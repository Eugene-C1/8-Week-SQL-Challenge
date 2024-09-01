-- C. Ingredients Optimisation
-- 1.What are the standard ingredients for each pizza?
-- 2.What was the most commonly added extra?
-- 3.What was the most common exclusion?
-- 4.Generate an order item for each record in the customers_orders table in the format of one of the following: 
-- 		* MeatLovers 
-- 		* MeatLovers-ExcludeBeef 
-- 		* MeatLovers-ExtraBacon 
-- 		* MeatLovers-ExcludeCheese,Bacon-ExtraMushroom,Peppers 
-- 5.Generate an alphabetically ordered comma-separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

-- Data Cleaning
DROP TABLE row_split_customer_orders;

CREATE TEMPORARY TABLE row_split_customer_orders AS
SELECT 
	t.row_num,
    t.order_id,
    t.pizza_id,
    TRIM(js1.exclusions) AS exclusions,
    TRIM(js2.extras) AS extras,
    t.order_time
FROM
	(SELECT
		*,
		ROW_NUMBER() OVER() AS row_num
	FROM customer_orders) t
INNER JOIN JSON_TABLE(TRIM(REPLACE(JSON_ARRAY(t.exclusions), ',', '","')),
						'$[*]' COLUMNS(exclusions VARCHAR(50) PATH '$')) js1
INNER JOIN JSON_TABLE(TRIM(REPLACE(JSON_ARRAY(t.extras), ',', '","')), 
						'$[*]' COLUMNS(extras VARCHAR(5) PATH '$' )) js2
;



SELECT *
FROM row_split_customer_orders
;

SELECT *
FROM pizza_recipes
;

DROP TABLE row_split_pizza_recipes;

CREATE TEMPORARY TABLE row_split_pizza_recipes AS
SELECT
	t.pizza_id,
    TRIM(js.toppings) AS topping_id
FROM
	pizza_recipes t
JOIN JSON_TABLE(TRIM(REPLACE(JSON_ARRAY(t.toppings), ',', '","')),
						'$[*]' COLUMNS (toppings VARCHAR (50) PATH '$')) js
;

SELECT *
FROM row_split_pizza_recipes
;

-- Answers:
-- 1.What are the standard ingredients for each pizza?
SELECT *
FROM row_split_pizza_recipes
;

SELECT *
FROM pizza_toppings
;

SELECT 
	pr.pizza_id,
    pz.pizza_name,
    GROUP_CONCAT(DISTINCT pt.topping_name) AS ingredients
FROM row_split_pizza_recipes pr
JOIN pizza_toppings pt
	ON pr.topping_id = pt.topping_id
JOIN pizza_names pz
	ON pz.pizza_id = pr.pizza_id
GROUP BY
	pr.pizza_id,
	pz.pizza_name
;

-- 2.What was the most commonly added extra?
SELECT *
FROM row_split_customer_orders
;

SELECT 
	pt.topping_id,
    pt.topping_name,
	COUNT(extras) AS num_count
FROM row_split_customer_orders co
JOIN pizza_toppings pt
	ON co.extras = pt.topping_id
GROUP BY 
	pt.topping_id,
    pt.topping_name
ORDER BY num_count DESC
LIMIT 1
;

-- 3.What was the most common exclusion?
SELECT *
FROM row_split_customer_orders
;

SELECT 
	pt.topping_id,
    pt.topping_name,
	COUNT(exclusions) AS num_count
FROM row_split_customer_orders co
JOIN pizza_toppings pt
	ON co.exclusions = pt.topping_id
GROUP BY 
	pt.topping_id,
    pt.topping_name
ORDER BY num_count DESC
LIMIT 1
;

-- 4.Generate an order item for each record in the customers_orders table in the format of one of the following: 
-- 		* MeatLovers 
-- 		* MeatLovers-ExcludeBeef 
-- 		* MeatLovers-ExtraBacon 
-- 		* MeatLovers-ExcludeCheese,Bacon-ExtraMushroom,Peppers 
SELECT *
FROM row_split_customer_orders
;

