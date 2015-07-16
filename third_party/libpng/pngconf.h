
/* pngconf.h - machine configurable file for libpng
 *
 * libpng version 1.2.45 - July 7, 2011
 * Copyright (c) 1998-2011 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license.
 * For conditions of distribution and use, see the disclaimer
 * and license in png.h
 */

/* Any machine specific code is near the front of this file, so if you
 * are configuring libpng for a machine, you may want to read the section
 * starting here down to where it starts to typedef png_color, png_text,
 * and png_info.
 */

#ifndef PNGCONF_H
#define PNGCONF_H

#define PNG_1_2_X

/*
 * PNG_USER_CONFIG has to be defined on the compiler command line. This
 * includes the resource compiler for Windows DLL configurations.
 */
#ifdef PNG_USER_CONFIG
#  ifndef PNG_USER_PRIVATEBUILD
#    define PNG_USER_PRIVATEBUILD
#  endif
#include "pngusr.h"
#endif

/* PNG_CONFIGURE_LIBPNG is set by the "configure" script. */
#ifdef PNG_CONFIGURE_LIBPNG
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#endif

/*
 * Added at libpng-1.2.8
 *
 * If you create a private DLL you need to define in "pngusr.h" the followings:
 * #define PNG_USER_PRIVATEBUILD <Describes by whom and why this version of
 *        the DLL was built>
 *  e.g. #define PNG_USER_PRIVATEBUILD "Build by MyCompany for xyz reasons."
 * #define PNG_USER_DLLFNAME_POSTFIX <two-letter postfix that serve to
 *        distinguish your DLL from those of the official release. These
 *        correspond to the trailing letters that come after the version
 *        number and must match your private DLL name>
 *  e.g. // private DLL "libpng13gx.dll"
 *       #define PNG_USER_DLLFNAME_POSTFIX "gx"
 *
 * The following macros are also at your disposal if you want to complete the
 * DLL VERSIONINFO structure.
 * - PNG_USER_VERSIONINFO_COMMENTS
 * - PNG_USER_VERSIONINFO_COMPANYNAME
 * - PNG_USER_VERSIONINFO_LEGALTRADEMARKS
 */

#ifdef __STDC__
#ifdef SPECIALBUILD
#  pragma message("PNG_LIBPNG_SPECIALBUILD (and deprecated SPECIALBUILD)\
 are now LIBPNG reserved macros. Use PNG_USER_PRIVATEBUILD instead.")
#endif

#ifdef PRIVATEBUILD
# pragma message("PRIVATEBUILD is deprecated.\
 Use PNG_USER_PRIVATEBUILD instead.")
# define PNG_USER_PRIVATEBUILD PRIVATEBUILD
#endif
#endif /* __STDC__ */

#ifndef PNG_VERSION_INFO_ONLY

/* End of material added to libpng-1.2.8 */

/* Added at libpng-1.2.19, removed at libpng-1.2.20 because it caused trouble
   Restored at libpng-1.2.21 */
#if !defined(PNG_NO_WARN_UNINITIALIZED_ROW) && \
    !defined(PNG_WARN_UNINITIALIZED_ROW)
#  define PNG_WARN_UNINITIALIZED_ROW 1
#endif
/* End of material added at libpng-1.2.19/1.2.21 */

/* This is the size of the compression buffer, and thus the size of
 * an IDAT chunk.  Make this whatever size you feel is best for your
 * machine.  One of these will be allocated per png_struct.  When this
 * is full, it writes the data to the disk, and does some other
 * calculations.  Making this an extremely small size will slow
 * the library down, but you may want to experiment to determine
 * where it becomes significant, if you are concerned with memory
 * usage.  Note that zlib allocates at least 32Kb also.  For readers,
 * this describes the size of the buffer available to read the data in.
 * Unless this gets smaller than the size of a row (compressed),
 * it should not make much difference how big this is.
 */

#ifndef PNG_ZBUF_SIZE
#  define PNG_ZBUF_SIZE 8192
#endif

/* Enable if you want a write-only libpng */

#ifndef PNG_NO_READ_SUPPORTED
#  define PNG_READ_SUPPORTED
#endif

/* Enable if you want a read-only libpng */

#ifndef PNG_NO_WRITE_SUPPORTED
#  define PNG_WRITE_SUPPORTED
#endif

/* Enabled in 1.2.41. */
#ifdef PNG_ALLOW_BENIGN_ERRORS
#  define png_benign_error png_warning
#  define png_chunk_benign_error png_chunk_warning
#else
#  ifndef PNG_BENIGN_ERRORS_SUPPORTED
#    define png_benign_error png_error
#    define png_chunk_benign_error png_chunk_error
#  endif
#endif

/* Added in libpng-1.2.41 */
#if !defined(PNG_NO_WARNINGS) && !defined(PNG_WARNINGS_SUPPORTED)
#  define PNG_WARNINGS_SUPPORTED
#endif

#if !defined(PNG_NO_ERROR_TEXT) && !defined(PNG_ERROR_TEXT_SUPPORTED)
#  define PNG_ERROR_TEXT_SUPPORTED
#endif

#if !defined(PNG_NO_CHECK_cHRM) && !defined(PNG_CHECK_cHRM_SUPPORTED)
#  define PNG_CHECK_cHRM_SUPPORTED
#endif

/* Enabled by default in 1.2.0.  You can disable this if you don't need to
 * support PNGs that are embedded in MNG datastreams
 */
#if !defined(PNG_1_0_X) && !defined(PNG_NO_MNG_FEATURES)
#  ifndef PNG_MNG_FEATURES_SUPPORTED
#    define PNG_MNG_FEATURES_SUPPORTED
#  endif
#endif

#ifndef PNG_NO_FLOATING_POINT_SUPPORTED
#  ifndef PNG_FLOATING_POINT_SUPPORTED
#    define PNG_FLOATING_POINT_SUPPORTED
#  endif
#endif

/* If you are running on a machine where you cannot allocate more
 * than 64K of memory at once, uncomment this.  While libpng will not
 * normally need that much memory in a chunk (unless you load up a very
 * large file), zlib needs to know how big of a chunk it can use, and
 * libpng thus makes sure to check any memory allocation to verify it
 * will fit into memory.
#define PNG_MAX_MALLOC_64K
 */
#if defined(MAXSEG_64K) && !defined(PNG_MAX_MALLOC_64K)
#  define PNG_MAX_MALLOC_64K
#endif

/* Special munging to support doing things the 'cygwin' way:
 * 'Normal' png-on-win32 defines/defaults:
 *   PNG_BUILD_DLL -- building dll
 *   PNG_USE_DLL   -- building an application, linking to dll
 *   (no define)   -- building static library, or building an
 *                    application and linking to the static lib
 * 'Cygwin' defines/defaults:
 *   PNG_BUILD_DLL -- (ignored) building the dll
 *   (no define)   -- (ignored) building an application, linking to the dll
 *   PNG_STATIC    -- (ignored) building the static lib, or building an
 *                    application that links to the static lib.
 *   ALL_STATIC    -- (ignored) building various static libs, or building an
 *                    application that links to the static libs.
 * Thus,
 * a cygwin user should define either PNG_BUILD_DLL or PNG_STATIC, and
 * this bit of #ifdefs will define the 'correct' config variables based on
 * that. If a cygwin user *wants* to define 'PNG_USE_DLL' that's okay, but
 * unnecessary.
 *
 * Also, the precedence order is:
 *   ALL_STATIC (since we can't #undef something outside our namespace)
 *   PNG_BUILD_DLL
 *   PNG_STATIC
 *   (nothing) == PNG_USE_DLL
 *
 * CYGWIN (2002-01-20): The preceding is now obsolete. With the advent
 *   of auto-import in binutils, we no longer need to worry about
 *   __declspec(dllexport) / __declspec(dllimport) and friends.  Therefore,
 *   we don't need to worry about PNG_STATIC or ALL_STATIC when it comes
 *   to __declspec() stuff.  However, we DO need to worry about
 *   PNG_BUILD_DLL and PNG_STATIC because those change some defaults
 *   such as CONSOLE_IO and whether GLOBAL_ARRAYS are allowed.
 */
