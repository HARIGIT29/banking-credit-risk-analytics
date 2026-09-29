# Final Cross-Tool Audit — Post-Fix Release

## Scope

This release was audited across the Excel workbook, bundled source/cleaned CSVs, Python notebook, modular/master SQL, and Power BI PBIP/TMDL/PBIR definitions. Core metrics were independently recomputed from the raw source.

## Core controls

| Metric | Release control |
|---|---:|
| Customers | 30,000 |
| Defaults | 6,636 |
| Observed Default Rate | 22.12% |
| Total Credit Limit | NT$5,024,529,680 |
| Customers With Delinquency | 10,069 |
| Delinquency Rate | 33.56% |
| Positive-Bill Customers | 27,402 |
| Positive-Bill No-Payment Customers | 3,495 |
| Positive-Bill No-Payment Rate | 12.75% |
| Six-period portfolio Payment Coverage | 11.71897309% |

## Post-fix changes

1. **Power BI DAX:** `Defaulted Credit-Limit Share` now removes both `Default_Label` and the raw default flag from its numerator/denominator context, preventing 100%/0% distortion under the Default Status slicer.
2. **SQL portability:** public SQL templates use `__PROJECT_ROOT__`; a local setup script generates machine-specific SQL files after extraction.
3. **Power BI portability:** `pProjectRoot` is a neutral public placeholder; the same local setup script configures the extracted project root.
4. **Python:** control-total reconciliation now reads the actual `Excel/Python Control` column in the bundled control CSV.
5. **Edge-case consistency:** negative-payment handling is explicit across Python/SQL/Excel definitions. The current data contain zero negative-payment records, so headline numbers are unchanged.
6. **Documentation:** README, Power BI documentation, SQL documentation and release checklist were synchronized to the actual model.
7. **Landing page:** `01 — Portfolio Overview` is now the active report page.
8. **Packaging:** local Power BI cache/settings artifacts are excluded from the shareable release.

## Remaining limitations

- A live MySQL engine was not executed in this environment.
- Power BI Desktop refresh/render was not executed in this environment.
- The utilization proxy intentionally uses `BILL_AMT1 / LIMIT_BAL`; non-positive latest bills therefore fall into the `<25%` band. This is documented and should be interpreted as a raw proxy, not a positive-utilization estimate.
- The project uses historical public credit-card data and supports descriptive case-study analysis, not production underwriting decisions.

## Release position

The analytical calculations and internal definitions are in a substantially reconciled state. Final portfolio release still depends on the local Power BI refresh/interaction smoke test and live MySQL validation.
