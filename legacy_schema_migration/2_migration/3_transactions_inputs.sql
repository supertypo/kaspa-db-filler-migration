-- Change primary key from serial to (transaction_id, index)
DELETE FROM transactions_inputs
    WHERE id NOT IN (SELECT MIN(id) FROM transactions_inputs GROUP BY transaction_id, index);
ALTER TABLE transactions_inputs
    DROP CONSTRAINT transactions_inputs_pkey,
    DROP COLUMN id,
    ADD PRIMARY KEY (transaction_id, index);

-- Change datatypes on transactions_inputs
ALTER TABLE transactions_inputs
    ALTER COLUMN transaction_id TYPE BYTEA USING DECODE(transaction_id, 'hex'),
    ALTER COLUMN index TYPE SMALLINT USING index::SMALLINT,
    ALTER COLUMN previous_outpoint_hash TYPE BYTEA USING DECODE(previous_outpoint_hash, 'hex'),
    ALTER COLUMN previous_outpoint_index TYPE SMALLINT USING previous_outpoint_index::SMALLINT,
    ALTER COLUMN signature_script TYPE BYTEA USING DECODE(signature_script, 'hex'),
    ALTER COLUMN sig_op_count TYPE SMALLINT USING sig_op_count::SMALLINT;

-- Rename indexes
ALTER INDEX idx_txinp RENAME TO idx_transactions_inputs_transaction_id;
ALTER INDEX idx_txin_prev RENAME TO idx_transactions_inputs_previous_outpoint_hash;
