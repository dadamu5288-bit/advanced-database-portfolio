-- TrustLink Microfinance Bank (simulated) - Portfolio 2 queries
-- Run ONE query at a time: highlight it, then press F5.

-- Q1: Statement - the 20 latest transactions of one account
SELECT * FROM transactions
WHERE account_id = 42
ORDER BY txn_time DESC
LIMIT 20;

-- Q2: Total deposits per branch in the last 30 days (3 JOINs + GROUP BY)
SELECT b.branch_name, SUM(t.amount) AS total_deposits
FROM transactions t
JOIN accounts a  ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
JOIN branches b  ON b.branch_id = c.branch_id
WHERE t.txn_type = 'DEPOSIT'
  AND t.txn_time > NOW() - INTERVAL '30 days'
GROUP BY b.branch_name
ORDER BY total_deposits DESC;

-- Q3: Customers with more than one account (GROUP BY + HAVING)
SELECT customer_id, COUNT(*) AS num_accounts
FROM accounts
GROUP BY customer_id
HAVING COUNT(*) > 1
LIMIT 20;

-- Q4: Accounts with above-average balance (subquery)
SELECT account_id, balance
FROM accounts
WHERE balance > (SELECT AVG(balance) FROM accounts)
LIMIT 20;

-- Q5: Failed transfers per day (aggregation by date)
SELECT created_at::date AS day, COUNT(*) AS failed_transfers
FROM transfers
WHERE status = 'FAILED'
GROUP BY day
ORDER BY day DESC
LIMIT 10;
