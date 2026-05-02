param(
    [string]$ImageName = "powerace-mariadb:latest",
    [string]$ContainerName = "powerace-mariadb",
    [int]$HostPort = 3307
)

$ErrorActionPreference = "Stop"

$ExistingContainer = docker ps -a --filter "name=^/$ContainerName$" --format "{{.Names}}"

if ($ExistingContainer -eq $ContainerName) {
    docker start $ContainerName | Out-Null
    Write-Host "Started existing container: $ContainerName"
} else {
    docker run -d --name $ContainerName -p "${HostPort}:3306" $ImageName | Out-Null
    Write-Host "Created and started container: $ContainerName"
}

Write-Host ""
Write-Host "MariaDB is available for PowerACE at:"
Write-Host "  host:     127.0.0.1"
Write-Host "  port:     $HostPort"
Write-Host "  user:     powerace"
Write-Host "  password: powerace"
