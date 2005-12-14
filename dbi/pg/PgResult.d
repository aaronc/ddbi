module dbi.pg.PgResult;

import std.string;
import dbi.BaseResult, dbi.Row, dbi.pg.imp;

/**
   Class: PgResult

   Manage the results of a PostgreSQL result set. This class
   implements all of the current DBD <Result> interface. The
   interface is not described here again, instead please view
   <Result> directly.

   See Also:

   <Result>
*/

class PgResult : BaseResult {
  /**
     Function: this

     Parameters:
     PGresult* res - PostgreSQL result structure
  */
  this(PGresult* res) {
    m_res    = res;
    m_rows   = PQntuples(res);
    m_fields = PQnfields(res);
  }

  /**
     Function: ~this
  */
  ~this() { finish();  }

  /**
     Function: fetchRow
  */
  Row fetchRow() {
    if (m_rowIdx > m_rows) {
      return null;
    }

    Row r = new Row();
    for (int a=0; a < m_fields; a++) {
      r.addField(std.string.toString(PQfname(m_res, a)).strip().dup, // name
                 std.string.toString(PQgetvalue(m_res,
                                                m_rowIdx,
                                                a)).strip().dup, // value
                 "", 0);
    }

    m_rowIdx += 1;

    return r;
  }

  /**
     Function: finish
  */
  void finish() {
    if (m_res != null) {
      PQclear(m_res);
      m_res = null;
    }
  }

  private {
    PGresult* m_res;
    int m_rowIdx;
    int m_rows;
    int m_fields;
  }
}
