-- Insert schema version
INSERT INTO vars (key, value) VALUES ('schema_version', '1');

-- Helper function to decode a VARCHAR array to a BYTEA array
CREATE OR REPLACE FUNCTION decode_varchar_array(varchar_array VARCHAR[])
    RETURNS BYTEA[] AS $$
DECLARE
    result BYTEA[] := '{}';
    varchar_element VARCHAR;
BEGIN
    IF varchar_array IS NULL OR varchar_array = '{}' THEN
        RETURN NULL;
    END IF;
    FOREACH varchar_element IN ARRAY varchar_array
        LOOP
            result := ARRAY_APPEND(result, DECODE(varchar_element, 'hex'));
        END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create read only user for api servers
CREATE ROLE apiserver WITH LOGIN PASSWORD 'apiserver'; -- Remember to change the password later
GRANT CONNECT ON DATABASE postgres TO apiserver; -- Allowed to connect to the database
GRANT USAGE ON SCHEMA public TO apiserver; -- Allowed to 'use' the schema
GRANT SELECT ON ALL TABLES IN SCHEMA public TO apiserver; -- Read only on all current tables
GRANT INSERT, UPDATE, DELETE ON TABLE vars TO apiserver; -- Write access on vars table
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO apiserver; -- Read only on all future tables
ALTER ROLE apiserver SET statement_timeout = '60s';
