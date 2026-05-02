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

Use this detailed table plan:

[EXPORT_PLAN_settings_Ali.md](EXPORT_PLAN_settings_Ali.md)

## Recommended File Parts

Create these files first:

```text
small-tables.sql
demand-profile-structure.sql
cf-profile-structure.sql
demand-profile-filtered.sql
cf-profile-filtered.sql
```

Then combine them into:

```text
data\powerace-data.sql
```

## Small Tables

In DBeaver, use `Tools -> Dump database` or `Tools -> Backup`.

Export these with **structure + data**:

```text
iip-web-0002_definitions.tbl_demands
iip-web-0002_definitions.tbl_scenarios
iip-web-0002_geo.tbl_market_areas
iip-web-0002_powerace.tbl_area_mapping_ERAA2025
iip-web-0002_powerace.tbl_weatherYearSequences
iip-web-0002_powerace.tbl_availability
iip-web-0002_commodity_prices.tbl_co2
iip-web-0002_commodity_prices.tbl_co2_historical
iip-web-0002_commodity_prices.tbl_energy_carriers
iip-web-0002_commodity_prices.tbl_energy_carriers_historical
iip-web-0002_project_bets.tbl_powerplants_eraa2025
iip-web-0002_project_bets.tbl_powerplants_options
iip-web-0002_renewables.tbl_renewables_plants_TEST
iip-web-0002_renewables.tbl_ror_inflow
iip-web-0002_demand.tbl_demand_assets
iip-web-0002_storages.tbl_electricity_storages_ERAA2025
iip-web-0002_storages.tbl_pumpStorageInflows
iip-web-0002_storages.tbl_seasonalStorageInflows
iip-web-0002_investment_options.tbl_storages
iip-web-0002_investment_options.tbl_renewables_TEST
iip-web-0002_net_transfer_capacities.tbl_ntc_hourly
iip-web-0002_net_transfer_capacities.tbl_ntc_area_limits
```

## Huge Tables

Do not export these fully:

```text
iip-web-0002_demand.tbl_demand_profiles_locationIDs
iip-web-0002_renewables.tbl_cf_profiles
```

For both tables:

1. Export table structure only.
2. Run the filtered query from [EXPORT_PLAN_settings_Ali.md](EXPORT_PLAN_settings_Ali.md).
3. Right-click the result grid.
4. Choose `Export Data`.
5. Export as SQL `INSERT` statements.

## Combine Files

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
