module dbi.sqlite.SqliteResult;

import std.string;
import dbi.BaseResult, dbi.Row, dbi.sqlite.imp;

/**
  Class: SqliteResult
  
  Manage the results of a sqlite result set. This class implements all
  of the current DBD <Result> interface. The interface is not
  described here again, instead please view <Result> directly.

  See Also:

  <Result>
 */
class SqliteResult : BaseResult {
  /**
     Function: this
     
     Parameters:
     sqlite3_stmt* - SQLite3 statement structure
  */
  this(sqlite3_stmt* stmt) {
    this.stmt = stmt;
  }

  /**
     Function: ~this
  */
  ~this() { finish(); }

  /**
     Function: fetchRow
  */
  Row fetchRow() {
    if (sqlite3_step(stmt) != SQLITE_ROW) {
      return null;
    }

    Row r = new Row();
    for (int a = 0; a < sqlite3_column_count(stmt); a++) {
      r.addField(std.string.toString(sqlite3_column_name(stmt,a)).dup,
                 std.string.toString(sqlite3_column_text(stmt,a)).dup,
                 std.string.toString(sqlite3_column_decltype(stmt,a)).dup,
                 sqlite3_column_type(stmt,a));
    }
    
    return r;
  }

  /**
     Function: finish
  */
  void finish() {
    if (stmt != null) {
      sqlite3_finalize(stmt);
      stmt = null;
    }
  }

  private {
    sqlite3_stmt *stmt;
  }
}
