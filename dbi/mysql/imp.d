module dbi.mysql.imp;

/* Copyright (C) 2000-2003 MySQL AB

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

extern (C) :
// #ifndef _mysql_h
// #define _mysql_h

// #ifdef __CYGWIN__     /* CYGWIN implements a UNIX API */
// #undef WIN
// #undef _WIN
// #undef _WIN32
// #undef _WIN64
// #undef __WIN__
// #endif

// #ifdef	__cplusplus
// extern "C" {
// #endif

// #ifndef _global_h				/* If not standard header */
// #include <sys/types.h>
// #ifdef __LCC__
// #include <winsock.h>				/* For windows */
// #endif



struct st_list {
  st_list *prev,next;
  void *data;
} 
alias st_list LIST;


typedef int (*list_walk_action)(void *,void *);

extern LIST *list_add(LIST *root,LIST *element);
extern LIST *list_delete(LIST *root,LIST *element);
extern LIST *list_cons(void *data,LIST *root);
extern LIST *list_reverse(LIST *root);
extern void list_free(LIST *root,uint free_data);
extern uint list_length(LIST *);
extern int list_walk(LIST *,list_walk_action action,gptr argument);


const int ALLOC_MAX_BLOCK_TO_DROP			=4096;
const int ALLOC_MAX_BLOCK_USAGE_BEFORE_DROP	=10;

struct st_used_mem
{				   /* struct for once_alloc (block) */
  st_used_mem *next;	   /* Next block in use */
  uint	left;		   /* memory left in block  */
  uint	size;		   /* size of block */
}

alias st_used_mem USED_MEM;


 struct st_mem_root
{
  USED_MEM *free;                  /* blocks with free memory in it */
  USED_MEM *used;                  /* blocks almost without free memory */
  USED_MEM *pre_alloc;             /* preallocated block */
  /* if block have less memory it will be put in 'used' list */
  uint min_malloc;
  uint block_size;         /* initial block size */
  uint block_num;          /* allocated blocks counter */
  /* 
     first free block in queue test counter (if it exceed 
     MAX_BLOCK_USAGE_BEFORE_DROP block will be droped in 'used' list)
  */
  uint first_block_usage;

  void (*error_handler)();
}
alias st_mem_root MEM_ROOT;

enum enum_mysql_timestamp_type
{
  MYSQL_TIMESTAMP_NONE= -2, MYSQL_TIMESTAMP_ERROR= -1,
  MYSQL_TIMESTAMP_DATE= 0, MYSQL_TIMESTAMP_DATETIME= 1, MYSQL_TIMESTAMP_TIME= 2
};

 struct st_mysql_time
{
  uint  year, month, day, hour, minute, second;
  ulong second_part;
  my_bool       neg;
  enum_mysql_timestamp_type time_type;
} 

alias st_mysql_time MYSQL_TIME;




const int  PROTOCOL_VERSION=		10;
const char []  MYSQL_SERVER_VERSION=		"4.1.11";
const char []  MYSQL_BASE_VERSION=		"mysqld-4.1";
const char [] MYSQL_SERVER_SUFFIX_DEF=		"-standard";
const int  FRM_VER				=6;
const int MYSQL_VERSION_ID=		40111;
const int MYSQL_PORT=			3306;
const char [] MYSQL_UNIX_ADDR=			"/tmp/mysql.sock";
const char []MYSQL_CONFIG_NAME=		"my";
const char []MYSQL_COMPILATION_COMMENT=	"MySQL Community Edition - Standard (GPL)";



const int NAME_LEN	=64		;
const int HOSTNAME_LENGTH =60;
const int USERNAME_LENGTH =16;
const int SERVER_VERSION_LENGTH =60;
const int SQLSTATE_LENGTH =5;

const char [] LOCAL_HOST	="localhost";
const char [] LOCAL_HOST_NAMEDPIPE= ".";



const char [] MYSQL_NAMEDPIPE ="MySQL";
const char [] MYSQL_SERVICENAME ="MySQL";

enum enum_server_command
{
  COM_SLEEP, COM_QUIT, COM_INIT_DB, COM_QUERY, COM_FIELD_LIST,
  COM_CREATE_DB, COM_DROP_DB, COM_REFRESH, COM_SHUTDOWN, COM_STATISTICS,
  COM_PROCESS_INFO, COM_CONNECT, COM_PROCESS_KILL, COM_DEBUG, COM_PING,
  COM_TIME, COM_DELAYED_INSERT, COM_CHANGE_USER, COM_BINLOG_DUMP,
  COM_TABLE_DUMP, COM_CONNECT_OUT, COM_REGISTER_SLAVE,
  COM_PREPARE, COM_EXECUTE, COM_LONG_DATA, COM_CLOSE_STMT,
  COM_RESET_STMT, COM_SET_OPTION,
  /* don't forget to update const char *command_name[] in sql_parse.cc */

  /* Must be last */
  COM_END
};


const int SCRAMBLE_LENGTH =20;
const int SCRAMBLE_LENGTH_323 =8;
/* length of password stored in the db: new passwords are preceeded with '*' */
const int SCRAMBLED_PASSWORD_CHAR_LENGTH =(SCRAMBLE_LENGTH*2+1);
const int SCRAMBLED_PASSWORD_CHAR_LENGTH_323= (SCRAMBLE_LENGTH_323*2);


const int NOT_NULL_FLAG	=1		;
const int PRI_KEY_FLAG	=2		;
const int UNIQUE_KEY_FLAG =4		;
const int MULTIPLE_KEY_FLAG =8		;
const int BLOB_FLAG	=16		;
const int UNSIGNED_FLAG	=32		;
const int ZEROFILL_FLAG	=64		;
const int BINARY_FLAG	=128		;
const int ENUM_FLAG	=256		;

const int AUTO_INCREMENT_FLAG =512		;
const int TIMESTAMP_FLAG	=1024		;
const int SET_FLAG	=2048		;
const int NUM_FLAG	=32768		;
const int PART_KEY_FLAG	=16384		;
const int GROUP_FLAG	=32768		;
const int UNIQUE_FLAG	=65536		;
const int BINCMP_FLAG	=131072		;

const int REFRESH_GRANT		=1	;
const int REFRESH_LOG		=2	;
const int REFRESH_TABLES		=4	;
const int REFRESH_HOSTS		=8	;
const int REFRESH_STATUS		=16	;
const int REFRESH_THREADS		=32	;
const int REFRESH_SLAVE           =64      ;
const int REFRESH_MASTER          =128     ;


