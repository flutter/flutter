/*
 * xmlIO.c : implementation of the I/O interfaces used by the parser
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 *
 * 14 Nov 2000 ht - for VMS, truncated name of long functions to under 32 char
 */

#define IN_LIBXML
#include "libxml.h"

#include <string.h>
#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif


#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_ZLIB_H
#include <zlib.h>
#endif
#ifdef HAVE_LZMA_H
#include <lzma.h>
#endif

#if defined(WIN32) || defined(_WIN32)
#include <windows.h>
#endif

#if defined(_WIN32_WCE)
#include <winnls.h> /* for CP_UTF8 */
#endif

/* Figure a portable way to know if a file is a directory. */
#ifndef HAVE_STAT
#  ifdef HAVE__STAT
     /* MS C library seems to define stat and _stat. The definition
        is identical. Still, mapping them to each other causes a warning. */
#    ifndef _MSC_VER
#      define stat(x,y) _stat(x,y)
#    endif
#    define HAVE_STAT
#  endif
#else
#  ifdef HAVE__STAT
#    if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
#      define stat _stat
#    endif
#  endif
#endif
#ifdef HAVE_STAT
#  ifndef S_ISDIR
#    ifdef _S_ISDIR
#      define S_ISDIR(x) _S_ISDIR(x)
#    else
#      ifdef S_IFDIR
#        ifndef S_IFMT
#          ifdef _S_IFMT
#            define S_IFMT _S_IFMT
#          endif
#        endif
#        ifdef S_IFMT
#          define S_ISDIR(m) (((m) & S_IFMT) == S_IFDIR)
#        endif
#      endif
#    endif
#  endif
#endif

#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/xmlIO.h>
#include <libxml/uri.h>
#include <libxml/nanohttp.h>
#include <libxml/nanoftp.h>
#include <libxml/xmlerror.h>
#ifdef LIBXML_CATALOG_ENABLED
#include <libxml/catalog.h>
#endif
#include <libxml/globals.h>

#include "buf.h"
#include "enc.h"

/* #define VERBOSE_FAILURE */
/* #define DEBUG_EXTERNAL_ENTITIES */
/* #define DEBUG_INPUT */

#ifdef DEBUG_INPUT
#define MINLEN 40
#else
#define MINLEN 4000
#endif

/*
 * Input I/O callback sets
 */
typedef struct _xmlInputCallback {
    xmlInputMatchCallback matchcallback;
    xmlInputOpenCallback opencallback;
    xmlInputReadCallback readcallback;
    xmlInputCloseCallback closecallback;
} xmlInputCallback;

#define MAX_INPUT_CALLBACK 15

static xmlInputCallback xmlInputCallbackTable[MAX_INPUT_CALLBACK];
static int xmlInputCallbackNr = 0;
static int xmlInputCallbackInitialized = 0;

#ifdef LIBXML_OUTPUT_ENABLED
/*
 * Output I/O callback sets
 */
typedef struct _xmlOutputCallback {
    xmlOutputMatchCallback matchcallback;
    xmlOutputOpenCallback opencallback;
    xmlOutputWriteCallback writecallback;
    xmlOutputCloseCallback closecallback;
} xmlOutputCallback;

#define MAX_OUTPUT_CALLBACK 15

static xmlOutputCallback xmlOutputCallbackTable[MAX_OUTPUT_CALLBACK];
static int xmlOutputCallbackNr = 0;
static int xmlOutputCallbackInitialized = 0;

xmlOutputBufferPtr
xmlAllocOutputBufferInternal(xmlCharEncodingHandlerPtr encoder);
#endif /* LIBXML_OUTPUT_ENABLED */

/************************************************************************
 *									*
 *		Tree memory error handler				*
 *									*
 ************************************************************************/

static const char *IOerr[] = {
    "Unknown IO error",         /* UNKNOWN */
    "Permission denied",	/* EACCES */
    "Resource temporarily unavailable",/* EAGAIN */
    "Bad file descriptor",	/* EBADF */
    "Bad message",		/* EBADMSG */
    "Resource busy",		/* EBUSY */
    "Operation canceled",	/* ECANCELED */
    "No child processes",	/* ECHILD */
    "Resource deadlock avoided",/* EDEADLK */
    "Domain error",		/* EDOM */
    "File exists",		/* EEXIST */
    "Bad address",		/* EFAULT */
    "File too large",		/* EFBIG */
    "Operation in progress",	/* EINPROGRESS */
    "Interrupted function call",/* EINTR */
    "Invalid argument",		/* EINVAL */
    "Input/output error",	/* EIO */
    "Is a directory",		/* EISDIR */
    "Too many open files",	/* EMFILE */
    "Too many links",		/* EMLINK */
    "Inappropriate message buffer length",/* EMSGSIZE */
    "Filename too long",	/* ENAMETOOLONG */
    "Too many open files in system",/* ENFILE */
    "No such device",		/* ENODEV */
    "No such file or directory",/* ENOENT */
    "Exec format error",	/* ENOEXEC */
    "No locks available",	/* ENOLCK */
    "Not enough space",		/* ENOMEM */
    "No space left on device",	/* ENOSPC */
    "Function not implemented",	/* ENOSYS */
    "Not a directory",		/* ENOTDIR */
    "Directory not empty",	/* ENOTEMPTY */
    "Not supported",		/* ENOTSUP */
    "Inappropriate I/O control operation",/* ENOTTY */
    "No such device or address",/* ENXIO */
    "Operation not permitted",	/* EPERM */
    "Broken pipe",		/* EPIPE */
    "Result too large",		/* ERANGE */
    "Read-only file system",	/* EROFS */
    "Invalid seek",		/* ESPIPE */
    "No such process",		/* ESRCH */
    "Operation timed out",	/* ETIMEDOUT */
    "Improper link",		/* EXDEV */
    "Attempt to load network entity %s", /* XML_IO_NETWORK_ATTEMPT */
    "encoder error",		/* XML_IO_ENCODER */
    "flush error",
    "write error",
    "no input",
    "buffer full",
    "loading error",
    "not a socket",		/* ENOTSOCK */
    "already connected",	/* EISCONN */
    "connection refused",	/* ECONNREFUSED */
    "unreachable network",	/* ENETUNREACH */
    "adddress in use",		/* EADDRINUSE */
    "already in use",		/* EALREADY */
    "unknown address familly",	/* EAFNOSUPPORT */
};

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
/**
 * __xmlIOWin32UTF8ToWChar:
 * @u8String:  uft-8 string
 *
 * Convert a string from utf-8 to wchar (WINDOWS ONLY!)
 */
static wchar_t *
__xmlIOWin32UTF8ToWChar(const char *u8String)
{
    wchar_t *wString = NULL;

    if (u8String) {
        int wLen =
            MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, u8String,
                                -1, NULL, 0);
        if (wLen) {
            wString = xmlMalloc(wLen * sizeof(wchar_t));
            if (wString) {
                if (MultiByteToWideChar
                    (CP_UTF8, 0, u8String, -1, wString, wLen) == 0) {
                    xmlFree(wString);
                    wString = NULL;
                }
            }
        }
    }

    return wString;
}
#endif

/**
 * xmlIOErrMemory:
 * @extra:  extra informations
 *
 * Handle an out of memory condition
 */
static void
xmlIOErrMemory(const char *extra)
{
    __xmlSimpleError(XML_FROM_IO, XML_ERR_NO_MEMORY, NULL, NULL, extra);
}

/**
 * __xmlIOErr:
 * @code:  the error number
 * @
 * @extra:  extra informations
 *
 * Handle an I/O error
 */
void
__xmlIOErr(int domain, int code, const char *extra)
{
    unsigned int idx;

    if (code == 0) {
#ifdef HAVE_ERRNO_H
	if (errno == 0) code = 0;
#ifdef EACCES
        else if (errno == EACCES) code = XML_IO_EACCES;
#endif
#ifdef EAGAIN
        else if (errno == EAGAIN) code = XML_IO_EAGAIN;
#endif
#ifdef EBADF
        else if (errno == EBADF) code = XML_IO_EBADF;
#endif
#ifdef EBADMSG
        else if (errno == EBADMSG) code = XML_IO_EBADMSG;
#endif
#ifdef EBUSY
        else if (errno == EBUSY) code = XML_IO_EBUSY;
#endif
#ifdef ECANCELED
        else if (errno == ECANCELED) code = XML_IO_ECANCELED;
#endif
#ifdef ECHILD
        else if (errno == ECHILD) code = XML_IO_ECHILD;
#endif
#ifdef EDEADLK
        else if (errno == EDEADLK) code = XML_IO_EDEADLK;
#endif
#ifdef EDOM
        else if (errno == EDOM) code = XML_IO_EDOM;
#endif
#ifdef EEXIST
        else if (errno == EEXIST) code = XML_IO_EEXIST;
#endif
#ifdef EFAULT
        else if (errno == EFAULT) code = XML_IO_EFAULT;
#endif
#ifdef EFBIG
        else if (errno == EFBIG) code = XML_IO_EFBIG;
#endif
#ifdef EINPROGRESS
        else if (errno == EINPROGRESS) code = XML_IO_EINPROGRESS;
#endif
#ifdef EINTR
        else if (errno == EINTR) code = XML_IO_EINTR;
#endif
#ifdef EINVAL
        else if (errno == EINVAL) code = XML_IO_EINVAL;
#endif
#ifdef EIO
        else if (errno == EIO) code = XML_IO_EIO;
#endif
#ifdef EISDIR
        else if (errno == EISDIR) code = XML_IO_EISDIR;
#endif
#ifdef EMFILE
        else if (errno == EMFILE) code = XML_IO_EMFILE;
#endif
#ifdef EMLINK
        else if (errno == EMLINK) code = XML_IO_EMLINK;
#endif
#ifdef EMSGSIZE
        else if (errno == EMSGSIZE) code = XML_IO_EMSGSIZE;
#endif
#ifdef ENAMETOOLONG
        else if (errno == ENAMETOOLONG) code = XML_IO_ENAMETOOLONG;
#endif
#ifdef ENFILE
        else if (errno == ENFILE) code = XML_IO_ENFILE;
#endif
#ifdef ENODEV
        else if (errno == ENODEV) code = XML_IO_ENODEV;
#endif
#ifdef ENOENT
        else if (errno == ENOENT) code = XML_IO_ENOENT;
#endif
#ifdef ENOEXEC
        else if (errno == ENOEXEC) code = XML_IO_ENOEXEC;
#endif
#ifdef ENOLCK
        else if (errno == ENOLCK) code = XML_IO_ENOLCK;
#endif
#ifdef ENOMEM
        else if (errno == ENOMEM) code = XML_IO_ENOMEM;
#endif
#ifdef ENOSPC
        else if (errno == ENOSPC) code = XML_IO_ENOSPC;
#endif
#ifdef ENOSYS
        else if (errno == ENOSYS) code = XML_IO_ENOSYS;
#endif
#ifdef ENOTDIR
        else if (errno == ENOTDIR) code = XML_IO_ENOTDIR;
#endif
#ifdef ENOTEMPTY
        else if (errno == ENOTEMPTY) code = XML_IO_ENOTEMPTY;
#endif
#ifdef ENOTSUP
        else if (errno == ENOTSUP) code = XML_IO_ENOTSUP;
#endif
#ifdef ENOTTY
        else if (errno == ENOTTY) code = XML_IO_ENOTTY;
#endif
#ifdef ENXIO
        else if (errno == ENXIO) code = XML_IO_ENXIO;
#endif
#ifdef EPERM
        else if (errno == EPERM) code = XML_IO_EPERM;
#endif
#ifdef EPIPE
        else if (errno == EPIPE) code = XML_IO_EPIPE;
#endif
#ifdef ERANGE
        else if (errno == ERANGE) code = XML_IO_ERANGE;
#endif
#ifdef EROFS
        else if (errno == EROFS) code = XML_IO_EROFS;
#endif
#ifdef ESPIPE
        else if (errno == ESPIPE) code = XML_IO_ESPIPE;
#endif
#ifdef ESRCH
        else if (errno == ESRCH) code = XML_IO_ESRCH;
#endif
#ifdef ETIMEDOUT
        else if (errno == ETIMEDOUT) code = XML_IO_ETIMEDOUT;
#endif
#ifdef EXDEV
        else if (errno == EXDEV) code = XML_IO_EXDEV;
#endif
#ifdef ENOTSOCK
        else if (errno == ENOTSOCK) code = XML_IO_ENOTSOCK;
#endif
#ifdef EISCONN
        else if (errno == EISCONN) code = XML_IO_EISCONN;
#endif
#ifdef ECONNREFUSED
        else if (errno == ECONNREFUSED) code = XML_IO_ECONNREFUSED;
#endif
#ifdef ETIMEDOUT
        else if (errno == ETIMEDOUT) code = XML_IO_ETIMEDOUT;
#endif
#ifdef ENETUNREACH
        else if (errno == ENETUNREACH) code = XML_IO_ENETUNREACH;
#endif
#ifdef EADDRINUSE
        else if (errno == EADDRINUSE) code = XML_IO_EADDRINUSE;
#endif
#ifdef EINPROGRESS
        else if (errno == EINPROGRESS) code = XML_IO_EINPROGRESS;
#endif
#ifdef EALREADY
        else if (errno == EALREADY) code = XML_IO_EALREADY;
#endif
#ifdef EAFNOSUPPORT
        else if (errno == EAFNOSUPPORT) code = XML_IO_EAFNOSUPPORT;
#endif
        else code = XML_IO_UNKNOWN;
#endif /* HAVE_ERRNO_H */
    }
    idx = 0;
    if (code >= XML_IO_UNKNOWN) idx = code - XML_IO_UNKNOWN;
    if (idx >= (sizeof(IOerr) / sizeof(IOerr[0]))) idx = 0;

    __xmlSimpleError(domain, code, NULL, IOerr[idx], extra);
}

/**
 * xmlIOErr:
 * @code:  the error number
 * @extra:  extra informations
 *
 * Handle an I/O error
 */
static void
xmlIOErr(int code, const char *extra)
{
    __xmlIOErr(XML_FROM_IO, code, extra);
}

/**
 * __xmlLoaderErr:
 * @ctx: the parser context
 * @extra:  extra informations
 *
 * Handle a resource access error
 */
void
__xmlLoaderErr(void *ctx, const char *msg, const char *filename)
{
    xmlParserCtxtPtr ctxt = (xmlParserCtxtPtr) ctx;
    xmlStructuredErrorFunc schannel = NULL;
    xmlGenericErrorFunc channel = NULL;
    void *data = NULL;
    xmlErrorLevel level = XML_ERR_ERROR;

    if ((ctxt != NULL) && (ctxt->disableSAX != 0) &&
        (ctxt->instate == XML_PARSER_EOF))
	return;
    if ((ctxt != NULL) && (ctxt->sax != NULL)) {
        if (ctxt->validate) {
	    channel = ctxt->sax->error;
	    level = XML_ERR_ERROR;
	} else {
	    channel = ctxt->sax->warning;
	    level = XML_ERR_WARNING;
	}
	if (ctxt->sax->initialized == XML_SAX2_MAGIC)
	    schannel = ctxt->sax->serror;
	data = ctxt->userData;
    }
    __xmlRaiseError(schannel, channel, data, ctxt, NULL, XML_FROM_IO,
                    XML_IO_LOAD_ERROR, level, NULL, 0,
		    filename, NULL, NULL, 0, 0,
		    msg, filename);

}

