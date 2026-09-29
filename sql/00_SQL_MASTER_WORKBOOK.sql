-- =====================================================================
-- 00_SQL_MASTER_WORKBOOK.sql
-- Retail Banking Credit Risk & Customer Analytics
-- Synchronized release build: 2026-09-29
-- =====================================================================

-- =====================================================================
-- 01_schema.sql
-- =====================================================================

-- 01_schema.sql
-- Create database and base table.
CREATE DATABASE IF NOT EXISTS banking_credit_risk;
USE banking_credit_risk;

-- SCHEMA01 | One row per customer
CREATE TABLE IF NOT EXISTS credit_clients_raw (
    ID INT PRIMARY KEY,
    LIMIT_BAL DECIMAL(14,2), SEX INT, EDUCATION INT, MARRIAGE INT, AGE INT,
    PAY_0 INT, PAY_2 INT, PAY_3 INT, PAY_4 INT, PAY_5 INT, PAY_6 INT,
    BILL_AMT1 DECIMAL(14,2), BILL_AMT2 DECIMAL(14,2), BILL_AMT3 DECIMAL(14,2),
    BILL_AMT4 DECIMAL(14,2), BILL_AMT5 DECIMAL(14,2), BILL_AMT6 DECIMAL(14,2),
    PAY_AMT1 DECIMAL(14,2), PAY_AMT2 DECIMAL(14,2), PAY_AMT3 DECIMAL(14,2),
    PAY_AMT4 DECIMAL(14,2), PAY_AMT5 DECIMAL(14,2), PAY_AMT6 DECIMAL(14,2),
    DefaultFlag TINYINT
);


-- SCHEMA02 | LOCAL INFILE must be enabled for LOAD DATA LOCAL INFILE
SHOW VARIABLES LIKE 'local_infile';

-- =====================================================================
-- 02_load_dataset.sql
-- =====================================================================

-- 02_load_dataset.sql
-- Import the cleaned CSV. The CSV has 43 columns; only the 25 base fields
-- are loaded into credit_clients_raw. The 18 derived fields are read into
-- session variables and intentionally ignored by the SQL base table.

USE banking_credit_risk;

-- LOAD01 | Reset base table before deterministic reload
TRUNCATE TABLE credit_clients_raw;

-- LOAD02 | Import cleaned dataset
LOAD DATA LOCAL INFILE '__PROJECT_ROOT__/data/cleaned/banking_credit_risk_cleaned.csv'
INTO TABLE credit_clients_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @ID, @LIMIT_BAL, @SEX, @EDUCATION, @MARRIAGE, @AGE,
    @PAY_0, @PAY_2, @PAY_3, @PAY_4, @PAY_5, @PAY_6,
    @BILL_AMT1, @BILL_AMT2, @BILL_AMT3, @BILL_AMT4, @BILL_AMT5, @BILL_AMT6,
    @PAY_AMT1, @PAY_AMT2, @PAY_AMT3, @PAY_AMT4, @PAY_AMT5, @PAY_AMT6,
    @DefaultFlag,
    @Avg_Bill_6M, @Avg_Payment_6M, @Credit_Utilization,
    @Payment_to_Bill_Ratio_Valid, @Bill_Amount_Status, @Payment_vs_Bill_Status,
    @PAY_0_Delayed, @PAY_2_Delayed, @PAY_3_Delayed, @PAY_4_Delayed, @PAY_5_Delayed, @PAY_6_Delayed,
    @Delinquency_Count, @Max_Delinquency_Code, @Default_Label, @Age_Group,
    @Credit_Limit_Band, @Utilization_Band
)
SET
    ID=@ID,
    LIMIT_BAL=@LIMIT_BAL,
    SEX=@SEX,
    EDUCATION=@EDUCATION,
    MARRIAGE=@MARRIAGE,
    AGE=@AGE,
    PAY_0=@PAY_0,
    PAY_2=@PAY_2,
    PAY_3=@PAY_3,
    PAY_4=@PAY_4,
    PAY_5=@PAY_5,
    PAY_6=@PAY_6,
    BILL_AMT1=@BILL_AMT1,
    BILL_AMT2=@BILL_AMT2,
    BILL_AMT3=@BILL_AMT3,
    BILL_AMT4=@BILL_AMT4,
    BILL_AMT5=@BILL_AMT5,
    BILL_AMT6=@BILL_AMT6,
    PAY_AMT1=@PAY_AMT1,
    PAY_AMT2=@PAY_AMT2,
    PAY_AMT3=@PAY_AMT3,
    PAY_AMT4=@PAY_AMT4,
    PAY_AMT5=@PAY_AMT5,
    PAY_AMT6=@PAY_AMT6,
    DefaultFlag=@DefaultFlag;

