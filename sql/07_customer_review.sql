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
