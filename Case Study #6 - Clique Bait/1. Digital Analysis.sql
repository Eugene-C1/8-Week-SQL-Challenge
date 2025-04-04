/*
Using the available datasets - answer the following questions using a single query for each one:

1. How many users are there?
2. How many cookies does each user have on average?
3. What is the unique number of visits by all users per month?
4. What is the number of events for each event type?
5. What is the percentage of visits which have a purchase event?
6. What is the percentage of visits which view the checkout page but do not have a purchase event?
7. What are the top 3 pages by number of views?
8. What is the number of views and cart adds for each product category?
9. What are the top 3 products by purchases?

*/

-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users
;

-- 2. How many cookies does each user have on average?
SELECT *
FROM clique_bait.users
;

WITH cookie_cte AS
(
	SELECT
		user_id,
		COUNT(cookie_id) AS cookies
	FROM clique_bait.users
	GROUP BY user_id
)
SELECT
	ROUND(AVG(cookies)) AS avg_cookies
FROM cookie_cte
;

-- 3. What is the unique number of visits by all users per month?
SELECT *
FROM clique_bait.events
;

SELECT 
	EXTRACT(MONTH FROM event_time) AS month_name,
	COUNT(DISTINCT visit_id) AS visits
FROM clique_bait.events
GROUP BY month_name
;

-- 4. What is the number of events for each event type?
SELECT *
FROM clique_bait.events
;

SELECT
	event_type,
	COUNT(*) AS total_event
FROM clique_bait.events
GROUP BY event_type
ORDER BY 1
;

-- 5. What is the percentage of visits which have a purchase event?
SELECT *
FROM clique_bait.events
;

SELECT *
FROM clique_bait.event_identifier
;

SELECT
	ROUND(100 *
		COUNT(DISTINCT cbe.visit_id) / 
			(SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events),0) AS purchase_percentage
FROM clique_bait.events cbe
LEFT JOIN clique_bait.event_identifier cbei
	ON cbe.event_type = cbei.event_type
WHERE cbei.event_name = 'Purchase'
;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
SELECT *
FROM clique_bait.events
;

SELECT *
FROM clique_bait.event_identifier
;

SELECT *
FROM clique_bait.page_hierarchy
;

WITH checkout_cte AS
(
	SELECT
		visit_id,
		MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
		MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
	FROM clique_bait.events
	GROUP BY visit_id
)
SELECT
	ROUND(100 *
		(SUM(checkout) - SUM(purchase)) / NULLIF(SUM(checkout), 0), 2) AS percentage_of_checkout_without_purchase
FROM checkout_cte
;

-- 7. What are the top 3 pages by number of views?
SELECT *
FROM clique_bait.events
;

SELECT *
FROM clique_bait.event_identifier
;

SELECT *
FROM clique_bait.page_hierarchy
;

SELECT
	cbph.page_name,
	COUNT(cbe.page_id) AS page_views
FROM clique_bait.events cbe
LEFT JOIN clique_bait.page_hierarchy cbph
	ON cbph.page_id = cbe.page_id
GROUP BY page_name
ORDER BY 2 DESC
LIMIT 3
;

-- 8. What is the number of views and cart adds for each product category?
SELECT *
FROM clique_bait.events
;

SELECT *
FROM clique_bait.event_identifier
;

SELECT *
FROM clique_bait.page_hierarchy
;

SELECT
	cbph.product_category,
	SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS total_view,
	SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS total_add_cart
FROM clique_bait.events cbe
LEFT JOIN clique_bait.page_hierarchy cbph
	ON cbe.page_id = cbph.page_id
WHERE cbph.product_category IS NOT NULL
GROUP BY cbph.product_category
ORDER BY 2 DESC
;

-- 9. What are the top 3 products by purchases?
SELECT *
FROM clique_bait.events
;

SELECT *
FROM clique_bait.event_identifier
;

SELECT *
FROM clique_bait.page_hierarchy
;

WITH new_cte AS
(
	SELECT
		visit_id,
		cbph.page_name,
		SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_cart
	FROM clique_bait.events cbe
	LEFT JOIN clique_bait.page_hierarchy cbph
		ON cbe.page_id = cbph.page_id
	WHERE cbph.product_category IS NOT NULL
	GROUP BY visit_id, cbph.page_name
),
purchase_cte AS
(
	SELECT DISTINCT visit_id
	FROM clique_bait.events
	WHERE event_type = 3
)
SELECT
	page_name,
	SUM(CASE WHEN p.visit_id IS NOT NULL AND add_cart = 1 THEN 1 ELSE 0 END) AS total_sold
FROM new_cte n
LEFT JOIN purchase_cte p
	ON n.visit_id = p.visit_id
GROUP BY page_name
ORDER BY 2 DESC
LIMIT 3
;





