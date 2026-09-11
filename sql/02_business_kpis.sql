USE growth_intelligence;


-- =========================================================
-- 1. OVERALL BUSINESS KPIs
-- =========================================================

SELECT
    SUM(revenue) AS total_revenue,
    SUM(cost) AS total_cost,
    SUM(revenue - cost) AS total_profit,
    ROUND(
        SUM(revenue - cost) / SUM(revenue) * 100,
        2
    ) AS profit_margin,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(
        SUM(revenue) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM orders;


-- =========================================================
-- 2. MONTHLY REVENUE, PROFIT & MoM GROWTH
-- =========================================================

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(revenue) AS revenue,
        SUM(cost) AS cost,
        SUM(revenue - cost) AS profit
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(cost, 2) AS cost,
    ROUND(profit, 2) AS profit,

    ROUND(
        LAG(revenue) OVER (ORDER BY month),
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            revenue
            - LAG(revenue) OVER (ORDER BY month)
        )
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS mom_growth_pct

FROM monthly_sales
ORDER BY month;


-- =========================================================
-- 3. MONTHLY ORDERS, CUSTOMERS & AOV
-- =========================================================

WITH monthly_metrics AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        COUNT(DISTINCT order_id) AS orders,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(revenue) AS revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)

SELECT
    month,
    orders,
    customers,
    ROUND(revenue, 2) AS revenue,

    ROUND(
        revenue / orders,
        2
    ) AS aov,

    ROUND(
        (
            revenue
            - LAG(revenue) OVER (ORDER BY month)
        )
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS revenue_growth_pct

FROM monthly_metrics
ORDER BY month;


-- =========================================================
-- 4. CATEGORY PERFORMANCE
-- =========================================================

SELECT
    category,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(cost), 2) AS cost,
    ROUND(SUM(revenue - cost), 2) AS profit,

    ROUND(
        SUM(revenue - cost)
        / SUM(revenue) * 100,
        2
    ) AS profit_margin,

    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units_sold

FROM orders

GROUP BY category

ORDER BY revenue DESC;


-- =========================================================
-- 5. MONTHLY CATEGORY PERFORMANCE
-- =========================================================

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    category,

    ROUND(SUM(revenue), 2) AS revenue,

    ROUND(
        SUM(revenue - cost),
        2
    ) AS profit,

    ROUND(
        SUM(revenue - cost)
        / SUM(revenue) * 100,
        2
    ) AS profit_margin

FROM orders

GROUP BY
    DATE_FORMAT(order_date, '%Y-%m'),
    category

ORDER BY
    month,
    revenue DESC;


-- =========================================================
-- 6. CHANNEL PERFORMANCE
-- =========================================================

SELECT
    channel,

    COUNT(DISTINCT order_id) AS orders,

    COUNT(DISTINCT customer_id) AS customers,

    ROUND(SUM(revenue), 2) AS revenue,

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

GROUP BY channel

ORDER BY revenue DESC;


-- =========================================================
-- 7. MONTHLY CHANNEL PERFORMANCE
-- =========================================================

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    channel,

    ROUND(SUM(revenue), 2) AS revenue,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(revenue)
        / COUNT(DISTINCT order_id),
        2
    ) AS aov

FROM orders

GROUP BY
    DATE_FORMAT(order_date, '%Y-%m'),
    channel

ORDER BY
    month,
    revenue DESC;