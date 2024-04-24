-- Convert transactions_outputs
ALTER TABLE transactions_outputs RENAME TO old_transactions_outputs;
CREATE TABLE transactions_outputs
(
    transaction_id            BYTEA    NOT NULL,
    index                     SMALLINT NOT NULL,
    amount                    BIGINT   NOT NULL,
    script_public_key         BYTEA    NOT NULL,
    script_public_key_address VARCHAR  NOT NULL,
    script_public_key_type    VARCHAR  NOT NULL,
    block_time                BIGINT   NOT NULL
) PARTITION BY RANGE (get_byte(transaction_id, 0));
CREATE INDEX ON transactions_outputs (get_byte(transaction_id, 0));

SELECT create_partition('transactions_outputs', 'transactions_outputs_p', 16);
-- We need a primary key to handle duplicates:
SELECT partition_query('ALTER table transactions_outputs_p{part_num} ADD PRIMARY KEY (transaction_id, index)', 16);

INSERT INTO transactions_outputs (transaction_id, index, amount, script_public_key, script_public_key_address, script_public_key_type, block_time)
SELECT DECODE(o.transaction_id, 'hex'),
       o.index::SMALLINT,
       o.amount,
       DECODE(o.script_public_key, 'hex'),
       SUBSTRING(o.script_public_key_address FROM 7),
       o.script_public_key_type,
       0 -- Will andle it later
FROM old_transactions_outputs o
ON CONFLICT DO NOTHING;

DROP TABLE old_transactions_outputs;

-- Create indexes
CREATE INDEX ON transactions_outputs (transaction_id);
CREATE INDEX ON transactions_outputs (script_public_key_address);

-- Populate block_time with values from transactions
UPDATE transactions_outputs o SET block_time = t.block_time
FROM transactions t
WHERE t.transaction_id = o.transaction_id;

-- Create indexes
CREATE INDEX ON transactions (block_time DESC NULLS LAST);
