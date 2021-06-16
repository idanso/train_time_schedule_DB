USE train_schedular;
# procedure for getting all lines and their departure time that match the wanted source and destination stations 
DELIMITER $$
CREATE PROCEDURE giving_relevent_lines_by_stations_and_departure_time(
    search_source CHAR(25),
    search_destination CHAR(25),
    departure_time TIME,
    wanted_date DATE
)
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE cur_line_id INT DEFAULT 0;
	DECLARE drive_duration_to_source_tmp INT DEFAULT 0;
    DECLARE drive_duration_from_source_to_destination INT;
    
    #geting relevant lines containing source station and destination station
	DECLARE match_lines CURSOR FOR SELECT lines_data.line_id FROM (select line_id, count(tmp.line_id) AS station_count_tmp FROM (SELECT * FROM lines_data, single_stop_drive
																		WHERE (single_stop_drive.source_station = search_source OR single_stop_drive.destination_station = search_destination)
																		AND single_stop_drive_id = single_stop_id) AS tmp
																		GROUP BY line_id) AS line_list, lines_data
													WHERE station_count_tmp >= 2 AND lines_data.line_id =  line_list.line_id
													GROUP BY line_id
													UNION
													SELECT line_id FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																		WHERE source_station = search_source AND destination_station = search_destination) AS single_stop_id_list
													WHERE lines_data.single_stop_id = single_stop_id_list.single_stop_drive_id;

	# declare NOT FOUND handler
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	
	OPEN match_lines;
    TRUNCATE TABLE search_result_tmp;
    
    fill_relevant_drives: LOOP
							FETCH match_lines INTO cur_line_id;
                            IF finished = 1 THEN 
									LEAVE fill_relevant_drives;
							END IF;
                            
                            SET drive_duration_to_source_tmp = (SELECT sum(drive_duration) FROM single_stop_drive, lines_data
																								WHERE lines_data.line_id = cur_line_id
																								and lines_data.drive_sequence_order <= 1
																								and lines_data.drive_sequence_order <= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																																														WHERE destination_station = search_source) As relevant_single_stop_id1
																																		WHERE	lines_data.single_stop_id = relevant_single_stop_id1.single_stop_drive_id and lines_data.line_id = cur_line_id)
																								and single_stop_drive_id = single_stop_id);
                            
                            SET drive_duration_from_source_to_destination = (SELECT sum(drive_duration) FROM single_stop_drive, lines_data
																		WHERE lines_data.line_id = cur_line_id
																		and lines_data.drive_sequence_order >= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																																								WHERE source_station = search_source) As relevant_single_stop_id1
																												WHERE	lines_data.single_stop_id = relevant_single_stop_id1.single_stop_drive_id and lines_data.line_id = cur_line_id)
																		and lines_data.drive_sequence_order <= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																																								WHERE destination_station = search_destination) relevant_single_stop_id2
																												WHERE	lines_data.single_stop_id = relevant_single_stop_id2.single_stop_drive_id and lines_data.line_id = cur_line_id)
																		and single_stop_drive_id = single_stop_id);
                            
                            INSERT INTO search_result_tmp (drive_id, line_id, departure_time, arrival_time, avaliable_seats) SELECT drive_id, time_schedular.line_id, ADDTIME(time_schedular.departure_time, SEC_TO_TIME(60*drive_duration_to_source_tmp)),
																										ADDTIME(time_schedular.departure_time, SEC_TO_TIME(60*(drive_duration_from_source_to_destination + drive_duration_to_source_tmp))), avaliable_seats
																									FROM time_schedular
																									WHERE time_schedular.departure_date = wanted_date
                                                                                                    AND time_schedular.line_id = cur_line_id
																									AND ADDTIME(time_schedular.departure_time, SEC_TO_TIME(60*drive_duration_to_source_tmp)) >= departure_time;
    
							END LOOP fill_relevant_drives;
	CLOSE match_lines;
	SELECT * FROM search_result_tmp ORDER BY arrival_time ASC LIMIT 10;
END$$
DELIMITER ;


