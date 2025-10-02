-- create_medical_db.sql
-- Crea la base de datos y tablas para el proyecto "base de datos medica"
CREATE DATABASE IF NOT EXISTS medica_project CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE medica_project;

-- Tabla de pacientes
DROP TABLE IF EXISTS patients;
CREATE TABLE patients (
  patient_id INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  telefono VARCHAR(32),
  email VARCHAR(255) NOT NULL,
  fecha_nacimiento DATETIME,
  UNIQUE KEY uq_patients_email (email)
) ENGINE=InnoDB;

-- Tabla de appointments (citas)
DROP TABLE IF EXISTS appointments;
CREATE TABLE appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  medico_cita VARCHAR(150),
  especialidad_medico VARCHAR(100),
  fecha_cita DATETIME,
  estado_cita VARCHAR(50),
  consultorio VARCHAR(100),
  diagnostico TEXT,
  tratamiento TEXT,
  observaciones_medicas TEXT,
  productos_comprados TEXT,
  total_venta DECIMAL(10,2) DEFAULT 0.00,
  medio_venta VARCHAR(32),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla de sales (registro derivado de appointments)
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
  sale_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  patient_id INT NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  products TEXT,
  medio VARCHAR(32),
  sale_date DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Índices útiles
CREATE INDEX idx_appointments_date ON appointments(fecha_cita);
CREATE INDEX idx_sales_date ON sales(sale_date);

SELECT 'create_medical_db.sql executed' AS info;
