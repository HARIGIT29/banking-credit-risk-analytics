# SQL Layer — Retail Banking Credit Risk & Customer Analytics

## Recommended run order

1. Run `01_schema.sql`.
2. From the project root, run `tools/CONFIGURE_LOCAL_PATHS.ps1` in PowerShell.
3. Run `02_load_dataset.local.sql` in MySQL Workbench.
4. Run `03_qa_checks.sql`.
5. Run `04_analytical_objects.sql`.
6. Run `05_business_analysis.sql`.
7. Run `06_monthly_behavior.sql`.
8. Run `07_customer_review.sql`.
9. Run `08_validation.sql`.

The public `02_load_dataset.sql` and `00_SQL_MASTER_WORKBOOK.sql` files use the token `__PROJECT_ROOT__` rather than a personal path.

## LOCAL INFILE

`LOAD DATA LOCAL INFILE` requires `local_infile=ON` on the server and client/Workbench connection.

```sql
SHOW VARIABLES LIKE 'local_infile';
```

## Final validation controls

The final validation expects:

- 30,000 customer rows
- 30,000 unique customer IDs
- 6,636 defaults
- 22.12% default rate
- 180,000 monthly customer-period rows
- 180,000 unique customer-period combinations
- 11.71897309% portfolio Payment Coverage within a 0.0001 percentage-point tolerance
