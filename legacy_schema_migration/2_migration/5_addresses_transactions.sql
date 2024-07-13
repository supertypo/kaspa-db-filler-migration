CREATE TABLE addresses_transactions
(
    address        VARCHAR,
    transaction_id BYTEA,
    block_time     BIGINT
);

INSERT INTO addresses_transactions (address, transaction_id, block_time)
SELECT SUBSTRING(map.address FROM 7),
       DECODE(map.transaction_id, 'hex'),
       map.block_time
FROM tx_id_address_mapping map;

DROP TABLE tx_id_address_mapping;

-- Create constraints/indexes
ALTER TABLE addresses_transactions ADD PRIMARY KEY (address, transaction_id);
CREATE INDEX ON addresses_transactions (address);
CREATE INDEX ON addresses_transactions (block_time DESC);
