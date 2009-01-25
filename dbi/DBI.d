module dbi.DBI;

/**
 * 
 * 
 * 
 */

public import dbi.util.Registry;

version(dbi_mysql) {
	import dbi.mysql.Mysql;
}

version(dbi_sqlite) {
	import dbi.sqlite.SqliteDatabase;
}