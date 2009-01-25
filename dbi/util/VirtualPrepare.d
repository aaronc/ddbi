module dbi.util.VirtualPrepare;

size_t[] getParamIndices(char[] sql) {
	size_t[] paramIndices;
	auto len = sql.length;
	for(size_t i = 0; i < len; ++i)
	{
		if(sql[i] == '\?')
			paramIndices ~= i;
	}
	return paramIndices;
}