/************************************************************************
 *									*
 *		Tree memory error handler				*
 *									*
 ************************************************************************/
/**
 * xmlNormalizeWindowsPath:
 * @path: the input file path
 *
 * This function is obsolete. Please see xmlURIFromPath in uri.c for
 * a better solution.
 *
 * Returns a canonicalized version of the path
 */
xmlChar *
xmlNormalizeWindowsPath(const xmlChar *path)
{
    return xmlCanonicPath(path);
}

/**
 * xmlCleanupInputCallbacks:
 *
 * clears the entire input callback table. this includes the
 * compiled-in I/O.
 */
void
xmlCleanupInputCallbacks(void)
{
    int i;

    if (!xmlInputCallbackInitialized)
        return;

    for (i = xmlInputCallbackNr - 1; i >= 0; i--) {
        xmlInputCallbackTable[i].matchcallback = NULL;
        xmlInputCallbackTable[i].opencallback = NULL;
        xmlInputCallbackTable[i].readcallback = NULL;
        xmlInputCallbackTable[i].closecallback = NULL;
    }

    xmlInputCallbackNr = 0;
    xmlInputCallbackInitialized = 0;
}

/**
 * xmlPopInputCallbacks:
 *
 * Clear the top input callback from the input stack. this includes the
 * compiled-in I/O.
 *
 * Returns the number of input callback registered or -1 in case of error.
 */
int
xmlPopInputCallbacks(void)
{
    if (!xmlInputCallbackInitialized)
        return(-1);

    if (xmlInputCallbackNr <= 0)
        return(-1);

    xmlInputCallbackNr--;
    xmlInputCallbackTable[xmlInputCallbackNr].matchcallback = NULL;
    xmlInputCallbackTable[xmlInputCallbackNr].opencallback = NULL;
    xmlInputCallbackTable[xmlInputCallbackNr].readcallback = NULL;
    xmlInputCallbackTable[xmlInputCallbackNr].closecallback = NULL;

    return(xmlInputCallbackNr);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlCleanupOutputCallbacks:
 *
 * clears the entire output callback table. this includes the
 * compiled-in I/O callbacks.
 */
void
xmlCleanupOutputCallbacks(void)
{
    int i;

    if (!xmlOutputCallbackInitialized)
        return;

    for (i = xmlOutputCallbackNr - 1; i >= 0; i--) {
        xmlOutputCallbackTable[i].matchcallback = NULL;
        xmlOutputCallbackTable[i].opencallback = NULL;
        xmlOutputCallbackTable[i].writecallback = NULL;
        xmlOutputCallbackTable[i].closecallback = NULL;
    }

    xmlOutputCallbackNr = 0;
    xmlOutputCallbackInitialized = 0;
}
#endif /* LIBXML_OUTPUT_ENABLED */

/************************************************************************
 *									*
 *		Standard I/O for file accesses				*
 *									*
 ************************************************************************/

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)

/**
 *  xmlWrapOpenUtf8:
 * @path:  the path in utf-8 encoding
 * @mode:  type of access (0 - read, 1 - write)
 *
 * function opens the file specified by @path
 *
 */
static FILE*
xmlWrapOpenUtf8(const char *path,int mode)
{
    FILE *fd = NULL;
    wchar_t *wPath;

    wPath = __xmlIOWin32UTF8ToWChar(path);
    if(wPath)
    {
       fd = _wfopen(wPath, mode ? L"wb" : L"rb");
       xmlFree(wPath);
    }
    /* maybe path in native encoding */
    if(fd == NULL)
       fd = fopen(path, mode ? "wb" : "rb");

    return fd;
}

#ifdef HAVE_ZLIB_H
static gzFile
xmlWrapGzOpenUtf8(const char *path, const char *mode)
{
    gzFile fd;
    wchar_t *wPath;

    fd = gzopen (path, mode);
    if (fd)
        return fd;

    wPath = __xmlIOWin32UTF8ToWChar(path);
    if(wPath)
    {
	int d, m = (strstr(mode, "r") ? O_RDONLY : O_RDWR);
#ifdef _O_BINARY
        m |= (strstr(mode, "b") ? _O_BINARY : 0);
#endif
	d = _wopen(wPath, m);
	if (d >= 0)
	    fd = gzdopen(d, mode);
        xmlFree(wPath);
    }

    return fd;
}
#endif

/**
 *  xmlWrapStatUtf8:
 * @path:  the path in utf-8 encoding
 * @info:  structure that stores results
 *
 * function obtains information about the file or directory
 *
 */
static int
xmlWrapStatUtf8(const char *path,struct stat *info)
{
#ifdef HAVE_STAT
    int retval = -1;
    wchar_t *wPath;

    wPath = __xmlIOWin32UTF8ToWChar(path);
    if (wPath)
    {
       retval = _wstat(wPath,info);
       xmlFree(wPath);
    }
    /* maybe path in native encoding */
    if(retval < 0)
       retval = stat(path,info);
    return retval;
#else
    return -1;
#endif
}

/**
 *  xmlWrapOpenNative:
 * @path:  the path
 * @mode:  type of access (0 - read, 1 - write)
 *
 * function opens the file specified by @path
 *
 */
static FILE*
xmlWrapOpenNative(const char *path,int mode)
{
    return fopen(path,mode ? "wb" : "rb");
}

/**
 *  xmlWrapStatNative:
 * @path:  the path
 * @info:  structure that stores results
 *
 * function obtains information about the file or directory
 *
 */
static int
xmlWrapStatNative(const char *path,struct stat *info)
{
#ifdef HAVE_STAT
    return stat(path,info);
#else
    return -1;
#endif
}

typedef int (* xmlWrapStatFunc) (const char *f, struct stat *s);
static xmlWrapStatFunc xmlWrapStat = xmlWrapStatNative;
typedef FILE* (* xmlWrapOpenFunc)(const char *f,int mode);
static xmlWrapOpenFunc xmlWrapOpen = xmlWrapOpenNative;
#ifdef HAVE_ZLIB_H
typedef gzFile (* xmlWrapGzOpenFunc) (const char *f, const char *mode);
static xmlWrapGzOpenFunc xmlWrapGzOpen = gzopen;
#endif
/**
 * xmlInitPlatformSpecificIo:
 *
 * Initialize platform specific features.
 */
static void
xmlInitPlatformSpecificIo(void)
{
    static int xmlPlatformIoInitialized = 0;
    OSVERSIONINFO osvi;

    if(xmlPlatformIoInitialized)
      return;

    osvi.dwOSVersionInfoSize = sizeof(osvi);

    if(GetVersionEx(&osvi) && (osvi.dwPlatformId == VER_PLATFORM_WIN32_NT)) {
      xmlWrapStat = xmlWrapStatUtf8;
      xmlWrapOpen = xmlWrapOpenUtf8;
#ifdef HAVE_ZLIB_H
      xmlWrapGzOpen = xmlWrapGzOpenUtf8;
#endif
    } else {
      xmlWrapStat = xmlWrapStatNative;
      xmlWrapOpen = xmlWrapOpenNative;
#ifdef HAVE_ZLIB_H
      xmlWrapGzOpen = gzopen;
#endif
    }

    xmlPlatformIoInitialized = 1;
    return;
}

#endif

/**
 * xmlCheckFilename:
 * @path:  the path to check
 *
 * function checks to see if @path is a valid source
 * (file, socket...) for XML.
 *
 * if stat is not available on the target machine,
 * returns 1.  if stat fails, returns 0 (if calling
 * stat on the filename fails, it can't be right).
 * if stat succeeds and the file is a directory,
 * returns 2.  otherwise returns 1.
 */

int
xmlCheckFilename (const char *path)
{
#ifdef HAVE_STAT
    struct stat stat_buffer;
#endif
    if (path == NULL)
	return(0);

#ifdef HAVE_STAT
#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    /*
     * On Windows stat and wstat do not work with long pathname,
     * which start with '\\?\'
     */
    if ((path[0] == '\\') && (path[1] == '\\') && (path[2] == '?') &&
	(path[3] == '\\') )
	    return 1;

    if (xmlWrapStat(path, &stat_buffer) == -1)
        return 0;
#else
    if (stat(path, &stat_buffer) == -1)
        return 0;
#endif
#ifdef S_ISDIR
    if (S_ISDIR(stat_buffer.st_mode))
        return 2;
#endif
#endif /* HAVE_STAT */
    return 1;
}

/**
 * xmlNop:
 *
 * No Operation function, does nothing, no input
 *
 * Returns zero
 */
int
xmlNop(void) {
    return(0);
}

/**
 * xmlFdRead:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to read
 *
 * Read @len bytes to @buffer from the I/O channel.
 *
 * Returns the number of bytes written
 */
static int
xmlFdRead (void * context, char * buffer, int len) {
    int ret;

    ret = read((int) (long) context, &buffer[0], len);
    if (ret < 0) xmlIOErr(0, "read()");
    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlFdWrite:
 * @context:  the I/O context
 * @buffer:  where to get data
 * @len:  number of bytes to write
 *
 * Write @len bytes from @buffer to the I/O channel.
 *
 * Returns the number of bytes written
 */
static int
xmlFdWrite (void * context, const char * buffer, int len) {
    int ret = 0;

    if (len > 0) {
	ret = write((int) (long) context, &buffer[0], len);
	if (ret < 0) xmlIOErr(0, "write()");
    }
    return(ret);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlFdClose:
 * @context:  the I/O context
 *
 * Close an I/O channel
 *
 * Returns 0 in case of success and error code otherwise
 */
static int
xmlFdClose (void * context) {
    int ret;
    ret = close((int) (long) context);
    if (ret < 0) xmlIOErr(0, "close()");
    return(ret);
}

/**
 * xmlFileMatch:
 * @filename:  the URI for matching
 *
 * input from FILE *
 *
 * Returns 1 if matches, 0 otherwise
 */
int
xmlFileMatch (const char *filename ATTRIBUTE_UNUSED) {
    return(1);
}

/**
 * xmlFileOpen_real:
 * @filename:  the URI for matching
 *
 * input from FILE *, supports compressed input
 * if @filename is " " then the standard input is used
 *
 * Returns an I/O context or NULL in case of error
 */
static void *
xmlFileOpen_real (const char *filename) {
    const char *path = filename;
    FILE *fd;

    if (filename == NULL)
        return(NULL);

    if (!strcmp(filename, "-")) {
	fd = stdin;
	return((void *) fd);
    }

    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file://localhost/", 17)) {
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[17];
#else
	path = &filename[16];
#endif
    } else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:///", 8)) {
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[8];
#else
	path = &filename[7];
#endif
    } else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:/", 6)) {
        /* lots of generators seems to lazy to read RFC 1738 */
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[6];
#else
	path = &filename[5];
#endif
    }

    if (!xmlCheckFilename(path))
        return(NULL);

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    fd = xmlWrapOpen(path, 0);
#else
    fd = fopen(path, "r");
#endif /* WIN32 */
    if (fd == NULL) xmlIOErr(0, path);
    return((void *) fd);
}

/**
 * xmlFileOpen:
 * @filename:  the URI for matching
 *
 * Wrapper around xmlFileOpen_real that try it with an unescaped
 * version of @filename, if this fails fallback to @filename
 *
 * Returns a handler or NULL in case or failure
 */
