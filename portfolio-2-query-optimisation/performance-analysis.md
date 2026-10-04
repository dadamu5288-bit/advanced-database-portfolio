# Performance Analysis - TrustLink Microfinance Bank (simulated)

Database: PostgreSQL 18, `bankdb`. Data is synthetic: 50,000 customers, 80,000 accounts, 500,000 transactions, 100,000 transfers.

Method: I ran `EXPLAIN (ANALYZE, BUFFERS)` on each query with no indexes (before), created indexes, then ran it again (after). Each query was run twice and the second run was recorded, so the first-run cost of loading data from disk does not distort the result. `ANALYZE` was run after the indexes were dropped and after they were created, so the planner had current statistics.

## Results

|Query|Before (ms)|After (ms)|Change|
|-|-|-|-|
|Q1: latest transactions of account 42|178.066|0.240|about 742 times faster (99.9% less time)|
|Q2: deposits per branch, last 30 days|159.681|87.853|about 1.8 times faster (45% less time)|

## Indexes created

|Index|Definition|Aimed at|
|-|-|-|
|idx\_txn\_account\_time|transactions (account\_id, txn\_time DESC)|Q1|
|idx\_txn\_time|transactions (txn\_time)|Q2|
|idx\_accounts\_customer|accounts (customer\_id)|joins in Q2|

## Q1: why it improved so much

Before: the plan used a (Parallel) Seq Scan on `transactions`. With no index on `account\_id`, PostgreSQL had to read all 500,000 rows to find the few belonging to account 42, then sort them by time.

After: The index lets PostgreSQL jump straight to account 42's rows, and because the index also stores `txn\_time` in descending order, the rows come out already sorted. Execution time fell from 178.066 ms to 0.240 ms.

Q1 returned 7 rows, not 20, because account 42 has only 7 transactions in the generated data. LIMIT 20 is a maximum, not a guaranteed row count.

## Q2: why it improved less

Q2 reads a large share of the table: only deposits (about a quarter of rows) from the last 30 days (about 8% of the year), and it still has to join to accounts, customers and branches and add up the amounts. The index on `txn\_time` helps PostgreSQL skip the older rows, but a lot of work remains, so the gain is smaller (159.681 ms to 87.853 ms).

Trade-offs of indexing

* Indexes use extra disk space.
* Every INSERT, UPDATE or DELETE on an indexed table must also update its indexes, so writes become slightly slower. For a bank this is acceptable because reads such as statements are far more frequent than writes to any one account, but indexes should be added for real query patterns, not on every column.
* Foreign key columns such as `transactions.account\_id` are not indexed automatically in PostgreSQL, which is why Q1 was slow at first.

## Conclusion

The index designed for the exact filter and sort of Q1 gave a dramatic improvement. The broader analytical query Q2 benefited moderately. Reading the execution plan before and after is what showed me where the time was going.

