-- A. Customer Nodes Explanation
-- 1. How many unique nodes are there on the Data Bank system?
-- 2. What is the number of nodes per region?
-- 3. How many customers are allocated to each region?
-- 4. How many days on average are customers reallocated to a different node?
-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- Answers:
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_customer_node
FROM customer_nodes
;

-- 2. What is the number of nodes per region?
SELECT *
FROM customer_nodes
;

SELECT
	reg.region_name,
    COUNT(DISTINCT cn.node_id) AS node_count
FROM customer_nodes cn
JOIN regions reg
	ON cn.region_id = reg.region_id
GROUP BY reg.region_name
;

-- 3. How many customers are allocated to each region?
SELECT
	reg.region_name,
    COUNT(cn.customer_id) AS customer_count
FROM customer_nodes cn
JOIN regions reg
	ON cn.region_id = reg.region_id
GROUP BY reg.region_name
ORDER BY 2
;

-- 4. How many days on average are customers reallocated to a different node?
SELECT *
FROM customer_nodes
;

WITH node_days AS
(
SELECT 
	customer_id,
	node_id,
    TIMESTAMPDIFF(DAY, start_date, end_date) AS days_in_node
FROM customer_nodes
WHERE end_date != '9999-12-31'
GROUP BY customer_id, node_id, days_in_node
),
total_node_days AS
(
SELECT
	customer_id,	
    SUM(days_in_node) AS total_day_in_node
FROM node_days
GROUP BY customer_id
)
SELECT ROUND(AVG(total_day_in_node)) AS avg_node_reallocation
FROM total_node_days
;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


