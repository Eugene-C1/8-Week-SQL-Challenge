/*
Using a single SQL query - create a new output table which has the following details:
1. How many times was each product viewed?
2. How many times was each product added to cart?
3. How many times was each product added to a cart but not purchased (abandoned)?
4. How many times was each product purchased?
*/

SELECT *
FROM clique_bait.events
;

SELECT *
FROM clique_bait.event_identifier
;

SELECT *
FROM clique_bait.page_hierarchy
;

CREATE TEMPORARY TABLE temp_product_data AS
WITH new_cte AS
(
	SELECT
		visit_id,
		cbph.page_name,
		SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS page_view,
		SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_cart
	FROM clique_bait.events cbe
	LEFT JOIN clique_bait.page_hierarchy cbph
		ON cbe.page_id = cbph.page_id
	WHERE cbph.product_category IS NOT NULL
	GROUP BY visit_id, cbph.page_name
),
purchase_cte AS
(
	SELECT
		DISTINCT visit_id
	FROM clique_bait.events
	WHERE event_type = 3
)
SELECT
	page_name,
	SUM(page_view) AS views,
	SUM(add_cart) AS add_carts,
	SUM(CASE WHEN add_cart = 1 AND p.visit_id IS NULL THEN 1 ELSE 0 END) AS abandoned,
	SUM(CASE WHEN add_cart = 1 AND p.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS purchased
FROM new_cte n
LEFT JOIN purchase_cte p
	ON n.visit_id = p.visit_id
GROUP BY page_name
;

/*
Additionally, create another table which further aggregates the data for 
the above points but this time for each product category instead of individual products.
*/
CREATE TEMPORARY TABLE temp_product_category_data AS
WITH new_cte AS
(
	SELECT
		visit_id,
		cbph.product_category,
		SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS page_view,
		SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_cart
	FROM clique_bait.events cbe
	LEFT JOIN clique_bait.page_hierarchy cbph
		ON cbe.page_id = cbph.page_id
	WHERE cbph.product_category IS NOT NULL
	GROUP BY visit_id, cbph.product_category
)
SELECT
	product_category,
	SUM(page_view) AS views,
	SUM(add_cart) AS add_carts
FROM new_cte
GROUP BY product_category
ORDER BY 1
;


/*
Use your 2 new output tables - answer the following questions:

1. Which product had the most views, cart adds and purchases?
2. Which product was most likely to be abandoned?
3. Which product had the highest view to purchase percentage?
4. What is the average conversion rate from view to cart add?
5. What is the average conversion rate from cart add to purchase?
*/

-- 1. Which product had the most views, cart adds and purchases?
SELECT *
FROM temp_product_data
;

SELECT *
FROM temp_product_data
ORDER BY views DESC
LIMIT 1

SELECT *
FROM temp_product_data
ORDER BY add_carts DESC
LIMIT 1


SELECT *
FROM temp_product_data
ORDER BY purchased DESC
LIMIT 1
;

-- 2. Which product was most likely to be abandoned?

SELECT *
FROM temp_product_data
ORDER BY abandoned DESC
LIMIT 1

-- 3. Which product had the highest view to purchase percentage?
SELECT *
FROM temp_product_data
;


SELECT
	page_name,
	ROUND(100 * SUM(purchased) / SUM(views), 2) AS view_to_purchase_percentage 
FROM temp_product_data
GROUP BY page_name
ORDER BY 2 DESC
LIMIT 3
;

-- 4. What is the average conversion rate from view to cart add?
SELECT
	ROUND(AVG(100 * add_carts / views), 2) AS view_to_add_cart_percentage 
FROM temp_product_data
LIMIT 3
;

-- 5. What is the average conversion rate from cart add to purchase?
SELECT
	ROUND(AVG(100 * purchased / add_carts), 2) AS view_to_add_cart_percentage 
FROM temp_product_data
LIMIT 3
;