#ifdef __CYGWIN__
#  ifdef ALL_STATIC
#    ifdef PNG_BUILD_DLL
#      undef PNG_BUILD_DLL
#    endif
#    ifdef PNG_USE_DLL
#      undef PNG_USE_DLL
#    endif
#    ifdef PNG_DLL
#      undef PNG_DLL
#    endif
#    ifndef PNG_STATIC
#      define PNG_STATIC
#    endif
#  else
#    ifdef PNG_BUILD_DLL
#      ifdef PNG_STATIC
#        undef PNG_STATIC
#      endif
#      ifdef PNG_USE_DLL
#        undef PNG_USE_DLL
#      endif
#      ifndef PNG_DLL
#        define PNG_DLL
#      endif
#    else
#      ifdef PNG_STATIC
#        ifdef PNG_USE_DLL
#          undef PNG_USE_DLL
#        endif
#        ifdef PNG_DLL
#          undef PNG_DLL
#        endif
#      else
#        ifndef PNG_USE_DLL
#          define PNG_USE_DLL
#        endif
#        ifndef PNG_DLL
#          define PNG_DLL
#        endif
#      endif
#    endif
#  endif
#endif

/* This protects us against compilers that run on a windowing system
 * and thus don't have or would rather us not use the stdio types:
 * stdin, stdout, and stderr.  The only one currently used is stderr
 * in png_error() and png_warning().  #defining PNG_NO_CONSOLE_IO will
 * prevent these from being compiled and used. #defining PNG_NO_STDIO
 * will also prevent these, plus will prevent the entire set of stdio
 * macros and functions (FILE *, printf, etc.) from being compiled and used,
 * unless (PNG_DEBUG > 0) has been #defined.
 *
 * #define PNG_NO_CONSOLE_IO
 * #define PNG_NO_STDIO
 */

#if !defined(PNG_NO_STDIO) && !defined(PNG_STDIO_SUPPORTED)
#  define PNG_STDIO_SUPPORTED
#endif

#ifdef _WIN32_WCE
#  include <windows.h>
   /* Console I/O functions are not supported on WindowsCE */
#  define PNG_NO_CONSOLE_IO
   /* abort() may not be supported on some/all Windows CE platforms */
#  define PNG_ABORT() exit(-1)
#  ifdef PNG_DEBUG
#    undef PNG_DEBUG
#  endif
#endif

#ifdef PNG_BUILD_DLL
#  ifndef PNG_CONSOLE_IO_SUPPORTED
#    ifndef PNG_NO_CONSOLE_IO
#      define PNG_NO_CONSOLE_IO
#    endif
#  endif
#endif

#  ifdef PNG_NO_STDIO
#    ifndef PNG_NO_CONSOLE_IO
#      define PNG_NO_CONSOLE_IO
#    endif
#    ifdef PNG_DEBUG
#      if (PNG_DEBUG > 0)
#        include <stdio.h>
#      endif
#    endif
#  else
#    ifndef _WIN32_WCE
/* "stdio.h" functions are not supported on WindowsCE */
#      include <stdio.h>
#    endif
#  endif

#if !(defined PNG_NO_CONSOLE_IO) && !defined(PNG_CONSOLE_IO_SUPPORTED)
#  define PNG_CONSOLE_IO_SUPPORTED
#endif

/* This macro protects us against machines that don't have function
 * prototypes (ie K&R style headers).  If your compiler does not handle
 * function prototypes, define this macro and use the included ansi2knr.
 * I've always been able to use _NO_PROTO as the indicator, but you may
 * need to drag the empty declaration out in front of here, or change the
 * ifdef to suit your own needs.
 */
#ifndef PNGARG

#ifdef OF /* zlib prototype munger */
#  define PNGARG(arglist) OF(arglist)
#else

#ifdef _NO_PROTO
#  define PNGARG(arglist) ()
#  ifndef PNG_TYPECAST_NULL
#     define PNG_TYPECAST_NULL
#  endif
#else
#  define PNGARG(arglist) arglist
#endif /* _NO_PROTO */


#endif /* OF */

#endif /* PNGARG */

/* Try to determine if we are compiling on a Mac.  Note that testing for
 * just __MWERKS__ is not good enough, because the Codewarrior is now used
 * on non-Mac platforms.
 */
#ifndef MACOS
#  if (defined(__MWERKS__) && defined(macintosh)) || defined(applec) || \
      defined(THINK_C) || defined(__SC__) || defined(TARGET_OS_MAC)
#    define MACOS
#  endif
#endif

/* enough people need this for various reasons to include it here */
#if !defined(MACOS) && !defined(RISCOS) && !defined(_WIN32_WCE)
#  include <sys/types.h>
#endif

#if !defined(PNG_SETJMP_NOT_SUPPORTED) && !defined(PNG_NO_SETJMP_SUPPORTED)
#  define PNG_SETJMP_SUPPORTED
#endif

#ifdef PNG_SETJMP_SUPPORTED
/* This is an attempt to force a single setjmp behaviour on Linux.  If
 * the X config stuff didn't define _BSD_SOURCE we wouldn't need this.
 *
 * You can bypass this test if you know that your application uses exactly
 * the same setjmp.h that was included when libpng was built.  Only define
 * PNG_SKIP_SETJMP_CHECK while building your application, prior to the
 * application's '#include "png.h"'. Don't define PNG_SKIP_SETJMP_CHECK
 * while building a separate libpng library for general use.
 */

#  ifndef PNG_SKIP_SETJMP_CHECK
#    ifdef __linux__
#      ifdef _BSD_SOURCE
#        define PNG_SAVE_BSD_SOURCE
#        undef _BSD_SOURCE
#      endif
#      ifdef _SETJMP_H
       /* If you encounter a compiler error here, see the explanation
        * near the end of INSTALL.
        */
           __pngconf.h__ in libpng already includes setjmp.h;
           __dont__ include it again.;
#      endif
#    endif /* __linux__ */
#  endif /* PNG_SKIP_SETJMP_CHECK */

   /* include setjmp.h for error handling */
#  include <setjmp.h>

#  ifdef __linux__
#    ifdef PNG_SAVE_BSD_SOURCE
#      ifndef _BSD_SOURCE
#        define _BSD_SOURCE
#      endif
#      undef PNG_SAVE_BSD_SOURCE
#    endif
#  endif /* __linux__ */
#endif /* PNG_SETJMP_SUPPORTED */

#ifdef BSD
#  include <strings.h>
#else
#  include <string.h>
#endif

/* Other defines for things like memory and the like can go here.  */
#ifdef PNG_INTERNAL

#include <stdlib.h>

/* The functions exported by PNG_EXTERN are PNG_INTERNAL functions, which
 * aren't usually used outside the library (as far as I know), so it is
 * debatable if they should be exported at all.  In the future, when it is
 * possible to have run-time registry of chunk-handling functions, some of
 * these will be made available again.
#define PNG_EXTERN extern
 */
#define PNG_EXTERN

/* Other defines specific to compilers can go here.  Try to keep
 * them inside an appropriate ifdef/endif pair for portability.
 */

#ifdef PNG_FLOATING_POINT_SUPPORTED
#  ifdef MACOS
     /* We need to check that <math.h> hasn't already been included earlier
      * as it seems it doesn't agree with <fp.h>, yet we should really use
      * <fp.h> if possible.
      */
#    if !defined(__MATH_H__) && !defined(__MATH_H) && !defined(__cmath__)
#      include <fp.h>
#    endif
#  else
#    include <math.h>
#  endif
#  if defined(_AMIGA) && defined(__SASC) && defined(_M68881)
     /* Amiga SAS/C: We must include builtin FPU functions when compiling using
      * MATH=68881
      */
#    include <m68881.h>
#  endif
#endif

/* Codewarrior on NT has linking problems without this. */
#if (defined(__MWERKS__) && defined(WIN32)) || defined(__STDC__)
#  define PNG_ALWAYS_EXTERN
#endif

