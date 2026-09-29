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