const int REFRESH_READ_LOCK	=16384	;
const int REFRESH_FAST		=32768	;


const int REFRESH_QUERY_CACHE	=65536;
const int REFRESH_QUERY_CACHE_FREE =0x20000L ;
const int REFRESH_DES_KEY_FILE	=0x40000L;
const int REFRESH_USER_RESOURCES	=0x80000L;

const int CLIENT_LONG_PASSWORD	=1	;
const int CLIENT_FOUND_ROWS	=2	;
const int CLIENT_LONG_FLAG	=4	;
const int CLIENT_CONNECT_WITH_DB	=8	;
const int CLIENT_NO_SCHEMA	=16	;
const int CLIENT_COMPRESS		=32	;
const int CLIENT_ODBC		=64	;
const int CLIENT_LOCAL_FILES	=128	;
const int CLIENT_IGNORE_SPACE	=256	;
const int CLIENT_PROTOCOL_41	=512	;
const int CLIENT_INTERACTIVE	=1024	;
const int CLIENT_SSL              =2048	;
const int CLIENT_IGNORE_SIGPIPE   =4096    ;
const int CLIENT_TRANSACTIONS	=8192	;
const int CLIENT_RESERVED         =16384   ;
const int CLIENT_SECURE_CONNECTION =32768  ;
const int CLIENT_MULTI_STATEMENTS =65536   ;
const int CLIENT_MULTI_RESULTS    =131072  ;
const int CLIENT_REMEMBER_OPTIONS=	( (1) << 31);

const int SERVER_STATUS_IN_TRANS     =1	;
const int SERVER_STATUS_AUTOCOMMIT   =2	;
const int SERVER_STATUS_MORE_RESULTS =4	;
const int SERVER_MORE_RESULTS_EXISTS =8    ;
const int SERVER_QUERY_NO_GOOD_INDEX_USED =16;
const int SERVER_QUERY_NO_INDEX_USED      =32;
const int SERVER_STATUS_DB_DROPPED        =256 ;

const int MYSQL_ERRMSG_SIZE	=512;
const int NET_READ_TIMEOUT	=30		;
const int NET_WRITE_TIMEOUT	=60		;
const int NET_WAIT_TIMEOUT	=8*60*60		;

struct st_vio;					
alias  st_vio Vio;

const int MAX_TINYINT_WIDTH       =3       ;
const int MAX_SMALLINT_WIDTH      =5       ;
const int MAX_MEDIUMINT_WIDTH     =8       ;
const int MAX_INT_WIDTH           =10      ;
const int MAX_BIGINT_WIDTH        =20      ;
const int MAX_CHAR_WIDTH		=255	;
const int MAX_BLOB_WIDTH		=8192	;

alias int my_socket;

 struct st_net {

  Vio* vio;
  char *buff,buff_end,write_pos,read_pos;
  my_socket fd;					
  ulong max_packet,max_packet_size;
  uint pkt_nr,compress_pkt_nr;
  uint write_timeout, read_timeout, retry_count;
  int fcntl;
  my_bool compress;
  
  ulong remain_in_buf,length, buf_length, where_b;
  uint *return_status;
  char reading_or_writing;
  char save_char;
  my_bool no_send_ok;
  

} 
alias st_net NET;

const int packet_error= (~0);

enum enum_field_types { MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
			MYSQL_TYPE_SHORT,  MYSQL_TYPE_LONG,
			MYSQL_TYPE_FLOAT,  MYSQL_TYPE_DOUBLE,
			MYSQL_TYPE_NULL,   MYSQL_TYPE_TIMESTAMP,
			MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
			MYSQL_TYPE_DATE,   MYSQL_TYPE_TIME,
			MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
			MYSQL_TYPE_NEWDATE,
			MYSQL_TYPE_ENUM=247,
			MYSQL_TYPE_SET=248,
			MYSQL_TYPE_TINY_BLOB=249,
			MYSQL_TYPE_MEDIUM_BLOB=250,
			MYSQL_TYPE_LONG_BLOB=251,
			MYSQL_TYPE_BLOB=252,
			MYSQL_TYPE_VAR_STRING=253,
			MYSQL_TYPE_STRING=254,
			MYSQL_TYPE_GEOMETRY=255

};


const int CLIENT_MULTI_QUERIES=    CLIENT_MULTI_STATEMENTS    ;
const int FIELD_TYPE_DECIMAL=     enum_field_types.MYSQL_TYPE_DECIMAL;
const int FIELD_TYPE_TINY=        enum_field_types.MYSQL_TYPE_TINY;
const int FIELD_TYPE_SHORT=       enum_field_types.MYSQL_TYPE_SHORT;
const int FIELD_TYPE_LONG=        enum_field_types.MYSQL_TYPE_LONG;
const int FIELD_TYPE_FLOAT=       enum_field_types.MYSQL_TYPE_FLOAT;
const int FIELD_TYPE_DOUBLE=      enum_field_types.MYSQL_TYPE_DOUBLE;
const int FIELD_TYPE_NULL=        enum_field_types.MYSQL_TYPE_NULL;
const int FIELD_TYPE_TIMESTAMP=   enum_field_types.MYSQL_TYPE_TIMESTAMP;
const int FIELD_TYPE_LONGLONG=    enum_field_types.MYSQL_TYPE_LONGLONG;
const int FIELD_TYPE_INT24=       enum_field_types.MYSQL_TYPE_INT24;
const int FIELD_TYPE_DATE=        enum_field_types.MYSQL_TYPE_DATE;
const int FIELD_TYPE_TIME=        enum_field_types.MYSQL_TYPE_TIME;
const int FIELD_TYPE_DATETIME=    enum_field_types.MYSQL_TYPE_DATETIME;
const int FIELD_TYPE_YEAR=        enum_field_types.MYSQL_TYPE_YEAR;
const int FIELD_TYPE_NEWDATE=     enum_field_types.MYSQL_TYPE_NEWDATE;
const int FIELD_TYPE_ENUM=        enum_field_types.MYSQL_TYPE_ENUM;
const int FIELD_TYPE_SET=         enum_field_types.MYSQL_TYPE_SET;
const int FIELD_TYPE_TINY_BLOB=   enum_field_types.MYSQL_TYPE_TINY_BLOB;
const int FIELD_TYPE_MEDIUM_BLOB= enum_field_types.MYSQL_TYPE_MEDIUM_BLOB;
const int FIELD_TYPE_LONG_BLOB=   enum_field_types.MYSQL_TYPE_LONG_BLOB;
const int FIELD_TYPE_BLOB=        enum_field_types.MYSQL_TYPE_BLOB;
const int FIELD_TYPE_VAR_STRING=  enum_field_types.MYSQL_TYPE_VAR_STRING;
const int FIELD_TYPE_STRING=      enum_field_types.MYSQL_TYPE_STRING;
const int FIELD_TYPE_CHAR=        enum_field_types.MYSQL_TYPE_TINY;
const int FIELD_TYPE_INTERVAL=    enum_field_types.MYSQL_TYPE_ENUM;
const int FIELD_TYPE_GEOMETRY=    enum_field_types.MYSQL_TYPE_GEOMETRY;


 