-- LOAD03 | Verify import
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT ID) AS customers FROM credit_clients_raw;




-- =====================================================================
-- 03_qa_checks.sql
-- =====================================================================

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

-- =====================================================================
-- 04_analytical_objects.sql
-- =====================================================================

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

-- =====================================================================
-- 05_business_analysis.sql
-- =====================================================================

-- =====================================================================
-- RETAIL BANKING CREDIT RISK & CUSTOMER ANALYTICS
-- 05_business_analysis.sql
-- =====================================================================
-- Purpose: Business analysis after the dataset is loaded and the
-- analytical objects customer_risk_analysis and repayment_monthly exist.
-- Query labels make the workbook easy to discuss in an interview.
--
-- BA01-BA14 = customer-level / portfolio analysis
-- BA15-BA18 = monthly behavior analysis
-- =====================================================================

USE banking_credit_risk;

-- =====================================================================
-- BA01 | OVERALL PORTFOLIO KPIs
-- Business question: What is the overall portfolio risk picture?
-- =====================================================================
SELECT
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 2) AS avg_credit_limit,
    SUM(LIMIT_BAL) AS total_credit_limit,
    ROUND(AVG(BILL_AMT1), 2) AS avg_latest_bill
FROM credit_clients_raw;

-- =====================================================================
-- BA02 | DEFAULT RATE BY AGE BAND
-- =====================================================================
SELECT
    CASE
        WHEN AGE < 25 THEN '<25'
        WHEN AGE < 35 THEN '25-34'
        WHEN AGE < 45 THEN '35-44'
        WHEN AGE < 55 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM credit_clients_raw
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN '<25' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        WHEN '55+' THEN 5
    END;

-- =====================================================================
-- BA03 | DEFAULT RATE + EXPOSURE BY CREDIT-LIMIT BAND
-- =====================================================================
WITH credit_segments AS (
    SELECT
        CASE
            WHEN LIMIT_BAL < 50000 THEN '<50K'
            WHEN LIMIT_BAL < 100000 THEN '50K-99K'
            WHEN LIMIT_BAL < 200000 THEN '100K-199K'
            WHEN LIMIT_BAL < 500000 THEN '200K-499K'
            ELSE '500K+'
        END AS credit_band,
        COUNT(*) AS customers,
        SUM(DefaultFlag) AS defaulted_customers,
        SUM(LIMIT_BAL) AS total_credit_limit,
        AVG(LIMIT_BAL) AS avg_credit_limit,
        AVG(DefaultFlag) * 100 AS default_rate_pct
    FROM credit_clients_raw
    GROUP BY
        CASE
            WHEN LIMIT_BAL < 50000 THEN '<50K'
            WHEN LIMIT_BAL < 100000 THEN '50K-99K'
            WHEN LIMIT_BAL < 200000 THEN '100K-199K'
            WHEN LIMIT_BAL < 500000 THEN '200K-499K'
            ELSE '500K+'
        END
)
SELECT
    credit_band,
    customers,
    defaulted_customers,
    ROUND(default_rate_pct, 2) AS default_rate_pct,
    total_credit_limit,
    ROUND(avg_credit_limit, 2) AS avg_credit_limit,
    ROUND(
        100 * total_credit_limit / SUM(total_credit_limit) OVER (),
        2
    ) AS exposure_share_pct
FROM credit_segments
ORDER BY
    CASE credit_band
        WHEN '<50K' THEN 1
        WHEN '50K-99K' THEN 2
        WHEN '100K-199K' THEN 3
        WHEN '200K-499K' THEN 4
        WHEN '500K+' THEN 5
    END;

-- =====================================================================
-- BA04 | DEFAULT RATE BY EDUCATION CODE
-- =====================================================================
SELECT
    EDUCATION AS education_code,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM credit_clients_raw
GROUP BY EDUCATION
ORDER BY EDUCATION;

-- =====================================================================
-- BA05 | DEFAULT RATE BY MARRIAGE CODE
-- =====================================================================
SELECT
    MARRIAGE AS marriage_code,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM credit_clients_raw
GROUP BY MARRIAGE
ORDER BY MARRIAGE;

-- =====================================================================
-- BA06 | DEFAULT RATE BY LATEST REPAYMENT STATUS (PAY_0)
-- =====================================================================
SELECT
    PAY_0 AS pay_0_status,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM credit_clients_raw
GROUP BY PAY_0
ORDER BY PAY_0;

-- =====================================================================
-- BA07 | DEFAULT RATE BY DELINQUENCY COUNT
-- Positive PAY_* status codes count as delayed periods under this
-- documented project rule.
-- =====================================================================
SELECT
    delinquency_count,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM customer_risk_analysis
