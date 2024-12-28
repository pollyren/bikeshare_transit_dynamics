DO $$ 
DECLARE 
    table_name TEXT;
    prefixes TEXT[] := ARRAY[
        'cta_q', 
        'mta_q', 
        'metro_q',
        'divvy_cta',
        'citi_mta',
        'metro_metro'
    ];
BEGIN
    FOR table_name IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND (
            tablename LIKE ANY (SELECT prefix || '%' FROM unnest(prefixes) AS prefix)
        )
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', table_name);
    END LOOP;
END $$;