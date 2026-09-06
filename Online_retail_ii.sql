-- create staging tables and data cleaning
SELECT * FROM customers;
CREATE TABLE customer_staging AS SELECT *,
								CASE WHEN region = 'Metro Manila' OR
										region = 'Ilocos' OR
										region = 'Bicol' THEN 'Luzon'
									WHEN region = 'Cebu' THEN 'Visayas'
									ELSE 'Mindanao' END AS island
								FROM customers;
SELECT * FROM orders;
CREATE TABLE order_staging AS SELECT * FROM orders;
SELECT * FROM order_items;
CREATE TABLE item_staging AS SELECT order_id,
									product_id,
									CAST(REPLACE(unit_price_string,'$', '') AS DECIMAL(10,2)) as unit_price,
                                    quantity
							FROM order_items;

-- creating views
CREATE VIEW vw_customers AS SELECT * FROM customer_staging;
CREATE VIEW vw_orders AS SELECT * FROM order_staging;
CREATE VIEW vw_order_items AS SELECT * FROM item_staging;

-- monthly revenue
CREATE VIEW vw_monthly_revenue AS 
WITH monthly_sales AS (
	SELECT MONTH(o.order_date) AS month,
			SUM(CASE WHEN YEAR(o.order_date)=2025 THEN i.unit_price * i.quantity 
					ELSE 0 END) AS total_revenue_2025,
			SUM(CASE WHEN YEAR(o.order_date)=2026 THEN i.unit_price * i.quantity 
					ELSE 0 END) AS total_revenue_2026
	FROM order_staging o
	INNER JOIN item_staging i
		ON o.order_id=i.order_id
	GROUP BY MONTH(o.order_date)
	ORDER BY month ASC
)

SELECT 
	month,
    total_revenue_2025 AS revenue_2025,
    total_revenue_2026 AS revenue_2026,
    SUM(total_revenue_2025) OVER(ORDER BY month) as running_revenue_2025,
    SUM(total_revenue_2026) OVER(ORDER BY month) as running_revenue_2026,
    CASE WHEN total_revenue_2025 = 0 OR total_revenue_2026 = 0 THEN 'N/A'
		ELSE CONCAT(ROUND((total_revenue_2026-total_revenue_2025)/total_revenue_2025*100,2), '%')
        END AS yoy_change
FROM monthly_sales
ORDER BY month;

-- RFM categories
CREATE VIEW vw_Recency AS
WITH customer_recency AS (
	SELECT c.customer_id,
		DATEDIFF('2026-09-05', MAX(o.order_date)) AS recency_days
	FROM customer_staging c
    LEFT JOIN order_staging o
		ON c.customer_id=o.customer_id
	GROUP BY c.customer_id
),
r_category AS (
	SELECT customer_id,
		CASE WHEN recency_days <= 100 THEN 'Active'
			WHEN recency_days <= 200 THEN 'At Risk'
			WHEN recency_days IS NULL THEN 'Never Purchased'
			ELSE 'Lost' END AS recency_category
	FROM customer_recency
)

SELECT recency_category,
	COUNT(*) AS total_customers
FROM r_category
GROUP BY recency_category
ORDER BY FIELD(recency_category, 'Active','At Risk','Lost','Never Purchased');

CREATE VIEW vw_Frequency AS
WITH customer_frequency AS (
	SELECT customer_id,
		COUNT(*) AS total_orders
	FROM order_staging
	GROUP BY customer_id
),
f_category AS (
	SELECT customer_id,
		CASE WHEN total_orders = 1 THEN 'One-time Buyer'
			WHEN total_orders = 2 OR total_orders = 3 THEN 'Repeat Customer'
			WHEN total_orders > 3 THEN 'Frequent Buyer'
			ELSE 'Non-Buyer' END AS frequency_category
	FROM customer_frequency
)
SELECT frequency_category,
	COUNT(*) AS total_customers
FROM f_category
GROUP BY frequency_category
ORDER BY FIELD(frequency_category, 'Frequent Buyer', 'Repeat Customer', 'One-time Buyer', 'Non-Buyer');

