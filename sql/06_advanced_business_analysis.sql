-- =============================================
-- 06 ADVANCED BUSINESS ANALYSIS
-- STEP 1: Customer Revenue & Profit Concentration
-- =============================================

USE growth_intelligence;

WITH customer_value AS (

    SELECT
        customer_id,

        SUM(revenue) AS revenue,

        SUM(revenue - cost) AS profit

    FROM orders

    GROUP BY customer_id
),

customer_contribution AS (

    SELECT
        customer_id,
        revenue,
        profit,

        RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,

        SUM(revenue) OVER () AS total_revenue,

        SUM(profit) OVER () AS total_profit

    FROM customer_value
)

SELECT
    customer_id,

    revenue_rank,

    ROUND(revenue, 2) AS revenue,

    ROUND(profit, 2) AS profit,

    ROUND(
        revenue / total_revenue * 100,
        2
    ) AS revenue_contribution_pct,

    ROUND(
        profit / total_profit * 100,
        2
    ) AS profit_contribution_pct

FROM customer_contribution

ORDER BY revenue DESC;

-- =============================================
-- STEP 2: Customer Revenue Concentration
-- =============================================

WITH customer_revenue AS (

    SELECT
        customer_id,
        SUM(revenue) AS revenue

    FROM orders

    GROUP BY customer_id
),

customer_running_total AS (

    SELECT
        customer_id,
        revenue,

        RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,

        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(revenue) OVER () AS total_revenue

    FROM customer_revenue
)

SELECT
    customer_id,

    revenue_rank,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        cumulative_revenue,
        2
    ) AS cumulative_revenue,

    ROUND(
        cumulative_revenue / total_revenue * 100,
        2
    ) AS cumulative_revenue_pct

FROM customer_running_total

ORDER BY revenue_rank;

-- =============================================
-- STEP 3: Top 10% Customer Contribution
-- =============================================

WITH customer_value AS (

    SELECT
        customer_id,
        SUM(revenue) AS revenue,
        SUM(revenue - cost) AS profit

    FROM orders

    GROUP BY customer_id
),

ranked_customers AS (

    SELECT
        customer_id,
        revenue,
        profit,

        RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(revenue) OVER () AS total_revenue,

        SUM(profit) OVER () AS total_profit

    FROM customer_value
)

SELECT
    COUNT(*) AS top_10pct_customers,

    ROUND(
        SUM(revenue),
        2
    ) AS top_10pct_revenue,

    ROUND(
        SUM(profit),
        2
    ) AS top_10pct_profit,

    ROUND(
        SUM(revenue) /
        MAX(total_revenue) * 100,
        2
    ) AS revenue_contribution_pct,

    ROUND(
        SUM(profit) /
        MAX(total_profit) * 100,
        2
    ) AS profit_contribution_pct

FROM ranked_customers

WHERE revenue_rank <= CEIL(total_customers * 0.10);

-- =============================================
-- STEP 4: Discount & Profitability Analysis
-- =============================================

SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount < 0.10 THEN 'Low Discount'
        WHEN discount < 0.20 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_band,

    COUNT(DISTINCT order_id) AS orders,

    SUM(quantity) AS units_sold,

    ROUND(SUM(revenue), 2) AS revenue,

    ROUND(SUM(cost), 2) AS cost,

    ROUND(
        SUM(revenue - cost),
        2
    ) AS profit,

    ROUND(
        SUM(revenue - cost)
        / SUM(revenue) * 100,
        2
    ) AS profit_margin,

    ROUND(
        SUM(revenue)
        / COUNT(DISTINCT order_id),
        2
    ) AS aov

FROM orders

GROUP BY
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount < 0.10 THEN 'Low Discount'
        WHEN discount < 0.20 THEN 'Medium Discount'
        ELSE 'High Discount'
    END

ORDER BY
    MIN(discount);
    
-- =============================================
-- STEP 5: Channel × Category Performance
-- =============================================

SELECT
    channel,
    category,

    COUNT(DISTINCT order_id) AS orders,

    SUM(quantity) AS units_sold,

    ROUND(SUM(revenue), 2) AS revenue,

    ROUND(SUM(revenue - cost), 2) AS profit,

    ROUND(
        SUM(revenue - cost)
        / SUM(revenue) * 100,
        2
    ) AS profit_margin,

    ROUND(
        SUM(revenue)
        / COUNT(DISTINCT order_id),
        2
    ) AS aov

FROM orders

GROUP BY
    channel,
    category

ORDER BY
    revenue DESC;