module dbi.Database;

import dbi.Result, dbi.Exception, dbi.Statement;

/**
  Interface: Database

  Database interface that all DBD's must inherit from
*/
interface Database {
  /**
    Function: connect

    Connect to a database.

    Paramters:
    char[] conn - connection string
    char[] user - username
    char[] passwd - password

    Notes:
    user and passwd are not always used. If not supplied, they default to null.
  */
  int connect(char[] conn, char[] user, char[] passwd);

  /**
    Function: close

    Close the database connection.
  */
  int close();

  /**
    Function: execute

    Execute a SQL statement that returns no results.

    Parameters:
    char[] sql - SQL statement to execute
  */
  int execute(char[] sql);

  /**
     Function: prepare

     Prepare a SQL statement for execution.

     Parameters:
     char[] sql - SQL statement to execute
  */
  Statement prepare(char[] sql);

  /**
     Function: query

     Query the database.

     Parameters:
     char[] sql - SQL statement to execute
  */
  Result query(char[] sql);

  /**
     Function: queryFetchOne

     Query the database and return only the first row.

     Parameters:
     char[] sql - SQL statement to execute
  */
  Row queryFetchOne(char[] sql);

  /**
     Function: queryFetchAll

     Query the database and return an array of all the rows.

     Parameters:
     char[] sql - SQL statement to execute
  */
  Row[] queryFetchAll(char[] sql);

  /**
     Function: getErrorCode

     Get the error code.

     Todo:

     This function needs some thought. Should we wrap common SQL
     errors into a "D DBI" error code so that ALL DBD's report the
     same information? That's the way I am currently leaning. Any
     input?

     See Also:

     <getErrorMessage>
  */
  int getErrorCode();

  /**
     Function: getErrorMessage

     Get the error message.

     See Also:

     <getErrorCode>
  */
  char[] getErrorMessage();
}
