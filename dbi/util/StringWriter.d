module dbi.util.StringWriter;

import CStdlib = tango.stdc.stdlib;
import tango.core.Memory;

interface IDisposableString
{
	char[] get();
	void free();
}

class DisposableStringWriter_(bool AllowCustomAlloc = false) : IDisposableString
{
	this(size_t initSize = short.max/2, size_t growSize = 8192)
	{
		forwardReserve(initSize);
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
		void function(void* p) free = function void(void* p) {
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
	char[] forwardReserve(size_t x)
	{
		auto targetSize = used + x;
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
	
	void forwardAdvance(size_t x)
	{
		if(buffer.length < used + x) forwardReserve(x);
		used += x;
	}
	
	void backup(size_t n = 1)
	{
		assert(n <= used);
		used -= n;
	}
	
	/**
	 * Replaces the previously written character with the
	 * provided character c 
	 */
	void correct(char c)
	{
		debug assert(used);
		buffer[used-1] = c;
	}

	char[] getOpenBuffer()
	{
		return buffer[used .. $];
	}
	
	/** 
	 * Returns: The current length of the array that has been written to (not the size of
	 * the buffer).
	 */
	size_t length()
	{
		return used;
	}
	
	void write(char[][] strs...)
	{
		size_t totalLen;
		foreach(str;strs) totalLen += str.length;
		forwardReserve(totalLen);
		foreach(str; strs)
		{
			size_t len = str.length;
			buffer[used .. used + len] = str;
			used += len;
		}
	}
	alias write opCall;
	
	/**
	 * Exposes raw buffer writing.
	 * 
	 * Params:
	 *     writeDg = the delegate which will write to the exposed buffer.  this
	 *     	delegate must return the number of bytes written.
	 */
	void write(size_t delegate(void[] buf) writeDg)
	{
		used += writeDg(buffer[used..$]);
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
	void write(size_t reserveSize, size_t delegate(void[] buf) writeDg)
	{
		forwardReserve(reserveSize);
		used += writeDg(buffer[used..$]);
	}
	
	/**
	 * Appends to the string
	 */
	void opCatAssign(char ch)
	{
		forwardReserve(1);	
		buffer[used] = ch;
		++used;
	}
	
	/**
	 * Appends to the string
	 */
	void opCatAssign(char[] str)
	{
		auto len = str.length;
		forwardReserve(len);	
		buffer[used .. used + len] = str;
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
	 * Returns: The string that has been written.  (Essentially returns a 
	 * slice of the string buffer up to the last character that has been written.)
	 */
	char[] get()
	{
		return buffer[0..used];
	}
	
	void reset()
	{
		/+if(buffer.length) free;
		buffer = (cast(char*)alloc(growSize))[0 .. growSize];+/
		used = 0;
	}
	
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

alias DisposableStringWriter_!() DisposableStringWriter;

unittest
{
	auto w = new DisposableStringWriter(5);
	w ~= "hello ";
	w ~= "world";
	w ~= " i";
	w ~= " am writing some strings ";
	assert(w.get == "hello world i am writing some strings ", w.get);
	w.reset;
}