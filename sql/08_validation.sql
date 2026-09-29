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