CREATE VIEW vw_Monetary AS
WITH customer_monetary AS (
	SELECT o.customer_id, 
		SUM(i.quantity*i.unit_price) AS total_monetary
	FROM order_staging o
	RIGHT JOIN item_staging i
		ON o.order_id = i.order_id
	GROUP BY customer_id
    ORDER BY customer_id
),
ranked_spend AS (
	SELECT customer_id,
		total_monetary,
		PERCENT_RANK() OVER (ORDER BY total_monetary DESC) AS spend_percentile
	FROM customer_monetary
),
m_category AS (
	SELECT customer_id,
		total_monetary,
		CASE WHEN spend_percentile <= 0.05 THEN 'VIP (Top 5%)'
			WHEN spend_percentile <= 0.20 THEN 'High Value (Top 20%)'
			WHEN spend_percentile <= 0.50 THEN 'Core (Top 50%)'
			ELSE 'Low Value (Bottom 50%)' END AS monetary_category
	FROM ranked_spend
)
SELECT monetary_category,
	COUNT(*) AS total_customers
FROM m_category
GROUP BY monetary_category
ORDER BY FIELD(monetary_category, 'VIP (Top 5%)','High Value (Top 20%)','Core (Top 50%)','Low Value (Bottom 50%)');

-- product performance
CREATE VIEW vw_Product_Perf AS
SELECT product_id,
	SUM(quantity) AS total_quantity_sold,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity*unit_price) AS revenue,
    ROUND(SUM(quantity*unit_price)/COUNT(DISTINCT order_id),2) AS AOV,
    RANK() OVER(ORDER BY SUM(quantity*unit_price) DESC) AS item_rank
FROM item_staging
GROUP BY product_id
ORDER BY product_id;

-- vip customer % share

SELECT 
    monetary_category,
    total_customers,
    ROUND(
        (total_customers / 300) * 100, 
        2
    ) AS vip_customer_share_pct
FROM vw_Monetary
WHERE monetary_category = 'VIP (Top 5%)';

-- VIP revenue % share
CREATE VIEW vw_vip_share AS
WITH customer_spending AS (
    SELECT 
        o.customer_id,
        SUM(i.quantity * i.unit_price) AS total_spend
    FROM order_staging o
    JOIN item_staging i 
		ON o.order_id = i.order_id
    GROUP BY o.customer_id
),
ranked_customers AS (
    SELECT 
        customer_id,
        total_spend,
        PERCENT_RANK() OVER (ORDER BY total_spend DESC) AS spend_percentile
    FROM customer_spending
)
SELECT 
    SUM(CASE WHEN spend_percentile <= 0.05 THEN total_spend ELSE 0 END) AS vip_revenue,
    SUM(total_spend) AS total_revenue,
    ROUND(
        (SUM(CASE WHEN spend_percentile <= 0.05 THEN total_spend ELSE 0 END) / SUM(total_spend)), 
        4
    ) AS vip_revenue_share_pct
FROM ranked_customers;

-- at risk revenue %share
CREATE VIEW vw_atrisk_share AS
WITH customer_last_purchase AS (
    SELECT 
        c.customer_id,
        DATEDIFF('2026-09-05', MAX(o.order_date)) AS recency_days,
        COALESCE(SUM(i.quantity * i.unit_price), 0) AS lifetime_spend
    FROM customer_staging c
    LEFT JOIN order_staging o ON c.customer_id = o.customer_id
    LEFT JOIN item_staging i ON o.order_id = i.order_id
    GROUP BY c.customer_id
),
customer_recency_tagged AS (
    SELECT 
        customer_id,
        lifetime_spend,
        CASE 
            WHEN recency_days <= 100 THEN 'Active'
            WHEN recency_days <= 200 THEN 'At Risk'
            WHEN recency_days IS NULL THEN 'Never Purchased'
            ELSE 'Lost' 
        END AS recency_category
    FROM customer_last_purchase
)
SELECT 
    SUM(CASE WHEN recency_category = 'At Risk' THEN lifetime_spend ELSE 0 END) AS at_risk_revenue,
    SUM(lifetime_spend) AS total_revenue,
    ROUND(
        (SUM(CASE WHEN recency_category = 'At Risk' THEN lifetime_spend ELSE 0 END) / SUM(lifetime_spend)), 
        4
    ) AS at_risk_revenue_share_pct
FROM customer_recency_tagged;