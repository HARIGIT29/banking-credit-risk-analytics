# Final Release Checklist — Retail Banking Credit Risk & Customer Analytics

## Fixed in the portfolio package

- [x] Excel workbook independently audited; core formulas and derived fields reconcile.
- [x] Bundled raw and cleaned CSVs included.
- [x] Python control-total loader uses the actual `Excel/Python Control` column.
- [x] Python negative-payment edge case aligned with Excel status hierarchy.
- [x] SQL BA09 negative-payment edge case aligned with the same hierarchy.
- [x] SQL public templates no longer contain a personal machine path.
- [x] Local SQL setup script generates machine-specific `.local.sql` files.
- [x] Power BI `Defaulted Credit-Limit Share` is independent of the Default Status slicer.
- [x] Power BI public parameter no longer contains a personal machine path.
- [x] Power BI setup instructions added.
- [x] Portfolio Overview is set as the active landing page.
- [x] Power BI documentation matches the five-page model and current measures.
- [x] Local Power BI cache/settings artifacts removed from the release ZIP.
- [x] Architecture documentation accurately describes the branching analytical pipeline.

## Remaining runtime checks

- [ ] Run `tools/CONFIGURE_LOCAL_PATHS.ps1` after extraction.
- [ ] Open the PBIP in Power BI Desktop and Refresh.
- [ ] Verify all five pages render without source errors.
- [ ] Verify Default Status slicer leaves `Defaulted Credit-Limit Share` at approximately 17.18% across Default / No Default / All.
- [ ] Test customer drillthrough.
- [ ] Run the generated `sql/02_load_dataset.local.sql` and `08_validation.sql` in MySQL Workbench.

These final runtime steps require the user's local Power BI Desktop and MySQL environments.
