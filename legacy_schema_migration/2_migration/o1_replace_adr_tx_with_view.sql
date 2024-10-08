--
--Copyright suprtypo@pm.me.
--LICENSED ONLY FOR THE PURPOSE OF INTEGRATING WITH THE KASPA CRYPTOCURRENCY NETWORK.
--

-----------------------------------------------------------
-- Optional: Replaces addresses_transactions with a view
-- - sacrifices a bit of lookup perf for faster inserts
-----------------------------------------------------------

-- Create indexes
CREATE INDEX ON transactions_outputs (script_public_key_address);
CREATE INDEX ON transactions_inputs (previous_outpoint_hash, previous_outpoint_index);

-- Rename existing table
ALTER TABLE addresses_transactions RENAME TO addresses_transactions_old;

-- Create view
CREATE OR REPLACE VIEW addresses_transactions AS
    SELECT DISTINCT adr_tx.address, t.transaction_id, t.block_time FROM (
        SELECT tout.script_public_key_address address, UNNEST(ARRAY [tout.transaction_id, tin.transaction_id]) transaction_id
            FROM transactions_outputs tout
            LEFT JOIN transactions_inputs tin ON tout.transaction_id = tin.previous_outpoint_hash AND tout.index = tin.previous_outpoint_index
    ) adr_tx
    INNER JOIN transactions t ON adr_tx.transaction_id = t.transaction_id;

-- Alternate - twice as fast (can return duplicate transaction_ids)
CREATE OR REPLACE VIEW addresses_transactions AS
    SELECT adr_tx.address, t.transaction_id, t.block_time FROM (
        SELECT tout.script_public_key_address address, UNNEST(ARRAY [tout.transaction_id, tin.transaction_id]) transaction_id
            FROM transactions_outputs tout
            LEFT JOIN transactions_inputs tin ON tout.transaction_id = tin.previous_outpoint_hash AND tout.index = tin.previous_outpoint_index
    ) adr_tx
    INNER JOIN transactions t ON adr_tx.transaction_id = t.transaction_id;

-- Alternate - even slightly faster (can return duplicate transaction_ids)
CREATE OR REPLACE VIEW addresses_transactions AS
    SELECT o.script_public_key_address address, UNNEST(ARRAY_REMOVE(ARRAY [o.transaction_id, i.transaction_id], NULL)) AS transaction_id, block_time
        FROM transactions_outputs o
        LEFT JOIN transactions_inputs i ON o.transaction_id = i.previous_outpoint_hash AND o.index = i.previous_outpoint_index
        INNER JOIN transactions t ON o.transaction_id = t.transaction_id OR i.transaction_id = t.transaction_id;