GROUP BY delinquency_count
ORDER BY delinquency_count;

-- =====================================================================
-- BA08 | DEFAULT RATE BY MAXIMUM OBSERVED DELINQUENCY
-- =====================================================================
SELECT
    max_delinquency,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM customer_risk_analysis
GROUP BY max_delinquency
ORDER BY max_delinquency;

-- =====================================================================
-- BA09 | LATEST-MONTH PAYMENT VS BILL BEHAVIOR
-- Population: customers with BILL_AMT1 > 0.
-- =====================================================================
WITH payment_behavior AS (
    SELECT
        ID,
        DefaultFlag,
        CASE
            WHEN BILL_AMT1 > 0 AND PAY_AMT1 < 0
                THEN 'Negative Payment'
            WHEN BILL_AMT1 > 0 AND PAY_AMT1 = 0
                THEN 'No Payment'
            WHEN BILL_AMT1 > 0 AND PAY_AMT1 > BILL_AMT1
                THEN 'Payment Above Bill'
            WHEN BILL_AMT1 > 0 AND PAY_AMT1 < BILL_AMT1
                THEN 'Payment Below Bill'
            WHEN BILL_AMT1 > 0 AND PAY_AMT1 = BILL_AMT1
                THEN 'Payment Equals Bill'
        END AS payment_behavior
    FROM credit_clients_raw
)
SELECT
    payment_behavior,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct
FROM payment_behavior
WHERE payment_behavior IS NOT NULL
GROUP BY payment_behavior
ORDER BY
    CASE payment_behavior
        WHEN 'Negative Payment' THEN 1
        WHEN 'No Payment' THEN 2
        WHEN 'Payment Below Bill' THEN 3
        WHEN 'Payment Equals Bill' THEN 4
        WHEN 'Payment Above Bill' THEN 5
    END;

-- =====================================================================
-- BA10 | AVERAGE CUSTOMER PAYMENT COVERAGE BY DEFAULT STATUS
-- Definition:
--   Customer-level Payment Coverage =
--   Total Payments / Total Positive Bills across six periods.
--
--   BA10 reports the average of customer-level payment coverage
--   within each observed default-status group.
--
--   Zero positive-bill denominator is treated as zero coverage.
-- =====================================================================
WITH customer_payment AS (
    SELECT
        ID,
        DefaultFlag,
        CASE
            WHEN (
                CASE WHEN BILL_AMT1 > 0 THEN BILL_AMT1 ELSE 0 END +
                CASE WHEN BILL_AMT2 > 0 THEN BILL_AMT2 ELSE 0 END +
                CASE WHEN BILL_AMT3 > 0 THEN BILL_AMT3 ELSE 0 END +
                CASE WHEN BILL_AMT4 > 0 THEN BILL_AMT4 ELSE 0 END +
                CASE WHEN BILL_AMT5 > 0 THEN BILL_AMT5 ELSE 0 END +
                CASE WHEN BILL_AMT6 > 0 THEN BILL_AMT6 ELSE 0 END
            ) = 0
            THEN 0
            ELSE
                (
                    PAY_AMT1 + PAY_AMT2 + PAY_AMT3 +
                    PAY_AMT4 + PAY_AMT5 + PAY_AMT6
                ) /
                (
                    CASE WHEN BILL_AMT1 > 0 THEN BILL_AMT1 ELSE 0 END +
                    CASE WHEN BILL_AMT2 > 0 THEN BILL_AMT2 ELSE 0 END +
                    CASE WHEN BILL_AMT3 > 0 THEN BILL_AMT3 ELSE 0 END +
                    CASE WHEN BILL_AMT4 > 0 THEN BILL_AMT4 ELSE 0 END +
                    CASE WHEN BILL_AMT5 > 0 THEN BILL_AMT5 ELSE 0 END +
                    CASE WHEN BILL_AMT6 > 0 THEN BILL_AMT6 ELSE 0 END
                )
        END AS payment_coverage
    FROM credit_clients_raw
)
SELECT
    DefaultFlag AS default_flag,
    COUNT(*) AS customers,
    ROUND(AVG(payment_coverage) * 100, 2) AS avg_customer_payment_coverage_pct
FROM customer_payment
GROUP BY DefaultFlag
ORDER BY DefaultFlag;

