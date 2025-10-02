# Proyecto final - Base de datos médica (medica_project)

Este directorio contiene scripts para crear una base de datos simple de ejemplo a partir del archivo proporcionado por el usuario.

Archivos incluidos:

- `create_medical_db.sql` - DDL: crea la base `medica_project` y las tablas `patients`, `appointments`, `sales`.
- `insert_medical_data.sql` - INSERTs con los registros extraídos del archivo proporcionado; también crea filas en `sales` derivadas de `appointments` donde aplica.
- `procedures_triggers_medical.sql` - Procedimientos y triggers:
  - `daily_sales_medical(IN in_date DATE)` - lista ventas del día y un resumen de conteo y total.
  - `listar_citas_por_estado(IN in_estado VARCHAR(50))` - lista citas filtradas por estado.
  - Trigger `appointments_after_insert` - al insertar una cita 'confirmada' con `total_venta>0` crea una fila en `sales`.

Requisitos previos
- MySQL 5.7+ o 8.x
- Acceso a un cliente MySQL (Workbench, mysql CLI, o similar)

Pasos rápidos (MySQL Workbench o mysql CLI)

1) Abrir una conexión al servidor MySQL y ejecutar en este orden:

   - `create_medical_db.sql`
   - `insert_medical_data.sql`
   - `procedures_triggers_medical.sql`

   En Workbench puedes abrir cada archivo y ejecutar todo (botón de rayo) o copiar/pegar en un script. Si usas `mysql` por línea de comandos:

   mysql -u root -p < "create_medical_db.sql"
   mysql -u root -p medica_project < "insert_medical_data.sql"
   mysql -u root -p medica_project < "procedures_triggers_medical.sql"

2) Probar el procedimiento de ventas diarias (ejemplo):

   CALL daily_sales_medical('2024-09-30');

   Esto devolverá primero el detalle de ventas del día y luego un resumen con `sales_count` y `total_amount`.

3) Probar listado de citas por estado:

   CALL listar_citas_por_estado('confirmada');

4) Verificar el trigger insertando una cita confirmada con `total_venta > 0`:

   INSERT INTO appointments (patient_id, fecha_cita, estado_cita, total_venta, productos_comprados, medio_venta, consultorio)
   VALUES (1, '2024-10-01 09:30:00', 'confirmada', 150.00, 'analisis sanguineo', 'tarjeta', 'Consultorio A');

   SELECT * FROM sales WHERE appointment_id IS NOT NULL ORDER BY sale_date DESC LIMIT 5;

Notas y consejos
- Si tu servidor no soporta `ADD COLUMN IF NOT EXISTS`, revisa que los scripts de creación funcionen en orden; el `insert_medical_data.sql` asume las columnas definidas en `create_medical_db.sql`.
- Si usas MySQL Workbench y obtienes el error 1175 (safe updates) durante pruebas con UPDATE, añade `LIMIT` a la actualización o desactiva temporalmente safe-updates desde las preferencias.

Soporte adicional
Si quieres que adapte la app Java existente para conectarse a `medica_project` o generar un pequeño cliente Java para consultas médicas, dime y lo añado dentro de `proyecto final/`.

Java - cliente JDBC (opcional)
---------------------------------
He incluido un cliente Java mínimo en `proyecto final/java-medical` que se conecta a `medica_project` y ofrece un menú CLI para Crear/Actualizar/Eliminar pacientes y para ejecutar el reporte `clientes_primer_trimestre` (Read).

Pasos para compilar y ejecutar (Windows PowerShell):

1) Abrir PowerShell y moverse a la carpeta del proyecto Java:

   cd "c:\Users\ianca\Downloads\\proyecto final\java-medical"

2) Construir el JAR con dependencias usando Maven (necesitas tener `mvn` en PATH y Java 17):

   mvn clean package

   Al final se generará un JAR tipo "jar-with-dependencies" en `target/`.

3) Ejecutar el JAR (ajusta usuario/contraseña dentro del archivo `Main.java` o añade parámetros según prefieras):

   java -jar target/medical-client-1.0-SNAPSHOT-jar-with-dependencies.jar

Uso del cliente Java (ejemplos):
- Elegir 1 para crear paciente. El procedimiento `add_patient_with_validation` manejará el error si el email está duplicado.
- Elegir 4 para listar los clientes que compraron en el primer trimestre del año.

Notas:
- Asegúrate de actualizar las constantes URL/USER/PASS en `Main.java` si tu servidor usa credenciales distintas.
- El código es intencionalmente mínimo para facilitar revisión y adaptación. Puedo ampliar validaciones, externalizar configuración o añadir más CRUD si lo deseas.

---

