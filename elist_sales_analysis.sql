-- Elist Sales Performance


-- Sales, revenue, AOV, and refund rates by region
SELECT
    geo_lookup.region,
    COUNT(DISTINCT orders.id) AS sales,
    ROUND(SUM(orders.usd_price), 2) AS revenue,
    ROUND(AVG(orders.usd_price), 2) AS aov,
    ROUND(
        (COUNT(order_status.refund_ts) / COUNT(order_status.order_id)) * 100, 2) AS refund_rt,
    ROUND(AVG(DATE_DIFF(order_status.ship_ts, order_status.purchase_ts, day)), 2) AS avg_tts_days,
    ROUND(AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)), 2) AS avg_ttd_days
FROM core.orders
     JOIN core.order_status 
       ON orders.id = order_status.order_id
     LEFT JOIN core.customers 
       ON orders.customer_id = customers.id
     LEFT JOIN core.geo_lookup 
       ON customers.country_code = geo_lookup.country
GROUP BY 1
ORDER BY 2 DESC
;


-- Sales, revenue, AOV, and refund rates by supplier
SELECT
    suppliers.supplier,
    COUNT(DISTINCT orders.id) AS sales,
    ROUND(SUM(orders.usd_price), 2) AS revenue,
    ROUND(AVG(orders.usd_price), 2) AS aov,
    ROUND(
        (COUNT(order_status.refund_ts) / COUNT(order_status.order_id)) * 100, 2) AS refund_rt,
    ROUND(AVG(DATE_DIFF(order_status.ship_ts, order_status.purchase_ts, day)), 2) AS avg_tts_days,
    ROUND(AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)), 2) AS avg_ttd_days
FROM core.orders
     JOIN core.order_status 
       ON orders.id = order_status.order_id
     LEFT JOIN core.suppliers
       ON orders.product_id = suppliers.product_id
GROUP BY 1
ORDER BY 2 DESC
;


-- Macbook sales, revenue, and AOV per region
SELECT
    geo_lookup.region,
    COUNT(DISTINCT orders.id) AS sales,
    ROUND(SUM(orders.usd_price), 2) AS revenue,
    ROUND(AVG(orders.usd_price), 2) AS aov
FROM core.orders
     LEFT JOIN core.customers 
       ON orders.customer_id = customers.id
     LEFT JOIN core.geo_lookup 
       ON customers.country_code = geo_lookup.country
WHERE LOWER(orders.product_name) LIKE '%macbook%'
GROUP BY 1
ORDER BY 2 DESC
;


-- Quarterly sales, revenue, and AOV for Macbooks sold in North America
WITH
na_macbook_sales AS (
    SELECT 
        DATE_TRUNC(orders.purchase_ts, quarter) AS qt,
        COUNT(DISTINCT orders.id) AS sales,
        ROUND(SUM(orders.usd_price), 2) AS revenue,
        ROUND(AVG(orders.usd_price), 2) AS aov
    FROM core.orders
         LEFT JOIN core.customers 
           ON orders.customer_id = customers.id
         LEFT JOIN core.geo_lookup 
           ON customers.country_code = geo_lookup.country
    WHERE LOWER(orders.product_name) LIKE '%macbook%'
      AND region = 'NA'
    GROUP BY 1
)

SELECT
    qt,
    sales,
    ROUND(
        ((sales - LAG(sales) OVER (ORDER BY qt)) / NULLIF(LAG(sales) OVER (ORDER BY qt), 0)) * 100, 2
    ) AS QoQ_sales_growth,
    revenue,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY qt)) / NULLIF(LAG(revenue) OVER (ORDER BY qt), 0)) * 100, 2
    ) AS QoQ_revenue_growth,
    aov,
    ROUND(
        ((aov - LAG(aov) OVER (ORDER BY qt)) / NULLIF(LAG(aov) OVER (ORDER BY qt), 0)) * 100, 2
    ) AS QoQ_aov_growth
FROM na_macbook_sales
ORDER BY qt DESC
;


-- Quarterly Macbook sales & refund rates
SELECT 
    DATE_TRUNC(orders.purchase_ts, quarter) AS qt,
    COUNT(DISTINCT orders.id) AS sales,
    COUNT(order_status.refund_ts) AS refunds,
    ROUND(
        (COUNT(order_status.refund_ts) / COUNT(order_status.order_id)) * 100, 2) AS refund_rt
FROM core.orders
     JOIN core.order_status
       ON orders.id = order_status.order_id
     LEFT JOIN core.customers 
       ON orders.customer_id = customers.id
     LEFT JOIN core.geo_lookup 
       ON customers.country_code = geo_lookup.country
WHERE LOWER(orders.product_name) LIKE '%macbook%'
  AND region = 'NA'
GROUP BY 1
ORDER BY 2 DESC
;


