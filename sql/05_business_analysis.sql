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
