Avance del proyecto — cumplimiento de los requisitos
--------------------------------------------------
Esta sección documenta puntualmente lo que pide la consigna del avance: consultas avanzadas (2 por cada estructura indicada), dos procedimientos almacenados (ventas diarias y clientes Q1), manejo de excepción por restricción única mediante HANDLER, dos triggers (control inventario y seguimiento clientes) y ejemplos de CRUD desde Java (JDBC).

1) Consultas avanzadas (dos por cada estructura)
   - Archivo sugerido: `sql/queries_advanced.sql`

   A) JOIN (2 ejemplos)
   -- 1) Detalle de compras con datos de usuario (INNER JOIN)
   SELECT p.purchase_id, p.user_id, u.country, u.device_type, p.amount, p.purchase_date
   FROM purchases p
   JOIN users u ON p.user_id = u.user_id
   WHERE p.purchase_date BETWEEN '2025-10-01' AND '2025-10-10';

   -- 2) Usuarios y su último pedido (LEFT JOIN + subconsulta)
   SELECT u.user_id, u.country, last_p.last_date
   FROM users u
   LEFT JOIN (
     SELECT user_id, MAX(purchase_date) AS last_date FROM purchases GROUP BY user_id
   ) last_p ON u.user_id = last_p.user_id
   ORDER BY last_p.last_date DESC;

   B) UNION (2 ejemplos)
   -- 1) Unir emails de customers y users (mismo formato)
   SELECT email FROM customers
   UNION
   SELECT CONCAT(user_id,'@no-email.local') AS email FROM users WHERE email IS NULL LIMIT 100;

   -- 2) Union de canales de compra y dispositivos (para análisis simple)
   SELECT DISTINCT channel AS source FROM purchases
   UNION
   SELECT DISTINCT device_type AS source FROM users;

   C) ORDER BY (2 ejemplos)
   -- 1) Compras ordenadas por fecha descendente
   SELECT * FROM purchases ORDER BY purchase_date DESC LIMIT 50;

   -- 2) Usuarios ordenados por country asc y por age desc
   SELECT user_id, country, age FROM users ORDER BY country ASC, age DESC LIMIT 100;

   D) GROUP BY (2 ejemplos)
   -- 1) Total de ventas por día (GROUP BY DATE)
   SELECT DATE(purchase_date) AS day, COUNT(*) AS sales_count, SUM(amount) AS total_amount
   FROM purchases
   GROUP BY DATE(purchase_date)
   ORDER BY day DESC;

   -- 2) Ventas totales por country
   SELECT u.country, COUNT(*) AS sales_count, SUM(p.amount) AS total_amount
   FROM purchases p
   JOIN users u ON p.user_id = u.user_id
   GROUP BY u.country
   ORDER BY total_amount DESC;

   E) Manipulación de fechas / time (2 ejemplos)
   -- 1) Buscar compras hechas en los últimos 7 días
   SELECT * FROM purchases WHERE purchase_date >= NOW() - INTERVAL 7 DAY ORDER BY purchase_date DESC;

   -- 2) Extraer año/mes y agrupar ventas por mes del año actual
   SELECT YEAR(purchase_date) AS y, MONTH(purchase_date) AS m, SUM(amount) AS total
   FROM purchases
   WHERE YEAR(purchase_date) = YEAR(CURDATE())
   GROUP BY y, m ORDER BY y, m;

   Nota sobre pruebas: para cada consulta ejecuta en Workbench y toma dos capturas: (1) código SQL y (2) grid result con filas. Guarda en `evidence/`.

2) Procedimiento almacenado: Ventas diarias (daily_sales)
   - Archivo sugerido: `proyecto final/procedures_triggers_medical.sql` (ya incluye una versión). Código de ejemplo:

-- DROP PROCEDURE IF EXISTS daily_sales_medical;
CREATE PROCEDURE daily_sales_medical(IN in_date DATE)
BEGIN
  -- detalle
  SELECT s.sale_id, s.appointment_id, s.patient_id, s.total_amount, s.products, s.sale_date
  FROM sales s
  WHERE DATE(s.sale_date) = in_date;

  -- resumen
  SELECT DATE(s.sale_date) AS day, COUNT(*) AS sales_count, SUM(s.total_amount) AS total_amount
  FROM sales s
  WHERE DATE(s.sale_date) = in_date
  GROUP BY DATE(s.sale_date);
