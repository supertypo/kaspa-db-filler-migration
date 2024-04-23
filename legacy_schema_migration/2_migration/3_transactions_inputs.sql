-- Drop index
DROP INDEX idx_txin_prev;

-- Delete duplicates. This takes roughly 7m for the index creation and 6m for the delete
CREATE INDEX idx_transactions_inputs_on_group_keys ON transactions_inputs (transaction_id, index, id);
WITH to_keep AS (SELECT MAX(id) AS id
                 FROM transactions_inputs
                 GROUP BY transaction_id, index)
DELETE FROM transactions_inputs tx_in
WHERE NOT EXISTS (SELECT 1
                  FROM to_keep
                  WHERE id = tx_in.id); -- ~50k rows affected
DROP INDEX idx_transactions_inputs_on_group_keys;

-- Drop index
DROP INDEX idx_txinp;

-- Drop constraints and columns
ALTER TABLE transactions_inputs
    DROP CONSTRAINT transactions_inputs_pkey,
    DROP COLUMN id;

-- Update columns types
ALTER TABLE transactions_inputs
    ALTER COLUMN transaction_id TYPE BYTEA USING DECODE(transaction_id, 'hex'),
    ALTER COLUMN index TYPE SMALLINT USING index::SMALLINT,
    ALTER COLUMN previous_outpoint_hash TYPE BYTEA USING DECODE(previous_outpoint_hash, 'hex'),
    ALTER COLUMN previous_outpoint_index TYPE SMALLINT USING previous_outpoint_index::SMALLINT,
    ALTER COLUMN signature_script TYPE BYTEA USING DECODE(signature_script, 'hex'),
    ALTER COLUMN sig_op_count TYPE SMALLINT USING sig_op_count::SMALLINT;

-- Add natural primary key
ALTER TABLE transactions_inputs
    ADD PRIMARY KEY (transaction_id, index);

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_transactions_inputs_transaction_id ON transactions_inputs (transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_inputs_previous_outpoint_hash_index ON transactions_inputs (previous_outpoint_hash, previous_outpoint_index);