const int MYSQL_SHUTDOWN_KILLABLE_CONNECT    =(1 << 0);
const int MYSQL_SHUTDOWN_KILLABLE_TRANS=      (1 << 1);
const int MYSQL_SHUTDOWN_KILLABLE_LOCK_TABLE =(1 << 2);
const int MYSQL_SHUTDOWN_KILLABLE_UPDATE=     (1 << 3);

enum mysql_enum_shutdown_level {
  
  SHUTDOWN_DEFAULT = 0,
  
  SHUTDOWN_WAIT_CONNECTIONS= MYSQL_SHUTDOWN_KILLABLE_CONNECT,
  
  SHUTDOWN_WAIT_TRANSACTIONS= MYSQL_SHUTDOWN_KILLABLE_TRANS,
  
  SHUTDOWN_WAIT_UPDATES= MYSQL_SHUTDOWN_KILLABLE_UPDATE,
  
  SHUTDOWN_WAIT_ALL_BUFFERS= (MYSQL_SHUTDOWN_KILLABLE_UPDATE << 1),
  
  SHUTDOWN_WAIT_CRITICAL_BUFFERS= (MYSQL_SHUTDOWN_KILLABLE_UPDATE << 1) + 1,
  

  KILL_CONNECTION= 255
};


enum enum_mysql_set_option
{
  MYSQL_OPTION_MULTI_STATEMENTS_ON,
  MYSQL_OPTION_MULTI_STATEMENTS_OFF
};


my_bool	my_net_init(NET *net, Vio* vio);
void	my_net_local_init(NET *net);
void	net_end(NET *net);
void	net_clear(NET *net);
my_bool net_realloc(NET *net, ulong length);
my_bool	net_flush(NET *net);
my_bool	my_net_write(NET *net, char *packet,ulong len);
my_bool	net_write_command(NET *net,char command,
			   char *header, ulong head_len,
			   char *packet, ulong len);
int	net_real_write(NET *net, char *packet,ulong len);
ulong my_net_read(NET *net);


struct sockaddr;
int my_connect(my_socket s,  sockaddr *name, uint namelen,
	       uint timeout);

struct rand_struct {
  ulong seed1,seed2,max_value;
  double max_value_dbl;
};

  

enum Item_result {STRING_RESULT, REAL_RESULT, INT_RESULT, ROW_RESULT};

struct st_udf_args
{
	uint arg_count;		/* Number of arguments */
	Item_result *arg_type;		/* Pointer to item_results */
	char **args;				/* Pointer to argument */
	ulong *lengths;		/* Length of string arguments */
	char *maybe_null;			/* Set to 1 for all maybe_null args */
} 

alias st_udf_args UDF_ARGS;

  /* This holds information about the result */

struct st_udf_init
{
  my_bool maybe_null;			/* 1 if function can return NULL */
  uint decimals;		/* for real functions */
  ulong max_length;		/* For string functions */
  char	  *ptr;				/* free pointer for function data */
  my_bool const_item;			/* 0 if result is independent of arguments */
}

alias  st_udf_init UDF_INIT;

  
const int NET_HEADER_SIZE =4		;
const int COMP_HEADER_SIZE =3		;

  


void randominit( rand_struct *, ulong seed1,
                ulong seed2);
double my_rnd( rand_struct *);
void create_random_string(char *to, uint length,  rand_struct *rand_st);

void hash_password(ulong *to,  char *password, uint password_len);
void make_scrambled_password_323(char *to,  char *password);
void scramble_323(char *to,  char *message,  char *password);
my_bool check_scramble_323( char *,  char *message,
                           ulong *salt);
void get_salt_from_password_323(ulong *res,  char *password);
void make_password_from_salt_323(char *to,  ulong *salt);

void make_scrambled_password(char *to,  char *password);
void scramble(char *to,  char *message,  char *password);
my_bool check_scramble( char *reply,  char *message,
                        char *hash_stage2);
void get_salt_from_password(char *res,  char *password);
void make_password_from_salt(char *to,  char *hash_stage2);

/* end of password.c */

char *get_tty_password(char *opt_message);
 char *mysql_errno_to_sqlstate(uint mysql_errno);

/* Some other useful functions */

my_bool my_init();
int load_defaults( char *conf_file,  char **groups,
		  int *argc, char ***argv);
my_bool my_thread_init();
void my_thread_end();


ulong net_field_length(char **packet);
my_ulong net_field_length_ll(char **packet);
char *net_store_length(char *pkg, ulong length);


const int NULL_LENGTH= (~0) ;
const int MYSQL_STMT_HEADER       =4;
const int MYSQL_LONG_DATA_HEADER  =6;

typedef char my_bool;
// #if (defined(_WIN32) || defined(_WIN64)) && !defined(__WIN__)
// #define __WIN__
// #endif
// #if !defined(__WIN__)
// #define STDCALL
// #else
// #define STDCALL __stdcall
// #endif
typedef char * gptr;

// #ifndef my_socket_defined
// #ifdef __WIN__
// #define my_socket SOCKET
// #else
// typedef int my_socket;
// #endif /* __WIN__ */
// #endif /* my_socket_defined */
// #endif /* _global_h */

version(Windows )
{
	
	typedef int my_socket;
}
version(Linux)
{
	typedef int my_socket;
}




// #include "mysql_com.h"
// #include "mysql_time.h"
// #include "mysql_version.h"
// #include "typelib.h"

// #include "my_list.h" /* for LISTs used in 'MYSQL' and 'MYSQL_STMT' */

uint mysql_port;
char *mysql_unix_port;

const size_t CLIENT_NET_READ_TIMEOUT = 365*24*3600;
const size_t CLIENT_NET_WRITE_TIMEOUT = 365*24*3600;

// #define CLIENT_NET_READ_TIMEOUT		365*24*3600	/* Timeout on read */
// #define CLIENT_NET_WRITE_TIMEOUT	365*24*3600	/* Timeout on write */

