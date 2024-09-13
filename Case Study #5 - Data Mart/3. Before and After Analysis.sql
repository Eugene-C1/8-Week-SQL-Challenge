/*
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

*/

-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
SELECT *
FROM clean_weekly_sales
;

SELECT DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15' 
  AND calendar_year = '2020';
  
WITH date_cte AS
(
	SELECT
		week_date,
        week_number,
        SUM(sales) AS total_sales
	FROM clean_weekly_sales
    WHERE (week_number BETWEEN 20 AND 27) AND calendar_year = 2020
    GROUP BY 
		week_date,
        week_number
),
sales_cte AS
(
	SELECT
		SUM(CASE WHEN week_number BETWEEN 20 AND 23 THEN total_sales ELSE NULL END) AS before_sales,
		SUM(CASE WHEN week_number BETWEEN 24 AND 27 THEN total_sales ELSE NULL END) AS after_sales
    FROM date_cte
)
SELECT
	after_sales - before_sales AS sales_variance,
    ROUND(100 *
		(after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM sales_cte
;

-- 2. What about the entire 12 weeks before and after?
SELECT *
FROM clean_weekly_sales
;

WITH date_cte AS
(
	SELECT
		week_date,
        week_number,
        SUM(sales) AS total_sales
	FROM clean_weekly_sales
    WHERE (week_number BETWEEN 12 AND 35) AND calendar_year = 2020
    GROUP BY 
		week_date,
        week_number
),
sales_cte AS
(
	SELECT
		SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN total_sales ELSE NULL END) AS before_sales,
		SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN total_sales ELSE NULL END) AS after_sales
    FROM date_cte
)
SELECT
	after_sales - before_sales AS sales_variance,
    ROUND(100 *
		(after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM sales_cte
;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
WITH date_cte AS
(
	SELECT
		calendar_year,
        week_number,
        SUM(sales) AS total_sales
	FROM clean_weekly_sales
    WHERE week_number BETWEEN 20 AND 27
    GROUP BY 
		calendar_year,
        week_number
),
sales_cte AS
(
	SELECT
		calendar_year,
		SUM(CASE WHEN week_number BETWEEN 20 AND 23 THEN total_sales ELSE NULL END) AS before_sales,
		SUM(CASE WHEN week_number BETWEEN 24 AND 27 THEN total_sales ELSE NULL END) AS after_sales
    FROM date_cte
    GROUP BY calendar_year
)
SELECT
	calendar_year,
	after_sales - before_sales AS sales_variance,
    ROUND(100 *
		(after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM sales_cte
GROUP BY calendar_year
ORDER BY 1
;

WITH date_cte AS
(
	SELECT
		calendar_year,
        week_number,
        SUM(sales) AS total_sales
	FROM clean_weekly_sales
    WHERE week_number BETWEEN 12 AND 35
    GROUP BY 
		calendar_year,
        week_number
),
sales_cte AS
(
	SELECT
		calendar_year,
		SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN total_sales ELSE NULL END) AS before_sales,
		SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN total_sales ELSE NULL END) AS after_sales
    FROM date_cte
    GROUP BY calendar_year
)
SELECT
	calendar_year,
	after_sales - before_sales AS sales_variance,
    ROUND(100 *
		(after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM sales_cte
GROUP BY calendar_year
ORDER BY 1
;


