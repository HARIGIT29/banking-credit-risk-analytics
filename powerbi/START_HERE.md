# Power BI — Start Here

## What is included

This folder is a Power BI Project (PBIP/PBIR + TMDL) with a bundled cleaned CSV under `../data/cleaned/`. The report has five pages and a four-table analytical model.

## Pages

1. **01 — Portfolio Overview**
2. **02 — Customer Risk & Segmentation**
3. **03 — Repayment Behaviour**
4. **04 — Risk Monitoring & Customer Review**
5. **05 — Methodology & Definitions**

## Model

- `Customer_Risk` — customer-level source + derived features and portfolio measures
- `DimCustomer` — customer dimension derived from the customer-level source
- `FactRepayment` — six-period long-format repayment fact
- `DimMonth` — canonical Apr–Sep 2005 month dimension

## Before opening

The public package does not contain a personal Windows path. From the extracted project root, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\CONFIGURE_LOCAL_PATHS.ps1
```

The script sets the Power Query parameter `pProjectRoot` to the extracted project root. The bundled dataset is `data/cleaned/banking_credit_risk_cleaned.csv`.

You can also set `pProjectRoot` manually in Power Query.

## Canonical metrics

- Observed Default Rate = Defaulted Customers / Total Customers
- Delinquency Rate = Customers With Delinquency / Total Customers
- Portfolio Payment Coverage = Total Payment / Total Positive Bill
- Positive bill means `bill_amt > 0` for the relevant period.
- Defaulted Credit-Limit Share = defaulted credit limit / total credit limit, with `Default_Label` and the raw target flag removed from the numerator/denominator context so the KPI remains stable under the Default Status slicer.

## Month mapping

1 = Apr 2005 = `PAY_6 / BILL_AMT6 / PAY_AMT6`  
2 = May 2005 = `PAY_5 / BILL_AMT5 / PAY_AMT5`  
3 = Jun 2005 = `PAY_4 / BILL_AMT4 / PAY_AMT4`  
4 = Jul 2005 = `PAY_3 / BILL_AMT3 / PAY_AMT3`  
5 = Aug 2005 = `PAY_2 / BILL_AMT2 / PAY_AMT2`  
6 = Sep 2005 = `PAY_0 / BILL_AMT1 / PAY_AMT1`

## Final Desktop test

After setup, open `Retail_Banking_Credit_Risk_Analytics.pbip`, refresh, inspect all five pages, test the Default Status slicer and customer drillthrough, then save. The Portfolio Overview page is the intended landing page.
