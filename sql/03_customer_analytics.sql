USE growth_intelligence;


-- =========================================================
-- 1. REPEAT VS ONE-TIME CUSTOMERS
-- =========================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(revenue) AS revenue
    FROM orders
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,

    COUNT(*) AS customers,

    ROUND(
        SUM(revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(revenue) / COUNT(*),
        2
    ) AS revenue_per_customer

FROM customer_orders

GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END

ORDER BY customers DESC;


-- =========================================================
-- 2. CUSTOMER-LEVEL METRICS
-- =========================================================

WITH customer_metrics AS (
    SELECT
        customer_id,

        MIN(order_date) AS first_purchase_date,

        MAX(order_date) AS last_purchase_date,

        COUNT(DISTINCT order_id) AS total_orders,

        SUM(revenue) AS total_revenue,

        SUM(revenue - cost) AS total_profit

    FROM orders

    GROUP BY customer_id
)

SELECT
    customer_id,

    first_purchase_date,

    last_purchase_date,

    total_orders,

    ROUND(
        total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        total_profit,
        2
    ) AS total_profit,

    ROUND(
        total_revenue / total_orders,
        2
    ) AS customer_aov

FROM customer_metrics

ORDER BY total_revenue DESC;


-- =========================================================
-- 3. RAW RFM METRICS
-- =========================================================

SELECT
    customer_id,

    DATEDIFF(
        (SELECT MAX(order_date) FROM orders),
        MAX(order_date)
    ) AS recency,

    COUNT(DISTINCT order_id) AS frequency,

    ROUND(
        SUM(revenue),
        2
    ) AS monetary

FROM orders

GROUP BY customer_id

ORDER BY monetary DESC;


-- =========================================================
-- 4. RFM SCORING
-- =========================================================

WITH rfm AS (

    SELECT
        customer_id,

        DATEDIFF(
            (SELECT MAX(order_date) FROM orders),
            MAX(order_date)
        ) AS recency,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(revenue) AS monetary

    FROM orders

    GROUP BY customer_id
),

rfm_scores AS (

    SELECT
        customer_id,

        recency,

        frequency,

        monetary,

        6 - NTILE(5) OVER (
            ORDER BY recency
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm
)

SELECT
    customer_id,

    recency,

    frequency,

    ROUND(
        monetary,
        2
    ) AS monetary,

    r_score,

    f_score,

    m_score,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_score

FROM rfm_scores

ORDER BY monetary DESC;


-- =========================================================
-- 5. RFM CUSTOMER SEGMENTS
-- =========================================================

WITH rfm AS (

    SELECT
        customer_id,

        DATEDIFF(
            (SELECT MAX(order_date) FROM orders),
            MAX(order_date)
        ) AS recency,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(revenue) AS monetary

    FROM orders

    GROUP BY customer_id
),

rfm_scores AS (

    SELECT
        customer_id,

        recency,

        frequency,

        monetary,

        6 - NTILE(5) OVER (
            ORDER BY recency
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm
)

SELECT
    customer_id,

    recency,

    frequency,

    ROUND(
        monetary,
        2
    ) AS monetary,

    r_score,

    f_score,

    m_score,

    CASE

        WHEN r_score >= 4
         AND f_score >= 4
         AND m_score >= 4
        THEN 'Champions'

        WHEN r_score >= 3
         AND f_score >= 4
        THEN 'Loyal Customers'

        WHEN r_score >= 4
         AND f_score <= 2
        THEN 'New Customers'

        WHEN r_score <= 2
         AND m_score >= 4
        THEN 'At Risk'

        WHEN r_score <= 2
         AND f_score <= 2
         AND m_score <= 2
        THEN 'Lost Customers'

        ELSE 'Potential Customers'

    END AS customer_segment

FROM rfm_scores

ORDER BY monetary DESC;


-- =========================================================
-- 6. RFM SEGMENT SUMMARY
-- =========================================================

WITH rfm AS (

    SELECT
        customer_id,

        DATEDIFF(
            (SELECT MAX(order_date) FROM orders),
            MAX(order_date)
        ) AS recency,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(revenue) AS monetary

    FROM orders

    GROUP BY customer_id
),

rfm_scores AS (

    SELECT
        customer_id,

        recency,

        frequency,

        monetary,

        6 - NTILE(5) OVER (
            ORDER BY recency
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm
),

segments AS (

    SELECT
        *,

        CASE

            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
            THEN 'Champions'

            WHEN r_score >= 3
             AND f_score >= 4
            THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score <= 2
            THEN 'New Customers'

            WHEN r_score <= 2
             AND m_score >= 4
            THEN 'At Risk'

            WHEN r_score <= 2
             AND f_score <= 2
             AND m_score <= 2
            THEN 'Lost Customers'

            ELSE 'Potential Customers'

        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary),
        2
    ) AS revenue,

    ROUND(
        SUM(monetary)
        /
        (SELECT SUM(monetary) FROM segments)
        * 100,
        2
    ) AS revenue_percentage,

    ROUND(
        AVG(monetary),
        2
    ) AS avg_revenue_per_customer

FROM segments

GROUP BY customer_segment

ORDER BY revenue DESC;