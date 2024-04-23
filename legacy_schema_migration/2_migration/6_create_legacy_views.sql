CREATE OR REPLACE VIEW v_legacy_blocks AS
SELECT b.hash,
       b.accepted_id_merkle_root,
       b.difficulty,
       EXISTS(SELECT 1 FROM chain_blocks cb WHERE cb.block_hash = b.hash) AS is_chain_block,
       b.merge_set_blues_hashes,
       b.merge_set_reds_hashes,
       b.selected_parent_hash,
       b.bits,
       b.blue_score,
       b.blue_work,
       b.daa_score,
       b.hash_merkle_root,
       b.nonce,
       b.parents,
       b.pruning_point,
       b.timestamp,
       b.utxo_commitment,
       b.version
FROM blocks b;


CREATE OR REPLACE VIEW v_legacy_transactions AS
SELECT t.transaction_id,
       s.subnetwork_id,
       t.hash,
       t.mass,
       ARRAY_AGG(DISTINCT bt.block_hash) AS block_hash,
       t.block_time,
       (ta.block_hash IS NOT NULL)       AS is_accepted,
       ta.block_hash                     AS accepting_block_hash
FROM transactions t
         LEFT JOIN subnetworks s ON t.subnetwork_id = s.id
         LEFT JOIN blocks_transactions bt ON t.transaction_id = bt.transaction_id
         LEFT JOIN transactions_acceptances ta ON t.transaction_id = ta.transaction_id
GROUP BY t.transaction_id, s.subnetwork_id, t.hash, t.mass, t.block_time, ta.block_hash;


CREATE OR REPLACE VIEW v_legacy_transactions_outputs AS
SELECT o.transaction_id,
       o.index,
       o.amount,
       o.script_public_key,
       o.script_public_key_address,
       o.script_public_key_type,
       a.block_hash AS accepting_block_hash
FROM transactions_outputs o
         LEFT JOIN transactions_acceptances a ON o.transaction_id = a.transaction_id;


CREATE OR REPLACE VIEW v_transaction_address_mapping AS
SELECT o.transaction_id,
       o.script_public_key_address AS address,
       o.block_time,
       (a.block_hash IS NOT NULL)  AS is_accepted
FROM transactions_outputs o
         LEFT JOIN transactions_inputs i ON i.previous_outpoint_hash = o.transaction_id AND i.previous_outpoint_index = o.index
         LEFT JOIN transactions_acceptances a ON o.transaction_id = a.transaction_id;
