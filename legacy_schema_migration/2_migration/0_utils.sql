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
DECLARE
    range_step int := 256 / num_partitions;
    range_start int := 0;
    range_end int := range_step;
BEGIN
    FOR i IN 1..num_partitions LOOP
            IF i = 1 THEN
                EXECUTE 'CREATE TABLE ' || partition_prefix || i || ' PARTITION OF ' || for_table ||
                        ' FOR VALUES FROM (MINVALUE) TO (' || range_end || ');';
            ELSIF i = num_partitions THEN
                EXECUTE 'CREATE TABLE ' || partition_prefix || i || ' PARTITION OF ' || for_table ||
                        ' FOR VALUES FROM (' || range_start || ') TO (MAXVALUE);';
            ELSE
                EXECUTE 'CREATE TABLE ' || partition_prefix || i || ' PARTITION OF ' || for_table ||
                        ' FOR VALUES FROM (' || range_start || ') TO (' || range_end || ');';
            END IF;
            range_start := range_end;
            range_end := range_end + range_step;
        END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Run a query on all partitions
CREATE OR REPLACE FUNCTION partition_query(query text, num_partitions int)
    RETURNS void AS $$
DECLARE
    part_num int;
    actual_query text;
BEGIN
    FOR part_num IN 1..num_partitions LOOP
            actual_query := REPLACE(query, '{part_num}', part_num::text);
            RAISE NOTICE 'Executing: %', actual_query;
            EXECUTE actual_query;
            RAISE NOTICE 'Completed: %', actual_query;
        END LOOP;
END;
$$ LANGUAGE plpgsql;
