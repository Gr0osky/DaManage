$ErrorActionPreference = "Stop"

# App data folder for per-user config and database
$AppData = Join-Path $env:LOCALAPPDATA "DaManage"
if (!(Test-Path $AppData)) { New-Item -ItemType Directory -Path $AppData | Out-Null }

$EnvFile = Join-Path $AppData ".env"
$DbFile  = Join-Path $AppData "usdm.db"

# First-run generation of secrets and config
if (!(Test-Path $EnvFile)) {
  Write-Host "Creating first-run .env at $EnvFile"
  $jwtBytes = New-Object byte[] 32; (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($jwtBytes)
  $jwt = -join ($jwtBytes | ForEach-Object { $_.ToString("x2") })
  $vaultBytes = New-Object byte[] 32; (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($vaultBytes)
  $vault = [Convert]::ToBase64String($vaultBytes)
  @(
    "PORT=3000"
    "DB_PATH=$DbFile"
    "JWT_SECRET=$jwt"
    "VAULT_KEY=$vault"
    "CORS_ORIGIN=*"
  ) | Set-Content -Path $EnvFile -Encoding ASCII
}

$env:DOTENV_CONFIG_PATH = $EnvFile

# Resolve backend exe in the same directory as this script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendExe = Join-Path $ScriptDir "backend.exe"
if (!(Test-Path $BackendExe)) {
  Write-Error "backend.exe not found at $BackendExe"
  exit 1
}

Write-Host "Starting backend.exe with env: $EnvFile"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $BackendExe
$psi.WorkingDirectory = $ScriptDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
[System.Diagnostics.Process]::Start($psi) | Out-Null
