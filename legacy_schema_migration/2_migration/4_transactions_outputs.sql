-- Change primary key from serial to (transaction_id, index)
DELETE FROM transactions_outputs
    WHERE id NOT IN (SELECT MIN(id) FROM transactions_outputs GROUP BY transaction_id, index);
ALTER TABLE transactions_outputs
    DROP CONSTRAINT transactions_outputs_pkey,
    DROP COLUMN id,
    ADD PRIMARY KEY (transaction_id, index);

-- Change datatypes on transactions_inputs
ALTER TABLE transactions_outputs
    ALTER COLUMN transaction_id TYPE BYTEA USING DECODE(transaction_id, 'hex'),
    ALTER COLUMN index TYPE SMALLINT USING index::SMALLINT,
    --amount stays the same
    ALTER COLUMN script_public_key TYPE BYTEA USING DECODE(script_public_key, 'hex'),
    ALTER COLUMN script_public_key_address TYPE BYTEA USING CONVERT_TO(SUBSTRING(script_public_key_address FROM 7), 'UTF8'),
    ALTER COLUMN script_public_key_type TYPE BYTEA USING CONVERT_TO(script_public_key_type, 'UTF8');

-- Rename indexes
ALTER INDEX idx_txouts RENAME TO idx_transactions_outputs_transaction_id;
ALTER INDEX idx_txouts_addr RENAME TO idx_transactions_outputs_script_public_key_address;
-- Drop index as it's now the primary key
DROP INDEX tx_id_and_index;
