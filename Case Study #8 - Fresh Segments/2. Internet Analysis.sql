# 1. Which interests have been present in all month_year dates in our dataset?
#    - Identify interest_id values that appear in every distinct month_year.
#    - This shows which interests are consistently active across the entire time range.
# 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months.
#    - Count how many interest_id values exist for each total_months value.
#    - Order them descending, and calculate cumulative percentage of total records.
#    - Find the smallest total_months value where cumulative percentage passes 90%.
# 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
#    - Count the number of records (rows) that belong to interest_ids with total_months less than that cutoff.
#    - This shows the impact in terms of data volume.
# 4. Does this decision make sense to remove these data points from a business perspective?
#    - Use a comparison example:
#      > Interest A appears in all 14 months = consistently engaged segment.
#      > Interest B appears in only 2 months = sporadic or one-time interest.
#    - Removing low-month-count interests reduces noise, short-term spikes, or test segments.
#    - Retaining high-month-count interests focuses on long-term, stable trends, useful for personalization or prediction.
# 5. After removing these interests - how many unique interests are there for each month?
#    - Re-calculate distinct interest_id values per month_year after the filter.
#    - Shows how segment diversity changes post-cleaning.

#-----------------------------------------------------------------------------------------------------------------------------

# 1. Which interests have been present in all month_year dates in our dataset?
#    - Identify interest_id values that appear in every distinct month_year.
#    - This shows which interests are consistently active across the entire time range.
SELECT 
	COUNT(DISTINCT month_year) AS unique_month_year,
    COUNT(DISTINCT interest_id) AS unique_interest_id
FROM fresh_segments.interest_metrics
;

WITH month_cte AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS total_months
	FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
)
SELECT
	c.total_months,
    COUNT(DISTINCT c.interest_id) AS unique_interest_id
FROM month_cte c
WHERE total_months = 14
GROUP BY c.total_months
ORDER BY unique_interest_id DESC
;

# 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months.
#    - Count how many interest_id values exist for each total_months value.
#    - Order them descending, and calculate cumulative percentage of total records.
#    - Find the smallest total_months value where cumulative percentage passes 90%.
WITH month_cte AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS total_months
	FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
),
count_cte AS (
	SELECT
		total_months,
        COUNT(DISTINCT interest_id) AS interest_count
	FROM month_cte
    GROUP BY total_months
)
SELECT
	total_months,
    interest_count,
    ROUND(100 * SUM(interest_count) OVER (ORDER BY total_months DESC) /
		(SUM(interest_count) OVER ()), 2) AS cumulative_percentage
FROM count_cte
;

# 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
#    - Count the number of records (rows) that belong to interest_ids with total_months less than that cutoff.
#    - This shows the impact in terms of data volume.
WITH month_cte AS (
	SELECT
		interest_id,
		COUNT(DISTINCT month_year) AS total_months
	FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
)
SELECT
	total_months,
    COUNT(DISTINCT interest_id) AS total_interest_id
FROM month_cte
WHERE total_months = 14
;

# 4. Does this decision make sense to remove these data points from a business perspective?
#    - Use a comparison example:
#      > Interest A appears in all 14 months = consistently engaged segment.
#      > Interest B appears in only 2 months = sporadic or one-time interest.
#    - Removing low-month-count interests reduces noise, short-term spikes, or test segments.
#    - Retaining high-month-count interests focuses on long-term, stable trends, useful for personalization or prediction.

WITH month_cte AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
)
SELECT
    total_months,
    COUNT(DISTINCT interest_id) AS total_interest_id
FROM month_cte
WHERE total_months = 14 OR total_months = 2
GROUP BY total_months
ORDER BY total_months DESC;


