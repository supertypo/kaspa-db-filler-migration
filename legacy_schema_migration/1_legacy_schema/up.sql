CREATE TABLE IF NOT EXISTS "vars"
(
    key   VARCHAR PRIMARY KEY,
    value TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS "blocks"
(
    hash                    VARCHAR PRIMARY KEY,
    accepted_id_merkle_root VARCHAR,
    difficulty              DOUBLE PRECISION,
    is_chain_block          BOOLEAN,
    merge_set_blues_hashes  VARCHAR[],
    merge_set_reds_hashes   VARCHAR[],
    selected_parent_hash    VARCHAR,
    bits                    INT,
    blue_score              BIGINT,
    blue_work               VARCHAR,
    daa_score               BIGINT,
    hash_merkle_root        VARCHAR,
    nonce                   VARCHAR,
    parents                 VARCHAR[],
    pruning_point           VARCHAR,
    "timestamp"             TIMESTAMP WITHOUT TIME ZONE,
    utxo_commitment         VARCHAR,
    version                 INT
);
CREATE INDEX IF NOT EXISTS block_chainblock ON blocks USING btree (is_chain_block ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_blue_score ON blocks USING btree (blue_score ASC NULLS LAST);


CREATE TABLE IF NOT EXISTS "transactions"
(
    transaction_id       VARCHAR PRIMARY KEY,
    subnetwork_id        VARCHAR,
    hash                 VARCHAR,
    mass                 VARCHAR,
    block_hash           VARCHAR[],
    block_time           BIGINT,
    is_accepted          BOOLEAN,
    accepting_block_hash VARCHAR
);
CREATE INDEX IF NOT EXISTS block_time_idx ON transactions USING btree (block_time DESC NULLS FIRST);
CREATE INDEX IF NOT EXISTS idx_accepting_block ON transactions USING btree (accepting_block_hash ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_block_hash ON transactions USING gin (block_hash);


CREATE TABLE IF NOT EXISTS "transactions_inputs"
(
    id                      SERIAL PRIMARY KEY,
    transaction_id          VARCHAR,
    index                   INT,
    previous_outpoint_hash  VARCHAR,
    previous_outpoint_index INT,
    signature_script        VARCHAR,
    sig_op_count            INT
);
CREATE INDEX IF NOT EXISTS idx_txinp ON transactions_inputs USING btree (transaction_id ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_txin_prev ON transactions_inputs USING btree (previous_outpoint_hash ASC NULLS LAST);


CREATE TABLE IF NOT EXISTS "transactions_outputs"
(
    id                        SERIAL PRIMARY KEY,
    transaction_id            VARCHAR,
    index                     INT,
    amount                    BIGINT,
    script_public_key         VARCHAR,
    script_public_key_address VARCHAR,
    script_public_key_type    VARCHAR,
    accepting_block_hash      VARCHAR
);
CREATE INDEX IF NOT EXISTS idx_txouts ON transactions_outputs USING btree (transaction_id);
CREATE INDEX IF NOT EXISTS idx_txouts_addr ON transactions_outputs USING btree (script_public_key_address);
CREATE INDEX IF NOT EXISTS tx_id_and_index ON transactions_outputs USING btree (transaction_id ASC NULLS LAST, index ASC NULLS LAST);


CREATE TABLE IF NOT EXISTS "tx_id_address_mapping"
(
    id             BIGSERIAL PRIMARY KEY,
    transaction_id VARCHAR(64) NOT NULL,
    address        VARCHAR(70) NOT NULL,
    block_time     BIGINT      NOT NULL,
    is_accepted    BOOLEAN,
    CONSTRAINT tx_id_address_mapping_transaction_id_address_key UNIQUE (transaction_id, address)
);
CREATE INDEX IF NOT EXISTS idx_address_block_time ON tx_id_address_mapping USING btree (address ASC NULLS LAST, block_time ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_block_time ON tx_id_address_mapping USING btree (block_time ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_tx_id ON tx_id_address_mapping USING btree (transaction_id ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_tx_id_address_mapping ON tx_id_address_mapping USING btree (address ASC NULLS LAST, is_accepted ASC NULLS LAST, block_time ASC NULLS LAST);
