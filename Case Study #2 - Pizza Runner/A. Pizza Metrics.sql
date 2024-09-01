-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
-- 2. How many unique customer orders were made?
-- 3. How many successful orders were delivered by each runner?
-- 4. How many of each type of pizza was delivered?
-- 5. How many Vegetarian and Meatlovers pizzas were ordered by each customer?
-- 6. What was the maximum number of pizzas delivered in a single order?
-- 7. For each customer, how many delivered pizzas had at least 1 change (exclusions or extras) and how many had no changes?
-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10. What was the volume of orders for each day of the week?

-- Data Cleaning
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = 'null';

UPDATE customer_orders
SET extras = NULL
WHERE extras = 'null' ;

UPDATE runner_orders
SET cancellation =  NULL
WHERE cancellation = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = ''
;

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null'
;

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null'
;

UPDATE runner_orders
SET distance = REPLACE(distance, 'km', '')
;

UPDATE runner_orders
SET duration = REPLACE(distance, 'km%', '')
;

ALTER TABLE runner_orders
MODIFY COLUMN duration FLOAT
;

ALTER TABLE runner_orders
MODIFY COLUMN distance FLOAT
;

ALTER TABLE runner_orders
MODIFY COLUMN pickup_time TIMESTAMP;

ALTER TABLE runner_orders
MODIFY COLUMN distance FLOAT;

-- Answers:
-- 1. How many pizzas were ordered?
SELECT COUNT(order_id) AS total_order
FROM customer_orders
;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS distinct_order
FROM customer_orders
;

-- 3. How many successful orders were delivered by each runner?
SELECT *
FROM runner_orders
;

SELECT 
	runner_id,
    COUNT(order_id) as completed_order
FROM runner_orders
WHERE distance > 0
GROUP BY
	runner_id
;

-- 4. How many of each type of pizza was delivered?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT *
FROM pizza_names
;

SELECT 
    co.pizza_id,
    pn.pizza_name,
    COUNT(ro.order_id) as completed_order
FROM runner_orders ro
LEFT JOIN customer_orders co
	ON ro.order_id = co.order_id
LEFT JOIN pizza_names pn
	ON co.pizza_id = pn.pizza_id
WHERE ro.distance > 0
GROUP BY co.pizza_id, pn.pizza_name
;

-- 5. How many Vegetarian and Meatlovers pizzas were ordered by each customer?
SELECT *
FROM customer_orders
;

SELECT *
FROM pizza_names
;

SELECT 
	co.customer_id,
    pn.pizza_name,
    COUNT(co.pizza_id) AS ordered_pizza
FROM customer_orders co
LEFT JOIN pizza_names pn
	ON co.pizza_id = pn.pizza_id
GROUP BY
	co.customer_id,
    pn.pizza_name
ORDER BY 1
;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT
	co.order_id,
    COUNT(co.pizza_id) AS number_of_orders
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
    AND ro.distance > 0
GROUP BY order_id
;

-- 7. For each customer, how many delivered pizzas had at least 1 change (exclusions or extras) and how many had no changes?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT 
	customer_id,
    SUM(
		CASE WHEN co.exclusions != 'null' OR co.extras != 'null' THEN 1
        ELSE 0 END) AS has_changes,
	SUM(
		CASE WHEN co.exclusions = 'null' AND co.extras = 'null' THEN 1
        ELSE 0 END) AS no_changes
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.distance > 0
GROUP BY customer_id
;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT
	co.order_id,
    COUNT(co.pizza_id) AS total_pizza
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
WHERE exclusions != 'null' AND extras != 'null' AND ro.cancellation = 'null'
GROUP BY order_id
;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT
	HOUR(order_time) AS hour_of_day,
    COUNT(pizza_id) AS number_of_pizza
FROM customer_orders
GROUP BY hour_of_day
ORDER BY 1
;

-- 10. What was the volume of orders for each day of the week?
SELECT
	DAYNAME(order_time) AS day_of_the_week,
    COUNT(pizza_id) AS number_of_pizza
FROM customer_orders
GROUP BY day_of_the_week
;