-- =====================================================================
-- BA11 | EXPOSURE BY OBSERVED DEFAULT STATUS
-- Credit limit is treated as a portfolio exposure-capacity proxy.
-- =====================================================================
SELECT
    DefaultFlag AS default_flag,
    COUNT(*) AS customers,
    SUM(LIMIT_BAL) AS total_credit_limit,
    ROUND(AVG(LIMIT_BAL), 2) AS avg_credit_limit,
    ROUND(AVG(BILL_AMT1), 2) AS avg_latest_bill,
    ROUND(
        100 * SUM(LIMIT_BAL) / SUM(SUM(LIMIT_BAL)) OVER (),
        2
    ) AS exposure_share_pct
FROM credit_clients_raw
GROUP BY DefaultFlag
ORDER BY DefaultFlag;

-- =====================================================================
-- BA12 | EXPOSURE BY DELINQUENCY COUNT
-- =====================================================================
SELECT
    delinquency_count,
    COUNT(*) AS customers,
    SUM(DefaultFlag) AS defaulted_customers,
    SUM(LIMIT_BAL) AS total_credit_limit,
    ROUND(AVG(LIMIT_BAL), 2) AS avg_credit_limit,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct,
    ROUND(
        100 * SUM(LIMIT_BAL) / SUM(SUM(LIMIT_BAL)) OVER (),
        2
    ) AS exposure_share_pct
FROM customer_risk_analysis
GROUP BY delinquency_count
ORDER BY delinquency_count;

-- =====================================================================
-- BA13 | RANK CUSTOMERS BY CREDIT LIMIT
-- =====================================================================
SELECT
    ID,
    LIMIT_BAL,
    DefaultFlag,
    RANK() OVER (
        ORDER BY LIMIT_BAL DESC
    ) AS credit_limit_rank
FROM credit_clients_raw
ORDER BY credit_limit_rank
LIMIT 100;

-- =====================================================================
-- BA14 | CUSTOMER CREDIT LIMIT VS CREDIT-BAND AVERAGE
-- =====================================================================
WITH customer_bands AS (
    SELECT
        ID,
        LIMIT_BAL,
        DefaultFlag,
        CASE
            WHEN LIMIT_BAL < 50000 THEN '<50K'
            WHEN LIMIT_BAL < 100000 THEN '50K-99K'
            WHEN LIMIT_BAL < 200000 THEN '100K-199K'
            WHEN LIMIT_BAL < 500000 THEN '200K-499K'
            ELSE '500K+'
        END AS credit_band
    FROM credit_clients_raw
)
SELECT
    ID,
    LIMIT_BAL,
    credit_band,
    DefaultFlag,
    ROUND(
        AVG(LIMIT_BAL) OVER (PARTITION BY credit_band),
        2
    ) AS band_avg_limit,
    ROUND(
        LIMIT_BAL - AVG(LIMIT_BAL) OVER (PARTITION BY credit_band),
        2
    ) AS vs_band_avg
FROM customer_bands
ORDER BY credit_band, LIMIT_BAL DESC;

-- =====================================================================
-- BA15 | MONTHLY REPAYMENT BEHAVIOR
-- Monthly table grain = one row per customer per period.
-- =====================================================================
SELECT
    month_index,
    COUNT(*) AS customer_periods,
    ROUND(AVG(pay_status > 0) * 100, 2) AS delay_rate_pct,
    ROUND(
        AVG(CASE WHEN bill_amt > 0 THEN bill_amt END),
        2
    ) AS avg_positive_bill,
    ROUND(AVG(pay_amt), 2) AS avg_payment,
    SUM(CASE WHEN bill_amt > 0 THEN 1 ELSE 0 END) AS positive_bill_customer_periods
FROM repayment_monthly
GROUP BY month_index
ORDER BY month_index;

-- =====================================================================
-- BA16 | MONTHLY PAYMENT COVERAGE
-- Definition aligned to positive-bill treatment.
-- =====================================================================
SELECT
    month_index,
    COUNT(*) AS customer_periods,
    ROUND(SUM(pay_amt), 2) AS total_payments,
    ROUND(
        SUM(CASE WHEN bill_amt > 0 THEN bill_amt ELSE 0 END),
        2
    ) AS total_positive_bills,
    ROUND(
        CASE
            WHEN SUM(CASE WHEN bill_amt > 0 THEN bill_amt ELSE 0 END) = 0
            THEN 0
            ELSE
                SUM(pay_amt) /
                SUM(CASE WHEN bill_amt > 0 THEN bill_amt ELSE 0 END)
        END * 100,
        2
    ) AS payment_coverage_pct
FROM repayment_monthly
GROUP BY month_index
ORDER BY month_index;

-- =====================================================================
-- BA17 | MONTHLY BEHAVIOR BY OBSERVED DEFAULT STATUS
-- =====================================================================
SELECT
    r.month_index,
    c.DefaultFlag AS default_flag,
    COUNT(*) AS customer_periods,
    ROUND(AVG(r.pay_status > 0) * 100, 2) AS delay_rate_pct,
    ROUND(
        AVG(CASE WHEN r.bill_amt > 0 THEN r.bill_amt END),
        2
    ) AS avg_positive_bill,
    ROUND(AVG(r.pay_amt), 2) AS avg_payment