void *
xmlFileOpen (const char *filename) {
    char *unescaped;
    void *retval;

    retval = xmlFileOpen_real(filename);
    if (retval == NULL) {
	unescaped = xmlURIUnescapeString(filename, 0, NULL);
	if (unescaped != NULL) {
	    retval = xmlFileOpen_real(unescaped);
	    xmlFree(unescaped);
	}
    }

    return retval;
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlFileOpenW:
 * @filename:  the URI for matching
 *
 * output to from FILE *,
 * if @filename is "-" then the standard output is used
 *
 * Returns an I/O context or NULL in case of error
 */
static void *
xmlFileOpenW (const char *filename) {
    const char *path = NULL;
    FILE *fd;

    if (!strcmp(filename, "-")) {
	fd = stdout;
	return((void *) fd);
    }

    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file://localhost/", 17))
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[17];
#else
	path = &filename[16];
#endif
    else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:///", 8)) {
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[8];
#else
	path = &filename[7];
#endif
    } else
	path = filename;

    if (path == NULL)
	return(NULL);

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    fd = xmlWrapOpen(path, 1);
#else
	   fd = fopen(path, "wb");
#endif /* WIN32 */

	 if (fd == NULL) xmlIOErr(0, path);
    return((void *) fd);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlFileRead:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Read @len bytes to @buffer from the I/O channel.
 *
 * Returns the number of bytes written or < 0 in case of failure
 */
int
xmlFileRead (void * context, char * buffer, int len) {
    int ret;
    if ((context == NULL) || (buffer == NULL))
        return(-1);
    ret = fread(&buffer[0], 1,  len, (FILE *) context);
    if (ret < 0) xmlIOErr(0, "fread()");
    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlFileWrite:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Write @len bytes from @buffer to the I/O channel.
 *
 * Returns the number of bytes written
 */
static int
xmlFileWrite (void * context, const char * buffer, int len) {
    int items;

    if ((context == NULL) || (buffer == NULL))
        return(-1);
    items = fwrite(&buffer[0], len, 1, (FILE *) context);
    if ((items == 0) && (ferror((FILE *) context))) {
        xmlIOErr(0, "fwrite()");
	return(-1);
    }
    return(items * len);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlFileClose:
 * @context:  the I/O context
 *
 * Close an I/O channel
 *
 * Returns 0 or -1 in case of error
 */
int
xmlFileClose (void * context) {
    FILE *fil;
    int ret;

    if (context == NULL)
        return(-1);
    fil = (FILE *) context;
    if ((fil == stdout) || (fil == stderr)) {
        ret = fflush(fil);
	if (ret < 0)
	    xmlIOErr(0, "fflush()");
	return(0);
    }
    if (fil == stdin)
	return(0);
    ret = ( fclose((FILE *) context) == EOF ) ? -1 : 0;
    if (ret < 0)
        xmlIOErr(0, "fclose()");
    return(ret);
}

/**
 * xmlFileFlush:
 * @context:  the I/O context
 *
 * Flush an I/O channel
 */
static int
xmlFileFlush (void * context) {
    int ret;

    if (context == NULL)
        return(-1);
    ret = ( fflush((FILE *) context) == EOF ) ? -1 : 0;
    if (ret < 0)
        xmlIOErr(0, "fflush()");
    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlBufferWrite:
 * @context:  the xmlBuffer
 * @buffer:  the data to write
 * @len:  number of bytes to write
 *
 * Write @len bytes from @buffer to the xml buffer
 *
 * Returns the number of bytes written
 */
static int
xmlBufferWrite (void * context, const char * buffer, int len) {
    int ret;

    ret = xmlBufferAdd((xmlBufferPtr) context, (const xmlChar *) buffer, len);
    if (ret != 0)
        return(-1);
    return(len);
}
#endif

#ifdef HAVE_ZLIB_H
/************************************************************************
 *									*
 *		I/O for compressed file accesses			*
 *									*
 ************************************************************************/
/**
 * xmlGzfileMatch:
 * @filename:  the URI for matching
 *
 * input from compressed file test
 *
 * Returns 1 if matches, 0 otherwise
 */
static int
xmlGzfileMatch (const char *filename ATTRIBUTE_UNUSED) {
    return(1);
}

/**
 * xmlGzfileOpen_real:
 * @filename:  the URI for matching
 *
 * input from compressed file open
 * if @filename is " " then the standard input is used
 *
 * Returns an I/O context or NULL in case of error
 */
static void *
xmlGzfileOpen_real (const char *filename) {
    const char *path = NULL;
    gzFile fd;

    if (!strcmp(filename, "-")) {
        int duped_fd = dup(fileno(stdin));
        fd = gzdopen(duped_fd, "rb");
        if (fd == Z_NULL && duped_fd >= 0) {
            close(duped_fd);  /* gzdOpen() does not close on failure */
        }

	return((void *) fd);
    }

    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file://localhost/", 17))
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[17];
#else
	path = &filename[16];
#endif
    else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:///", 8)) {
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[8];
#else
	path = &filename[7];
#endif
    } else
	path = filename;

    if (path == NULL)
	return(NULL);
    if (!xmlCheckFilename(path))
        return(NULL);

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    fd = xmlWrapGzOpen(path, "rb");
#else
    fd = gzopen(path, "rb");
#endif
    return((void *) fd);
}

/**
 * xmlGzfileOpen:
 * @filename:  the URI for matching
 *
 * Wrapper around xmlGzfileOpen if the open fais, it will
 * try to unescape @filename
 */
static void *
xmlGzfileOpen (const char *filename) {
    char *unescaped;
    void *retval;

    retval = xmlGzfileOpen_real(filename);
    if (retval == NULL) {
	unescaped = xmlURIUnescapeString(filename, 0, NULL);
	if (unescaped != NULL) {
	    retval = xmlGzfileOpen_real(unescaped);
	}
	xmlFree(unescaped);
    }
    return retval;
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlGzfileOpenW:
 * @filename:  the URI for matching
 * @compression:  the compression factor (0 - 9 included)
 *
 * input from compressed file open
 * if @filename is " " then the standard input is used
 *
 * Returns an I/O context or NULL in case of error
 */
static void *
xmlGzfileOpenW (const char *filename, int compression) {
    const char *path = NULL;
    char mode[15];
    gzFile fd;

    snprintf(mode, sizeof(mode), "wb%d", compression);
    if (!strcmp(filename, "-")) {
        int duped_fd = dup(fileno(stdout));
        fd = gzdopen(duped_fd, "rb");
        if (fd == Z_NULL && duped_fd >= 0) {
            close(duped_fd);  /* gzdOpen() does not close on failure */
        }

	return((void *) fd);
    }

    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file://localhost/", 17))
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[17];
#else
	path = &filename[16];
#endif
    else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:///", 8)) {
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &filename[8];
#else
	path = &filename[7];
#endif
    } else
	path = filename;

    if (path == NULL)
	return(NULL);

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    fd = xmlWrapGzOpen(path, mode);
#else
    fd = gzopen(path, mode);
#endif
    return((void *) fd);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlGzfileRead:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Read @len bytes to @buffer from the compressed I/O channel.
 *
 * Returns the number of bytes written
 */
static int
xmlGzfileRead (void * context, char * buffer, int len) {
    int ret;

    ret = gzread((gzFile) context, &buffer[0], len);
    if (ret < 0) xmlIOErr(0, "gzread()");
    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlGzfileWrite:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Write @len bytes from @buffer to the compressed I/O channel.
 *
 * Returns the number of bytes written
 */
static int
xmlGzfileWrite (void * context, const char * buffer, int len) {
    int ret;

    ret = gzwrite((gzFile) context, (char *) &buffer[0], len);
    if (ret < 0) xmlIOErr(0, "gzwrite()");
    return(ret);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlGzfileClose:
 * @context:  the I/O context
 *
 * Close a compressed I/O channel
 */
static int
xmlGzfileClose (void * context) {
    int ret;

    ret =  (gzclose((gzFile) context) == Z_OK ) ? 0 : -1;
    if (ret < 0) xmlIOErr(0, "gzclose()");
    return(ret);
}
#endif /* HAVE_ZLIB_H */

#ifdef HAVE_LZMA_H
/************************************************************************
 *									*
 *		I/O for compressed file accesses			*
 *									*
 ************************************************************************/
#include "xzlib.h"
/**
 * xmlXzfileMatch:
 * @filename:  the URI for matching
 *
 * input from compressed file test
 *
 * Returns 1 if matches, 0 otherwise
 */
static int
xmlXzfileMatch (const char *filename ATTRIBUTE_UNUSED) {
    return(1);
}

/**
 * xmlXzFileOpen_real:
 * @filename:  the URI for matching
 *
 * input from compressed file open
 * if @filename is " " then the standard input is used
 *
 * Returns an I/O context or NULL in case of error
 */
static void *
xmlXzfileOpen_real (const char *filename) {
    const char *path = NULL;
    xzFile fd;

    if (!strcmp(filename, "-")) {
        fd = __libxml2_xzdopen(dup(fileno(stdin)), "rb");
	return((void *) fd);
    }

    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file://localhost/", 17)) {
	path = &filename[16];
    } else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:///", 8)) {
	path = &filename[7];
    } else if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "file:/", 6)) {
        /* lots of generators seems to lazy to read RFC 1738 */
	path = &filename[5];
    } else
	path = filename;

    if (path == NULL)
	return(NULL);
    if (!xmlCheckFilename(path))
        return(NULL);

    fd = __libxml2_xzopen(path, "rb");
    return((void *) fd);
}

/**
 * xmlXzfileOpen:
 * @filename:  the URI for matching
 *
 * Wrapper around xmlXzfileOpen_real that try it with an unescaped
 * version of @filename, if this fails fallback to @filename
 *
 * Returns a handler or NULL in case or failure
 */
static void *
xmlXzfileOpen (const char *filename) {
    char *unescaped;
    void *retval;

    retval = xmlXzfileOpen_real(filename);
    if (retval == NULL) {
	unescaped = xmlURIUnescapeString(filename, 0, NULL);
	if (unescaped != NULL) {
	    retval = xmlXzfileOpen_real(unescaped);
	}
	xmlFree(unescaped);
    }

    return retval;
}

/**
 * xmlXzfileRead:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Read @len bytes to @buffer from the compressed I/O channel.
 *
 * Returns the number of bytes written
 */
static int
xmlXzfileRead (void * context, char * buffer, int len) {
    int ret;

    ret = __libxml2_xzread((xzFile) context, &buffer[0], len);
    if (ret < 0) xmlIOErr(0, "xzread()");
    return(ret);
}

/**
 * xmlXzfileClose:
 * @context:  the I/O context
 *
 * Close a compressed I/O channel
 */
static int
xmlXzfileClose (void * context) {
    int ret;

    ret =  (__libxml2_xzclose((xzFile) context) == LZMA_OK ) ? 0 : -1;
    if (ret < 0) xmlIOErr(0, "xzclose()");
    return(ret);
}
#endif /* HAVE_LZMA_H */

#ifdef LIBXML_HTTP_ENABLED
/************************************************************************
 *									*
 *			I/O for HTTP file accesses			*
 *									*
 ************************************************************************/

#ifdef LIBXML_OUTPUT_ENABLED
typedef struct xmlIOHTTPWriteCtxt_
{
    int			compression;

    char *		uri;

    void *		doc_buff;

} xmlIOHTTPWriteCtxt, *xmlIOHTTPWriteCtxtPtr;

#ifdef HAVE_ZLIB_H

#define DFLT_WBITS		( -15 )
#define DFLT_MEM_LVL		( 8 )
#define GZ_MAGIC1		( 0x1f )
#define GZ_MAGIC2		( 0x8b )
#define LXML_ZLIB_OS_CODE	( 0x03 )
#define INIT_HTTP_BUFF_SIZE	( 32768 )
#define DFLT_ZLIB_RATIO		( 5 )

/*
**  Data structure and functions to work with sending compressed data
**  via HTTP.
*/

typedef struct xmlZMemBuff_
{
   unsigned long	size;
   unsigned long	crc;

   unsigned char *	zbuff;
   z_stream		zctrl;

} xmlZMemBuff, *xmlZMemBuffPtr;

/**
 * append_reverse_ulong
 * @buff:  Compressed memory buffer
 * @data:  Unsigned long to append
 *
 * Append a unsigned long in reverse byte order to the end of the
 * memory buffer.
 */
static void
append_reverse_ulong( xmlZMemBuff * buff, unsigned long data ) {

    int		idx;

    if ( buff == NULL )
	return;

    /*
    **  This is plagiarized from putLong in gzio.c (zlib source) where
    **  the number "4" is hardcoded.  If zlib is ever patched to
    **  support 64 bit file sizes, this code would need to be patched
    **  as well.
    */

    for ( idx = 0; idx < 4; idx++ ) {
	*buff->zctrl.next_out = ( data & 0xff );
	data >>= 8;
	buff->zctrl.next_out++;
    }

    return;
}

/**
 *
 * xmlFreeZMemBuff
 * @buff:  The memory buffer context to clear
 *
 * Release all the resources associated with the compressed memory buffer.
 */
static void
xmlFreeZMemBuff( xmlZMemBuffPtr buff ) {

#ifdef DEBUG_HTTP
    int z_err;
#endif

    if ( buff == NULL )
	return;

    xmlFree( buff->zbuff );
#ifdef DEBUG_HTTP
    z_err = deflateEnd( &buff->zctrl );
    if ( z_err != Z_OK )
	xmlGenericError( xmlGenericErrorContext,
			"xmlFreeZMemBuff:  Error releasing zlib context:  %d\n",
			z_err );
#else
    deflateEnd( &buff->zctrl );
#endif

    xmlFree( buff );
    return;
}

/**
 * xmlCreateZMemBuff
 *@compression:	Compression value to use
 *
 * Create a memory buffer to hold the compressed XML document.  The
 * compressed document in memory will end up being identical to what
 * would be created if gzopen/gzwrite/gzclose were being used to
 * write the document to disk.  The code for the header/trailer data to
 * the compression is plagiarized from the zlib source files.
 */
static void *
xmlCreateZMemBuff( int compression ) {

    int			z_err;
    int			hdr_lgth;
    xmlZMemBuffPtr	buff = NULL;

    if ( ( compression < 1 ) || ( compression > 9 ) )
	return ( NULL );

    /*  Create the control and data areas  */

    buff = xmlMalloc( sizeof( xmlZMemBuff ) );
    if ( buff == NULL ) {
	xmlIOErrMemory("creating buffer context");
	return ( NULL );
    }

    (void)memset( buff, 0, sizeof( xmlZMemBuff ) );
    buff->size = INIT_HTTP_BUFF_SIZE;
    buff->zbuff = xmlMalloc( buff->size );
    if ( buff->zbuff == NULL ) {
	xmlFreeZMemBuff( buff );
	xmlIOErrMemory("creating buffer");
	return ( NULL );
    }

    z_err = deflateInit2( &buff->zctrl, compression, Z_DEFLATED,
			    DFLT_WBITS, DFLT_MEM_LVL, Z_DEFAULT_STRATEGY );
    if ( z_err != Z_OK ) {
	xmlChar msg[500];
	xmlFreeZMemBuff( buff );
	buff = NULL;
	xmlStrPrintf(msg, 500,
		    (const xmlChar *) "xmlCreateZMemBuff:  %s %d\n",
		    "Error initializing compression context.  ZLIB error:",
		    z_err );
	xmlIOErr(XML_IO_WRITE, (const char *) msg);
	return ( NULL );
    }

    /*  Set the header data.  The CRC will be needed for the trailer  */
    buff->crc = crc32( 0L, NULL, 0 );
    hdr_lgth = snprintf( (char *)buff->zbuff, buff->size,
			"%c%c%c%c%c%c%c%c%c%c",
			GZ_MAGIC1, GZ_MAGIC2, Z_DEFLATED,
			0, 0, 0, 0, 0, 0, LXML_ZLIB_OS_CODE );
    buff->zctrl.next_out  = buff->zbuff + hdr_lgth;
    buff->zctrl.avail_out = buff->size - hdr_lgth;

    return ( buff );
}

/**
 * xmlZMemBuffExtend
 * @buff:  Buffer used to compress and consolidate data.
 * @ext_amt:   Number of bytes to extend the buffer.
 *
 * Extend the internal buffer used to store the compressed data by the
 * specified amount.
 *
 * Returns 0 on success or -1 on failure to extend the buffer.  On failure
 * the original buffer still exists at the original size.
 */
static int
xmlZMemBuffExtend( xmlZMemBuffPtr buff, size_t ext_amt ) {

    int			rc = -1;
    size_t		new_size;
    size_t		cur_used;

    unsigned char *	tmp_ptr = NULL;

    if ( buff == NULL )
	return ( -1 );

    else if ( ext_amt == 0 )
	return ( 0 );

    cur_used = buff->zctrl.next_out - buff->zbuff;
    new_size = buff->size + ext_amt;

#ifdef DEBUG_HTTP
    if ( cur_used > new_size )
	xmlGenericError( xmlGenericErrorContext,
			"xmlZMemBuffExtend:  %s\n%s %d bytes.\n",
			"Buffer overwrite detected during compressed memory",
			"buffer extension.  Overflowed by",
			(cur_used - new_size ) );
#endif

    tmp_ptr = xmlRealloc( buff->zbuff, new_size );
    if ( tmp_ptr != NULL ) {
	rc = 0;
	buff->size  = new_size;
	buff->zbuff = tmp_ptr;
	buff->zctrl.next_out  = tmp_ptr + cur_used;
	buff->zctrl.avail_out = new_size - cur_used;
    }
    else {
	xmlChar msg[500];
	xmlStrPrintf(msg, 500,
		    (const xmlChar *) "xmlZMemBuffExtend:  %s %lu bytes.\n",
		    "Allocation failure extending output buffer to",
		    new_size );
	xmlIOErr(XML_IO_WRITE, (const char *) msg);
    }

    return ( rc );
}

/**
 * xmlZMemBuffAppend
 * @buff:  Buffer used to compress and consolidate data
 * @src:   Uncompressed source content to append to buffer
 * @len:   Length of source data to append to buffer
 *
 * Compress and append data to the internal buffer.  The data buffer
 * will be expanded if needed to store the additional data.
 *
 * Returns the number of bytes appended to the buffer or -1 on error.
 */
static int
xmlZMemBuffAppend( xmlZMemBuffPtr buff, const char * src, int len ) {

    int		z_err;
    size_t	min_accept;

    if ( ( buff == NULL ) || ( src == NULL ) )
	return ( -1 );

    buff->zctrl.avail_in = len;
    buff->zctrl.next_in  = (unsigned char *)src;
    while ( buff->zctrl.avail_in > 0 ) {
	/*
	**  Extend the buffer prior to deflate call if a reasonable amount
	**  of output buffer space is not available.
	*/
	min_accept = buff->zctrl.avail_in / DFLT_ZLIB_RATIO;
	if ( buff->zctrl.avail_out <= min_accept ) {
	    if ( xmlZMemBuffExtend( buff, buff->size ) == -1 )
		return ( -1 );
	}

	z_err = deflate( &buff->zctrl, Z_NO_FLUSH );
	if ( z_err != Z_OK ) {
	    xmlChar msg[500];
	    xmlStrPrintf(msg, 500,
			(const xmlChar *) "xmlZMemBuffAppend:  %s %d %s - %d",
			"Compression error while appending",
			len, "bytes to buffer.  ZLIB error", z_err );
	    xmlIOErr(XML_IO_WRITE, (const char *) msg);
	    return ( -1 );
	}
    }

    buff->crc = crc32( buff->crc, (unsigned char *)src, len );

    return ( len );
}

/**
 * xmlZMemBuffGetContent
 * @buff:  Compressed memory content buffer
 * @data_ref:  Pointer reference to point to compressed content
 *
 * Flushes the compression buffers, appends gzip file trailers and
 * returns the compressed content and length of the compressed data.
 * NOTE:  The gzip trailer code here is plagiarized from zlib source.
 *
 * Returns the length of the compressed data or -1 on error.
 */
static int
xmlZMemBuffGetContent( xmlZMemBuffPtr buff, char ** data_ref ) {

    int		zlgth = -1;
    int		z_err;

    if ( ( buff == NULL ) || ( data_ref == NULL ) )
	return ( -1 );

    /*  Need to loop until compression output buffers are flushed  */

    do
    {
	z_err = deflate( &buff->zctrl, Z_FINISH );
	if ( z_err == Z_OK ) {
	    /*  In this case Z_OK means more buffer space needed  */

	    if ( xmlZMemBuffExtend( buff, buff->size ) == -1 )
		return ( -1 );
	}
    }
    while ( z_err == Z_OK );

    /*  If the compression state is not Z_STREAM_END, some error occurred  */

    if ( z_err == Z_STREAM_END ) {

	/*  Need to append the gzip data trailer  */

	if ( buff->zctrl.avail_out < ( 2 * sizeof( unsigned long ) ) ) {
	    if ( xmlZMemBuffExtend(buff, (2 * sizeof(unsigned long))) == -1 )
		return ( -1 );
	}

	/*
	**  For whatever reason, the CRC and length data are pushed out
	**  in reverse byte order.  So a memcpy can't be used here.
	*/

	append_reverse_ulong( buff, buff->crc );
	append_reverse_ulong( buff, buff->zctrl.total_in );

	zlgth = buff->zctrl.next_out - buff->zbuff;
	*data_ref = (char *)buff->zbuff;
    }

    else {
	xmlChar msg[500];
	xmlStrPrintf(msg, 500,
		    (const xmlChar *) "xmlZMemBuffGetContent:  %s - %d\n",
		    "Error flushing zlib buffers.  Error code", z_err );
	xmlIOErr(XML_IO_WRITE, (const char *) msg);
    }

    return ( zlgth );
}
#endif /* LIBXML_OUTPUT_ENABLED */
#endif  /*  HAVE_ZLIB_H  */

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlFreeHTTPWriteCtxt
 * @ctxt:  Context to cleanup
 *
 * Free allocated memory and reclaim system resources.
 *
 * No return value.
 */
static void
xmlFreeHTTPWriteCtxt( xmlIOHTTPWriteCtxtPtr ctxt )
{
    if ( ctxt->uri != NULL )
	xmlFree( ctxt->uri );

    if ( ctxt->doc_buff != NULL ) {

#ifdef HAVE_ZLIB_H
	if ( ctxt->compression > 0 ) {
	    xmlFreeZMemBuff( ctxt->doc_buff );
	}
	else
#endif
	{
	    xmlOutputBufferClose( ctxt->doc_buff );
	}
    }

    xmlFree( ctxt );
    return;
}
#endif /* LIBXML_OUTPUT_ENABLED */


/**
 * xmlIOHTTPMatch:
 * @filename:  the URI for matching
 *
 * check if the URI matches an HTTP one
 *
 * Returns 1 if matches, 0 otherwise
 */
int
xmlIOHTTPMatch (const char *filename) {
    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "http://", 7))
	return(1);
    return(0);
}

