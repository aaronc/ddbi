module dbi.util.StringWriter;

//import dbi.util.Memory;

import CStdlib = tango.stdc.stdlib;

/**
 * Allows for concatentation to arrays of type T where arrays 
 * grow in steps of size growSize.  Designed to reduce
 * array-reallocation and copying.
 * 
 */
class DisposableStringWriter
{
	/**
	 * 
	 * Params:
	 *     initSize = the initial size of the array 
	 *     growSize = the amount by which the array size is increase each time it is
	 *     grows
	 */
	this(size_t initSize = 100, size_t growSize = 100)
	{
		this.initSize = initSize;
		this.growSize = growSize;
		buffer = (cast(char*)CStdlib.malloc(initSize))[0 .. initSize];
	}
	
	protected size_t initSize;
	
	/**
	 * The array grow size
	 */
	size_t growSize;
	
	protected char[] buffer;
	protected size_t used = 0;
	protected void forwardReserve(size_t x)
	{
		auto targetSize = used + x;
		if(targetSize >= buffer.length) {
			uint newSize = buffer.length + growSize;
			if(newSize < targetSize) newSize = targetSize;
			char[] temp = (cast(char*)CStdlib.malloc(newSize))[0 .. newSize];
			temp[0 .. buffer.length] = buffer;
			CStdlib.free(buffer.ptr);
			buffer = temp;
		}
	}
	
	/** 
	 * Returns: The current length of the array that has been written to (not the size of
	 * the buffer).
	 */
	size_t length()
	{
		return used;
	}
	
	/**
	 * Appends an array of elements to the array
	 */
	void opCatAssign(char[] t)
	{
		auto len = t.length;
		forwardReserve(len);	
		buffer[used .. used + len] = t;
		used += len;
	}
	
	char[] getWriteBuffer(size_t x)
	{
		forwardReserve(x);
		auto buf = buffer[used .. used + x];
		used += x;
		return buf;
	}
	
	/**
	 * 
	 * Returns: The array that has been written.  (Essentially returns a 
	 * slice of the array buffer up to the last element that has been written.)
	 */
	char[] get()
	{
		return buffer[0..used];
	}
	
	void free()
	{
		CStdlib.free(buffer.ptr);
	}
}

unittest
{
	auto w = new DisposableStringWriter(5, 5);
	w ~= "hello ";
	w ~= "world";
	w ~= " i";
	w ~= " am writing some strings ";
	assert(w.get == "hello world i am writing some strings ", w.get);
}