END;

   Prueba: `CALL daily_sales_medical('2025-10-06');` — captura código y los dos resultsets (detalle y resumen).

3) Procedimiento almacenado: Clientes del primer trimestre
   - Archivo sugerido: mismo de procedimientos. Implementación (ejemplo con año actual):

-- DROP PROCEDURE IF EXISTS clientes_primer_trimestre;
CREATE PROCEDURE clientes_primer_trimestre()
BEGIN
  DECLARE start_dt DATE;
  DECLARE end_dt DATE;
  SET start_dt = STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-01-01'), '%Y-%m-%d');
  SET end_dt = STR_TO_DATE(CONCAT(YEAR(CURDATE()), '-03-31'), '%Y-%m-%d');

  SELECT DISTINCT c.customer_id, c.name, c.email, c.created_at
  FROM customers c
  JOIN purchases p ON c.user_id = p.user_id
  WHERE DATE(p.purchase_date) BETWEEN start_dt AND end_dt
  ORDER BY c.customer_id;
END;

   Prueba: `CALL clientes_primer_trimestre();` — captura resultado.

4) Excepción de restricción única (handler en procedimiento)
   - Objetivo: detectar error 1062 y devolver mensaje personalizado.
   - Ejemplo (archivo de procedimientos):

-- DROP PROCEDURE IF EXISTS agregar_cliente_con_validacion;
CREATE PROCEDURE agregar_cliente_con_validacion(
  IN p_user_id INT,
  IN p_name VARCHAR(100),
  IN p_email VARCHAR(255)
)
BEGIN
  DECLARE v_errno INT DEFAULT 0;
  DECLARE v_msg TEXT DEFAULT '';

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_errno = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
    IF v_errno = 1062 THEN
      SELECT 'El email esta duplicado, intente con otro email' AS message;
    ELSE
      SELECT CONCAT('Error al insertar cliente: ', v_msg) AS message;
    END IF;
  END;

  INSERT INTO customers (user_id, name, email, created_at)
  VALUES (p_user_id, p_name, p_email, NOW());
END;

   Prueba:
   - `CALL agregar_cliente_con_validacion(1, 'Prueba', 'dup@example.com');` (primera vez OK)
   - `CALL agregar_cliente_con_validacion(2, 'Prueba2', 'dup@example.com');` -> debe devolver: "El email esta duplicado, intente con otro email".

5) Trigger de control de inventario (evitar duplicados)
   - Ejemplo de trigger (archivo de procedimientos/triggers):

-- DROP TRIGGER IF EXISTS inventory_before_insert;
CREATE TRIGGER inventory_before_insert
BEFORE INSERT ON inventory
FOR EACH ROW
BEGIN
  IF EXISTS(SELECT 1 FROM inventory i WHERE i.sku = NEW.sku) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SKU duplicado: no se puede insertar';
  END IF;
END;

   Prueba: intentar insertar dos filas con mismo `sku` y capturar el error en Workbench.

6) Trigger de seguimiento a clientes (purchases -> customer_followups)
   - Ejemplo:

-- DROP TRIGGER IF EXISTS purchases_after_insert;
CREATE TRIGGER purchases_after_insert
AFTER INSERT ON purchases
FOR EACH ROW
BEGIN
  IF NEW.channel IN ('Web','Mobile') THEN
    INSERT INTO customer_followups (user_id, full_name, followup_time, note)
    VALUES (NEW.user_id, CONCAT('User_', NEW.user_id), NEW.purchase_date, CONCAT('Followup for channel: ', NEW.channel));
  END IF;
END;

   Prueba: `INSERT INTO purchases (user_id, amount, purchase_date, channel) VALUES (1, 99.99, NOW(), 'Web');` — luego `SELECT * FROM customer_followups` para ver el nuevo registro.

