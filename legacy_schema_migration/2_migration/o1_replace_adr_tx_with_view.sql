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
CREATE INDEX ON transactions_inputs (previous_outpoint_hash);

-- Drop existing table
DROP TABLE IF EXISTS addresses_transactions;

-- Create view
CREATE OR REPLACE VIEW addresses_transactions AS
SELECT o.script_public_key_address address, t.transaction_id as transaction_id, block_time
FROM transactions t
         LEFT JOIN transactions_outputs o ON t.transaction_id = o.transaction_id
         LEFT JOIN transactions_inputs i ON o.transaction_id = i.previous_outpoint_hash AND o.index = i.previous_outpoint_index;
