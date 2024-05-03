-- Convert transactions_inputs
ALTER TABLE transactions_inputs RENAME TO old_transactions_inputs;
CREATE TABLE transactions_inputs
(
    transaction_id          BYTEA    NOT NULL,
    index                   SMALLINT NOT NULL,
    previous_outpoint_hash  BYTEA    NOT NULL,
    previous_outpoint_index SMALLINT NOT NULL,
    signature_script        BYTEA    NOT NULL,
    sig_op_count            SMALLINT NOT NULL
);

-- We need a primary key to handle duplicates:
ALTER table transactions_inputs ADD PRIMARY KEY (transaction_id, index);

INSERT INTO transactions_inputs (transaction_id, index, previous_outpoint_hash, previous_outpoint_index, signature_script, sig_op_count)
SELECT DECODE(transaction_id, 'hex'),
       index::SMALLINT,
       DECODE(previous_outpoint_hash, 'hex'),
       previous_outpoint_index::SMALLINT,
       DECODE(signature_script, 'hex'),
       sig_op_count::SMALLINT
FROM old_transactions_inputs
ON CONFLICT DO NOTHING;

DROP TABLE old_transactions_inputs;

-- Create indexes
CREATE INDEX ON transactions_inputs (transaction_id);
