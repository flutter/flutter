
/* pngconf.h - machine configurable file for libpng
 *
 * libpng version 1.6.22rc01, May 14, 2016
 *
 * Copyright (c) 1998-2002,2004,2006-2015 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 *
 * Any machine specific code is near the front of this file, so if you
 * are configuring libpng for a machine, you may want to read the section
 * starting here down to where it starts to typedef png_color, png_text,
 * and png_info.
 */

#ifndef PNGCONF_H
#define PNGCONF_H

#ifndef PNG_BUILDING_SYMBOL_TABLE /* else includes may cause problems */

/* From libpng 1.6.0 libpng requires an ANSI X3.159-1989 ("ISOC90") compliant C
 * compiler for correct compilation.  The following header files are required by
 * the standard.  If your compiler doesn't provide these header files, or they
 * do not match the standard, you will need to provide/improve them.
 */
#include <limits.h>
#include <stddef.h>

/* Library header files.  These header files are all defined by ISOC90; libpng
 * expects conformant implementations, however, an ISOC90 conformant system need
 * not provide these header files if the functionality cannot be implemented.
 * In this case it will be necessary to disable the relevant parts of libpng in
 * the build of pnglibconf.h.
 *
 * Prior to 1.6.0 string.h was included here; the API changes in 1.6.0 to not
 * include this unnecessary header file.
 */

#ifdef PNG_STDIO_SUPPORTED
   /* Required for the definition of FILE: */
#  include <stdio.h>
#endif

#ifdef PNG_SETJMP_SUPPORTED
   /* Required for the definition of jmp_buf and the declaration of longjmp: */
#  include <setjmp.h>
#endif

#ifdef PNG_CONVERT_tIME_SUPPORTED
   /* Required for struct tm: */
#  include <time.h>
#endif

#endif /* PNG_BUILDING_SYMBOL_TABLE */

/* Prior to 1.6.0 it was possible to turn off 'const' in declarations using
 * PNG_NO_CONST; this is no longer supported except for data declarations which
 * apparently still cause problems in 2011 on some compilers.
 */
#define PNG_CONST const /* backward compatibility only */

/* This controls optimization of the reading of 16-bit and 32-bit values
 * from PNG files.  It can be set on a per-app-file basis - it
 * just changes whether a macro is used when the function is called.
 * The library builder sets the default; if read functions are not
 * built into the library the macro implementation is forced on.
 */
#ifndef PNG_READ_INT_FUNCTIONS_SUPPORTED
#  define PNG_USE_READ_MACROS
#endif
#if !defined(PNG_NO_USE_READ_MACROS) && !defined(PNG_USE_READ_MACROS)
#  if PNG_DEFAULT_READ_MACROS
#    define PNG_USE_READ_MACROS
#  endif
#endif

/* COMPILER SPECIFIC OPTIONS.
 *
 * These options are provided so that a variety of difficult compilers
 * can be used.  Some are fixed at build time (e.g. PNG_API_RULE
 * below) but still have compiler specific implementations, others
 * may be changed on a per-file basis when compiling against libpng.
 */

/* The PNGARG macro was used in versions of libpng prior to 1.6.0 to protect
 * against legacy (pre ISOC90) compilers that did not understand function
 * prototypes.  It is not required for modern C compilers.
 */
#ifndef PNGARG
#  define PNGARG(arglist) arglist
#endif

