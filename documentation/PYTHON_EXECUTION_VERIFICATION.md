# Python Runtime Verification

The packaged notebook `python/Retail_Banking_Credit_Risk_Python_Analysis.ipynb` was executed end-to-end against the bundled `data/raw/default of credit card clients.csv` after the final release fixes.

Verified during execution:

- 30,000 rows and 25 source columns loaded.
- Control-total reconciliation passed for 12 release controls, including Portfolio Payment Coverage.
- Raw-data, feature and denominator checks passed.
- Export QA passed.
- No notebook cell raised an execution error.
- The notebook regenerated the cleaned customer CSV plus monthly behavior, reconciliation, findings, and segment-evidence outputs in `data/cleaned/`.
