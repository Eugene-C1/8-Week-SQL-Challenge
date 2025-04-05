# Data Exploration and Cleansing
# 1. Update the fresh_segments.interest_metrics table by modifying the month_year column 
#    to be a DATE data type with the start of the month.
# 2. Count the number of records in fresh_segments.interest_metrics for each month_year value, 
#    sorted in chronological order (earliest to latest), with NULL values appearing first.
# 3. Analyze what should be done with NULL values in the month_year column of 
#    fresh_segments.interest_metrics.
# 4. Find how many interest_id values exist in fresh_segments.interest_metrics 
#    but not in fresh_segments.interest_map. Then, check the reverse: 
#    how many exist in fresh_segments.interest_map but not in fresh_segments.interest_metrics.
# 5. Summarize the id values in fresh_segments.interest_map by their total record count.
# 6. Determine the appropriate type of table join for analysis and explain why. 
#    Verify the logic by checking the rows where interest_id = 21246 in the joined output. 
#    Include all columns from fresh_segments.interest_metrics and all columns from 
#    fresh_segments.interest_map except for the id column.
# 7. Identify any records in the joined table where the month_year value is before the created_at 
#    value from fresh_segments.interest_map. Determine if these values are valid and explain why.

#---------------------------------------------------------------------------------------

# 1. Update the fresh_segments.interest_metrics table by modifying the month_year column 
#    to be a DATE data type with the start of the month.
SELECT *
FROM fresh_segments.interest_metrics
;

ALTER TABLE fresh_segments.interest_metrics 
ADD COLUMN new_month_year DATE;

UPDATE fresh_segments.interest_metrics
SET new_month_year = STR_TO_DATE(CONCAT('01-', month_year), '%d-%m-%Y');

ALTER TABLE fresh_segments.interest_metrics
DROP COLUMN month_year,
CHANGE COLUMN new_month_year month_year DATE;

# 2. Count the number of records in fresh_segments.interest_metrics for each month_year value, 
#    sorted in chronological order (earliest to latest), with NULL values appearing first.
SELECT 
	month_year,
	COUNT(interest_id) AS total_records
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year ASC
;

# 3. Analyze what should be done with NULL values in the month_year column of 
#    fresh_segments.interest_metrics.

# Since there's only one null value in month_year and one record in that month_year,
# we can just remove the row.

DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;

# 4. Find how many interest_id values exist in fresh_segments.interest_metrics 
#    but not in fresh_segments.interest_map. Then, check the reverse: 
#    how many exist in fresh_segments.interest_map but not in fresh_segments.interest_metrics.
SELECT
	COUNT(DISTINCT imp.id) AS interest_map_count,
    COUNT(DISTINCT imt.interest_id) AS interest_metrics_count,
     
	(SELECT COUNT(DISTINCT metrics.interest_id)
	  FROM fresh_segments.interest_metrics metrics
	  LEFT JOIN fresh_segments.interest_map map ON map.id = metrics.interest_id
	  WHERE map.id IS NULL) AS not_in_map,
	  
	(SELECT COUNT(DISTINCT map.id)
	 FROM fresh_segments.interest_map map
	 LEFT JOIN fresh_segments.interest_metrics metrics ON map.id = metrics.interest_id
	 WHERE metrics.interest_id IS NULL) AS not_in_metric
     
FROM fresh_segments.interest_map imp
LEFT JOIN fresh_segments.interest_metrics imt
	ON imp.id = imt.interest_id
;

# 5. Summarize the id values in fresh_segments.interest_map by their total record count.
SELECT
	COUNT(DISTINCT id) AS interest_map_total_record
FROM fresh_segments.interest_map
;

# 6. Determine the appropriate type of table join for analysis and explain why. 
#    Verify the logic by checking the rows where interest_id = 21246 in the joined output. 
#    Include all columns from fresh_segments.interest_metrics and all columns from 
#    fresh_segments.interest_map except for the id column.
SELECT 
	*
FROM fresh_segments.interest_map map
INNER JOIN fresh_segments.interest_metrics metrics
	ON map.id = metrics.interest_id
WHERE metrics.interest_id = 21246
;

# 7. Identify any records in the joined table where the month_year value is before the created_at 
#    value from fresh_segments.interest_map. Determine if these values are valid and explain why.

# Answer: They are created in the same month but not the same day because of the alteration made
# in month_year which defaulted to first day of the month. This is considered valid since the
# original data never indicated the day when it was created.

SELECT 
	*
FROM fresh_segments.interest_map map
INNER JOIN fresh_segments.interest_metrics metrics
	ON map.id = metrics.interest_id
WHERE map.created_at < metrics.month_year
;

