# General Guide: Create `powerace-data.sql`

This guide explains how to create the SQL file that is imported into the
PowerACE MariaDB Docker image.

The file must be named:

```text
data\powerace-data.sql
```

It should contain all database tables and rows needed for the PowerACE settings
file you want to run.

## Main Idea

PowerACE reads most input data from MariaDB tables. A settings XML file decides
which scenarios, years, market areas, and table names are used.

The Docker image should contain:

```text
MariaDB software + the required PowerACE tables + the required data rows
```

The SQL dump does not need to contain the entire original database server. It
only needs enough data for the selected PowerACE run.

## Step 1: Choose The PowerACE Settings File

First decide which PowerACE settings file should run, for example:

```text
params\Allgemein\settings_Ali.xml
params\Allgemein\settings_Test.xml
params\DissTW\settings_DE.xml
```

The SQL export depends on this file.

Important values inside the settings file include:

```text
startYear
totalDays
weatherSequenceID
areaMapping
scenario names
market areas
database table names
```

## Step 2: List The Referenced Tables

Most table names appear directly in the settings XML as values like:

```xml
value="`iip-web-0002_demand`.`tbl_demand_profiles_locationIDs`"
```

You can list these tables with:

```powershell
.\list-powerace-tables.ps1 -SettingsFile "path\to\settings.xml"
```

Some tables are needed even if they are not explicitly listed in the settings
XML. For current PowerACE versions, always include:

```text
iip-web-0002_definitions.tbl_demands
iip-web-0002_definitions.tbl_scenarios
iip-web-0002_geo.tbl_market_areas
```

These are lookup tables needed during model startup.

## Step 3: Decide Which Tables Can Be Fully Exported

Small lookup tables can usually be exported completely.

Typical examples:

```text
tbl_scenarios
tbl_demands
tbl_market_areas
tbl_area_mapping_...
tbl_availability
fuel price tables
CO2 price tables
power plant tables
storage tables
investment option tables
```

In DBeaver, export these with:

```text
Structure + Data
```

The SQL should include both:

```sql
CREATE TABLE ...
INSERT INTO ...
```

## Step 4: Identify Large Tables

Do not blindly export very large hourly/profile tables.

Use DBeaver to run this query for your table list:

```sql
SELECT
    table_schema,
    table_name,
    ROUND((data_length + index_length) / 1024 / 1024 / 1024, 2) AS size_gb,
    table_rows
FROM information_schema.tables
WHERE table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys')
ORDER BY size_gb DESC;
```

Large tables often include:

```text
demand profile tables
renewable profile tables
capacity factor tables
hourly NTC/interconnector tables
historical flow tables
weather-dependent inflow tables
```

These should usually be filtered.

## Step 5: Work Out The Filters

Filters depend on the selected settings file.

Common filter dimensions are:

```text
scenario_ID
year
weather_year
location_ID
market_area_ID
technology_ID
```

Scenario names in XML must be translated to `scenario_ID` through:

```text
iip-web-0002_definitions.tbl_scenarios
```

Market-area names must be translated to location and market-area IDs through:

```text
iip-web-0002_geo.tbl_market_areas
```

Area mappings and sub-areas usually come from:

```text
areaMapping from the settings XML
```

For example, if the settings file uses an area mapping table, include both the
main bidding-zone IDs and the mapped sub-IDs.

## Step 6: Export Large Tables As Structure + Filtered Rows

For every large table:

1. Export the table structure only.
2. Create a filtered `SELECT` query for the rows needed by your settings file.
3. Run the query in DBeaver.
4. Right-click the result grid.
5. Choose `Export Data`.
6. Export as SQL `INSERT` statements.

The filtered export should insert into the real table name, not into the query
text. If DBeaver produces wrong insert headers, this repository has a repair
script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\fix-dbeaver-query-inserts.ps1
```

## Step 7: Combine The SQL Parts

A practical workflow is to create several files:

```text
small-tables.sql
large-table-1-structure.sql
large-table-1-filtered-data.sql
large-table-2-structure.sql
large-table-2-filtered-data.sql
```

Then combine them into:

```text
data\powerace-data.sql
```

For large files, use Windows `cmd`:

```cmd
copy /b small-tables.sql+large-table-1-structure.sql+large-table-1-filtered-data.sql+large-table-2-structure.sql+large-table-2-filtered-data.sql data\powerace-data.sql
```

## Step 8: Normalize The Dump If Needed

Some DBeaver exports contain comments such as:

```sql
-- Host: ... Database: iip-web-0002_demand
```

but do not contain:

```sql
CREATE DATABASE ...
USE ...
```

If so, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\normalize-dump-databases.ps1
```

## Step 9: Handle Duplicate Filtered Profile Rows If Needed

Filtered profile exports can contain duplicates, especially when the filter joins
against weather-year sequence tables.

If Docker build fails with:

```text
Duplicate entry ... for key 'PRIMARY'
```

run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\make-profile-inserts-idempotent.ps1
```

Then rebuild.

## Step 10: Build And Validate

Build the image:

```powershell
.\build-image.ps1
```

Start the container:

```powershell
.\run-container.ps1
```

Check that MariaDB answers:

```powershell
.\test-connection.ps1 -ContainerName powerace-mariadb
```

Validate required tables:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\validate-powerace-tables.ps1
```

Finally, run PowerACE against the Docker database.

## Important Rule

The repository and scripts are reusable for many PowerACE settings files.

The actual `powerace-data.sql` file is scenario-specific. If you change the
PowerACE settings file, you may need a different SQL export and a rebuilt Docker
image.