# filling schedular time table with drives according to frequancy
DELIMITER $$
CREATE PROCEDURE insert_drives_to_schedular_time_by_frequency(
    wanted_line_id INT,
    wanted_first_departure_time TIME,
    wanted_departure_date DATE
)
BEGIN
    DECLARE cur_datetime DATETIME DEFAULT CAST(wanted_first_departure_time AS DATETIME);
    DECLARE tmp TIME DEFAULT '23:59:00';
    DECLARE stop_time DATETIME DEFAULT CAST(tmp AS DATETIME);
    DECLARE wanted_frequency INT DEFAULT 0;
    
    SET wanted_frequency = (SELECT frequency_minutes FROM line WHERE line_id = wanted_line_id);
    
    WHILE cur_datetime <= stop_time DO
        INSERT INTO time_Schedular(departure_time, line_id, avaliable_seats, departure_date)
        VALUES (TIME(cur_datetime), wanted_line_id, 0, wanted_departure_date);
        
        SET cur_datetime = ADDTIME(cur_datetime, SEC_TO_TIME(wanted_frequency*60));
    END WHILE;
END$$
DELIMITER ;


# procedure for getting sum of column between stations for specific line
DELIMITER $$
CREATE PROCEDURE get_sum_of_column_between_stations_for_line(
    IN line_id INT,
    IN source_station CHAR(25),
    IN destination_station CHAR(25),
	IN selected_column CHAR(25)
)
BEGIN

SET @line_id = line_id;
SET @source_station = source_station;
SET @destination_station = destination_station;

SET @stmt = CONCAT("SELECT sum(",selected_column,") INTO @OUT_VAR FROM single_stop_drive, lines_data
					WHERE lines_data.line_id = ?
					and lines_data.drive_sequence_order >= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																											WHERE source_station = ?) As relevant_single_stop_id1
															WHERE	lines_data.single_stop_id = relevant_single_stop_id1.single_stop_drive_id and lines_data.line_id = ?)
					and lines_data.drive_sequence_order <= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																											WHERE destination_station = ?) relevant_single_stop_id2
															WHERE	lines_data.single_stop_id = relevant_single_stop_id2.single_stop_drive_id and lines_data.line_id = ?)
					and single_stop_drive_id = single_stop_id");

PREPARE stmt FROM @stmt;
                    
EXECUTE stmt USING @line_id, @source_station, @line_id, @destination_station, @line_id;
DEALLOCATE PREPARE stmt;
END$$
DELIMITER ;


#trigger for calculate and set cost, arrival time and purchuse time to new ticket
DELIMITER $$
CREATE TRIGGER calculate_cost_and_duration_time
Before INSERT ON ticket
FOR EACH ROW
BEGIN
	DECLARE new_line_id INT;
    SET new_line_id = (SELECT line_id FROM time_schedular WHERE time_schedular.drive_id = NEW.drive_id);
    
	#calculate and set cost of ticket
	SET NEW.cost = (SELECT sum(cost) FROM single_stop_drive, lines_data
			WHERE lines_data.line_id = new_line_id
			and lines_data.drive_sequence_order >= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																									WHERE source_station = NEW.source_station) As relevant_single_stop_id1
													WHERE	lines_data.single_stop_id = relevant_single_stop_id1.single_stop_drive_id and lines_data.line_id = new_line_id)
			and lines_data.drive_sequence_order <= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																									WHERE destination_station = NEW.destination_station) relevant_single_stop_id2
													WHERE	lines_data.single_stop_id = relevant_single_stop_id2.single_stop_drive_id and lines_data.line_id = new_line_id)
			and single_stop_drive_id = single_stop_id);
            
	#calculate and set arrival time of route of ticket
	SET NEW.arrival_time = ADDTIME(NEW.departure_time, SEC_TO_TIME(60*(SELECT sum(drive_duration) FROM single_stop_drive, lines_data
																		WHERE lines_data.line_id = new_line_id
																		and lines_data.drive_sequence_order >= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																																								WHERE source_station = NEW.source_station) As relevant_single_stop_id1
																												WHERE	lines_data.single_stop_id = relevant_single_stop_id1.single_stop_drive_id and lines_data.line_id = new_line_id)
																		and lines_data.drive_sequence_order <= (SELECT drive_sequence_order FROM lines_data, (SELECT single_stop_drive_id FROM single_stop_drive
																																								WHERE destination_station = NEW.destination_station) relevant_single_stop_id2
																												WHERE	lines_data.single_stop_id = relevant_single_stop_id2.single_stop_drive_id and lines_data.line_id = new_line_id)
																		and single_stop_drive_id = single_stop_id)));
            
	#set purchase time to current time
	SET NEW.purchase_time = NOW();
