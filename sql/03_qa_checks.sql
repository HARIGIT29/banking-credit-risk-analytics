-- =====================================================================
-- RETAIL BANKING CREDIT RISK & CUSTOMER ANALYTICS
-- 03_qa_checks.sql
-- =====================================================================
-- Purpose: Validate the imported customer-level dataset before business
-- analysis. This file contains base-table QA only so it can be executed
-- immediately after the CSV load.
--
-- Expected base-table grain: 1 row per customer
-- Expected records: 30,000 customers
-- =====================================================================

USE banking_credit_risk;

-- =====================================================================
-- QA01 | BASE TABLE GRAIN
-- Business question: Is the imported table one row per customer?
-- Expected: rows = 30,000 and customers = 30,000
-- =====================================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ID) AS customers
FROM credit_clients_raw;

-- =====================================================================
-- QA02 | DUPLICATE CUSTOMER IDS
-- Expected: zero result rows
-- =====================================================================
SELECT
    ID,
    COUNT(*) AS duplicate_count
FROM credit_clients_raw
GROUP BY ID
HAVING COUNT(*) > 1;

-- =====================================================================
-- QA03 | BUSINESS-CRITICAL NULLS
-- =====================================================================
SELECT
    SUM(ID IS NULL) AS null_id,
    SUM(LIMIT_BAL IS NULL) AS null_limit_bal,
    SUM(AGE IS NULL) AS null_age,
    SUM(DefaultFlag IS NULL) AS null_default_flag
FROM credit_clients_raw;

-- =====================================================================
-- QA04 | TARGET DISTRIBUTION
-- Business question: Is DefaultFlag binary and what is its distribution?
-- =====================================================================
SELECT
    DefaultFlag,
    COUNT(*) AS customers
FROM credit_clients_raw
GROUP BY DefaultFlag
ORDER BY DefaultFlag;

-- =====================================================================
-- QA05 | EDUCATION CODE AUDIT
-- Keep raw codes; do not invent labels in the QA layer.
-- =====================================================================
SELECT
    EDUCATION,
    COUNT(*) AS customers
FROM credit_clients_raw
GROUP BY EDUCATION
ORDER BY EDUCATION;

-- =====================================================================
-- QA06 | MARRIAGE CODE AUDIT
-- Keep raw codes; do not invent labels in the QA layer.
-- =====================================================================
SELECT
    MARRIAGE,
    COUNT(*) AS customers
FROM credit_clients_raw
GROUP BY MARRIAGE
ORDER BY MARRIAGE;

-- =====================================================================
-- QA07 | REPAYMENT STATUS CODE AUDIT
-- PAY_0 is a repayment-status code, not a payment amount.
-- =====================================================================
SELECT
    PAY_0,
    COUNT(*) AS customers
FROM credit_clients_raw
GROUP BY PAY_0
ORDER BY PAY_0;

-- =====================================================================
-- QA08 | FULL SIX-MONTH RANGE CHECK
-- Validate all repayment-status, bill and payment fields across
-- the six observed periods.
-- =====================================================================
SELECT
    MIN(AGE) AS min_age,
    MAX(AGE) AS max_age,
    MIN(LIMIT_BAL) AS min_credit_limit,
    MAX(LIMIT_BAL) AS max_credit_limit,

    MIN(PAY_0) AS min_pay_0,
    MAX(PAY_0) AS max_pay_0,

    MIN(PAY_2) AS min_pay_2,
    MAX(PAY_2) AS max_pay_2,

    MIN(PAY_3) AS min_pay_3,
    MAX(PAY_3) AS max_pay_3,

    MIN(PAY_4) AS min_pay_4,
    MAX(PAY_4) AS max_pay_4,

    MIN(PAY_5) AS min_pay_5,
    MAX(PAY_5) AS max_pay_5,

    MIN(PAY_6) AS min_pay_6,
    MAX(PAY_6) AS max_pay_6,

    MIN(BILL_AMT1) AS min_bill_amt1,
    MAX(BILL_AMT1) AS max_bill_amt1,

    MIN(BILL_AMT2) AS min_bill_amt2,
    MAX(BILL_AMT2) AS max_bill_amt2,

    MIN(BILL_AMT3) AS min_bill_amt3,
    MAX(BILL_AMT3) AS max_bill_amt3,

    MIN(BILL_AMT4) AS min_bill_amt4,
    MAX(BILL_AMT4) AS max_bill_amt4,

    MIN(BILL_AMT5) AS min_bill_amt5,
    MAX(BILL_AMT5) AS max_bill_amt5,

    MIN(BILL_AMT6) AS min_bill_amt6,
    MAX(BILL_AMT6) AS max_bill_amt6,

    MIN(PAY_AMT1) AS min_pay_amt1,
    MAX(PAY_AMT1) AS max_pay_amt1,

    MIN(PAY_AMT2) AS min_pay_amt2,
    MAX(PAY_AMT2) AS max_pay_amt2,

    MIN(PAY_AMT3) AS min_pay_amt3,
    MAX(PAY_AMT3) AS max_pay_amt3,

    MIN(PAY_AMT4) AS min_pay_amt4,
    MAX(PAY_AMT4) AS max_pay_amt4,

    MIN(PAY_AMT5) AS min_pay_amt5,
    MAX(PAY_AMT5) AS max_pay_amt5,

    MIN(PAY_AMT6) AS min_pay_amt6,
    MAX(PAY_AMT6) AS max_pay_amt6

