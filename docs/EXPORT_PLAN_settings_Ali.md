# Export Plan for `params/Allgemein/settings_Ali.xml`

This plan creates a smaller SQL dump for the two-market-area `settings_Ali.xml`
run. The active areas are:

```text
Germany_Luxembourg
France
```

The run currently uses:

```text
startYear = 2028
totalDays = 3*365
weatherSequenceID = 99001
renewable/demand scenario = ERAA2025
```

So the main filtered years are:

```text
2028, 2029, 2030
```

## Recommended Dump Strategy

Do not fully dump the two very large profile tables:

```text
iip-web-0002_demand.tbl_demand_profiles_locationIDs
iip-web-0002_renewables.tbl_cf_profiles
```

For those two tables:

1. Export table structure only.
2. Export filtered rows from a query result as SQL `INSERT` statements.

For the other tables, a full structure + data dump is acceptable for the first
working version.

## Table-by-Table Plan

| Database | Table | Export Method | Why |
|---|---|---|---|
| `iip-web-0002_definitions` | `tbl_demands` | Full structure + data | Tiny lookup table, loaded at startup. |
| `iip-web-0002_definitions` | `tbl_scenarios` | Full structure + data | Tiny lookup table, loaded at startup. |
| `iip-web-0002_geo` | `tbl_market_areas` | Full structure + data | Tiny lookup table, needed to map DE_LU and FR. |
| `iip-web-0002_powerace` | `tbl_area_mapping_ERAA2025` | Full structure + data | Small, needed for sub-area mapping. |
| `iip-web-0002_powerace` | `tbl_weatherYearSequences` | Full structure + data | Small enough; can filter later to `scenario_ID = 99001` if needed. |
| `iip-web-0002_powerace` | `tbl_availability` | Full structure + data | Tiny. |
| `iip-web-0002_commodity_prices` | `tbl_co2` | Full structure + data | Tiny. |
| `iip-web-0002_commodity_prices` | `tbl_co2_historical` | Full structure + data | Tiny. |
| `iip-web-0002_commodity_prices` | `tbl_energy_carriers` | Full structure + data | Tiny. |
| `iip-web-0002_commodity_prices` | `tbl_energy_carriers_historical` | Full structure + data | Tiny. |
| `iip-web-0002_project_bets` | `tbl_powerplants_eraa2025` | Full structure + data | Small enough for first version. |
| `iip-web-0002_project_bets` | `tbl_powerplants_options` | Full structure + data | Tiny. |
| `iip-web-0002_renewables` | `tbl_renewables_plants_TEST` | Full structure + data | Small enough for first version. |
| `iip-web-0002_renewables` | `tbl_cf_profiles` | Structure only + filtered rows | Huge table. Must filter. |
| `iip-web-0002_renewables` | `tbl_ror_inflow` | Full structure + data | Medium-small; can filter later if needed. |
| `iip-web-0002_demand` | `tbl_demand_profiles_locationIDs` | Structure only + filtered rows | Huge table. Must filter. |
| `iip-web-0002_demand` | `tbl_demand_assets` | Full structure + data | Tiny. |
| `iip-web-0002_storages` | `tbl_electricity_storages_ERAA2025` | Full structure + data | Tiny. |
| `iip-web-0002_storages` | `tbl_pumpStorageInflows` | Full structure + data | Medium-small; can filter later if needed. |
| `iip-web-0002_storages` | `tbl_seasonalStorageInflows` | Full structure + data | Medium-small; can filter later if needed. |
| `iip-web-0002_investment_options` | `tbl_storages` | Full structure + data | Tiny. |
| `iip-web-0002_investment_options` | `tbl_renewables_TEST` | Full structure + data | Tiny. |
| `iip-web-0002_net_transfer_capacities` | `tbl_ntc_hourly` | Full structure + data for first version | 1.78 GB; can filter later. |
| `iip-web-0002_net_transfer_capacities` | `tbl_ntc_area_limits` | Full structure + data for first version | 0.07 GB; small enough. |
| `iip-web-0002_powerace` | `tbl_historical_commercial_flows` | Usually omit if `exchangeScenario=noexchange`; otherwise filter | Large-ish and currently schema-sensitive. |

