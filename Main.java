package app.medical;

import java.io.InputStream;
import java.util.Properties;
import java.sql.*;
import java.util.Scanner;

public class Main {
    private static String URL; 
    private static String USER;
    private static String PASS;

    public static void main(String[] args) throws Exception {
        loadConfig();
        try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {
            System.out.println("Conectado a medica_project");
            runMenu(conn);
        } catch (SQLException e) {
            System.err.println("Error de conexion: " + e.getMessage());
        }
    }

    private static void loadConfig() throws Exception {
        // First, allow overrides via system properties (java -Djdbc.url=...) or environment variables
        URL = System.getProperty("jdbc.url");
        USER = System.getProperty("jdbc.user");
        PASS = System.getProperty("jdbc.pass");

        if (URL == null) {
            // try environment variables
            URL = System.getenv("JDBC_URL");
            USER = System.getenv("JDBC_USER");
            PASS = System.getenv("JDBC_PASS");
        }

        if (URL == null) {
            Properties p = new Properties();
            try (InputStream in = Main.class.getResourceAsStream("/db.properties")) {
                if (in == null) throw new Exception("No se encontro db.properties en resources");
                p.load(in);
            }
            URL = p.getProperty("jdbc.url");
            USER = p.getProperty("jdbc.user");
            PASS = p.getProperty("jdbc.pass");
        }
    }

    private static void runMenu(Connection conn) throws SQLException {
        Scanner sc = new Scanner(System.in);
        while (true) {
            System.out.println("\nMenu:\n1) Crear paciente\n2) Actualizar paciente\n3) Eliminar paciente\n4) Reporte - clientes primer trimestre\n5) Salir\n6) Crear appointment\n7) Crear sale\n8) Listar appointments\n9) Listar sales\n10) Actualizar appointment estado\n11) Eliminar sale\n12) Reporte - clientes por periodo");
            System.out.print("Opcion: ");
            String opt = sc.nextLine().trim();
            switch (opt) {
                case "1": createPatient(conn, sc); break;
                case "2": updatePatient(conn, sc); break;
                case "3": deletePatient(conn, sc); break;
                case "6": createAppointment(conn, sc); break;
                case "7": createSale(conn, sc); break;
                case "8": listAppointments(conn); break;
                case "9": listSales(conn); break;
                case "10": updateAppointmentStatus(conn, sc); break;
                case "11": deleteSale(conn, sc); break;
                case "4": callClientesPrimerTrimestre(conn); break;
                case "12": callClientesPorPeriodo(conn, sc); break;
                case "5": System.out.println("Saliendo..."); return;
                default: System.out.println("Opcion invalida");
            }
        }
    }

    private static void listAppointments(Connection conn) {
        String sql = "SELECT appointment_id, patient_id, fecha_cita, estado_cita, total_venta FROM appointments ORDER BY fecha_cita DESC LIMIT 200";
        try (Statement st = conn.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            System.out.println("Appointments:");
            while (rs.next()) {
                System.out.printf("%d | patient %d | %s | %s | %.2f\n",
                        rs.getInt("appointment_id"), rs.getInt("patient_id"), rs.getString("fecha_cita"), rs.getString("estado_cita"), rs.getDouble("total_venta"));
            }
        } catch (SQLException e) {
            System.err.println("Error listar appointments: " + e.getMessage());
        }
    }

    private static void listSales(Connection conn) {
        String sql = "SELECT sale_id, appointment_id, patient_id, total_amount, sale_date FROM sales ORDER BY sale_date DESC LIMIT 200";
        try (Statement st = conn.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            System.out.println("Sales:");
            while (rs.next()) {
                System.out.printf("%d | appt %s | patient %d | %.2f | %s\n",
                        rs.getInt("sale_id"), rs.getObject("appointment_id"), rs.getInt("patient_id"), rs.getDouble("total_amount"), rs.getString("sale_date"));
            }
        } catch (SQLException e) {
            System.err.println("Error listar sales: " + e.getMessage());
        }
    }

