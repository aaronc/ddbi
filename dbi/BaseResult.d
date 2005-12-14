module dbi.BaseResult;

import dbi.Database, dbi.Result;

/**
   Class: BaseResult

   All DBI Result classes should inherit from <BaseResult> instead
   of <Result> directly. This class will provide a default
   implementation of fetchAll() which seems to work on all DBI
   drivers.

   See Also:

   <Result>
*/
class BaseResult : Result {

  /**
     Function: fetchRow
  */
  Row fetchRow() {
    throw new DBIException("Not implemented");
  }

  /**
     Function: fetchAll

     Fetch all results returning an array of Row's

     Returns:

     Row[] - rows retrieved.
  */
   
  Row[] fetchAll() {
    Row[] rows;
    Row row;

    while ((row = fetchRow()) !== null) {
      rows ~= row;
    }

    finish();

    return rows;
  }

  /**
     Function: finish
  */
  void finish() {
    throw new DBIException("Not implemented");
  }
}
