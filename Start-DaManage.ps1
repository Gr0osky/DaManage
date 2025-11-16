param(
    [int]$BackendStartupTimeoutSeconds = 45
)

$ErrorActionPreference = "Stop"

function New-RandomHexString([int]$bytes) {
    $data = New-Object byte[] $bytes
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($data)
    return -join ($data | ForEach-Object { $_.ToString("x2") })
}

function New-RandomBase64String([int]$bytes) {
    $data = New-Object byte[] $bytes
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($data)
    return [Convert]::ToBase64String($data)
}

function Ensure-AppEnv {
    $appData = Join-Path $env:LOCALAPPDATA "DaManage"
    if (!(Test-Path $appData)) {
        New-Item -ItemType Directory -Path $appData | Out-Null
    }

    $envFile = Join-Path $appData ".env"
    $dbFile = Join-Path $appData "usdm.db"

    if (!(Test-Path $envFile)) {
        Write-Host "Creating first-run .env at $envFile"
        $jwt = New-RandomHexString -bytes 32
        $vault = New-RandomBase64String -bytes 32
        @(
            "PORT=3000"
            "DB_PATH=$dbFile"
            "JWT_SECRET=$jwt"
            "VAULT_KEY=$vault"
            "CORS_ORIGIN=*"
        ) | Set-Content -Path $envFile -Encoding ASCII
    }

    $dbDir = Split-Path -Parent $dbFile
    if (!(Test-Path $dbDir)) {
        New-Item -ItemType Directory -Path $dbDir | Out-Null
    }

    return [PSCustomObject]@{
        EnvFile = $envFile
        DbFile  = $dbFile
    }
}

function Get-PortFromEnv([string]$envFile, [int]$defaultPort = 3000) {
    try {
        foreach ($line in Get-Content -Path $envFile) {
            if ($line -match '^[\s\t]*PORT[\s\t]*=\s*(\d+)\s*$') {
                return [int]$Matches[1]
            }
        }
    } catch {
        # ignore and fall back to default
    }
    return $defaultPort
}

function Test-TcpPort([int]$port) {
    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect('127.0.0.1', $port, $null, $null)
        if ($async.AsyncWaitHandle.WaitOne(500)) {
            $client.EndConnect($async)
            return $true
        }
    } catch {
        return $false
    } finally {
        if ($client) {
            $client.Dispose()
        }
    }
    return $false
}

function Wait-ForBackend([int]$port, [int]$timeoutSeconds, $process) {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    while ($timer.Elapsed.TotalSeconds -lt $timeoutSeconds) {
        if (Test-TcpPort -port $port) {
            return $true
        }
        if ($process -and $process.HasExited) {
            return $false
        }
        Start-Sleep -Milliseconds 500
    }
    return Test-TcpPort -port $port
}

function Resolve-BackendPlan([string]$root) {
    $packagedDir = Join-Path $root "backend"
    $packagedExe = Join-Path $packagedDir "backend.exe"
    if (Test-Path $packagedExe) {
        return [PSCustomObject]@{
            Mode      = 'packaged'
            FilePath  = $packagedExe
            Arguments = @()
            WorkDir   = $packagedDir
        }
    }

    $distExe = Join-Path $root "usdm-backend\dist\backend.exe"
    if (Test-Path $distExe) {
        $distDir = Split-Path -Parent $distExe
        return [PSCustomObject]@{
            Mode      = 'packaged'
            FilePath  = $distExe
            Arguments = @()
            WorkDir   = $distDir
        }
    }

    $devDir = Join-Path $root "usdm-backend"
    $serverJs = Join-Path $devDir "server.js"
    if (Test-Path $serverJs) {
        return [PSCustomObject]@{
            Mode      = 'node'
            FilePath  = 'node'
            Arguments = @('-r', 'dotenv/config', 'server.js')
            WorkDir   = $devDir
        }
    }

    throw "Unable to locate backend executable or server.js. Build the backend first."
}

function Resolve-FrontendExecutable([string]$root) {
    $candidates = @(
        (Join-Path $root "DaManage.exe"),
        (Join-Path $root "usdm_gui.exe"),
        (Join-Path $root "usdm_gui\build\windows\x64\runner\Release\DaManage.exe"),
        (Join-Path $root "usdm_gui\build\windows\x64\runner\Release\usdm_gui.exe"),
        (Join-Path $root "usdm_gui\build\windows\x64\runner\Debug\DaManage.exe"),
        (Join-Path $root "usdm_gui\build\windows\x64\runner\Debug\usdm_gui.exe")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Unable to locate DaManage.exe. Build the Flutter desktop app with `flutter build windows --release`."
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$appEnv = Ensure-AppEnv
$originalDotEnv = $env:DOTENV_CONFIG_PATH
$env:DOTENV_CONFIG_PATH = $appEnv.EnvFile

$backendPlan = Resolve-BackendPlan -root $scriptRoot
$frontendExe = Resolve-FrontendExecutable -root $scriptRoot
$frontendDir = Split-Path -Parent $frontendExe
$port = Get-PortFromEnv -envFile $appEnv.EnvFile -defaultPort 3000

$env:PORT = $port.ToString()

$backendAlreadyRunning = Test-TcpPort -port $port
$backendProcess = $null
$frontendProcess = $null

try {
    if ($backendAlreadyRunning) {
        Write-Host "Backend already running on port $port. Skipping startup." -ForegroundColor Yellow
    } else {
        if ($backendPlan.Mode -eq 'node' -and -not (Get-Command $backendPlan.FilePath -ErrorAction SilentlyContinue)) {
            throw "Node.js runtime not found in PATH. Install Node.js or package the backend."
        }

        Write-Host "Starting backend ($($backendPlan.Mode))..."
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $backendPlan.FilePath
        $psi.WorkingDirectory = $backendPlan.WorkDir
        if ($backendPlan.Arguments -and $backendPlan.Arguments.Count -gt 0) {
            $psi.Arguments = ($backendPlan.Arguments | ForEach-Object {
                if ($_ -match '\s') { '"' + ($_ -replace '"','\"') + '"' } else { $_ }
            }) -join ' '
        }
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $backendProcess = [System.Diagnostics.Process]::Start($psi)

        if (-not (Wait-ForBackend -port $port -timeoutSeconds $BackendStartupTimeoutSeconds -process $backendProcess)) {
            throw "Backend failed to start or did not open port $port within $BackendStartupTimeoutSeconds seconds."
        }

        Write-Host "Backend listening on http://localhost:$port"
    }

    Write-Host "Launching frontend ($frontendExe)..."
    $frontendProcess = Start-Process -FilePath $frontendExe -WorkingDirectory $frontendDir -PassThru
    Write-Host "Waiting for frontend to exit..."
    Wait-Process -Id $frontendProcess.Id
    Write-Host "Frontend exited with code $($frontendProcess.ExitCode)"
}
finally {
    if ($backendProcess -and -not $backendProcess.HasExited) {
        Write-Host "Shutting down backend..."
        try {
            Stop-Process -Id $backendProcess.Id -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to terminate backend process: $($_.Exception.Message)"
        }
    }

    if (-not [string]::IsNullOrEmpty($originalDotEnv)) {
        $env:DOTENV_CONFIG_PATH = $originalDotEnv
    } else {
        Remove-Item Env:DOTENV_CONFIG_PATH -ErrorAction SilentlyContinue
    }
}