    private static void updateAppointmentStatus(Connection conn, Scanner sc) {
        try {
            System.out.print("ID appointment: "); int id = Integer.parseInt(sc.nextLine());
            System.out.print("Nuevo estado: "); String estado = sc.nextLine();
            String sql = "UPDATE appointments SET estado_cita = ? WHERE appointment_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, estado);
                ps.setInt(2, id);
                int r = ps.executeUpdate();
                System.out.println("Filas afectadas: " + r);
            }
        } catch (SQLException e) {
            System.err.println("Error actualizar appointment: " + e.getMessage());
        }
    }

    private static void deleteSale(Connection conn, Scanner sc) {
        try {
            System.out.print("ID sale a eliminar: "); int id = Integer.parseInt(sc.nextLine());
            String sql = "DELETE FROM sales WHERE sale_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, id);
                int r = ps.executeUpdate();
                System.out.println("Filas eliminadas: " + r);
            }
        } catch (SQLException e) {
            System.err.println("Error al eliminar sale: " + e.getMessage());
        }
    }

    private static void createPatient(Connection conn, Scanner sc) {
        try {
            System.out.print("Nombre: "); String nombre = sc.nextLine();
            System.out.print("Apellidos: "); String apellidos = sc.nextLine();
            System.out.print("Email: "); String email = sc.nextLine();
            System.out.print("Telefono: "); String telefono = sc.nextLine();

            String sql = "CALL add_patient_with_validation(?,?,?,?)";
            try (CallableStatement cs = conn.prepareCall(sql)) {
                cs.setString(1, nombre);
                cs.setString(2, apellidos);
                cs.setString(3, email);
                cs.setString(4, telefono);
                cs.execute();
                System.out.println("Procedimiento ejecutado (verifique mensajes de handler si hubo errores)");
            }
        } catch (SQLException e) {
            System.err.println("Error al crear paciente: " + e.getMessage());
        }
    }

    private static void updatePatient(Connection conn, Scanner sc) {
        try {
            System.out.print("ID paciente a actualizar: "); int id = Integer.parseInt(sc.nextLine());
            System.out.print("Nuevo telefono: "); String tel = sc.nextLine();
            String sql = "UPDATE patients SET telefono = ? WHERE patient_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, tel);
                ps.setInt(2, id);
                int r = ps.executeUpdate();
                System.out.println("Filas afectadas: " + r);
            }
        } catch (SQLException e) {
            System.err.println("Error al actualizar paciente: " + e.getMessage());
        }
    }

    private static void deletePatient(Connection conn, Scanner sc) {
        try {
            System.out.print("ID paciente a eliminar: "); int id = Integer.parseInt(sc.nextLine());
            String sql = "DELETE FROM patients WHERE patient_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, id);
                int r = ps.executeUpdate();
                System.out.println("Filas eliminadas: " + r);
            }
        } catch (SQLException e) {
            System.err.println("Error al eliminar paciente: " + e.getMessage());
        }
    }

    private static void createAppointment(Connection conn, Scanner sc) {
        try {
            System.out.print("Patient ID: "); int pid = Integer.parseInt(sc.nextLine());
            System.out.print("Fecha cita (YYYY-MM-DD HH:MM:SS): "); String fecha = sc.nextLine();
            System.out.print("Estado (pendiente/confirmada/cancelada): "); String estado = sc.nextLine();
            System.out.print("Total venta (0 si none): "); double total = Double.parseDouble(sc.nextLine());
            System.out.print("Productos comprados: "); String productos = sc.nextLine();
            System.out.print("Medio venta: "); String medio = sc.nextLine();
            System.out.print("Consultorio: "); String consultorio = sc.nextLine();

            String sql = "INSERT INTO appointments (patient_id, fecha_cita, estado_cita, total_venta, productos_comprados, medio_venta, consultorio) VALUES (?,?,?,?,?,?,?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, pid);
                ps.setString(2, fecha);
                ps.setString(3, estado);
                ps.setDouble(4, total);
                ps.setString(5, productos);
                ps.setString(6, medio);
                ps.setString(7, consultorio);
                int r = ps.executeUpdate();
                System.out.println("Appointment inserted rows: " + r);
            }
        } catch (SQLException e) {
            System.err.println("Error crear appointment: " + e.getMessage());
        }
    }

    private static void createSale(Connection conn, Scanner sc) {
        try {
            System.out.print("Appointment ID (or 0): "); int aid = Integer.parseInt(sc.nextLine());
            System.out.print("Patient ID: "); int pid = Integer.parseInt(sc.nextLine());
            System.out.print("Total amount: "); double total = Double.parseDouble(sc.nextLine());
            System.out.print("Products: "); String products = sc.nextLine();
            System.out.print("Medio: "); String medio = sc.nextLine();
            System.out.print("Sale date (YYYY-MM-DD HH:MM:SS): "); String sdate = sc.nextLine();

            String sql = "INSERT INTO sales (appointment_id, patient_id, total_amount, products, medio, sale_date) VALUES (?,?,?,?,?,?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                if (aid == 0) ps.setNull(1, Types.INTEGER); else ps.setInt(1, aid);
                ps.setInt(2, pid);
                ps.setDouble(3, total);
                ps.setString(4, products);
                ps.setString(5, medio);
                ps.setString(6, sdate);
                int r = ps.executeUpdate();
                System.out.println("Sale inserted rows: " + r);
            }
        } catch (SQLException e) {
            System.err.println("Error crear sale: " + e.getMessage());
        }
    }

    private static void callClientesPrimerTrimestre(Connection conn) {
        try (CallableStatement cs = conn.prepareCall("CALL clientes_primer_trimestre()")) {
            boolean has = cs.execute();
            if (has) {
                try (ResultSet rs = cs.getResultSet()) {
                    System.out.println("Clientes primer trimestre:");
                    while (rs.next()) {
                        System.out.printf("%d - %s %s - %s - %s\n",
                                rs.getInt("patient_id"), rs.getString("nombre"), rs.getString("apellidos"), rs.getString("email"), rs.getString("telefono"));
                    }
                }
            } else {
                System.out.println("El procedimiento no devolvio resultset");
            }
        } catch (SQLException e) {
            System.err.println("Error al ejecutar reporte: " + e.getMessage());
        }
    }

    private static void callClientesPorPeriodo(Connection conn, Scanner sc) {
        try {
            System.out.print("Fecha inicio (YYYY-MM-DD): ");
            String start = sc.nextLine().trim();
            System.out.print("Fecha fin (YYYY-MM-DD): ");
            String end = sc.nextLine().trim();

            try (CallableStatement cs = conn.prepareCall("CALL clientes_por_periodo(?,?)")) {
                cs.setString(1, start);
                cs.setString(2, end);
                boolean has = cs.execute();
                if (has) {
                    try (ResultSet rs = cs.getResultSet()) {
                        System.out.println("Clientes por periodo:");
                        while (rs.next()) {
                            System.out.printf("%d - %s %s - %s - %s\n",
                                    rs.getInt("patient_id"), rs.getString("nombre"), rs.getString("apellidos"), rs.getString("email"), rs.getString("telefono"));
                        }
                    }
                } else {
                    System.out.println("El procedimiento no devolvio resultset");
                }
            }
        } catch (SQLException e) {
            System.err.println("Error al ejecutar clientes_por_periodo: " + e.getMessage());
        }
    }

}