// #ifdef __NETWARE__
// #pragma pack(push, 8)		/* 8 byte alignment */
// #endif


/+ need to define these, if you want to use em +/
// #define IS_PRI_KEY(n)	((n) & PRI_KEY_FLAG)
// #define IS_NOT_NULL(n)	((n) & NOT_NULL_FLAG)
// #define IS_BLOB(n)	((n) & BLOB_FLAG)
// #define IS_NUM(t)	((t) <= FIELD_TYPE_INT24 || (t) == FIELD_TYPE_YEAR)
// #define IS_NUM_FIELD(f)	 ((f)->flags & NUM_FLAG)
// #define INTERNAL_NUM_FIELD(f) (((f)->type <= FIELD_TYPE_INT24 && ((f)->type != FIELD_TYPE_TIMESTAMP || (f)->length == 14 || (f)->length == 8)) || (f)->type == FIELD_TYPE_YEAR)



struct st_mysql_field {
  char *name;                 /* Name of column */
  char *org_name;             /* Original column name, if an alias */ 
  char *table;                /* Table of column if column was a field */
  char *org_table;            /* Org table name, if table was an alias */
  char *db;                   /* Database for table */
  char *catalog;	      /* Catalog for table */
  char *def;                  /* Default value (set by mysql_list_fields) */
  ulong length;       /* Width of column (create length) */
  ulong max_length;   /* Max width for selected set */
  uint name_length;
  uint org_name_length;
  uint table_length;
  uint org_table_length;
  uint db_length;
  uint catalog_length;
  uint def_length;
  uint flags;         /* Div flags */
  uint decimals;      /* Number of decimals in field */
  uint charsetnr;     /* Character set */
   enum_field_types type; /* Type of field. See mysql_com.h for types */
} 
alias st_mysql_field MYSQL_FIELD;

typedef char **MYSQL_ROW;		/* return data as array of strings */
typedef uint MYSQL_FIELD_OFFSET; /* offset to current field */

// #ifndef _global_h
// #if defined(NO_CLIENT_LONG_LONG)
typedef ulong my_ulong;
// #elif defined (__WIN__)
// typedef unsigned __int64 my_ulong;
// #else
// typedef ulong long my_ulong;
// #endif
// #endif
//const int MYSQL_COUNT_ERROR = (~0 );
// #define MYSQL_COUNT_ERROR (~(my_ulong) 0)

struct st_mysql_rows {
   st_mysql_rows *next;		/* list of rows */
  MYSQL_ROW data;
  ulong length;
} 

alias st_mysql_rows MYSQL_ROWS;

typedef MYSQL_ROWS *MYSQL_ROW_OFFSET;	/* offset to current row */

//#include "my_alloc.h"

struct st_mysql_data {
  my_ulong rows;
  uint fields;
  MYSQL_ROWS *data;
  MEM_ROOT alloc;

}
alias st_mysql_data MYSQL_DATA;

enum mysql_option 
{
  MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS, MYSQL_OPT_NAMED_PIPE,
  MYSQL_INIT_COMMAND, MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP,
  MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME, MYSQL_OPT_LOCAL_INFILE,
  MYSQL_OPT_PROTOCOL, MYSQL_SHARED_MEMORY_BASE_NAME, MYSQL_OPT_READ_TIMEOUT,
  MYSQL_OPT_WRITE_TIMEOUT, MYSQL_OPT_USE_RESULT,
  MYSQL_OPT_USE_REMOTE_CONNECTION, MYSQL_OPT_USE_EMBEDDED_CONNECTION,
  MYSQL_OPT_GUESS_CONNECTION, MYSQL_SET_CLIENT_IP, MYSQL_SECURE_AUTH
};


 struct st_dynamic_array
{
  char *buffer;
  uint elements,max_element;
  uint alloc_increment;
  uint size_of_element;
} 
alias st_dynamic_array DYNAMIC_ARRAY;

struct st_mysql_options {
  uint connect_timeout, read_timeout, write_timeout;
  uint port, protocol;
  ulong client_flag;
  char *host,user,password,unix_socket,db;
  st_dynamic_array *init_commands;
  char *my_cnf_file,my_cnf_group, charset_dir, charset_name;
  char *ssl_key;				/* PEM key file */
  char *ssl_cert;				/* PEM cert file */
  char *ssl_ca;					/* PEM CA file */
  char *ssl_capath;				/* PEM directory of CA-s? */
  char *ssl_cipher;				/* cipher to use */
  char *shared_memory_base_name;
  long max_allowed_packet;
  my_bool use_ssl;				/* if to use SSL or not */
  my_bool compress,named_pipe;
 /*
   On connect, find out the replication role of the server, and
   establish connections to all the peers
 */
  my_bool rpl_probe;
 /*
   Each call to mysql_real_query() will parse it to tell if it is a read
   or a write, and direct it to the slave or the master
 */
  my_bool rpl_parse;
 /*
   If set, never read from a master, only from slave, when doing
   a read that is replication-aware
 */
  my_bool no_master_reads;

  mysql_option methods_to_use;
  char *client_ip;
  /* Refuse client connecting to server if it uses old (pre-4.1.1) protocol */
  my_bool secure_auth;

  /* function pointers for local infile support */
  int (*local_infile_init)(void **,  char *, void *);
  int (*local_infile_read)(void *, char *, uint);
  void (*local_infile_end)(void *);
  int (*local_infile_error)(void *, char *, uint);
  void *local_infile_userdata;
};

enum mysql_status 
{
  MYSQL_STATUS_READY,MYSQL_STATUS_GET_RESULT,MYSQL_STATUS_USE_RESULT
};

enum mysql_protocol_type 
{
  MYSQL_PROTOCOL_DEFAULT, MYSQL_PROTOCOL_TCP, MYSQL_PROTOCOL_SOCKET,
  MYSQL_PROTOCOL_PIPE, MYSQL_PROTOCOL_MEMORY
};
/*
  There are three types of queries - the ones that have to go to
  the master, the ones that go to a slave, and the adminstrative
  type which must happen on the pivot connectioin
*/
enum mysql_rpl_type 
{
  MYSQL_RPL_MASTER, MYSQL_RPL_SLAVE, MYSQL_RPL_ADMIN
};



