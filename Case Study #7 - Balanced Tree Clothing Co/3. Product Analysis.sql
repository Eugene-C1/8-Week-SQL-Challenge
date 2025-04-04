# 1. What are the top 3 products by total revenue before discount?
# 2. What is the total quantity, revenue, and discount for each segment?
# 3. What is the top-selling product for each segment?
# 4. What is the total quantity, revenue, and discount for each category?
# 5. What is the top-selling product for each category?
# 6. What is the percentage split of revenue by product for each segment?
# 7. What is the percentage split of revenue by segment for each category?
# 8. What is the percentage split of total revenue by category?
# 9. What is the total transaction “penetration” for each product? 
#    (hint: penetration = number of transactions where at least 1 quantity 
#    of a product was purchased divided by total number of transactions)
# 10. What is the most common combination of at least 1 quantity of any 
#     3 products in a single transaction?

#--------------------------------------------------------------------------
# 1. What are the top 3 products by total revenue before discount?
SELECT
	pd.product_name,
    SUM(sl.qty * sl.price) AS total_revenue
FROM balanced_tree.product_details pd
LEFT JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC 
LIMIT 3
;

# 2. What is the total quantity, revenue, and discount for each segment?
SELECT
	pd.segment_name,
    SUM(sl.qty) AS total_quantity,
    SUM(sl.qty * sl.price) AS total_revenue,
    ROUND(SUM(sl.qty * sl.price * (1 - sl.discount/100)), 2) AS net_revenue_after_discount
FROM balanced_tree.product_details pd
LEFT JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
GROUP BY pd.segment_name
;

# 3. What is the top-selling product for each segment?
WITH segment_cte AS (
	SELECT
		pd.segment_name,
        pd.product_name,
        SUM(sl.qty * sl.price) AS total_revenue_before_discount
	FROM balanced_tree.product_details pd
	INNER JOIN balanced_tree.sales sl
		ON pd.product_id = sl.prod_id
	GROUP BY 
		pd.segment_name,
		pd.product_name
	ORDER BY pd.segment_name, total_revenue_before_discount DESC
)
SELECT 
	segment_name,
    product_name,
    total_revenue_before_discount
FROM (
	SELECT *, RANK() OVER (PARTITION BY segment_name ORDER BY total_revenue_before_discount DESC) as rnk
    FROM segment_cte
) subquery
WHERE rnk = 1
;

# 4. What is the total quantity, revenue, and discount for each category?
SELECT
	*
FROM balanced_tree.product_details pd
INNER JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
;
SELECT
	pd.category_name,
	SUM(sl.qty) AS total_quantity,
	SUM(sl.qty * sl.price) AS total_revenue_before_discount,
	SUM(sl.qty * sl.price * (discount/100)) AS total_discount
FROM balanced_tree.product_details pd
INNER JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
GROUP BY pd.category_name
;

# 5. What is the top-selling product for each category?
WITH category_cte AS (
	SELECT
		pd.category_name,
        pd.product_name,
		SUM(sl.qty) AS quantity,
		SUM(sl.qty * sl.price) AS total_revenue_before_discount
	FROM balanced_tree.product_details pd
	INNER JOIN balanced_tree.sales sl
		ON pd.product_id = sl.prod_id
	GROUP BY pd.category_name, pd.product_name
    ORDER BY pd.category_name, total_revenue_before_discount DESC
)

SELECT
	category_name,
    product_name,
    quantity
    quantity
FROM (
	SELECT 
		*, RANK() OVER (PARTITION BY category_name ORDER BY total_revenue_before_discount DESC) AS rnk
	FROM category_cte
) subquery
WHERE rnk = 1
;

# 6. What is the percentage split of revenue by product for each segment?
WITH segment_cte AS (
	SELECT 
		pd.segment_name,
		pd.product_name,
		SUM(sl.qty * sl.price) AS total_revenue_before_discount
	FROM balanced_tree.product_details pd
	INNER JOIN balanced_tree.sales sl
		ON pd.product_id = sl.prod_id
	GROUP BY pd.segment_name, pd.product_name
	ORDER BY pd.segment_name, total_revenue_before_discount DESC
)
SELECT
	segment_name,
    product_name,
    total_revenue_before_discount,
    100 * (total_revenue_before_discount / SUM(total_revenue_before_discount) OVER (PARTITION BY segment_name)) AS percentage
FROM segment_cte
GROUP BY segment_name, product_name
;

# 7. What is the percentage split of revenue by segment for each category?
WITH segment_cte AS (
	SELECT 
		pd.category_name,
		pd.segment_name,
		SUM(sl.qty * sl.price) AS total_revenue_before_discount
	FROM balanced_tree.product_details pd
	INNER JOIN balanced_tree.sales sl
		ON pd.product_id = sl.prod_id
	GROUP BY pd.category_name, pd.segment_name
	ORDER BY pd.category_name, total_revenue_before_discount DESC
)
SELECT
	category_name,
    segment_name,
    total_revenue_before_discount,
    100 * (total_revenue_before_discount / SUM(total_revenue_before_discount) OVER (PARTITION BY category_name)) AS percentage
FROM segment_cte
GROUP BY segment_name, category_name
;

# 8. What is the percentage split of total revenue by category?
WITH category_cte AS (
	SELECT 
		pd.category_name,
		SUM(sl.qty * sl.price) AS total_revenue_before_discount
	FROM balanced_tree.product_details pd
	INNER JOIN balanced_tree.sales sl
		ON pd.product_id = sl.prod_id
	GROUP BY pd.category_name
	ORDER BY pd.category_name, total_revenue_before_discount DESC
)
SELECT
	category_name,
    total_revenue_before_discount,
    100 * (total_revenue_before_discount / SUM(total_revenue_before_discount) OVER ()) AS percentage
FROM category_cte
GROUP BY category_name
;

# 9. What is the total transaction “penetration” for each product? 
#    (hint: penetration = number of transactions where at least 1 quantity 
#    of a product was purchased divided by total number of transactions)

SELECT *
FROM balanced_tree.product_details pd
INNER JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
;

WITH penetration_cte AS (
	SELECT
		pd.product_id,
        pd.product_name,
        COUNT(DISTINCT sl.txn_id) as product_transaction
	FROM balanced_tree.product_details pd
	INNER JOIN balanced_tree.sales sl
		ON pd.product_id = sl.prod_id
	GROUP BY pd.product_id, pd.product_name
),
total_transactions AS (
	SELECT COUNT(DISTINCT txn_id) AS total_transaction
    FROM balanced_tree.sales
)
SELECT
	pc.product_id,
    pc.product_name,
    pc.product_transaction,
    tt.total_transaction,
    100 * (pc.product_transaction / tt.total_transaction) AS penetration
FROM penetration_cte pc
CROSS JOIN  total_transactions tt
ORDER BY penetration DESC

# 10. What is the most common combination of at least 1 quantity of any 
#     3 products in a single transaction?