# PowerACE MariaDB Docker Package

This repository contains the Docker/MariaDB workflow for running PowerACE with a
local database instead of the institute database server.

It intentionally does **not** contain the PowerACE source code and it should not
contain the real SQL data dump. The real SQL file is large and may contain
restricted project data, so it is ignored by Git.

## What This Solves

External users can run PowerACE without access to the original database server.
The final Docker image contains the imported MariaDB data and can be started
directly.

```text
PowerACE -> local Docker container -> MariaDB with PowerACE data
```

## What Is Included

```text
Dockerfile                              Builds a MariaDB image with imported data
build-image.ps1                        Builds the Docker image
run-container.ps1                      Starts the database container
test-connection.ps1                    Checks that MariaDB answers
validate-powerace-tables.ps1           Checks that required PowerACE tables exist
normalize-dump-databases.ps1           Fixes dumps without CREATE DATABASE / USE
fix-dbeaver-query-inserts.ps1          Fixes DBeaver query-result INSERT headers
make-profile-inserts-idempotent.ps1    Handles duplicate filtered profile rows
data/                                  Put the real SQL dump here locally
examples/                              Small smoke-test SQL file
docs/                                  Detailed guides
```

## Requirements

Install:

- Docker Desktop
- PowerShell
- PowerACE separately
- Java/Eclipse for running PowerACE

You do **not** need to install MariaDB or MySQL on your PC. MariaDB runs inside
Docker.

## Quick Smoke Test

This only tests Docker and MariaDB. It does not contain enough data to run a full
PowerACE simulation.

Open PowerShell in this repository folder and run:

```powershell
.\build-image.ps1 -SqlFile .\examples\smoke-test-data.sql -ImageName powerace-mariadb-smoke:latest
.\run-container.ps1 -ImageName powerace-mariadb-smoke:latest -ContainerName powerace-mariadb-smoke -HostPort 3308
.\test-connection.ps1 -ContainerName powerace-mariadb-smoke
```

If database names are shown, Docker and MariaDB work.

## Build The Real PowerACE Database Image

Put the real SQL dump here:

```text
data\powerace-data.sql
```

Then run:

```powershell
.\build-image.ps1
```

This creates:

```text
powerace-mariadb:latest
```

The import can take a while. A one-gigabyte SQL dump may take several minutes.

## Start The Real Database

```powershell
.\run-container.ps1
```

The database will be available at:

```text
host:     127.0.0.1
port:     3307
user:     powerace
password: powerace
```

Check it:

```powershell
.\test-connection.ps1 -ContainerName powerace-mariadb
```

Validate required tables:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\validate-powerace-tables.ps1
```

## Configure PowerACE In Eclipse

In the PowerACE run configuration, add these environment variables:

```text
POWERACE_DB_HOST=127.0.0.1
POWERACE_DB_PORT=3307
POWERACE_DB_USER=powerace
POWERACE_DB_PASSWORD=powerace
```

The working directory should be the PowerACE project folder, for example:

```text
E:\iip\workspace\powerace\PowerACE-main
```

More details: [docs/POWERACE_ECLIPSE_SETUP.md](docs/POWERACE_ECLIPSE_SETUP.md)

## Share The Finished Image

After the real image has been built, export it:

```powershell
docker save powerace-mariadb:latest -o powerace-mariadb-image.tar
```

Another user can import it:

```powershell
docker load -i powerace-mariadb-image.tar
```

Then they start it with:

```powershell
.\run-container.ps1
```

## For Maintainers

To create the SQL dump from DBeaver, see:

- [docs/CREATE_SQL_DUMP_WITH_DBEAVER.md](docs/CREATE_SQL_DUMP_WITH_DBEAVER.md)
- [docs/EXPORT_PLAN_settings_Ali.md](docs/EXPORT_PLAN_settings_Ali.md)

For common errors, see:

- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
