-- Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4. What was the average distance travelled for each customer?
-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7. What is the successful delivery percentage for each runner?

-- Data Cleaning


-- Answers:
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
	WEEK(registration_date) + 1 AS week_number,
    COUNT(runner_id) AS signed_up_runners
FROM runners
GROUP BY week_number
;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT
	ro.runner_id,
    AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)) AS time_difference_minutes
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
WHERE pickup_time IS NOT NULL
GROUP BY ro.runner_id
;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

WITH Number_of_Order AS
(
SELECT 
	co.order_id,
	COUNT(co.order_id) AS pizza_order,
    co.order_time,
    ro.pickup_time
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.distance > 0
GROUP BY 
	co.order_id,
    co.order_time,
    ro.pickup_time
)
SELECT 
	pizza_order,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)), 2) AS avg_prepare_time_minutes
FROM Number_of_Order
GROUP BY pizza_order
;

-- 4. What was the average distance travelled for each customer?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT 
	co.customer_id,
    ROUND(AVG(distance), 2)as avg_distance
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
WHERE ro.distance > 0
GROUP BY co.customer_id
;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT MAX(duration) - MIN(duration) AS time_difference
FROM runner_orders
WHERE duration > 0
;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT *
FROM customer_orders
;

SELECT *
FROM runner_orders
;

SELECT 
	co.order_id,
    co.customer_id,
    ro.runner_id,
    COUNT(co.order_id) AS pizza_count,
    ro.distance AS distance_km,
    ro.distance / ro.duration AS avg_speed_mins
FROM customer_orders co
LEFT JOIN runner_orders ro
	ON co.order_id = ro.order_id
WHERE distance > 0
GROUP BY
	co.order_id,
    co.customer_id,
    ro.runner_id,
    distance_km,
    avg_speed_mins
;

-- 7. What is the successful delivery percentage for each runner?
SELECT *
FROM runner_orders
;

SELECT 
	runner_id,
    COUNT(order_id) AS total_order,
    COUNT(pickup_time) AS completed_order,
	ROUND((SUM(
    CASE WHEN distance IS NULL THEN 0
    ELSE 1 END) / COUNT(order_id)) * 100, 0) AS delivery_percentage
FROM runner_orders
GROUP BY runner_id
;