FROM repayment_monthly r
INNER JOIN credit_clients_raw c
    ON r.ID = c.ID
GROUP BY r.month_index, c.DefaultFlag
ORDER BY r.month_index, c.DefaultFlag;

-- =====================================================================
-- BA18 | MONTH-OVER-MONTH MOVEMENT USING LAG()
-- =====================================================================
WITH monthly_metrics AS (
    SELECT
        month_index,
        AVG(pay_status > 0) * 100 AS delay_rate_pct,
        AVG(CASE WHEN bill_amt > 0 THEN bill_amt END) AS avg_positive_bill,
        AVG(pay_amt) AS avg_payment
    FROM repayment_monthly
    GROUP BY month_index
)
SELECT
    month_index,
    ROUND(delay_rate_pct, 2) AS delay_rate_pct,
    ROUND(
        delay_rate_pct - LAG(delay_rate_pct) OVER (ORDER BY month_index),
        2
    ) AS delay_rate_change_pct,
    ROUND(avg_positive_bill, 2) AS avg_positive_bill,
    ROUND(
        avg_positive_bill - LAG(avg_positive_bill) OVER (ORDER BY month_index),
        2
    ) AS avg_bill_change,
    ROUND(avg_payment, 2) AS avg_payment,
    ROUND(
        avg_payment - LAG(avg_payment) OVER (ORDER BY month_index),
        2
    ) AS avg_payment_change
FROM monthly_metrics
ORDER BY month_index;

-- =====================================================================
-- END OF BUSINESS ANALYSIS WORKBOOK
-- =====================================================================

-- =====================================================================
-- 06_monthly_behavior.sql
-- =====================================================================

-- =====================================================================
-- RETAIL BANKING CREDIT RISK & CUSTOMER ANALYTICS
-- 06_monthly_behavior.sql
-- =====================================================================

USE banking_credit_risk;

-- =====================================================================
-- MB01 | MONTHLY TABLE GRAIN
-- =====================================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ID) AS customers,
    COUNT(DISTINCT month_index) AS months
FROM repayment_monthly;


-- =====================================================================
-- MB02 | MONTHLY REPAYMENT BEHAVIOR
-- Definition:
--   avg_positive_bill = average bill among periods where bill_amt > 0
--   avg_payment       = average payment across all customer-periods
-- =====================================================================

SELECT
    month_index,
    COUNT(*) AS customer_periods,
    ROUND(AVG(pay_status > 0) * 100, 2) AS delay_rate_pct,
    ROUND(
        AVG(CASE WHEN bill_amt > 0 THEN bill_amt END),
        2
    ) AS avg_positive_bill,
    ROUND(AVG(pay_amt), 2) AS avg_payment,
    SUM(
        CASE WHEN bill_amt > 0 THEN 1 ELSE 0 END
    ) AS positive_bill_customer_periods
FROM repayment_monthly
GROUP BY month_index
ORDER BY month_index;


-- =====================================================================
-- MB03 | MONTHLY PAYMENT COVERAGE
-- Definition:
--   total payments / total positive bills
-- Zero positive-bill denominator is treated as zero.
-- =====================================================================

SELECT
    month_index,
    COUNT(*) AS customer_periods,
    ROUND(SUM(pay_amt), 2) AS total_payments,
    ROUND(
        SUM(CASE WHEN bill_amt > 0 THEN bill_amt ELSE 0 END),
        2
    ) AS total_positive_bills,
    ROUND(
        CASE
            WHEN SUM(
                CASE WHEN bill_amt > 0 THEN bill_amt ELSE 0 END
            ) = 0
            THEN 0
            ELSE
                SUM(pay_amt)
                /
                SUM(
                    CASE WHEN bill_amt > 0 THEN bill_amt ELSE 0 END
                )
        END * 100,
        2
    ) AS payment_coverage_pct
FROM repayment_monthly
GROUP BY month_index
ORDER BY month_index;


-- =====================================================================
-- MB04 | MONTHLY BEHAVIOR BY OBSERVED DEFAULT STATUS
-- =====================================================================

SELECT
    r.month_index,
    c.DefaultFlag AS default_flag,
    COUNT(*) AS customer_periods,
    ROUND(AVG(r.pay_status > 0) * 100, 2) AS delay_rate_pct,
    ROUND(
        AVG(CASE WHEN r.bill_amt > 0 THEN r.bill_amt END),
        2
    ) AS avg_positive_bill,
    ROUND(AVG(r.pay_amt), 2) AS avg_payment,
    SUM(
        CASE WHEN r.bill_amt > 0 THEN 1 ELSE 0 END
    ) AS positive_bill_customer_periods
