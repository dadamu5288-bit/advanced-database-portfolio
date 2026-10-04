-- TrustLink Microfinance Bank (simulated) - Portfolio 3
-- A safe fund transfer: either everything happens, or nothing does.

CREATE OR REPLACE PROCEDURE transfer_funds(p_from BIGINT, p_to BIGINT, p_amount NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
  v_balance NUMERIC;
  v_ref     TEXT := gen_random_uuid()::text;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  -- Lock both accounts, lowest id first (stops two transfers deadlocking each other)
  PERFORM 1 FROM accounts
  WHERE account_id IN (p_from, p_to)
  ORDER BY account_id
  FOR UPDATE;

  SELECT balance INTO v_balance FROM accounts WHERE account_id = p_from;

  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient funds in account %', p_from;
  END IF;

  UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from;
  UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to;

  INSERT INTO transactions (account_id, txn_type, amount, reference)
  VALUES (p_from, 'TRANSFER_OUT', p_amount, 'TRF-OUT-' || v_ref),
         (p_to,   'TRANSFER_IN',  p_amount, 'TRF-IN-'  || v_ref);

  INSERT INTO transfers (from_account, to_account, amount, status)
  VALUES (p_from, p_to, p_amount, 'COMPLETED');
END $$;
