param(
    [string]$SqlFile = ".\data\powerace-data.sql"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SqlFile)) {
    throw "SQL file not found: $SqlFile"
}

$ResolvedSqlFile = (Resolve-Path $SqlFile).Path
$TempFile = "$ResolvedSqlFile.normalized"
$DatabasePattern = [regex]'^\s*--\s+Host:.*\s+Database:\s+([^\s]+)\s*$'
$CurrentDatabase = $null

$Reader = [System.IO.StreamReader]::new($ResolvedSqlFile)
$Writer = [System.IO.StreamWriter]::new($TempFile, $false, [System.Text.UTF8Encoding]::new($false))

try {
    while (($Line = $Reader.ReadLine()) -ne $null) {
        $Writer.WriteLine($Line)

        $Match = $DatabasePattern.Match($Line)
        if ($Match.Success) {
            $DatabaseName = $Match.Groups[1].Value
            if ($DatabaseName -ne $CurrentDatabase) {
                $EscapedDatabaseName = $DatabaseName.Replace('`', '``')
                $Writer.WriteLine("")
                $Writer.WriteLine("CREATE DATABASE IF NOT EXISTS ``$EscapedDatabaseName``;")
                $Writer.WriteLine("USE ``$EscapedDatabaseName``;")
                $Writer.WriteLine("")
                $CurrentDatabase = $DatabaseName
            }
        }
    }
}
finally {
    $Reader.Close()
    $Writer.Close()
}

Move-Item -Path $TempFile -Destination $ResolvedSqlFile -Force

Write-Host "Normalized database sections in: $ResolvedSqlFile"
