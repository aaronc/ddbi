/**
 * SQLite import library.
 * Part of the D DBI project.
 *
 * SQLite version 3.3.6
 * Import library version 0.02
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.sqlite.imp;

version (Windows) {
	pragma (lib, "sqlite3.lib");
} else version (linux) {
	pragma (lib, "libsqlite.so");
} else version (darwin) {
	pragma (lib, "libsqlite.so");	
} else {
	static assert (0);
}

private import std.c.stdarg;

/**
 *
 */
struct sqlite3 {
}

/**
 *
 */
struct sqlite3_context {
}

/**
 *
 */
struct sqlite3_stmt {
}

/**
 *
 */
struct sqlite3_value {
}

/**
 *
 */
alias int function(void*, int, char**, char**) sqlite_callback;

const uint SQLITE_OK		= 0;	/// Successful result.
const uint SQLITE_ERROR		= 1;	/// SQL error or missing database.
const uint SQLITE_INTERNAL	= 2;	/// An internal logic error in SQLite.
const uint SQLITE_PERM		= 3;	/// Access permission denied.
const uint SQLITE_ABORT		= 4;	/// Callback routine requested an abort.
const uint SQLITE_BUSY		= 5;	/// The database file is locked.
const uint SQLITE_LOCKED	= 6;	/// A table in the database is locked.
const uint SQLITE_NOMEM		= 7;	/// A malloc() failed.
const uint SQLITE_READONLY	= 8;	/// Attempt to write a readonly database.
const uint SQLITE_INTERRUPT	= 9;	/// Operation terminated by sqlite_interrupt().
const uint SQLITE_IOERR		= 10;	/// Some kind of disk I/O error occurred.
const uint SQLITE_CORRUPT	= 11;	/// The database disk image is malformed.
const uint SQLITE_NOTFOUND	= 12;	/// (Internal Only) Table or record not found.
const uint SQLITE_FULL		= 13;	/// Insertion failed because database is full.
const uint SQLITE_CANTOPEN	= 14;	/// Unable to open the database file.
const uint SQLITE_PROTOCOL	= 15;	/// Database lock protocol error.
const uint SQLITE_EMPTY		= 16;	/// (Internal Only) Database table is empty.
const uint SQLITE_SCHEMA	= 17;	/// The database schema changed.
const uint SQLITE_TOOBIG	= 18;	/// Too much data for one row of a table.
const uint SQLITE_CONSTRAINT	= 19;	/// Abort due to constraint violation.
const uint SQLITE_MISMATCH	= 20;	/// Data type mismatch.
const uint SQLITE_MISUSE	= 21;	/// Library used incorrectly.
const uint SQLITE_NOLFS		= 22;	/// Uses OS features not supported on host.
const uint SQLITE_AUTH		= 23;	/// Authorization denied.
const uint SQLITE_ROW		= 100;	/// sqlite_step() has another row ready.
const uint SQLITE_DONE		= 101;	/// sqlite_step() has finished executing.
const uint SQLITE_UTF8		= 1;	/// The text is in UTF8 format.
const uint SQLITE_UTF16BE	= 2;	/// The text is in UTF16 big endian format.
const uint SQLITE_UTF16LE	= 3;	/// The text is in UTF16 little endian format.
const uint SQLITE_UTF16		= 4;	/// The text is in UTF16 format.
const uint SQLITE_ANY		= 5;	/// The text is in some format or another.

const uint SQLITE_INTEGER	= 1;	/// The data value is an integer.
const uint SQLITE_FLOAT		= 2;	/// The data value is a float.
const uint SQLITE_TEXT		= 3;	/// The data value is text.
const uint SQLITE_BLOB		= 4;	/// The data value is a blob.
const uint SQLITE_NULL		= 5;	/// The data value is _null.

const uint SQLITE_DENY		= 1;	/// Abort the SQL statement with an error.
const uint SQLITE_IGNORE	= 2;	/// Don't allow access, but don't generate an error.

