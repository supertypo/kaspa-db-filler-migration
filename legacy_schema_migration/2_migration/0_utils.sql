-- Helper function to decode a VARCHAR array to a BYTEA array
CREATE OR REPLACE FUNCTION decode_varchar_array(varchar_array VARCHAR[])
    RETURNS BYTEA[] AS $$
DECLARE
    result BYTEA[] := '{}';
    varchar_element VARCHAR;
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


-- Create a number of partitons on a table
CREATE OR REPLACE FUNCTION create_partition(for_table text, partition_prefix text, num_partitions int)
    RETURNS void AS $$
BEGIN
    FOR i IN 0..num_partitions - 1 LOOP
            EXECUTE 'CREATE TABLE ' || partition_prefix || i || ' PARTITION OF ' || for_table ||
                    ' FOR VALUES WITH (MODULUS ' || num_partitions || ', REMAINDER ' || i || ');';
        END LOOP;
END;
$$ LANGUAGE plpgsql;
