-- Drop conflicting tables (both local and foreign) before importing
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' AND tablename IN ('users', 'biketypes', 'bikes', 'stations', 'rentals', 'maintenance', 'feedbacks', 'payments')
    LOOP
        -- EXECUTE format('DROP TABLE IF EXISTS %I CASCADE;', r.tablename);
		EXECUTE format('DROP FOREIGN TABLE IF EXISTS %I CASCADE;', r.tablename);
    END LOOP;
END $$;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT 
            n.nspname AS schemaname, 
            c.relname AS tablename
        FROM 
            pg_foreign_table ft
        JOIN pg_class c ON ft.ftrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public'
    LOOP
        EXECUTE format('DROP FOREIGN TABLE IF EXISTS %I.%I CASCADE;', r.schemaname, r.tablename);
    END LOOP;
END $$;


-- Create FDW extension if not exists
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create server and connect to bike_rental_db (OLTP)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_foreign_server
        WHERE srvname = 'oltp_server'
    ) THEN
        CREATE SERVER oltp_server
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host 'localhost', dbname 'bike_rental_db', port '5001');
    END IF;
END $$;

-- Create user mapping if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_user_mappings
        WHERE srvname = 'oltp_server' AND usename = CURRENT_USER
    ) THEN
        CREATE USER MAPPING FOR CURRENT_USER
        SERVER oltp_server
        OPTIONS (user 'postgres', password 'root');
    END IF;
END $$;

-- Import OLTP tables
IMPORT FOREIGN SCHEMA public
LIMIT TO (users, biketypes, bikes, stations, rentals, maintenance, feedbacks, payments)
FROM SERVER oltp_server INTO public;

DROP TABLE IF EXISTS staging_users;
DROP TABLE IF EXISTS staging_bikes;
DROP TABLE IF EXISTS staging_bike_types;
DROP TABLE IF EXISTS staging_stations;
DROP TABLE IF EXISTS staging_time;
DROP TABLE IF EXISTS staging_fact_rentals;
DROP TABLE IF EXISTS staging_fact_maintenance;

--CREATE TEMP TABLE THEN MOVE IT TO OLAP DIM_USERS
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_users AS
SELECT
    user_phone,
    name,
    email,
    registration_date,
    birth_date,
    TRUE AS is_current,
    registration_date AS start_date,
    NULL::DATE AS end_date
FROM users;

INSERT INTO Dim_Users (user_phone, name, email, registration_date, birth_date, is_current, start_date, end_date)
SELECT DISTINCT
    user_phone, name, email, registration_date, birth_date, is_current, start_date, end_date
FROM staging_users
ON CONFLICT (user_phone) DO NOTHING;
-------------------------------------

--CREATE TEMP TABLE THEN MOVE IT TO OLAP DIM_BIKE_TYPES
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_bike_types AS
SELECT
    bike_type,
    hourly_rate
FROM bikeTypes;

INSERT INTO dim_bike_types (bike_type, hourly_rate)
SELECT DISTINCT
    bike_type, hourly_rate
FROM staging_bike_types
ON CONFLICT (bike_type) DO NOTHING;
-------------------------------------

--CREATE TEMP TABLE THEN MOVE IT TO OLAP DIM_BIKES
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_bikes AS
SELECT
    bike_serial_number,
    (SELECT bike_type_id FROM Dim_bike_types WHERE bike_type = bikes.bike_type) AS bike_type_id,
    model,
    status,
    TRUE AS is_current,
    CURRENT_DATE AS start_date,
    NULL::DATE AS end_date
FROM bikes;

INSERT INTO Dim_Bikes (bike_serial_number, bike_type_id, model, status, is_current, start_date, end_date)
SELECT DISTINCT
    bike_serial_number, bike_type_id, model, status, is_current, start_date, end_date
FROM staging_bikes
ON CONFLICT (bike_serial_number) DO NOTHING;
-------------------------------------

--CREATE TEMP TABLE THEN MOVE IT TO OLAP DIM_STATIONS
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_stations AS
SELECT
    station_name,
    location,
    capacity
FROM stations;

INSERT INTO Dim_Stations (station_name, location, capacity)
SELECT DISTINCT
    station_name, location, capacity
FROM staging_stations
ON CONFLICT (station_name) DO NOTHING;
-------------------------------------

--CREATE TEMP TABLE THEN MOVE IT TO OLAP DIM_TIME
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_time AS
SELECT DISTINCT
    DATE(m.date_start) AS date,
    EXTRACT(DAY FROM m.date_start) AS day,
    EXTRACT(MONTH FROM m.date_start) AS month,
    EXTRACT(YEAR FROM m.date_start) AS year,
    CEILING(EXTRACT(MONTH FROM m.date_start) / 3.0) AS quarter,
    TO_CHAR(m.date_start, 'Day') AS day_of_week,
    CASE
        WHEN TO_CHAR(m.date_start, 'D') IN ('6', '7') THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM maintenance m