const void function(void*) SQLITE_STATIC = cast(void function(void*))0; /// The data doesn't need to be freed by SQLite.  
const void function(void*) SQLITE_TRANSIENT = cast(void function(void*))-1; /// SQLite should make a private copy of the data.

const uint SQLITE_CREATE_INDEX		= 1;	/// Index Name		Table Name
const uint SQLITE_CREATE_TABLE		= 2;	/// Table Name		NULL
const uint SQLITE_CREATE_TEMP_INDEX	= 3;	/// Index Name		Table Name
const uint SQLITE_CREATE_TEMP_TABLE	= 4;	/// Table Name		NULL
const uint SQLITE_CREATE_TEMP_TRIGGER	= 5;	/// Trigger Name	Table Name
const uint SQLITE_CREATE_TEMP_VIEW	= 6;	/// View Name		NULL
const uint SQLITE_CREATE_TRIGGER	= 7;	/// Trigger Name	Table Name
const uint SQLITE_CREATE_VIEW		= 8;	/// View Name		NULL
const uint SQLITE_DELETE		= 9;	/// Table Name		NULL
const uint SQLITE_DROP_INDEX		= 10;	/// Index Name		Table Name
const uint SQLITE_DROP_TABLE		= 11;	/// Table Name		NULL
const uint SQLITE_DROP_TEMP_INDEX	= 12;	/// Index Name		Table Name
const uint SQLITE_DROP_TEMP_TABLE	= 13;	/// Table Name		NULL
const uint SQLITE_DROP_TEMP_TRIGGER	= 14;	/// Trigger Name	Table Name
const uint SQLITE_DROP_TEMP_VIEW	= 15;	/// View Name		NULL
const uint SQLITE_DROP_TRIGGER		= 16;	/// Trigger Name	Table Name
const uint SQLITE_DROP_VIEW		= 17;	/// View Name		NULL
const uint SQLITE_INSERT		= 18;	/// Table Name		NULL
const uint SQLITE_PRAGMA		= 19;	/// Pragma Name		1st arg or NULL
const uint SQLITE_READ			= 20;	/// Table Name		Column Name
const uint SQLITE_SELECT		= 21;	/// NULL		NULL
const uint SQLITE_TRANSACTION		= 22;	/// NULL		NULL
const uint SQLITE_UPDATE		= 23;	/// Table Name		Column Name
const uint SQLITE_ATTACH		= 24;	/// Filename		NULL
const uint SQLITE_DETACH		= 25;	/// Database Name	NULL
const uint SQLITE_ALTER_TABLE		= 26;	/// Database Name	Table Name
const uint SQLITE_REINDEX		= 27;	/// Index Name		NULL
const uint SQLITE_ANALYZE		= 28;	/// Table Name		NULL

extern (C):

/**
 *
 */
void* sqlite3_aggregate_context (sqlite3_context* ctx, int nBytes);

/**
 *
 */
deprecated int sqlite3_aggregate_count (sqlite3_context* ctx);

/**
 *
 */
int sqlite3_bind_blob (sqlite3_stmt* stmt, int index, void* value, int n, void function(void*) destructor);

/**
 *
 */
int sqlite3_bind_double (sqlite3_stmt* stmt, int index, double value);

/**
 *
 */
int sqlite3_bind_int (sqlite3_stmt* stmt, int index, int value);

/**
 *
 */
int sqlite3_bind_int64 (sqlite3_stmt* stmt, int index, long value);

/**
 *
 */
int sqlite3_bind_null (sqlite3_stmt* stmt, int index);

/**
 *
 */
int sqlite3_bind_text (sqlite3_stmt* stmt, int index, char* value, int n, void function(void*) destructor);

/**
 *
 */
int sqlite3_bind_text16 (sqlite3_stmt* stmt, int index, void* value, int n, void function(void*) destructor);

/**
 *
 */
