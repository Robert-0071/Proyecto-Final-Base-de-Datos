-- procedures_triggers_medical.sql
USE medica_project;

DELIMITER $$

-- Procedimiento: ventas diarias para medica_project
DROP PROCEDURE IF EXISTS daily_sales_medical$$
CREATE PROCEDURE daily_sales_medical(IN in_date DATE)
BEGIN
  SELECT s.sale_id, s.appointment_id, s.patient_id, s.total_amount, s.products, s.sale_date
  FROM sales s
  WHERE DATE(s.sale_date) = in_date;

  SELECT DATE(s.sale_date) AS day, COUNT(*) AS sales_count, SUM(s.total_amount) AS total_amount
  FROM sales s
  WHERE DATE(s.sale_date) = in_date
  GROUP BY DATE(s.sale_date);
END$$

-- Procedimiento: listar citas por estado
DROP PROCEDURE IF EXISTS listar_citas_por_estado$$
CREATE PROCEDURE listar_citas_por_estado(IN in_estado VARCHAR(50))
BEGIN
  SELECT a.appointment_id, a.patient_id, p.nombre, p.apellidos, a.fecha_cita, a.estado_cita, a.consultorio
  FROM appointments a
  JOIN patients p ON a.patient_id = p.patient_id
  WHERE a.estado_cita = in_estado
  ORDER BY a.fecha_cita;
END$$

-- Trigger: cuando se inserta una appointment con total_venta>0 y estado 'confirmada', crear entrada en sales
DROP TRIGGER IF EXISTS appointments_after_insert$$
CREATE TRIGGER appointments_after_insert
AFTER INSERT ON appointments
FOR EACH ROW
BEGIN
  IF NEW.total_venta IS NOT NULL AND NEW.total_venta > 0 AND NEW.estado_cita = 'confirmada' THEN
    INSERT INTO sales (appointment_id, patient_id, total_amount, products, medio, sale_date)
    VALUES (NEW.appointment_id, NEW.patient_id, NEW.total_venta, NEW.productos_comprados, NEW.medio_venta, NEW.fecha_cita);
  END IF;
END$$

-- Procedimiento: clientes del primer trimestre (1 enero - 31 marzo)
DROP PROCEDURE IF EXISTS clientes_primer_trimestre$$
CREATE PROCEDURE clientes_primer_trimestre()
BEGIN
  -- Lista pacientes que tuvieron al menos una venta entre 1-ene y 31-mar del año actual
  DECLARE start_dt DATE;
  DECLARE end_dt DATE;
  -- Evitar funciones no portables; construimos fechas con STR_TO_DATE
  SET start_dt = STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-01-01'), '%Y-%m-%d'); -- 1 de enero del año actual
  SET end_dt = STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-03-31'), '%Y-%m-%d'); -- 31 de marzo del año actual

  SELECT DISTINCT p.patient_id, p.nombre, p.apellidos, p.email, p.telefono
  FROM patients p
  JOIN sales s ON p.patient_id = s.patient_id
  WHERE DATE(s.sale_date) BETWEEN start_dt AND end_dt
  ORDER BY p.patient_id;
END$$

-- Procedimiento: agregar paciente con handler para email único (captura error 1062)
DROP PROCEDURE IF EXISTS add_patient_with_validation$$
CREATE PROCEDURE add_patient_with_validation(
  IN in_nombre VARCHAR(100),
  IN in_apellidos VARCHAR(100),
  IN in_email VARCHAR(255),
  IN in_telefono VARCHAR(50)
)
BEGIN
  DECLARE v_errno INT DEFAULT 0;
  DECLARE v_msg TEXT DEFAULT '';

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    -- Obtener el código de error y mensaje
    GET DIAGNOSTICS CONDITION 1
      v_errno = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
    IF v_errno = 1062 THEN
      SELECT 'El email esta duplicado, intente con otro email' AS message;
    ELSE
      SELECT CONCAT('Error al insertar paciente: ', v_msg) AS message;
    END IF;
  END;

  INSERT INTO patients (nombre, apellidos, email, telefono)
  VALUES (in_nombre, in_apellidos, in_email, in_telefono);
END$$

-- Trigger de control de inventario / duplicados sobre la tabla sales
-- Su objetivo: evitar insertar ventas duplicadas con el mismo appointment_id y patient_id
DROP TRIGGER IF EXISTS sales_before_insert$$
CREATE TRIGGER sales_before_insert
BEFORE INSERT ON sales
FOR EACH ROW
BEGIN
  IF NEW.appointment_id IS NOT NULL THEN
    IF EXISTS(SELECT 1 FROM sales s WHERE s.appointment_id = NEW.appointment_id AND s.patient_id = NEW.patient_id) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate sale detected for the same appointment and patient';
    END IF;
  END IF;
END$$

DELIMITER ;

-- Procedimiento opcional: clientes por periodo (parametrizable)
DELIMITER $$
DROP PROCEDURE IF EXISTS clientes_por_periodo$$
CREATE PROCEDURE clientes_por_periodo(IN p_start DATE, IN p_end DATE)
BEGIN
  SELECT DISTINCT p.patient_id, p.nombre, p.apellidos, p.email, p.telefono
  FROM patients p
  JOIN sales s ON p.patient_id = s.patient_id
  WHERE DATE(s.sale_date) BETWEEN p_start AND p_end
  ORDER BY p.patient_id;
END$$
DELIMITER ;


SELECT 'procedures_triggers_medical.sql executed' AS info;
