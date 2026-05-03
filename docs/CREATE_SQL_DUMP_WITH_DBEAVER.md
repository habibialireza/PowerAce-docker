# Create The SQL Dump With DBeaver

This guide is for the person who has access to the original database.

The goal is to create:

```text
data\powerace-data.sql
```

This file is imported into the Docker image.

## Important

Do not dump the complete database server. The full profile tables can be very
large. For your preferred `setting.xml` test case, export only the needed tables and
filter the tables that are too big.

## Recommended Workflow


# Combine Files

For large files, use Windows `cmd`:

```cmd
copy /b small-tables.sql+demand-profile-structure.sql+cf-profile-structure.sql+demand-profile-filtered.sql+cf-profile-filtered.sql data\powerace-data.sql
```

## Repair DBeaver Dumps

If the dump does not include `CREATE DATABASE` and `USE`, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\normalize-dump-databases.ps1
```

If DBeaver exported filtered query results as `INSERT INTO <the whole query>`,
run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\fix-dbeaver-query-inserts.ps1
```

If duplicate profile rows appear during Docker build, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\make-profile-inserts-idempotent.ps1
```

Then build the image:

```powershell
.\build-image.ps1
```
