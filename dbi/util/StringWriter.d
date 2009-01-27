module dbi.util.StringWriter;

import CStdlib = tango.stdc.stdlib;
import tango.core.Memory;

class SqlStringWriter_(bool AllowCustomAlloc = false)
{
	alias SqlStringWriter_!(AllowCustomAlloc) TypeOfThis;
	
	this(size_t initSize = short.max/2, size_t growSize = 8192)
	{
		reserve(initSize);
		this.growSize = growSize;
	}
	
	/**
	 * The string grow size
	 */
	size_t growSize;
	
	static if(AllowCustomAlloc)
	{
		void* function(size_t x) alloc = function void*(size_t x) {
			return CStdlib.malloc(x);
		};
		void function(void* p) release = function void(void* p) {
			CStdlib.free(p);
		};
	}
	else
	{
		alias GC.malloc alloc;
		alias GC.free release;
	}
	
	protected char[] buffer;
	protected size_t used = 0;
	
	/**
	 * Ensures that the buffer has space to write sz elements and
	 * does appropriate allocation as necessary.
	 * Params:
	 *     sz = the buffer length to reserve
	 * Returns:
	 */
	char[] reserve(size_t sz)
	{
		auto targetSize = used + sz;
		if(targetSize >= buffer.length) {
			uint newSize = buffer.length + growSize;
			if(newSize < targetSize) newSize = targetSize;
			char[] temp = (cast(char*)alloc(newSize))[0 .. newSize];
			temp[0 .. buffer.length] = buffer;
			release(buffer.ptr);
			buffer = temp;
		}
		return buffer[used .. $];
	}
	
	/**
	 * Decrements the buffer index essentially erasing data that was written 
	 * Params:
	 *     n = the number of characters to backup
	 * Returns:
	 */
	final TypeOfThis backup(size_t n = 1)
	{
		assert(n <= used);
		used -= n;
		return this;
	}
	
	/**
	 * Replaces the previously written character with the
	 * provided character c 
	 */
	final TypeOfThis correct(char c)
	{
		debug assert(used);
		buffer[used-1] = c;
		return this;
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
	 * Alias for write
	 */
	alias write opCall;
	
	/**
	 * 
	 */
	final TypeOfThis write(char[][] strs...)
	{
		size_t totalLen;
		foreach(str;strs) totalLen += str.length;
		reserve(totalLen);
		foreach(str; strs)
		{
			size_t len = str.length;
			buffer[used .. used + len] = str;
			used += len;
		}
		return this;
	}
	
	/**
	 * Exposes raw buffer for writing
	 * 
	 * Params:
	 *     writeDg = the delegate which will write to the exposed buffer.  this
	 *     	delegate must return the number of bytes written.
	 */
	final TypeOfThis write(size_t delegate(void[] buf) writeDg)
	{
		used += writeDg(buffer[used..$]);
		return this;
	}
	
	/**
	 * Reserves a certain amount of space in the write buffer
	 * and exposes that raw buffer to writing	
	 * 
	 * Params:
	 * 	   reserveSize
	 *     writeDg = the delegate which will write to the exposed buffer.  this
	 *     	delegate must return the number of bytes written.
	 */
	final TypeOfThis write(size_t reserveSize, size_t delegate(void[] buf) writeDg)
	{
		reserve(reserveSize);
		used += writeDg(buffer[used..$]);
		return this;
	}
	
	/**
	 * Appends to the string
	 */
	void opCatAssign(char ch)
	{
		reserve(1);	
		buffer[used] = ch;
		++used;
	}
	
	/**
	 * Appends to the string
	 */
	void opCatAssign(char[] str)
	{
		auto len = str.length;
		reserve(len);	
		buffer[used .. used + len] = str;
		used += len;
	}
	
	char[] getWriteBuffer(size_t x)
	{
		reserve(x);
		auto buf = buffer[used .. used + x];
		used += x;
		return buf;
	}
	
	/**
	 * 
	 * Returns: The string that has been written.  (Essentially returns a 
	 * slice of the string buffer up to the last character that has been written.)
	 */
	char[] get()
	{
		return buffer[0..used];
	}
	
	/**
	 * Resets buffer for reuse
	 */
	void reset()
	{
		used = 0;
	}

	/**
	 * Frees memory that has been allocated
	 */
	void free()
	{
		if(buffer.length) {
			release(buffer.ptr);
			buffer = null;
		}
	}
	
	~this()
	{
		free;
	}
}

alias SqlStringWriter_!() SqlStringWriter;

unittest
{
	auto w = new SqlStringWriter(5);
	w ~= "hello ";
	w ~= "world";
	w ~= " i";
	w ~= " am writing some strings ";
	assert(w.get == "hello world i am writing some strings ", w.get);
	w.reset;
}