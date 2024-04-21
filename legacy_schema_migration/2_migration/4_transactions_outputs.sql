-- Delete duplicates. This takes roughly 13m for the index creation and 8m for the delete
CREATE INDEX idx_transactions_outputs_on_group_keys ON transactions_outputs(transaction_id, index, id);
WITH to_keep AS (SELECT MAX(id) AS id
                 FROM transactions_outputs
                 GROUP BY transaction_id, index)
DELETE FROM transactions_outputs tx_out
WHERE NOT EXISTS (SELECT 1
                  FROM to_keep
                  WHERE id = tx_out.id); -- 2k rows affected
DROP INDEX idx_transactions_outputs_on_group_keys;

-- Change primary key from serial to (transaction_id, index)
ALTER TABLE transactions_outputs
    DROP CONSTRAINT transactions_outputs_pkey,
    DROP COLUMN id,
    ADD PRIMARY KEY (transaction_id, index),
    -- Change datatypes on transactions_inputs
    ALTER COLUMN transaction_id TYPE BYTEA USING DECODE(transaction_id, 'hex'),
    ALTER COLUMN index TYPE SMALLINT USING index::SMALLINT,
    --amount stays the same
    ALTER COLUMN script_public_key TYPE BYTEA USING DECODE(script_public_key, 'hex'),
    ALTER COLUMN script_public_key_address TYPE VARCHAR USING SUBSTRING(script_public_key_address FROM 7); --it's already VARCHAR, but this saves another full table scan
    --script_public_key_type stays the same

-- Rename indexes
ALTER INDEX idx_txouts RENAME TO idx_transactions_outputs_transaction_id;
ALTER INDEX idx_txouts_addr RENAME TO idx_transactions_outputs_script_public_key_address;
-- Drop index as it's now the primary key
DROP INDEX tx_id_and_index;
