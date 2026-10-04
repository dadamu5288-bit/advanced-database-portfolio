-- TrustLink Microfinance Bank (simulated) - Portfolio 3: Transactions and Concurrency
-- Run each numbered block separately in the pgAdmin Query Tool (highlight, then F5).
-- Requires: schema.sql, seed_data.sql and transfer_procedure.sql already run on bankdb.

-- =====================================================
-- Setup: reset two test accounts
-- =====================================================
UPDATE accounts SET balance = 50000 WHERE account_id IN (1,2);
SELECT account_id, balance FROM accounts WHERE account_id IN (1,2) ORDER BY account_id;
-- Expected: both accounts at 50000.00


-- =====================================================
-- Demo 1: successful transfer (COMMIT)
-- =====================================================

-- 1A. Start the transfer (not saved yet)
BEGIN;
CALL transfer_funds(1, 2, 10000);
SELECT account_id, balance FROM accounts WHERE account_id IN (1,2) ORDER BY account_id;
-- Expected: account 1 = 40000.00, account 2 = 60000.00 (inside the transaction)

-- 1B. Save it
COMMIT;

-- 1C. Prove it was saved
SELECT account_id, balance FROM accounts WHERE account_id IN (1,2) ORDER BY account_id;

SELECT txn_id, account_id, txn_type, amount, reference
FROM transactions
ORDER BY txn_id DESC
LIMIT 2;
-- Expected: one TRANSFER_OUT (account 1) and one TRANSFER_IN (account 2)

SELECT * FROM transfers ORDER BY transfer_id DESC LIMIT 1;
-- Expected: status = COMPLETED


-- =====================================================
-- Demo 2: failed transfer (ROLLBACK)
-- =====================================================

-- 2A. Check the starting balances
SELECT account_id, balance FROM accounts WHERE account_id IN (1,2) ORDER BY account_id;
-- Expected: 40000.00 and 60000.00

-- 2B. Try to send more money than the account has
BEGIN;
CALL transfer_funds(1, 2, 999999999);
-- Expected: ERROR: Insufficient funds in account 1

-- 2C. Undo everything
ROLLBACK;

SELECT account_id, balance FROM accounts WHERE account_id IN (1,2) ORDER BY account_id;
-- Expected: balances unchanged (40000.00 and 60000.00)


-- =====================================================
-- Demo 2 (manual): change a balance, then ROLLBACK
-- =====================================================
BEGIN;
UPDATE accounts SET balance = 0 WHERE account_id = 1;
SELECT account_id, balance FROM accounts WHERE account_id = 1;
-- Expected: 0.00 (inside the transaction only)

ROLLBACK;
SELECT account_id, balance FROM accounts WHERE account_id = 1;
-- Expected: back to 40000.00


-- =====================================================
-- Concurrency demos (Demo 3 onward) will be added below
-- =====================================================
