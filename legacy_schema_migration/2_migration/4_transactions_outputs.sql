-- Convert transactions_outputs
ALTER TABLE transactions_outputs RENAME TO old_transactions_outputs;
CREATE TABLE transactions_outputs
(
    transaction_id            BYTEA    NOT NULL,
    index                     SMALLINT NOT NULL,
    amount                    BIGINT   NOT NULL,
    script_public_key         BYTEA    NOT NULL,
    script_public_key_address VARCHAR  NOT NULL
);

-- We need a primary key to handle duplicates:
ALTER table transactions_outputs ADD PRIMARY KEY (transaction_id, index);

INSERT INTO transactions_outputs (transaction_id, index, amount, script_public_key, script_public_key_address)
SELECT DECODE(o.transaction_id, 'hex'),
       o.index::SMALLINT,
       o.amount,
       DECODE(o.script_public_key, 'hex'),
       SUBSTRING(o.script_public_key_address FROM 7)
FROM old_transactions_outputs o
ON CONFLICT DO NOTHING;

DROP TABLE old_transactions_outputs;

-- Create indexes
CREATE INDEX ON transactions_outputs (transaction_id);
CREATE INDEX ON transactions_outputs (script_public_key_address);