/* This provides the non-ANSI (far) memory allocation routines. */
#if defined(__TURBOC__) && defined(__MSDOS__)
#  include <mem.h>
#  include <alloc.h>
#endif

/* I have no idea why is this necessary... */
#if defined(_MSC_VER) && (defined(WIN32) || defined(_Windows) || \
    defined(_WINDOWS) || defined(_WIN32) || defined(__WIN32__))
#  include <malloc.h>
#endif

/* This controls how fine the dithering gets.  As this allocates
 * a largish chunk of memory (32K), those who are not as concerned
 * with dithering quality can decrease some or all of these.
 */
#ifndef PNG_DITHER_RED_BITS
#  define PNG_DITHER_RED_BITS 5
#endif
#ifndef PNG_DITHER_GREEN_BITS
#  define PNG_DITHER_GREEN_BITS 5
#endif
#ifndef PNG_DITHER_BLUE_BITS
#  define PNG_DITHER_BLUE_BITS 5
#endif

/* This controls how fine the gamma correction becomes when you
 * are only interested in 8 bits anyway.  Increasing this value
 * results in more memory being used, and more pow() functions
 * being called to fill in the gamma tables.  Don't set this value
 * less then 8, and even that may not work (I haven't tested it).
 */

#ifndef PNG_MAX_GAMMA_8
#  define PNG_MAX_GAMMA_8 11
#endif

/* This controls how much a difference in gamma we can tolerate before
 * we actually start doing gamma conversion.
 */
#ifndef PNG_GAMMA_THRESHOLD
#  define PNG_GAMMA_THRESHOLD 0.05
#endif

#endif /* PNG_INTERNAL */

/* The following uses const char * instead of char * for error
 * and warning message functions, so some compilers won't complain.
 * If you do not want to use const, define PNG_NO_CONST here.
 */

#ifndef PNG_NO_CONST
#  define PNG_CONST const
#else
#  define PNG_CONST
#endif

/* The following defines give you the ability to remove code from the
 * library that you will not be using.  I wish I could figure out how to
 * automate this, but I can't do that without making it seriously hard
 * on the users.  So if you are not using an ability, change the #define
 * to and #undef, and that part of the library will not be compiled.  If
 * your linker can't find a function, you may want to make sure the
 * ability is defined here.  Some of these depend upon some others being
 * defined.  I haven't figured out all the interactions here, so you may
 * have to experiment awhile to get everything to compile.  If you are
 * creating or using a shared library, you probably shouldn't touch this,
 * as it will affect the size of the structures, and this will cause bad
 * things to happen if the library and/or application ever change.
 */

/* Any features you will not be using can be undef'ed here */

/* GR-P, 0.96a: Set "*TRANSFORMS_SUPPORTED as default but allow user
 * to turn it off with "*TRANSFORMS_NOT_SUPPORTED" or *PNG_NO_*_TRANSFORMS
 * on the compile line, then pick and choose which ones to define without
 * having to edit this file. It is safe to use the *TRANSFORMS_NOT_SUPPORTED
 * if you only want to have a png-compliant reader/writer but don't need
 * any of the extra transformations.  This saves about 80 kbytes in a
 * typical installation of the library. (PNG_NO_* form added in version
 * 1.0.1c, for consistency)
 */

/* The size of the png_text structure changed in libpng-1.0.6 when
 * iTXt support was added.  iTXt support was turned off by default through
 * libpng-1.2.x, to support old apps that malloc the png_text structure
 * instead of calling png_set_text() and letting libpng malloc it.  It
 * will be turned on by default in libpng-1.4.0.
 */

#if defined(PNG_1_0_X) || defined (PNG_1_2_X)
#  ifndef PNG_NO_iTXt_SUPPORTED
#    define PNG_NO_iTXt_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_iTXt
#    define PNG_NO_READ_iTXt
#  endif
#  ifndef PNG_NO_WRITE_iTXt
#    define PNG_NO_WRITE_iTXt
#  endif
#endif

#if !defined(PNG_NO_iTXt_SUPPORTED)
#  if !defined(PNG_READ_iTXt_SUPPORTED) && !defined(PNG_NO_READ_iTXt)
#    define PNG_READ_iTXt
#  endif
#  if !defined(PNG_WRITE_iTXt_SUPPORTED) && !defined(PNG_NO_WRITE_iTXt)
#    define PNG_WRITE_iTXt
#  endif
#endif

/* The following support, added after version 1.0.0, can be turned off here en
 * masse by defining PNG_LEGACY_SUPPORTED in case you need binary compatibility
 * with old applications that require the length of png_struct and png_info
 * to remain unchanged.
 */

#ifdef PNG_LEGACY_SUPPORTED
#  define PNG_NO_FREE_ME
#  define PNG_NO_READ_UNKNOWN_CHUNKS
#  define PNG_NO_WRITE_UNKNOWN_CHUNKS
#  define PNG_NO_HANDLE_AS_UNKNOWN
#  define PNG_NO_READ_USER_CHUNKS
#  define PNG_NO_READ_iCCP
#  define PNG_NO_WRITE_iCCP
#  define PNG_NO_READ_iTXt
#  define PNG_NO_WRITE_iTXt
#  define PNG_NO_READ_sCAL
#  define PNG_NO_WRITE_sCAL
#  define PNG_NO_READ_sPLT
#  define PNG_NO_WRITE_sPLT
#  define PNG_NO_INFO_IMAGE
#  define PNG_NO_READ_RGB_TO_GRAY
#  define PNG_NO_READ_USER_TRANSFORM
#  define PNG_NO_WRITE_USER_TRANSFORM
#  define PNG_NO_USER_MEM
#  define PNG_NO_READ_EMPTY_PLTE
#  define PNG_NO_MNG_FEATURES
#  define PNG_NO_FIXED_POINT_SUPPORTED
#endif

/* Ignore attempt to turn off both floating and fixed point support */
#if !defined(PNG_FLOATING_POINT_SUPPORTED) || \
    !defined(PNG_NO_FIXED_POINT_SUPPORTED)
#  define PNG_FIXED_POINT_SUPPORTED
#endif

#ifndef PNG_NO_FREE_ME
#  define PNG_FREE_ME_SUPPORTED
#endif

#ifdef PNG_READ_SUPPORTED

#if !defined(PNG_READ_TRANSFORMS_NOT_SUPPORTED) && \
      !defined(PNG_NO_READ_TRANSFORMS)
#  define PNG_READ_TRANSFORMS_SUPPORTED
#endif

#ifdef PNG_READ_TRANSFORMS_SUPPORTED
#  ifndef PNG_NO_READ_EXPAND
#    define PNG_READ_EXPAND_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_SHIFT
#    define PNG_READ_SHIFT_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_PACK
#    define PNG_READ_PACK_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_BGR
#    define PNG_READ_BGR_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_SWAP
#    define PNG_READ_SWAP_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_PACKSWAP
#    define PNG_READ_PACKSWAP_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_INVERT
#    define PNG_READ_INVERT_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_DITHER
#    define PNG_READ_DITHER_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_BACKGROUND
#    define PNG_READ_BACKGROUND_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_16_TO_8
#    define PNG_READ_16_TO_8_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_FILLER
#    define PNG_READ_FILLER_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_GAMMA
#    define PNG_READ_GAMMA_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_GRAY_TO_RGB
#    define PNG_READ_GRAY_TO_RGB_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_SWAP_ALPHA
#    define PNG_READ_SWAP_ALPHA_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_INVERT_ALPHA
#    define PNG_READ_INVERT_ALPHA_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_STRIP_ALPHA
#    define PNG_READ_STRIP_ALPHA_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_USER_TRANSFORM
#    define PNG_READ_USER_TRANSFORM_SUPPORTED
#  endif
#  ifndef PNG_NO_READ_RGB_TO_GRAY
#    define PNG_READ_RGB_TO_GRAY_SUPPORTED
#  endif
#endif /* PNG_READ_TRANSFORMS_SUPPORTED */

