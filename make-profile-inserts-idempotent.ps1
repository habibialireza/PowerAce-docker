param(
    [string]$SqlFile = ".\data\powerace-data.sql"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SqlFile)) {
    throw "SQL file not found: $SqlFile"
}

$ResolvedSqlFile = (Resolve-Path $SqlFile).Path
$TempFile = "$ResolvedSqlFile.idempotent"

$Reader = [System.IO.StreamReader]::new($ResolvedSqlFile)
$Writer = [System.IO.StreamWriter]::new($TempFile, $false, [System.Text.UTF8Encoding]::new($false))
$ChangedLines = 0

try {
    while (($Line = $Reader.ReadLine()) -ne $null) {
        $FixedLine = $Line

        if ($FixedLine.StartsWith("INSERT INTO ``iip-web-0002_renewables``.``tbl_cf_profiles`` ")) {
            $FixedLine = $FixedLine.Replace("INSERT INTO ", "INSERT IGNORE INTO ")
            $ChangedLines++
        } elseif ($FixedLine.StartsWith("INSERT INTO ``iip-web-0002_demand``.``tbl_demand_profiles_locationIDs`` ")) {
            $FixedLine = $FixedLine.Replace("INSERT INTO ", "INSERT IGNORE INTO ")
            $ChangedLines++
        }

        $Writer.WriteLine($FixedLine)
    }
}
finally {
    $Reader.Close()
    $Writer.Close()
}

Move-Item -Path $TempFile -Destination $ResolvedSqlFile -Force

Write-Host "Changed $ChangedLines filtered profile INSERT statement(s) to INSERT IGNORE in: $ResolvedSqlFile"