struct my_charset_handler_st
{
  my_bool (*init)( charset_info_st *, void *(*alloc)(uint));
  /* Multibyte routines */
  int     (*ismbchar)( charset_info_st *,  char *,  char *);
  int     (*mbcharlen)( charset_info_st *, uint);
  uint    (*numchars)( charset_info_st *,  char *b,  char *e);
  uint    (*charpos)( charset_info_st *,  char *b,  char *e, uint pos);
  uint    (*well_formed_len)( charset_info_st *,
  			    char *b, char *e, uint nchars);
  uint    (*lengthsp)( charset_info_st *,  char *ptr, uint length);
  uint    (*numcells)( charset_info_st *,  char *b,  char *e);
  
  /* Unicode convertion */
  int (*mb_wc)( charset_info_st *cs,ulong *wc,
	         char *s,  char *e);
  int (*wc_mb)( charset_info_st *cs,ulong wc,
	        char *s, char *e);
  
  /* Functions for case and sort convertion */
  void    (*caseup_str)( charset_info_st *, char *);
  void    (*casedn_str)( charset_info_st *, char *);
  void    (*caseup)( charset_info_st *, char *, uint);
  void    (*casedn)( charset_info_st *, char *, uint);
  
  /* Charset dependant snprintf() */
  int  (*snprintf)( charset_info_st *, char *to, uint n,  char *fmt,
		   ...);
  int  (*long10_to_str)( charset_info_st *, char *to, uint n, int radix,
			ulong val);
  int (*ulong10_to_str)( charset_info_st *, char *to, uint n,
			   int radix, ulong val);
  
  void (*fill)( charset_info_st *, char *to, uint len, int fill);
  
  /* String-to-number convertion routines */
  long        (*strntol)( charset_info_st *,  char *s, uint l,
			 int base, char **e, int *err);
  ulong      (*strntoul)( charset_info_st *,  char *s, uint l,
			 int base, char **e, int *err);
  ulong   (*strntoll)( charset_info_st *,  char *s, uint l,
			 int base, char **e, int *err);
  ulong (*strntoull)( charset_info_st *,  char *s, uint l,
			 int base, char **e, int *err);
  double      (*strntod)( charset_info_st *, char *s, uint l, char **e,
			 int *err);
  ulong (*my_strtoll10)( charset_info_st *cs,
                            char *nptr, char **endptr, int *error);
  ulong        (*scan)( charset_info_st *,  char *b,  char *e,
		       int sq);
}

alias  my_charset_handler_st  MY_CHARSET_HANDLER;

struct my_match_t
{
  uint beg;
  uint end;
  uint mblen;
} 


struct my_collation_handler_st
{
  my_bool (*init)( charset_info_st *, void *(*alloc)(uint));
  /* Collation routines */
  int     (*strnncoll)( charset_info_st *,
		        char *, uint,  char *, uint, my_bool);
  int     (*strnncollsp)( charset_info_st *,
		        char *, uint,  char *, uint);
  int     (*strnxfrm)( charset_info_st *,
		      char *, uint,  char *, uint);
  my_bool (*like_range)( charset_info_st *,
			 char *s, uint s_length,
			wchar w_prefix, wchar w_one, wchar w_many, 
			uint res_length,
			char *min_str, char *max_str,
			uint *min_len, uint *max_len);
  int     (*wildcmp)( charset_info_st *,
  		      char *str, char *str_end,
                      char *wildstr, char *wildend,
                     int escape,int w_one, int w_many);

  int  (*strcasecmp)( charset_info_st *,  char *,  char *);
  
  uint (*instr)( charset_info_st *,
                 char *b, uint b_length,
                 char *s, uint s_length,
                my_match_t *match, uint nmatch);
  
  /* Hash calculation */
  void (*hash_sort)( charset_info_st *cs,  char *key, uint len,
		    ulong *nr1, ulong *nr2); 
}
alias  my_collation_handler_st MY_COLLATION_HANDLER;

struct my_uni_idx_st
{
  uint from;
  uint to;
	char  *tab;
}
alias  my_uni_idx_st MY_UNI_IDX;

//struct st_mysql_methods;
struct charset_info_st
{
  uint      number;
  uint      primary_number;
  uint      binary_number;
  uint      state;
   char *csname;
   char *name;
   char *comment;
   char *tailoring;
  char    *ctype;
  char    *to_lower;
  char    *to_upper;
  char    *sort_order;
  uint   *contractions;
  uint   **sort_order_big;
  uint      *tab_to_uni;
  MY_UNI_IDX  *tab_from_uni;
  char     *state_map;
  char     *ident_map;
  uint      strxfrm_multiply;
  uint      mbminlen;
  uint      mbmaxlen;
  uint    min_sort_char;
  uint    max_sort_char; /* For LIKE optimization */
  
  MY_CHARSET_HANDLER *cset;
  MY_COLLATION_HANDLER *coll;
  
}
alias charset_info_st CHARSET_INFO;

struct st_mysql
{
  NET		net;			/* Communication parameters */
  gptr		connector_fd;		/* ConnectorFd for SSL */
  char		*host,user,passwd,unix_socket,server_version,host_info,info;
  char          *db;
  charset_info_st *charset;
  MYSQL_FIELD	*fields;
  MEM_ROOT	field_alloc;
  my_ulong affected_rows;
  my_ulong insert_id;		/* id if insert on table with NEXTNR */
  my_ulong extra_info;		/* Used by mysqlshow */
  ulong thread_id;		/* Id for connection in server */
  ulong packet_length;
  uint	port;
  ulong client_flag,server_capabilities;
  uint	protocol_version;
  uint	field_count;
  uint 	server_status;
  uint  server_language;
  uint	warning_count;
  st_mysql_options options;
  mysql_status status;
  my_bool	free_me;		/* If free in mysql_close */
  my_bool	reconnect;		/* set to 1 if automatic reconnect */

  /* session-wide random string */
  char	        scramble[SCRAMBLE_LENGTH+1];

 /*
   Set if this is the original connection, not a master or a slave we have
   added though mysql_rpl_probe() or mysql_set_master()/ mysql_add_slave()
 */
  my_bool rpl_pivot;
  /*
    Pointers to the master, and the next slave connections, points to
    itself if lone connection.
  */
	st_mysql* master, next_slave;

   st_mysql* last_used_slave; /* needed for round-robin slave pick */
 /* needed for send/read/store/use result to work correctly with replication */
   st_mysql* last_used_con;

  LIST  *stmts;                     /* list of all statements */
   st_mysql_methods *methods;
  void *thd;
  /*
    Points to boolean flag in MYSQL_RES  or MYSQL_STMT. We set this flag 
    from mysql_stmt_close if close had to cancel result set of this object.
  */
  my_bool *unbuffered_fetch_owner;
} 

