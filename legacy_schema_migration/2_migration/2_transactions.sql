-- Create a new table for subnetworks
DROP TABLE IF EXISTS subnetworks;
CREATE TABLE subnetworks
(
    id            SMALLSERIAL PRIMARY KEY,
    subnetwork_id VARCHAR NOT NULL
);
CREATE INDEX idx_subnetworks_subnetwork_id ON subnetworks (subnetwork_id);
INSERT INTO subnetworks (subnetwork_id) SELECT DISTINCT subnetwork_id FROM transactions;


-- Create a new table for transaction/block mappings
DROP TABLE IF EXISTS blocks_transactions;
CREATE TABLE blocks_transactions
(
    block_hash     BYTEA NOT NULL,
    transaction_id BYTEA NOT NULL
);
-- Insert mappings from transactions.block_hash (~8m, ~130m rows)
INSERT INTO blocks_transactions (block_hash, transaction_id)
SELECT DECODE(bh, 'hex') AS block_hash, DECODE(t.transaction_id, 'hex') AS transaction_id
FROM transactions t CROSS JOIN LATERAL UNNEST(t.block_hash) AS bh; -- LATERAL ensures we only pair a rows txid with the rows block_hash[]
-- Create indexes afterwards (faster insert)
ALTER TABLE blocks_transactions ADD PRIMARY KEY (block_hash, transaction_id); --(~9m)
CREATE INDEX idx_blocks_transactions_block_hash ON blocks_transactions (block_hash); --(~4m)
CREATE INDEX idx_blocks_transactions_transaction_id ON blocks_transactions (transaction_id); --(~4m)


-- Create a new table for transaction/accepting block
DROP TABLE IF EXISTS transactions_acceptances;
CREATE TABLE transactions_acceptances
(
    transaction_id BYTEA NOT NULL,
    block_hash     BYTEA NOT NULL
);
-- Insert acceptance mappings from transactions.accepting_block_hash (~4m, ~61m rows)
INSERT INTO transactions_acceptances (transaction_id, block_hash)
SELECT DECODE(transaction_id, 'hex') AS transaction_id, DECODE(accepting_block_hash, 'hex') AS block_hash
FROM transactions WHERE accepting_block_hash IS NOT NULL;
-- Create indexes afterwards (faster insert)
ALTER TABLE transactions_acceptances ADD PRIMARY KEY (transaction_id); --(~3m)
CREATE INDEX IF NOT EXISTS idx_transactions_acceptances_accepting_block ON transactions_acceptances (block_hash); --(~2m)


-- Change datatypes on transactions and map subnetworks --(~10m)
DROP TABLE IF EXISTS new_transactions;
CREATE TABLE new_transactions
(
    transaction_id BYTEA,
    subnetwork_id  INTEGER,
    hash           BYTEA,
    mass           INTEGER,
    block_time     INTEGER
);
INSERT INTO new_transactions (transaction_id, subnetwork_id, hash, mass, block_time)
SELECT
    decode(t.transaction_id, 'hex') AS transaction_id,
    s.id AS subnetwork_id,
    decode(t.hash, 'hex') AS hash,
    t.mass::INTEGER AS mass,
    (t.block_time / 1000)::INTEGER AS block_time
FROM transactions t
    JOIN subnetworks s ON t.subnetwork_id = s.subnetwork_id;
-- Replace old table with new
DROP table transactions;
ALTER table new_transactions RENAME TO transactions;
-- Create primary key and index
ALTER TABLE transactions ADD PRIMARY KEY (transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_block_time ON transactions (block_time);
