import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;
import java.sql.*;
import java.util.*;

class LoginTest {
  public static void main(String args[]) throws Exception {
    OracleDataSource ods = new OracleDataSource();
    Properties props = new Properties();
    ods.setURL("jdbc:oracle:thin:@//" + args[2]);
    ods.setUser(args[0]);
    ods.setPassword(args[1]);
    ods.setConnectionProperties(props);
    Connection conn = ods.getConnection();

    // Create a Statement
    Statement stmt = conn.createStatement();

    String[] Queries = {
        "SELECT '-DB_NAME               : '||sys_context('userenv','db_name') FROM dual",
        "SELECT '-INSTANCE_NAME         : '||sys_context('userenv','instance_name') FROM dual",
        "SELECT '-SERVER_HOST           : '||sys_context('userenv','server_host') FROM dual",
        "SELECT '-SESSION_USER          : '||sys_context('userenv','session_user') FROM dual",
        "SELECT '-PROXY_USER            : '||sys_context('userenv','proxy_user') FROM dual",
        "SELECT '-AUTHENTICATION_METHOD : '||sys_context('userenv','authentication_method') FROM dual",
        "SELECT '-IDENTIFICATION_TYPE   : '||sys_context('userenv','identification_type') FROM dual",
        "SELECT '-NETWORK_PROTOCOL      : '||sys_context('userenv','network_protocol') FROM dual",
        "SELECT '-OS_USER               : '||sys_context('userenv','os_user') FROM dual",
        "SELECT '-AUTHENTICATED_IDENTITY: '||sys_context('userenv','authenticated_identity') FROM dual",
        "SELECT '-ENTERPRISE_IDENTITY   : '||sys_context('userenv','enterprise_identity') FROM dual",
        "SELECT '-ISDBA                 : '||sys_context('userenv','isdba') FROM dual",
        "SELECT '-CLIENT_INFO           : '||sys_context('userenv','client_info') FROM dual",
        "SELECT '-IP_ADDRESS            : '||sys_context('userenv','ip_address') FROM dual",
        "SELECT '-HOST                  : '||sys_context('userenv','host') FROM dual",
        "SELECT '---------------------------------------------------------' FROM dual",
        "SELECT NETWORK_SERVICE_BANNER FROM v$session_connect_info where sid = (SELECT sys_context('userenv','sid') FROM dual)" };

    System.out.println();
    System.out.println("Database Information");
    System.out
        .println("---------------------------------------------------------");
    for (String Query : Queries) {
      ResultSet rset = stmt.executeQuery(Query);
      while (rset.next())
        System.out.println(rset.getString(1));
      rset.close();
    }

    System.out.println();

    stmt.close();
    conn.close();
  }
}