-- Overall average sales/revenue for Macbooks sold in North America
WITH
quarterly_metrics AS (
    SELECT 
        DATE_TRUNC(orders.purchase_ts, quarter) AS qt,
        COUNT(DISTINCT orders.id) AS sales,
        ROUND(SUM(orders.usd_price), 2) AS revenue
    FROM core.orders
         LEFT JOIN core.customers 
           ON orders.customer_id = customers.id
         LEFT JOIN core.geo_lookup 
           ON customers.country_code = geo_lookup.country
    WHERE LOWER(orders.product_name) LIKE '%macbook%'
      AND region = 'NA'
    GROUP BY 1
    ORDER BY 1 DESC
)

SELECT 
    AVG(sales) AS avg_qt_sales,
    AVG(revenue) AS avg_qt_orders
FROM quarterly_metrics
;


-- Overall average TTD (days for orders placed on website in 2022 OR products purchased on mobile devices (any year) per region
SELECT 
    geo_lookup.region, 
    ROUND(AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)), 2) AS avg_ttd_days
FROM core.order_status
     LEFT JOIN core.orders 
       ON order_status.order_id = orders.id
     LEFT JOIN core.customers 
       ON customers.id = orders.customer_id
     LEFT JOIN core.geo_lookup 
       ON geo_lookup.country = customers.country_code
WHERE (EXTRACT(YEAR FROM orders.purchase_ts) = 2022 AND purchase_platform = 'website')
   OR purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC
;


-- Yearly average TTD (days) & refund rates per region for orders placed on website in 2022 OR products purchased on mobile devices (any year)
SELECT
    EXTRACT(YEAR FROM orders.purchase_ts) AS yr,
    geo_lookup.region, 
    ROUND(
        AVG(DATE_DIFF(order_status.delivery_ts, order_status.purchase_ts, day)), 2) AS avg_ttd_days,
    ROUND(
        (COUNT(order_status.refund_ts) / COUNT(order_status.order_id)) * 100, 2) AS refund_rt
FROM core.order_status
     LEFT JOIN core.orders 
       ON order_status.order_id = orders.id
     LEFT JOIN core.customers 
       ON customers.id = orders.customer_id
     LEFT JOIN core.geo_lookup 
       ON geo_lookup.country = customers.country_code
WHERE (EXTRACT(YEAR FROM orders.purchase_ts) = 2022 AND purchase_platform = 'website')
   OR purchase_platform = 'mobile app'
GROUP BY 1, 2
ORDER BY 2 DESC, 1
;


-- Overall product refunds & refund rate
SELECT 
    CASE 
        WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' -- Fix inconsistent product name (same product)
        ELSE product_name 
    END AS products,
    SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refunds,
    ROUND(
        AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) AS refund_rt
FROM core.orders 
     LEFT JOIN core.order_status 
       ON orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC
;


-- Yearly product refunds & refund rate
SELECT 
    EXTRACT(YEAR FROM orders.purchase_ts) AS purchase_year,
    CASE 
        WHEN product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' -- Fix inconsistent product name (same product)
        ELSE product_name 
    END AS products,
    SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refunds,
    AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refund_rt
FROM core.orders 
     LEFT JOIN core.order_status 
       ON orders.id = order_status.order_id
GROUP BY 1, 2
ORDER BY 3 DESC
;


-- Best selling product per region
WITH
sales_by_product AS (
    SELECT 
        region,
        product_name,
        COUNT(DISTINCT orders.id) AS sales,
    FROM core.orders
         LEFT JOIN core.customers 
           ON orders.customer_id = customers.id
         LEFT JOIN core.geo_lookup 
           ON geo_lookup.country = customers.country_code
    GROUP BY 1, 2
)

SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) AS ranking,
    ROUND(
        (sales / (SELECT COUNT(DISTINCT id) FROM core.orders WHERE LOWER(product_name) = 'apple airpods headphones')) * 100, 2) AS sales_share
FROM sales_by_product
QUALIFY ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) = 1 -- BigQuery specific function
ORDER BY sales DESC
;


-- Loyalty/non-loyalty customers TTP (days/months)
SELECT 
    customers.loyalty_program, 
    ROUND(AVG(DATE_DIFF(order_status.purchase_ts, customers.created_on, day)), 1) AS avg_ttp_days,
    ROUND(AVG(DATE_DIFF(order_status.purchase_ts, customers.created_on, month)), 1) AS avg_ttp_months
FROM core.customers
     LEFT JOIN core.orders 
       ON customers.id = orders.customer_id
     LEFT JOIN core.order_status 
       ON order_status.order_id = orders.id
GROUP BY 1
;


-- Loyalty/non-loyalty customers TTP (days/months) per purchase platform
SELECT 
    orders.purchase_platform, 
    customers.loyalty_program, 
    ROUND(AVG(DATE_DIFF(order_status.purchase_ts, customers.created_on, day)), 1) AS avg_ttp_days,
    ROUND(AVG(DATE_DIFF(order_status.purchase_ts, customers.created_on, month)), 1) AS avg_ttp_months,
    COUNT(*) AS row_count
FROM core.customers
     LEFT JOIN core.orders 
       ON customers.id = orders.customer_id
     LEFT JOIN core.order_status 
       ON order_status.order_id = orders.id
GROUP BY 1, 2
;
