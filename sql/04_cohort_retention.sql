USE growth_intelligence;

-- =========================================================
-- COHORT RETENTION ANALYSIS
-- Step 1: Assign each customer to their acquisition cohort
-- =========================================================

SELECT
    customer_id,
    DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
FROM orders
GROUP BY customer_id
ORDER BY cohort_month, customer_id;
-- =============================================
-- STEP 2: Customer activity by purchase month
-- =============================================

SELECT
    customer_id,
    DATE_FORMAT(order_date, '%Y-%m') AS purchase_month
FROM orders
GROUP BY
    customer_id,
    DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
    customer_id,
    purchase_month;
-- =============================================
-- STEP 3: Months since customer acquisition
-- =============================================

SELECT
    customer_id,

    DATE_FORMAT(
        MIN(order_date) OVER (
            PARTITION BY customer_id
        ),
        '%Y-%m'
    ) AS cohort_month,

    DATE_FORMAT(
        order_date,
        '%Y-%m'
    ) AS purchase_month,

    TIMESTAMPDIFF(
        MONTH,
        MIN(order_date) OVER (
            PARTITION BY customer_id
        ),
        order_date
    ) AS months_since_cohort

FROM orders

ORDER BY
    customer_id,
    order_date;