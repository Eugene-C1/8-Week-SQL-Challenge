-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- 6. What is the number and percentage of customer plans after their initial free trial?
-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- 8. How many customers have upgraded to an annual plan in 2020?
-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- Answers:
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS total_customer
FROM subscriptions
;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
	MONTH(start_date) AS month_date,
	MONTHNAME(start_date) AS month_name,
    COUNT(MONTHNAME(start_date)) AS count
FROM subscriptions
WHERE plan_id = 0
GROUP BY 
	month_date,
	month_name
ORDER BY 1
;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
	plan.plan_id,
    plan.plan_name,
    COUNT(sub.plan_id) AS num_events
FROM subscriptions sub
JOIN plans plan
	ON sub.plan_id = plan.plan_id
WHERE start_date >= '2021-01-01'
GROUP BY
	plan.plan_id,
    plan.plan_name
ORDER BY 1
;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
	COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) AS customer_count,
    ROUND
    (
		100 * COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) /
        COUNT(DISTINCT customer_id), 1
    ) AS customer_percentage
FROM subscriptions
;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH ranking_cte AS
(
SELECT 
	customer_id,
    plan_id,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date) AS ranking
FROM subscriptions
)
SELECT
	COUNT(DISTINCT CASE WHEN ranking = 2 AND plan_id = 4 THEN customer_id END) customer_churn_count,
    ROUND
    (
		100 * COUNT(DISTINCT CASE WHEN ranking = 2 AND plan_id = 4 THEN customer_id END) /
        COUNT(DISTINCT customer_id), 0
    ) AS churn_customer_percentage
FROM ranking_cte
;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH ranking_cte AS
(
SELECT 
	customer_id,
    plan_id,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date) AS ranking
FROM subscriptions
)
SELECT 
	cte.plan_id,
    plan.plan_name,
    COUNT(CASE WHEN ranking = 2 THEN cte.plan_id END) AS count,
    ROUND
    (
		100 * COUNT(CASE WHEN ranking = 2 THEN cte.plan_id END) / 
        (SELECT COUNT(DISTINCT customer_id) FROM ranking_cte)
	, 1) AS customer_percentage
FROM ranking_cte cte
JOIN plans plan
	ON cte.plan_id = plan.plan_id
    AND cte.plan_id > 0
GROUP BY 
	cte.plan_id,
    plan.plan_name
;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH ranking_cte AS
(
SELECT 
	customer_id,
    plan_id,
    start_date,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS ranking
FROM subscriptions
WHERE start_date <= '2020-12-31'
)
SELECT 
	cte.plan_id,
    plan.plan_name,
    COUNT(CASE WHEN ranking = 1 THEN cte.plan_id END) AS count,
    ROUND
    (
		100 * COUNT(CASE WHEN ranking = 1 THEN cte.plan_id END) / 
        (SELECT COUNT(DISTINCT customer_id) FROM ranking_cte)
	, 1) AS customer_percentage
FROM ranking_cte cte
JOIN plans plan
	ON cte.plan_id = plan.plan_id
GROUP BY 
	cte.plan_id,
    plan.plan_name
;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS upgraded_customer
FROM subscriptions
WHERE plan_id = 3 AND start_date <= '2020-12-31'
;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trial_cte AS
(
SELECT *
FROM subscriptions
WHERE plan_id = 0
),
annual_cte AS
(
SELECT *
FROM subscriptions
WHERE plan_id = 3
)
SELECT
	ROUND(AVG(TIMESTAMPDIFF(DAY, trial.start_date, annual.start_date)), 0) AS avg_days_to_upgrade
FROM trial_cte trial
JOIN annual_cte annual
	ON trial.customer_id = annual.customer_id
;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial_cte AS
(
SELECT *
FROM subscriptions
WHERE plan_id = 0
),
annual_cte AS
(
SELECT *
FROM subscriptions
WHERE plan_id = 3
),
days_cte AS
(
SELECT
	TIMESTAMPDIFF(DAY, trial.start_date, annual.start_date) AS days_to_upgrade
FROM trial_cte trial
JOIN annual_cte annual
	ON trial.customer_id = annual.customer_id
)
SELECT
    CASE 
        WHEN days_to_upgrade BETWEEN 0 AND 30 THEN '0-30 days'
        WHEN days_to_upgrade BETWEEN 30 AND 60 THEN '30-60 days'
        WHEN days_to_upgrade BETWEEN 60 AND 90 THEN '60-90 days'
        WHEN days_to_upgrade BETWEEN 90 AND 120 THEN '90-120 days'
        WHEN days_to_upgrade BETWEEN 120 AND 150 THEN '120-150 days'
        WHEN days_to_upgrade BETWEEN 150 AND 180 THEN '150-180 days'
        WHEN days_to_upgrade BETWEEN 180 AND 210 THEN '180-210 days'
        ELSE '210+ days'
    END AS period,
    COUNT(*) AS customer_count
FROM days_cte
GROUP BY period
ORDER BY 
    MIN(days_to_upgrade)
;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT *
FROM subscriptions
;

WITH ranked_cte AS
(
SELECT 
	customer_id,
	plan_id,
    LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_plan_id
FROM subscriptions
WHERE start_date < '2020-12-31'
)
SELECT COUNT(DISTINCT customer_id) AS customer_downgrade
FROM ranked_cte
WHERE plan_id = 2 AND next_plan_id = 1
;