alias st_mysql MYSQL;

struct st_mysql_res {
  my_ulong row_count;
  MYSQL_FIELD	*fields;
  MYSQL_DATA	*data;
  MYSQL_ROWS	*data_cursor;
  ulong *lengths;		/* column lengths of current row */
  MYSQL		*handle;		/* for unbuffered reads */
  MEM_ROOT	field_alloc;
  uint	field_count, current_field;
  MYSQL_ROW	row;			/* If unbuffered read */
  MYSQL_ROW	current_row;		/* buffer to current row */
  my_bool	eof;			/* Used by mysql_fetch_row */
  /* mysql_stmt_close() had to cancel this result */
  my_bool       unbuffered_fetch_cancelled;  
   st_mysql_methods *methods;
} 

alias st_mysql_res MYSQL_RES;

const int MAX_MYSQL_MANAGER_ERR = 256  ;
const int MAX_MYSQL_MANAGER_MSG = 256;

const int MANAGER_OK           = 200;
const int MANAGER_INFO         = 250;
const int MANAGER_ACCESS       = 401;
const int MANAGER_CLIENT_ERR   = 450;
const int MANAGER_INTERNAL_ERR = 500;



 struct st_mysql_manager
{
  NET net;
  char *host,user,passwd;
  uint port;
  my_bool free_me;
  my_bool eof;
  int cmd_status;
  int last_errno;
  char* net_buf,net_buf_pos,net_data_end;
  int net_buf_size;
  char last_error[MAX_MYSQL_MANAGER_ERR];
}
alias st_mysql_manager MYSQL_MANAGER;

struct st_mysql_parameters
{
  ulong *p_max_allowed_packet;
  ulong *p_net_buffer_length;
} 

alias st_mysql_parameters MYSQL_PARAMETERS;

// #if !defined(MYSQL_SERVER) && !defined(EMBEDDED_LIBRARY)
// #define max_allowed_packet (*mysql_get_parameters()->p_max_allowed_packet)
// #define net_buffer_length (*mysql_get_parameters()->p_net_buffer_length)
// #endif

/*
  Set up and bring down the server; to ensure that applications will
  work when linked against either the standard client library or the
  embedded server library, these functions should be called.
*/
int  mysql_server_init(int argc, char **argv, char **groups);
void  mysql_server_end();
/*
  mysql_server_init/end need to be called when using libmysqld or
  libmysqlclient (exactly, mysql_server_init() is called by mysql_init() so
  you don't need to call it explicitely; but you need to call
  mysql_server_end() to free memory). The names are a bit misleading
  (mysql_SERVER* to be used when using libmysqlCLIENT). So we add more general
  names which suit well whether you're using libmysqld or libmysqlclient. We
  intend to promote these aliases over the mysql_server* ones.
*/
alias mysql_server_init mysql_library_init;
alias mysql_server_end mysql_library_end ;

MYSQL_PARAMETERS * mysql_get_parameters();

/*
  Set up and bring down a thread; these function should be called
  for each thread in an application which opens at least one MySQL
  connection.  All uses of the connection(s) should be between these
  function calls.
*/
my_bool  mysql_thread_init();
void  mysql_thread_end();

/*
  Functions to get information from the MYSQL and MYSQL_RES structures
  Should definitely be used if one uses shared libraries.
*/

my_ulong  mysql_num_rows(MYSQL_RES *res);
uint  mysql_num_fields(MYSQL_RES *res);
my_bool  mysql_eof(MYSQL_RES *res);
MYSQL_FIELD * mysql_fetch_field_direct(MYSQL_RES *res,
					      uint fieldnr);
MYSQL_FIELD *  mysql_fetch_fields(MYSQL_RES *res);
MYSQL_ROW_OFFSET  mysql_row_tell(MYSQL_RES *res);
MYSQL_FIELD_OFFSET  mysql_field_tell(MYSQL_RES *res);

uint  mysql_field_count(MYSQL *mysql);
my_ulong  mysql_affected_rows(MYSQL *mysql);
my_ulong  mysql_insert_id(MYSQL *mysql);
uint  mysql_errno(MYSQL *mysql);
 char *  mysql_error(MYSQL *mysql);
 char * mysql_sqlstate(MYSQL *mysql);
uint  mysql_warning_count(MYSQL *mysql);
 char *  mysql_info(MYSQL *mysql);
ulong  mysql_thread_id(MYSQL *mysql);
 char *  mysql_character_set_name(MYSQL *mysql);

MYSQL *		 mysql_init(MYSQL *mysql);
my_bool		 mysql_ssl_set(MYSQL *mysql,  char *key,
				       char *cert,  char *ca,
				       char *capath,  char *cipher);
my_bool		 mysql_change_user(MYSQL *mysql,  char *user, 
					   char *passwd,  char *db);
MYSQL *		 mysql_real_connect(MYSQL *mysql,  char *host,
					    char *user,
					    char *passwd,
					    char *db,
					   uint port,
					    char *unix_socket,
					   ulong clientflag);
int		 mysql_select_db(MYSQL *mysql,  char *db);
int		 mysql_query(MYSQL *mysql,  char *q);
int		 mysql_send_query(MYSQL *mysql,  char *q,
					 ulong length);
int		 mysql_real_query(MYSQL *mysql,  char *q,
					ulong length);
MYSQL_RES *      mysql_store_result(MYSQL *mysql);
MYSQL_RES *      mysql_use_result(MYSQL *mysql);

/* perform query on master */
my_bool		 mysql_master_query(MYSQL *mysql,  char *q,
					   ulong length);
my_bool		 mysql_master_send_query(MYSQL *mysql,  char *q,
						ulong length);
/* perform query on slave */  
my_bool		 mysql_slave_query(MYSQL *mysql,  char *q,
					  ulong length);
my_bool		 mysql_slave_send_query(MYSQL *mysql,  char *q,
					       ulong length);

/* local infile support */

const int LOCAL_INFILE_ERROR_LEN  = 512;


void
mysql_set_local_infile_handler(MYSQL *mysql,
                               int (*local_infile_init)(void **,  char *,
                            void *),
                               int (*local_infile_read)(void *, char *,
							uint),
                               void (*local_infile_end)(void *),
                               int (*local_infile_error)(void *, char*,
							 uint),
                               void *);

void
mysql_set_local_infile_default(MYSQL *mysql);


/*
  enable/disable parsing of all queries to decide if they go on master or
  slave
*/
void             mysql_enable_rpl_parse(MYSQL* mysql);
void             mysql_disable_rpl_parse(MYSQL* mysql);
/* get the value of the parse flag */  
int              mysql_rpl_parse_enabled(MYSQL* mysql);

