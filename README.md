# PowerACE MariaDB Docker Package

This repository contains the Docker/MariaDB workflow for running PowerACE with a
local database instead of the institute database server.

It intentionally does **not** contain the PowerACE source code and the real SQL data dump.

## What This Solves

External users can run PowerACE without access to the original database server.
The final Docker image contains the imported MariaDB data and can be started
directly.

```text
PowerACE -> local Docker container -> MariaDB with PowerACE data
```

## What Is Included

```text
Dockerfile                             Builds a MariaDB image with imported data
build-image.ps1                        Builds the Docker image
run-container.ps1                      Starts the database container
test-connection.ps1                    Checks that MariaDB answers
normalize-dump-databases.ps1           Fixes dumps without CREATE DATABASE / USE
data/                                  Put the real SQL dump here locally
examples/                              Small smoke-test SQL file
docs/                                  Detailed guides
```

## Requirements

Install:

- Docker Desktop
- PowerShell
- PowerACE separately (and all of it's dependencies)
- Java/Eclipse for running PowerACE

You do **not** need to install MariaDB or MySQL on your PC. MariaDB runs inside
Docker. 
For a complete startup guide for PowerACE refer to it's documentation.

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
C:\workspace\powerace\PowerACE-main
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
