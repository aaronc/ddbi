module dbi.Row;

public import dbi.Metadata;

class Row
{
	package this(FieldInfo[] metadata)
	{
		this.metadata = metadata;
	}
	
	char[][] values;
	FieldInfo[] metadata;
}