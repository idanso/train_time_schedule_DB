USE train_schedular;

INSERT INTO station VALUES
('Hahagana','tel aviv address'),
('Ad Halom','Ashdod address'),
('Hashalom','tel aviv address'),
('Yavne Maarav','Yavne address'),
('Lev Hamifratz','Haifa address'),
('Atlit', 'Atlit address'),
('Hadera Maarav', 'Hadera Address'),
('Huzot Hamifratz', 'Haifa Adress'),
('Naharya', 'Naharya Address'),
('Beer Sheva Mercaz', 'Beer Sheva Address'),
('Binyamina', 'Binyamina Address');

INSERT INTO single_stop_drive VALUES
(1,'Hahagana','Hashalom', 5, 15),
(2,'Hashalom','Lev Hamifratz', 45, 35),
(3,'Ad Halom','Yavne Maarav', 30, 20),
(4,'Yavne Maarav','Hahagana', 40, 50),
(5, 'Ad Halom', 'Hahagana', 60, 55),
(6, 'Hahagana', 'Lev Hamifratz', 45, 55),
(7, 'Beer Sheva Mercaz', 'Ad Halom', 35, 20),
(8, 'Hadera Maarav', 'Binyamina', 25, 10),
(9, 'Huzot Hamifratz', 'Naharya', 10, 5),
(10, 'Lev Hamifratz', 'Huzot Hamifratz', 5, 3),
(11, 'Binyamina', 'Lev Hamifratz', 20, 8),
(12, 'Binyamina', 'Atlit',10, 5),
(13, 'Atlit', 'Lev Hamifratz', 15, 10),
(14, 'Hashalom', 'Hadera Maarav', 40, 50),
(15, 'Hadera Maarav', 'Naharya', 90, 100),
(16, 'Beer Sheva Mercaz', 'Yavne Maarav', 100, 120);


INSERT INTO person VALUES
(316594811, 'idan', 'sorany'),
(804840660, 'gal', 'shiff'),
(485930276, 'dor', 'ingber'),
(175034276, 'or', 'asher'),
(530854135, 'jonathan', 'bitton');

INSERT INTO passanger VALUES
(316594811),
(804840660);

INSERT INTO driver VALUES
(485930276, 8),
(175034276, 15),
(530854135, 10);

INSERT INTO train VALUES
(1, 'avaliable', 250),
(2, 'avaliable', 400),
(3, 'avaliable', 300),
(4, 'maintainance', 400),
(5, 'out of order', 300);


INSERT INTO line VALUES
(1, 60),
(2, 90),
(3, 130),
(4, 120);


INSERT INTO lines_data VALUES
(1, 1, 7),
(1, 2, 3),
(1, 3, 4),
(1, 4, 1),
(1, 5, 2),
(1, 6, 10),
(1, 7, 9),
(2, 1, 5),
(2, 2, 1),
(2, 3, 14),
(2, 4, 15),
(3, 1, 5),
(3, 2, 1),
(3, 3, 14),
(3, 4, 8),
(3, 5, 12),
(3, 6, 13),
(3, 7, 10),
(3, 8, 9),
(4, 1, 16),
(4, 2, 4),
(4, 3, 1),
(4, 4, 14),
(4, 5, 15);

# creating drives according the input of lines, first departure time of day and a date 
CALL insert_drives_to_schedular_time_by_frequency(1, '07:00', '2021-06-16');
CALL insert_drives_to_schedular_time_by_frequency(2, '08:00', '2021-06-16');
CALL insert_drives_to_schedular_time_by_frequency(3, '06:00', '2021-06-16');
CALL insert_drives_to_schedular_time_by_frequency(4, '06:00', '2021-06-16');
CALL insert_drives_to_schedular_time_by_frequency(1, '05:00', '2021-06-17');
CALL insert_drives_to_schedular_time_by_frequency(2, '08:00', '2021-06-17');
CALL insert_drives_to_schedular_time_by_frequency(3, '10:00', '2021-06-17');
CALL insert_drives_to_schedular_time_by_frequency(4, '06:30', '2021-06-17');
CALL insert_drives_to_schedular_time_by_frequency(1, '05:00', '2021-06-18');
CALL insert_drives_to_schedular_time_by_frequency(2, '08:00', '2021-06-18');
CALL insert_drives_to_schedular_time_by_frequency(3, '10:00', '2021-06-18');
CALL insert_drives_to_schedular_time_by_frequency(4, '06:30', '2021-06-18');

# assighning a driver and train to a drive
UPDATE time_schedular
SET driver_id = 485930276, train_id = 1
WHERE drive_id = 1;

UPDATE time_schedular
SET driver_id = 175034276, train_id = 3
WHERE drive_id = 22;

UPDATE time_schedular
SET driver_id = 175034276, train_id = 1
WHERE drive_id = 56;

# creating a tickets
INSERT INTO ticket(purchase_time, cost, drive_id, source_station, destination_station, departure_time, arrival_time, passanger_id) VALUES
(NULL, NULL, 22, 'Ad Halom', 'Hashalom', '14:35:00', NULL, 316594811);

INSERT INTO ticket(purchase_time, cost, drive_id, source_station, destination_station, departure_time, arrival_time, passanger_id) VALUES
(NULL, NULL, 56, 'Ad Halom', 'Hashalom', '14:35:00', NULL, 804840660);

DELETE FROM ticket WHERE ticket_num = 1;

# creating a ticket again after deletion
INSERT INTO ticket(purchase_time, cost, drive_id, source_station, destination_station, departure_time, arrival_time, passanger_id) VALUES
(NULL, NULL, 22, 'Ad Halom', 'Hashalom', '14:35:00', NULL, 316594811);

UPDATE train SET avaliability = 'maintainance' WHERE train_id = 2;


