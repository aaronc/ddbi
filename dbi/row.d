/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.Row;

private import dbi.DBIException;

private import std.stdio, std.conv;

/**
 * Provide access to a single row in a result set.
 */
final class Row {
	/**
	 * Get a field's contents by index.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Examples:
	 *	(begin code)
	 *	Row row = res.fetchRow();
	 *	printf("first=%.*s, last=%.*s\n", row[0], row[1]);
	 *	(end code)
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] opIndex (int idx) {
		return get(idx);
	}

	/**
	 * Get a field's contents by field _name.
	 *
	 * Params:
	 *	name = Field _name.
	 *
	 * Example:
	 *	(begin code)
	 *	Row row = res.fetchRow();
	 *	printf("first=%.*s, last=%.*s\n", row["first"], row["last"]);
	 *	(end code)
	 *
	 * Returns: 
	 *	The field's contents.
	 */
	char[] opIndex (char[] name) {
		return get(name);
	}

	/**
	 * Get a field's contents by index.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] get (int idx) {
		return fieldValues[idx];
	}

	/**
	 * Get a field's contents by field _name.
	 *
	 * Params:
	 *	name = Field _name.
	 *
	 * Returns:
	 *	The field's contents.
	 */
	char[] get (char[] name) {
		return fieldValues[getFieldIndex(name)];
	}

	/**
	 * Get a field's index by field _name.
	 *
	 * Params:
	 *	name = Field _name.
	 *
	 * Returns:
	 *	The field's index.
	 */
	int getFieldIndex (char[] name) {
		for (int idx = 0; idx < fieldNames.length; idx++) {
			if (fieldNames[idx] == name) {
				return idx;
			}
		}
		throw new DBIException("The name '" ~ name ~ "' is not a valid index.");
	}

	/**
	 * Get the field type.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Returns:
	 *	The field's type.
	 */
	int getFieldType (int idx) {
		return fieldTypes[idx];
	}

	/**
	 * Get a field's SQL declaration.
	 *
	 * Params:
	 *	idx = Field index.
	 *
	 * Returns:
	 *	The field's SQL declaration.
	 */
	char[] getFieldDecl (int idx) {
		return fieldDecls[idx];
	}

	/**
	 * Add a new field to this row.
	 *
	 * Params:
	 *	name = Name.
	 *	value = Value.
	 *	decl = SQL declaration, i.e. varchar(20), decimal(12,2), etc...
	 *	type = SQL _type.
	 *
	 * Todo:
	 *	SQL _type should be defined by the D DBI DBD interface spec, therefore
	 *	each DBD module will act exactly alike.
	 */
	void addField (char[] name, char[] value, char[] decl, int type) {
		fieldNames ~= name.dup;
		fieldValues ~= value.dup;
		fieldDecls ~= decl.dup;
		fieldTypes ~= type;
	}

	private:
	char[][] fieldNames;
	char[][] fieldValues;
	char[][] fieldDecls;
	int[] fieldTypes;
}

unittest {
	void s1 (char[] s) {
		printf("%.*s\n", s);
	}
	void s2 (char[] s) {
		printf("   ...%.*s\n", s);
	}

	s1("dbi.Row:");
	Row r1 = new Row();
	r1.addField("name", "John Doe", "text",    3);
	r1.addField("age",  "23",       "integer", 1);

	s2("get(int)");
	assert(r1.get(0) == "John Doe");

	s2("get(char[])");
	assert(r1.get("name") == "John Doe");

	s2("[int]");
	assert(r1[0] == "John Doe");

	s2("[char[]]");
	assert(r1["age"] == "23");

	s2("getFieldIndex");
	assert(r1.getFieldIndex("name") == 0);

	s2("getFieldType");
	assert(r1.getFieldType(0) == 3);
    
	s2("getFieldDecl");
	assert(r1.getFieldDecl(1) == "integer");
}