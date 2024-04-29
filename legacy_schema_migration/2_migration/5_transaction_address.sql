CREATE TABLE addresses_transactions
(
    address        VARCHAR,
    transaction_id BYTEA,
    block_time     BIGINT
);

INSERT INTO addresses_transactions (address, transaction_id, block_time)
SELECT map.address,
       DECODE(map.transaction_id, 'hex'),
       map.block_time
FROM tx_id_address_mapping map;

DROP TABLE tx_id_address_mapping;

-- Create constraints/indexes
ALTER table addresses_transactions ADD PRIMARY KEY (address, transaction_id);
CREATE INDEX ON addresses_transactions (address);
CREATE INDEX ON addresses_transactions (transaction_id);
CREATE INDEX ON addresses_transactions (block_time DESC NULLS LAST);
