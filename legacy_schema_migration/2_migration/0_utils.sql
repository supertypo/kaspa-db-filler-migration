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

-- Create read only user
CREATE ROLE readonly WITH LOGIN PASSWORD 'readonly'; -- Remember to change the password later
GRANT CONNECT ON DATABASE postgres TO readonly; -- Allowed to connect to the database
GRANT USAGE ON SCHEMA public TO readonly; -- Allowed to 'use' the schema
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly; -- Access to current tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly; -- Access to all future tables
