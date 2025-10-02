-- sql_examples_medical.sql
USE medica_project;

-- =====================================
-- JOIN examples (2)
-- 1) INNER JOIN: listar ventas con datos del paciente
SELECT s.sale_id, s.sale_date, s.total_amount, p.patient_id, p.nombre, p.apellidos
FROM sales s
INNER JOIN patients p ON s.patient_id = p.patient_id
ORDER BY s.sale_date DESC;

-- 2) LEFT JOIN: listar todas las citas y, si existe, la venta asociada
SELECT a.appointment_id, a.fecha_cita, a.estado_cita, p.nombre, s.sale_id, s.total_amount
FROM appointments a
LEFT JOIN patients p ON a.patient_id = p.patient_id
LEFT JOIN sales s ON s.appointment_id = a.appointment_id
ORDER BY a.fecha_cita ASC;

-- =====================================
-- UNION examples (2)
-- 1) UNION: combinar nombres de pacientes y nombres de doctores ficticios (ejemplo)
SELECT patient_id AS id, nombre AS name, 'paciente' AS role FROM patients
UNION
SELECT NULL AS id, 'Dr. Ejemplo' AS name, 'doctor' AS role
ORDER BY name;

-- 2) UNION ALL: combinar emails y telefonos en una sola lista (permitir duplicados)
SELECT email AS contact FROM patients WHERE email IS NOT NULL
UNION ALL
SELECT telefono AS contact FROM patients WHERE telefono IS NOT NULL;

-- =====================================
-- ORDER BY examples (2)
-- 1) Ordenar pacientes por apellidos ascendente
SELECT patient_id, nombre, apellidos FROM patients ORDER BY apellidos ASC, nombre ASC;

-- 2) Ordenar ventas por monto descendente
SELECT sale_id, patient_id, total_amount FROM sales ORDER BY total_amount DESC LIMIT 10;

-- =====================================
-- GROUP BY examples (2)
-- 1) Contar ventas por paciente
SELECT p.patient_id, p.nombre, p.apellidos, COUNT(s.sale_id) AS ventas_count, COALESCE(SUM(s.total_amount),0) AS total
FROM patients p
LEFT JOIN sales s ON p.patient_id = s.patient_id
GROUP BY p.patient_id, p.nombre, p.apellidos
ORDER BY total DESC;

-- 2) Ventas por medio (tarjeta, efectivo, etc.)
SELECT medio, COUNT(*) AS ventas, SUM(total_amount) AS total_monto
FROM sales
GROUP BY medio
ORDER BY total_monto DESC;

-- =====================================
-- Date/time manipulation examples (2)
-- 1) Ventas del mes actual
SELECT * FROM sales WHERE YEAR(sale_date) = YEAR(CURDATE()) AND MONTH(sale_date) = MONTH(CURDATE());

-- 2) Ventas entre dos fechas (ejemplo parametrizable)
SELECT * FROM sales WHERE DATE(sale_date) BETWEEN '2024-01-01' AND '2024-03-31' ORDER BY sale_date;

-- Fin de ejemplos
