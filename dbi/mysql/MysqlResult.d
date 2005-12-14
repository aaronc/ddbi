module dbi.mysql.MysqlResult;

import std.string;
import dbi.BaseResult, dbi.Row, dbi.mysql.imp;

/**
   Class: MysqlResult

   Manage the results of a mysql result set. This class implements
   all of the current DBD <Result> interface. The interface is not
   described here again, instead please view <Result> directly.

   See Also:

   <Result>
*/
class MysqlResult : BaseResult {
  this(MYSQL_RES* res) {
    this.m_res = res;
  }

  ~this() {
    if (m_res != null) {
      finish();
    }
  }

  /**
     Function: fetchRow
  */
  Row fetchRow() {
    MYSQL_ROW row = mysql_fetch_row(m_res);
    if (row == null) return null;

    MYSQL_FIELD* field;
    int fieldCount = mysql_num_fields(m_res);

    Row r = new Row();
    for (int idx = 0; idx < fieldCount; idx++) {
      field = mysql_fetch_field_direct(m_res, idx);
      r.addField(std.string.toString(field.name).dup,
                 std.string.toString(row[idx]  ).dup,
                 "",//std.string.toString(field.def ).dup,
                 field.type);
    }

    return r;
  }

  void finish() {
    mysql_free_result(m_res);
    m_res = null;
  }

  private {
    MYSQL_RES* m_res;
  }
}