/* PNG_PROGRESSIVE_READ_NOT_SUPPORTED is deprecated. */
#if !defined(PNG_NO_PROGRESSIVE_READ) && \
 !defined(PNG_PROGRESSIVE_READ_NOT_SUPPORTED)  /* if you don't do progressive */
#  define PNG_PROGRESSIVE_READ_SUPPORTED     /* reading.  This is not talking */
#endif                               /* about interlacing capability!  You'll */
            /* still have interlacing unless you change the following define: */
#define PNG_READ_INTERLACING_SUPPORTED /* required for PNG-compliant decoders */

/* PNG_NO_SEQUENTIAL_READ_SUPPORTED is deprecated. */
#if !defined(PNG_NO_SEQUENTIAL_READ) && \
    !defined(PNG_SEQUENTIAL_READ_SUPPORTED) && \
    !defined(PNG_NO_SEQUENTIAL_READ_SUPPORTED)
#  define PNG_SEQUENTIAL_READ_SUPPORTED
#endif

#define PNG_READ_INTERLACING_SUPPORTED /* required in PNG-compliant decoders */

#ifndef PNG_NO_READ_COMPOSITE_NODIV
#  ifndef PNG_NO_READ_COMPOSITED_NODIV  /* libpng-1.0.x misspelling */
#    define PNG_READ_COMPOSITE_NODIV_SUPPORTED  /* well tested on Intel, SGI */
#  endif
#endif

#if defined(PNG_1_0_X) || defined (PNG_1_2_X)
/* Deprecated, will be removed from version 2.0.0.
   Use PNG_MNG_FEATURES_SUPPORTED instead. */
#ifndef PNG_NO_READ_EMPTY_PLTE
#  define PNG_READ_EMPTY_PLTE_SUPPORTED
#endif
#endif

#endif /* PNG_READ_SUPPORTED */

#ifdef PNG_WRITE_SUPPORTED

# if !defined(PNG_WRITE_TRANSFORMS_NOT_SUPPORTED) && \
    !defined(PNG_NO_WRITE_TRANSFORMS)
#  define PNG_WRITE_TRANSFORMS_SUPPORTED
#endif

#ifdef PNG_WRITE_TRANSFORMS_SUPPORTED
#  ifndef PNG_NO_WRITE_SHIFT
#    define PNG_WRITE_SHIFT_SUPPORTED
#  endif
#  ifndef PNG_NO_WRITE_PACK
#    define PNG_WRITE_PACK_SUPPORTED
#  endif
#  ifndef PNG_NO_WRITE_BGR
#    define PNG_WRITE_BGR_SUPPORTED
#  endif
#  ifndef PNG_NO_WRITE_SWAP
#    define PNG_WRITE_SWAP_SUPPORTED
#  endif
#  ifndef PNG_NO_WRITE_PACKSWAP
#    define PNG_WRITE_PACKSWAP_SUPPORTED
#  endif
#  ifndef PNG_NO_WRITE_INVERT
#    define PNG_WRITE_INVERT_SUPPORTED
#  endif
#  ifndef PNG_NO_WRITE_FILLER
#    define PNG_WRITE_FILLER_SUPPORTED   /* same as WRITE_STRIP_ALPHA */
#  endif
#  ifndef PNG_NO_WRITE_SWAP_ALPHA
#    define PNG_WRITE_SWAP_ALPHA_SUPPORTED
#  endif
#ifndef PNG_1_0_X
#  ifndef PNG_NO_WRITE_INVERT_ALPHA
#    define PNG_WRITE_INVERT_ALPHA_SUPPORTED
#  endif
#endif
#  ifndef PNG_NO_WRITE_USER_TRANSFORM
#    define PNG_WRITE_USER_TRANSFORM_SUPPORTED
#  endif
#endif /* PNG_WRITE_TRANSFORMS_SUPPORTED */

#if !defined(PNG_NO_WRITE_INTERLACING_SUPPORTED) && \
    !defined(PNG_WRITE_INTERLACING_SUPPORTED)
#define PNG_WRITE_INTERLACING_SUPPORTED  /* not required for PNG-compliant
                                            encoders, but can cause trouble
                                            if left undefined */
#endif

#if !defined(PNG_NO_WRITE_WEIGHTED_FILTER) && \
    !defined(PNG_WRITE_WEIGHTED_FILTER) && \
     defined(PNG_FLOATING_POINT_SUPPORTED)
#  define PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
#endif

#ifndef PNG_NO_WRITE_FLUSH
#  define PNG_WRITE_FLUSH_SUPPORTED
#endif

#if defined(PNG_1_0_X) || defined (PNG_1_2_X)
/* Deprecated, see PNG_MNG_FEATURES_SUPPORTED, above */
#ifndef PNG_NO_WRITE_EMPTY_PLTE
#  define PNG_WRITE_EMPTY_PLTE_SUPPORTED
#endif
#endif

#endif /* PNG_WRITE_SUPPORTED */

#ifndef PNG_1_0_X
#  ifndef PNG_NO_ERROR_NUMBERS
#    define PNG_ERROR_NUMBERS_SUPPORTED
#  endif
#endif /* PNG_1_0_X */

#if defined(PNG_READ_USER_TRANSFORM_SUPPORTED) || \
    defined(PNG_WRITE_USER_TRANSFORM_SUPPORTED)
#  ifndef PNG_NO_USER_TRANSFORM_PTR
#    define PNG_USER_TRANSFORM_PTR_SUPPORTED
#  endif
#endif

#ifndef PNG_NO_STDIO
#  define PNG_TIME_RFC1123_SUPPORTED
#endif

/* This adds extra functions in pngget.c for accessing data from the
 * info pointer (added in version 0.99)
 * png_get_image_width()
 * png_get_image_height()
 * png_get_bit_depth()
 * png_get_color_type()
 * png_get_compression_type()
 * png_get_filter_type()
 * png_get_interlace_type()
 * png_get_pixel_aspect_ratio()
 * png_get_pixels_per_meter()
 * png_get_x_offset_pixels()
 * png_get_y_offset_pixels()
 * png_get_x_offset_microns()
 * png_get_y_offset_microns()
 */
#if !defined(PNG_NO_EASY_ACCESS) && !defined(PNG_EASY_ACCESS_SUPPORTED)
#  define PNG_EASY_ACCESS_SUPPORTED
#endif

/* PNG_ASSEMBLER_CODE was enabled by default in version 1.2.0
 * and removed from version 1.2.20.  The following will be removed
 * from libpng-1.4.0
*/

#if defined(PNG_READ_SUPPORTED) && !defined(PNG_NO_OPTIMIZED_CODE)
#  ifndef PNG_OPTIMIZED_CODE_SUPPORTED
#    define PNG_OPTIMIZED_CODE_SUPPORTED
#  endif
#endif

#if defined(PNG_READ_SUPPORTED) && !defined(PNG_NO_ASSEMBLER_CODE)
#  ifndef PNG_ASSEMBLER_CODE_SUPPORTED
#    define PNG_ASSEMBLER_CODE_SUPPORTED
#  endif

#  if defined(__GNUC__) && defined(__x86_64__) && (__GNUC__ < 4)
     /* work around 64-bit gcc compiler bugs in gcc-3.x */
#    if !defined(PNG_MMX_CODE_SUPPORTED) && !defined(PNG_NO_MMX_CODE)
#      define PNG_NO_MMX_CODE
#    endif
#  endif

#  ifdef __APPLE__
#    if !defined(PNG_MMX_CODE_SUPPORTED) && !defined(PNG_NO_MMX_CODE)
#      define PNG_NO_MMX_CODE
#    endif
#  endif

#  if (defined(__MWERKS__) && ((__MWERKS__ < 0x0900) || macintosh))
#    if !defined(PNG_MMX_CODE_SUPPORTED) && !defined(PNG_NO_MMX_CODE)
#      define PNG_NO_MMX_CODE
#    endif
#  endif

#  if !defined(PNG_MMX_CODE_SUPPORTED) && !defined(PNG_NO_MMX_CODE)
#    define PNG_MMX_CODE_SUPPORTED
#  endif

