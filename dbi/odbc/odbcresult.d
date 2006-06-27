/**
 * Copyright: LGPL
 */
module dbi.odbc.odbcResult;

private import std.string;
private import dbi.BaseResult, dbi.Row;
private import dbi.odbc.imp;

/**
 * These numbers were picked by me (MPSD) almost at random.
 * Currently this makes the buffer 800k, perhaps excessive.
 */
const int ODBC_BUFFER_MAX = 8192;
const int ODBC_COLUMN_MAX = 100;
const int ODBC_NAME_MAX = 64;

/**
 *
 */
class odbcResult : BaseResult {
	/**
	 *
	 */
	this (HSTMT hstmt) {
		this.hstmt = hstmt;    
	}

	/**
	 *
	 */
  	~this () {
		finish();
	}

	/**
	 *
	 */
	Row fetchRow () {
		Row r = null; // Where the Data Hopefully Goes
		short num_cols = 0; // Number of Fields in Query
		SQLCHAR[ODBC_BUFFER_MAX][ODBC_COLUMN_MAX] buffer; // Massive Array of Doom
		SQLCHAR[][ODBC_COLUMN_MAX] column_names; // Query Field Names
		RETCODE rc; // ODBC Return Code
		SQLCHAR[ODBC_COLUMN_MAX] odbc_str; // Temporary Field Name

		// Unused, but necessary?
		SDWORD len;
		SQLSMALLINT column_name_length;
		SQLINTEGER fDesc;

		// Get field name from columns and count the columns while we're at it
		for (int i = 0; i < buffer.length && rc == SQL_SUCCESS; i++) {	// No overflow, No Error
			// Older-style SQLColAttributes (plural) was much more cooperative than SQLColAttribute
			rc = odbcSQLColAttributes(hstmt, cast(ushort) (i+1), SQL_C_CHAR, odbc_str, ODBC_NAME_MAX, &column_name_length, &fDesc);		
			column_names[i] = std.string.toString(odbc_str).dup; // dup!
			if (rc == SQL_SUCCESS) { // Don't count icky columns
				num_cols++;
			}
		}

		// Assign column numbers respective buffer positions in the buffer array
		for (int i = 0; i < num_cols; i++) {
			rc = odbcSQLBindCol(hstmt, cast(ushort) (i+1), SQL_C_CHAR, buffer[i], ODBC_BUFFER_MAX, &len);
		}
		rc = odbcSQLFetch(hstmt);

		// If we have real data, toss it into DDBI's row
		if (rc == SQL_SUCCESS) {
			r = new Row();
			for (int i = 0; i < num_cols; i++) {
				r.addField(column_names[i].dup, std.string.toString(buffer[i]).dup, std.string.toString("").dup, 0); // No extra goodies :(
			}
		}    
		return r;
	}

	/**
	 *
	 */
	void finish () {
		if (hstmt !is null) {
			odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
			hstmt = null;
		}
	}

	private:
	HSTMT hstmt;  // Presumably the same as odbcDatabase's hstmt
}