FROM repayment_monthly r
INNER JOIN credit_clients_raw c
    ON r.ID = c.ID
GROUP BY
    r.month_index,
    c.DefaultFlag
ORDER BY
    r.month_index,
    c.DefaultFlag;


-- =====================================================================
-- MB05 | MONTH-OVER-MONTH MOVEMENT USING LAG()
-- =====================================================================

WITH monthly_metrics AS (
    SELECT
        month_index,
        AVG(pay_status > 0) * 100 AS delay_rate_pct,
        AVG(
            CASE WHEN bill_amt > 0 THEN bill_amt END
        ) AS avg_positive_bill,
        AVG(pay_amt) AS avg_payment
    FROM repayment_monthly
    GROUP BY month_index
)

SELECT
    month_index,

    ROUND(delay_rate_pct, 2) AS delay_rate_pct,

    ROUND(
        delay_rate_pct
        - LAG(delay_rate_pct) OVER (
            ORDER BY month_index
        ),
        2
    ) AS delay_rate_change_pct,

    ROUND(avg_positive_bill, 2) AS avg_positive_bill,

    ROUND(
        avg_positive_bill
        - LAG(avg_positive_bill) OVER (
            ORDER BY month_index
        ),
        2
    ) AS avg_bill_change,

    ROUND(avg_payment, 2) AS avg_payment,

    ROUND(
        avg_payment
        - LAG(avg_payment) OVER (
            ORDER BY month_index
        ),
        2
    ) AS avg_payment_change

FROM monthly_metrics
ORDER BY month_index;
-- =====================================================================
-- 07_customer_review.sql
-- =====================================================================

-- =====================================================================
-- RETAIL BANKING CREDIT RISK & CUSTOMER ANALYTICS
-- 07_customer_review.sql
-- =====================================================================
-- Purpose:
--   Customer-level analytical review and advanced SQL examples.
--
-- Query labels:
--   CR01 | Analytical customer review list
--   CR02 | Rank customers by six-month bill exposure
--   CR03 | Rank exposure within delinquency group
--   CR04 | Repeated-delay population by default status
--
-- Notes:
--   CR01-CR04 are analytical portfolio queries, not live lending/
--   collections policy rules.
-- =====================================================================

USE banking_credit_risk;

-- =====================================================================
-- CR01 | ANALYTICAL CUSTOMER REVIEW LIST
-- =====================================================================
-- Analytical rule:
--   delinquency_count >= 2
--   AND LIMIT_BAL >= 100000
--
-- Purpose:
--   Produce a customer-level review population containing delinquency,
--   exposure and payment-behavior context.
--
-- Payment coverage definition:
--   Total Payments / Total Positive Bills
--   where only bill amounts > 0 contribute to the denominator.
-- =====================================================================

WITH customer_features AS (
    SELECT
        ID,
        LIMIT_BAL,
        DefaultFlag,

        -- Maximum observed repayment-status code
        GREATEST(
            PAY_0,
            PAY_2,
            PAY_3,
            PAY_4,
            PAY_5,
            PAY_6
        ) AS max_delinquency,

        -- Number of periods with a positive repayment-status code
        (
            (PAY_0 > 0)
            + (PAY_2 > 0)
            + (PAY_3 > 0)
            + (PAY_4 > 0)
            + (PAY_5 > 0)
            + (PAY_6 > 0)
        ) AS delinquency_count,

        -- Six-month total of positive bill amounts only
        (
            CASE WHEN BILL_AMT1 > 0 THEN BILL_AMT1 ELSE 0 END +
            CASE WHEN BILL_AMT2 > 0 THEN BILL_AMT2 ELSE 0 END +
            CASE WHEN BILL_AMT3 > 0 THEN BILL_AMT3 ELSE 0 END +
            CASE WHEN BILL_AMT4 > 0 THEN BILL_AMT4 ELSE 0 END +
            CASE WHEN BILL_AMT5 > 0 THEN BILL_AMT5 ELSE 0 END +
            CASE WHEN BILL_AMT6 > 0 THEN BILL_AMT6 ELSE 0 END
        ) AS total_positive_bills,

        -- Six-month total payments
        (
            PAY_AMT1 +
            PAY_AMT2 +
            PAY_AMT3 +
            PAY_AMT4 +
            PAY_AMT5 +
            PAY_AMT6
        ) AS total_payments

    FROM credit_clients_raw
)

