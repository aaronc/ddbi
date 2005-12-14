Section: D DBI

Group: Introduction

D DBI is a database independent interface for the D programming language.

Status:

D DBI is in it's infancy and the API *will* change. As database
drivers are added a common factor will be found. Some existing
functions may change names, parameters or totally removed. Other
functions will be added. The purpose of this release is to give the
community something to work with and start collecting ideas, bug fixes
and hopefully other database drivers.

In regards to documentation, as you browse around you will see that it
is still very sparse. I would recommend you checking out
dbi/sqlite/SqliteDatabase.d. In that file is a unittest { ... } block
that should help out quite a bit.

Supported Databases:

* SQLite v3.0
* MySQL
* PostgreSQL

Simple Example:

(start code)
import dbi.sqlite.SqliteDatabase;
//import dbi.pg.PgDatabase;
//import dbi.mysql.MysqlDatabase;

void main() {
  // PgDatabase db = new PgDatabase();
  // MysqlDatabase db = new MysqlDatabase();
  // db.connect("dbname=test");

  SqliteDatabase db = new SqliteDatabase();
  db.connect("_test.db");

  Row[] rows = db.queryFetchAll("SELECT * FROM names");
  for (Row row; rows) {
    printf("name: %.*s zip: %.*s\n", row["name"], row["zip"]);
  }

  db.close();
}
(end code)

Group: Download

Currently there is no NEWS document. Please view the ChangeLog to the left for information about what changed between releases.

 * April 20, 2005 - version 0.1.5: http://jeremy.cowgar.com/ddbi/ddbi-0.1.5.tar.gz
 * April 19, 2005 - version 0.1.4: http://jeremy.cowgar.com/ddbi/ddbi-0.1.4.tar.gz
 * April 19, 2005 - version 0.1.3: http://jeremy.cowgar.com/ddbi/ddbi-0.1.3.tar.gz
 * April 15, 2005 - version 0.1.2: http://jeremy.cowgar.com/ddbi/ddbi-0.1.2.tar.gz
 * April 14, 2005 - version 0.1.1: http://jeremy.cowgar.com/ddbi/ddbi-0.1.1.tar.gz
 * April 14, 2005 - version 0.1.0: http://jeremy.cowgar.com/ddbi/ddbi-0.1.0.tar.gz
