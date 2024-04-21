-- Create a new table for subnetworks
DROP TABLE IF EXISTS subnetworks;
CREATE TABLE subnetworks
(
    id            SERIAL PRIMARY KEY,
    subnetwork_id VARCHAR NOT NULL
);
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

-- Change datatypes on transactions --(~10m)
ALTER TABLE transactions
    ALTER COLUMN transaction_id TYPE BYTEA USING DECODE(transaction_id, 'hex'),
    ALTER COLUMN hash TYPE BYTEA USING DECODE(hash, 'hex'),
    ALTER COLUMN mass TYPE INTEGER USING mass::INTEGER,
    DROP COLUMN block_hash,
    ALTER COLUMN block_time TYPE INTEGER USING block_time / 1000,
    DROP COLUMN is_accepted,
    DROP COLUMN accepting_block_hash;

-- Move in the mapped subnetworks
ALTER TABLE transactions RENAME COLUMN subnetwork_id TO subnetwork_id_old;
ALTER TABLE transactions ADD COLUMN subnetwork_id INT;
UPDATE transactions SET subnetwork_id = subnetworks.id FROM subnetworks --(140m+)
    WHERE transactions.subnetwork_id_old = subnetworks.subnetwork_id;
ALTER TABLE transactions DROP COLUMN subnetwork_id_old;

-- Rename index
ALTER INDEX block_time_idx RENAME TO idx_transactions_block_time;
