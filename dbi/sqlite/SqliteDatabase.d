module dbi.sqlite.SqliteDatabase;

import std.string;
import dbi.BaseDatabase, dbi.Result, dbi.Row, dbi.Exception;
import dbi.sqlite.imp, dbi.sqlite.SqliteResult;

/**
  Class: SqliteDatabase
  
  Manage a SQLite database. This class implements all of the current
  DBD interface as defined in <Database>. In addition, a few "extra"
  functions are included.

  See Also:

  <BaseDatabase>, <Database>
*/
class SqliteDatabase : BaseDatabase {
  this() {}
  this(char[] dbFile) {
    errorCode = connect(dbFile);
    if (errorCode != SQLITE_OK) {
      throw new DBIException("Could not open or create: " ~ dbFile, errorCode);
    }
  }

  /**
    Function: connect

    Connect to a database (open), create if necessary.

    Paramenters:
    char[] dbFile - database filename to open or create
    char[] user - not used
    char[] passwd - not used
  */
  int connect(char[] dbFile, char[] user=null, char[] passwd=null) {
    errorCode = sqlite3_open(dbFile, &db);
    return errorCode;
  }

  int close() {
    sqlite3_close(db);
    return SQLITE_OK;
  }

  int execute(char[] sql) {
    char **errorMessage;
    this.sql = sql;
    errorCode = sqlite3_exec(db, sql, null, null, errorMessage);
    return errorCode;
  }

  Result query(char[] sql) {
    char **errorMessage;
    sqlite3_stmt *stmt;

    this.sql = sql;
    errorCode = sqlite3_prepare(db, sql, sql.length, &stmt, errorMessage);
    if (errorCode != SQLITE_OK) {
      return null;
    }

    return new SqliteResult(stmt);
  }

  long getLastInsertRowId() {
    return sqlite3_last_insert_rowid(db);
  }

  int getChanges() {
    return sqlite3_changes(db);
  }

  int getErrorCode() {
    return sqlite3_errcode(db);
  }

  char[] getErrorMessage() {
    return std.string.toString(sqlite3_errmsg(db));
  }

  /**
    Section: Above and Beyond DBI API
  */
  
  /**
    Function: getTableNames

    Get a list of all table names

    Returns:
    
    char[][] - array of all table names
   */
  char[][] getTableNames() {
    return getItemNames("table");
  }

  /**
    Function: getViewNames
    
    Get a list of all view names

    Returns:

    char[][] - array of all view names
   */
  char[][] getViewNames() {
    return getItemNames("view");
  }

  /**
    Function: getIndexNames
    
    Get a list of all index names

    Returns:
    char[][] - array of all index names
   */
  char[][] getIndexNames() {
    return getItemNames("index");
  }

  /**
    Function: hasTable
    
    Does this database have the given table?

    Parameters:
    char[] name - name of table to check for existance of

    Returns:
    0 - does not have
    1 - has
   */
  byte hasTable(char[] name) {
    return hasItem("table", name);
  }

  /**
    Function: hasView
    
    Does this database have the given view?

    Parameters:
    char[] name - name of view to check for existance of

    Returns:
    0 - does not have
    1 - has
   */
  byte hasView(char[] name) {
    return hasItem("view", name);
  }

  /**
    Function: hasIndex
    
    Does this database have the given index?

    Parameters:
    char[] name - name of index to check for existance of

    Returns:
    0 - does not have
    1 - has
   */
  byte hasIndex(char[] name) {
    return hasItem("index", name);
  }

  private {
    sqlite3* db;
    int errorCode;
    char[] sql;

    char[][] getItemNames(char[] type) {
      char[][] items;
      Row[] rows = queryFetchAll("SELECT name FROM sqlite_master " ~
                                 "WHERE type='" ~ type ~ "'");
      for (int idx=0; idx < rows.length; idx++) {
        items ~= rows[idx].get(0);
      }

      return items;
    }

    byte hasItem(char[] type, char[] name) {
      Row[] rows = queryFetchAll("SELECT name FROM sqlite_master " ~
                                 "WHERE type='" ~ type ~ "' AND name='" ~
                                 name ~ "'");
      if (rows != null && rows.length > 0)
        return 1;
      return 0;
    }
  }

  unittest {
    void s1(char[] s) { printf("%.*s\n", s); }
    void s2(char[] s) { printf("   ...%.*s\n", s); }

    s1("dbi.sqlite.SqliteDatabase:");
    SqliteDatabase db = new SqliteDatabase();
    s2("connect");
    assert(db.connect("_test.db") == SQLITE_OK);

    s2("query");
    Result res = db.query("SELECT * FROM people");
    assert(res != null);

    s2("fetchRow");
    Row row = res.fetchRow();
    assert(row != null);
    assert(row.getFieldIndex("name") == 1);
    assert(row.getFieldType(1) == SQLITE_TEXT);
    assert(row.getFieldDecl(1) == "char(40)");
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
    assert(db.execute("INSERT INTO people VALUES (0, 'Test Doe', '10')")
           == SQLITE_OK);
    s2("getChanges");
    assert(db.getChanges() == 1);

    s2("execute(DELETE via prepare statement)");
    stmt = db.prepare("DELETE FROM people WHERE id=?");
    stmt.bind(1, "0");
    assert(stmt.execute() == SQLITE_OK);
    assert(db.getChanges() == 1);

    s2("getErrorCode, getErrorMessage");
    db.execute("SELECT * FROM doesnotexist");
    assert(db.getErrorCode() > 0);
    assert(count(db.getErrorMessage(), "doesnotexist") > 0);

    s2("getTableNames, getViewNames, getIndexNames");
    assert(db.getTableNames().length == 1);
    assert(db.getIndexNames().length == 0);
    assert(db.getViewNames( ).length == 0);

    s2("hasTable, hasView, hasIndex");
    assert(db.hasTable("people") == 1);
    assert(db.hasTable("doesnotexist") == 0);
    assert(db.hasIndex("doesnotexist") == 0);
    assert(db.hasView( "doesnotexist") == 0);

    db.close();
  }
}
