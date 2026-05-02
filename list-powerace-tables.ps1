param(
    [string]$SettingsFile = "..\..\params\Allgemein\settings_Ali.xml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SettingsFile)) {
    throw "Settings file not found: $SettingsFile"
}

$Content = Get-Content -Path $SettingsFile -Raw
$Matches = [regex]::Matches($Content, '`([^`]+)`\.`([^`]+)`')

$Backtick = [char]96
$Tables = New-Object System.Collections.Generic.List[string]
$Tables.Add("${Backtick}iip-web-0002_definitions${Backtick}.${Backtick}tbl_demands${Backtick}")
$Tables.Add("${Backtick}iip-web-0002_definitions${Backtick}.${Backtick}tbl_scenarios${Backtick}")
$Tables.Add("${Backtick}iip-web-0002_geo${Backtick}.${Backtick}tbl_market_areas${Backtick}")

foreach ($Match in $Matches) {
    $DatabaseName = $Match.Groups[1].Value
    $TableName = $Match.Groups[2].Value
    $Tables.Add("${Backtick}${DatabaseName}${Backtick}.${Backtick}${TableName}${Backtick}")
}

$Tables |
    Sort-Object -Unique |
    ForEach-Object { Write-Host $_ }
