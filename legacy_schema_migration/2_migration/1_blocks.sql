--
--Copyright suprtypo@pm.me.
--LICENSED ONLY FOR THE PURPOSE OF INTEGRATING WITH THE KASPA CRYPTOCURRENCY NETWORK.
--

-- Create a new table for is_chain_block
-- Skip migrating blocks.is_chain_block, as the old filler does not update the field on reorgs
CREATE TABLE chain_blocks
(
    block_hash BYTEA PRIMARY KEY
);

-- Convert blocks
ALTER TABLE blocks RENAME TO old_blocks;
CREATE TABLE blocks
(
    hash                    BYTEA,
    accepted_id_merkle_root BYTEA,
    difficulty              DOUBLE PRECISION,
    merge_set_blues_hashes  BYTEA[],
    merge_set_reds_hashes   BYTEA[],
    selected_parent_hash    BYTEA,
    bits                    BIGINT,
    blue_score              BIGINT,
    blue_work               BYTEA,
    daa_score               BIGINT,
    hash_merkle_root        BYTEA,
    nonce                   BYTEA,
    parents                 BYTEA[],
    pruning_point           BYTEA,
    "timestamp"             BIGINT,
    utxo_commitment         BYTEA,
    version                 SMALLINT
);

INSERT INTO blocks
SELECT DECODE(hash, 'hex'),
       DECODE(accepted_id_merkle_root, 'hex'),
       difficulty,
       decode_varchar_array(merge_set_blues_hashes),
       decode_varchar_array(merge_set_reds_hashes),
       DECODE(selected_parent_hash, 'hex'),
       bits,
       blue_score,
       CONVERT_TO(blue_work, 'UTF8'),
       daa_score,
       DECODE(hash_merkle_root, 'hex'),
       CONVERT_TO(nonce, 'UTF8'),
       decode_varchar_array(parents),
       CASE
           WHEN LENGTH(pruning_point) % 2 = 1 THEN DECODE('0' || pruning_point, 'hex')
           ELSE DECODE(pruning_point, 'hex')
       END,
       FLOOR(EXTRACT(EPOCH FROM timestamp) * 1000),
       DECODE(utxo_commitment, 'hex'),
       version
FROM old_blocks;

DROP TABLE old_blocks;

-- Create constraints/indexes
ALTER TABLE blocks ADD PRIMARY KEY (hash);
CREATE INDEX ON blocks (blue_score);
