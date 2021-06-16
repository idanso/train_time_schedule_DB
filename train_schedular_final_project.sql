CREATE SCHEMA train_schedular;
-- drop SCHEMA train_schedular;
USE train_schedular;

CREATE TABLE train
(train_id		int NOT NULL,
avaliability 	enum('avaliable', 'maintainance', 'out of order'),
num_of_seats	int,
PRIMARY KEY		(train_id)
)ENGINE = InnoDB;

CREATE TABLE person
(num_id		int NOT NULL,
first_name	VARCHAR(25) NOT NULL,
last_name	VARCHAR(25) NOT NULL,
PRIMARY KEY	(num_id)

)ENGINE = InnoDB;

CREATE TABLE passanger
(num_id integer not null,
FOREIGN KEY (num_id) REFERENCES person(num_id),
PRIMARY KEY (num_id)
)ENGINE = InnoDB;	

CREATE TABLE driver
(num_id int not null,
seniority_years int,
PRIMARY KEY (num_id),
FOREIGN KEY (num_id) REFERENCES person(num_id)
)ENGINE = InnoDB;

CREATE TABLE station
(station_name	VARCHAR(25) NOT NULL,
address	VARCHAR(40),
PRIMARY KEY (station_name)
)ENGINE = InnoDB;

CREATE TABLE single_stop_drive
(single_stop_drive_id INT NOT NULL,
source_station VARCHAR(25) NOT NULL,
destination_station VARCHAR(25) NOT NULL,
drive_duration int NOT NULL,
cost INT NOT NULL,
FOREIGN KEY (source_station) REFERENCES station(station_name),
FOREIGN KEY (destination_station) REFERENCES station(station_name),
PRIMARY KEY (single_stop_drive_id)
)ENGINE = InnoDB;

CREATE INDEX single_stop_drive_index
ON lines_data (single_stop_id);

CREATE TABLE line
(line_id INT NOT NULL,
frequency_minutes INT NOT NULL,
PRIMARY KEY (line_id)
)ENGINE = InnoDB;

CREATE TABLE lines_data
(line_id INT NOT NULL,
drive_sequence_order INT NOT NULL,
single_stop_id INT NOT NULL,
FOREIGN KEY (line_id) REFERENCES line(line_id) ON DELETE CASCADE,
FOREIGN KEY (single_stop_id) REFERENCES single_stop_drive(single_stop_drive_id),
PRIMARY KEY (line_id, drive_sequence_order)
)ENGINE = InnoDB;

CREATE TABLE time_schedular
(drive_id INT NOT NULL AUTO_INCREMENT,
departure_time TIME,
driver_id INT, 
train_id  INT,
line_id INT NOT NULL,
avaliable_seats INT,
FOREIGN KEY (driver_id) REFERENCES driver(num_id),
FOREIGN KEY (train_id) REFERENCES train(train_id),
FOREIGN KEY (line_id) REFERENCES line(line_id) ON DELETE CASCADE,
PRIMARY KEY (drive_id)
)ENGINE = InnoDB;

CREATE INDEX departute_time_index
ON time_schedular (departure_time, line_id);

CREATE TABLE ticket
(ticket_num INT NOT NULL,
purchase_time DATETIME,
cost INT,
drive_id INT NOT NULL,
source_station VARCHAR(25) NOT NULL,
destination_station VARCHAR(25) NOT NULL,
departure_time TIME NOT NULL,
arrival_time TIME,
passanger_id INT NOT NULL,
FOREIGN KEY (drive_id) REFERENCES time_schedular(drive_id),
FOREIGN KEY (source_station) REFERENCES station(station_name),
FOREIGN KEY (destination_station) REFERENCES station(station_name),
FOREIGN KEY (passanger_id) REFERENCES passanger(num_id),
PRIMARY KEY (ticket_num)
)ENGINE = InnoDB;

# temporary table for procedure use
CREATE TEMPORARY TABLE search_result_tmp(drive_id INT, line_id INT, departure_time TIME, arrival_time TIME, avaliable_seats INT);

################## Logs Tables ##################

CREATE TABLE ticket_logs
(id INT NOT NULL AUTO_INCREMENT,
ticket_num INT NOT NULL,
purchase_time DATETIME,
new_cost INT,
old_cost INT,
new_drive_id INT,
old_drive_id INT,
new_source_station VARCHAR(25),
old_source_station VARCHAR(25),
new_destination_station VARCHAR(25),
old_destination_station VARCHAR(25),
new_departure_time TIME,
old_departure_time TIME,
new_arrival_time TIME,
old_arrival_time TIME,
new_passanger_id INT,
old_passanger_id INT,
log_time TIMESTAMP,
log_op VARCHAR(25),
PRIMARY KEY (id)
)ENGINE = InnoDB;

CREATE TABLE time_schedular_logs
(id INT NOT NULL AUTO_INCREMENT,
driver_id INT, 
new_train_id INT,
new_line_id INT,
new_avaliable_seats INT,
new_departure_time TIME,
old_train_id  INT,
old_line_id INT,
old_avaliable_seats INT,
old_departure_time TIME,
log_time TIMESTAMP,
log_op VARCHAR(25),
PRIMARY KEY (id)
)ENGINE = InnoDB;

CREATE TABLE train_logs
(id INT NOT NULL AUTO_INCREMENT,
train_id		int NOT NULL,
new_avaliability 	enum('avaliable', 'maintainance', 'out of order'),
new_num_of_seats	int,
old_avaliability 	enum('avaliable', 'maintainance', 'out of order'),
old_num_of_seats	int,
log_time TIMESTAMP,
log_op VARCHAR(25),
PRIMARY KEY (id)
)ENGINE = InnoDB;


###################### NOT IN USE ######################
-- DELIMITER $$
-- # procedure for getting sum of column between stations for specific line
-- CREATE PROCEDURE get_sum_of_column_between_stations_for_line(
--     line_id INT,
--     departure_station CHAR(25),
--     source_station CHAR(25),
--     selected_column CHAR(25)
-- )
-- BEGIN
-- SELECT sum(selected_column) FROM single_stop_drive, lines_data
-- 			WHERE lines_data.line_id = line_id
-- 			and lines_data.drive_sequence_order >= (SELECT drive_sequence_order FROM lines_data
-- 													WHERE	lines_data.single_stop_id = (SELECT single_stop_drive_id FROM single_stop_drive
-- 																						WHERE source_station = departure_station))
-- 			and lines_data.drive_sequence_order <= (SELECT drive_sequence_order FROM lines_data
-- 													WHERE	lines_data.single_stop_id = (SELECT single_stop_drive_id FROM single_stop_drive
-- 																						WHERE destination_station = source_station))
-- 			and single_stop_drive_id = single_stop_id;
-- END$$
-- DELIMITER ;