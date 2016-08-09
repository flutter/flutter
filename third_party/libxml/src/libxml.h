/*
 * libxml.h: internal header only used during the compilation of libxml
 *
 * See COPYRIGHT for the status of this software
 *
 * Author: breese@users.sourceforge.net
 */

#ifndef __XML_LIBXML_H__
#define __XML_LIBXML_H__

#ifndef NO_LARGEFILE_SOURCE
#ifndef _LARGEFILE_SOURCE
#define _LARGEFILE_SOURCE
#endif
#ifndef _FILE_OFFSET_BITS
#define _FILE_OFFSET_BITS 64
#endif
#endif
#ifndef _CRT_NO_POSIX_ERROR_CODES
#define _CRT_NO_POSIX_ERROR_CODES
#endif

#if defined(macintosh)
#include "config-mac.h"
#elif defined(_WIN32_WCE)
/*
 * Windows CE compatibility definitions and functions
 * This is needed to compile libxml2 for Windows CE.
 * At least I tested it with WinCE 5.0 for Emulator and WinCE 4.2/SH4 target
 */
#include <win32config.h>
#include <libxml/xmlversion.h>
#else
#include "config.h"
#include <libxml/xmlversion.h>
#endif

#if defined(__Lynx__)
#include <stdio.h> /* pull definition of size_t */
#include <varargs.h>
int snprintf(char *, size_t, const char *, ...);
int vfprintf(FILE *, const char *, va_list);
#endif

#ifndef WITH_TRIO
#include <stdio.h>
#else
/**
 * TRIO_REPLACE_STDIO:
 *
 * This macro is defined if teh trio string formatting functions are to
 * be used instead of the default stdio ones.
 */
#define TRIO_REPLACE_STDIO
#include "trio.h"
#endif

/*
 * Internal variable indicating if a callback has been registered for
 * node creation/destruction. It avoids spending a lot of time in locking
 * function while checking if the callback exists.
 */
extern int __xmlRegisterCallbacks;
/*
 * internal error reporting routines, shared but not partof the API.
 */
void __xmlIOErr(int domain, int code, const char *extra);
void __xmlLoaderErr(void *ctx, const char *msg, const char *filename);
#ifdef LIBXML_HTML_ENABLED
/*
 * internal function of HTML parser needed for xmlParseInNodeContext
 * but not part of the API
 */
void __htmlParseContent(void *ctx);
#endif

/*
 * internal global initialization critical section routines.
 */
void __xmlGlobalInitMutexLock(void);
void __xmlGlobalInitMutexUnlock(void);
void __xmlGlobalInitMutexDestroy(void);

#ifdef IN_LIBXML
#ifdef __GNUC__
#ifdef PIC
#ifdef linux
#if (__GNUC__ == 3 && __GNUC_MINOR__ >= 3) || (__GNUC__ > 3)
#include "elfgcchack.h"
#endif
#endif
#endif
#endif
#endif
#ifndef PIC
#  define LIBXML_STATIC
#endif
#endif /* ! __XML_LIBXML_H__ */
