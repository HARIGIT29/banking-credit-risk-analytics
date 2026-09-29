-- 04_analytical_objects.sql
USE banking_credit_risk;

-- OBJ01 | Customer analytical view
CREATE OR REPLACE VIEW customer_risk_analysis AS
SELECT ID, LIMIT_BAL, SEX, EDUCATION, MARRIAGE, AGE,
       PAY_0, PAY_2, PAY_3, PAY_4, PAY_5, PAY_6,
       BILL_AMT1, BILL_AMT2, BILL_AMT3, BILL_AMT4, BILL_AMT5, BILL_AMT6,
       PAY_AMT1, PAY_AMT2, PAY_AMT3, PAY_AMT4, PAY_AMT5, PAY_AMT6,
       DefaultFlag,
       GREATEST(PAY_0,PAY_2,PAY_3,PAY_4,PAY_5,PAY_6) AS max_delinquency,
       ((PAY_0>0)+(PAY_2>0)+(PAY_3>0)+(PAY_4>0)+(PAY_5>0)+(PAY_6>0)) AS delinquency_count
FROM credit_clients_raw;

-- OBJ02 | Long customer-period table
-- Canonical project mapping:
-- 1 = Apr 2005 = PAY_6 / BILL_AMT6
-- 2 = May 2005 = PAY_5 / BILL_AMT5
-- 3 = Jun 2005 = PAY_4 / BILL_AMT4
-- 4 = Jul 2005 = PAY_3 / BILL_AMT3
-- 5 = Aug 2005 = PAY_2 / BILL_AMT2
-- 6 = Sep 2005 = PAY_0 / BILL_AMT1

DROP TABLE IF EXISTS repayment_monthly;

CREATE TABLE repayment_monthly AS

SELECT
    ID,
    1 AS month_index,
    PAY_6 AS pay_status,
    BILL_AMT6 AS bill_amt,
    PAY_AMT6 AS pay_amt
FROM credit_clients_raw

UNION ALL

SELECT
    ID,
    2 AS month_index,
    PAY_5 AS pay_status,
    BILL_AMT5 AS bill_amt,
    PAY_AMT5 AS pay_amt
FROM credit_clients_raw

UNION ALL

SELECT
    ID,
    3 AS month_index,
    PAY_4 AS pay_status,
    BILL_AMT4 AS bill_amt,
    PAY_AMT4 AS pay_amt
FROM credit_clients_raw

UNION ALL

SELECT
    ID,
    4 AS month_index,
    PAY_3 AS pay_status,
    BILL_AMT3 AS bill_amt,
    PAY_AMT3 AS pay_amt
FROM credit_clients_raw

UNION ALL

SELECT
    ID,
    5 AS month_index,
    PAY_2 AS pay_status,
    BILL_AMT2 AS bill_amt,
    PAY_AMT2 AS pay_amt
FROM credit_clients_raw

UNION ALL

SELECT
    ID,
    6 AS month_index,
    PAY_0 AS pay_status,
    BILL_AMT1 AS bill_amt,
    PAY_AMT1 AS pay_amt
FROM credit_clients_raw;

-- OBJ02B | Enforce one row per customer-period grain
CREATE UNIQUE INDEX ux_repayment_monthly_id_month
    ON repayment_monthly (ID, month_index);

-- OBJ03 | Analytical grain checks
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT ID) AS customers FROM customer_risk_analysis;
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT ID) AS customers, COUNT(DISTINCT month_index) AS months FROM repayment_monthly;
