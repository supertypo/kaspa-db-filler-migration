-- Helper function to decode a VARCHAR array to a BYTEA array
CREATE OR REPLACE FUNCTION decode_varchar_array(varchar_array VARCHAR[])
    RETURNS BYTEA[] AS $$
DECLARE
    result BYTEA[] := '{}';
    varchar_element VARCHAR; -- Correctly declare loop variable
BEGIN
    IF varchar_array IS NULL THEN
        RETURN '{}';
    END IF;
    FOREACH varchar_element IN ARRAY varchar_array
        LOOP
            result := ARRAY_APPEND(result, DECODE(varchar_element, 'hex'));
        END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create a new table for is_chain_block
DROP TABLE IF EXISTS chain_blocks;
CREATE TABLE chain_blocks AS
SELECT DECODE(accepted_id_merkle_root, 'hex') AS block_hash FROM blocks
WHERE is_chain_block = true;
ALTER TABLE chain_blocks ADD PRIMARY KEY (block_hash);

-- Fix odd length blue_work by padding them with a zero
UPDATE blocks SET blue_work = '0' || blue_work WHERE LENGTH(blue_work) % 2 != 0;

-- Change datatypes on blocks
ALTER TABLE blocks ALTER COLUMN hash TYPE BYTEA USING DECODE(hash, 'hex');
ALTER TABLE blocks ALTER COLUMN accepted_id_merkle_root TYPE BYTEA USING DECODE(accepted_id_merkle_root, 'hex');
--difficulty stays the same
ALTER TABLE blocks DROP COLUMN is_chain_block;
ALTER TABLE blocks ALTER COLUMN merge_set_blues_hashes TYPE BYTEA[] USING decode_varchar_array(merge_set_blues_hashes);
ALTER TABLE blocks ALTER COLUMN merge_set_reds_hashes TYPE BYTEA[] USING decode_varchar_array(merge_set_reds_hashes);
ALTER TABLE blocks ALTER COLUMN selected_parent_hash TYPE BYTEA USING DECODE(selected_parent_hash, 'hex');
ALTER TABLE blocks ALTER COLUMN bits TYPE BIGINT;
--blue_score stays the same
ALTER TABLE blocks ALTER COLUMN blue_work TYPE BYTEA USING DECODE(blue_work, 'hex');
ALTER TABLE blocks ALTER COLUMN hash_merkle_root TYPE BYTEA USING DECODE(hash_merkle_root, 'hex');
ALTER TABLE blocks ALTER COLUMN nonce TYPE NUMERIC(32,0) USING nonce::NUMERIC(32,0);
ALTER TABLE blocks ALTER COLUMN parents TYPE BYTEA[] USING decode_varchar_array(parents);
ALTER TABLE blocks ALTER COLUMN pruning_point TYPE BYTEA USING DECODE(pruning_point, 'hex');
ALTER TABLE blocks ALTER COLUMN timestamp TYPE INTEGER USING EXTRACT(EPOCH FROM timestamp)::INTEGER;
ALTER TABLE blocks ALTER COLUMN utxo_commitment TYPE BYTEA USING DECODE(utxo_commitment, 'hex');
ALTER TABLE blocks ALTER COLUMN version TYPE SMALLINT;

-- Rename index
ALTER INDEX idx_blue_score RENAME TO idx_blocks_blue_score;
