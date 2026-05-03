# General Guide: Create `powerace-data.sql`

This guide explains how to create the SQL file that will be imported into the
PowerACE MariaDB Docker image.

The final file must be named:

```text
data\powerace-data.sql
```

It should contain the database structure and data needed for the selected
PowerACE run.

## What `powerace-data.sql` Is

`powerace-data.sql` is a database export. It contains SQL commands such as:

```sql
CREATE DATABASE ...
CREATE TABLE ...
INSERT INTO ...
```

When the Docker image is built, MariaDB imports this file. After that, the data
is inside the image.

The file does **not** have to contain the entire original database server. It
only needs to contain enough data for the PowerACE settings file that should be
run.

## Why The SQL File Is Scenario-Specific

PowerACE settings files define which data is needed. A settings file can choose:

```text
market areas
start year
number of simulated days
weather-year sequence
scenario names
database table names
investment options
renewable and demand profile tables
interconnector tables
```

Because of that, a SQL dump created for one settings file is not automatically
valid for all other settings files.

The Docker workflow is reusable. The actual data dump is specific to the chosen
PowerACE run.

## Step 1: Choose The Settings File

Start by deciding which settings XML file should be supported, for example:

```text
params\Allgemein\settings_Ali.xml
params\Allgemein\settings_Test.xml
params\DissTW\settings_DE.xml
```

Open that file and note the important values:

```text
startYear
totalDays
weatherSequenceID
market areas
scenario names
table names
```

For example, if a file starts in 2028 and simulates three years, many hourly
tables only need rows for 2028, 2029, and 2030.

## Step 2: Identify Required Tables

Most required table names are written directly in the settings XML. They often
look like this:

```xml
value="`iip-web-0002_demand`.`tbl_demand_profiles_locationIDs`"
```

Record every database/table pair referenced in the settings file.

Also include startup lookup tables that PowerACE reads from code before or
during model setup. Current PowerACE versions need at least:

```text
iip-web-0002_definitions.tbl_demands
iip-web-0002_definitions.tbl_scenarios
iip-web-0002_geo.tbl_market_areas
```

These tables are small, but important.

## Step 3: Decide Which Tables Can Be Exported Completely

Small tables can usually be exported with all rows.

Examples:

```text
scenario lookup tables
demand type lookup tables
market-area lookup tables
area mapping tables
fuel price tables
CO2 price tables
availability tables
power plant tables
storage asset tables
investment option tables
```

For these tables, export:

```text
Structure + Data
```

The export must contain both the table definition and the data:

```sql
CREATE TABLE ...
INSERT INTO ...
```

## Step 4: Find Large Tables Before Exporting

Do not export large hourly/profile tables blindly. They may contain hundreds of
millions of rows.

In DBeaver, table sizes can be checked through the table properties or with a
query against `information_schema.tables`.

Useful columns are:

```text
table_schema
table_name
data_length + index_length
table_rows
```

Large tables often include:

```text
demand profiles
renewable capacity factors
renewable inflows
storage inflows
hourly interconnector capacities
historical commercial flows
weather-dependent time series
```

If a table is multiple gigabytes in the source database, exporting it fully will
make the Docker image large and difficult to share.

## Step 5: Filter Large Tables

For large tables, export only the rows needed by the chosen settings file.

Common filters are:

```text
scenario_ID
year
weather_year
location_ID
market_area_ID
technology_ID
```

Scenario names in the XML must be translated to IDs using:

```text
iip-web-0002_definitions.tbl_scenarios
```

Market-area names must be translated to IDs using:

```text
iip-web-0002_geo.tbl_market_areas
```

If an area mapping table is used, include both:

```text
bidding_zone_ID
sub_ID
```

This matters because PowerACE often loads data for a bidding zone and its
sub-areas.

## Step 6: Export Large Tables In Two Parts

For each large table, create two exports:

1. The table structure.
2. The filtered data rows.

The structure export contains:

```sql
CREATE TABLE ...
```

The filtered data export contains:

```sql
INSERT INTO ...
```

In DBeaver, filtered data can be exported by running a `SELECT` query, then
right-clicking the result grid and choosing `Export Data`.

Important: the exported `INSERT INTO` statements must target the real table
name. For example:

```sql
INSERT INTO `iip-web-0002_demand`.`tbl_demand_profiles_locationIDs` (...) VALUES (...);
```

They must not target the text of the query itself.

## Step 7: Combine All SQL Parts

A practical workflow is to create separate files:

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

The order matters:

1. Create databases and small tables.
2. Create large table structures.
3. Insert small table data.
4. Insert filtered large table data.

Foreign-key relationships may require lookup tables, such as `tbl_scenarios`, to
be created and filled before dependent tables are filled.

## Step 8: Check Database Context

Every table command must belong to the correct database.

Good SQL contains either fully qualified table names:

```sql
CREATE TABLE `iip-web-0002_demand`.`tbl_demand_profiles_locationIDs` (...);
INSERT INTO `iip-web-0002_demand`.`tbl_demand_profiles_locationIDs` VALUES (...);
```

or it selects the database before table commands:

```sql
CREATE DATABASE IF NOT EXISTS `iip-web-0002_demand`;
USE `iip-web-0002_demand`;

CREATE TABLE `tbl_demand_profiles_locationIDs` (...);
INSERT INTO `tbl_demand_profiles_locationIDs` VALUES (...);
```

If the dump only contains comments such as:

```sql
-- Database: iip-web-0002_demand
```

that is not enough. MariaDB needs an actual `USE` statement or fully qualified
table names.

## Step 9: Check For Duplicate Rows

Filtered exports can accidentally contain duplicate rows, especially if the
query joins to weather-year sequence tables.

If duplicate rows are present, the import may fail with:

```text
Duplicate entry ... for key 'PRIMARY'
```

The best solution is to fix the export query so it returns unique rows.

If the duplicates are known to be identical and harmless, another option is to
use:

```sql
INSERT IGNORE INTO ...
```

for the affected table. This tells MariaDB to keep the first row and ignore later
duplicates.

## Step 10: Build And Test The Docker Image

After `data\powerace-data.sql` is ready, build the image:

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

Then run PowerACE against the Docker database.

## Step 11: If PowerACE Reports Missing Tables

If PowerACE reports that a table does not exist, the SQL dump is incomplete.

Find the missing table name in the error message, export that table from the
source database, add it to `powerace-data.sql`, rebuild the Docker image, and
start a fresh container from the rebuilt image.

Changing `powerace-data.sql` does not change an already running container.

## Final Rule

The Docker repository is general. The SQL dump is not.

For every new PowerACE settings file, review the required tables, scenarios,
years, and market areas again. Then create a matching `powerace-data.sql` and
rebuild the image.
