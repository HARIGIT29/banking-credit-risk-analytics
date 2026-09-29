# Power BI Build Notes — Final Release

## Project files

Open `Retail_Banking_Credit_Risk_Analytics.pbip` in Power BI Desktop.

## Data source

The final package includes `../data/cleaned/banking_credit_risk_cleaned.csv`. The semantic model uses `pProjectRoot` and reads `data/cleaned/banking_credit_risk_cleaned.csv` from that project root.

The public PBIP contains a neutral placeholder path. Run `tools/CONFIGURE_LOCAL_PATHS.ps1` from the project root, or set `pProjectRoot` manually in Power Query.

## Page structure

1. Portfolio Overview
2. Customer Risk & Segmentation
3. Repayment Behaviour
4. Risk Monitoring & Customer Review
5. Methodology & Definitions

## Model relationships

- `FactRepayment[ID]` → `DimCustomer[ID]`
- `FactRepayment[MonthIndex]` → `DimMonth[MonthIndex]`

`FactRepayment` uses the canonical six-period mapping documented below.

## Canonical definitions

- Observed Default Rate = Defaulted Customers / Total Customers
- Delinquency Rate = Customers With Delinquency / Total Customers
- Portfolio Payment Coverage = Total Payment / Total Positive Bill
- Monthly Payment Coverage = Monthly Total Payment / Monthly Total Positive Bills
- Monthly Delay Rate = customer-periods with `PayStatus > 0` / customer-periods
- Defaulted Credit-Limit Share = defaulted credit limit / total credit limit, with both `Default_Label` and the raw default flag removed from filter context so the KPI is stable under Default Status selection.
- Latest Credit Utilization proxy = `BILL_AMT1 / LIMIT_BAL`; non-positive bill amounts are retained in the raw calculation and therefore appear in the `<25%` utilization band.

## Month mapping

1 Apr 2005 = `PAY_6 / BILL_AMT6 / PAY_AMT6`  
2 May 2005 = `PAY_5 / BILL_AMT5 / PAY_AMT5`  
3 Jun 2005 = `PAY_4 / BILL_AMT4 / PAY_AMT4`  
4 Jul 2005 = `PAY_3 / BILL_AMT3 / PAY_AMT3`  
5 Aug 2005 = `PAY_2 / BILL_AMT2 / PAY_AMT2`  
6 Sep 2005 = `PAY_0 / BILL_AMT1 / PAY_AMT1`

## Expected headline figures

- Customers: 30,000
- Defaults: 6,636
- Observed default rate: 22.12%
- Total credit limit: NT$5,024,529,680
- Average credit limit: NT$167,484
- Average 6M bill: NT$44,977
- Average 6M payment: NT$5,275
- Customers with delinquency: 10,069
- Delinquency rate: 33.56%
- Positive-bill customers: 27,402
- Positive-bill no-payment customers: 3,495
- Positive-bill no-payment rate: 12.75%
- Portfolio six-period Payment Coverage: 11.71897309%

## Final Desktop step

The final package requires one local Power BI Desktop refresh/render and interaction test after setting `pProjectRoot`.
