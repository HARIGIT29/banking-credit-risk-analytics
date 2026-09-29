# Configure local project paths for the extracted portfolio project.
# Run from PowerShell at the project root:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\tools\CONFIGURE_LOCAL_PATHS.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ProjectRootForPowerQuery = $ProjectRoot -replace '/', '\\'
$ProjectRootForSql = $ProjectRoot -replace '\\', '/'

$cleanedCsv = Join-Path $ProjectRoot "data\cleaned\banking_credit_risk_cleaned.csv"
if (-not (Test-Path $cleanedCsv)) {
    throw "Could not find bundled cleaned CSV: $cleanedCsv"
}

# Power BI parameter is stored in the PBIP semantic-model expression file.
$pbiExpr = Join-Path $ProjectRoot "powerbi\Retail_Banking_Credit_Risk_Analytics.SemanticModel\definition\expressions.tmdl"
$text = [System.IO.File]::ReadAllText($pbiExpr)
$escaped = [regex]::Escape($ProjectRootForPowerQuery)
$text = [regex]::Replace(
    $text,
    'expression pProjectRoot = ".*?" meta',
    'expression pProjectRoot = "' + $ProjectRootForPowerQuery + '" meta'
)
[System.IO.File]::WriteAllText($pbiExpr, $text, (New-Object System.Text.UTF8Encoding($false)))

# Generate local SQL scripts while leaving the public templates portable.
$sqlFiles = @("02_load_dataset.sql", "00_SQL_MASTER_WORKBOOK.sql")
foreach ($name in $sqlFiles) {
    $src = Join-Path $ProjectRoot "sql\$name"
    $dst = Join-Path $ProjectRoot ("sql\" + [System.IO.Path]::GetFileNameWithoutExtension($name) + ".local.sql")
    $sql = [System.IO.File]::ReadAllText($src)
    $sql = $sql.Replace('__PROJECT_ROOT__', $ProjectRootForSql)
    [System.IO.File]::WriteAllText($dst, $sql, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "Local paths configured." -ForegroundColor Green
Write-Host "Project root: $ProjectRoot"
Write-Host "Cleaned CSV: $cleanedCsv"
Write-Host "Power BI pProjectRoot updated."
Write-Host "Generated: sql\02_load_dataset.local.sql and sql\00_SQL_MASTER_WORKBOOK.local.sql"
Write-Host "Next: open the PBIP, Refresh, then run the SQL local script in MySQL Workbench."
