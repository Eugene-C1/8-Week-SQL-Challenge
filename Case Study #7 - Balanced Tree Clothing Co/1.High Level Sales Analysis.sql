#1. What was the total quantity sold for all products?
#2. What is the total generated revenue for all products before discounts?
#3. What was the total discount amount for all products?

# -----------------------------------------------------------------------------
#1. What was the total quantity sold for all products?
SELECT
    pd.product_name, 
    SUM(sl.qty) AS total_quantity
FROM balanced_tree.product_details pd
LEFT JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
GROUP BY pd.product_name
;

#2. What is the total generated revenue for all products before discounts?
SELECT 
	pd.product_name,
    SUM(sl.qty) * SUM(sl.price) AS total_revenue
FROM balanced_tree.product_details pd
LEFT JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
GROUP BY pd.product_name
ORDER BY total_revenue DESC
;

#3. What was the total discount amount for all products?
SELECT 
	pd.product_name,
    ROUND(SUM(sl.qty * sl.price * sl.discount/100), 2) AS total_discount
FROM balanced_tree.product_details pd
LEFT JOIN balanced_tree.sales sl
	ON pd.product_id = sl.prod_id
GROUP BY pd.product_name
ORDER BY total_discount DESC
;