#endif
/* end of obsolete code to be removed from libpng-1.4.0 */

/* Added at libpng-1.2.0 */
#ifndef PNG_1_0_X
#if !defined(PNG_NO_USER_MEM) && !defined(PNG_USER_MEM_SUPPORTED)
#  define PNG_USER_MEM_SUPPORTED
#endif
#endif /* PNG_1_0_X */

/* Added at libpng-1.2.6 */
#ifndef PNG_1_0_X
#  ifndef PNG_SET_USER_LIMITS_SUPPORTED
#    ifndef PNG_NO_SET_USER_LIMITS
#      define PNG_SET_USER_LIMITS_SUPPORTED
#    endif
#  endif
#endif /* PNG_1_0_X */

/* Added at libpng-1.0.53 and 1.2.43 */
#ifndef PNG_USER_LIMITS_SUPPORTED
#  ifndef PNG_NO_USER_LIMITS
#    define PNG_USER_LIMITS_SUPPORTED
#  endif
#endif

/* Added at libpng-1.0.16 and 1.2.6.  To accept all valid PNGS no matter
 * how large, set these limits to 0x7fffffffL
 */
#ifndef PNG_USER_WIDTH_MAX
#  define PNG_USER_WIDTH_MAX 1000000L
#endif
#ifndef PNG_USER_HEIGHT_MAX
#  define PNG_USER_HEIGHT_MAX 1000000L
#endif

/* Added at libpng-1.2.43.  To accept all valid PNGs no matter
 * how large, set these two limits to 0.
 */
#ifndef PNG_USER_CHUNK_CACHE_MAX
#  define PNG_USER_CHUNK_CACHE_MAX 0
#endif

/* Added at libpng-1.2.43 */
#ifndef PNG_USER_CHUNK_MALLOC_MAX
#  define PNG_USER_CHUNK_MALLOC_MAX 0
#endif

#ifndef PNG_LITERAL_SHARP
#  define PNG_LITERAL_SHARP 0x23
#endif
#ifndef PNG_LITERAL_LEFT_SQUARE_BRACKET
#  define PNG_LITERAL_LEFT_SQUARE_BRACKET 0x5b
#endif
#ifndef PNG_LITERAL_RIGHT_SQUARE_BRACKET
#  define PNG_LITERAL_RIGHT_SQUARE_BRACKET 0x5d
#endif

/* Added at libpng-1.2.34 */
#ifndef PNG_STRING_NEWLINE
#define PNG_STRING_NEWLINE "\n"
#endif

/* These are currently experimental features, define them if you want */

/* very little testing */
/*
#ifdef PNG_READ_SUPPORTED
#  ifndef PNG_READ_16_TO_8_ACCURATE_SCALE_SUPPORTED
#    define PNG_READ_16_TO_8_ACCURATE_SCALE_SUPPORTED
#  endif
#endif
*/

/* This is only for PowerPC big-endian and 680x0 systems */
/* some testing */
/*
#ifndef PNG_READ_BIG_ENDIAN_SUPPORTED
#  define PNG_READ_BIG_ENDIAN_SUPPORTED
#endif
*/

/* Buggy compilers (e.g., gcc 2.7.2.2) need this */
/*
#define PNG_NO_POINTER_INDEXING
*/

#if !defined(PNG_NO_POINTER_INDEXING) && \
    !defined(PNG_POINTER_INDEXING_SUPPORTED)
#  define PNG_POINTER_INDEXING_SUPPORTED
#endif

/* These functions are turned off by default, as they will be phased out. */
/*
#define  PNG_USELESS_TESTS_SUPPORTED
#define  PNG_CORRECT_PALETTE_SUPPORTED
*/

/* Any chunks you are not interested in, you can undef here.  The
 * ones that allocate memory may be expecially important (hIST,
 * tEXt, zTXt, tRNS, pCAL).  Others will just save time and make png_info
 * a bit smaller.
 */

#if defined(PNG_READ_SUPPORTED) && \
    !defined(PNG_READ_ANCILLARY_CHUNKS_NOT_SUPPORTED) && \
    !defined(PNG_NO_READ_ANCILLARY_CHUNKS)
#  define PNG_READ_ANCILLARY_CHUNKS_SUPPORTED
#endif

#if defined(PNG_WRITE_SUPPORTED) && \
    !defined(PNG_WRITE_ANCILLARY_CHUNKS_NOT_SUPPORTED) && \
    !defined(PNG_NO_WRITE_ANCILLARY_CHUNKS)
#  define PNG_WRITE_ANCILLARY_CHUNKS_SUPPORTED
#endif

#ifdef PNG_READ_ANCILLARY_CHUNKS_SUPPORTED

#ifdef PNG_NO_READ_TEXT
#  define PNG_NO_READ_iTXt
#  define PNG_NO_READ_tEXt
#  define PNG_NO_READ_zTXt
#endif
#ifndef PNG_NO_READ_bKGD
#  define PNG_READ_bKGD_SUPPORTED
#  define PNG_bKGD_SUPPORTED
#endif
#ifndef PNG_NO_READ_cHRM
#  define PNG_READ_cHRM_SUPPORTED
#  define PNG_cHRM_SUPPORTED
#endif
#ifndef PNG_NO_READ_gAMA
#  define PNG_READ_gAMA_SUPPORTED
#  define PNG_gAMA_SUPPORTED
#endif
#ifndef PNG_NO_READ_hIST
#  define PNG_READ_hIST_SUPPORTED
#  define PNG_hIST_SUPPORTED
#endif
#ifndef PNG_NO_READ_iCCP
#  define PNG_READ_iCCP_SUPPORTED
#  define PNG_iCCP_SUPPORTED
#endif
#ifndef PNG_NO_READ_iTXt
#  ifndef PNG_READ_iTXt_SUPPORTED
#    define PNG_READ_iTXt_SUPPORTED
#  endif
#  ifndef PNG_iTXt_SUPPORTED
#    define PNG_iTXt_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_READ_oFFs
#  define PNG_READ_oFFs_SUPPORTED
#  define PNG_oFFs_SUPPORTED
#endif
#ifndef PNG_NO_READ_pCAL
#  define PNG_READ_pCAL_SUPPORTED
#  define PNG_pCAL_SUPPORTED
#endif
#ifndef PNG_NO_READ_sCAL
#  define PNG_READ_sCAL_SUPPORTED
#  define PNG_sCAL_SUPPORTED
#endif
#ifndef PNG_NO_READ_pHYs
#  define PNG_READ_pHYs_SUPPORTED
#  define PNG_pHYs_SUPPORTED
#endif
#ifndef PNG_NO_READ_sBIT
#  define PNG_READ_sBIT_SUPPORTED
#  define PNG_sBIT_SUPPORTED
#endif
#ifndef PNG_NO_READ_sPLT
#  define PNG_READ_sPLT_SUPPORTED
#  define PNG_sPLT_SUPPORTED
#endif
#ifndef PNG_NO_READ_sRGB
#  define PNG_READ_sRGB_SUPPORTED
#  define PNG_sRGB_SUPPORTED
#endif
#ifndef PNG_NO_READ_tEXt
#  define PNG_READ_tEXt_SUPPORTED
#  define PNG_tEXt_SUPPORTED
#endif
#ifndef PNG_NO_READ_tIME
#  define PNG_READ_tIME_SUPPORTED
#  define PNG_tIME_SUPPORTED
#endif
#ifndef PNG_NO_READ_tRNS
#  define PNG_READ_tRNS_SUPPORTED
#  define PNG_tRNS_SUPPORTED
#endif
#ifndef PNG_NO_READ_zTXt
#  define PNG_READ_zTXt_SUPPORTED
#  define PNG_zTXt_SUPPORTED
#endif
#ifndef PNG_NO_READ_OPT_PLTE
#  define PNG_READ_OPT_PLTE_SUPPORTED /* only affects support of the */
#endif                      /* optional PLTE chunk in RGB and RGBA images */
#if defined(PNG_READ_iTXt_SUPPORTED) || defined(PNG_READ_tEXt_SUPPORTED) || \
    defined(PNG_READ_zTXt_SUPPORTED)
