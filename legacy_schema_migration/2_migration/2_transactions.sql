-- Create a new table for subnetworks
CREATE TABLE subnetworks
(
    id            SMALLSERIAL PRIMARY KEY,
    subnetwork_id VARCHAR NOT NULL
);
CREATE INDEX ON subnetworks (subnetwork_id);
INSERT INTO subnetworks (subnetwork_id) SELECT DISTINCT subnetwork_id FROM transactions;


-- Create a new table for transaction/block mappings
CREATE TABLE blocks_transactions
(
    block_hash     BYTEA NOT NULL,
    transaction_id BYTEA NOT NULL
) PARTITION BY RANGE (get_byte(transaction_id, 0));
CREATE INDEX ON blocks_transactions (get_byte(transaction_id, 0));

SELECT create_partition('blocks_transactions', 'blocks_transactions_p', 16);

-- Insert mappings from transactions.block_hash
INSERT INTO blocks_transactions (block_hash, transaction_id)
SELECT DECODE(bh, 'hex')               AS block_hash,
       DECODE(t.transaction_id, 'hex') AS transaction_id
FROM transactions t CROSS JOIN LATERAL UNNEST(t.block_hash) AS bh; -- LATERAL ensures we only pair a rows txid with the rows block_hash[]

-- Create constraints/indexes
SELECT partition_query('ALTER table blocks_transactions_p{part_num} ADD PRIMARY KEY (block_hash, transaction_id)', 16);
CREATE INDEX ON blocks_transactions (block_hash);
CREATE INDEX ON blocks_transactions (transaction_id);


-- Create a new table for transaction/accepting block
CREATE TABLE transactions_acceptances
(
    transaction_id BYTEA NOT NULL,
    block_hash     BYTEA NOT NULL
) PARTITION BY RANGE (get_byte(transaction_id, 0));
CREATE INDEX ON transactions_acceptances (get_byte(transaction_id, 0));

SELECT create_partition('transactions_acceptances', 'transactions_acceptances_p', 16);

-- Insert acceptance mappings from transactions.accepting_block_hash
INSERT INTO transactions_acceptances (transaction_id, block_hash)
SELECT DECODE(transaction_id, 'hex')       AS transaction_id,
       DECODE(accepting_block_hash, 'hex') AS block_hash
FROM transactions WHERE accepting_block_hash IS NOT NULL;

-- Create constraints/indexes
SELECT partition_query('ALTER table transactions_acceptances_p{part_num} ADD PRIMARY KEY (transaction_id)', 16);
CREATE INDEX ON transactions_acceptances (block_hash);


-- Convert transactions
ALTER TABLE transactions RENAME TO old_transactions;
CREATE TABLE transactions
(
    transaction_id BYTEA,
    subnetwork_id  INTEGER,
    hash           BYTEA,
    mass           INTEGER,
    block_time     BIGINT
) PARTITION BY RANGE (get_byte(transaction_id, 0));
CREATE INDEX ON transactions (get_byte(transaction_id, 0));

SELECT create_partition('transactions', 'transactions_p', 16);

INSERT INTO transactions (transaction_id, subnetwork_id, hash, mass, block_time)
SELECT decode(t.transaction_id, 'hex') AS transaction_id,
       s.id                            AS subnetwork_id,
       decode(t.hash, 'hex')           AS hash,
       t.mass::INTEGER                 AS mass,
       block_time
FROM old_transactions t
    JOIN subnetworks s ON t.subnetwork_id = s.subnetwork_id;

DROP TABLE old_transactions;

-- Create constraints/indexes
SELECT partition_query('ALTER table transactions_p{part_num} ADD PRIMARY KEY (transaction_id)', 16);
CREATE INDEX ON transactions (block_time DESC NULLS LAST);
