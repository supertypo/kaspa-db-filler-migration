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