/* Function calling conventions.
 * =============================
 * Normally it is not necessary to specify to the compiler how to call
 * a function - it just does it - however on x86 systems derived from
 * Microsoft and Borland C compilers ('IBM PC', 'DOS', 'Windows' systems
 * and some others) there are multiple ways to call a function and the
 * default can be changed on the compiler command line.  For this reason
 * libpng specifies the calling convention of every exported function and
 * every function called via a user supplied function pointer.  This is
 * done in this file by defining the following macros:
 *
 * PNGAPI    Calling convention for exported functions.
 * PNGCBAPI  Calling convention for user provided (callback) functions.
 * PNGCAPI   Calling convention used by the ANSI-C library (required
 *           for longjmp callbacks and sometimes used internally to
 *           specify the calling convention for zlib).
 *
 * These macros should never be overridden.  If it is necessary to
 * change calling convention in a private build this can be done
 * by setting PNG_API_RULE (which defaults to 0) to one of the values
 * below to select the correct 'API' variants.
 *
 * PNG_API_RULE=0 Use PNGCAPI - the 'C' calling convention - throughout.
 *                This is correct in every known environment.
 * PNG_API_RULE=1 Use the operating system convention for PNGAPI and
 *                the 'C' calling convention (from PNGCAPI) for
 *                callbacks (PNGCBAPI).  This is no longer required
 *                in any known environment - if it has to be used
 *                please post an explanation of the problem to the
 *                libpng mailing list.
 *
 * These cases only differ if the operating system does not use the C
 * calling convention, at present this just means the above cases
 * (x86 DOS/Windows sytems) and, even then, this does not apply to
 * Cygwin running on those systems.
 *
 * Note that the value must be defined in pnglibconf.h so that what
 * the application uses to call the library matches the conventions
 * set when building the library.
 */

/* Symbol export
 * =============
 * When building a shared library it is almost always necessary to tell
 * the compiler which symbols to export.  The png.h macro 'PNG_EXPORT'
 * is used to mark the symbols.  On some systems these symbols can be
 * extracted at link time and need no special processing by the compiler,
 * on other systems the symbols are flagged by the compiler and just
 * the declaration requires a special tag applied (unfortunately) in a
 * compiler dependent way.  Some systems can do either.
 *
 * A small number of older systems also require a symbol from a DLL to
 * be flagged to the program that calls it.  This is a problem because
 * we do not know in the header file included by application code that
 * the symbol will come from a shared library, as opposed to a statically
 * linked one.  For this reason the application must tell us by setting
 * the magic flag PNG_USE_DLL to turn on the special processing before
 * it includes png.h.
 *
 * Four additional macros are used to make this happen:
 *
 * PNG_IMPEXP The magic (if any) to cause a symbol to be exported from
 *            the build or imported if PNG_USE_DLL is set - compiler
 *            and system specific.
 *
 * PNG_EXPORT_TYPE(type) A macro that pre or appends PNG_IMPEXP to
 *                       'type', compiler specific.
 *
 * PNG_DLL_EXPORT Set to the magic to use during a libpng build to
 *                make a symbol exported from the DLL.  Not used in the
 *                public header files; see pngpriv.h for how it is used
 *                in the libpng build.
 *
 * PNG_DLL_IMPORT Set to the magic to force the libpng symbols to come
 *                from a DLL - used to define PNG_IMPEXP when
 *                PNG_USE_DLL is set.
 */

/* System specific discovery.
 * ==========================
 * This code is used at build time to find PNG_IMPEXP, the API settings
 * and PNG_EXPORT_TYPE(), it may also set a macro to indicate the DLL
 * import processing is possible.  On Windows systems it also sets
 * compiler-specific macros to the values required to change the calling
 * conventions of the various functions.
 */
#if defined(_Windows) || defined(_WINDOWS) || defined(WIN32) ||\
    defined(_WIN32) || defined(__WIN32__) || defined(__CYGWIN__)
  /* Windows system (DOS doesn't support DLLs).  Includes builds under Cygwin or
   * MinGW on any architecture currently supported by Windows.  Also includes
   * Watcom builds but these need special treatment because they are not
   * compatible with GCC or Visual C because of different calling conventions.
   */
#  if PNG_API_RULE == 2
    /* If this line results in an error, either because __watcall is not
     * understood or because of a redefine just below you cannot use *this*
     * build of the library with the compiler you are using.  *This* build was
     * build using Watcom and applications must also be built using Watcom!
     */
#    define PNGCAPI __watcall
#  endif

#  if defined(__GNUC__) || (defined(_MSC_VER) && (_MSC_VER >= 800))
#    define PNGCAPI __cdecl
#    if PNG_API_RULE == 1
       /* If this line results in an error __stdcall is not understood and
        * PNG_API_RULE should not have been set to '1'.
        */