#  define PNG_READ_TEXT_SUPPORTED
#  define PNG_TEXT_SUPPORTED
#endif

#endif /* PNG_READ_ANCILLARY_CHUNKS_SUPPORTED */

#ifndef PNG_NO_READ_UNKNOWN_CHUNKS
#  define PNG_READ_UNKNOWN_CHUNKS_SUPPORTED
#  ifndef PNG_UNKNOWN_CHUNKS_SUPPORTED
#    define PNG_UNKNOWN_CHUNKS_SUPPORTED
#  endif
#endif
#if !defined(PNG_NO_READ_USER_CHUNKS) && \
     defined(PNG_READ_UNKNOWN_CHUNKS_SUPPORTED)
#  define PNG_READ_USER_CHUNKS_SUPPORTED
#  define PNG_USER_CHUNKS_SUPPORTED
#  ifdef PNG_NO_READ_UNKNOWN_CHUNKS
#    undef PNG_NO_READ_UNKNOWN_CHUNKS
#  endif
#  ifdef PNG_NO_HANDLE_AS_UNKNOWN
#    undef PNG_NO_HANDLE_AS_UNKNOWN
#  endif
#endif

#ifndef PNG_NO_HANDLE_AS_UNKNOWN
#  ifndef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
#    define PNG_HANDLE_AS_UNKNOWN_SUPPORTED
#  endif
#endif

#ifdef PNG_WRITE_SUPPORTED
#ifdef PNG_WRITE_ANCILLARY_CHUNKS_SUPPORTED

#ifdef PNG_NO_WRITE_TEXT
#  define PNG_NO_WRITE_iTXt
#  define PNG_NO_WRITE_tEXt
#  define PNG_NO_WRITE_zTXt
#endif
#ifndef PNG_NO_WRITE_bKGD
#  define PNG_WRITE_bKGD_SUPPORTED
#  ifndef PNG_bKGD_SUPPORTED
#    define PNG_bKGD_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_cHRM
#  define PNG_WRITE_cHRM_SUPPORTED
#  ifndef PNG_cHRM_SUPPORTED
#    define PNG_cHRM_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_gAMA
#  define PNG_WRITE_gAMA_SUPPORTED
#  ifndef PNG_gAMA_SUPPORTED
#    define PNG_gAMA_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_hIST
#  define PNG_WRITE_hIST_SUPPORTED
#  ifndef PNG_hIST_SUPPORTED
#    define PNG_hIST_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_iCCP
#  define PNG_WRITE_iCCP_SUPPORTED
#  ifndef PNG_iCCP_SUPPORTED
#    define PNG_iCCP_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_iTXt
#  ifndef PNG_WRITE_iTXt_SUPPORTED
#    define PNG_WRITE_iTXt_SUPPORTED
#  endif
#  ifndef PNG_iTXt_SUPPORTED
#    define PNG_iTXt_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_oFFs
#  define PNG_WRITE_oFFs_SUPPORTED
#  ifndef PNG_oFFs_SUPPORTED
#    define PNG_oFFs_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_pCAL
#  define PNG_WRITE_pCAL_SUPPORTED
#  ifndef PNG_pCAL_SUPPORTED
#    define PNG_pCAL_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_sCAL
#  define PNG_WRITE_sCAL_SUPPORTED
#  ifndef PNG_sCAL_SUPPORTED
#    define PNG_sCAL_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_pHYs
#  define PNG_WRITE_pHYs_SUPPORTED
#  ifndef PNG_pHYs_SUPPORTED
#    define PNG_pHYs_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_sBIT
#  define PNG_WRITE_sBIT_SUPPORTED
#  ifndef PNG_sBIT_SUPPORTED
#    define PNG_sBIT_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_sPLT
#  define PNG_WRITE_sPLT_SUPPORTED
#  ifndef PNG_sPLT_SUPPORTED
#    define PNG_sPLT_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_sRGB
#  define PNG_WRITE_sRGB_SUPPORTED
#  ifndef PNG_sRGB_SUPPORTED
#    define PNG_sRGB_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_tEXt
#  define PNG_WRITE_tEXt_SUPPORTED
#  ifndef PNG_tEXt_SUPPORTED
#    define PNG_tEXt_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_tIME
#  define PNG_WRITE_tIME_SUPPORTED
#  ifndef PNG_tIME_SUPPORTED
#    define PNG_tIME_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_tRNS
#  define PNG_WRITE_tRNS_SUPPORTED
#  ifndef PNG_tRNS_SUPPORTED
#    define PNG_tRNS_SUPPORTED
#  endif
#endif
#ifndef PNG_NO_WRITE_zTXt
#  define PNG_WRITE_zTXt_SUPPORTED
#  ifndef PNG_zTXt_SUPPORTED
#    define PNG_zTXt_SUPPORTED
#  endif
#endif
#if defined(PNG_WRITE_iTXt_SUPPORTED) || defined(PNG_WRITE_tEXt_SUPPORTED) || \
    defined(PNG_WRITE_zTXt_SUPPORTED)
#  define PNG_WRITE_TEXT_SUPPORTED
#  ifndef PNG_TEXT_SUPPORTED
#    define PNG_TEXT_SUPPORTED
#  endif
#endif

#ifdef PNG_WRITE_tIME_SUPPORTED
#  ifndef PNG_NO_CONVERT_tIME
#    ifndef _WIN32_WCE
/*   The "tm" structure is not supported on WindowsCE */
#      ifndef PNG_CONVERT_tIME_SUPPORTED
#        define PNG_CONVERT_tIME_SUPPORTED
#      endif
#   endif
#  endif
#endif

#endif /* PNG_WRITE_ANCILLARY_CHUNKS_SUPPORTED */

#if !defined(PNG_NO_WRITE_FILTER) && !defined(PNG_WRITE_FILTER_SUPPORTED)
#  define PNG_WRITE_FILTER_SUPPORTED
#endif

#ifndef PNG_NO_WRITE_UNKNOWN_CHUNKS
#  define PNG_WRITE_UNKNOWN_CHUNKS_SUPPORTED
#  ifndef PNG_UNKNOWN_CHUNKS_SUPPORTED
#    define PNG_UNKNOWN_CHUNKS_SUPPORTED
#  endif
#endif

#ifndef PNG_NO_HANDLE_AS_UNKNOWN
#  ifndef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
#    define PNG_HANDLE_AS_UNKNOWN_SUPPORTED
#  endif
#endif
#endif /* PNG_WRITE_SUPPORTED */

/* Turn this off to disable png_read_png() and
 * png_write_png() and leave the row_pointers member
 * out of the info structure.
 */
#ifndef PNG_NO_INFO_IMAGE
#  define PNG_INFO_IMAGE_SUPPORTED
#endif

/* Need the time information for converting tIME chunks */
#ifdef PNG_CONVERT_tIME_SUPPORTED
     /* "time.h" functions are not supported on WindowsCE */
#    include <time.h>
#endif

/* Some typedefs to get us started.  These should be safe on most of the
 * common platforms.  The typedefs should be at least as large as the
 * numbers suggest (a png_uint_32 must be at least 32 bits long), but they
 * don't have to be exactly that size.  Some compilers dislike passing
 * unsigned shorts as function parameters, so you may be better off using
 * unsigned int for png_uint_16.  Likewise, for 64-bit systems, you may
 * want to have unsigned int for png_uint_32 instead of unsigned long.
 */

typedef unsigned long png_uint_32;
typedef long png_int_32;
typedef unsigned short png_uint_16;
typedef short png_int_16;
typedef unsigned char png_byte;

/* This is usually size_t.  It is typedef'ed just in case you need it to
   change (I'm not sure if you will or not, so I thought I'd be safe) */
#ifdef PNG_SIZE_T
   typedef PNG_SIZE_T png_size_t;
#  define png_sizeof(x) png_convert_size(sizeof(x))
#else
   typedef size_t png_size_t;
#  define png_sizeof(x) sizeof(x)
#endif

