# Maintainer Checklist

Use this checklist before handing the package to another user.

## Build The Image

```powershell
.\build-image.ps1
```

## Recreate The Container

```powershell
docker rm -f powerace-mariadb
.\run-container.ps1
```

## Test Connection

```powershell
.\test-connection.ps1 -ContainerName powerace-mariadb
```

## Validate Required Tables

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\validate-powerace-tables.ps1
```

Expected output:

```text
All required PowerACE tables are present.
```

## Test With PowerACE

Run PowerACE in Eclipse with:

```text
POWERACE_DB_HOST=127.0.0.1
POWERACE_DB_PORT=3307
POWERACE_DB_USER=powerace
POWERACE_DB_PASSWORD=powerace
```

The simulation should finish with `settings_Ali.xml`.

## Export The Finished Image

```powershell
docker save powerace-mariadb:latest -o powerace-mariadb-image.tar
```

Do not commit this `.tar` file to Git.

## Git Safety Check

Before committing:

```powershell
git status
```

Make sure no real SQL dump, Docker image tar, or private data file is staged.
