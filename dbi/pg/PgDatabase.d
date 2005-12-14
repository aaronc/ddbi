module dbi.pg.PgDatabase;

import std.string;
import dbi.all, dbi.pg.imp, dbi.pg.PgResult;

/**
   Class: PgDatabase

   Manage a PostgreSQL database connection. This class implements all of
   the current DBD interface as defined in <Database>. Functions are
   not going to be explained in detail here, please see other references
   listed below.

   Limitations:
   
   <PgDatabase> currently does not retrieve column types.

   See Also:

   <BaseDatabase>, <Database>
*/

class PgDatabase : BaseDatabase {
  this() {}

  /**
     Function: connect

     Connect to a database.

     Parameters:

     char[] connString - connection string
     char[] user       - user name to authenticate with
     char[] passwd     - password to use for authentication

     Connection String Keywords:

     <http://www.postgresql.org/docs/8.0/static/libpq.html>
  */

  int connect(char[] conn, char[] user=null, char[] passwd=null) {
    if (conn == null) conn = "";
    if (user != null) conn ~= " user=" ~ user ~ "";
    if (passwd != null) conn ~= " password=" ~ passwd ~ "";

    m_pg = PQconnectdb(conn);

    m_errorCode   = cast(int)PQstatus(m_pg);
    m_errorString = std.string.toString(PQerrorMessage(m_pg));

    return m_errorCode;
  }

  int close() {
    PQfinish(m_pg);

    m_errorCode   = cast(int)PQstatus(m_pg);
    m_errorString = std.string.toString(PQerrorMessage(m_pg));

    if (PQstatus(m_pg) == ConnStatusType.CONNECTION_BAD)
      return 0;
    return m_errorCode;
  }

  int execute(char[] sql) {
    PGresult* res = PQexec(m_pg, toStringz(sql.dup));
    ExecStatusType status = PQresultStatus(res);

    m_errorCode = cast(int)status;
    m_errorString = std.string.toString(PQresultErrorMessage(res));

    PQclear(res);

    if (status == ExecStatusType.PGRES_COMMAND_OK)
      return 0;
    return m_errorCode;
  }

  Result query(char[] sql) {
    PGresult* res = PQexec(m_pg, toStringz(sql.dup));
    ExecStatusType status = PQresultStatus(res);

    m_errorCode = cast(int)status;
    m_errorString = std.string.toString(PQresultErrorMessage(res));

    return new PgResult(res);
  }

  int getErrorCode() {
    return m_errorCode;
  }

  char[] getErrorMessage() {
    return m_errorString;
  }

  private {
    PGconn* m_pg;
    int m_errorCode;
    char[] m_errorString;
  }


  unittest {
    void s1(char[] s) { printf("%.*s\n", s); }
    void s2(char[] s) { printf("   ...%.*s\n", s); }

    s1("dbi.pg.PgDatabase:");
    PgDatabase db = new PgDatabase();
    s2("connect");
    assert(db.connect("dbname=test") == 0);

    s2("query");
    Result res = db.query("SELECT * FROM people");
    assert(res != null);

    s2("fetchRow");
    Row row = res.fetchRow();
    assert(row != null);
    assert(row.getFieldIndex("name") == 1);
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