/* The following is needed for medium model support.  It cannot be in the
 * PNG_INTERNAL section.  Needs modification for other compilers besides
 * MSC.  Model independent support declares all arrays and pointers to be
 * large using the far keyword.  The zlib version used must also support
 * model independent data.  As of version zlib 1.0.4, the necessary changes
 * have been made in zlib.  The USE_FAR_KEYWORD define triggers other
 * changes that are needed. (Tim Wegner)
 */

/* Separate compiler dependencies (problem here is that zlib.h always
   defines FAR. (SJT) */
#ifdef __BORLANDC__
#  if defined(__LARGE__) || defined(__HUGE__) || defined(__COMPACT__)
#    define LDATA 1
#  else
#    define LDATA 0
#  endif
   /* GRR:  why is Cygwin in here?  Cygwin is not Borland C... */
#  if !defined(__WIN32__) && !defined(__FLAT__) && !defined(__CYGWIN__)
#    define PNG_MAX_MALLOC_64K
#    if (LDATA != 1)
#      ifndef FAR
#        define FAR __far
#      endif
#      define USE_FAR_KEYWORD
#    endif   /* LDATA != 1 */
     /* Possibly useful for moving data out of default segment.
      * Uncomment it if you want. Could also define FARDATA as
      * const if your compiler supports it. (SJT)
#    define FARDATA FAR
      */
#  endif  /* __WIN32__, __FLAT__, __CYGWIN__ */
#endif   /* __BORLANDC__ */


/* Suggest testing for specific compiler first before testing for
 * FAR.  The Watcom compiler defines both __MEDIUM__ and M_I86MM,
 * making reliance oncertain keywords suspect. (SJT)
 */

/* MSC Medium model */
#ifdef FAR
#  ifdef M_I86MM
#    define USE_FAR_KEYWORD
#    define FARDATA FAR
#    include <dos.h>
#  endif
#endif

/* SJT: default case */
#ifndef FAR
#  define FAR
#endif

/* At this point FAR is always defined */
#ifndef FARDATA
#  define FARDATA
#endif

/* Typedef for floating-point numbers that are converted
   to fixed-point with a multiple of 100,000, e.g., int_gamma */
typedef png_int_32 png_fixed_point;

/* Add typedefs for pointers */
typedef void            FAR * png_voidp;
typedef png_byte        FAR * png_bytep;
typedef png_uint_32     FAR * png_uint_32p;
typedef png_int_32      FAR * png_int_32p;
typedef png_uint_16     FAR * png_uint_16p;
typedef png_int_16      FAR * png_int_16p;
typedef PNG_CONST char  FAR * png_const_charp;
typedef char            FAR * png_charp;
typedef png_fixed_point FAR * png_fixed_point_p;

#ifndef PNG_NO_STDIO
#ifdef _WIN32_WCE
typedef HANDLE                png_FILE_p;
#else
typedef FILE                * png_FILE_p;
#endif
#endif

#ifdef PNG_FLOATING_POINT_SUPPORTED
typedef double          FAR * png_doublep;
#endif

/* Pointers to pointers; i.e. arrays */
typedef png_byte        FAR * FAR * png_bytepp;
typedef png_uint_32     FAR * FAR * png_uint_32pp;
typedef png_int_32      FAR * FAR * png_int_32pp;
typedef png_uint_16     FAR * FAR * png_uint_16pp;
typedef png_int_16      FAR * FAR * png_int_16pp;
typedef PNG_CONST char  FAR * FAR * png_const_charpp;
typedef char            FAR * FAR * png_charpp;
typedef png_fixed_point FAR * FAR * png_fixed_point_pp;
#ifdef PNG_FLOATING_POINT_SUPPORTED
typedef double          FAR * FAR * png_doublepp;
#endif

/* Pointers to pointers to pointers; i.e., pointer to array */
typedef char            FAR * FAR * FAR * png_charppp;

#if defined(PNG_1_0_X) || defined(PNG_1_2_X)
/* SPC -  Is this stuff deprecated? */
/* It'll be removed as of libpng-1.4.0 - GR-P */
/* libpng typedefs for types in zlib. If zlib changes
 * or another compression library is used, then change these.
 * Eliminates need to change all the source files.
 */
typedef charf *         png_zcharp;
typedef charf * FAR *   png_zcharpp;
typedef z_stream FAR *  png_zstreamp;
#endif /* (PNG_1_0_X) || defined(PNG_1_2_X) */

/*
 * Define PNG_BUILD_DLL if the module being built is a Windows
 * LIBPNG DLL.
 *
 * Define PNG_USE_DLL if you want to *link* to the Windows LIBPNG DLL.
 * It is equivalent to Microsoft predefined macro _DLL that is
 * automatically defined when you compile using the share
 * version of the CRT (C Run-Time library)
 *
 * The cygwin mods make this behavior a little different:
 * Define PNG_BUILD_DLL if you are building a dll for use with cygwin
 * Define PNG_STATIC if you are building a static library for use with cygwin,
 *   -or- if you are building an application that you want to link to the
 *   static library.
 * PNG_USE_DLL is defined by default (no user action needed) unless one of
 *   the other flags is defined.
 */

#if !defined(PNG_DLL) && (defined(PNG_BUILD_DLL) || defined(PNG_USE_DLL))
#  define PNG_DLL
#endif
/* If CYGWIN, then disallow GLOBAL ARRAYS unless building a static lib.
 * When building a static lib, default to no GLOBAL ARRAYS, but allow
 * command-line override
 */
#ifdef __CYGWIN__
#  ifndef PNG_STATIC
#    ifdef PNG_USE_GLOBAL_ARRAYS
#      undef PNG_USE_GLOBAL_ARRAYS
#    endif
#    ifndef PNG_USE_LOCAL_ARRAYS
#      define PNG_USE_LOCAL_ARRAYS
#    endif
#  else
#    if defined(PNG_USE_LOCAL_ARRAYS) || defined(PNG_NO_GLOBAL_ARRAYS)
#      ifdef PNG_USE_GLOBAL_ARRAYS
#        undef PNG_USE_GLOBAL_ARRAYS
#      endif
#    endif
#  endif
#  if !defined(PNG_USE_LOCAL_ARRAYS) && !defined(PNG_USE_GLOBAL_ARRAYS)
#    define PNG_USE_LOCAL_ARRAYS
#  endif
#endif

/* Do not use global arrays (helps with building DLL's)
 * They are no longer used in libpng itself, since version 1.0.5c,
 * but might be required for some pre-1.0.5c applications.
 */
#if !defined(PNG_USE_LOCAL_ARRAYS) && !defined(PNG_USE_GLOBAL_ARRAYS)
#  if defined(PNG_NO_GLOBAL_ARRAYS) || \
      (defined(__GNUC__) && defined(PNG_DLL)) || defined(_MSC_VER)
#    define PNG_USE_LOCAL_ARRAYS
#  else
#    define PNG_USE_GLOBAL_ARRAYS
#  endif
#endif

#ifdef __CYGWIN__
#  undef PNGAPI
#  define PNGAPI __cdecl
#  undef PNG_IMPEXP
#  define PNG_IMPEXP
#endif

/* If you define PNGAPI, e.g., with compiler option "-DPNGAPI=__stdcall",
 * you may get warnings regarding the linkage of png_zalloc and png_zfree.
 * Don't ignore those warnings; you must also reset the default calling
 * convention in your compiler to match your PNGAPI, and you must build
 * zlib and your applications the same way you build libpng.
 */

#if defined(__MINGW32__) && !defined(PNG_MODULEDEF)
#  ifndef PNG_NO_MODULEDEF
#    define PNG_NO_MODULEDEF
#  endif
#endif

#if !defined(PNG_IMPEXP) && defined(PNG_BUILD_DLL) && !defined(PNG_NO_MODULEDEF)
#  define PNG_IMPEXP
#endif

#if defined(PNG_DLL) || defined(_DLL) || defined(__DLL__ ) || \
    (( defined(_Windows) || defined(_WINDOWS) || \
       defined(WIN32) || defined(_WIN32) || defined(__WIN32__) ))