/*  enable/disable reads from master */
void             mysql_enable_reads_from_master(MYSQL* mysql);
void             mysql_disable_reads_from_master(MYSQL* mysql);
/* get the value of the master read flag */  
my_bool		 mysql_reads_from_master_enabled(MYSQL* mysql);

mysql_rpl_type      mysql_rpl_query_type( char* q, int len);  

/* discover the master and its slaves */  
my_bool		 mysql_rpl_probe(MYSQL* mysql);

/* set the master, close/free the old one, if it is not a pivot */
int              mysql_set_master(MYSQL* mysql,  char* host,
					 uint port,
					  char* user,
					  char* passwd);
int              mysql_add_slave(MYSQL* mysql,  char* host,
					uint port,
					 char* user,
					 char* passwd);

int		 mysql_shutdown(MYSQL *mysql,
                                       mysql_enum_shutdown_level
                                       shutdown_level);
int		 mysql_dump_debug_info(MYSQL *mysql);
int		 mysql_refresh(MYSQL *mysql,
				     uint refresh_options);
int		 mysql_kill(MYSQL *mysql,ulong pid);
int		 mysql_set_server_option(MYSQL *mysql,
						enum_mysql_set_option
						option);
int		 mysql_ping(MYSQL *mysql);
 char *	 mysql_stat(MYSQL *mysql);
 char *	 mysql_get_server_info(MYSQL *mysql);
 char *	 mysql_get_client_info();
ulong	 mysql_get_client_version();
 char *	 mysql_get_host_info(MYSQL *mysql);
ulong	 mysql_get_server_version(MYSQL *mysql);
uint	 mysql_get_proto_info(MYSQL *mysql);
MYSQL_RES *	 mysql_list_dbs(MYSQL *mysql, char *wild);
MYSQL_RES *	 mysql_list_tables(MYSQL *mysql, char *wild);
MYSQL_RES *	 mysql_list_processes(MYSQL *mysql);
int		 mysql_options(MYSQL *mysql, mysql_option option,
				       char *arg);
void		 mysql_free_result(MYSQL_RES *result);
void		 mysql_data_seek(MYSQL_RES *result,
					my_ulong offset);
MYSQL_ROW_OFFSET  mysql_row_seek(MYSQL_RES *result,
						MYSQL_ROW_OFFSET offset);
MYSQL_FIELD_OFFSET  mysql_field_seek(MYSQL_RES *result,
					   MYSQL_FIELD_OFFSET offset);
MYSQL_ROW	 mysql_fetch_row(MYSQL_RES *result);
ulong *  mysql_fetch_lengths(MYSQL_RES *result);
MYSQL_FIELD *	 mysql_fetch_field(MYSQL_RES *result);
MYSQL_RES *      mysql_list_fields(MYSQL *mysql,  char *table,
					   char *wild);
ulong	 mysql_escape_string(char *to, char *from,
					    ulong from_length);
ulong	 mysql_hex_string(char *to, char *from,
                                         ulong from_length);
ulong  mysql_real_escape_string(MYSQL *mysql,
					       char *to, char *from,
					       ulong length);
void		 mysql_debug( char *debug_);
char *		 mysql_odbc_escape_string(MYSQL *mysql,
						 char *to,
						 ulong to_length,
						  char *from,
						 ulong from_length,
						 void *param,
						 char *
						 (*extend_buffer)
						 (void *, char *to,
						  ulong *length));
void 		 myodbc_remove_escape(MYSQL *mysql,char *name);
uint	 mysql_thread_safe();
my_bool		 mysql_embedded();
MYSQL_MANAGER*   mysql_manager_init(MYSQL_MANAGER* con);  
MYSQL_MANAGER*   mysql_manager_connect(MYSQL_MANAGER* con,
					       char* host,
					       char* user,
					       char* passwd,
					      uint port);
void             mysql_manager_close(MYSQL_MANAGER* con);
int              mysql_manager_command(MYSQL_MANAGER* con,
						 char* cmd, int cmd_len);
int              mysql_manager_fetch_line(MYSQL_MANAGER* con,
						  char* res_buf,
						 int res_buf_size);
my_bool          mysql_read_query_result(MYSQL *mysql);


/*
  The following definitions are added for the enhanced 
  client-server protocol
*/

/* statement state */
enum enum_mysql_stmt_state
{
  MYSQL_STMT_INIT_DONE= 1, MYSQL_STMT_PREPARE_DONE, MYSQL_STMT_EXECUTE_DONE,
  MYSQL_STMT_FETCH_DONE
};


/* bind structure */
 struct st_mysql_bind
{
  ulong	*length;          /* output length pointer */
  my_bool       *is_null;	  /* Pointer to null indicator */
  void		*buffer;	  /* buffer to get/put data */
  enum_field_types buffer_type;	/* buffer type */
  ulong buffer_length;    /* buffer length, must be set for str/binary */  

  /* Following are for internal use. Set by mysql_stmt_bind_param */
  char *inter_buffer;    /* for the current data position */
  ulong offset;           /* offset position for char/binary fetch */
  ulong	internal_length;  /* Used if length is 0 */
  uint	param_number;	  /* For null count and error messages */
  uint  pack_length;	  /* Internal length for packed data */
  my_bool       is_unsigned;      /* set if integer type is unsigned */
  my_bool	long_data_used;	  /* If used with mysql_send_long_data */
  my_bool	internal_is_null; /* Used if is_null is 0 */
  void (*store_param_func)(NET *net,  st_mysql_bind *param);
  void (*fetch_result)(st_mysql_bind *, char **row);
  void (*skip_result)( st_mysql_bind *, MYSQL_FIELD *,
		      char **row);
} 

alias st_mysql_bind MYSQL_BIND;