SELECT
    ID,
    LIMIT_BAL,
    max_delinquency,
    delinquency_count,
    total_positive_bills,
    total_payments,

    -- Payment Coverage = Total Payments / Total Positive Bills
    ROUND(
        CASE
            WHEN total_positive_bills = 0 THEN 0
            ELSE total_payments / total_positive_bills
        END,
        4
    ) AS payment_coverage,

    DefaultFlag

FROM customer_features

WHERE delinquency_count >= 2
  AND LIMIT_BAL >= 100000

ORDER BY
    delinquency_count DESC,
    LIMIT_BAL DESC;
-- =====================================================================
-- CR02 | RANK CUSTOMERS BY SIX-MONTH BILL EXPOSURE
-- =====================================================================
-- Purpose:
--   Identify customers with the largest six-month positive-bill totals.
--
-- Definition:
--   Total Bill Exposure = sum of positive BILL_AMT1 ... BILL_AMT6.
--   Negative or zero bill amounts are treated as 0.
-- =====================================================================

WITH customer_bills AS (
    SELECT
        ID,
        LIMIT_BAL,
        DefaultFlag,

        (
            CASE WHEN BILL_AMT1 > 0 THEN BILL_AMT1 ELSE 0 END
            + CASE WHEN BILL_AMT2 > 0 THEN BILL_AMT2 ELSE 0 END
            + CASE WHEN BILL_AMT3 > 0 THEN BILL_AMT3 ELSE 0 END
            + CASE WHEN BILL_AMT4 > 0 THEN BILL_AMT4 ELSE 0 END
            + CASE WHEN BILL_AMT5 > 0 THEN BILL_AMT5 ELSE 0 END
            + CASE WHEN BILL_AMT6 > 0 THEN BILL_AMT6 ELSE 0 END
        ) AS total_bills

    FROM credit_clients_raw
)

SELECT
    ID,
    LIMIT_BAL,
    total_bills,
    DefaultFlag,

    RANK() OVER (
        ORDER BY total_bills DESC
    ) AS total_bill_rank

FROM customer_bills

ORDER BY total_bill_rank, ID

LIMIT 100;


-- =====================================================================
-- CR03 | RANK EXPOSURE WITHIN DELINQUENCY GROUP
-- =====================================================================
-- Purpose:
--   Compare customer credit-limit exposure among customers with the
--   same delinquency count.
-- =====================================================================

WITH customer_features AS (
    SELECT
        ID,
        LIMIT_BAL,
        DefaultFlag,

        (
            (PAY_0 > 0)
            + (PAY_2 > 0)
            + (PAY_3 > 0)
            + (PAY_4 > 0)
            + (PAY_5 > 0)
            + (PAY_6 > 0)
        ) AS delinquency_count

    FROM credit_clients_raw
)

SELECT
    ID,
    LIMIT_BAL,
    delinquency_count,
    DefaultFlag,

    RANK() OVER (
        PARTITION BY delinquency_count
        ORDER BY LIMIT_BAL DESC
    ) AS exposure_rank_within_delinquency

FROM customer_features

ORDER BY
    delinquency_count DESC,
    exposure_rank_within_delinquency

LIMIT 200;


-- =====================================================================
-- CR04 | REPEATED-DELAY POPULATION BY DEFAULT STATUS
-- =====================================================================
-- Purpose:
--   Count customers with two or more periods containing a positive
--   repayment-status code, split by observed default outcome.
-- =====================================================================

WITH customer_features AS (
    SELECT
        ID,
        DefaultFlag,

        (
            (PAY_0 > 0)
            + (PAY_2 > 0)
            + (PAY_3 > 0)
            + (PAY_4 > 0)
            + (PAY_5 > 0)
            + (PAY_6 > 0)
        ) AS delinquency_count

    FROM credit_clients_raw
)

SELECT
    DefaultFlag AS default_flag,
    COUNT(*) AS customers

FROM customer_features

WHERE delinquency_count >= 2

GROUP BY DefaultFlag

ORDER BY DefaultFlag;


-- =====================================================================
-- END OF 07_customer_review.sql
-- =====================================================================

-- =====================================================================
-- 08_validation.sql
-- =====================================================================

-- =====================================================================
-- RETAIL BANKING CREDIT RISK & CUSTOMER ANALYTICS
-- 08_validation.sql
-- =====================================================================

USE banking_credit_risk;


-- =====================================================================
-- VAL01 | CORE PORTFOLIO RECONCILIATION
-- =====================================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT ID) AS unique_customers,
    SUM(DefaultFlag) AS defaulted_customers,
    ROUND(AVG(DefaultFlag) * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 2) AS avg_credit_limit,
    SUM(LIMIT_BAL) AS total_credit_limit
FROM credit_clients_raw;