## Filter Query: Demand Profiles

Use this query in DBeaver. Export the result grid as SQL `INSERT` statements.

```sql
WITH target_areas AS (
    SELECT location_ID
    FROM `iip-web-0002_geo`.`tbl_market_areas`
    WHERE eic_display_name IN ('DE_LU', 'FR')
),
target_locations AS (
    SELECT location_ID AS location_ID FROM target_areas
    UNION
    SELECT sub_ID
    FROM `iip-web-0002_powerace`.`tbl_area_mapping_ERAA2025`
    WHERE bidding_zone_ID IN (SELECT location_ID FROM target_areas)
      AND sub_ID IS NOT NULL
),
target_scenario AS (
    SELECT scenario_ID
    FROM `iip-web-0002_definitions`.`tbl_scenarios`
    WHERE name = 'ERAA2025'
)
SELECT s.*
FROM `iip-web-0002_demand`.`tbl_demand_profiles_locationIDs` s
JOIN `iip-web-0002_powerace`.`tbl_weatherYearSequences` w
  ON s.year = w.year
 AND s.weather_year = w.weather_year
WHERE w.scenario_ID = 99001
  AND s.scenario_ID = (SELECT scenario_ID FROM target_scenario)
  AND s.year BETWEEN 2028 AND 2030
  AND s.location_ID IN (SELECT location_ID FROM target_locations);
```

## Filter Query: Renewable Capacity Factors

Use this query in DBeaver. Export the result grid as SQL `INSERT` statements.

```sql
WITH target_areas AS (
    SELECT location_ID
    FROM `iip-web-0002_geo`.`tbl_market_areas`
    WHERE eic_display_name IN ('DE_LU', 'FR')
),
target_locations AS (
    SELECT location_ID AS location_ID FROM target_areas
    UNION
    SELECT sub_ID
    FROM `iip-web-0002_powerace`.`tbl_area_mapping_ERAA2025`
    WHERE bidding_zone_ID IN (SELECT location_ID FROM target_areas)
      AND sub_ID IS NOT NULL
),
target_scenario AS (
    SELECT scenario_ID
    FROM `iip-web-0002_definitions`.`tbl_scenarios`
    WHERE name = 'ERAA2025'
)
SELECT s.*
FROM `iip-web-0002_renewables`.`tbl_cf_profiles` s
JOIN `iip-web-0002_powerace`.`tbl_weatherYearSequences` w
  ON s.weather_year = w.weather_year
WHERE w.scenario_ID = 99001
  AND w.year BETWEEN 2028 AND 2030
  AND s.scenario_ID = (SELECT scenario_ID FROM target_scenario)
  AND s.location_ID IN (SELECT location_ID FROM target_locations);
```

## Combining the SQL Files

The final `powerace-data.sql` can be built from multiple SQL files in this order:

1. Small tables dumped with structure + data.
2. Structure-only dump for `tbl_demand_profiles_locationIDs`.
3. Structure-only dump for `tbl_cf_profiles`.
4. Filtered `INSERT` export for `tbl_demand_profiles_locationIDs`.
5. Filtered `INSERT` export for `tbl_cf_profiles`.

On Windows PowerShell, you can combine files like this:

```powershell
Get-Content .\small-tables.sql, .\demand-profile-structure.sql, .\cf-profile-structure.sql, .\demand-profile-filtered.sql, .\cf-profile-filtered.sql |
    Set-Content .\data\powerace-data.sql
```

For very large files, use `cmd` instead:

```cmd
copy /b small-tables.sql+demand-profile-structure.sql+cf-profile-structure.sql+demand-profile-filtered.sql+cf-profile-filtered.sql data\powerace-data.sql
```