WITH Order_Summary_CTE AS
(
SELECT 
	t1.row_num,
	t1.order_id,
    t1.pizza_name,
    GROUP_CONCAT(DISTINCT t1.topping_name) AS excluded_topping,
    GROUP_CONCAT(DISTINCT t2.topping_name) AS included_topping
FROM
	(
		SELECT *
        FROM row_split_customer_orders
        LEFT JOIN pizza_names USING (pizza_id)
        LEFT JOIN pizza_toppings ON topping_id = exclusions) t1
LEFT JOIN
	pizza_toppings t2 ON t2.topping_id = extras
GROUP BY
	t1.row_num,
	t1.order_id,
    t1.pizza_name
)
SELECT
	order_id,
    CASE 
		WHEN excluded_topping IS NULL
			AND included_topping IS NULL THEN pizza_name
		WHEN excluded_topping IS NULL 
			AND included_topping IS NOT NULL THEN CONCAT(pizza_name, ' - Include ', included_topping)
		WHEN excluded_topping IS NOT NULL 
			AND included_topping IS NULL THEN CONCAT(pizza_name, ' - Exclude ', excluded_topping)
        ELSE CONCAT(pizza_name, ' - Include ', included_topping, ' - Exclude ', excluded_topping)
        END AS order_item
FROM Order_Summary_CTE
;

-- 5.Generate an alphabetically ordered comma-separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients


SELECT *
FROM row_split_pizza_recipes
;

SELECT *
FROM row_split_customer_orders
;

WITH Recipe_CTE AS
(
SELECT 
	
	pr.pizza_id,
    pz.pizza_name,
    pt.topping_id,
    pt.topping_name AS ingredients
FROM row_split_pizza_recipes pr
JOIN pizza_toppings pt
	ON pr.topping_id = pt.topping_id
JOIN pizza_names pz
	ON pz.pizza_id = pr.pizza_id
GROUP BY
	pr.pizza_id,
	pz.pizza_name,
    pt.topping_id,
    ingredients
ORDER BY pizza_id, ingredients
),
Alphabetical_Recipe_CTE AS
(
SELECT
	co.order_id,
	rc.pizza_id AS temp,
    rc.pizza_name,
    rc.topping_id,
    rc.ingredients,
    co.exclusions,
    co.extras
FROM Recipe_CTE rc
LEFT JOIN row_split_customer_orders co ON rc.pizza_id = co.pizza_id
ORDER BY
	co.order_id,
    rc.ingredients
),
Summary_CTE AS
(
SELECT
	order_id,
    pizza_name,
	CASE 
		WHEN topping_id = extras THEN CONCAT('2x', ingredients)
        ELSE ingredients
        END AS extra_ingredients
FROM Alphabetical_Recipe_CTE
)
SELECT
	order_id,
    pizza_name,
    GROUP_CONCAT(DISTINCT extra_ingredients)
FROM Summary_CTE
GROUP BY
	order_id,
    pizza_name
;
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
DROP TABLE row_split_customer_orders2;

CREATE TEMPORARY TABLE row_split_customer_orders2 AS
SELECT 
	t.row_num,
    t.order_id,
    t.pizza_id,
    TRIM(js2.extras) AS extras
FROM
	(SELECT
		*,
		ROW_NUMBER() OVER() AS row_num
	FROM customer_orders) t
INNER JOIN JSON_TABLE(TRIM(REPLACE(JSON_ARRAY(t.extras), ',', '","')), 
						'$[*]' COLUMNS(extras VARCHAR(5) PATH '$' )) js2
;

WITH Recipe_CTE AS
(
SELECT 
	pr.pizza_id,
    pz.pizza_name,
    pt.topping_id,
    pt.topping_name AS ingredients
FROM row_split_pizza_recipes pr
JOIN pizza_toppings pt
	ON pr.topping_id = pt.topping_id
JOIN pizza_names pz
	ON pz.pizza_id = pr.pizza_id
GROUP BY
	pr.pizza_id,
	pz.pizza_name,
    pt.topping_id,
    ingredients
ORDER BY pizza_id, ingredients
),
Customer_Orders_CTE AS
(
SELECT
	co.order_id,
	rc.pizza_id AS temp,
    rc.pizza_name,
    rc.topping_id,
    rc.ingredients
FROM Recipe_CTE rc
LEFT JOIN row_split_customer_orders co ON rc.pizza_id = co.pizza_id
ORDER BY
	co.order_id,
    rc.ingredients
),
COUNT_CTE AS
( 
SELECT 
	topping_id,
    ingredients,
    COUNT(topping_id) AS counts
FROM Customer_Orders_CTE cte
GROUP BY 
	topping_id,
    ingredients
ORDER BY 3 DESC
)
SELECT
    cte.topping_id,        
    cte.ingredients,    
    CASE
		WHEN co2.extras IS NOT NULL THEN COUNT(cte.topping_id) + counts
        ELSE counts END AS final_count
FROM 
    COUNT_CTE cte
LEFT JOIN 
    (
        SELECT extras 
        FROM row_split_customer_orders2
    ) AS co2 
    ON co2.extras = cte.topping_id
GROUP BY
	cte.topping_id,        
    cte.ingredients
ORDER BY 3 DESC;






