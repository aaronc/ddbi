module dbi.mysql.MysqlDatabase;

import std.string;
import dbi.BaseDatabase, dbi.Result, dbi.Row, dbi.Exception;
import dbi.mysql.imp, dbi.mysql.MysqlResult;

/**
   Class: MysqlDatabase

   Manage a MySQL database connection. This class implements all of the
   current DBD interface as defined in <Database>.

   Limitations:

   <MysqlDatabase> currently does not retrieve column types.

   See Also:

   <BaseDatabase>, <Database>
*/
class MysqlDatabase : BaseDatabase {
  this() {}

  /**
     Function: connect

     Connect to a database on a MySQL server

     Keywords:
     
       host - hostname
     dbname - database name

     Example:
     
     (start code)
     MysqlDatabase db = new MysqlDatabase();
     db.connect("host=localhost;dbname=test", "username", "password");
     (end code)
  */
  int connect(char[] conn, char[] user=null, char[] passwd=null) {
    char[] host   = "localhost";
    char[] dbname = "test";
    char[] sock   = null;
    uint   port   = 0;

    if (conn.find("=")) {
      char[][char[]] keywords = getKeywords(conn);
      if ("host"   in keywords)   host = keywords["host"];
      if ("dbname" in keywords) dbname = keywords["dbname"];
      if ("sock"   in keywords)   sock = keywords["sock"];
      if ("port"   in keywords)   port = cast(int)keywords["port"].atoi();
    } else {
      dbname = conn;
    }

    m_mysql = mysql_init(null);
    mysql_real_connect(m_mysql, toStringz(host), toStringz(user),
                       toStringz(passwd), toStringz(dbname), port,
                       toStringz("/tmp/mysql.sock"), 0);
    
    return cast(int)mysql_errno(m_mysql);
  }

  int close() {
    mysql_close(m_mysql);
    return cast(int)mysql_errno(m_mysql);
  }

  int execute(char[] sql) {
    return mysql_real_query(m_mysql, toStringz(sql), sql.length);
  }

  Result query(char[] sql) {
    mysql_real_query(m_mysql, toStringz(sql), sql.length);
    MysqlResult res = new MysqlResult(mysql_store_result(m_mysql));
    return res;
  }

  int getErrorCode() {
    return cast(int)mysql_errno(m_mysql);
  }

  char[] getErrorMessage() {
    return std.string.toString(mysql_error(m_mysql));
  }

  private {
    MYSQL* m_mysql;
  }

  unittest {
    void s1(char[] s) { printf("%.*s\n", s); }
    void s2(char[] s) { printf("   ...%.*s\n", s); }

    s1("dbi.mysql.MysqlDatabase:");
    MysqlDatabase db = new MysqlDatabase();
    s2("connect");
    assert(db.connect("dbname=test", "test", "test") == 0);

    s2("query");
    Result res = db.query("SELECT * FROM people");
    assert(res != null);

    s2("fetchRow");
    Row row = res.fetchRow();
    assert(row != null);
    assert(row.getFieldIndex("name") == 1);
    /** Todo: MySQL type retrieval is not functioning */
    //assert(row.getFieldType(1) == FIELD_TYPE_STRING);
    //assert(row.getFieldDecl(1) == "char(40)");
    assert(row.get(0) == "1");
    assert(row.get("name") == "John Doe");
    assert(row["name"]     == "John Doe");
    assert(row.get(2) == "45");
    assert(row[2]     == "45");
    res.finish();

    s2("prepare");
    Statement stmt = db.prepare("SELECT * FROM people WHERE id = ?");
    stmt.bind(1, "1");
    res = stmt.query();
    row = res.fetchRow();
    res.finish();
    assert(row["id"] == "1");

    s2("fetchOne");
    row = db.queryFetchOne("SELECT * FROM people");
    assert(row["id"] == "1");

    s2("execute(INSERT)");
    assert(db.execute("INSERT INTO people VALUES (0, 'Test Doe', '10')") == 0);

    s2("execute(DELETE via prepare statement)");
    stmt = db.prepare("DELETE FROM people WHERE id=?");
    stmt.bind(1, "0");
    assert(stmt.execute() == 0);
    
    s2("getErrorCode, getErrorMessage");
    db.execute("SELECT * FROM doesnotexist");
    assert(db.getErrorCode() > 0);
    assert(count(db.getErrorMessage(), "doesnotexist") > 0);
    
    s2("close");
    assert(db.close() == 0);
  }
}
