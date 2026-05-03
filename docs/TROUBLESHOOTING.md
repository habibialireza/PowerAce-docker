# Troubleshooting

This page explains common problems when creating or using the PowerACE MariaDB
Docker image. The goal is to understand what went wrong and what has to be
changed.

## PowerShell Says Scripts Are Disabled

Typical message:

```text
running scripts is disabled on this system
```

This is a Windows PowerShell safety setting. It does not mean the script is
wrong.

Solve it by running the script with a temporary execution-policy bypass:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script-name.ps1
```

This only affects the current command.

## Docker Is Not Recognized

Typical message:

```text
docker is not recognized as the name of a cmdlet
```

Docker Desktop is either not installed, not running, or not available in the
terminal path.

Solve it by installing and starting Docker Desktop. Then open a new PowerShell
window and check:

```powershell
docker --version
docker ps
```

## Docker Permission Error

Typical message:

```text
permission denied while trying to connect to the docker API
```

Docker Desktop is installed, but the current Windows user or terminal session
cannot access the Docker engine.

Try these steps:

1. Start or restart Docker Desktop.
2. Open a new PowerShell window.
3. Run `docker ps`.
4. If it still fails, check whether your Windows user is allowed to use Docker
   Desktop on that machine.

## Build Fails: No Database Selected

Typical message:

```text
ERROR 1046 (3D000): No database selected
```

This means the SQL dump contains table commands such as:

```sql
DROP TABLE IF EXISTS `tbl_co2`;
CREATE TABLE `tbl_co2` (...);
```

but MariaDB does not know which database/schema the table belongs to.

The SQL file must select a database before creating or filling tables:

```sql
CREATE DATABASE IF NOT EXISTS `iip-web-0002_commodity_prices`;
USE `iip-web-0002_commodity_prices`;
```

Solve it by adding `CREATE DATABASE` and `USE` statements before each database
section in the SQL dump. DBeaver sometimes writes comments like this:

```sql
-- Host: mysql2g.scc.kit.edu    Database: iip-web-0002_commodity_prices
```

but does not add the actual `USE` command. In that case, use the database name
from the comment and add the missing SQL commands.

## Build Fails: Incorrect Table Name With A Long SELECT Query

Typical message:

```text
Incorrect table name 'WITH target_areas AS ...'
```

This happens when DBeaver exports the result of a filtered query as SQL inserts,
but uses the whole query text as the target table name.

Wrong output looks like:

```sql
INSERT INTO `WITH target_areas AS (...) SELECT ...` (...) VALUES (...);
```

The insert must target the real table instead:

```sql
INSERT INTO `iip-web-0002_demand`.`tbl_demand_profiles_locationIDs` (...) VALUES (...);
```

or:

```sql
INSERT INTO `iip-web-0002_renewables`.`tbl_cf_profiles` (...) VALUES (...);
```

Solve it by editing the SQL export so every `INSERT INTO` statement points to
the real database and table name.

## Build Fails: Duplicate Entry

Typical message:

```text
ERROR 1062 (23000): Duplicate entry ... for key 'PRIMARY'
```

This means the SQL file tries to insert the same primary-key row more than once.
It can happen in filtered profile exports when a query joins against weather-year
sequence tables and returns duplicate rows.

There are two ways to solve it:

1. Fix the export query so it returns unique rows only.
2. Make the affected profile inserts duplicate-tolerant by changing:

   ```sql
   INSERT INTO ...
   ```

   to:

   ```sql
   INSERT IGNORE INTO ...
   ```

Use `INSERT IGNORE` only when duplicate rows are expected to be identical and it
is acceptable to keep the first copy.

## Container Starts But Tables Are Missing

PowerACE may fail later with messages like:

```text
Table ... doesn't exist
```

or the validation step may report missing tables.

This means the SQL dump did not include all tables needed by the selected
PowerACE settings file.

Solve it by:

1. Identifying the missing database and table name from the error.
2. Exporting that table from the original database with structure and data.
3. Adding the exported SQL to `data\powerace-data.sql`.
4. Rebuilding the Docker image.
5. Removing the old container and starting a new one from the rebuilt image.

The old running container does not automatically receive changes made to the SQL
dump file.

## PowerACE Cannot Connect

Typical message:

```text
Communications link failure
```

This usually means PowerACE cannot reach the MariaDB container.

Check:

1. Is Docker Desktop running?
2. Is the container running?

   ```powershell
   docker ps
   ```

3. Is the container exposing the expected port?

   ```text
   127.0.0.1:3307
   ```

4. Are the Eclipse environment variables set correctly?

   ```text
   POWERACE_DB_HOST=127.0.0.1
   POWERACE_DB_PORT=3307
   POWERACE_DB_USER=powerace
   POWERACE_DB_PASSWORD=powerace
   ```

## Access Denied For User

Typical message:

```text
Access denied for user '...'
```

This means MariaDB is reachable, but the username or password is wrong.

For the default Docker image in this repository, PowerACE should use:

```text
user:     powerace
password: powerace
```

Root access inside the container uses:

```text
user:     root
password: powerace_root
```

## PowerACE Might Still Be Using The Original Database

If PowerACE runs successfully, but you are unsure whether it used Docker or the
original database server, prove it.

First check the PowerACE console. It should show a local connection like:

```text
Opening PowerACE database connection pool at jdbc:mysql://127.0.0.1:3307 with user 'powerace'.
```

You can also stop the Docker container:

```powershell
docker stop powerace-mariadb
```

Then run PowerACE again with the same Eclipse configuration. If it is really
using Docker, it should fail with a database connection error.

Start the container again afterwards:

```powershell
docker start powerace-mariadb
```

If PowerACE still runs while the Docker container is stopped, Eclipse is probably
not using the Docker environment variables and PowerACE may still be connecting
to the original database.
