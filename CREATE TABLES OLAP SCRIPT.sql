-- Dimension tables
CREATE TABLE IF NOT EXISTS Dim_Users (
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_phone VARCHAR(12) UNIQUE NOT NULL,
    name VARCHAR(40) NOT NULL,
    email VARCHAR(100),
    registration_date DATE NOT NULL,
    birth_date DATE NOT NULL,
    is_current BOOLEAN,
    start_date DATE,
    end_date DATE
);

CREATE TABLE IF NOT EXISTS Dim_bike_types (
	bike_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bike_type VARCHAR(50) UNIQUE NOT NULL,
    hourly_rate DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS Dim_Bikes (
    bike_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bike_serial_number INT UNIQUE,
	bike_type_id INT NOT NULL REFERENCES Dim_bike_types(bike_type_id) ON DELETE CASCADE,
    model VARCHAR(50),
    status VARCHAR(11),
    is_current BOOLEAN,
    start_date DATE,
    end_date DATE
);

CREATE TABLE IF NOT EXISTS Dim_Stations (
    station_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_name VARCHAR(255) NOT NULL UNIQUE,
    location VARCHAR(255),
    capacity INT
);

CREATE TABLE IF NOT EXISTS Dim_Time (
    time_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date DATE UNIQUE,
    day INT,
    month INT,
    year INT,
    quarter INT,
	day_of_week TEXT,
	is_weekend BOOLEAN
);

-- Fact_Rentals table
CREATE TABLE IF NOT EXISTS Fact_Rentals (
    rental_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT REFERENCES Dim_Users(user_id) ON DELETE CASCADE,
    bike_id INT REFERENCES Dim_Bikes(bike_id) ON DELETE CASCADE,
    station_id INT REFERENCES Dim_Stations(station_id) ON DELETE CASCADE,
	time_id INT REFERENCES Dim_Time(time_id) ON DELETE CASCADE,
    duration_minutes INT,
    -- Aggregated fields
    total_rentals_count INT,
    total_rentals_duration INT,
    total_rentals_price DECIMAL(10, 2)
);

-- Fact_Maintenance table
CREATE TABLE IF NOT EXISTS Fact_Maintenance (
    maintenance_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bike_id INT REFERENCES Dim_Bikes(bike_id) ON DELETE CASCADE,
    station_id INT REFERENCES Dim_Stations(station_id) ON DELETE CASCADE,
	time_id INT REFERENCES Dim_Time(time_id) ON DELETE CASCADE NOT NULL,
    -- Aggregated fields
	duration_days INT,
    total_bikes_in_maintenance INT,
    total_maintenance_cost DECIMAL(10, 2),
    total_maintenance_duration INT
);
