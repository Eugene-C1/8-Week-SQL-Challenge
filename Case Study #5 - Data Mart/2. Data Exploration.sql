
/*
Data Exploration
1.What day of the week is used for each week_date value?
2.What range of week numbers are missing from the dataset?
3.How many total transactions were there for each year in the dataset?
4.What is the total sales for each region for each month?
5.What is the total count of transactions for each platform?
6.What is the percentage of sales for Retail vs Shopify for each month?
7.What is the percentage of sales by demographic for each year in the dataset?
8.Which age_band and demographic values contribute the most to Retail sales?
9.Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
*/

-- Answers:
-- 1.What day of the week is used for each week_date value?
SELECT *
FROM clean_weekly_sales
;

SELECT DAYNAME(week_date) AS week_day
FROM clean_weekly_sales
GROUP BY week_day
;

-- 2.What range of week numbers are missing from the dataset?
SELECT *
FROM clean_weekly_sales
;

SELECT MIN(week_number), MAX(week_number)
FROM clean_weekly_sales
;

WITH RECURSIVE number_series AS (
    SELECT 1 AS week_number
    UNION ALL
    SELECT week_number + 1
    FROM number_series
    WHERE week_number < 35
)
SELECT week_number
FROM number_series
WHERE week_number NOT IN (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales
);

-- 3.How many total transactions were there for each year in the dataset?
SELECT *
FROM clean_weekly_sales
;

SELECT calendar_year, SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
;

-- 4.What is the total sales for each region for each month?
SELECT *
FROM clean_weekly_sales
;

SELECT calendar_year, SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY calendar_year
;

-- 5.What is the total count of transactions for each platform?
SELECT *
FROM clean_weekly_sales
;

SELECT platform, SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY platform
;

-- 6.What is the percentage of sales for Retail vs Shopify for each month?
SELECT *
FROM clean_weekly_sales
;

WITH platform_percentage AS
(
SELECT
	calendar_year,
    month_number,
    platform,
	SUM(sales) AS monthly_sales
FROM clean_weekly_sales
GROUP BY 
	calendar_year,
    month_number,
    platform
ORDER BY calendar_year, month_number
)
SELECT
	calendar_year,
    month_number,
    ROUND(
		MAX(CASE WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END) / SUM(monthly_sales) * 100,
    2) AS retail_percentage,
    ROUND(
		MAX(CASE WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END) / SUM(monthly_sales) * 100,
    2) AS shopify_percentage
FROM platform_percentage
GROUP BY 
	calendar_year,
    month_number
;

-- 7.What is the percentage of sales by demographic for each year in the dataset?
SELECT *
FROM clean_weekly_sales
;

WITH demographic_cte AS
(
	SELECT
		calendar_year,
        demographic,
        SUM(sales) AS total_sales
	FROM clean_weekly_sales
    GROUP BY
		calendar_year,
        demographic
)
SELECT
	calendar_year,
    ROUND(
		100 * MAX(
				CASE WHEN demographic = 'Couple' THEN total_sales 
                ELSE NULL END) / SUM(total_sales), 2) AS couple_percentage,
	ROUND(
		100 * MAX(
				CASE WHEN demographic = 'Families' THEN total_sales 
                ELSE NULL END) / SUM(total_sales), 2) AS families_percentage,
	ROUND(
		100 * MAX(
				CASE WHEN demographic = 'Unknown' THEN total_sales 
                ELSE NULL END) / SUM(total_sales), 2) AS unknown_percentage
FROM demographic_cte
GROUP BY calendar_year
ORDER BY 1
;
-- 8.Which age_band and demographic values contribute the most to Retail sales?
SELECT *
FROM clean_weekly_sales
;

SELECT
	demographic,
	age_band,
	ROUND(
		100 * SUM(sales) / SUM(SUM(sales)) OVER(), 1) AS contribution_percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY
	age_band,
    demographic
ORDER BY 3 DESC
;

-- 9.Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT *
FROM clean_weekly_sales
;

SELECT
	calendar_year,
    platform,
    ROUND(AVG(avg_transactions),0) AS avg_transactions_per_platform,
    SUM(sales) / SUM(transactions) AS avg_transactions_both
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY 1
;

	