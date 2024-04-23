-- Drop index
DROP INDEX idx_txouts_addr;

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

-- Drop remaining indexes
DROP INDEX idx_txouts;
DROP INDEX tx_id_and_index;

-- Drop constraints and columns
ALTER TABLE transactions_outputs
    DROP CONSTRAINT transactions_outputs_pkey,
    DROP COLUMN id,
    DROP COLUMN accepting_block_hash;

-- Update columns types
ALTER TABLE transactions_outputs
    -- Change datatypes
    ALTER COLUMN transaction_id TYPE BYTEA USING DECODE(transaction_id, 'hex'),
    ALTER COLUMN index TYPE SMALLINT USING index::SMALLINT,
    --amount stays the same
    ALTER COLUMN script_public_key TYPE BYTEA USING DECODE(script_public_key, 'hex'),
    ALTER COLUMN script_public_key_address TYPE VARCHAR USING SUBSTRING(script_public_key_address FROM 7); --it's already VARCHAR, but this saves another full table scan
    --script_public_key_type stays the same

-- Add new column block_time
ALTER TABLE transactions_outputs
    ADD COLUMN block_time INTEGER;
-- Populate it with values from transactions
UPDATE transactions_outputs o SET block_time = t.block_time
    FROM transactions t
    WHERE t.transaction_id = o.transaction_id;

-- Add natural primary key
ALTER TABLE transactions_outputs
    ADD PRIMARY KEY (transaction_id, index);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_outputs_transaction_id ON transactions_outputs (transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_outputs_script_public_key_address ON transactions_outputs (script_public_key_address);
CREATE INDEX IF NOT EXISTS idx_transactions_outputs_block_time ON transactions (block_time DESC NULLS LAST);
