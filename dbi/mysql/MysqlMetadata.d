module dbi.mysql.MysqlMetadata;

version (dbi_mysql) {
	
import dbi.mysql.c.mysql;
import dbi.Metadata;

FieldInfo[] getFieldMetadata(MYSQL_FIELD[] fields)
{
	FieldInfo[] metadata;
	
	auto nFields = fields.length;
	metadata.length = nFields;
	
	for(uint i = 0; i < nFields; i++)
	{
		metadata[i].name = fields[i].name[0 .. fields[i].name_length].dup;
		metadata[i].type = fromMysqlType(fields[i].type, fields[i].flags);
	}
	
	return metadata;
}

BindType fromMysqlType(enum_field_types type, uint flags)
{
	bool unsigned = flags & UNSIGNED_FLAG ? true : false;
	with(enum_field_types) {
	with(BindType) {
		switch(type)
		{
		case MYSQL_TYPE_BIT:
			return Bool;
		case MYSQL_TYPE_TINY:
			return unsigned ? UByte : Byte;
        case MYSQL_TYPE_SHORT:
        	return unsigned ? UShort : Short;
        case MYSQL_TYPE_LONG:
        case MYSQL_TYPE_INT24:
        	return unsigned ? UInt : Int;
        case MYSQL_TYPE_LONGLONG:
        	return unsigned ? ULong : Long;
		case MYSQL_TYPE_DECIMAL:
        case MYSQL_TYPE_FLOAT:
        	return Float;
        case MYSQL_TYPE_DOUBLE:
        	return Double;
        case MYSQL_TYPE_TIMESTAMP:
        case MYSQL_TYPE_DATE:
        case MYSQL_TYPE_TIME:
        case MYSQL_TYPE_DATETIME:
        	return DateTime;
        case MYSQL_TYPE_VAR_STRING:
        case MYSQL_TYPE_STRING:
        case MYSQL_TYPE_VARCHAR:
        	return String;
        case MYSQL_TYPE_NULL:
        	return Null;
        case MYSQL_TYPE_TINY_BLOB:
        case MYSQL_TYPE_MEDIUM_BLOB:
        case MYSQL_TYPE_LONG_BLOB:
        case MYSQL_TYPE_BLOB:
        	return Binary;  	
        case MYSQL_TYPE_YEAR:
        case MYSQL_TYPE_NEWDATE:
        case MYSQL_TYPE_NEWDECIMAL:
        case MYSQL_TYPE_ENUM:
        case MYSQL_TYPE_SET:
		case MYSQL_TYPE_GEOMETRY:
		default:
			debug assert(false, "Unsupported type");
			return Null;
		}
	}
	}
}

}