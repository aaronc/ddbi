module dbi.Exception;

/**
  Class: DBIException
*/
class DBIException : Exception {
  private {
    char[] sql;
    int errorCode;
  }

  /**
     Function: this

     Create a new DBIException
     
     Parameters:
     char[] msg - message contents
  */
  this(char[] msg)
  {
    super("SQLException: " ~ msg);
  }

  /**
     Function: this

     Create a new DBIException
     
     Parameters:
     char[] msg - message contents
     int errorCode - associated numeric error code
  */
  this(char[] msg, int errorCode) {
    this(msg);
    this.errorCode = errorCode;
  }

  /**
     Function: this

     Create a new DBIException
     
     Parameters:
     char[] msg - message contents
     char[] sql - SQL statement that caused the error
     int errorCode - associated numeric error code
  */
  this(char[] msg, char[] sql, int errorCode) {
    this(msg, errorCode);
    this.sql = sql;
  }

  /**
    Function: getErrorCode

    Get the associated numeric error code.

    Returns:
    int - associated numeric error code
  */
  int getErrorCode() {
    return errorCode;
  }

  /**
    Function: getSQL

    Get the SQL statement that caused the error.
    
    Rerturns:
    char[] - SQL statement that caused the error
  */
  char[] getSQL() {
    return sql;
  }
}
