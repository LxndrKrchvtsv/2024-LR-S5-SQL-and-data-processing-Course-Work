DROP TABLE IF EXISTS temp_bikes; CREATE TEMP TABLE temp_bikes (bike_serial_number INT, bike_type VARCHAR(50), model VARCHAR(50), status VARCHAR(11)); \COPY temp_bikes(bike_serial_number, bike_type, model, status) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\bikes.csv' WITH (FORMAT csv, HEADER true); INSERT INTO bikes (bike_serial_number, bike_type, model, status) SELECT bike_serial_number, bike_type, model, status FROM temp_bikes ON CONFLICT (bike_serial_number) DO NOTHING;

DROP TABLE IF EXISTS temp_maintenance; CREATE TEMP TABLE temp_maintenance (maintenance_id INT, bike_serial_number INT, station_name VARCHAR(255), description TEXT, date_start DATE, date_end DATE, cost DECIMAL(10, 2)); \COPY temp_maintenance(maintenance_id, bike_serial_number, station_name, description, date_start, date_end, cost) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\maintenance.csv' WITH (FORMAT csv, HEADER true); INSERT INTO maintenance (maintenance_id, bike_serial_number, station_name, description, date_start, date_end, cost) SELECT maintenance_id, bike_serial_number, station_name, description, date_start, date_end, cost FROM temp_maintenance ON CONFLICT (maintenance_id) DO NOTHING;

DROP TABLE IF EXISTS temp_payments; CREATE TEMP TABLE temp_payments (payment_id INT, rental_id INT, amount DECIMAL(10, 2), date TIMESTAMP, method VARCHAR(50)); \COPY temp_payments (payment_id, rental_id, amount, date, method) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\payments.csv' WITH (FORMAT csv, HEADER true); INSERT INTO payments (payment_id, rental_id, amount, date, method) SELECT payment_id, rental_id, amount, date, method FROM temp_payments ON CONFLICT (payment_id) DO NOTHING;

DROP TABLE IF EXISTS temp_rentals; CREATE TEMP TABLE temp_rentals (rental_id INT, user_phone VARCHAR(12), bike_serial_number INT, station_name VARCHAR(255), start_time TIMESTAMP, end_time TIMESTAMP, total_price DECIMAL(10, 2)); \COPY temp_rentals (rental_id, user_phone, bike_serial_number, station_name, start_time, end_time, total_price) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\rentals.csv' WITH (FORMAT csv, HEADER true); INSERT INTO rentals (rental_id, user_phone, bike_serial_number, station_name, start_time, end_time, total_price) SELECT rental_id, user_phone, bike_serial_number, station_name, start_time, end_time, total_price FROM temp_rentals ON CONFLICT (rental_id) DO NOTHING;

DROP TABLE IF EXISTS temp_biketypes; CREATE TEMP TABLE temp_biketypes (bike_type VARCHAR(50), hourly_rate numeric(10,2)); \COPY temp_biketypes(bike_type, hourly_rate) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\bikeTypes.csv' WITH (FORMAT csv, HEADER true); INSERT INTO biketypes (bike_type, hourly_rate) SELECT bike_type, hourly_rate FROM temp_biketypes ON CONFLICT (bike_type) DO NOTHING;

DROP TABLE IF EXISTS temp_stations; CREATE TEMP TABLE temp_stations (station_name VARCHAR(255), location VARCHAR(255), capacity INT); \COPY temp_stations(station_name, location, capacity) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\stations.csv' WITH (FORMAT csv, HEADER true); INSERT INTO stations (station_name, location, capacity) SELECT station_name, location, capacity FROM temp_stations ON CONFLICT (station_name) DO NOTHING;

DROP TABLE IF EXISTS temp_users; CREATE TEMP TABLE temp_users (user_phone VARCHAR(12), name VARCHAR(40), email VARCHAR(100),registration_date DATE, birth_date DATE); \COPY temp_users(user_phone, name, email, registration_date, birth_date ) FROM 'C:\Program Files\PostgreSQL\17\CSV_FILES\users.csv' WITH (FORMAT csv, HEADER true); INSERT INTO users (user_phone, name, email, registration_date,  birth_date) SELECT user_phone, name, email, registration_date,  birth_date FROM temp_users ON CONFLICT (user_phone) DO NOTHING;