#      define PNGAPI __stdcall
#    endif
#  else
    /* An older compiler, or one not detected (erroneously) above,
     * if necessary override on the command line to get the correct
     * variants for the compiler.
     */
#    ifndef PNGCAPI
#      define PNGCAPI _cdecl
#    endif
#    if PNG_API_RULE == 1 && !defined(PNGAPI)
#      define PNGAPI _stdcall
#    endif
#  endif /* compiler/api */

  /* NOTE: PNGCBAPI always defaults to PNGCAPI. */

#  if defined(PNGAPI) && !defined(PNG_USER_PRIVATEBUILD)
#     error "PNG_USER_PRIVATEBUILD must be defined if PNGAPI is changed"
#  endif

#  if (defined(_MSC_VER) && _MSC_VER < 800) ||\
      (defined(__BORLANDC__) && __BORLANDC__ < 0x500)
    /* older Borland and MSC
     * compilers used '__export' and required this to be after
     * the type.
     */
#    ifndef PNG_EXPORT_TYPE
#      define PNG_EXPORT_TYPE(type) type PNG_IMPEXP
#    endif
#    define PNG_DLL_EXPORT __export
#  else /* newer compiler */
#    define PNG_DLL_EXPORT __declspec(dllexport)
#    ifndef PNG_DLL_IMPORT
#      define PNG_DLL_IMPORT __declspec(dllimport)
#    endif
#  endif /* compiler */

#else /* !Windows */
#  if (defined(__IBMC__) || defined(__IBMCPP__)) && defined(__OS2__)
#    define PNGAPI _System
#  else /* !Windows/x86 && !OS/2 */
    /* Use the defaults, or define PNG*API on the command line (but
     * this will have to be done for every compile!)
     */
#  endif /* other system, !OS/2 */
#endif /* !Windows/x86 */

/* Now do all the defaulting . */
#ifndef PNGCAPI
#  define PNGCAPI
#endif
#ifndef PNGCBAPI
#  define PNGCBAPI PNGCAPI
#endif
#ifndef PNGAPI
#  define PNGAPI PNGCAPI
#endif

/* PNG_IMPEXP may be set on the compilation system command line or (if not set)
 * then in an internal header file when building the library, otherwise (when
 * using the library) it is set here.
 */
#ifndef PNG_IMPEXP
#  if defined(PNG_USE_DLL) && defined(PNG_DLL_IMPORT)
     /* This forces use of a DLL, disallowing static linking */
#    define PNG_IMPEXP PNG_DLL_IMPORT
#  endif

#  ifndef PNG_IMPEXP
#    define PNG_IMPEXP
#  endif
#endif

/* In 1.5.2 the definition of PNG_FUNCTION has been changed to always treat
 * 'attributes' as a storage class - the attributes go at the start of the
 * function definition, and attributes are always appended regardless of the
 * compiler.  This considerably simplifies these macros but may cause problems
 * if any compilers both need function attributes and fail to handle them as
 * a storage class (this is unlikely.)
 */
#ifndef PNG_FUNCTION
#  define PNG_FUNCTION(type, name, args, attributes) attributes type name args
#endif

#ifndef PNG_EXPORT_TYPE
#  define PNG_EXPORT_TYPE(type) PNG_IMPEXP type
#endif

   /* The ordinal value is only relevant when preprocessing png.h for symbol
    * table entries, so we discard it here.  See the .dfn files in the
    * scripts directory.
    */

#ifndef PNG_EXPORTA
#  define PNG_EXPORTA(ordinal, type, name, args, attributes) \
      PNG_FUNCTION(PNG_EXPORT_TYPE(type), (PNGAPI name), PNGARG(args), \
      PNG_LINKAGE_API attributes)
#endif

/* ANSI-C (C90) does not permit a macro to be invoked with an empty argument,
 * so make something non-empty to satisfy the requirement:
 */
#define PNG_EMPTY /*empty list*/

#define PNG_EXPORT(ordinal, type, name, args) \
   PNG_EXPORTA(ordinal, type, name, args, PNG_EMPTY)

/* Use PNG_REMOVED to comment out a removed interface. */
#ifndef PNG_REMOVED
#  define PNG_REMOVED(ordinal, type, name, args, attributes)
#endif