int sqlite3_bind_parameter_count (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_bind_parameter_index (sqlite3_stmt* stmt, char* zName);

/**
 *
 */
char* sqlite3_bind_parameter_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
int sqlite3_busy_handler (sqlite3* database, int function(void*, int) handler, void* n);

/**
 *
 */
int sqlite3_busy_timeout (sqlite3* database, int ms);

/**
 *
 */
int sqlite3_changes (sqlite3* database);

/**
 *
 */
int sqlite3_clear_bindings(sqlite3_stmt* statement);

/**
 *
 */
int sqlite3_close(sqlite3* database);

/**
 *
 */
int sqlite3_collation_needed (sqlite3* database, void* names, void function(void* names, sqlite3* database, int eTextRep, char* sequence));

/**
 *
 */
int sqlite3_collation_needed (sqlite3* database, void* names, void function(void* names, sqlite3* database, int eTextRep, void* sequence));

/**
 *
 */
void* sqlite3_column_blob (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_bytes (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_bytes16 (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
double sqlite3_column_double (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_int (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
long sqlite3_column_int64 (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
char* sqlite3_column_text (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
void* sqlite3_column_text16 (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_type (sqlite3_stmt* stmt, int iCol);

/**
 *
 */
int sqlite3_column_count (sqlite3_stmt* stmt);

/**
 *
 */
char* sqlite3_column_database_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_database_name16 (sqlite3_stmt* stmt, int n);

/**
 *
 */
char* sqlite3_column_decltype (sqlite3_stmt* stmt, int i);

/**
 *
 */
void* sqlite3_column_decltype16 (sqlite3_stmt* stmt, int i);

/**
 *
 */
char* sqlite3_column_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_name16 (sqlite3_stmt* stmt, int n);

/**
 *
 */
char* sqlite3_column_origin_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_origin_name16 (sqlite3_stmt* sStmt, int n);

/**
 *
 */
char* sqlite3_column_table_name (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_column_table_name16 (sqlite3_stmt* stmt, int n);

/**
 *
 */
void* sqlite3_commit_hook (sqlite3* database, int function(void* args) xCallback, void* args);

/**
 *
 */
int sqlite3_complete (char* sql);

/**
 *
 */
int sqlite3_complete16 (void* sql);

/**
 *
 */
int sqlite3_create_collation (sqlite3* database, char* zName, int pref16, void* routine, int function(void*, int, void*, int, void*) xCompare);

/**
 *
 */
int sqlite3_create_collation16 (sqlite3* database, char* zName, int pref16, void* routine, int function(void*, int, void*, int, void*) xCompare);

/**
 *
 */
int sqlite3_create_function (sqlite3* database, char* zFunctionName, int nArg, int eTextRep, void* pUserData, void function(sqlite3_context*, int, sqlite3_value**) xFunc, void function(sqlite3_context*, int, sqlite3_value**) xStep, void function(sqlite3_context*) xFinal);

/**
 *
 */
int sqlite3_create_function (sqlite3* database, void* zFunctionName, int nArg, int eTextRep, void* pUserData, void function(sqlite3_context*, int, sqlite3_value**) xFunc, void function(sqlite3_context*, int, sqlite3_value**) xStep, void function(sqlite3_context*) xFinal);

/**
 *
 */
int sqlite3_data_count (sqlite3_stmt* stmt);

/**
 *
 */
sqlite3* sqlite3_db_handle (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_enable_shared_cache (int enable);

/**
 *
 */
int sqlite3_errcode (sqlite3* db);

/**
 *
 */
char* sqlite3_errmsg (sqlite3* database);

/**
 *
 */
void* sqlite3_errmsg16 (sqlite3* database);

/**
 *
 */
int sqlite3_exec (sqlite3* database, char* sql, sqlite_callback routine, void* arg, char** errmsg);

/**
 *
 */
int sqlite3_expired (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_finalize (sqlite3_stmt* stmt);

/**
 *
 */
void sqlite3_free (char* z);

/**
 *
 */
int sqlite3_get_table (sqlite3* database, char* sql, char*** resultp, int* nrow, int* ncolumn, char** errmsg);

/**
 *
 */
void sqlite3_free_table (char** result);

/**
 *
 */
int sqlite3_get_autocommit (sqlite3* database);

/**
 *
 */
int sqlite3_global_recover ();

/**
 *
 */
void sqlite3_interrupt (sqlite3* database);

/**
 *
 */
long sqlite3_last_insert_rowid (sqlite3* database);

/**
 *
 */
char* sqlite3_libversion ();

/**
 *
 */
char* sqlite3_mprintf (char* string, ...);

/**
 *
 */
char* sqlite3_vmprintf (char* string, va_list args);

/**
 *
 */
int sqlite3_open (char* filename, sqlite3** database);

/**
 *
 */
int sqlite3_open16 (void* filename, sqlite3** database);

/**
 *
 */
int sqlite3_prepare (sqlite3* database, char* zSql, int nBytes, sqlite3_stmt** stmt, char** zTail);

/**
 *
 */
int sqlite3_prepare16 (sqlite3* database, void* zSql, int nBytes, sqlite3_stmt** stmt, void** zTail);

/**
 *
 */
void sqlite3_progress_handler (sqlite3* database, int n, int function(void*) callback, void* arg);

/**
 *
 */
int sqlite3_release_memory (int n);

/**
 *
 */
int sqlite3_reset (sqlite3_stmt* stmt);

/**
 *
 */
void sqlite3_result_blob (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_double (sqlite3_context* context, double value);

/**
 *
 */
void sqlite3_result_error (sqlite3_context* context, char* value, int n);

/**
 *
 */
void sqlite3_result_error16 (sqlite3_context* context, void* value, int n);

/**
 *
 */
void sqlite3_result_int (sqlite3_context* context, int value);

/**
 *
 */
void sqlite3_result_int64 (sqlite3_context* context, long value);

/**
 *
 */
void sqlite3_result_null (sqlite3_context* context);

/**
 *
 */
void sqlite3_result_text (sqlite3_context* context, char* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_text16 (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_text16be (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_text16le (sqlite3_context* context, void* value, int n, void function(void*) destructor);

/**
 *
 */
void sqlite3_result_value (sqlite3_context* context, sqlite3_value* value);

/**
 *
 */
void* sqlite3_rollback_hook (sqlite3* database, void function(void*) callback, void* args);

/**
 *
 */
int sqlite3_set_authorizer (sqlite3* database, int function(void*, int, char*, char*, char*, char*) xAuth, void* UserData);

/**
 *
 */
int sqlite3_sleep (int ms);

/**
 *
 */
void sqlite3_soft_heap_limit (int n);

/**
 *
 */
int sqlite3_step (sqlite3_stmt* stmt);

/**
 *
 */
int sqlite3_table_column_metadata (sqlite3* database, char* zDbName, char* zTableName, char* zColumnName, char** zDataType, char** zCollSeq, int* notNull, int* primaryKey, int* autoInc);

/**
 *
 */
void sqlite3_thread_cleanup ();

/**
 *
 */
int sqlite3_total_changes (sqlite3* database);

/**
 *
 */
void* sqlite3_trace (sqlite3* database, void function(void*, char*) xTrace, void* args);

/**
 *
 */
int sqlite3_transfer_bindings (sqlite3_stmt* stmt, sqlite3_stmt* stmt);

/**
 *
 */
void* sqlite3_update_hook (sqlite3* database, void function(void*, int, char*, char*, long) callback, void* args);

/**
 *
 */
void* sqlite3_user_data (sqlite3_context* context);

/**
 *
 */
void* sqlite3_value_blob (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_bytes (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_bytes16 (sqlite3_value* value);

/**
 *
 */
double sqlite3_value_double (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_int (sqlite3_value* value);

/**
 *
 */
long sqlite3_value_int64 (sqlite3_value* value);

/**
 *
 */
char* sqlite3_value_text (sqlite3_value* value);

/**
 *
 */
void* sqlite3_value_text16 (sqlite3_value* value);

/**
 *
 */
void* sqlite3_value_text16be (sqlite3_value* value);

/**
 *
 */
void* sqlite3_value_text16le (sqlite3_value* value);

/**
 *
 */
int sqlite3_value_type (sqlite3_value* value);