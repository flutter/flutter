/*
 * wincecompat.c : wince compatiblity module
 *
 * See Copyright for the status of this software.
 *
 * javier@tiresiassoft.com
 *
 * 17 Sep 2002  created
 */

#include "wincecompat.h"

char *strError[]= {"Error 0","","No such file or directory","","","","","Arg list too long",
	"Exec format error","Bad file number","","","Not enough core","Permission denied","","",
	"","File exists","Cross-device link","","","","Invalid argument","","Too many open files",
	"","","","No space left on device","","","","","Math argument","Result too large","",
	"Resource deadlock would occur", "Unknown error under wince"};


int errno=0;

int read(int handle, char *buffer, unsigned int len)
{
	return(fread(&buffer[0], len, 1, (FILE *) handle));
}

int write(int handle, const char *buffer, unsigned int len)
{
	return(fwrite(&buffer[0], len,1,(FILE *) handle));
}

int open(const char *filename,int oflag, ...)
{
	char mode[3]; /* mode[0] ="w/r/a"  mode[1]="+" */
	mode[2]=0;
	if ( oflag==(O_WRONLY|O_CREAT) )
		mode[0]='w';
	else if (oflag==O_RDONLY)
		mode[0]='r';
	return (int) fopen(filename, mode);
}

int close(int handle)
{
	return ( fclose((FILE *) handle) );
}


char *getcwd( char *buffer, unsigned int size)
{
    /* Windows CE don't have the concept of a current directory
     * so we just return NULL to indicate an error
     */
    return NULL;
}

char *getenv( const char *varname )
{
	return NULL;
}

char *strerror(int errnum)
{
	if (errnum>MAX_STRERROR)
		return strError[MAX_STRERROR];
	else
		return strError[errnum];
}
