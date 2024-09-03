-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
-- 2. What is the average total historical deposit counts and amounts for all customers?
-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- 4. What is the closing balance for each customer at the end of the month?
-- 5. What is the percentage of customers who increase their closing balance by more than 5%?


-- Answers:
-- 1. What is the unique count and total amount for each transaction type?
SELECT 
	txn_type,
    COUNT(txn_type) AS total_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH Deposits_CTE AS
(
SELECT
	customer_id,
    COUNT(txn_type) AS total_count,
    AVG(txn_amount) AS avg_amount
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT 
	ROUND(AVG(total_count)) AS avg_count,
    ROUND(AVG(avg_amount)) AS avg_amount
FROM Deposits_CTE
;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH Summary_CTE AS
(
SELECT
	customer_id,
    MONTH(txn_date) AS month_number,
    MONTHNAME(txn_date) AS month_name,
    SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
FROM customer_transactions
GROUP BY customer_id, month_number, month_name
)
SELECT
	month_number,
    month_name,
    SUM(CASE WHEN deposit_count = 1 AND (purchase_count = 1 OR withdrawal_count = 1) THEN 1
			ELSE 0 END) AS total_count
FROM Summary_CTE
GROUP BY month_number, month_name
;

-- 4. What is the closing balance for each customer at the end of the month?
WITH Balance_CTE AS
(
SELECT
	customer_id,
    LAST_DAY(txn_date) AS end_of_month,
    SUM(txn_amount) AS current_balance
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id, end_of_month
ORDER BY 1
),
Purchase_Withdrawal_CTE AS
(
SELECT
	customer_id,
    LAST_DAY(txn_date) AS end_of_month,
    SUM(txn_amount) AS current_balance
FROM customer_transactions
WHERE txn_type = 'purchase' OR txn_type = 'withdrawal'
GROUP BY customer_id, end_of_month
ORDER BY 1
)
SELECT
	bal.customer_id,
    bal.end_of_month,
	COALESCE(bal.current_balance, 0) - COALESCE(pur.current_balance, 0) AS current_balance
FROM Balance_CTE bal
LEFT JOIN Purchase_Withdrawal_CTE pur
	ON bal.customer_id = pur.customer_id
    AND bal.end_of_month = pur.end_of_month
ORDER BY bal.customer_id, bal.end_of_month
;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH Balance_CTE AS
(
    SELECT
        customer_id,
        LAST_DAY(txn_date) AS end_of_month,
        SUM(txn_amount) AS current_balance
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id, end_of_month
),
Purchase_Withdrawal_CTE AS
(
    SELECT
        customer_id,
        LAST_DAY(txn_date) AS end_of_month,
        SUM(txn_amount) AS current_balance
    FROM customer_transactions
    WHERE txn_type = 'purchase' OR txn_type = 'withdrawal'
    GROUP BY customer_id, end_of_month
),
Combined_CTE AS
(
    SELECT
        bal.customer_id,
        bal.end_of_month,
        bal.current_balance - COALESCE(pur.current_balance, 0) AS closing_balance
    FROM Balance_CTE bal
    LEFT JOIN Purchase_Withdrawal_CTE pur
        ON bal.customer_id = pur.customer_id
        AND bal.end_of_month = pur.end_of_month
),
Percentage_Increase_CTE AS
(
    SELECT
        customer_id,
        (closing_balance - LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY end_of_month)) / LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY end_of_month) * 100 AS percentage_increase
    FROM Combined_CTE
)
SELECT
    (COUNT(CASE WHEN percentage_increase > 5 THEN 1 END) / COUNT(*)) * 100 AS percentage_increase_over_5
FROM Percentage_Increase_CTE;