FROM credit_clients_raw;

-- =====================================================================
-- QA08B | REPAYMENT STATUS VALIDITY ACROSS ALL SIX PERIODS
-- Expected: repayment status codes remain within the documented
-- observed range. No NULLs are expected in the current dataset.
-- =====================================================================
SELECT
    SUM(PAY_0 IS NULL) AS null_pay_0,
    SUM(PAY_2 IS NULL) AS null_pay_2,
    SUM(PAY_3 IS NULL) AS null_pay_3,
    SUM(PAY_4 IS NULL) AS null_pay_4,
    SUM(PAY_5 IS NULL) AS null_pay_5,
    SUM(PAY_6 IS NULL) AS null_pay_6,

    SUM(PAY_0 NOT BETWEEN -2 AND 8) AS invalid_pay_0,
    SUM(PAY_2 NOT BETWEEN -2 AND 8) AS invalid_pay_2,
    SUM(PAY_3 NOT BETWEEN -2 AND 8) AS invalid_pay_3,
    SUM(PAY_4 NOT BETWEEN -2 AND 8) AS invalid_pay_4,
    SUM(PAY_5 NOT BETWEEN -2 AND 8) AS invalid_pay_5,
    SUM(PAY_6 NOT BETWEEN -2 AND 8) AS invalid_pay_6

FROM credit_clients_raw;
-- =====================================================================
-- QA09 | DEFAULT COUNT AND RATE
-- Expected: 6,636 defaults and 22.12%
-- =====================================================================
SELECT
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM credit_clients_raw;

-- =====================================================================
-- QA10 | LATEST-MONTH BILL SIGN AUDIT
-- Expected from the validated analysis:
-- negative = 590, zero = 2,008, positive = 27,402
-- =====================================================================
SELECT
    SUM(BILL_AMT1 < 0) AS negative_bill,
    SUM(BILL_AMT1 = 0) AS zero_bill,
    SUM(BILL_AMT1 > 0) AS positive_bill
FROM credit_clients_raw;

-- =====================================================================
-- QA11 | LATEST-MONTH PAYMENT SIGN AUDIT
-- Expected: negative = 0
-- =====================================================================
SELECT
    SUM(PAY_AMT1 < 0) AS negative_payment,
    SUM(PAY_AMT1 = 0) AS zero_payment,
    SUM(PAY_AMT1 > 0) AS positive_payment
FROM credit_clients_raw;

-- =====================================================================
-- QA12 | POSITIVE-BILL / NO-PAYMENT CHECK
-- Expected: 27,402 positive-bill customers,
-- 3,495 no-payment customers, about 12.75%.
-- =====================================================================
SELECT
    COUNT(*) AS positive_bill_customers,
    SUM(PAY_AMT1 = 0) AS no_payment_customers,
    ROUND(
        100 * SUM(PAY_AMT1 = 0) / COUNT(*),
        2
    ) AS no_payment_rate_pct
FROM credit_clients_raw
WHERE BILL_AMT1 > 0;

-- =====================================================================
-- QA13 | FINAL BASE-TABLE CHECK
-- Compact pass/fail-style control summary.
-- =====================================================================
SELECT
    COUNT(*) AS customers,
    COUNT(DISTINCT ID) AS unique_customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct,
    SUM(ID IS NULL) AS null_id,
    SUM(DefaultFlag IS NULL) AS null_default_flag
FROM credit_clients_raw;

-- =====================================================================
-- NOTE ON POST-OBJECT QA
-- Checks involving customer_risk_analysis or repayment_monthly belong in
-- 05_business_analysis.sql / 04_analytical_objects.sql or the final
-- validation script because those objects do not exist immediately after
-- the CSV import.
-- =====================================================================
