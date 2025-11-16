$ErrorActionPreference = "Stop"

# App data folder for per-user config and database
$AppData = Join-Path $env:LOCALAPPDATA "DaManage"
if (!(Test-Path $AppData)) { New-Item -ItemType Directory -Path $AppData | Out-Null }

$EnvFile = Join-Path $AppData ".env"
$DbFile = Join-Path $AppData "usdm.db"

# First-run generation of secrets and config
if (!(Test-Path $EnvFile)) {
  Write-Host "Creating first-run .env at $EnvFile"
  # JWT secret: 32 random bytes as hex
  $jwtBytes = New-Object byte[] 32; (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($jwtBytes)
  $jwt = -join ($jwtBytes | ForEach-Object { $_.ToString("x2") })
  # Vault key: 32 random bytes, base64
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

$null = New-Item -ItemType Directory -Path (Split-Path -Parent $DbFile) -Force -ErrorAction SilentlyContinue

$env:DOTENV_CONFIG_PATH = $EnvFile

Write-Host "Starting backend with env: $EnvFile"
node -r dotenv/config server.js