UNION
SELECT DISTINCT
    DATE(r.start_time) AS date,
    EXTRACT(DAY FROM r.start_time) AS day,
    EXTRACT(MONTH FROM r.start_time) AS month,
    EXTRACT(YEAR FROM r.start_time) AS year,
    CEILING(EXTRACT(MONTH FROM r.start_time) / 3.0) AS quarter,
    TO_CHAR(r.start_time, 'Day') AS day_of_week,
    CASE
        WHEN TO_CHAR(r.start_time, 'D') IN ('6', '7') THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM rentals r;

INSERT INTO Dim_Time (date, day, month, year, quarter, day_of_week, is_weekend)
SELECT DISTINCT
    date, day, month, year, quarter, day_of_week, is_weekend
FROM staging_time
ON CONFLICT (date) DO NOTHING;
-------------------------------------

--CREATE TEMP TABLE THEN MOVE IT TO OLAP FACT_RENTALS
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_fact_rentals AS
SELECT
    r.user_phone,
    b.bike_serial_number AS bike_id,
    s.station_name AS station_id,
    DATE(r.start_time) AS date,
    EXTRACT(EPOCH FROM (r.end_time - r.start_time)) / 60 AS duration_minutes,
    COUNT(*) OVER (PARTITION BY r.user_phone) AS total_rentals_count,
    SUM(EXTRACT(EPOCH FROM (r.end_time - r.start_time))) OVER (PARTITION BY r.user_phone) / 60 AS total_rentals_duration,
    SUM(r.total_price) OVER (PARTITION BY r.user_phone) AS total_rentals_price
FROM rentals r
LEFT JOIN users u ON r.user_phone = u.user_phone
LEFT JOIN bikes b ON r.bike_serial_number = b.bike_serial_number
LEFT JOIN stations s ON r.station_name = s.station_name; 

INSERT INTO Fact_Rentals (
    user_id,
    bike_id,
    station_id,
    time_id,
    duration_minutes,
    total_rentals_count,
    total_rentals_duration,
    total_rentals_price
)
SELECT
    du.user_id,
    db.bike_id,
    ds.station_id,
    dt.time_id,
    sf.duration_minutes,
    sf.total_rentals_count,
    sf.total_rentals_duration,
    sf.total_rentals_price
FROM staging_fact_rentals sf
LEFT JOIN Dim_Users du ON sf.user_phone = du.user_phone
LEFT JOIN Dim_Bikes db ON sf.bike_id = db.bike_serial_number
LEFT JOIN Dim_Stations ds ON sf.station_id = ds.station_name
LEFT JOIN Dim_Time dt ON sf.date = dt.date
WHERE
    EXTRACT(YEAR FROM sf.date) = 2024
    AND db.status IN ('available')
	AND NOT EXISTS (
        SELECT 1
        FROM Fact_Rentals fr
        WHERE 
            fr.user_id = du.user_id
            AND fr.bike_id = db.bike_id
            AND fr.station_id = ds.station_id
            AND fr.time_id = dt.time_id
            AND fr.duration_minutes = sf.duration_minutes
    );
-------------------------------------



-- CREATE TEMP TABLE THEN MOVE IT TO OLAP FACT_RENTALS_MAINTENANCE
-------------------------------------
CREATE TEMP TABLE IF NOT EXISTS staging_fact_maintenance AS
SELECT
    b.bike_serial_number AS bike_id,
    s.station_name AS station_id,
    DATE(m.date_start) AS date,
    (m.date_end - m.date_start) AS duration_days,
    COUNT(*) OVER (PARTITION BY b.bike_serial_number) AS total_bikes_in_maintenance,
    SUM(m.cost) OVER (PARTITION BY b.bike_serial_number) AS total_maintenance_cost,
    SUM(m.date_end - m.date_start) OVER (PARTITION BY b.bike_serial_number) AS total_maintenance_duration
FROM maintenance m
LEFT JOIN staging_bikes b ON m.bike_serial_number = b.bike_serial_number
LEFT JOIN staging_stations s ON m.station_name = s.station_name;

INSERT INTO Fact_Maintenance (
    bike_id,
    station_id,
    time_id,
    duration_days,
    total_bikes_in_maintenance,
    total_maintenance_cost,
    total_maintenance_duration
)
SELECT
    db.bike_id,
    ds.station_id,
    dt.time_id,
    sfm.duration_days,
    sfm.total_bikes_in_maintenance,
    sfm.total_maintenance_cost,
    sfm.total_maintenance_duration
FROM staging_fact_maintenance sfm
LEFT JOIN Dim_Bikes db ON sfm.bike_id = db.bike_serial_number
LEFT JOIN Dim_Stations ds ON sfm.station_id = ds.station_name
LEFT JOIN Dim_Time dt ON sfm.date = dt.date
WHERE
    EXTRACT(YEAR FROM sfm.date) = 2024
    AND dt.time_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM Fact_Maintenance fm
        WHERE 
            fm.bike_id = db.bike_id
            AND fm.station_id = ds.station_id
            AND fm.time_id = dt.time_id
            AND fm.duration_days = sfm.duration_days
    );
-------------------------------------