/**
 * xmlIOHTTPOpen:
 * @filename:  the URI for matching
 *
 * open an HTTP I/O channel
 *
 * Returns an I/O context or NULL in case of error
 */
void *
xmlIOHTTPOpen (const char *filename) {
    return(xmlNanoHTTPOpen(filename, NULL));
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlIOHTTPOpenW:
 * @post_uri:  The destination URI for the document
 * @compression:  The compression desired for the document.
 *
 * Open a temporary buffer to collect the document for a subsequent HTTP POST
 * request.  Non-static as is called from the output buffer creation routine.
 *
 * Returns an I/O context or NULL in case of error.
 */

void *
xmlIOHTTPOpenW(const char *post_uri, int compression)
{

    xmlIOHTTPWriteCtxtPtr ctxt = NULL;

    if (post_uri == NULL)
        return (NULL);

    ctxt = xmlMalloc(sizeof(xmlIOHTTPWriteCtxt));
    if (ctxt == NULL) {
	xmlIOErrMemory("creating HTTP output context");
        return (NULL);
    }

    (void) memset(ctxt, 0, sizeof(xmlIOHTTPWriteCtxt));

    ctxt->uri = (char *) xmlStrdup((const xmlChar *)post_uri);
    if (ctxt->uri == NULL) {
	xmlIOErrMemory("copying URI");
        xmlFreeHTTPWriteCtxt(ctxt);
        return (NULL);
    }

    /*
     * **  Since the document length is required for an HTTP post,
     * **  need to put the document into a buffer.  A memory buffer
     * **  is being used to avoid pushing the data to disk and back.
     */

#ifdef HAVE_ZLIB_H
    if ((compression > 0) && (compression <= 9)) {

        ctxt->compression = compression;
        ctxt->doc_buff = xmlCreateZMemBuff(compression);
    } else
#endif
    {
        /*  Any character conversions should have been done before this  */

        ctxt->doc_buff = xmlAllocOutputBufferInternal(NULL);
    }

    if (ctxt->doc_buff == NULL) {
        xmlFreeHTTPWriteCtxt(ctxt);
        ctxt = NULL;
    }

    return (ctxt);
}
#endif /* LIBXML_OUTPUT_ENABLED */

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlIOHTTPDfltOpenW
 * @post_uri:  The destination URI for this document.
 *
 * Calls xmlIOHTTPOpenW with no compression to set up for a subsequent
 * HTTP post command.  This function should generally not be used as
 * the open callback is short circuited in xmlOutputBufferCreateFile.
 *
 * Returns a pointer to the new IO context.
 */
static void *
xmlIOHTTPDfltOpenW( const char * post_uri ) {
    return ( xmlIOHTTPOpenW( post_uri, 0 ) );
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlIOHTTPRead:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Read @len bytes to @buffer from the I/O channel.
 *
 * Returns the number of bytes written
 */
int
xmlIOHTTPRead(void * context, char * buffer, int len) {
    if ((buffer == NULL) || (len < 0)) return(-1);
    return(xmlNanoHTTPRead(context, &buffer[0], len));
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlIOHTTPWrite
 * @context:  previously opened writing context
 * @buffer:   data to output to temporary buffer
 * @len:      bytes to output
 *
 * Collect data from memory buffer into a temporary file for later
 * processing.
 *
 * Returns number of bytes written.
 */

static int
xmlIOHTTPWrite( void * context, const char * buffer, int len ) {

    xmlIOHTTPWriteCtxtPtr	ctxt = context;

    if ( ( ctxt == NULL ) || ( ctxt->doc_buff == NULL ) || ( buffer == NULL ) )
	return ( -1 );

    if ( len > 0 ) {

	/*  Use gzwrite or fwrite as previously setup in the open call  */

#ifdef HAVE_ZLIB_H
	if ( ctxt->compression > 0 )
	    len = xmlZMemBuffAppend( ctxt->doc_buff, buffer, len );

	else
#endif
	    len = xmlOutputBufferWrite( ctxt->doc_buff, len, buffer );

	if ( len < 0 ) {
	    xmlChar msg[500];
	    xmlStrPrintf(msg, 500,
			(const xmlChar *) "xmlIOHTTPWrite:  %s\n%s '%s'.\n",
			"Error appending to internal buffer.",
			"Error sending document to URI",
			ctxt->uri );
	    xmlIOErr(XML_IO_WRITE, (const char *) msg);
	}
    }

    return ( len );
}
#endif /* LIBXML_OUTPUT_ENABLED */


/**
 * xmlIOHTTPClose:
 * @context:  the I/O context
 *
 * Close an HTTP I/O channel
 *
 * Returns 0
 */
int
xmlIOHTTPClose (void * context) {
    xmlNanoHTTPClose(context);
    return 0;
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlIOHTTCloseWrite
 * @context:  The I/O context
 * @http_mthd: The HTTP method to be used when sending the data
 *
 * Close the transmit HTTP I/O channel and actually send the data.
 */
static int
xmlIOHTTPCloseWrite( void * context, const char * http_mthd ) {

    int				close_rc = -1;
    int				http_rtn = 0;
    int				content_lgth = 0;
    xmlIOHTTPWriteCtxtPtr	ctxt = context;

    char *			http_content = NULL;
    char *			content_encoding = NULL;
    char *			content_type = (char *) "text/xml";
    void *			http_ctxt = NULL;

    if ( ( ctxt == NULL ) || ( http_mthd == NULL ) )
	return ( -1 );

    /*  Retrieve the content from the appropriate buffer  */

#ifdef HAVE_ZLIB_H

    if ( ctxt->compression > 0 ) {
	content_lgth = xmlZMemBuffGetContent( ctxt->doc_buff, &http_content );
	content_encoding = (char *) "Content-Encoding: gzip";
    }
    else
#endif
    {
	/*  Pull the data out of the memory output buffer  */

	xmlOutputBufferPtr	dctxt = ctxt->doc_buff;
	http_content = (char *) xmlBufContent(dctxt->buffer);
	content_lgth = xmlBufUse(dctxt->buffer);
    }

    if ( http_content == NULL ) {
	xmlChar msg[500];
	xmlStrPrintf(msg, 500,
		     (const xmlChar *) "xmlIOHTTPCloseWrite:  %s '%s' %s '%s'.\n",
		     "Error retrieving content.\nUnable to",
		     http_mthd, "data to URI", ctxt->uri );
	xmlIOErr(XML_IO_WRITE, (const char *) msg);
    }

    else {

	http_ctxt = xmlNanoHTTPMethod( ctxt->uri, http_mthd, http_content,
					&content_type, content_encoding,
					content_lgth );

	if ( http_ctxt != NULL ) {
#ifdef DEBUG_HTTP
	    /*  If testing/debugging - dump reply with request content  */

	    FILE *	tst_file = NULL;
	    char	buffer[ 4096 ];
	    char *	dump_name = NULL;
	    int		avail;

	    xmlGenericError( xmlGenericErrorContext,
			"xmlNanoHTTPCloseWrite:  HTTP %s to\n%s returned %d.\n",
			http_mthd, ctxt->uri,
			xmlNanoHTTPReturnCode( http_ctxt ) );

	    /*
	    **  Since either content or reply may be gzipped,
	    **  dump them to separate files instead of the
	    **  standard error context.
	    */

	    dump_name = tempnam( NULL, "lxml" );
	    if ( dump_name != NULL ) {
		(void)snprintf( buffer, sizeof(buffer), "%s.content", dump_name );

		tst_file = fopen( buffer, "wb" );
		if ( tst_file != NULL ) {
		    xmlGenericError( xmlGenericErrorContext,
			"Transmitted content saved in file:  %s\n", buffer );

		    fwrite( http_content, sizeof( char ),
					content_lgth, tst_file );
		    fclose( tst_file );
		}

		(void)snprintf( buffer, sizeof(buffer), "%s.reply", dump_name );
		tst_file = fopen( buffer, "wb" );
		if ( tst_file != NULL ) {
		    xmlGenericError( xmlGenericErrorContext,
			"Reply content saved in file:  %s\n", buffer );


		    while ( (avail = xmlNanoHTTPRead( http_ctxt,
					buffer, sizeof( buffer ) )) > 0 ) {

			fwrite( buffer, sizeof( char ), avail, tst_file );
		    }

		    fclose( tst_file );
		}

		free( dump_name );
	    }
#endif  /*  DEBUG_HTTP  */

	    http_rtn = xmlNanoHTTPReturnCode( http_ctxt );
	    if ( ( http_rtn >= 200 ) && ( http_rtn < 300 ) )
		close_rc = 0;
	    else {
                xmlChar msg[500];
                xmlStrPrintf(msg, 500,
    (const xmlChar *) "xmlIOHTTPCloseWrite: HTTP '%s' of %d %s\n'%s' %s %d\n",
			    http_mthd, content_lgth,
			    "bytes to URI", ctxt->uri,
			    "failed.  HTTP return code:", http_rtn );
		xmlIOErr(XML_IO_WRITE, (const char *) msg);
            }

	    xmlNanoHTTPClose( http_ctxt );
	    xmlFree( content_type );
	}
    }

    /*  Final cleanups  */

    xmlFreeHTTPWriteCtxt( ctxt );

    return ( close_rc );
}

/**
 * xmlIOHTTPClosePut
 *
 * @context:  The I/O context
 *
 * Close the transmit HTTP I/O channel and actually send data using a PUT
 * HTTP method.
 */
static int
xmlIOHTTPClosePut( void * ctxt ) {
    return ( xmlIOHTTPCloseWrite( ctxt, "PUT" ) );
}


/**
 * xmlIOHTTPClosePost
 *
 * @context:  The I/O context
 *
 * Close the transmit HTTP I/O channel and actually send data using a POST
 * HTTP method.
 */
static int
xmlIOHTTPClosePost( void * ctxt ) {
    return ( xmlIOHTTPCloseWrite( ctxt, "POST" ) );
}
#endif /* LIBXML_OUTPUT_ENABLED */

#endif /* LIBXML_HTTP_ENABLED */

#ifdef LIBXML_FTP_ENABLED
/************************************************************************
 *									*
 *			I/O for FTP file accesses			*
 *									*
 ************************************************************************/
/**
 * xmlIOFTPMatch:
 * @filename:  the URI for matching
 *
 * check if the URI matches an FTP one
 *
 * Returns 1 if matches, 0 otherwise
 */
int
xmlIOFTPMatch (const char *filename) {
    if (!xmlStrncasecmp(BAD_CAST filename, BAD_CAST "ftp://", 6))
	return(1);
    return(0);
}

/**
 * xmlIOFTPOpen:
 * @filename:  the URI for matching
 *
 * open an FTP I/O channel
 *
 * Returns an I/O context or NULL in case of error
 */
void *
xmlIOFTPOpen (const char *filename) {
    return(xmlNanoFTPOpen(filename));
}

/**
 * xmlIOFTPRead:
 * @context:  the I/O context
 * @buffer:  where to drop data
 * @len:  number of bytes to write
 *
 * Read @len bytes to @buffer from the I/O channel.
 *
 * Returns the number of bytes written
 */
int
xmlIOFTPRead(void * context, char * buffer, int len) {
    if ((buffer == NULL) || (len < 0)) return(-1);
    return(xmlNanoFTPRead(context, &buffer[0], len));
}

/**
 * xmlIOFTPClose:
 * @context:  the I/O context
 *
 * Close an FTP I/O channel
 *
 * Returns 0
 */
int
xmlIOFTPClose (void * context) {
    return ( xmlNanoFTPClose(context) );
}
#endif /* LIBXML_FTP_ENABLED */


/**
 * xmlRegisterInputCallbacks:
 * @matchFunc:  the xmlInputMatchCallback
 * @openFunc:  the xmlInputOpenCallback
 * @readFunc:  the xmlInputReadCallback
 * @closeFunc:  the xmlInputCloseCallback
 *
 * Register a new set of I/O callback for handling parser input.
 *
 * Returns the registered handler number or -1 in case of error
 */
int
xmlRegisterInputCallbacks(xmlInputMatchCallback matchFunc,
	xmlInputOpenCallback openFunc, xmlInputReadCallback readFunc,
	xmlInputCloseCallback closeFunc) {
    if (xmlInputCallbackNr >= MAX_INPUT_CALLBACK) {
	return(-1);
    }
    xmlInputCallbackTable[xmlInputCallbackNr].matchcallback = matchFunc;
    xmlInputCallbackTable[xmlInputCallbackNr].opencallback = openFunc;
    xmlInputCallbackTable[xmlInputCallbackNr].readcallback = readFunc;
    xmlInputCallbackTable[xmlInputCallbackNr].closecallback = closeFunc;
    xmlInputCallbackInitialized = 1;
    return(xmlInputCallbackNr++);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlRegisterOutputCallbacks:
 * @matchFunc:  the xmlOutputMatchCallback
 * @openFunc:  the xmlOutputOpenCallback
 * @writeFunc:  the xmlOutputWriteCallback
 * @closeFunc:  the xmlOutputCloseCallback
 *
 * Register a new set of I/O callback for handling output.
 *
 * Returns the registered handler number or -1 in case of error
 */
int
xmlRegisterOutputCallbacks(xmlOutputMatchCallback matchFunc,
	xmlOutputOpenCallback openFunc, xmlOutputWriteCallback writeFunc,
	xmlOutputCloseCallback closeFunc) {
    if (xmlOutputCallbackNr >= MAX_OUTPUT_CALLBACK) {
	return(-1);
    }
    xmlOutputCallbackTable[xmlOutputCallbackNr].matchcallback = matchFunc;
    xmlOutputCallbackTable[xmlOutputCallbackNr].opencallback = openFunc;
    xmlOutputCallbackTable[xmlOutputCallbackNr].writecallback = writeFunc;
    xmlOutputCallbackTable[xmlOutputCallbackNr].closecallback = closeFunc;
    xmlOutputCallbackInitialized = 1;
    return(xmlOutputCallbackNr++);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlRegisterDefaultInputCallbacks:
 *
 * Registers the default compiled-in I/O handlers.
 */
void
xmlRegisterDefaultInputCallbacks(void) {
    if (xmlInputCallbackInitialized)
	return;

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    xmlInitPlatformSpecificIo();
#endif

    xmlRegisterInputCallbacks(xmlFileMatch, xmlFileOpen,
	                      xmlFileRead, xmlFileClose);
#ifdef HAVE_ZLIB_H
    xmlRegisterInputCallbacks(xmlGzfileMatch, xmlGzfileOpen,
	                      xmlGzfileRead, xmlGzfileClose);
#endif /* HAVE_ZLIB_H */
#ifdef HAVE_LZMA_H
    xmlRegisterInputCallbacks(xmlXzfileMatch, xmlXzfileOpen,
	                      xmlXzfileRead, xmlXzfileClose);
#endif /* HAVE_ZLIB_H */

#ifdef LIBXML_HTTP_ENABLED
    xmlRegisterInputCallbacks(xmlIOHTTPMatch, xmlIOHTTPOpen,
	                      xmlIOHTTPRead, xmlIOHTTPClose);
#endif /* LIBXML_HTTP_ENABLED */

#ifdef LIBXML_FTP_ENABLED
    xmlRegisterInputCallbacks(xmlIOFTPMatch, xmlIOFTPOpen,
	                      xmlIOFTPRead, xmlIOFTPClose);
#endif /* LIBXML_FTP_ENABLED */
    xmlInputCallbackInitialized = 1;
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlRegisterDefaultOutputCallbacks:
 *
 * Registers the default compiled-in I/O handlers.
 */
void
xmlRegisterDefaultOutputCallbacks (void) {
    if (xmlOutputCallbackInitialized)
	return;

#if defined(_WIN32) || defined (__DJGPP__) && !defined (__CYGWIN__)
    xmlInitPlatformSpecificIo();
#endif

    xmlRegisterOutputCallbacks(xmlFileMatch, xmlFileOpenW,
	                      xmlFileWrite, xmlFileClose);

#ifdef LIBXML_HTTP_ENABLED
    xmlRegisterOutputCallbacks(xmlIOHTTPMatch, xmlIOHTTPDfltOpenW,
	                       xmlIOHTTPWrite, xmlIOHTTPClosePut);
#endif

/*********************************
 No way a-priori to distinguish between gzipped files from
 uncompressed ones except opening if existing then closing
 and saving with same compression ratio ... a pain.

#ifdef HAVE_ZLIB_H
    xmlRegisterOutputCallbacks(xmlGzfileMatch, xmlGzfileOpen,
	                       xmlGzfileWrite, xmlGzfileClose);
#endif

 Nor FTP PUT ....
#ifdef LIBXML_FTP_ENABLED
    xmlRegisterOutputCallbacks(xmlIOFTPMatch, xmlIOFTPOpen,
	                       xmlIOFTPWrite, xmlIOFTPClose);
#endif
 **********************************/
    xmlOutputCallbackInitialized = 1;
}

#ifdef LIBXML_HTTP_ENABLED
/**
 * xmlRegisterHTTPPostCallbacks:
 *
 * By default, libxml submits HTTP output requests using the "PUT" method.
 * Calling this method changes the HTTP output method to use the "POST"
 * method instead.
 *
 */
void
xmlRegisterHTTPPostCallbacks( void ) {

    /*  Register defaults if not done previously  */

    if ( xmlOutputCallbackInitialized == 0 )
	xmlRegisterDefaultOutputCallbacks( );

    xmlRegisterOutputCallbacks(xmlIOHTTPMatch, xmlIOHTTPDfltOpenW,
	                       xmlIOHTTPWrite, xmlIOHTTPClosePost);
    return;
}
#endif
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlAllocParserInputBuffer:
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for progressive parsing
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlAllocParserInputBuffer(xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;

    ret = (xmlParserInputBufferPtr) xmlMalloc(sizeof(xmlParserInputBuffer));
    if (ret == NULL) {
	xmlIOErrMemory("creating input buffer");
	return(NULL);
    }
    memset(ret, 0, (size_t) sizeof(xmlParserInputBuffer));
    ret->buffer = xmlBufCreateSize(2 * xmlDefaultBufferSize);
    if (ret->buffer == NULL) {
        xmlFree(ret);
	return(NULL);
    }
    xmlBufSetAllocationScheme(ret->buffer, XML_BUFFER_ALLOC_DOUBLEIT);
    ret->encoder = xmlGetCharEncodingHandler(enc);
    if (ret->encoder != NULL)
        ret->raw = xmlBufCreateSize(2 * xmlDefaultBufferSize);
    else
        ret->raw = NULL;
    ret->readcallback = NULL;
    ret->closecallback = NULL;
    ret->context = NULL;
    ret->compressed = -1;
    ret->rawconsumed = 0;

    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlAllocOutputBuffer:
 * @encoder:  the encoding converter or NULL
 *
 * Create a buffered parser output
 *
 * Returns the new parser output or NULL
 */
xmlOutputBufferPtr
xmlAllocOutputBuffer(xmlCharEncodingHandlerPtr encoder) {
    xmlOutputBufferPtr ret;

    ret = (xmlOutputBufferPtr) xmlMalloc(sizeof(xmlOutputBuffer));
    if (ret == NULL) {
	xmlIOErrMemory("creating output buffer");
	return(NULL);
    }
    memset(ret, 0, (size_t) sizeof(xmlOutputBuffer));
    ret->buffer = xmlBufCreate();
    if (ret->buffer == NULL) {
        xmlFree(ret);
	return(NULL);
    }

    /* try to avoid a performance problem with Windows realloc() */
    if (xmlBufGetAllocationScheme(ret->buffer) == XML_BUFFER_ALLOC_EXACT)
        xmlBufSetAllocationScheme(ret->buffer, XML_BUFFER_ALLOC_DOUBLEIT);

    ret->encoder = encoder;
    if (encoder != NULL) {
        ret->conv = xmlBufCreateSize(4000);
	if (ret->conv == NULL) {
	    xmlFree(ret);
	    return(NULL);
	}

	/*
	 * This call is designed to initiate the encoder state
	 */
	xmlCharEncOutput(ret, 1);
    } else
        ret->conv = NULL;
    ret->writecallback = NULL;
    ret->closecallback = NULL;
    ret->context = NULL;
    ret->written = 0;

    return(ret);
}

/**
 * xmlAllocOutputBufferInternal:
 * @encoder:  the encoding converter or NULL
 *
 * Create a buffered parser output
 *
 * Returns the new parser output or NULL
 */
xmlOutputBufferPtr
xmlAllocOutputBufferInternal(xmlCharEncodingHandlerPtr encoder) {
    xmlOutputBufferPtr ret;

    ret = (xmlOutputBufferPtr) xmlMalloc(sizeof(xmlOutputBuffer));
    if (ret == NULL) {
	xmlIOErrMemory("creating output buffer");
	return(NULL);
    }
    memset(ret, 0, (size_t) sizeof(xmlOutputBuffer));
    ret->buffer = xmlBufCreate();
    if (ret->buffer == NULL) {
        xmlFree(ret);
	return(NULL);
    }


    /*
     * For conversion buffers we use the special IO handling
     */
    xmlBufSetAllocationScheme(ret->buffer, XML_BUFFER_ALLOC_IO);

    ret->encoder = encoder;
    if (encoder != NULL) {
        ret->conv = xmlBufCreateSize(4000);
	if (ret->conv == NULL) {
	    xmlFree(ret);
	    return(NULL);
	}

	/*
	 * This call is designed to initiate the encoder state
	 */
        xmlCharEncOutput(ret, 1);
    } else
        ret->conv = NULL;
    ret->writecallback = NULL;
    ret->closecallback = NULL;
    ret->context = NULL;
    ret->written = 0;

    return(ret);
}

#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlFreeParserInputBuffer:
 * @in:  a buffered parser input
 *
 * Free up the memory used by a buffered parser input
 */
void
xmlFreeParserInputBuffer(xmlParserInputBufferPtr in) {
    if (in == NULL) return;

    if (in->raw) {
        xmlBufFree(in->raw);
	in->raw = NULL;
    }
    if (in->encoder != NULL) {
        xmlCharEncCloseFunc(in->encoder);
    }
    if (in->closecallback != NULL) {
	in->closecallback(in->context);
    }
    if (in->buffer != NULL) {
        xmlBufFree(in->buffer);
	in->buffer = NULL;
    }

    xmlFree(in);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlOutputBufferClose:
 * @out:  a buffered output
 *
 * flushes and close the output I/O channel
 * and free up all the associated resources
 *
 * Returns the number of byte written or -1 in case of error.
 */
int
xmlOutputBufferClose(xmlOutputBufferPtr out)
{
    int written;
    int err_rc = 0;

    if (out == NULL)
        return (-1);
    if (out->writecallback != NULL)
        xmlOutputBufferFlush(out);
    if (out->closecallback != NULL) {
        err_rc = out->closecallback(out->context);
    }
    written = out->written;
    if (out->conv) {
        xmlBufFree(out->conv);
        out->conv = NULL;
    }
    if (out->encoder != NULL) {
        xmlCharEncCloseFunc(out->encoder);
    }
    if (out->buffer != NULL) {
        xmlBufFree(out->buffer);
        out->buffer = NULL;
    }

    if (out->error)
        err_rc = -1;
    xmlFree(out);
    return ((err_rc == 0) ? written : err_rc);
}
#endif /* LIBXML_OUTPUT_ENABLED */

xmlParserInputBufferPtr
__xmlParserInputBufferCreateFilename(const char *URI, xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;
    int i = 0;
    void *context = NULL;

    if (xmlInputCallbackInitialized == 0)
	xmlRegisterDefaultInputCallbacks();

    if (URI == NULL) return(NULL);

    /*
     * Try to find one of the input accept method accepting that scheme
     * Go in reverse to give precedence to user defined handlers.
     */
    if (context == NULL) {
	for (i = xmlInputCallbackNr - 1;i >= 0;i--) {
	    if ((xmlInputCallbackTable[i].matchcallback != NULL) &&
		(xmlInputCallbackTable[i].matchcallback(URI) != 0)) {
		context = xmlInputCallbackTable[i].opencallback(URI);
		if (context != NULL) {
		    break;
		}
	    }
	}
    }
    if (context == NULL) {
	return(NULL);
    }

    /*
     * Allocate the Input buffer front-end.
     */
    ret = xmlAllocParserInputBuffer(enc);
    if (ret != NULL) {
	ret->context = context;
	ret->readcallback = xmlInputCallbackTable[i].readcallback;
	ret->closecallback = xmlInputCallbackTable[i].closecallback;
#ifdef HAVE_ZLIB_H
	if ((xmlInputCallbackTable[i].opencallback == xmlGzfileOpen) &&
		(strcmp(URI, "-") != 0)) {
#if defined(ZLIB_VERNUM) && ZLIB_VERNUM >= 0x1230
            ret->compressed = !gzdirect(context);
#else
	    if (((z_stream *)context)->avail_in > 4) {
	        char *cptr, buff4[4];
		cptr = (char *) ((z_stream *)context)->next_in;
		if (gzread(context, buff4, 4) == 4) {
		    if (strncmp(buff4, cptr, 4) == 0)
		        ret->compressed = 0;
		    else
		        ret->compressed = 1;
		    gzrewind(context);
		}
	    }
#endif
	}
#endif
#ifdef HAVE_LZMA_H
	if ((xmlInputCallbackTable[i].opencallback == xmlXzfileOpen) &&
		(strcmp(URI, "-") != 0)) {
            ret->compressed = __libxml2_xzcompressed(context);
	}
#endif
    }
    else
      xmlInputCallbackTable[i].closecallback (context);

    return(ret);
}

/**
 * xmlParserInputBufferCreateFilename:
 * @URI:  a C string containing the URI or filename
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for the progressive parsing of a file
 * If filename is "-' then we use stdin as the input.
 * Automatic support for ZLIB/Compress compressed document is provided
 * by default if found at compile-time.
 * Do an encoding check if enc == XML_CHAR_ENCODING_NONE
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlParserInputBufferCreateFilename(const char *URI, xmlCharEncoding enc) {
    if ((xmlParserInputBufferCreateFilenameValue)) {
		return xmlParserInputBufferCreateFilenameValue(URI, enc);
	}
	return __xmlParserInputBufferCreateFilename(URI, enc);
}

#ifdef LIBXML_OUTPUT_ENABLED
xmlOutputBufferPtr
__xmlOutputBufferCreateFilename(const char *URI,
                              xmlCharEncodingHandlerPtr encoder,
                              int compression ATTRIBUTE_UNUSED) {
    xmlOutputBufferPtr ret;
    xmlURIPtr puri;
    int i = 0;
    void *context = NULL;
    char *unescaped = NULL;
#ifdef HAVE_ZLIB_H
    int is_file_uri = 1;
#endif

    if (xmlOutputCallbackInitialized == 0)
	xmlRegisterDefaultOutputCallbacks();

    if (URI == NULL) return(NULL);

    puri = xmlParseURI(URI);
    if (puri != NULL) {
#ifdef HAVE_ZLIB_H
        if ((puri->scheme != NULL) &&
	    (!xmlStrEqual(BAD_CAST puri->scheme, BAD_CAST "file")))
	    is_file_uri = 0;
#endif
	/*
	 * try to limit the damages of the URI unescaping code.
	 */
	if ((puri->scheme == NULL) ||
	    (xmlStrEqual(BAD_CAST puri->scheme, BAD_CAST "file")))
	    unescaped = xmlURIUnescapeString(URI, 0, NULL);
	xmlFreeURI(puri);
    }

    /*
     * Try to find one of the output accept method accepting that scheme
     * Go in reverse to give precedence to user defined handlers.
     * try with an unescaped version of the URI
     */
    if (unescaped != NULL) {
#ifdef HAVE_ZLIB_H
	if ((compression > 0) && (compression <= 9) && (is_file_uri == 1)) {
	    context = xmlGzfileOpenW(unescaped, compression);
	    if (context != NULL) {
		ret = xmlAllocOutputBufferInternal(encoder);
		if (ret != NULL) {
		    ret->context = context;
		    ret->writecallback = xmlGzfileWrite;
		    ret->closecallback = xmlGzfileClose;
		}
		xmlFree(unescaped);
		return(ret);
	    }
	}
#endif
	for (i = xmlOutputCallbackNr - 1;i >= 0;i--) {
	    if ((xmlOutputCallbackTable[i].matchcallback != NULL) &&
		(xmlOutputCallbackTable[i].matchcallback(unescaped) != 0)) {
#if defined(LIBXML_HTTP_ENABLED) && defined(HAVE_ZLIB_H)
		/*  Need to pass compression parameter into HTTP open calls  */
		if (xmlOutputCallbackTable[i].matchcallback == xmlIOHTTPMatch)
		    context = xmlIOHTTPOpenW(unescaped, compression);
		else
#endif
		    context = xmlOutputCallbackTable[i].opencallback(unescaped);
		if (context != NULL)
		    break;
	    }
	}
	xmlFree(unescaped);
    }

    /*
     * If this failed try with a non-escaped URI this may be a strange
     * filename
     */
    if (context == NULL) {
#ifdef HAVE_ZLIB_H
	if ((compression > 0) && (compression <= 9) && (is_file_uri == 1)) {
	    context = xmlGzfileOpenW(URI, compression);
	    if (context != NULL) {
		ret = xmlAllocOutputBufferInternal(encoder);
		if (ret != NULL) {
		    ret->context = context;
		    ret->writecallback = xmlGzfileWrite;
		    ret->closecallback = xmlGzfileClose;
		}
		return(ret);
	    }
	}
#endif
	for (i = xmlOutputCallbackNr - 1;i >= 0;i--) {
	    if ((xmlOutputCallbackTable[i].matchcallback != NULL) &&
		(xmlOutputCallbackTable[i].matchcallback(URI) != 0)) {
#if defined(LIBXML_HTTP_ENABLED) && defined(HAVE_ZLIB_H)
		/*  Need to pass compression parameter into HTTP open calls  */
		if (xmlOutputCallbackTable[i].matchcallback == xmlIOHTTPMatch)
		    context = xmlIOHTTPOpenW(URI, compression);
		else
#endif
		    context = xmlOutputCallbackTable[i].opencallback(URI);
		if (context != NULL)
		    break;
	    }
	}
    }

    if (context == NULL) {
	return(NULL);
    }

    /*
     * Allocate the Output buffer front-end.
     */
    ret = xmlAllocOutputBufferInternal(encoder);
    if (ret != NULL) {
	ret->context = context;
	ret->writecallback = xmlOutputCallbackTable[i].writecallback;
	ret->closecallback = xmlOutputCallbackTable[i].closecallback;
    }
    return(ret);
}

/**
 * xmlOutputBufferCreateFilename:
 * @URI:  a C string containing the URI or filename
 * @encoder:  the encoding converter or NULL
 * @compression:  the compression ration (0 none, 9 max).
 *
 * Create a buffered  output for the progressive saving of a file
 * If filename is "-' then we use stdout as the output.
 * Automatic support for ZLIB/Compress compressed document is provided
 * by default if found at compile-time.
 * TODO: currently if compression is set, the library only support
 *       writing to a local file.
 *
 * Returns the new output or NULL
 */
xmlOutputBufferPtr
xmlOutputBufferCreateFilename(const char *URI,
                              xmlCharEncodingHandlerPtr encoder,
                              int compression ATTRIBUTE_UNUSED) {
    if ((xmlOutputBufferCreateFilenameValue)) {
		return xmlOutputBufferCreateFilenameValue(URI, encoder, compression);
	}
	return __xmlOutputBufferCreateFilename(URI, encoder, compression);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlParserInputBufferCreateFile:
 * @file:  a FILE*
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for the progressive parsing of a FILE *
 * buffered C I/O
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlParserInputBufferCreateFile(FILE *file, xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;

    if (xmlInputCallbackInitialized == 0)
	xmlRegisterDefaultInputCallbacks();

    if (file == NULL) return(NULL);

    ret = xmlAllocParserInputBuffer(enc);
    if (ret != NULL) {
        ret->context = file;
	ret->readcallback = xmlFileRead;
	ret->closecallback = xmlFileFlush;
    }

    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlOutputBufferCreateFile:
 * @file:  a FILE*
 * @encoder:  the encoding converter or NULL
 *
 * Create a buffered output for the progressive saving to a FILE *
 * buffered C I/O
 *
 * Returns the new parser output or NULL
 */
xmlOutputBufferPtr
xmlOutputBufferCreateFile(FILE *file, xmlCharEncodingHandlerPtr encoder) {
    xmlOutputBufferPtr ret;

    if (xmlOutputCallbackInitialized == 0)
	xmlRegisterDefaultOutputCallbacks();

    if (file == NULL) return(NULL);

    ret = xmlAllocOutputBufferInternal(encoder);
    if (ret != NULL) {
        ret->context = file;
	ret->writecallback = xmlFileWrite;
	ret->closecallback = xmlFileFlush;
    }

    return(ret);
}

/**
 * xmlOutputBufferCreateBuffer:
 * @buffer:  a xmlBufferPtr
 * @encoder:  the encoding converter or NULL
 *
 * Create a buffered output for the progressive saving to a xmlBuffer
 *
 * Returns the new parser output or NULL
 */
xmlOutputBufferPtr
xmlOutputBufferCreateBuffer(xmlBufferPtr buffer,
                            xmlCharEncodingHandlerPtr encoder) {
    xmlOutputBufferPtr ret;

    if (buffer == NULL) return(NULL);

    ret = xmlOutputBufferCreateIO((xmlOutputWriteCallback)
                                  xmlBufferWrite,
                                  (xmlOutputCloseCallback)
                                  NULL, (void *) buffer, encoder);

    return(ret);
}

/**
 * xmlOutputBufferGetContent:
 * @out:  an xmlOutputBufferPtr
 *
 * Gives a pointer to the data currently held in the output buffer
 *
 * Returns a pointer to the data or NULL in case of error
 */
const xmlChar *
xmlOutputBufferGetContent(xmlOutputBufferPtr out) {
    if ((out == NULL) || (out->buffer == NULL))
        return(NULL);

    return(xmlBufContent(out->buffer));
}

/**
 * xmlOutputBufferGetSize:
 * @out:  an xmlOutputBufferPtr
 *
 * Gives the length of the data currently held in the output buffer
 *
 * Returns 0 in case or error or no data is held, the size otherwise
 */
size_t
xmlOutputBufferGetSize(xmlOutputBufferPtr out) {
    if ((out == NULL) || (out->buffer == NULL))
        return(0);

    return(xmlBufUse(out->buffer));
}


#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlParserInputBufferCreateFd:
 * @fd:  a file descriptor number
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for the progressive parsing for the input
 * from a file descriptor
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlParserInputBufferCreateFd(int fd, xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;

    if (fd < 0) return(NULL);

    ret = xmlAllocParserInputBuffer(enc);
    if (ret != NULL) {
        ret->context = (void *) (long) fd;
	ret->readcallback = xmlFdRead;
	ret->closecallback = xmlFdClose;
    }

    return(ret);
}

/**
 * xmlParserInputBufferCreateMem:
 * @mem:  the memory input
 * @size:  the length of the memory block
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for the progressive parsing for the input
 * from a memory area.
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlParserInputBufferCreateMem(const char *mem, int size, xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;
    int errcode;

    if (size <= 0) return(NULL);
    if (mem == NULL) return(NULL);

    ret = xmlAllocParserInputBuffer(enc);
    if (ret != NULL) {
        ret->context = (void *) mem;
	ret->readcallback = (xmlInputReadCallback) xmlNop;
	ret->closecallback = NULL;
	errcode = xmlBufAdd(ret->buffer, (const xmlChar *) mem, size);
	if (errcode != 0) {
	    xmlFree(ret);
	    return(NULL);
	}
    }

    return(ret);
}

/**
 * xmlParserInputBufferCreateStatic:
 * @mem:  the memory input
 * @size:  the length of the memory block
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for the progressive parsing for the input
 * from an immutable memory area. This will not copy the memory area to
 * the buffer, but the memory is expected to be available until the end of
 * the parsing, this is useful for example when using mmap'ed file.
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlParserInputBufferCreateStatic(const char *mem, int size,
                                 xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;

    if (size <= 0) return(NULL);
    if (mem == NULL) return(NULL);

    ret = (xmlParserInputBufferPtr) xmlMalloc(sizeof(xmlParserInputBuffer));
    if (ret == NULL) {
	xmlIOErrMemory("creating input buffer");
	return(NULL);
    }
    memset(ret, 0, (size_t) sizeof(xmlParserInputBuffer));
    ret->buffer = xmlBufCreateStatic((void *)mem, (size_t) size);
    if (ret->buffer == NULL) {
        xmlFree(ret);
	return(NULL);
    }
    ret->encoder = xmlGetCharEncodingHandler(enc);
    if (ret->encoder != NULL)
        ret->raw = xmlBufCreateSize(2 * xmlDefaultBufferSize);
    else
        ret->raw = NULL;
    ret->compressed = -1;
    ret->context = (void *) mem;
    ret->readcallback = NULL;
    ret->closecallback = NULL;

    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlOutputBufferCreateFd:
 * @fd:  a file descriptor number
 * @encoder:  the encoding converter or NULL
 *
 * Create a buffered output for the progressive saving
 * to a file descriptor
 *
 * Returns the new parser output or NULL
 */
xmlOutputBufferPtr
xmlOutputBufferCreateFd(int fd, xmlCharEncodingHandlerPtr encoder) {
    xmlOutputBufferPtr ret;

    if (fd < 0) return(NULL);

    ret = xmlAllocOutputBufferInternal(encoder);
    if (ret != NULL) {
        ret->context = (void *) (long) fd;
	ret->writecallback = xmlFdWrite;
	ret->closecallback = NULL;
    }

    return(ret);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlParserInputBufferCreateIO:
 * @ioread:  an I/O read function
 * @ioclose:  an I/O close function
 * @ioctx:  an I/O handler
 * @enc:  the charset encoding if known
 *
 * Create a buffered parser input for the progressive parsing for the input
 * from an I/O handler
 *
 * Returns the new parser input or NULL
 */
xmlParserInputBufferPtr
xmlParserInputBufferCreateIO(xmlInputReadCallback   ioread,
	 xmlInputCloseCallback  ioclose, void *ioctx, xmlCharEncoding enc) {
    xmlParserInputBufferPtr ret;

    if (ioread == NULL) return(NULL);

    ret = xmlAllocParserInputBuffer(enc);
    if (ret != NULL) {
        ret->context = (void *) ioctx;
	ret->readcallback = ioread;
	ret->closecallback = ioclose;
    }

    return(ret);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlOutputBufferCreateIO:
 * @iowrite:  an I/O write function
 * @ioclose:  an I/O close function
 * @ioctx:  an I/O handler
 * @encoder:  the charset encoding if known
 *
 * Create a buffered output for the progressive saving
 * to an I/O handler
 *
 * Returns the new parser output or NULL
 */
xmlOutputBufferPtr
xmlOutputBufferCreateIO(xmlOutputWriteCallback   iowrite,
	 xmlOutputCloseCallback  ioclose, void *ioctx,
	 xmlCharEncodingHandlerPtr encoder) {
    xmlOutputBufferPtr ret;

    if (iowrite == NULL) return(NULL);

    ret = xmlAllocOutputBufferInternal(encoder);
    if (ret != NULL) {
        ret->context = (void *) ioctx;
	ret->writecallback = iowrite;
	ret->closecallback = ioclose;
    }

    return(ret);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlParserInputBufferCreateFilenameDefault:
 * @func: function pointer to the new ParserInputBufferCreateFilenameFunc
 *
 * Registers a callback for URI input file handling
 *
 * Returns the old value of the registration function
 */
xmlParserInputBufferCreateFilenameFunc
xmlParserInputBufferCreateFilenameDefault(xmlParserInputBufferCreateFilenameFunc func)
{
    xmlParserInputBufferCreateFilenameFunc old = xmlParserInputBufferCreateFilenameValue;
    if (old == NULL) {
		old = __xmlParserInputBufferCreateFilename;
	}

    xmlParserInputBufferCreateFilenameValue = func;
    return(old);
}

/**
 * xmlOutputBufferCreateFilenameDefault:
 * @func: function pointer to the new OutputBufferCreateFilenameFunc
 *
 * Registers a callback for URI output file handling
 *
 * Returns the old value of the registration function
 */
xmlOutputBufferCreateFilenameFunc
xmlOutputBufferCreateFilenameDefault(xmlOutputBufferCreateFilenameFunc func)
{
    xmlOutputBufferCreateFilenameFunc old = xmlOutputBufferCreateFilenameValue;
#ifdef LIBXML_OUTPUT_ENABLED
    if (old == NULL) {
		old = __xmlOutputBufferCreateFilename;
	}
#endif
    xmlOutputBufferCreateFilenameValue = func;
    return(old);
}

/**
 * xmlParserInputBufferPush:
 * @in:  a buffered parser input
 * @len:  the size in bytes of the array.
 * @buf:  an char array
 *
 * Push the content of the arry in the input buffer
 * This routine handle the I18N transcoding to internal UTF-8
 * This is used when operating the parser in progressive (push) mode.
 *
 * Returns the number of chars read and stored in the buffer, or -1
 *         in case of error.
 */
int
xmlParserInputBufferPush(xmlParserInputBufferPtr in,
	                 int len, const char *buf) {
    int nbchars = 0;
    int ret;

    if (len < 0) return(0);
    if ((in == NULL) || (in->error)) return(-1);
    if (in->encoder != NULL) {
        unsigned int use;

        /*
	 * Store the data in the incoming raw buffer
	 */
        if (in->raw == NULL) {
	    in->raw = xmlBufCreate();
	}
	ret = xmlBufAdd(in->raw, (const xmlChar *) buf, len);
	if (ret != 0)
	    return(-1);

	/*
	 * convert as much as possible to the parser reading buffer.
	 */
	use = xmlBufUse(in->raw);
	nbchars = xmlCharEncInput(in, 1);
	if (nbchars < 0) {
	    xmlIOErr(XML_IO_ENCODER, NULL);
	    in->error = XML_IO_ENCODER;
	    return(-1);
	}
	in->rawconsumed += (use - xmlBufUse(in->raw));
    } else {
	nbchars = len;
        ret = xmlBufAdd(in->buffer, (xmlChar *) buf, nbchars);
	if (ret != 0)
	    return(-1);
    }
#ifdef DEBUG_INPUT
    xmlGenericError(xmlGenericErrorContext,
	    "I/O: pushed %d chars, buffer %d/%d\n",
            nbchars, xmlBufUse(in->buffer), xmlBufLength(in->buffer));
#endif
    return(nbchars);
}

/**
 * endOfInput:
 *
 * When reading from an Input channel indicated end of file or error
 * don't reread from it again.
 */
static int
endOfInput (void * context ATTRIBUTE_UNUSED,
	    char * buffer ATTRIBUTE_UNUSED,
	    int len ATTRIBUTE_UNUSED) {
    return(0);
}

/**
 * xmlParserInputBufferGrow:
 * @in:  a buffered parser input
 * @len:  indicative value of the amount of chars to read
 *
 * Grow up the content of the input buffer, the old data are preserved
 * This routine handle the I18N transcoding to internal UTF-8
 * This routine is used when operating the parser in normal (pull) mode
 *
 * TODO: one should be able to remove one extra copy by copying directly
 *       onto in->buffer or in->raw
 *
 * Returns the number of chars read and stored in the buffer, or -1
 *         in case of error.
 */
int
xmlParserInputBufferGrow(xmlParserInputBufferPtr in, int len) {
    char *buffer = NULL;
    int res = 0;
    int nbchars = 0;

    if ((in == NULL) || (in->error)) return(-1);
    if ((len <= MINLEN) && (len != 4))
        len = MINLEN;

    if (xmlBufAvail(in->buffer) <= 0) {
	xmlIOErr(XML_IO_BUFFER_FULL, NULL);
	in->error = XML_IO_BUFFER_FULL;
	return(-1);
    }

    if (xmlBufGrow(in->buffer, len + 1) < 0) {
        xmlIOErrMemory("growing input buffer");
        in->error = XML_ERR_NO_MEMORY;
        return(-1);
    }
    buffer = (char *)xmlBufEnd(in->buffer);

    /*
     * Call the read method for this I/O type.
     */
    if (in->readcallback != NULL) {
	res = in->readcallback(in->context, &buffer[0], len);
	if (res <= 0)
	    in->readcallback = endOfInput;
    } else {
	xmlIOErr(XML_IO_NO_INPUT, NULL);
	in->error = XML_IO_NO_INPUT;
	return(-1);
    }
    if (res < 0) {
	return(-1);
    }

    /*
     * try to establish compressed status of input if not done already
     */
    if (in->compressed == -1) {
#ifdef HAVE_LZMA_H
	if (in->readcallback == xmlXzfileRead)
            in->compressed = __libxml2_xzcompressed(in->context);
#endif
    }

    len = res;
    if (in->encoder != NULL) {
        unsigned int use;

        /*
	 * Store the data in the incoming raw buffer
	 */
        if (in->raw == NULL) {
	    in->raw = xmlBufCreate();
	}
	res = xmlBufAdd(in->raw, (const xmlChar *) buffer, len);
	if (res != 0)
	    return(-1);

	/*
	 * convert as much as possible to the parser reading buffer.
	 */
	use = xmlBufUse(in->raw);
	nbchars = xmlCharEncInput(in, 1);
	if (nbchars < 0) {
	    xmlIOErr(XML_IO_ENCODER, NULL);
	    in->error = XML_IO_ENCODER;
	    return(-1);
	}
	in->rawconsumed += (use - xmlBufUse(in->raw));
    } else {
	nbchars = len;
        xmlBufAddLen(in->buffer, nbchars);
    }
#ifdef DEBUG_INPUT
    xmlGenericError(xmlGenericErrorContext,
	    "I/O: read %d chars, buffer %d\n",
            nbchars, xmlBufUse(in->buffer));
#endif
    return(nbchars);
}

/**
 * xmlParserInputBufferRead:
 * @in:  a buffered parser input
 * @len:  indicative value of the amount of chars to read
 *
 * Refresh the content of the input buffer, the old data are considered
 * consumed
 * This routine handle the I18N transcoding to internal UTF-8
 *
 * Returns the number of chars read and stored in the buffer, or -1
 *         in case of error.
 */
int
xmlParserInputBufferRead(xmlParserInputBufferPtr in, int len) {
    if ((in == NULL) || (in->error)) return(-1);
    if (in->readcallback != NULL)
	return(xmlParserInputBufferGrow(in, len));
    else if (xmlBufGetAllocationScheme(in->buffer) == XML_BUFFER_ALLOC_IMMUTABLE)
	return(0);
    else
        return(-1);
}

#ifdef LIBXML_OUTPUT_ENABLED
/**
 * xmlOutputBufferWrite:
 * @out:  a buffered parser output
 * @len:  the size in bytes of the array.
 * @buf:  an char array
 *
 * Write the content of the array in the output I/O buffer
 * This routine handle the I18N transcoding from internal UTF-8
 * The buffer is lossless, i.e. will store in case of partial
 * or delayed writes.
 *
 * Returns the number of chars immediately written, or -1
 *         in case of error.
 */
int
xmlOutputBufferWrite(xmlOutputBufferPtr out, int len, const char *buf) {
    int nbchars = 0; /* number of chars to output to I/O */
    int ret;         /* return from function call */
    int written = 0; /* number of char written to I/O so far */
    int chunk;       /* number of byte curreent processed from buf */

    if ((out == NULL) || (out->error)) return(-1);
    if (len < 0) return(0);
    if (out->error) return(-1);

    do {
	chunk = len;
	if (chunk > 4 * MINLEN)
	    chunk = 4 * MINLEN;

	/*
	 * first handle encoding stuff.
	 */
	if (out->encoder != NULL) {
	    /*
	     * Store the data in the incoming raw buffer
	     */
	    if (out->conv == NULL) {
		out->conv = xmlBufCreate();
	    }
	    ret = xmlBufAdd(out->buffer, (const xmlChar *) buf, chunk);
	    if (ret != 0)
	        return(-1);

	    if ((xmlBufUse(out->buffer) < MINLEN) && (chunk == len))
		goto done;

	    /*
	     * convert as much as possible to the parser reading buffer.
	     */
	    ret = xmlCharEncOutput(out, 0);
	    if ((ret < 0) && (ret != -3)) {
		xmlIOErr(XML_IO_ENCODER, NULL);
		out->error = XML_IO_ENCODER;
		return(-1);
	    }
	    nbchars = xmlBufUse(out->conv);
	} else {
	    ret = xmlBufAdd(out->buffer, (const xmlChar *) buf, chunk);
	    if (ret != 0)
	        return(-1);
	    nbchars = xmlBufUse(out->buffer);
	}
	buf += chunk;
	len -= chunk;

	if ((nbchars < MINLEN) && (len <= 0))
	    goto done;

	if (out->writecallback) {
	    /*
	     * second write the stuff to the I/O channel
	     */
	    if (out->encoder != NULL) {
		ret = out->writecallback(out->context,
                           (const char *)xmlBufContent(out->conv), nbchars);
		if (ret >= 0)
		    xmlBufShrink(out->conv, ret);
	    } else {
		ret = out->writecallback(out->context,
                           (const char *)xmlBufContent(out->buffer), nbchars);
		if (ret >= 0)
		    xmlBufShrink(out->buffer, ret);
	    }
	    if (ret < 0) {
		xmlIOErr(XML_IO_WRITE, NULL);
		out->error = XML_IO_WRITE;
		return(ret);
	    }
	    out->written += ret;
	}
	written += nbchars;
    } while (len > 0);

done:
#ifdef DEBUG_INPUT
    xmlGenericError(xmlGenericErrorContext,
	    "I/O: wrote %d chars\n", written);
#endif
    return(written);
}

/**
 * xmlEscapeContent:
 * @out:  a pointer to an array of bytes to store the result
 * @outlen:  the length of @out
 * @in:  a pointer to an array of unescaped UTF-8 bytes
 * @inlen:  the length of @in
 *
 * Take a block of UTF-8 chars in and escape them.
 * Returns 0 if success, or -1 otherwise
 * The value of @inlen after return is the number of octets consumed
 *     if the return value is positive, else unpredictable.
 * The value of @outlen after return is the number of octets consumed.
 */
static int
xmlEscapeContent(unsigned char* out, int *outlen,
                 const xmlChar* in, int *inlen) {
    unsigned char* outstart = out;
    const unsigned char* base = in;
    unsigned char* outend = out + *outlen;
    const unsigned char* inend;

    inend = in + (*inlen);

    while ((in < inend) && (out < outend)) {
	if (*in == '<') {
	    if (outend - out < 4) break;
	    *out++ = '&';
	    *out++ = 'l';
	    *out++ = 't';
	    *out++ = ';';
	} else if (*in == '>') {
	    if (outend - out < 4) break;
	    *out++ = '&';
	    *out++ = 'g';
	    *out++ = 't';
	    *out++ = ';';
	} else if (*in == '&') {
	    if (outend - out < 5) break;
	    *out++ = '&';
	    *out++ = 'a';
	    *out++ = 'm';
	    *out++ = 'p';
	    *out++ = ';';
	} else if (*in == '\r') {
	    if (outend - out < 5) break;
	    *out++ = '&';
	    *out++ = '#';
	    *out++ = '1';
	    *out++ = '3';
	    *out++ = ';';
	} else {
	    *out++ = (unsigned char) *in;
	}
	++in;
    }
    *outlen = out - outstart;
    *inlen = in - base;
    return(0);
}

/**
 * xmlOutputBufferWriteEscape:
 * @out:  a buffered parser output
 * @str:  a zero terminated UTF-8 string
 * @escaping:  an optional escaping function (or NULL)
 *
 * Write the content of the string in the output I/O buffer
 * This routine escapes the caracters and then handle the I18N
 * transcoding from internal UTF-8
 * The buffer is lossless, i.e. will store in case of partial
 * or delayed writes.
 *
 * Returns the number of chars immediately written, or -1
 *         in case of error.
 */
int
xmlOutputBufferWriteEscape(xmlOutputBufferPtr out, const xmlChar *str,
                           xmlCharEncodingOutputFunc escaping) {
    int nbchars = 0; /* number of chars to output to I/O */
    int ret;         /* return from function call */
    int written = 0; /* number of char written to I/O so far */
    int oldwritten=0;/* loop guard */
    int chunk;       /* number of byte currently processed from str */
    int len;         /* number of bytes in str */
    int cons;        /* byte from str consumed */

    if ((out == NULL) || (out->error) || (str == NULL) ||
        (out->buffer == NULL) ||
	(xmlBufGetAllocationScheme(out->buffer) == XML_BUFFER_ALLOC_IMMUTABLE))
        return(-1);
    len = strlen((const char *)str);
    if (len < 0) return(0);
    if (out->error) return(-1);
    if (escaping == NULL) escaping = xmlEscapeContent;

    do {
        oldwritten = written;

        /*
	 * how many bytes to consume and how many bytes to store.
	 */
	cons = len;
	chunk = xmlBufAvail(out->buffer) - 1;

        /*
	 * make sure we have enough room to save first, if this is
	 * not the case force a flush, but make sure we stay in the loop
	 */
	if (chunk < 40) {
	    if (xmlBufGrow(out->buffer, 100) < 0)
	        return(-1);
            oldwritten = -1;
	    continue;
	}

	/*
	 * first handle encoding stuff.
	 */
	if (out->encoder != NULL) {
	    /*
	     * Store the data in the incoming raw buffer
	     */
	    if (out->conv == NULL) {
		out->conv = xmlBufCreate();
	    }
	    ret = escaping(xmlBufEnd(out->buffer) ,
	                   &chunk, str, &cons);
	    if ((ret < 0) || (chunk == 0)) /* chunk==0 => nothing done */
	        return(-1);
            xmlBufAddLen(out->buffer, chunk);

	    if ((xmlBufUse(out->buffer) < MINLEN) && (cons == len))
		goto done;

	    /*
	     * convert as much as possible to the output buffer.
	     */
	    ret = xmlCharEncOutput(out, 0);
	    if ((ret < 0) && (ret != -3)) {
		xmlIOErr(XML_IO_ENCODER, NULL);
		out->error = XML_IO_ENCODER;
		return(-1);
	    }
	    nbchars = xmlBufUse(out->conv);
	} else {
	    ret = escaping(xmlBufEnd(out->buffer), &chunk, str, &cons);
	    if ((ret < 0) || (chunk == 0)) /* chunk==0 => nothing done */
	        return(-1);
            xmlBufAddLen(out->buffer, chunk);
	    nbchars = xmlBufUse(out->buffer);
	}
	str += cons;
	len -= cons;

	if ((nbchars < MINLEN) && (len <= 0))
	    goto done;

	if (out->writecallback) {
	    /*
	     * second write the stuff to the I/O channel
	     */
	    if (out->encoder != NULL) {
		ret = out->writecallback(out->context,
                           (const char *)xmlBufContent(out->conv), nbchars);
		if (ret >= 0)
		    xmlBufShrink(out->conv, ret);
	    } else {
		ret = out->writecallback(out->context,
                           (const char *)xmlBufContent(out->buffer), nbchars);
		if (ret >= 0)
		    xmlBufShrink(out->buffer, ret);
	    }
	    if (ret < 0) {
		xmlIOErr(XML_IO_WRITE, NULL);
		out->error = XML_IO_WRITE;
		return(ret);
	    }
	    out->written += ret;
	} else if (xmlBufAvail(out->buffer) < MINLEN) {
	    xmlBufGrow(out->buffer, MINLEN);
	}
	written += nbchars;
    } while ((len > 0) && (oldwritten != written));

done:
#ifdef DEBUG_INPUT
    xmlGenericError(xmlGenericErrorContext,
	    "I/O: wrote %d chars\n", written);
#endif
    return(written);
}

/**
 * xmlOutputBufferWriteString:
 * @out:  a buffered parser output
 * @str:  a zero terminated C string
 *
 * Write the content of the string in the output I/O buffer
 * This routine handle the I18N transcoding from internal UTF-8
 * The buffer is lossless, i.e. will store in case of partial
 * or delayed writes.
 *
 * Returns the number of chars immediately written, or -1
 *         in case of error.
 */
int
xmlOutputBufferWriteString(xmlOutputBufferPtr out, const char *str) {
    int len;

    if ((out == NULL) || (out->error)) return(-1);
    if (str == NULL)
        return(-1);
    len = strlen(str);

    if (len > 0)
	return(xmlOutputBufferWrite(out, len, str));
    return(len);
}

/**
 * xmlOutputBufferFlush:
 * @out:  a buffered output
 *
 * flushes the output I/O channel
 *
 * Returns the number of byte written or -1 in case of error.
 */
int
xmlOutputBufferFlush(xmlOutputBufferPtr out) {
    int nbchars = 0, ret = 0;

    if ((out == NULL) || (out->error)) return(-1);
    /*
     * first handle encoding stuff.
     */
    if ((out->conv != NULL) && (out->encoder != NULL)) {
	/*
	 * convert as much as possible to the parser output buffer.
	 */
	do {
	    nbchars = xmlCharEncOutput(out, 0);
	    if (nbchars < 0) {
		xmlIOErr(XML_IO_ENCODER, NULL);
		out->error = XML_IO_ENCODER;
		return(-1);
	    }
	} while (nbchars);
    }

    /*
     * second flush the stuff to the I/O channel
     */
    if ((out->conv != NULL) && (out->encoder != NULL) &&
	(out->writecallback != NULL)) {
	ret = out->writecallback(out->context,
                                 (const char *)xmlBufContent(out->conv),
                                 xmlBufUse(out->conv));
	if (ret >= 0)
	    xmlBufShrink(out->conv, ret);
    } else if (out->writecallback != NULL) {
	ret = out->writecallback(out->context,
                                 (const char *)xmlBufContent(out->buffer),
                                 xmlBufUse(out->buffer));
	if (ret >= 0)
	    xmlBufShrink(out->buffer, ret);
    }
    if (ret < 0) {
	xmlIOErr(XML_IO_FLUSH, NULL);
	out->error = XML_IO_FLUSH;
	return(ret);
    }
    out->written += ret;

#ifdef DEBUG_INPUT
    xmlGenericError(xmlGenericErrorContext,
	    "I/O: flushed %d chars\n", ret);
#endif
    return(ret);
}
#endif /* LIBXML_OUTPUT_ENABLED */

/**
 * xmlParserGetDirectory:
 * @filename:  the path to a file
 *
 * lookup the directory for that file
 *
 * Returns a new allocated string containing the directory, or NULL.
 */
char *
xmlParserGetDirectory(const char *filename) {
    char *ret = NULL;
    char dir[1024];
    char *cur;

#ifdef _WIN32_WCE  /* easy way by now ... wince does not have dirs! */
    return NULL;
#endif

    if (xmlInputCallbackInitialized == 0)
	xmlRegisterDefaultInputCallbacks();

    if (filename == NULL) return(NULL);

#if defined(WIN32) && !defined(__CYGWIN__)
#   define IS_XMLPGD_SEP(ch) ((ch=='/')||(ch=='\\'))
#else
#   define IS_XMLPGD_SEP(ch) (ch=='/')
#endif

    strncpy(dir, filename, 1023);
    dir[1023] = 0;
    cur = &dir[strlen(dir)];
    while (cur > dir) {
         if (IS_XMLPGD_SEP(*cur)) break;
	 cur --;
    }
    if (IS_XMLPGD_SEP(*cur)) {
        if (cur == dir) dir[1] = 0;
	else *cur = 0;
	ret = xmlMemStrdup(dir);
    } else {
        if (getcwd(dir, 1024) != NULL) {
	    dir[1023] = 0;
	    ret = xmlMemStrdup(dir);
	}
    }
    return(ret);
#undef IS_XMLPGD_SEP
}

/****************************************************************
 *								*
 *		External entities loading			*
 *								*
 ****************************************************************/

/**
 * xmlCheckHTTPInput:
 * @ctxt: an XML parser context
 * @ret: an XML parser input
 *
 * Check an input in case it was created from an HTTP stream, in that
 * case it will handle encoding and update of the base URL in case of
 * redirection. It also checks for HTTP errors in which case the input
 * is cleanly freed up and an appropriate error is raised in context
 *
 * Returns the input or NULL in case of HTTP error.
 */
xmlParserInputPtr
xmlCheckHTTPInput(xmlParserCtxtPtr ctxt, xmlParserInputPtr ret) {
#ifdef LIBXML_HTTP_ENABLED
    if ((ret != NULL) && (ret->buf != NULL) &&
        (ret->buf->readcallback == xmlIOHTTPRead) &&
        (ret->buf->context != NULL)) {
        const char *encoding;
        const char *redir;
        const char *mime;
        int code;

        code = xmlNanoHTTPReturnCode(ret->buf->context);
        if (code >= 400) {
            /* fatal error */
	    if (ret->filename != NULL)
		__xmlLoaderErr(ctxt, "failed to load HTTP resource \"%s\"\n",
                         (const char *) ret->filename);
	    else
		__xmlLoaderErr(ctxt, "failed to load HTTP resource\n", NULL);
            xmlFreeInputStream(ret);
            ret = NULL;
        } else {

            mime = xmlNanoHTTPMimeType(ret->buf->context);
            if ((xmlStrstr(BAD_CAST mime, BAD_CAST "/xml")) ||
                (xmlStrstr(BAD_CAST mime, BAD_CAST "+xml"))) {
                encoding = xmlNanoHTTPEncoding(ret->buf->context);
                if (encoding != NULL) {
                    xmlCharEncodingHandlerPtr handler;

                    handler = xmlFindCharEncodingHandler(encoding);
                    if (handler != NULL) {
                        xmlSwitchInputEncoding(ctxt, ret, handler);
                    } else {
                        __xmlErrEncoding(ctxt, XML_ERR_UNKNOWN_ENCODING,
                                         "Unknown encoding %s",
                                         BAD_CAST encoding, NULL);
                    }
                    if (ret->encoding == NULL)
                        ret->encoding = xmlStrdup(BAD_CAST encoding);
                }
#if 0
            } else if (xmlStrstr(BAD_CAST mime, BAD_CAST "html")) {
#endif
            }
            redir = xmlNanoHTTPRedir(ret->buf->context);
            if (redir != NULL) {
                if (ret->filename != NULL)
                    xmlFree((xmlChar *) ret->filename);
                if (ret->directory != NULL) {
                    xmlFree((xmlChar *) ret->directory);
                    ret->directory = NULL;
                }
                ret->filename =
                    (char *) xmlStrdup((const xmlChar *) redir);
            }
        }
    }
#endif
    return(ret);
}

static int xmlNoNetExists(const char *URL) {
    const char *path;

    if (URL == NULL)
	return(0);

    if (!xmlStrncasecmp(BAD_CAST URL, BAD_CAST "file://localhost/", 17))
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &URL[17];
#else
	path = &URL[16];
#endif
    else if (!xmlStrncasecmp(BAD_CAST URL, BAD_CAST "file:///", 8)) {
#if defined (_WIN32) || defined (__DJGPP__) && !defined(__CYGWIN__)
	path = &URL[8];
#else
	path = &URL[7];
#endif
    } else
	path = URL;

    return xmlCheckFilename(path);
}

#ifdef LIBXML_CATALOG_ENABLED

/**
 * xmlResolveResourceFromCatalog:
 * @URL:  the URL for the entity to load
 * @ID:  the System ID for the entity to load
 * @ctxt:  the context in which the entity is called or NULL
 *
 * Resolves the URL and ID against the appropriate catalog.
 * This function is used by xmlDefaultExternalEntityLoader and
 * xmlNoNetExternalEntityLoader.
 *
 * Returns a new allocated URL, or NULL.
 */
static xmlChar *
xmlResolveResourceFromCatalog(const char *URL, const char *ID,
                              xmlParserCtxtPtr ctxt) {
    xmlChar *resource = NULL;
    xmlCatalogAllow pref;

    /*
     * If the resource doesn't exists as a file,
     * try to load it from the resource pointed in the catalogs
     */
    pref = xmlCatalogGetDefaults();

    if ((pref != XML_CATA_ALLOW_NONE) && (!xmlNoNetExists(URL))) {
	/*
	 * Do a local lookup
	 */
	if ((ctxt != NULL) && (ctxt->catalogs != NULL) &&
	    ((pref == XML_CATA_ALLOW_ALL) ||
	     (pref == XML_CATA_ALLOW_DOCUMENT))) {
	    resource = xmlCatalogLocalResolve(ctxt->catalogs,
					      (const xmlChar *)ID,
					      (const xmlChar *)URL);
        }
	/*
	 * Try a global lookup
	 */
	if ((resource == NULL) &&
	    ((pref == XML_CATA_ALLOW_ALL) ||
	     (pref == XML_CATA_ALLOW_GLOBAL))) {
	    resource = xmlCatalogResolve((const xmlChar *)ID,
					 (const xmlChar *)URL);
	}
	if ((resource == NULL) && (URL != NULL))
	    resource = xmlStrdup((const xmlChar *) URL);

	/*
	 * TODO: do an URI lookup on the reference
	 */
	if ((resource != NULL) && (!xmlNoNetExists((const char *)resource))) {
	    xmlChar *tmp = NULL;

	    if ((ctxt != NULL) && (ctxt->catalogs != NULL) &&
		((pref == XML_CATA_ALLOW_ALL) ||
		 (pref == XML_CATA_ALLOW_DOCUMENT))) {
		tmp = xmlCatalogLocalResolveURI(ctxt->catalogs, resource);
	    }
	    if ((tmp == NULL) &&
		((pref == XML_CATA_ALLOW_ALL) ||
	         (pref == XML_CATA_ALLOW_GLOBAL))) {
		tmp = xmlCatalogResolveURI(resource);
	    }

	    if (tmp != NULL) {
		xmlFree(resource);
		resource = tmp;
	    }
	}
    }

    return resource;
}

#endif

/**
 * xmlDefaultExternalEntityLoader:
 * @URL:  the URL for the entity to load
 * @ID:  the System ID for the entity to load
 * @ctxt:  the context in which the entity is called or NULL
 *
 * By default we don't load external entitites, yet.
 *
 * Returns a new allocated xmlParserInputPtr, or NULL.
 */
static xmlParserInputPtr
xmlDefaultExternalEntityLoader(const char *URL, const char *ID,
                               xmlParserCtxtPtr ctxt)
{
    xmlParserInputPtr ret = NULL;
    xmlChar *resource = NULL;

#ifdef DEBUG_EXTERNAL_ENTITIES
    xmlGenericError(xmlGenericErrorContext,
                    "xmlDefaultExternalEntityLoader(%s, xxx)\n", URL);
#endif
    if ((ctxt != NULL) && (ctxt->options & XML_PARSE_NONET)) {
        int options = ctxt->options;

	ctxt->options -= XML_PARSE_NONET;
        ret = xmlNoNetExternalEntityLoader(URL, ID, ctxt);
	ctxt->options = options;
	return(ret);
    }
#ifdef LIBXML_CATALOG_ENABLED
    resource = xmlResolveResourceFromCatalog(URL, ID, ctxt);
#endif

    if (resource == NULL)
        resource = (xmlChar *) URL;

    if (resource == NULL) {
        if (ID == NULL)
            ID = "NULL";
        __xmlLoaderErr(ctxt, "failed to load external entity \"%s\"\n", ID);
        return (NULL);
    }
    ret = xmlNewInputFromFile(ctxt, (const char *) resource);
    if ((resource != NULL) && (resource != (xmlChar *) URL))
        xmlFree(resource);
    return (ret);
}

static xmlExternalEntityLoader xmlCurrentExternalEntityLoader =
       xmlDefaultExternalEntityLoader;

/**
 * xmlSetExternalEntityLoader:
 * @f:  the new entity resolver function
 *
 * Changes the defaultexternal entity resolver function for the application
 */
void
xmlSetExternalEntityLoader(xmlExternalEntityLoader f) {
    xmlCurrentExternalEntityLoader = f;
}

/**
 * xmlGetExternalEntityLoader:
 *
 * Get the default external entity resolver function for the application
 *
 * Returns the xmlExternalEntityLoader function pointer
 */
xmlExternalEntityLoader
xmlGetExternalEntityLoader(void) {
    return(xmlCurrentExternalEntityLoader);
}

/**
 * xmlLoadExternalEntity:
 * @URL:  the URL for the entity to load
 * @ID:  the Public ID for the entity to load
 * @ctxt:  the context in which the entity is called or NULL
 *
 * Load an external entity, note that the use of this function for
 * unparsed entities may generate problems
 *
 * Returns the xmlParserInputPtr or NULL
 */
xmlParserInputPtr
xmlLoadExternalEntity(const char *URL, const char *ID,
                      xmlParserCtxtPtr ctxt) {
    if ((URL != NULL) && (xmlNoNetExists(URL) == 0)) {
	char *canonicFilename;
	xmlParserInputPtr ret;

	canonicFilename = (char *) xmlCanonicPath((const xmlChar *) URL);
	if (canonicFilename == NULL) {
            xmlIOErrMemory("building canonical path\n");
	    return(NULL);
	}

	ret = xmlCurrentExternalEntityLoader(canonicFilename, ID, ctxt);
	xmlFree(canonicFilename);
	return(ret);
    }
    return(xmlCurrentExternalEntityLoader(URL, ID, ctxt));
}

/************************************************************************
 *									*
 *		Disabling Network access				*
 *									*
 ************************************************************************/

/**
 * xmlNoNetExternalEntityLoader:
 * @URL:  the URL for the entity to load
 * @ID:  the System ID for the entity to load
 * @ctxt:  the context in which the entity is called or NULL
 *
 * A specific entity loader disabling network accesses, though still
 * allowing local catalog accesses for resolution.
 *
 * Returns a new allocated xmlParserInputPtr, or NULL.
 */
xmlParserInputPtr
xmlNoNetExternalEntityLoader(const char *URL, const char *ID,
                             xmlParserCtxtPtr ctxt) {
    xmlParserInputPtr input = NULL;
    xmlChar *resource = NULL;

#ifdef LIBXML_CATALOG_ENABLED
    resource = xmlResolveResourceFromCatalog(URL, ID, ctxt);
#endif

    if (resource == NULL)
	resource = (xmlChar *) URL;

    if (resource != NULL) {
        if ((!xmlStrncasecmp(BAD_CAST resource, BAD_CAST "ftp://", 6)) ||
            (!xmlStrncasecmp(BAD_CAST resource, BAD_CAST "http://", 7))) {
            xmlIOErr(XML_IO_NETWORK_ATTEMPT, (const char *) resource);
	    if (resource != (xmlChar *) URL)
		xmlFree(resource);
	    return(NULL);
	}
    }
    input = xmlDefaultExternalEntityLoader((const char *) resource, ID, ctxt);
    if (resource != (xmlChar *) URL)
	xmlFree(resource);
    return(input);
}

#define bottom_xmlIO
#include "elfgcchack.h"