#ifndef PNG_CALLBACK
#  define PNG_CALLBACK(type, name, args) type (PNGCBAPI name) PNGARG(args)
#endif

/* Support for compiler specific function attributes.  These are used
 * so that where compiler support is available incorrect use of API
 * functions in png.h will generate compiler warnings.
 *
 * Added at libpng-1.2.41.
 */

#ifndef PNG_NO_PEDANTIC_WARNINGS
#  ifndef PNG_PEDANTIC_WARNINGS_SUPPORTED
#    define PNG_PEDANTIC_WARNINGS_SUPPORTED
#  endif
#endif

#ifdef PNG_PEDANTIC_WARNINGS_SUPPORTED
  /* Support for compiler specific function attributes.  These are used
   * so that where compiler support is available, incorrect use of API
   * functions in png.h will generate compiler warnings.  Added at libpng
   * version 1.2.41.  Disabling these removes the warnings but may also produce
   * less efficient code.
   */
#  if defined(__clang__) && defined(__has_attribute)
     /* Clang defines both __clang__ and __GNUC__. Check __clang__ first. */
#    if !defined(PNG_USE_RESULT) && __has_attribute(__warn_unused_result__)
#      define PNG_USE_RESULT __attribute__((__warn_unused_result__))
#    endif
#    if !defined(PNG_NORETURN) && __has_attribute(__noreturn__)
#      define PNG_NORETURN __attribute__((__noreturn__))
#    endif
#    if !defined(PNG_ALLOCATED) && __has_attribute(__malloc__)
#      define PNG_ALLOCATED __attribute__((__malloc__))
#    endif
#    if !defined(PNG_DEPRECATED) && __has_attribute(__deprecated__)
#      define PNG_DEPRECATED __attribute__((__deprecated__))
#    endif
#    if !defined(PNG_PRIVATE)
#      ifdef __has_extension
#        if __has_extension(attribute_unavailable_with_message)
#          define PNG_PRIVATE __attribute__((__unavailable__(\
             "This function is not exported by libpng.")))
#        endif
#      endif
#    endif
#    ifndef PNG_RESTRICT
#      define PNG_RESTRICT __restrict
#    endif

#  elif defined(__GNUC__)
#    ifndef PNG_USE_RESULT
#      define PNG_USE_RESULT __attribute__((__warn_unused_result__))
#    endif
#    ifndef PNG_NORETURN
#      define PNG_NORETURN   __attribute__((__noreturn__))
#    endif
#    if __GNUC__ >= 3
#      ifndef PNG_ALLOCATED
#        define PNG_ALLOCATED  __attribute__((__malloc__))
#      endif
#      ifndef PNG_DEPRECATED
#        define PNG_DEPRECATED __attribute__((__deprecated__))
#      endif
#      ifndef PNG_PRIVATE
#        if 0 /* Doesn't work so we use deprecated instead*/
#          define PNG_PRIVATE \
            __attribute__((warning("This function is not exported by libpng.")))
#        else
#          define PNG_PRIVATE \
            __attribute__((__deprecated__))
#        endif
#      endif
#      if ((__GNUC__ > 3) || !defined(__GNUC_MINOR__) || (__GNUC_MINOR__ >= 1))
#        ifndef PNG_RESTRICT
#          define PNG_RESTRICT __restrict
#        endif
#      endif /* __GNUC__.__GNUC_MINOR__ > 3.0 */
#    endif /* __GNUC__ >= 3 */

#  elif defined(_MSC_VER)  && (_MSC_VER >= 1300)
#    ifndef PNG_USE_RESULT
#      define PNG_USE_RESULT /* not supported */
#    endif
#    ifndef PNG_NORETURN
#      define PNG_NORETURN   __declspec(noreturn)
#    endif
#    ifndef PNG_ALLOCATED
#      if (_MSC_VER >= 1400)
#        define PNG_ALLOCATED __declspec(restrict)
#      endif
#    endif
#    ifndef PNG_DEPRECATED
#      define PNG_DEPRECATED __declspec(deprecated)
#    endif
#    ifndef PNG_PRIVATE
#      define PNG_PRIVATE __declspec(deprecated)
#    endif
#    ifndef PNG_RESTRICT
#      if (_MSC_VER >= 1400)
#        define PNG_RESTRICT __restrict
#      endif
#    endif

