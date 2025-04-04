# 1. Count the number of unique transactions
# 2. Calculate the average number of unique products purchased per transaction
# 3. Get the 25th, 50th, and 75th percentile values for revenue per transaction
# 4. Calculate the average discount value per transaction
# 5. Calculate the percentage split of transactions for members vs. non-members
# 6. Calculate the average revenue for member vs. non-member transactions

#-----------------------------------------------------------------------------------

# 1. Count the number of unique transactions
SELECT COUNT(DISTINCT txn_id) AS total_transactions
FROM balanced_tree.sales
;

# 2. Calculate the average number of unique products purchased per transaction
SELECT ROUND(AVG(transaction_quantities.total_qty), 0) AS avg_unique_products
FROM (
	SELECT 
		txn_id,
        SUM(qty) AS total_qty
    FROM balanced_tree.sales
    GROUP BY txn_id
) AS transaction_quantities
;

# 3. Get the 25th, 50th, and 75th percentile values for revenue per transaction
WITH revenue_cte AS (
	SELECT 
		txn_id,
        SUM(qty * price * (1 - discount / 100)) AS net_revenue
	FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT
    percentile,
    AVG(net_revenue) AS percentile_value
FROM (
	SELECT 
		net_revenue,
        NTILE(4) OVER (ORDER BY net_revenue) AS percentile
	FROM revenue_cte
) subquery
WHERE percentile IN (1, 2, 3)
GROUP BY percentile
;

# 4. Calculate the average discount value per transaction
SELECT
    AVG(discount_value) AS avg_discount
FROM (
	SELECT
		txn_id,
        (SUM(qty * price * discount/100)) AS discount_value
    FROM balanced_tree.sales
    GROUP BY txn_id
) subquery
;

# 5. Calculate the percentage split of transactions for members vs. non-members
SELECT *
FROM balanced_tree.sales;

WITH transaction_cte AS (
	SELECT 
		member,
        COUNT(DISTINCT txn_id) AS  unique_transactions
	FROM balanced_tree.sales
    GROUP BY member
)
SELECT
	member,
    unique_transactions,
    ROUND(
		100 * unique_transactions /(SELECT SUM(unique_transactions) FROM transaction_cte)
    ) AS percentile
FROM transaction_cte
GROUP BY member
;

# 6. Calculate the average revenue for member vs. non-member transactions
SELECT *
FROM balanced_tree.sales;

WITH transaction_cte AS (
	SELECT
		member,
        txn_id,
        SUM(qty * price) as total_revenue
    FROM balanced_tree.sales
    GROUP BY member, txn_id
)
SELECT
	member,
    AVG(total_revenue) AS avg_revenue
FROM transaction_cte
GROUP BY member
;