/* statement handler */
struct st_mysql_stmt
{
  MEM_ROOT       mem_root;             /* root allocations */
  LIST           list;                 /* list to keep track of all stmts */
  MYSQL          *mysql;               /* connection handle */
  MYSQL_BIND     *params;              /* input parameters */
  MYSQL_BIND     *bind;                /* output parameters */
  MYSQL_FIELD    *fields;              /* result set metadata */
  MYSQL_DATA     result;               /* cached result set */
  MYSQL_ROWS     *data_cursor;         /* current row in cached result */
  /* copy of mysql->affected_rows after statement execution */
  my_ulong   affected_rows;
  my_ulong   insert_id;            /* copy of mysql->insert_id */
  /*
    mysql_stmt_fetch() calls this function to fetch one row (it's different
    for buffered, unbuffered and cursor fetch).
  */
  int            (*read_row_func)(st_mysql_stmt *stmt, 
                                  char **row);
  ulong	 stmt_id;	       /* Id for prepared statement */
  uint	 last_errno;	       /* error code */
  uint   param_count;          /* input parameter count */
  uint   field_count;          /* number of columns in result set */
   enum_mysql_stmt_state state;    /* statement state */
  char		 last_error[MYSQL_ERRMSG_SIZE]; /* error message */
  char		 sqlstate[SQLSTATE_LENGTH+1];
  /* Types of input parameters should be sent to server */
  my_bool        send_types_to_server;
  my_bool        bind_param_done;      /* input buffers were supplied */
  my_bool        bind_result_done;     /* output buffers were supplied */
  /* mysql_stmt_close() had to cancel this result */
  my_bool       unbuffered_fetch_cancelled;  
  /*
    Is set to true if we need to calculate field->max_length for 
    metadata fields when doing mysql_stmt_store_result.
  */
  my_bool       update_max_length;     
} 
alias st_mysql_stmt MYSQL_STMT;

enum enum_stmt_attr_type
{
  /*
    When doing mysql_stmt_store_result calculate max_length attribute
    of statement metadata. This is to be consistent with the old API, 
    where this was done automatically.
    In the new API we do that only by request because it slows down
    mysql_stmt_store_result sufficiently.
  */
  STMT_ATTR_UPDATE_MAX_LENGTH
};


struct st_mysql_methods
{
  my_bool (*read_query_result)(MYSQL *mysql);
  my_bool (*advanced_command)(MYSQL *mysql,
			      enum_server_command command,
			       char *header,
			      ulong header_length,
			       char *arg,
			      ulong arg_length,
			      my_bool skip_check);
  MYSQL_DATA *(*read_rows)(MYSQL *mysql,MYSQL_FIELD *mysql_fields,
			   uint fields);
  MYSQL_RES * (*use_result)(MYSQL *mysql);
  void (*fetch_lengths)(ulong *to, 
			MYSQL_ROW column, uint field_count);
  void (*flush_use_result)(MYSQL *mysql);

}

alias st_mysql_methods  MYSQL_METHODS;


MYSQL_STMT *  mysql_stmt_init(MYSQL *mysql);
int  mysql_stmt_prepare(MYSQL_STMT *stmt,  char *query,
                               ulong length);
int  mysql_stmt_execute(MYSQL_STMT *stmt);
int  mysql_stmt_fetch(MYSQL_STMT *stmt);
int  mysql_stmt_fetch_column(MYSQL_STMT *stmt, MYSQL_BIND *bind, 
                                    uint column,
                                    ulong offset);
int  mysql_stmt_store_result(MYSQL_STMT *stmt);
ulong  mysql_stmt_param_count(MYSQL_STMT * stmt);
my_bool  mysql_stmt_attr_set(MYSQL_STMT *stmt,
                                    enum_stmt_attr_type attr_type,
                                     void *attr);
my_bool  mysql_stmt_attr_get(MYSQL_STMT *stmt,
                                     enum_stmt_attr_type attr_type,
                                    void *attr);
my_bool  mysql_stmt_bind_param(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool  mysql_stmt_bind_result(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool  mysql_stmt_close(MYSQL_STMT * stmt);
my_bool  mysql_stmt_reset(MYSQL_STMT * stmt);
my_bool  mysql_stmt_free_result(MYSQL_STMT *stmt);
my_bool  mysql_stmt_send_long_data(MYSQL_STMT *stmt, 
                                          uint param_number,
                                           char *data, 
                                          ulong length);
MYSQL_RES * mysql_stmt_result_metadata(MYSQL_STMT *stmt);
MYSQL_RES * mysql_stmt_param_metadata(MYSQL_STMT *stmt);
uint  mysql_stmt_errno(MYSQL_STMT * stmt);
 char * mysql_stmt_error(MYSQL_STMT * stmt);
 char * mysql_stmt_sqlstate(MYSQL_STMT * stmt);
MYSQL_ROW_OFFSET  mysql_stmt_row_seek(MYSQL_STMT *stmt, 
                                             MYSQL_ROW_OFFSET offset);
MYSQL_ROW_OFFSET  mysql_stmt_row_tell(MYSQL_STMT *stmt);
void  mysql_stmt_data_seek(MYSQL_STMT *stmt, my_ulong offset);
my_ulong  mysql_stmt_num_rows(MYSQL_STMT *stmt);
my_ulong  mysql_stmt_affected_rows(MYSQL_STMT *stmt);
my_ulong  mysql_stmt_insert_id(MYSQL_STMT *stmt);
uint  mysql_stmt_field_count(MYSQL_STMT *stmt);

my_bool  mysql_commit(MYSQL * mysql);
my_bool  mysql_rollback(MYSQL * mysql);
my_bool  mysql_autocommit(MYSQL * mysql, my_bool auto_mode);
my_bool  mysql_more_results(MYSQL *mysql);
int  mysql_next_result(MYSQL *mysql);
void  mysql_close(MYSQL *sock);


/* status return codes */
const int  MYSQL_NO_DATA=      100;

//#define mysql_reload(mysql) mysql_refresh((mysql),REFRESH_GRANT)

// #ifdef USE_OLD_FUNCTIONS
// MYSQL *		 mysql_connect(MYSQL *mysql,  char *host,
// 				       char *user,  char *passwd);
// int		 mysql_create_db(MYSQL *mysql,  char *DB);
// int		 mysql_drop_db(MYSQL *mysql,  char *DB);
// #define	 mysql_reload(mysql) mysql_refresh((mysql),REFRESH_GRANT)
// #endif
// #define HAVE_MYSQL_REAL_CONNECT

/*
  The following functions are mainly exported because of mysqlbinlog;
  They are not for general usage
*/

// #define simple_command(mysql, command, arg, length, skip_check) \
//   (*(mysql)->methods->advanced_command)(mysql, command,         \
// 					NullS, 0, arg, length, skip_check)
ulong net_safe_read(MYSQL* mysql);

// #ifdef __NETWARE__
// #pragma pack(pop)		/* restore alignment */
// #endif

// #ifdef	__cplusplus
// }
// #endif

//#endif /* _mysql_h */




// #include "mysql_com.h"
// #include "mysql_time.h"
// #include "mysql_version.h"
// #include "typelib.h"
// #include "my_alloc.h"