-- =====================================================================
-- VAL02 | DELINQUENCY RECONCILIATION
-- =====================================================================

SELECT
    COUNT(*) AS customers,
    SUM(delinquency_count > 0) AS customers_with_delinquency,
    ROUND(
        100 * SUM(delinquency_count > 0) / COUNT(*),
        2
    ) AS delinquency_rate_pct
FROM customer_risk_analysis;


-- =====================================================================
-- VAL03 | POSITIVE-BILL / NO-PAYMENT RECONCILIATION
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
-- VAL04 | MONTHLY GRAIN RECONCILIATION
-- =====================================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ID) AS customers,
    COUNT(DISTINCT month_index) AS months
FROM repayment_monthly;


-- =====================================================================
-- VAL05 | MONTHLY METRIC RECONCILIATION
-- Definition:
--   Payment Coverage = Total Payment / Total Positive Bill
-- =====================================================================

SELECT
    month_index,

    COUNT(*) AS customer_periods,

    ROUND(
        AVG(pay_status > 0) * 100,
        2
    ) AS delay_rate_pct,

    ROUND(
        AVG(
            CASE
                WHEN bill_amt > 0 THEN bill_amt
            END
        ),
        2
    ) AS avg_positive_bill,

    ROUND(
        AVG(pay_amt),
        2
    ) AS avg_payment,

    ROUND(
        SUM(
            CASE
                WHEN bill_amt > 0 THEN bill_amt
                ELSE 0
            END
        ),
        2
    ) AS total_positive_bills,

    ROUND(
        SUM(pay_amt),
        2
    ) AS total_payments,

    ROUND(
        CASE
            WHEN SUM(
                CASE
                    WHEN bill_amt > 0 THEN bill_amt
                    ELSE 0
                END
            ) = 0
            THEN 0
            ELSE
                SUM(pay_amt)
                /
                SUM(
                    CASE
                        WHEN bill_amt > 0 THEN bill_amt
                        ELSE 0
                    END
                )
        END * 100,
        2
    ) AS payment_coverage_pct

FROM repayment_monthly
GROUP BY month_index
ORDER BY month_index;


-- =====================================================================
-- VAL06 | FINAL PASS/FAIL CONTROL SUMMARY
-- =====================================================================
-- Purpose:
--   Final validation gate for customer-level and monthly analytical data.
--
-- Checks:
--   1. Customer row count
--   2. Unique customer IDs
--   3. Default count
--   4. Default rate
--   5. Null customer IDs
--   6. Null default flags
--   7. Monthly repayment row count
--   8. Monthly customer-period uniqueness
--   9. Monthly Payment Coverage calculation integrity
-- =====================================================================

WITH customer_validation AS (
    SELECT
        COUNT(*) AS total_customers,
        COUNT(DISTINCT ID) AS unique_customers,
        SUM(DefaultFlag) AS defaulted_customers,

        ROUND(
            AVG(DefaultFlag) * 100,
            2
        ) AS default_rate_pct,

        SUM(ID IS NULL) AS null_ids,
        SUM(DefaultFlag IS NULL) AS null_default_flags

    FROM credit_clients_raw
),

monthly_validation AS (
    SELECT
        COUNT(*) AS monthly_rows,

        COUNT(DISTINCT CONCAT(ID, '-', month_index))
            AS unique_customer_periods,

        CASE
            WHEN SUM(
                CASE
                    WHEN bill_amt > 0 THEN bill_amt
                    ELSE 0
                END
            ) = 0
            THEN 0
            ELSE
                SUM(pay_amt)
                /
                SUM(
                    CASE
                        WHEN bill_amt > 0 THEN bill_amt
                        ELSE 0
                    END
                )
        END * 100 AS overall_payment_coverage_pct

    FROM repayment_monthly
)

SELECT
    c.total_customers,
    c.unique_customers,
    c.defaulted_customers,
    c.default_rate_pct,
    c.null_ids,
    c.null_default_flags,

    m.monthly_rows,
    m.unique_customer_periods,
    m.overall_payment_coverage_pct,

    CASE
        WHEN c.total_customers = 30000
         AND c.unique_customers = 30000
         AND c.defaulted_customers = 6636
         AND c.default_rate_pct = 22.12
         AND c.null_ids = 0
         AND c.null_default_flags = 0

         AND m.monthly_rows = 180000
         AND m.unique_customer_periods = 180000

         -- Release control: 11.71897309% portfolio Payment Coverage
         -- Allow tiny rounding/engine variation while catching logic drift.
         AND ABS(m.overall_payment_coverage_pct - 11.71897309) <= 0.0001

        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM customer_validation c
CROSS JOIN monthly_validation m;