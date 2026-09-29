# Retail Banking Credit Risk & Customer Analytics — Portfolio Release

## Project objective

Analyze a historical retail credit-card customer portfolio to understand observed default risk, delinquency patterns, credit exposure concentration, repayment behavior, and monitoring signals.

## End-to-end architecture

```text
Bundled UCI source CSV (25 fields)
        │
        ├── Excel — source audit + formulas + KPI / pivot analysis
        │
        └── Python — reproducible feature engineering + EDA + validation
                 │
                 └── Standardized analytical CSV (43 fields)
                        │
                        ├── MySQL — schema + QA + analytical objects + business analysis
                        │
                        └── Power BI — Power Query + semantic model + DAX + dashboard

Cross-tool control totals reconcile the analytical branches.
```

The project is intentionally a branching analytical pipeline rather than a claim that Power BI consumes the MySQL database.

## Final package

- `excel/` — validated source workbook snapshot.
- `python/` — reproducible notebook with bundled-data discovery and control-total validation.
- `sql/` — synchronized modular scripts and master workbook.
- `powerbi/` — PBIP/PBIR + TMDL project with five report pages.
- `data/raw/` — bundled 25-field source CSV.
- `data/cleaned/` — bundled 43-column analytical CSV.
- `documentation/` — controls, audit notes and setup instructions.
- `tools/` — one-time local path configuration script.

## Local setup

Run `tools/CONFIGURE_LOCAL_PATHS.ps1` once after extracting the project. It configures the Power BI project-root parameter and generates local SQL scripts without putting your personal Windows path into the portfolio templates.

See `documentation/LOCAL_SETUP.md`.

## Headline control totals

| Metric | Release control |
|---|---:|
| Customers | 30,000 |
| Defaults | 6,636 |
| Observed default rate | 22.12% |
| Total credit limit | NT$5,024,529,680 |
| Average credit limit | NT$167,484 |
| Customers with delinquency | 10,069 |
| Delinquency rate | 33.56% |
| Positive-bill customers | 27,402 |
| Positive-bill no-payment customers | 3,495 |
| Positive-bill no-payment rate | 12.75% |
| Six-period portfolio Payment Coverage | 11.71897309% |

## Key analytical definitions

**Delinquency:** positive repayment-status code across the six observed periods.

**Portfolio Payment Coverage:** total payments divided by total positive bills.

**Positive bill:** bill amount greater than zero for the relevant period.

**Latest Credit Utilization proxy:** latest observed bill amount divided by credit limit (`BILL_AMT1 / LIMIT_BAL`). Non-positive latest bills are retained in the raw proxy calculation; therefore those records fall in the `<25%` band and are not interpreted as positive utilization.

**Latest Payment-vs-Bill Status:** for positive bills, negative payment, no payment, payment below bill, payment equal to bill, or payment above bill. The current dataset contains no negative payments.

## Portfolio scope and limitations

The dataset is historical public credit-card data. Findings describe observed patterns in the case-study population and are not live-bank lending or collections decisions. Correlation should not be interpreted as causation.

## Verification status

Excel calculations were independently recomputed and matched. Python feature engineering and control-total validation were executed against the bundled source. SQL logic and Power BI model metadata were statically validated. The remaining runtime step is the final Power BI Desktop refresh/render and a live MySQL execution on the user's machine.
