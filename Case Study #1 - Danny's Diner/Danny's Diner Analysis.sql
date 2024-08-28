/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Answers:
-- 1. What is the total amount each customer spent at the restaurant?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT 
	sal.customer_id, 
    SUM(men.price) AS total_spent
FROM dannys_diner.sales sal
LEFT JOIN dannys_diner.menu men
	ON sal.product_id = men.product_id
GROUP BY sal.customer_id
;

-- 2. How many days has each customer visited the restaurant?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT 
	customer_id,
    COUNT(DISTINCT order_date) AS days_spent
FROM dannys_diner.sales
GROUP BY customer_id
;

-- 3. What was the first item from the menu purchased by each customer?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT *
FROM dannys_diner.members
;

WITH First_Order AS 
(
SELECT 
	sal.customer_id,
    sal.order_date,
    men.product_name,
    DENSE_RANK() OVER (PARTITION BY sal.customer_id ORDER BY sal.order_date) AS ranking
FROM dannys_diner.sales sal
LEFT JOIN dannys_diner.menu men
	ON sal.product_id = men.product_id
)
SELECT customer_id, product_name
FROM First_Order
WHERE ranking = 1
GROUP BY customer_id, product_name
;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT
	sal.product_id,
    men.product_name,
    COUNT(sal.product_id) AS most_purchased
FROM dannys_diner.sales sal
LEFT JOIN dannys_diner.menu men
	ON sal.product_id = men.product_id
GROUP BY sal.product_id, men.product_name
ORDER BY most_purchased DESC
LIMIT 1
;

-- 5. Which item was the most popular for each customer?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

WITH Most_Popular AS
(
SELECT 
	sal.customer_id,
    men.product_name,
    COUNT(men.product_id) AS order_count,
    DENSE_RANK() OVER (PARTITION BY sal.customer_id ORDER BY COUNT(sal.product_id) DESC) AS ranking
FROM dannys_diner.sales sal
LEFT JOIN dannys_diner.menu men
	ON sal.product_id = men.product_id
GROUP BY
	sal.customer_id,
    men.product_name
)
SELECT 
	customer_id,
    product_name,
	order_count
FROM Most_Popular
WHERE ranking = 1
GROUP BY customer_id, product_name
;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT *
FROM dannys_diner.members
;

WITH First_Order AS
(
SELECT 
	mem.customer_id,
    sal.product_id,
    DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date) as ranking
FROM dannys_diner.members mem
LEFT JOIN dannys_diner.sales sal
	ON mem.customer_id = sal.customer_id
WHERE mem.join_date <= sal.order_date
)
SELECT 
	customer_id,
    product_name
FROM First_Order fo
LEFT JOIN dannys_diner.menu men
	ON fo.product_id = men.product_id
WHERE ranking = 1
;
-- 7. Which item was purchased just before the customer became a member?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT *
FROM dannys_diner.members
;

WITH First_Order AS
(
SELECT 
	mem.customer_id,
    sal.product_id,
    DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date DESC) as ranking
FROM dannys_diner.members mem
LEFT JOIN dannys_diner.sales sal
	ON mem.customer_id = sal.customer_id
WHERE mem.join_date > sal.order_date
)
SELECT 
	customer_id,
    product_name
FROM First_Order fo
LEFT JOIN dannys_diner.menu men
	ON fo.product_id = men.product_id
WHERE ranking = 1
;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT *
FROM dannys_diner.sales
;

SELECT *
FROM dannys_diner.menu
;

SELECT *
FROM dannys_diner.members
;

SELECT 
	mem.customer_id,
    COUNT(sal.product_id) AS total_items,
    SUM(men.price) as total_spent
FROM dannys_diner.members mem
INNER JOIN dannys_diner.sales sal
	ON mem.customer_id = sal.customer_id
	AND mem.join_date > sal.order_date
INNER JOIN dannys_diner.menu men
	ON men.product_id = sal.product_id
GROUP BY sal.customer_id
ORDER BY 1
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH Point_Conversion AS
(
SELECT 
	product_id,
    CASE
		WHEN product_id = 1 THEN price * 20
        ELSE price * 10 END AS points
FROM dannys_diner.menu
)
SELECT 
	sal.customer_id,
    SUM(pc.points) AS total_points
FROM Point_Conversion pc
INNER JOIN dannys_diner.sales sal
	ON pc.product_id = sal.product_id
GROUP BY customer_id
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH Dates_cte AS
(
SELECT
	customer_id,
    join_date,
    join_date + INTERVAL 7 DAY AS valid_date,
    DATE '2021-01-31' AS last_date
FROM dannys_diner.members
)
SELECT sal.customer_id,
	SUM(
    CASE
		WHEN men.product_id = 1 THEN 20 * men.price
        WHEN sal.order_date BETWEEN dat.valid_date AND dat.last_date THEN 20 * men.price
        ELSE 10 * men.price END ) AS total_points
FROM Dates_cte dat
LEFT JOIN dannys_diner.sales sal
	ON dat.customer_id = sal.customer_id
INNER JOIN dannys_diner.menu men
	ON sal.product_id = men.product_id
GROUP BY sal.customer_id
;

