module dbi.Result;

import dbi.Row;

/**
   Interface: Result

   Manage a result set from a database query.
*/
interface Result {
  /**
     Function: fetchRow

     Fetch one <Row> from the result set.
     
     Returns:
     
     Row object - if another row existed
     null - if the last row has already been fetched
  */
  Row fetchRow();
  
  /**
     Function: fetchAll

     Fetch all results into a <Row> array
     
     Returns:

     Row[] - either empty or will content
  */
  Row[] fetchAll();
  
  /**
     Function: finish

     Finish resultset. This should be called if you terminate a query
     without fetching all results.
  */
  void finish();
}
