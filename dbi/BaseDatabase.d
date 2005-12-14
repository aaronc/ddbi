module dbi.BaseDatabase;

import dbi.Database, dbi.Result, dbi.Row, dbi.Statement;

/**
   Class: BaseDatabase
   
   Base Database implementation that is suggested that other DBD's
   inherit from. This defines a few functions that are DBD independent
   such as <Database.queryFetchOne> and <Database.queryFetchAll>. For
   all other functions a <DBIException> is thrown with the message
   content "Not impemented."

   New DBD classes should inherit from BaseDatabase not directly from
   the <Database> interface.

   See Also:

   <Database>
*/
class BaseDatabase : Database {
  this() {}

  int connect(char[] conn, char[] user=null, char[] passwd=null) {
    throw new DBIException("Not implemented");
  }

  int close() {
    throw new DBIException("Not implemented");
  }

  int execute(char[] sql) {
    throw new DBIException("Not implemented");
  }

  Statement prepare(char[] sql) {
    return new Statement(cast(Database)this, sql);
  }

  Result query(char[] sql) {
    throw new DBIException("Not implemented");
  }

  Row queryFetchOne(char[] sql) {
    Result res = query(sql);
    if (res == null)
      return null;

    Row row = res.fetchRow();
    res.finish();

    return row;
  }

  Row[] queryFetchAll(char[] sql) {
    Result res = query(sql);
    if (res == null)
      return null;

    Row[] rows = res.fetchAll();
    res.finish();

    return rows;
  }

  int getErrorCode() {
    throw new DBIException("Not implemented");
  }

  char[] getErrorMessage() {
    throw new DBIException("Not implemented");
  }

  /**
     Function: getKeywords

     Takes a string and returns keywords and their values in a
     character array.
  */
  char[][char[]] getKeywords(char[] s) {
    char[][char[]] keywords;
    char[][] groups = s.split(";");
    foreach (char[] group; groups) {
      if (group == "") { continue; }
      char[][] vals = group.split("=");
      keywords[vals[0]] = vals[1];
    }

    return keywords;
  }

  unittest {
    void s1(char[] s) { printf("%.*s\n", s); }
    void s2(char[] s) { printf("   ...%.*s\n", s); }

    s1("dbi.BaseDatabase");
    BaseDatabase db = new BaseDatabase();

    s2("getKeywords");
    char[][char[]] keywords = db.getKeywords("dbname=hi;host=local;");
    assert(keywords["dbname"] == "hi");
    assert(keywords["host"] == "local");
  }
}