END$$
DELIMITER ;

# update number of avalible seats when assigning a train to a drive
DELIMITER $$
CREATE TRIGGER update_avaliable_seats_in_drive
BEFORE UPDATE ON time_schedular
FOR EACH ROW
BEGIN
   IF NOT (NEW.train_id <=> OLD.train_id) THEN
        SET NEW.avaliable_seats = (SELECT num_of_seats FROM train WHERE train_id = NEW.train_id);
   END IF;

END$$
DELIMITER ;

#trigger for decrease one avaliable seat from the drive after a pourchase of ticket
DELIMITER $$
CREATE TRIGGER reduce_avaliable_seat_from_drive
AFTER INSERT ON ticket
FOR EACH ROW
BEGIN
	UPDATE time_schedular SET avaliable_seats = avaliable_seats - 1 WHERE time_schedular.drive_id = NEW.drive_id;
END$$
DELIMITER ;


#trigger for increse one avaliable seat from the drive after a cancle pourchase of ticket
DELIMITER $$
CREATE TRIGGER increse_avaliable_seat_from_drive
AFTER DELETE ON ticket
FOR EACH ROW
BEGIN
	UPDATE time_schedular SET avaliable_seats = avaliable_seats + 1 WHERE time_schedular.drive_id = OLD.drive_id;
END$$
DELIMITER ;

################### Logs Triggers ###################

#trigger for train_log for insert
DELIMITER $$
CREATE TRIGGER train_ins_log
AFTER INSERT ON train
FOR EACH ROW
BEGIN
	INSERT INTO train_logs (train_id, new_avaliability, new_num_of_seats, old_avaliability, old_num_of_seats, log_time, log_op)
    VALUES (NEW.train_id, NEW.avaliability, NEW.num_of_seats, NULL, NULL, NOW(), 'INSERT');
END$$
DELIMITER ;

#trigger for train_log for update
DELIMITER $$
CREATE TRIGGER train_upt_log
AFTER UPDATE ON train
FOR EACH ROW
BEGIN
	INSERT INTO train_logs (train_id, new_avaliability, new_num_of_seats, old_avaliability, old_num_of_seats, log_time, log_op)
    VALUES (NEW.train_id, NEW.avaliability, NEW.num_of_seats, OLD.avaliability, OLD.num_of_seats, NOW(), 'UPDATE');
END$$
DELIMITER ;

#trigger for train_log for delete
DELIMITER $$
CREATE TRIGGER train_del_log
AFTER DELETE ON train
FOR EACH ROW
BEGIN
	INSERT INTO train_logs (train_id, new_avaliability, new_num_of_seats, old_avaliability, old_num_of_seats, log_time, log_op)
    VALUES (OLD.train_id, NULL, NULL, OLD.avaliability, OLD.num_of_seats, NOW(), 'DELETE');
END$$
DELIMITER ;


#trigger for time_schedular_logs for insert
DELIMITER $$
CREATE TRIGGER time_schedular_ins_logs
AFTER INSERT ON time_schedular
FOR EACH ROW
BEGIN
	INSERT INTO time_schedular_logs (driver_id, new_train_id, new_line_id, new_avaliable_seats, new_departure_time, old_train_id, old_line_id, old_avaliable_seats, old_departure_time, log_time, log_op)
    VALUES (NEW.driver_id, NEW.train_id, NEW.line_id, NEW.avaliable_seats, NEW.departure_time, NULL, NULL, NULL, NULL, NOW(), 'INSERT');
