param(
    [string]$SqlFile = ".\data\powerace-data.sql",
    [string]$ImageName = "powerace-mariadb:latest"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataDir = Join-Path $ScriptDir "data"
$TargetSqlFile = Join-Path $DataDir "powerace-data.sql"

if (-not (Test-Path $SqlFile)) {
    throw "SQL file not found: $SqlFile"
}

if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir | Out-Null
}

$ResolvedInput = (Resolve-Path $SqlFile).Path
$ResolvedTarget = $null
if (Test-Path $TargetSqlFile) {
    $ResolvedTarget = (Resolve-Path $TargetSqlFile).Path
}

if ($ResolvedInput -ne $ResolvedTarget) {
    Copy-Item -Path $ResolvedInput -Destination $TargetSqlFile -Force
}

docker build -t $ImageName $ScriptDir
if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed. Please check the Docker error output above."
}

Write-Host ""
Write-Host "Done. Docker image created: $ImageName"
Write-Host "The SQL data is now inside the image."
