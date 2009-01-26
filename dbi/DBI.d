/**
 * The main import module for DBI.  Loading this module will automatically
 * load all database backend that are built into DBI using command line version
 * switches.  Currently the following versions switches are functional:
 * 
 * ---
 * -dbi_mysql = loads the Mysql DBI package
 * -dbi_sqlite = loads the Sqlite DBI package
 * ---
 * 
 * To connect to a database, use getDatabaseForURL() or a database's own
 * connection method (see the documentation for the database you are using).
 * 
 * The most basic database methods are the following:
 * ---
 * void query(char[] sql,...);
 * bool fetchRow(...);
 * ---
 * 
 * query() takes template variadic parameters which are bound automatically to the
 * provided sql and fetchRow() binds result-row fields to the provided parameters.
 * 
 * Databases also provide the following convenience methods which dynamically
 * generate sql and bind the provided variadic parameters to that sql (note: database
 * implementations are written in such a way as to minimize or eliminate the need
 * to dynamically allocate memory for sql generation - these methods should be fairly
 * efficient) :
 * ---
 * void insert(char[] tablename, char[][] fields, ...);
 * void update(char[] tablename, char[][] fields, char[] whereClause, ...);
 * void select(char[] tablename, char[][] fields, char[] whereClause, ...);
 * void remove(char[] tablename, char[] whereClause, ...);
 * ---
 * 
 * This simple example should show you how to get stated with DBI.
 * ---
 * auto db = getDatabaseForURL("sqlite://sqlite.db");
 * 
 * db.query(`CREATE TABLE "user" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT)`);
 * 
 * db.insert("user",["name"],"bob");
 * assert(db.affectedRows == 1);
 * auto id = db.lastInsertID;
 * 
 * db.update("user",["bob"],`WHERE "id" = ?`,"mike",id);
 * assert(db.affectedRows == 1);
 * 
 * db.select("user",["name"],`WHERE "id" = ?`,id);
 * char[] name;
 * assert(db.rowCount == 1);
 * assert(db.fetchRow(name));
 * assert(name == "mike");
 * ---
 * 
 * 
 * 
 */
module dbi.DBI;



version(DDoc) {
	
	import dbi.model.Database;
	
	/**
	 * Creates a database based on a connection url in a
	 * JBDC-like format.  See the documentation for each database
	 * to understand its URL format.  This is the standard way
	 * to connect to a database in DBI without having to explicitly
	 * load a database specific module, create an connection instance,
	 * and call the database's conenct method. 
	 * 
	 * 
	 * Params:
	 *     dbUrl = the url for the database being loaded 
	 * Returns: a connection to the database specified by dbUrl
	 */
	Database getDatabaseForURL(char[] dbUrl)
	{
		return null;
	}
}

public import dbi.util.Registry;

version(dbi_mysql) {
	import dbi.mysql.Mysql;
}

version(dbi_sqlite) {
	import dbi.sqlite.Sqlite;
}