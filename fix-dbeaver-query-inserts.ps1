param(
    [string]$SqlFile = ".\data\powerace-data.sql"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SqlFile)) {
    throw "SQL file not found: $SqlFile"
}

$ResolvedSqlFile = (Resolve-Path $SqlFile).Path
$TempFile = "$ResolvedSqlFile.fixed"

$Reader = [System.IO.StreamReader]::new($ResolvedSqlFile)
$Writer = [System.IO.StreamWriter]::new($TempFile, $false, [System.Text.UTF8Encoding]::new($false))

$InsideBadInsertHeader = $false
$TargetTable = $null
$FixedHeaders = 0

try {
    while (($Line = $Reader.ReadLine()) -ne $null) {
        if (-not $InsideBadInsertHeader) {
            if ($Line.StartsWith("INSERT INTO ``WITH target_areas AS (")) {
                $InsideBadInsertHeader = $true
                $TargetTable = $null
                continue
            }

            $Writer.WriteLine($Line)
            continue
        }

        if ($Line.Contains("tbl_demand_profiles_locationIDs")) {
            $TargetTable = "``iip-web-0002_demand``.``tbl_demand_profiles_locationIDs``"
        } elseif ($Line.Contains("tbl_cf_profiles")) {
            $TargetTable = "``iip-web-0002_renewables``.``tbl_cf_profiles``"
        }

        $TailMatch = [regex]::Match($Line, '.*`\s+(\(.+)$')
        if ($TailMatch.Success) {
            if ($null -eq $TargetTable) {
                throw "Could not determine target table for bad DBeaver INSERT header."
            }

            $Writer.WriteLine("INSERT INTO $TargetTable $($TailMatch.Groups[1].Value)")
            $InsideBadInsertHeader = $false
            $TargetTable = $null
            $FixedHeaders++
        }
    }

    if ($InsideBadInsertHeader) {
        throw "Reached end of file while repairing a DBeaver INSERT header."
    }
}
finally {
    $Reader.Close()
    $Writer.Close()
}

Move-Item -Path $TempFile -Destination $ResolvedSqlFile -Force

Write-Host "Fixed $FixedHeaders DBeaver query-result INSERT header(s) in: $ResolvedSqlFile"
