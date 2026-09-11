-- =============================================
-- 05 PRODUCT ANALYSIS
-- STEP 1: Product Performance
-- =============================================

SELECT
    product_id,
    category,
    subcategory,

    ROUND(SUM(revenue), 2) AS revenue,

    ROUND(SUM(cost), 2) AS cost,

    ROUND(SUM(revenue - cost), 2) AS profit,

    ROUND(
        SUM(revenue - cost) / SUM(revenue) * 100,
        2
    ) AS profit_margin,

    SUM(quantity) AS units_sold,

    COUNT(DISTINCT order_id) AS orders,

    ROUND(
        SUM(revenue) / COUNT(DISTINCT order_id),
        2
    ) AS aov

FROM orders

GROUP BY
    product_id,
    category,
    subcategory

ORDER BY
    revenue DESC;
    
    -- =============================================
-- STEP 2: Product Ranking Within Category
-- =============================================

WITH product_metrics AS (

    SELECT
        product_id,
        category,
        subcategory,

        SUM(revenue) AS revenue,

        SUM(cost) AS cost,

        SUM(revenue - cost) AS profit,

        SUM(quantity) AS units_sold

    FROM orders

    GROUP BY
        product_id,
        category,
        subcategory
)

SELECT
    product_id,
    category,
    subcategory,

    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,

    ROUND(
        profit / revenue * 100,
        2
    ) AS profit_margin,

    units_sold,

    RANK() OVER (
        PARTITION BY category
        ORDER BY revenue DESC
    ) AS revenue_rank,

    RANK() OVER (
        PARTITION BY category
        ORDER BY profit DESC
    ) AS profit_rank,

    RANK() OVER (
        PARTITION BY category
        ORDER BY units_sold DESC
    ) AS units_rank

FROM product_metrics

ORDER BY
    category,
    revenue_rank;
    
-- =============================================
-- STEP 3: Top 10 Products by Revenue
-- =============================================

WITH product_metrics AS (

    SELECT
        product_id,
        category,
        subcategory,

        SUM(revenue) AS revenue,
        SUM(cost) AS cost,
        SUM(revenue - cost) AS profit,
        SUM(quantity) AS units_sold

    FROM orders

    GROUP BY
        product_id,
        category,
        subcategory
),

ranked_products AS (

    SELECT
        product_id,
        category,
        subcategory,
        revenue,
        profit,
        units_sold,

        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS revenue_rank

    FROM product_metrics
)

SELECT
    product_id,
    category,
    subcategory,

    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,

    ROUND(
        profit / revenue * 100,
        2
    ) AS profit_margin,

    units_sold,
    revenue_rank

FROM ranked_products

WHERE revenue_rank <= 10

ORDER BY
    category,
    revenue_rank;
    
-- =============================================
-- STEP 4: Revenue vs Category Margin Benchmark
-- =============================================

WITH product_metrics AS (

    SELECT
        product_id,
        category,
        subcategory,

        SUM(revenue) AS revenue,
        SUM(cost) AS cost,
        SUM(revenue - cost) AS profit

    FROM orders

    GROUP BY
        product_id,
        category,
        subcategory
),

product_margin AS (

    SELECT
        product_id,
        category,
        subcategory,
        revenue,
        profit,

        profit / revenue * 100 AS profit_margin

    FROM product_metrics
),

category_benchmark AS (

    SELECT
        category,
        AVG(profit_margin) AS avg_category_margin

    FROM product_margin

    GROUP BY category
)

SELECT
    p.product_id,
    p.category,
    p.subcategory,

    ROUND(p.revenue, 2) AS revenue,
    ROUND(p.profit, 2) AS profit,
    ROUND(p.profit_margin, 2) AS profit_margin,

    ROUND(b.avg_category_margin, 2) AS avg_category_margin,

    ROUND(
        p.profit_margin - b.avg_category_margin,
        2
    ) AS margin_vs_category

FROM product_margin p

JOIN category_benchmark b
    ON p.category = b.category

ORDER BY
    p.revenue DESC;
    
-- =============================================
-- STEP 5: Product Opportunity / Risk Matrix
-- =============================================

WITH product_metrics AS (

    SELECT
        product_id,
        category,
        subcategory,

        SUM(revenue) AS revenue,
        SUM(revenue - cost) AS profit

    FROM orders

    GROUP BY
        product_id,
        category,
        subcategory
),

product_margin AS (

    SELECT
        product_id,
        category,
        subcategory,
        revenue,
        profit,

        profit / revenue * 100 AS profit_margin

    FROM product_metrics
),

category_benchmark AS (

    SELECT
        category,
        AVG(profit_margin) AS avg_category_margin

    FROM product_margin

    GROUP BY category
),

overall_benchmark AS (

    SELECT
        AVG(revenue) AS avg_product_revenue

    FROM product_margin
)

SELECT
    p.product_id,
    p.category,
    p.subcategory,

    ROUND(p.revenue, 2) AS revenue,

    ROUND(p.profit, 2) AS profit,

    ROUND(p.profit_margin, 2) AS profit_margin,

    ROUND(b.avg_category_margin, 2) AS category_avg_margin,

    CASE

        WHEN p.revenue >= o.avg_product_revenue
             AND p.profit_margin >= b.avg_category_margin
            THEN 'High Revenue - High Margin'

        WHEN p.revenue >= o.avg_product_revenue
             AND p.profit_margin < b.avg_category_margin
            THEN 'High Revenue - Low Margin'

        WHEN p.revenue < o.avg_product_revenue
             AND p.profit_margin >= b.avg_category_margin
            THEN 'Low Revenue - High Margin'

        ELSE
            'Low Revenue - Low Margin'

    END AS product_segment

FROM product_margin p

JOIN category_benchmark b
    ON p.category = b.category

CROSS JOIN overall_benchmark o

ORDER BY
    p.revenue DESC;

-- =============================================
-- STEP 6: Product Revenue & Profit Contribution
-- =============================================

WITH product_metrics AS (

    SELECT
        product_id,
        category,
        subcategory,

        SUM(revenue) AS revenue,
        SUM(revenue - cost) AS profit

    FROM orders

    GROUP BY
        product_id,
        category,
        subcategory
),

product_contribution AS (

    SELECT
        product_id,
        category,
        subcategory,
        revenue,
        profit,

        SUM(revenue) OVER () AS total_revenue,
        SUM(profit) OVER () AS total_profit

    FROM product_metrics
)

SELECT
    product_id,
    category,
    subcategory,

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

FROM product_contribution

ORDER BY revenue DESC;