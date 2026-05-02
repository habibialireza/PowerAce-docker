param(
    [string]$ContainerName = "powerace-mariadb"
)

$ErrorActionPreference = "Stop"

docker exec `
    --env MYSQL_PWD=powerace `
    $ContainerName `
    mariadb -upowerace -e "SHOW DATABASES;"

Write-Host ""
Write-Host "If database names are shown above, the MariaDB container is answering."
