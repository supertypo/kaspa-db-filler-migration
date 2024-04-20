-- Create a new table for subnetworks
DROP TABLE IF EXISTS subnetworks;
CREATE TABLE subnetworks
(
    id            SERIAL PRIMARY KEY,
    subnetwork_id VARCHAR(40) NOT NULL
);
INSERT INTO subnetworks (subnetwork_id) SELECT DISTINCT subnetwork_id FROM transactions;


-- Create a new table for transaction/block mappings
DROP TABLE IF EXISTS blocks_transactions;
CREATE TABLE blocks_transactions
(
    block_hash     BYTEA NOT NULL,
    transaction_id BYTEA NOT NULL,
    CONSTRAINT pk_blocks_transactions PRIMARY KEY (block_hash, transaction_id)
);
-- Insert mappings from transactions.block_hash
INSERT INTO blocks_transactions (block_hash, transaction_id)
SELECT DECODE(bh, 'hex') AS block_hash, DECODE(transaction_id, 'hex') AS transaction_id
FROM transactions, UNNEST(block_hash) AS bh;
-- Create indexes
CREATE INDEX idx_blocks_transactions_block_hash ON blocks_transactions (block_hash);
CREATE INDEX idx_blocks_transactions_transaction_id ON blocks_transactions (transaction_id);


-- Create a new table for transaction/accepting block
DROP TABLE IF EXISTS transactions_acceptances;
CREATE TABLE transactions_acceptances
(
    transaction_id BYTEA PRIMARY KEY,
    block_hash     BYTEA NOT NULL
);
-- Insert acceptance mappings from transactions.accepting_block_hash
INSERT INTO transactions_acceptances (transaction_id, block_hash)
SELECT DECODE(transaction_id, 'hex') AS transaction_id,
       DECODE(accepting_block_hash, 'hex') AS block_hash
FROM transactions WHERE  accepting_block_hash IS NOT NULL;
-- Create index
CREATE INDEX IF NOT EXISTS idx_transactions_acceptances_accepting_block ON transactions_acceptances (block_hash);


-- Change datatypes on transactions
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
UPDATE transactions SET subnetwork_id = subnetworks.id FROM subnetworks
    WHERE transactions.subnetwork_id_old = subnetworks.subnetwork_id;
ALTER TABLE transactions DROP COLUMN subnetwork_id_old;

-- Rename index
ALTER INDEX block_time_idx RENAME TO idx_transactions_block_time;