7) CRUD desde Java (JDBC) — ejemplos concretos
   - Archivo: `java-medical/src/main/java/app/medical/Main.java` contiene la implementación. Aquí ejemplos de cómo hacerlo en Java:

  A) Crear (INSERT) — crear appointment (fragmento):
  ```java
  String sql = "INSERT INTO appointments (patient_id, fecha_cita, estado_cita, total_venta, productos_comprados, medio_venta, consultorio) VALUES (?,?,?,?,?,?,?)";
  try (PreparedStatement ps = conn.prepareStatement(sql)){
    ps.setInt(1, pid);
    ps.setString(2, fecha);
    ps.setString(3, estado);
    ps.setDouble(4, total);
    ps.setString(5, productos);
    ps.setString(6, medio);
    ps.setString(7, consultorio);
    ps.executeUpdate();
  }
  ```

  B) Leer (SELECT) — listar sales (fragmento):
  ```java
  try (Statement st = conn.createStatement(); ResultSet rs = st.executeQuery("SELECT sale_id, patient_id, total_amount, sale_date FROM sales ORDER BY sale_date DESC LIMIT 50")){
    while(rs.next()){ System.out.println(rs.getInt("sale_id") + " " + rs.getDouble("total_amount")); }
  }
  ```

  C) Actualizar (UPDATE) — ejemplo cambiar estado de appointment:
  ```java
  String sql = "UPDATE appointments SET estado_cita = ? WHERE appointment_id = ?";
  try (PreparedStatement ps = conn.prepareStatement(sql)){
    ps.setString(1, nuevoEstado);
    ps.setInt(2, appointmentId);
    ps.executeUpdate();
  }
  ```

  D) Eliminar (DELETE):
  ```java
  String sql = "DELETE FROM sales WHERE sale_id = ?";
  try (PreparedStatement ps = conn.prepareStatement(sql)){
    ps.setInt(1, saleId);
    ps.executeUpdate();
  }
  ```

  E) Llamar procedimiento (R) — clientes primer trimestre
  ```java
  try (CallableStatement cs = conn.prepareCall("CALL clientes_primer_trimestre()")){
    boolean has = cs.execute();
    if(has){ try (ResultSet rs = cs.getResultSet()) { while(rs.next()){ /* leer columnas */ } } }
  }
  ```

   Nota: la aplicación `Main.java` ya incorpora un menú con estas opciones; documenta en la entrega que se usó la app para la parte interactiva.

8) Capturas y evidencias específicas (lista de comandos para ejecutar y capturar en Workbench)
   - Ejecuta y captura cada consulta avanzada del punto 1 (código + resultado).
   - Ejecuta y captura los `CALL daily_sales_medical(...)` y `CALL clientes_primer_trimestre()`.
   - Ejecuta el `CALL agregar_cliente_con_validacion(...)` para mostrar el mensaje de error por duplicado.
   - Inserta un `purchase` por Web/Mobile y captura `SELECT * FROM customer_followups;` antes y después.
   - Inserta duplicado en `inventory` y captura el error del trigger.
   - Ejecuta la app Java y captura la consola cuando:
     * Creas (Create) una entidad (appointment o sale).
     * Actualizas un registro (Update).
     * Eliminás un registro (Delete).
     * Llamas al reporte Q1 desde la app (R).

9) Ubicación recomendada de archivos entregables
   - `sql/queries_advanced.sql` — todas las consultas avanzadas que ejecutaste.
   - `proyecto final/procedures_triggers_medical.sql` — procedimientos y triggers (ya incluidos).
   - `java-medical/` — código fuente del cliente Java (Main.java y db.properties).
   - `evidence/` — capturas (nombra con prefijo numérico para ordenarlas).

10) Observaciones finales
   - MySQL usa HANDLERS en lugar de TRY/CATCH; se usó `GET DIAGNOSTICS` para obtener el código y mensaje dentro del handler.
   - Asegúrate de ejecutar las consultas con rangos de fecha que correspondan a tus datos de prueba (los ejemplos usan fechas de octubre de 2025 porque los datos de ejemplo fueron insertados en ese mes).

Con esto queda documentado paso a paso cómo cumplir los puntos 1..8 de la consigna. Si quieres, puedo:
- Generar el archivo `sql/queries_advanced.sql` con todas las consultas arriba (para que solo lo ejecutes en Workbench). ¿Lo creo? 
- Crear un script PowerShell en `proyecto final/scripts` que ejecute las pruebas y capture salidas (limitado por el entorno). 