#  elif defined(__WATCOMC__)
#    ifndef PNG_RESTRICT
#      define PNG_RESTRICT __restrict
#    endif
#  endif
#endif /* PNG_PEDANTIC_WARNINGS */

#ifndef PNG_DEPRECATED
#  define PNG_DEPRECATED  /* Use of this function is deprecated */
#endif
#ifndef PNG_USE_RESULT
#  define PNG_USE_RESULT  /* The result of this function must be checked */
#endif
#ifndef PNG_NORETURN
#  define PNG_NORETURN    /* This function does not return */
#endif
#ifndef PNG_ALLOCATED
#  define PNG_ALLOCATED   /* The result of the function is new memory */
#endif
#ifndef PNG_PRIVATE
#  define PNG_PRIVATE     /* This is a private libpng function */
#endif
#ifndef PNG_RESTRICT
#  define PNG_RESTRICT    /* The C99 "restrict" feature */
#endif

#ifndef PNG_FP_EXPORT     /* A floating point API. */
#  ifdef PNG_FLOATING_POINT_SUPPORTED
#     define PNG_FP_EXPORT(ordinal, type, name, args)\
         PNG_EXPORT(ordinal, type, name, args);
#  else                   /* No floating point APIs */
#     define PNG_FP_EXPORT(ordinal, type, name, args)
#  endif
#endif
#ifndef PNG_FIXED_EXPORT  /* A fixed point API. */
#  ifdef PNG_FIXED_POINT_SUPPORTED
#     define PNG_FIXED_EXPORT(ordinal, type, name, args)\
         PNG_EXPORT(ordinal, type, name, args);
#  else                   /* No fixed point APIs */
#     define PNG_FIXED_EXPORT(ordinal, type, name, args)
#  endif
#endif

#ifndef PNG_BUILDING_SYMBOL_TABLE
/* Some typedefs to get us started.  These should be safe on most of the common
 * platforms.
 *
 * png_uint_32 and png_int_32 may, currently, be larger than required to hold a
 * 32-bit value however this is not normally advisable.
 *
 * png_uint_16 and png_int_16 should always be two bytes in size - this is
 * verified at library build time.
 *
 * png_byte must always be one byte in size.
 *
 * The checks below use constants from limits.h, as defined by the ISOC90
 * standard.
 */
#if CHAR_BIT == 8 && UCHAR_MAX == 255
   typedef unsigned char png_byte;
#else
#  error "libpng requires 8-bit bytes"
#endif

#if INT_MIN == -32768 && INT_MAX == 32767
   typedef int png_int_16;
#elif SHRT_MIN == -32768 && SHRT_MAX == 32767
   typedef short png_int_16;
#else
#  error "libpng requires a signed 16-bit type"
#endif

#if UINT_MAX == 65535
   typedef unsigned int png_uint_16;
#elif USHRT_MAX == 65535
   typedef unsigned short png_uint_16;
#else
#  error "libpng requires an unsigned 16-bit type"
#endif

#if INT_MIN < -2147483646 && INT_MAX > 2147483646
   typedef int png_int_32;
#elif LONG_MIN < -2147483646 && LONG_MAX > 2147483646
   typedef long int png_int_32;
#else
#  error "libpng requires a signed 32-bit (or more) type"
#endif

#if UINT_MAX > 4294967294
   typedef unsigned int png_uint_32;
#elif ULONG_MAX > 4294967294
   typedef unsigned long int png_uint_32;
#else
#  error "libpng requires an unsigned 32-bit (or more) type"
#endif

/* Prior to 1.6.0 it was possible to disable the use of size_t, 1.6.0, however,
 * requires an ISOC90 compiler and relies on consistent behavior of sizeof.
 */
typedef size_t png_size_t;
typedef ptrdiff_t png_ptrdiff_t;

