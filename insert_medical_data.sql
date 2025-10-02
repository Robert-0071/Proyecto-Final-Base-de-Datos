-- insert_medical_data.sql
USE medica_project;

INSERT INTO patients (patient_id, nombre, apellidos, telefono, email, fecha_nacimiento) VALUES
(1,'Mario','Vargas','5566778899','mario.vargas@example.com','1992-04-12 00:00:00'),
(2,'Ana','Ramirez','5544332211','ana.ramirez@example.com','1988-05-22 00:00:00'),
(3,'Luis','Torres','5511223344','luis.torres@example.com','1995-09-15 00:00:00'),
(4,'Carla','Gomez','5599881122','carla.gomez@example.com','1990-02-17 00:00:00'),
(5,'Ricardo','Lopez','5533445566','ricardo.lopez@example.com','1985-07-30 00:00:00'),
(6,'Elena','Martinez','5522113344','elena.martinez@example.com','1993-11-21 00:00:00'),
(7,'Jorge','Sanchez','5566998877','jorge.sanchez@example.com','1991-03-10 00:00:00'),
(8,'Sofia','Diaz','5544221100','sofia.diaz@example.com','1994-08-25 00:00:00'),
(9,'Andres','Cruz','5511442233','andres.cruz@example.com','1989-12-05 00:00:00'),
(10,'Valeria','Mendoza','5599001122','valeria.mendoza@example.com','1996-06-18 00:00:00');

INSERT INTO appointments (patient_id, medico_cita, especialidad_medico, fecha_cita, estado_cita, consultorio, diagnostico, tratamiento, observaciones_medicas, productos_comprados, total_venta, medio_venta)
VALUES
(1,'Carlos Hernandez','Cardiologia','2025-10-01 12:00:00','confirmada','Consultorio 1','Gripe','Reposo y líquidos','Paciente estable','Kit Prueba (2), Medicamento A (1)',350,'web'),
(2,'Elena Martinez','Dermatologia','2025-10-02 10:00:00','pendiente','Consultorio 2','Dermatitis','Crema tópica','Revisar seguimiento','Medicamento B (1), Vacuna X (1)',200,'app'),
(3,'Pedro Lopez','Neurologia','2025-10-03 09:00:00','completada','Consultorio 3','Migraña','Analgésicos','Paciente tolera tratamiento','Kit Prueba 2 (1), Pastilla Y (2)',450,'presencial'),
(4,'Marta Gomez','Pediatria','2025-10-04 11:00:00','cancelada','Consultorio 4','Otitis','Antibióticos','Sin complicaciones','Pastilla Z (1), Inyección A (1)',150,'web'),
(5,'Luis Ramirez','Oftalmologia','2025-10-05 13:00:00','confirmada','Consultorio 5','Cataratas','Cirugía programada','Paciente mayor','Crema C (2), Sueroterapia (1)',300,'app'),
(6,'Sofia Vargas','Ginecologia','2025-10-06 08:00:00','pendiente','Consultorio 6','Hipotiroidismo','Medicación diaria','Control cada 3 meses','Ninguno',250,'web'),
(7,'Jorge Diaz','Ortopedia','2025-10-07 15:00:00','completada','Consultorio 7','Fractura brazo','Fisioterapia','Recuperación buena','Ninguno',500,'presencial'),
(8,'Ana Torres','Endocrinologia','2025-10-08 14:00:00','confirmada','Consultorio 8','Embarazo','Control prenatal','Sin riesgo','Ninguno',100,'web'),
(9,'Ricardo Mendoza','Dermatologia','2025-10-09 16:00:00','pendiente','Consultorio 9','Alergia','Antihistamínicos','Evitar exposición','Ninguno',400,'app'),
(10,'Carla Sanchez','Cardiologia','2025-10-10 17:00:00','confirmada','Consultorio 10','Gastroenteritis','Hidratación','Paciente estable','Ninguno',350,'web');

-- Crear registros de ventas derivados
INSERT INTO sales (appointment_id, patient_id, total_amount, products, medio, sale_date)
SELECT appointment_id, patient_id, total_venta, productos_comprados, medio_venta, fecha_cita FROM appointments;

SELECT 'insert_medical_data.sql executed' AS info;
