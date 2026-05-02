param(
    [string]$ContainerName = "powerace-mariadb"
)

$ErrorActionPreference = "Stop"

$RequiredTables = @(
    @("iip-web-0002_commodity_prices", "tbl_co2_historical"),
    @("iip-web-0002_commodity_prices", "tbl_co2"),
    @("iip-web-0002_commodity_prices", "tbl_energy_carriers_historical"),
    @("iip-web-0002_commodity_prices", "tbl_energy_carriers"),
    @("iip-web-0002_definitions", "tbl_demands"),
    @("iip-web-0002_definitions", "tbl_scenarios"),
    @("iip-web-0002_demand", "tbl_demand_assets"),
    @("iip-web-0002_demand", "tbl_demand_profiles_locationIDs"),
    @("iip-web-0002_geo", "tbl_market_areas"),
    @("iip-web-0002_investment_options", "tbl_renewables_TEST"),
    @("iip-web-0002_investment_options", "tbl_storages"),
    @("iip-web-0002_net_transfer_capacities", "tbl_ntc_area_limits"),
    @("iip-web-0002_net_transfer_capacities", "tbl_ntc_hourly"),
    @("iip-web-0002_powerace", "tbl_area_mapping_ERAA2025"),
    @("iip-web-0002_powerace", "tbl_availability"),
    @("iip-web-0002_powerace", "tbl_weatherYearSequences"),
    @("iip-web-0002_project_bets", "tbl_powerplants_eraa2025"),
    @("iip-web-0002_project_bets", "tbl_powerplants_options"),
    @("iip-web-0002_renewables", "tbl_cf_profiles"),
    @("iip-web-0002_renewables", "tbl_renewables_plants_TEST"),
    @("iip-web-0002_renewables", "tbl_ror_inflow"),
    @("iip-web-0002_storages", "tbl_electricity_storages_ERAA2025"),
    @("iip-web-0002_storages", "tbl_pumpStorageInflows"),
    @("iip-web-0002_storages", "tbl_seasonalStorageInflows")
)

$Missing = New-Object System.Collections.Generic.List[string]

foreach ($Table in $RequiredTables) {
    $SchemaName = $Table[0]
    $TableName = $Table[1]
    $Sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$SchemaName' AND table_name='$TableName';"
    $Result = docker exec --env MYSQL_PWD=powerace $ContainerName mariadb -N -upowerace -e $Sql

    if ($Result.Trim() -ne "1") {
        $Missing.Add("$SchemaName.$TableName")
    }
}

if ($Missing.Count -gt 0) {
    Write-Host "Missing required table(s):"
    $Missing | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "All required PowerACE tables are present."
