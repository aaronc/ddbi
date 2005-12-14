module dbi.pg.imp;

import std.string;

extern(C):

enum ConnStatusType {
  /*
   * Although it is okay to add to this list, values which become unused
   * should never be removed, nor should constants be redefined - that
   * would break compatibility with existing code.
   */
  CONNECTION_OK,
  CONNECTION_BAD,
  /* Non-blocking mode only below here */

  /*
   * The existence of these should never be relied upon - they should
   * only be used for user feedback or similar purposes.
   */
  CONNECTION_STARTED,			/* Waiting for connection to be made.  */
  CONNECTION_MADE,			/* Connection OK; waiting to send.	   */
  CONNECTION_AWAITING_RESPONSE,		/* Waiting for a response from the
                                     * postmaster.		  */
  CONNECTION_AUTH_OK,			/* Received authentication; waiting for
								 * backend startup. */
  CONNECTION_SETENV,			/* Negotiating environment. */
  CONNECTION_SSL_STARTUP,		/* Negotiating SSL. */
  CONNECTION_NEEDED			/* Internal state: connect() needed */
}

enum ExecStatusType
{
	PGRES_EMPTY_QUERY = 0,		/* empty query string was executed */
	PGRES_COMMAND_OK,			/* a query command that doesn't return
								 * anything was executed properly by the
								 * backend */
	PGRES_TUPLES_OK,			/* a query command that returns tuples was
								 * executed properly by the backend,
								 * PGresult contains the result tuples */
	PGRES_COPY_OUT,				/* Copy Out data transfer in progress */
	PGRES_COPY_IN,				/* Copy In data transfer in progress */
	PGRES_BAD_RESPONSE,			/* an unexpected response was recv'd from
								 * the backend */
	PGRES_NONFATAL_ERROR,		/* notice or warning message */
	PGRES_FATAL_ERROR			/* query failed */
}

struct PGconn   {}
struct PGresult {}

/* Connection */
PGconn* PQconnectdb(char* conninfo);
ConnStatusType PQstatus(PGconn *conn);
void PQfinish(PGconn* conn);
char* PQerrorMessage(PGconn* conn);

/* Execute/Query */
PGresult* PQexec(PGconn* conn, char* command);
ExecStatusType PQresultStatus(PGresult* res);
void PQclear(PGresult* res);

/* Retrieve Results */
int PQntuples(PGresult* res);
int PQnfields(PGresult* res);

char* PQresultErrorMessage(PGresult* res);

char* PQfname(PGresult* res, int column_number);
int PQfnumber(PGresult* res, char* column_name);
char* PQgetvalue(PGresult* res, int row_number, int column_number);
char* PQgetisnull(PGresult* res, int row_number, int column_number);