/* libpng needs to know the maximum value of 'size_t' and this controls the
 * definition of png_alloc_size_t, below.  This maximum value of size_t limits
 * but does not control the maximum allocations the library makes - there is
 * direct application control of this through png_set_user_limits().
 */
#ifndef PNG_SMALL_SIZE_T
   /* Compiler specific tests for systems where size_t is known to be less than
    * 32 bits (some of these systems may no longer work because of the lack of
    * 'far' support; see above.)
    */
#  if (defined(__TURBOC__) && !defined(__FLAT__)) ||\
   (defined(_MSC_VER) && defined(MAXSEG_64K))
#     define PNG_SMALL_SIZE_T
#  endif
#endif

/* png_alloc_size_t is guaranteed to be no smaller than png_size_t, and no
 * smaller than png_uint_32.  Casts from png_size_t or png_uint_32 to
 * png_alloc_size_t are not necessary; in fact, it is recommended not to use
 * them at all so that the compiler can complain when something turns out to be
 * problematic.
 *
 * Casts in the other direction (from png_alloc_size_t to png_size_t or
 * png_uint_32) should be explicitly applied; however, we do not expect to
 * encounter practical situations that require such conversions.
 *
 * PNG_SMALL_SIZE_T must be defined if the maximum value of size_t is less than
 * 4294967295 - i.e. less than the maximum value of png_uint_32.
 */
#ifdef PNG_SMALL_SIZE_T
   typedef png_uint_32 png_alloc_size_t;
#else
   typedef png_size_t png_alloc_size_t;
#endif

/* Prior to 1.6.0 libpng offered limited support for Microsoft C compiler
 * implementations of Intel CPU specific support of user-mode segmented address
 * spaces, where 16-bit pointers address more than 65536 bytes of memory using
 * separate 'segment' registers.  The implementation requires two different
 * types of pointer (only one of which includes the segment value.)
 *
 * If required this support is available in version 1.2 of libpng and may be
 * available in versions through 1.5, although the correctness of the code has
 * not been verified recently.
 */

/* Typedef for floating-point numbers that are converted to fixed-point with a
 * multiple of 100,000, e.g., gamma
 */
typedef png_int_32 png_fixed_point;

/* Add typedefs for pointers */
typedef void                  * png_voidp;
typedef const void            * png_const_voidp;
typedef png_byte              * png_bytep;
typedef const png_byte        * png_const_bytep;
typedef png_uint_32           * png_uint_32p;
typedef const png_uint_32     * png_const_uint_32p;
typedef png_int_32            * png_int_32p;
typedef const png_int_32      * png_const_int_32p;
typedef png_uint_16           * png_uint_16p;
typedef const png_uint_16     * png_const_uint_16p;
typedef png_int_16            * png_int_16p;
typedef const png_int_16      * png_const_int_16p;
typedef char                  * png_charp;
typedef const char            * png_const_charp;
typedef png_fixed_point       * png_fixed_point_p;
typedef const png_fixed_point * png_const_fixed_point_p;
typedef png_size_t            * png_size_tp;
typedef const png_size_t      * png_const_size_tp;

#ifdef PNG_STDIO_SUPPORTED
typedef FILE            * png_FILE_p;
#endif

#ifdef PNG_FLOATING_POINT_SUPPORTED
typedef double       * png_doublep;
typedef const double * png_const_doublep;
#endif

/* Pointers to pointers; i.e. arrays */
typedef png_byte        * * png_bytepp;
typedef png_uint_32     * * png_uint_32pp;
typedef png_int_32      * * png_int_32pp;
typedef png_uint_16     * * png_uint_16pp;
typedef png_int_16      * * png_int_16pp;
typedef const char      * * png_const_charpp;
typedef char            * * png_charpp;
typedef png_fixed_point * * png_fixed_point_pp;
#ifdef PNG_FLOATING_POINT_SUPPORTED
typedef double          * * png_doublepp;
#endif

/* Pointers to pointers to pointers; i.e., pointer to array */
typedef char            * * * png_charppp;

#endif /* PNG_BUILDING_SYMBOL_TABLE */

#endif /* PNGCONF_H */
