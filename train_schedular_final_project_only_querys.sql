USE train_schedular;

#call for procedure:
#	input:
#		1- wanted source station CHAR(25)
#		2- wanted destination station CHAR(25)
#		3- wanted time to departure travel TIME
#		4- wanted date to departure travel DATE
#	output:
#		table with line_id and departure time for all lines that contain the wanted travel (from source to destination)
#		with their time of leaving the station and arrival time to destenation station
CALL giving_relevent_lines_by_stations_and_departure_time('Ad Halom', 'Hashalom', '14:10', '2021-06-16');
CALL giving_relevent_lines_by_stations_and_departure_time('Ad Halom', 'Hashalom', '14:10', '2021-06-17');
CALL giving_relevent_lines_by_stations_and_departure_time('Hahagana', 'Naharya', '12:00', '2021-06-18');

# Show all Tickets
SELECT * FROM ticket;

# show all drives in time_schedular
SELECT * FROM time_schedular;

# Show details of specific drive
SELECT * FROM time_schedular WHERE drive_id = 22;

# a dynamic procedure that return sum of column (cost or duration) between 2 stations for specific line (tried to implement it inside trigers to shorten the triggers but with no success) 
CALL get_sum_of_column_between_stations_for_line(1, 'Ad Halom', 'Hashalom', 'cost');
SELECT @OUT_VAR AS 'cost';

CALL get_sum_of_column_between_stations_for_line(1, 'Ad Halom', 'Hashalom', 'drive_duration');
SELECT @OUT_VAR AS 'drive duration';

# Get all drives that no one purchased a ticket to and a train Is assigned to
SELECT DISTINCT time_schedular.* FROM time_schedular, train
WHERE time_schedular.train_id IS NOT NULL AND time_schedular.avaliable_seats = train.num_of_seats;

# Logs
SELECT * FROM train_logs ORDER BY log_time DESC;
SELECT * FROM time_schedular_logs ORDER BY log_time DESC;
SELECT * FROM ticket_logs ORDER BY log_time DESC;

