# Local Setup — Portfolio Project

The project is intentionally packaged without personal machine paths. The cleaned dataset is bundled under `data/cleaned/`.

## One-time setup on Windows

Open PowerShell in the extracted project root and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\CONFIGURE_LOCAL_PATHS.ps1
```

The script:

1. Finds the project root from the script location.
2. Verifies `data/cleaned/banking_credit_risk_cleaned.csv` exists.
3. Updates the Power BI `pProjectRoot` parameter to the extracted project root.
4. Generates `sql/02_load_dataset.local.sql` and `sql/00_SQL_MASTER_WORKBOOK.local.sql` with the correct local CSV path.

The public SQL templates use the token `__PROJECT_ROOT__` because MySQL Workbench does not resolve a SQL file-relative path for `LOAD DATA LOCAL INFILE`.

## Manual alternative

Power BI: set `pProjectRoot` to the extracted project root, for example:

```text
C:\Users\<your-user>\Downloads\Retail_Banking_Credit_Risk_Analytics_PORTFOLIO_READY
```

SQL: replace `__PROJECT_ROOT__` in `02_load_dataset.sql` with the same root and use forward slashes in the `LOAD DATA LOCAL INFILE` path.

## MySQL prerequisite

`LOAD DATA LOCAL INFILE` must be enabled on the MySQL server and in the client/Workbench connection.

```sql
SHOW VARIABLES LIKE 'local_infile';
```

The result should be `ON`.
