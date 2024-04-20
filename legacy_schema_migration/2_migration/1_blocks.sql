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

-- Change datatypes on blocks
ALTER TABLE blocks
    ALTER COLUMN hash TYPE BYTEA USING DECODE(hash, 'hex'),
    ALTER COLUMN accepted_id_merkle_root TYPE BYTEA USING DECODE(accepted_id_merkle_root, 'hex'),
    --difficulty stays the same
    DROP COLUMN is_chain_block,
    ALTER COLUMN merge_set_blues_hashes TYPE BYTEA[] USING decode_varchar_array(merge_set_blues_hashes),
    ALTER COLUMN merge_set_reds_hashes TYPE BYTEA[] USING decode_varchar_array(merge_set_reds_hashes),
    ALTER COLUMN selected_parent_hash TYPE BYTEA USING DECODE(selected_parent_hash, 'hex'),
    ALTER COLUMN bits TYPE BIGINT,
    --blue_score stays the same
    ALTER COLUMN blue_work TYPE BYTEA USING CONVERT_TO(blue_work, 'UTF8'), -- Store large number as bytea to save space
    ALTER COLUMN hash_merkle_root TYPE BYTEA USING DECODE(hash_merkle_root, 'hex'),
    ALTER COLUMN nonce TYPE NUMERIC(32,0) USING CONVERT_TO(nonce, 'UTF8'), -- Store large number as bytea to save space
    ALTER COLUMN parents TYPE BYTEA[] USING decode_varchar_array(parents),
    ALTER COLUMN pruning_point TYPE BYTEA USING DECODE(pruning_point, 'hex'),
    ALTER COLUMN timestamp TYPE INTEGER USING EXTRACT(EPOCH FROM timestamp)::INTEGER,
    ALTER COLUMN utxo_commitment TYPE BYTEA USING DECODE(utxo_commitment, 'hex'),
    ALTER COLUMN version TYPE SMALLINT;

-- Rename index
ALTER INDEX idx_blue_score RENAME TO idx_blocks_blue_score;
