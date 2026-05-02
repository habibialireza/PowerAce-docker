# Troubleshooting

## PowerShell Says Scripts Are Disabled

Run the script like this:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script-name.ps1
```

Example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\validate-powerace-tables.ps1
```

## Docker Is Not Recognized

Docker Desktop is not installed, not running, or Docker is not on `PATH`.

Start Docker Desktop and try:

```powershell
docker --version
docker ps
```

## Docker Permission Error

Typical message:

```text
permission denied while trying to connect to the docker API
```

Restart Docker Desktop. If the problem remains, check that your Windows user is
allowed to use Docker Desktop.

## Build Fails: No Database Selected

Typical message:

```text
ERROR 1046 (3D000): No database selected
```

The SQL dump does not contain `CREATE DATABASE` / `USE` statements.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\normalize-dump-databases.ps1
```

Then rebuild:

```powershell
.\build-image.ps1
```

## Build Fails: Incorrect Table Name With A Long SELECT Query

Typical message:

```text
Incorrect table name 'WITH target_areas AS ...'
```

DBeaver exported query results using the entire SQL query as the table name.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\fix-dbeaver-query-inserts.ps1
```

Then rebuild.

## Build Fails: Duplicate Entry

Typical message:

```text
ERROR 1062 (23000): Duplicate entry ...
```

Filtered profile exports may contain duplicates because of weather-year joins.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\make-profile-inserts-idempotent.ps1
```

Then rebuild.

## Container Starts But Tables Are Missing

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\validate-powerace-tables.ps1
```

If a table is missing, export that table from DBeaver with structure + data,
append it to `data\powerace-data.sql`, rebuild the image, remove the old
container, and start a new one:

```powershell
.\build-image.ps1
docker rm -f powerace-mariadb
.\run-container.ps1
```

## PowerACE Cannot Connect

Make sure the container is running:

```powershell
docker ps
```

Make sure Eclipse uses:

```text
POWERACE_DB_HOST=127.0.0.1
POWERACE_DB_PORT=3307
POWERACE_DB_USER=powerace
POWERACE_DB_PASSWORD=powerace
```

## PowerACE Might Still Be Using The Original Database

Stop the container:

```powershell
docker stop powerace-mariadb
```

Run PowerACE. It should fail. If it still runs, Eclipse is probably not using the
Docker environment variables.
