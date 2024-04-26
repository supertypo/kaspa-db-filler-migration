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
) PARTITION BY HASH (transaction_id);

SELECT create_partition('transactions_outputs', 'transactions_outputs_p', 32);
-- We need a primary key to handle duplicates:
ALTER table transactions_outputs ADD PRIMARY KEY (transaction_id, index);

INSERT INTO transactions_outputs (transaction_id, index, amount, script_public_key, script_public_key_address, script_public_key_type, block_time)
SELECT DECODE(o.transaction_id, 'hex'),
       o.index::SMALLINT,
       o.amount,
       DECODE(o.script_public_key, 'hex'),
       SUBSTRING(o.script_public_key_address FROM 7),
       o.script_public_key_type,
       t.block_time
FROM old_transactions_outputs o
         LEFT JOIN transactions t ON t.transaction_id = DECODE(o.transaction_id, 'hex')
ON CONFLICT DO NOTHING;

DROP TABLE old_transactions_outputs;

-- Create indexes
CREATE INDEX ON transactions_outputs (transaction_id);
CREATE INDEX ON transactions_outputs (script_public_key_address);
CREATE INDEX ON transactions_outputs (block_time DESC NULLS LAST);
