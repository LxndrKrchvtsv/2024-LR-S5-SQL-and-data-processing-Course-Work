--creating table users (if not exists)
CREATE TABLE IF NOT EXISTS users (
	user_phone VARCHAR(12) PRIMARY KEY NOT NULL UNIQUE,
	name VARCHAR(40) NOT NULL,
	email VARCHAR(100) UNIQUE,
	birth_date DATE NOT NULL,
	registration_date DATE NOT NULL
);

--creating table bikeTypes (if not exists)
CREATE TABLE IF NOT EXISTS bikeTypes (
    bike_type VARCHAR(50) PRIMARY KEY NOT NULL,
    hourly_rate DECIMAL(10, 2) NOT NULL
);

--creating table bikes (if not exists)
CREATE TABLE IF NOT EXISTS bikes (
    bike_serial_number INT PRIMARY KEY NOT NULL UNIQUE,
    bike_type VARCHAR(50) NOT NULL REFERENCES bikeTypes(bike_type) ON DELETE CASCADE,
    model VARCHAR(50) NOT NULL,
    status VARCHAR(11) NOT NULL
);

--creating table stations (if not exists)
CREATE TABLE IF NOT EXISTS stations (
    station_name VARCHAR(255) PRIMARY KEY NOT NULL UNIQUE,
	location VARCHAR(255) NOT NULL UNIQUE,
    capacity INT NOT NULL
);

--creating table rentals (if not exists)
CREATE TABLE IF NOT EXISTS rentals (
    rental_id INT PRIMARY KEY NOT NULL UNIQUE,
    user_phone VARCHAR(12) NOT NULL REFERENCES users(user_phone) ON DELETE CASCADE,
    bike_serial_number INT NOT NULL REFERENCES bikes(bike_serial_number) ON DELETE CASCADE,
    station_name VARCHAR(255) NOT NULL REFERENCES stations(station_name) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    total_price DECIMAL(10, 2)
);

--creating table maintenance (if not exists)
CREATE TABLE IF NOT EXISTS maintenance (
    maintenance_id INT PRIMARY KEY NOT NULL UNIQUE,
    bike_serial_number INT NOT NULL REFERENCES bikes(bike_serial_number) ON DELETE CASCADE,
	station_name VARCHAR(255) NOT NULL REFERENCES stations(station_name) ON DELETE CASCADE,
    description TEXT NOT NULL,
    date_start DATE NOT NULL,
    date_end DATE,
    cost DECIMAL(10, 2) NOT NULL
);

--creating table feedbacks (if not exists)
CREATE TABLE IF NOT EXISTS feedbacks (
    feedback_id INT PRIMARY KEY NOT NULL UNIQUE,
    rental_id INT NOT NULL REFERENCES rentals(rental_id) ON DELETE CASCADE,
    user_phone VARCHAR(12) NOT NULL REFERENCES users(user_phone) ON DELETE CASCADE,
    rate INT CHECK (rate >= 1 AND rate <= 5),
    comment TEXT
);

--creating table payments (if not exists) 
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT PRIMARY KEY NOT NULL UNIQUE,
    rental_id INT NOT NULL REFERENCES rentals(rental_id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    date TIMESTAMP NOT NULL,
    method VARCHAR(50) NOT NULL
);