#  ifndef PNGAPI
#     if defined(__GNUC__) || (defined (_MSC_VER) && (_MSC_VER >= 800))
#        define PNGAPI __cdecl
#     else
#        define PNGAPI _cdecl
#     endif
#  endif

#  if !defined(PNG_IMPEXP) && (!defined(PNG_DLL) || \
       0 /* WINCOMPILER_WITH_NO_SUPPORT_FOR_DECLIMPEXP */)
#     define PNG_IMPEXP
#  endif

#  ifndef PNG_IMPEXP

#     define PNG_EXPORT_TYPE1(type,symbol)  PNG_IMPEXP type PNGAPI symbol
#     define PNG_EXPORT_TYPE2(type,symbol)  type PNG_IMPEXP PNGAPI symbol

      /* Borland/Microsoft */
#     if defined(_MSC_VER) || defined(__BORLANDC__)
#        if (_MSC_VER >= 800) || (__BORLANDC__ >= 0x500)
#           define PNG_EXPORT PNG_EXPORT_TYPE1
#        else
#           define PNG_EXPORT PNG_EXPORT_TYPE2
#           ifdef PNG_BUILD_DLL
#              define PNG_IMPEXP __export
#           else
#              define PNG_IMPEXP /*__import */ /* doesn't exist AFAIK in
                                                 VC++ */
#           endif                             /* Exists in Borland C++ for
                                                 C++ classes (== huge) */
#        endif
#     endif

#     ifndef PNG_IMPEXP
#        ifdef PNG_BUILD_DLL
#           define PNG_IMPEXP __declspec(dllexport)
#        else
#           define PNG_IMPEXP __declspec(dllimport)
#        endif
#     endif
#  endif  /* PNG_IMPEXP */
#else /* !(DLL || non-cygwin WINDOWS) */
#   if (defined(__IBMC__) || defined(__IBMCPP__)) && defined(__OS2__)
#      ifndef PNGAPI
#         define PNGAPI _System
#      endif
#   else
#      if 0 /* ... other platforms, with other meanings */
#      endif
#   endif
#endif

#ifndef PNGAPI
#  define PNGAPI
#endif
#ifndef PNG_IMPEXP
#  define PNG_IMPEXP
#endif

#ifdef PNG_BUILDSYMS
#  ifndef PNG_EXPORT
#    define PNG_EXPORT(type,symbol) PNG_FUNCTION_EXPORT symbol END
#  endif
#  ifdef PNG_USE_GLOBAL_ARRAYS
#    ifndef PNG_EXPORT_VAR
#      define PNG_EXPORT_VAR(type) PNG_DATA_EXPORT
#    endif
#  endif
#endif

#ifndef PNG_EXPORT
#  define PNG_EXPORT(type,symbol) PNG_IMPEXP type PNGAPI symbol
#endif

#ifdef PNG_USE_GLOBAL_ARRAYS
#  ifndef PNG_EXPORT_VAR
#    define PNG_EXPORT_VAR(type) extern PNG_IMPEXP type
#  endif
#endif

#ifdef PNG_PEDANTIC_WARNINGS
#  ifndef PNG_PEDANTIC_WARNINGS_SUPPORTED
#    define PNG_PEDANTIC_WARNINGS_SUPPORTED
#  endif
#endif

#ifdef PNG_PEDANTIC_WARNINGS_SUPPORTED
/* Support for compiler specific function attributes.  These are used
 * so that where compiler support is available incorrect use of API
 * functions in png.h will generate compiler warnings.  Added at libpng
 * version 1.2.41.
 */
#  ifdef __GNUC__
#    ifndef PNG_USE_RESULT
#      define PNG_USE_RESULT __attribute__((__warn_unused_result__))
#    endif
#    ifndef PNG_NORETURN
#      define PNG_NORETURN   __attribute__((__noreturn__))
#    endif
#    ifndef PNG_ALLOCATED
#      define PNG_ALLOCATED  __attribute__((__malloc__))
#    endif

    /* This specifically protects structure members that should only be
     * accessed from within the library, therefore should be empty during
     * a library build.
     */
#    ifndef PNG_DEPRECATED
#      define PNG_DEPRECATED __attribute__((__deprecated__))
#    endif
#    ifndef PNG_DEPSTRUCT
#      define PNG_DEPSTRUCT  __attribute__((__deprecated__))
#    endif
#    ifndef PNG_PRIVATE
#      if 0 /* Doesn't work so we use deprecated instead*/
#        define PNG_PRIVATE \
          __attribute__((warning("This function is not exported by libpng.")))
#      else
#        define PNG_PRIVATE \
          __attribute__((__deprecated__))
#      endif
#    endif /* PNG_PRIVATE */
#  endif /* __GNUC__ */
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
#ifndef PNG_DEPSTRUCT
#  define PNG_DEPSTRUCT   /* Access to this struct member is deprecated */
#endif
#ifndef PNG_PRIVATE
#  define PNG_PRIVATE     /* This is a private libpng function */
#endif

/* User may want to use these so they are not in PNG_INTERNAL. Any library
 * functions that are passed far data must be model independent.
 */

#ifndef PNG_ABORT
#  define PNG_ABORT() abort()
#endif

#ifdef PNG_SETJMP_SUPPORTED
#  define png_jmpbuf(png_ptr) ((png_ptr)->jmpbuf)
#else
#  define png_jmpbuf(png_ptr) \
   (LIBPNG_WAS_COMPILED_WITH__PNG_SETJMP_NOT_SUPPORTED)
#endif

#ifdef USE_FAR_KEYWORD  /* memory model independent fns */
/* Use this to make far-to-near assignments */
#  define CHECK   1
#  define NOCHECK 0
#  define CVT_PTR(ptr) (png_far_to_near(png_ptr,ptr,CHECK))
#  define CVT_PTR_NOCHECK(ptr) (png_far_to_near(png_ptr,ptr,NOCHECK))
#  define png_snprintf _fsnprintf   /* Added to v 1.2.19 */
#  define png_strlen  _fstrlen
#  define png_memcmp  _fmemcmp    /* SJT: added */
#  define png_memcpy  _fmemcpy
#  define png_memset  _fmemset
#else /* Use the usual functions */
#  define CVT_PTR(ptr)         (ptr)
#  define CVT_PTR_NOCHECK(ptr) (ptr)
#  ifndef PNG_NO_SNPRINTF
#    ifdef _MSC_VER
#      define png_snprintf _snprintf   /* Added to v 1.2.19 */
#      define png_snprintf2 _snprintf
#      define png_snprintf6 _snprintf
#    else
#      define png_snprintf snprintf   /* Added to v 1.2.19 */
#      define png_snprintf2 snprintf
#      define png_snprintf6 snprintf
#    endif
#  else
     /* You don't have or don't want to use snprintf().  Caution: Using
      * sprintf instead of snprintf exposes your application to accidental
      * or malevolent buffer overflows.  If you don't have snprintf()
      * as a general rule you should provide one (you can get one from
      * Portable OpenSSH).
      */
#    define png_snprintf(s1,n,fmt,x1) sprintf(s1,fmt,x1)
#    define png_snprintf2(s1,n,fmt,x1,x2) sprintf(s1,fmt,x1,x2)
#    define png_snprintf6(s1,n,fmt,x1,x2,x3,x4,x5,x6) \
        sprintf(s1,fmt,x1,x2,x3,x4,x5,x6)
#  endif
#  define png_strlen  strlen
#  define png_memcmp  memcmp      /* SJT: added */
#  define png_memcpy  memcpy
#  define png_memset  memset
#endif
/* End of memory model independent support */

/* Just a little check that someone hasn't tried to define something
 * contradictory.
 */
#if (PNG_ZBUF_SIZE > 65536L) && defined(PNG_MAX_MALLOC_64K)
#  undef PNG_ZBUF_SIZE
#  define PNG_ZBUF_SIZE 65536L
#endif

/* Added at libpng-1.2.8 */
#endif /* PNG_VERSION_INFO_ONLY */

#endif /* PNGCONF_H */
