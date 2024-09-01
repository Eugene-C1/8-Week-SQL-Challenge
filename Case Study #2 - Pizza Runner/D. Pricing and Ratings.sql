-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 andpizza_names Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- 2. What if there was an additional $1 charge for any pizza extras?
-- 	* Add cheese is $1 extra
-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- 	* customer_id
-- 	* order_id
-- 	* runner_id
-- 	* rating
-- 	* order_time
-- 	* pickup_time
-- 	* Time between order and pickup
-- 	* Delivery duration
-- 	* Average speed
-- 	* Total number of pizzas
-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

-- Answers:
-- 1.Calculate total revenue from pizza sales with no charges for changes.
DROP TABLE customer_order_temp;

CREATE TEMPORARY TABLE customer_order_temp AS
SELECT 
    co.customer_id,
	ro.order_id,
    ro.runner_id,
    co.pizza_id,
    pz.pizza_name,
    co.order_time,
    ro.pickup_time,
	TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time) AS time_between_order_and_pickup_min,
    ro.duration AS delivery_duration_mins,
    (ro.distance / ro.duration) AS avg_speed_km,
	COUNT(co.pizza_id) AS total_pizzas,
    TRIM(js2.extras) AS extras
FROM runner_orders ro
LEFT JOIN customer_orders co
	ON ro.order_id = co.order_id
LEFT JOIN pizza_names pz
	ON co.pizza_id = pz.pizza_id
INNER JOIN JSON_TABLE(TRIM(REPLACE(JSON_ARRAY(co.extras), ',', '","')), 
						'$[*]' COLUMNS(extras VARCHAR(5) PATH '$' )) js2
WHERE ro.distance > 0
GROUP BY
co.customer_id,
	ro.order_id,
    ro.runner_id,
    co.pizza_id,
    pz.pizza_name,
    co.order_time,
    ro.pickup_time,
    delivery_duration_mins,
    avg_speed_km,
    extras
;

SELECT
	SUM(t1.price) AS total_revenue
FROM 
	(SELECT 
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			ELSE 10 END AS price
	 FROM customer_order_temp
	) t1
;

-- 2. What if there was an additional $1 charge for any pizza extras?
SELECT *
FROM customer_order_temp
;

SELECT
	SUM(t1.pizza_price) + COUNT(t1.extras) AS total_revenue
FROM 
	(SELECT
		extras,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			ELSE 10 END AS pizza_price
	 FROM customer_order_temp
	) t1
;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
SELECT *
FROM customer_order_temp;

DROP TABLE rating_table;

CREATE TEMPORARY TABLE rating_table (
    order_id INT,
    runner_id INT,
    rating INT
);

INSERT INTO rating_table
SELECT
	order_id,
    runner_id,
    CASE
		WHEN delivery_duration_mins <= 10 THEN 5
        WHEN delivery_duration_mins > 10 AND delivery_duration_mins < 15 THEN 4
        WHEN delivery_duration_mins = 20 THEN 4
        WHEN delivery_duration_mins > 20 THEN 3
        END AS rating
FROM customer_order_temp
;

SELECT *
FROM rating_table
;

DROP TABLE new_customer_order_temp;

CREATE TEMPORARY TABLE new_customer_order_temp AS
SELECT 
    cot.*,
    rt.rating
FROM customer_order_temp cot
LEFT JOIN (
    SELECT DISTINCT order_id, rating
    FROM rating_table
) rt
    ON cot.order_id = rt.order_id;

SELECT *
FROM new_customer_order_temp
;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT
	SUM(t1.pizza_price) - SUM(t1.wage)AS total_profit
FROM 
	(SELECT
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			ELSE 10 END AS pizza_price,
		(ro.distance * 0.30) AS wage
	 FROM new_customer_order_temp cot
     JOIN runner_orders ro
		ON cot.order_id = ro.order_id
	) t1
;