END$$
DELIMITER ;

#trigger for time_schedular_logs for update
DELIMITER $$
CREATE TRIGGER time_schedular_upt_logs
AFTER UPDATE ON time_schedular
FOR EACH ROW
BEGIN
	INSERT INTO time_schedular_logs (driver_id, new_train_id, new_line_id, new_avaliable_seats, new_departure_time, old_train_id, old_line_id, old_avaliable_seats, old_departure_time, log_time, log_op)
    VALUES (NEW.driver_id, NEW.train_id, NEW.line_id, NEW.avaliable_seats, NEW.departure_time, OLD.train_id, OLD.line_id, OLD.avaliable_seats, OLD.departure_time, NOW(), 'UPDATE');
END$$
DELIMITER ;

#trigger for time_schedular_logs for delete
DELIMITER $$
CREATE TRIGGER time_schedular_del_logs
AFTER DELETE ON time_schedular
FOR EACH ROW
BEGIN
	INSERT INTO time_schedular_logs (driver_id, new_train_id, new_line_id, new_avaliable_seats, new_departure_time, old_train_id, old_line_id, old_avaliable_seats, old_departure_time, log_time, log_op)
    VALUES (OLD.driver_id, OLD.train_id, NULL, NULL, NULL, NULL, OLD.line_id, OLD.avaliable_seats, OLD.departure_time, NOW(), 'DELETE');
END$$
DELIMITER ;


#trigger for ticket_logs for insert
DELIMITER $$
CREATE TRIGGER ticket_ins_logs
AFTER INSERT ON ticket
FOR EACH ROW
BEGIN
	INSERT INTO ticket_logs (ticket_num, purchase_time, new_passanger_id, new_cost, new_drive_id, new_source_station, new_destination_station, new_departure_time, new_arrival_time,
							old_passanger_id, old_cost, old_drive_id, old_source_station, old_destination_station, old_departure_time, old_arrival_time, log_time, log_op)
    VALUES (NEW.ticket_num, NEW.purchase_time, NEW.passanger_id, NEW.cost, NEW.drive_id, NEW.source_station, NEW.destination_station, NEW.departure_time, NEW.arrival_time,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), 'INSERT');
END$$
DELIMITER ;

#trigger for ticket_logs for update
DELIMITER $$
CREATE TRIGGER ticket_upt_logs
AFTER UPDATE ON ticket
FOR EACH ROW
BEGIN
	INSERT INTO ticket_logs (ticket_num, purchase_time, new_passanger_id, new_cost, new_drive_id, new_source_station, new_destination_station, new_departure_time, new_arrival_time,
							old_passanger_id, old_cost, old_drive_id, old_source_station, old_destination_station, old_departure_time, old_arrival_time, log_time, log_op)
    VALUES (NEW.ticket_num, NEW.purchase_time, NEW.passanger_id, NEW.cost, NEW.drive_id, NEW.source_station, NEW.destination_station, NEW.departure_time, NEW.arrival_time,
			OLD.passanger_id, OLD.cost, OLD.drive_id, OLD.source_station, OLD.destination_station, OLD.departure_time, OLD.arrival_time, NOW(), 'UPDATE');
END$$
DELIMITER ;

#trigger for ticket_logs for delete
DELIMITER $$
CREATE TRIGGER ticket_del_logs
AFTER DELETE ON ticket
FOR EACH ROW
BEGIN
	INSERT INTO ticket_logs (ticket_num, purchase_time, new_passanger_id, new_cost, new_drive_id, new_source_station, new_destination_station, new_departure_time, new_arrival_time,
							old_passanger_id, old_cost, old_drive_id, old_source_station, old_destination_station, old_departure_time, old_arrival_time, log_time, log_op)
    VALUES (OLD.ticket_num, OLD.purchase_time, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			OLD.passanger_id, OLD.cost, OLD.drive_id, OLD.source_station, OLD.destination_station, OLD.departure_time, OLD.arrival_time, NOW(), 'DELETE');
END$$
DELIMITER ;