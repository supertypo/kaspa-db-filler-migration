CREATE TABLE addresses_transactions
(
    address        VARCHAR,
    transaction_id BYTEA,
    block_time     BIGINT,
    PRIMARY KEY (address, transaction_id)
) PARTITION BY HASH (address);

SELECT create_partition('addresses_transactions', 'addresses_transactions_p', 32);

INSERT INTO addresses_transactions (address, transaction_id, block_time)
SELECT map.address,
       DECODE(map.transaction_id, 'hex'),
       map.block_time
FROM tx_id_address_mapping map;

-- Create constraints/indexes
ALTER table addresses_transactions ADD PRIMARY KEY (address, transaction_id);
CREATE INDEX ON addresses_transactions (address);
CREATE INDEX ON addresses_transactions (transaction_id);
CREATE INDEX ON addresses_transactions (block_time DESC NULLS LAST);


CREATE FUNCTION update_adresses_transactions()
    RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO addresses_transactions (address, transaction_id, block_time)
    SELECT o.script_public_key_address,
           o.transaction_id,
           o.block_time
    FROM transactions_outputs o
    WHERE o.transaction_id = NEW.transaction_id
    ON CONFLICT (address, transaction_id) DO NOTHING;

    INSERT INTO addresses_transactions (address, transaction_id, block_time)
    SELECT o.script_public_key_address,
           i.transaction_id,
           o.block_time
    FROM transactions_inputs i
             JOIN transactions_outputs o ON o.transaction_id = i.previous_outpoint_hash AND o.index = i.previous_outpoint_index
    WHERE i.transaction_id = NEW.transaction_id
    ON CONFLICT (address, transaction_id) DO NOTHING;

    RETURN NEW; -- Must return NEW to proceed with the insert into blocks_transactions
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_before_insert_blocks_transactions
    BEFORE INSERT
    ON blocks_transactions
    FOR EACH ROW
EXECUTE FUNCTION update_adresses_transactions();
