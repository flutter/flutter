
/* png.h - header file for PNG reference library
 *
 * libpng version 1.6.22rc01, May 14, 2016
 *
 * Copyright (c) 1998-2002,2004,2006-2016 Glenn Randers-Pehrson
 * (Version 0.96 Copyright (c) 1996, 1997 Andreas Dilger)
 * (Version 0.88 Copyright (c) 1995, 1996 Guy Eric Schalnat, Group 42, Inc.)
 *
 * This code is released under the libpng license (See LICENSE, below)
 *
 * Authors and maintainers:
 *   libpng versions 0.71, May 1995, through 0.88, January 1996: Guy Schalnat
 *   libpng versions 0.89, June 1996, through 0.96, May 1997: Andreas Dilger
 *   libpng versions 0.97, January 1998, through 1.6.22rc01, May 14, 2016:
 *     Glenn Randers-Pehrson.
 *   See also "Contributing Authors", below.
 */

/*
 * COPYRIGHT NOTICE, DISCLAIMER, and LICENSE:
 *
 * If you modify libpng you may insert additional notices immediately following
 * this sentence.
 *
 * This code is released under the libpng license.
 *
 * Some files in the "contrib" directory and some configure-generated
 * files that are distributed with libpng have other copyright owners and
 * are released under other open source licenses.
 *
 * libpng versions 1.0.7, July 1, 2000 through 1.6.22rc01, May 14, 2016 are
 * Copyright (c) 2000-2002, 2004, 2006-2016 Glenn Randers-Pehrson, are
 * derived from libpng-1.0.6, and are distributed according to the same
 * disclaimer and license as libpng-1.0.6 with the following individuals
 * added to the list of Contributing Authors:
 *
 *    Simon-Pierre Cadieux
 *    Eric S. Raymond
 *    Mans Rullgard
 *    Cosmin Truta
 *    Gilles Vollant
 *    James Yu
 *
 * and with the following additions to the disclaimer:
 *
 *    There is no warranty against interference with your enjoyment of the
 *    library or against infringement.  There is no warranty that our
 *    efforts or the library will fulfill any of your particular purposes
 *    or needs.  This library is provided with all faults, and the entire
 *    risk of satisfactory quality, performance, accuracy, and effort is with
 *    the user.
 *
 * Some files in the "contrib" directory have other copyright owners and
 * are released under other open source licenses.
 *
 *
 * libpng versions 0.97, January 1998, through 1.0.6, March 20, 2000, are
 * Copyright (c) 1998-2000 Glenn Randers-Pehrson, are derived from
 * libpng-0.96, and are distributed according to the same disclaimer and
 * license as libpng-0.96, with the following individuals added to the list
 * of Contributing Authors:
 *
 *    Tom Lane
 *    Glenn Randers-Pehrson
 *    Willem van Schaik
 *
 * Some files in the "scripts" directory have different copyright owners
 * but are also released under this license.
 *
 * libpng versions 0.89, June 1996, through 0.96, May 1997, are
 * Copyright (c) 1996-1997 Andreas Dilger, are derived from libpng-0.88,
 * and are distributed according to the same disclaimer and license as
 * libpng-0.88, with the following individuals added to the list of
 * Contributing Authors:
 *
 *    John Bowler
 *    Kevin Bracey
 *    Sam Bushell
 *    Magnus Holmgren
 *    Greg Roelofs
 *    Tom Tanner
 *
 * Some files in the "scripts" directory have other copyright owners
 * but are released under this license.
 *
 * libpng versions 0.5, May 1995, through 0.88, January 1996, are
 * Copyright (c) 1995-1996 Guy Eric Schalnat, Group 42, Inc.
 *
 * For the purposes of this copyright and license, "Contributing Authors"
 * is defined as the following set of individuals:
 *
 *    Andreas Dilger
 *    Dave Martindale
 *    Guy Eric Schalnat
 *    Paul Schmidt
 *    Tim Wegner
 *
 * The PNG Reference Library is supplied "AS IS".  The Contributing Authors
 * and Group 42, Inc. disclaim all warranties, expressed or implied,
 * including, without limitation, the warranties of merchantability and of
 * fitness for any purpose.  The Contributing Authors and Group 42, Inc.
 * assume no liability for direct, indirect, incidental, special, exemplary,
 * or consequential damages, which may result from the use of the PNG
 * Reference Library, even if advised of the possibility of such damage.
 *
 * Permission is hereby granted to use, copy, modify, and distribute this
 * source code, or portions hereof, for any purpose, without fee, subject
 * to the following restrictions:
 *
 *   1. The origin of this source code must not be misrepresented.
 *
 *   2. Altered versions must be plainly marked as such and must not
 *      be misrepresented as being the original source.
 *
 *   3. This Copyright notice may not be removed or altered from any
 *      source or altered source distribution.
 *
 * The Contributing Authors and Group 42, Inc. specifically permit, without
 * fee, and encourage the use of this source code as a component to
 * supporting the PNG file format in commercial products.  If you use this
 * source code in a product, acknowledgment is not required but would be
 * appreciated.
 *
 * END OF COPYRIGHT NOTICE, DISCLAIMER, and LICENSE.
 *
 * TRADEMARK:
 *
 * The name "libpng" has not been registered by the Copyright owner
 * as a trademark in any jurisdiction.  However, because libpng has
 * been distributed and maintained world-wide, continually since 1995,
 * the Copyright owner claims "common-law trademark protection" in any
 * jurisdiction where common-law trademark is recognized.
 *
 * OSI CERTIFICATION:
 *
 * Libpng is OSI Certified Open Source Software.  OSI Certified Open Source is
 * a certification mark of the Open Source Initiative. OSI has not addressed
 * the additional disclaimers inserted at version 1.0.7.
 *
 * EXPORT CONTROL:
 *
 * The Copyright owner believes that the Export Control Classification
 * Number (ECCN) for libpng is EAR99, which means not subject to export
 * controls or International Traffic in Arms Regulations (ITAR) because
 * it is open source, publicly available software, that does not contain
 * any encryption software.  See the EAR, paragraphs 734.3(b)(3) and
 * 734.7(b).
 */

/*
 * A "png_get_copyright" function is available, for convenient use in "about"
 * boxes and the like:
 *
 *    printf("%s", png_get_copyright(NULL));
 *
 * Also, the PNG logo (in PNG format, of course) is supplied in the
 * files "pngbar.png" and "pngbar.jpg (88x31) and "pngnow.png" (98x31).
 */

/*
 * The contributing authors would like to thank all those who helped
 * with testing, bug fixes, and patience.  This wouldn't have been
 * possible without all of you.
 *
 * Thanks to Frank J. T. Wojcik for helping with the documentation.
 */

/* Note about libpng version numbers:
 *
 *    Due to various miscommunications, unforeseen code incompatibilities
 *    and occasional factors outside the authors' control, version numbering
 *    on the library has not always been consistent and straightforward.
 *    The following table summarizes matters since version 0.89c, which was
 *    the first widely used release:
 *
 *    source                 png.h  png.h  shared-lib
 *    version                string   int  version
 *    -------                ------ -----  ----------
 *    0.89c "1.0 beta 3"     0.89      89  1.0.89
 *    0.90  "1.0 beta 4"     0.90      90  0.90  [should have been 2.0.90]
 *    0.95  "1.0 beta 5"     0.95      95  0.95  [should have been 2.0.95]
 *    0.96  "1.0 beta 6"     0.96      96  0.96  [should have been 2.0.96]
 *    0.97b "1.00.97 beta 7" 1.00.97   97  1.0.1 [should have been 2.0.97]
 *    0.97c                  0.97      97  2.0.97
 *    0.98                   0.98      98  2.0.98
 *    0.99                   0.99      98  2.0.99
 *    0.99a-m                0.99      99  2.0.99
 *    1.00                   1.00     100  2.1.0 [100 should be 10000]
 *    1.0.0      (from here on, the   100  2.1.0 [100 should be 10000]
 *    1.0.1       png.h string is   10001  2.1.0
 *    1.0.1a-e    identical to the  10002  from here on, the shared library
 *    1.0.2       source version)   10002  is 2.V where V is the source code
 *    1.0.2a-b                      10003  version, except as noted.
 *    1.0.3                         10003
 *    1.0.3a-d                      10004
 *    1.0.4                         10004
 *    1.0.4a-f                      10005
 *    1.0.5 (+ 2 patches)           10005
 *    1.0.5a-d                      10006
 *    1.0.5e-r                      10100 (not source compatible)
 *    1.0.5s-v                      10006 (not binary compatible)
 *    1.0.6 (+ 3 patches)           10006 (still binary incompatible)
 *    1.0.6d-f                      10007 (still binary incompatible)
 *    1.0.6g                        10007
 *    1.0.6h                        10007  10.6h (testing xy.z so-numbering)
 *    1.0.6i                        10007  10.6i
 *    1.0.6j                        10007  2.1.0.6j (incompatible with 1.0.0)
 *    1.0.7beta11-14        DLLNUM  10007  2.1.0.7beta11-14 (binary compatible)
 *    1.0.7beta15-18           1    10007  2.1.0.7beta15-18 (binary compatible)
 *    1.0.7rc1-2               1    10007  2.1.0.7rc1-2 (binary compatible)
 *    1.0.7                    1    10007  (still compatible)
 *    ...
 *    1.0.19                  10    10019  10.so.0.19[.0]
 *    ...
 *    1.2.56                  13    10256  12.so.0.56[.0]
 *    ...
 *    1.5.25                  15    10525  15.so.15.25[.0]
 *    ...
 *    1.6.22                  16    10622  16.so.16.22[.0]
 *
 *    Henceforth the source version will match the shared-library major
 *    and minor numbers; the shared-library major version number will be
 *    used for changes in backward compatibility, as it is intended.  The
 *    PNG_LIBPNG_VER macro, which is not used within libpng but is available
 *    for applications, is an unsigned integer of the form xyyzz corresponding
 *    to the source version x.y.z (leading zeros in y and z).  Beta versions
 *    were given the previous public release number plus a letter, until
 *    version 1.0.6j; from then on they were given the upcoming public
 *    release number plus "betaNN" or "rcNN".
 *
 *    Binary incompatibility exists only when applications make direct access
 *    to the info_ptr or png_ptr members through png.h, and the compiled
 *    application is loaded with a different version of the library.
 *
 *    DLLNUM will change each time there are forward or backward changes
 *    in binary compatibility (e.g., when a new feature is added).
 *
 * See libpng.txt or libpng.3 for more information.  The PNG specification
 * is available as a W3C Recommendation and as an ISO Specification,
 * <http://www.w3.org/TR/2003/REC-PNG-20031110/
 */

/*
 * Y2K compliance in libpng:
 * =========================
 *
 *    May 14, 2016
 *
 *    Since the PNG Development group is an ad-hoc body, we can't make
 *    an official declaration.
 *
 *    This is your unofficial assurance that libpng from version 0.71 and
 *    upward through 1.6.22rc01 are Y2K compliant.  It is my belief that
 *    earlier versions were also Y2K compliant.
 *
 *    Libpng only has two year fields.  One is a 2-byte unsigned integer
 *    that will hold years up to 65535.  The other, which is deprecated,
 *    holds the date in text format, and will hold years up to 9999.
 *
 *    The integer is
 *        "png_uint_16 year" in png_time_struct.
 *
 *    The string is
 *        "char time_buffer[29]" in png_struct.  This is no longer used
 *    in libpng-1.6.x and will be removed from libpng-1.7.0.
 *
 *    There are seven time-related functions:
 *        png.c: png_convert_to_rfc_1123_buffer() in png.c
 *          (formerly png_convert_to_rfc_1123() prior to libpng-1.5.x and
 *          png_convert_to_rfc_1152() in error prior to libpng-0.98)
 *        png_convert_from_struct_tm() in pngwrite.c, called in pngwrite.c
 *        png_convert_from_time_t() in pngwrite.c
 *        png_get_tIME() in pngget.c
 *        png_handle_tIME() in pngrutil.c, called in pngread.c
 *        png_set_tIME() in pngset.c
 *        png_write_tIME() in pngwutil.c, called in pngwrite.c
 *
 *    All handle dates properly in a Y2K environment.  The
 *    png_convert_from_time_t() function calls gmtime() to convert from system
 *    clock time, which returns (year - 1900), which we properly convert to
 *    the full 4-digit year.  There is a possibility that libpng applications
 *    are not passing 4-digit years into the png_convert_to_rfc_1123_buffer()
 *    function, or that they are incorrectly passing only a 2-digit year
 *    instead of "year - 1900" into the png_convert_from_struct_tm() function,
 *    but this is not under our control.  The libpng documentation has always
 *    stated that it works with 4-digit years, and the APIs have been
 *    documented as such.
 *
 *    The tIME chunk itself is also Y2K compliant.  It uses a 2-byte unsigned
 *    integer to hold the year, and can hold years as large as 65535.
 *
 *    zlib, upon which libpng depends, is also Y2K compliant.  It contains
 *    no date-related code.
 *
 *       Glenn Randers-Pehrson
 *       libpng maintainer
 *       PNG Development Group
 */

#ifndef PNG_H
#define PNG_H

/* This is not the place to learn how to use libpng. The file libpng-manual.txt
 * describes how to use libpng, and the file example.c summarizes it
 * with some code on which to build.  This file is useful for looking
 * at the actual function definitions and structure components.  If that
 * file has been stripped from your copy of libpng, you can find it at
 * <http://www.libpng.org/pub/png/libpng-manual.txt>
 *
 * If you just need to read a PNG file and don't want to read the documentation
 * skip to the end of this file and read the section entitled 'simplified API'.
 */

/* Version information for png.h - this should match the version in png.c */
#define PNG_LIBPNG_VER_STRING "1.6.22rc01"
#define PNG_HEADER_VERSION_STRING \
     " libpng version 1.6.22rc01 - May 14, 2016\n"

#define PNG_LIBPNG_VER_SONUM   16
#define PNG_LIBPNG_VER_DLLNUM  16

/* These should match the first 3 components of PNG_LIBPNG_VER_STRING: */
#define PNG_LIBPNG_VER_MAJOR   1
#define PNG_LIBPNG_VER_MINOR   6
#define PNG_LIBPNG_VER_RELEASE 22

/* This should match the numeric part of the final component of
 * PNG_LIBPNG_VER_STRING, omitting any leading zero:
 */

#define PNG_LIBPNG_VER_BUILD  01

/* Release Status */
#define PNG_LIBPNG_BUILD_ALPHA    1
#define PNG_LIBPNG_BUILD_BETA     2
#define PNG_LIBPNG_BUILD_RC       3
#define PNG_LIBPNG_BUILD_STABLE   4
#define PNG_LIBPNG_BUILD_RELEASE_STATUS_MASK 7

/* Release-Specific Flags */
#define PNG_LIBPNG_BUILD_PATCH    8 /* Can be OR'ed with
                                       PNG_LIBPNG_BUILD_STABLE only */
#define PNG_LIBPNG_BUILD_PRIVATE 16 /* Cannot be OR'ed with
                                       PNG_LIBPNG_BUILD_SPECIAL */
#define PNG_LIBPNG_BUILD_SPECIAL 32 /* Cannot be OR'ed with
                                       PNG_LIBPNG_BUILD_PRIVATE */

#define PNG_LIBPNG_BUILD_BASE_TYPE PNG_LIBPNG_BUILD_RC

/* Careful here.  At one time, Guy wanted to use 082, but that would be octal.
 * We must not include leading zeros.
 * Versions 0.7 through 1.0.0 were in the range 0 to 100 here (only
 * version 1.0.0 was mis-numbered 100 instead of 10000).  From
 * version 1.0.1 it's    xxyyzz, where x=major, y=minor, z=release
 */
#define PNG_LIBPNG_VER 10622 /* 1.6.22 */

/* Library configuration: these options cannot be changed after
 * the library has been built.
 */
#ifndef PNGLCONF_H
    /* If pnglibconf.h is missing, you can
     * copy scripts/pnglibconf.h.prebuilt to pnglibconf.h
     */
#   include "pnglibconf.h"
#endif

#ifndef PNG_VERSION_INFO_ONLY
   /* Machine specific configuration. */
#  include "pngconf.h"
#endif

/*
 * Added at libpng-1.2.8
 *
 * Ref MSDN: Private as priority over Special
 * VS_FF_PRIVATEBUILD File *was not* built using standard release
 * procedures. If this value is given, the StringFileInfo block must
 * contain a PrivateBuild string.
 *
 * VS_FF_SPECIALBUILD File *was* built by the original company using
 * standard release procedures but is a variation of the standard
 * file of the same version number. If this value is given, the
 * StringFileInfo block must contain a SpecialBuild string.
 */

#ifdef PNG_USER_PRIVATEBUILD /* From pnglibconf.h */
#  define PNG_LIBPNG_BUILD_TYPE \
       (PNG_LIBPNG_BUILD_BASE_TYPE | PNG_LIBPNG_BUILD_PRIVATE)
#else
#  ifdef PNG_LIBPNG_SPECIALBUILD
#    define PNG_LIBPNG_BUILD_TYPE \
         (PNG_LIBPNG_BUILD_BASE_TYPE | PNG_LIBPNG_BUILD_SPECIAL)
#  else
#    define PNG_LIBPNG_BUILD_TYPE (PNG_LIBPNG_BUILD_BASE_TYPE)
#  endif
#endif

#ifndef PNG_VERSION_INFO_ONLY

/* Inhibit C++ name-mangling for libpng functions but not for system calls. */
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* Version information for C files, stored in png.c.  This had better match
 * the version above.
 */
#define png_libpng_ver png_get_header_ver(NULL)

/* This file is arranged in several sections:
 *
 * 1. [omitted]
 * 2. Any configuration options that can be specified by for the application
 *    code when it is built.  (Build time configuration is in pnglibconf.h)
 * 3. Type definitions (base types are defined in pngconf.h), structure
 *    definitions.
 * 4. Exported library functions.
 * 5. Simplified API.
 * 6. Implementation options.
 *
 * The library source code has additional files (principally pngpriv.h) that
 * allow configuration of the library.
 */

/* Section 1: [omitted] */

/* Section 2: run time configuration
 * See pnglibconf.h for build time configuration
 *
 * Run time configuration allows the application to choose between
 * implementations of certain arithmetic APIs.  The default is set
 * at build time and recorded in pnglibconf.h, but it is safe to
 * override these (and only these) settings.  Note that this won't
 * change what the library does, only application code, and the
 * settings can (and probably should) be made on a per-file basis
 * by setting the #defines before including png.h
 *
 * Use macros to read integers from PNG data or use the exported
 * functions?
 *   PNG_USE_READ_MACROS: use the macros (see below)  Note that
 *     the macros evaluate their argument multiple times.
 *   PNG_NO_USE_READ_MACROS: call the relevant library function.
 *
 * Use the alternative algorithm for compositing alpha samples that
 * does not use division?
 *   PNG_READ_COMPOSITE_NODIV_SUPPORTED: use the 'no division'
 *      algorithm.
 *   PNG_NO_READ_COMPOSITE_NODIV: use the 'division' algorithm.
 *
 * How to handle benign errors if PNG_ALLOW_BENIGN_ERRORS is
 * false?
 *   PNG_ALLOW_BENIGN_ERRORS: map calls to the benign error
 *      APIs to png_warning.
 * Otherwise the calls are mapped to png_error.
 */

/* Section 3: type definitions, including structures and compile time
 * constants.
 * See pngconf.h for base types that vary by machine/system
 */

/* This triggers a compiler error in png.c, if png.c and png.h
 * do not agree upon the version number.
 */
typedef char* png_libpng_version_1_6_22rc01;

/* Basic control structions.  Read libpng-manual.txt or libpng.3 for more info.
 *
 * png_struct is the cache of information used while reading or writing a single
 * PNG file.  One of these is always required, although the simplified API
 * (below) hides the creation and destruction of it.
 */
typedef struct png_struct_def png_struct;
typedef const png_struct * png_const_structp;
typedef png_struct * png_structp;
typedef png_struct * * png_structpp;

/* png_info contains information read from or to be written to a PNG file.  One
 * or more of these must exist while reading or creating a PNG file.  The
 * information is not used by libpng during read but is used to control what
 * gets written when a PNG file is created.  "png_get_" function calls read
 * information during read and "png_set_" functions calls write information
 * when creating a PNG.
 * been moved into a separate header file that is not accessible to
 * applications.  Read libpng-manual.txt or libpng.3 for more info.
 */
typedef struct png_info_def png_info;
typedef png_info * png_infop;
typedef const png_info * png_const_infop;
typedef png_info * * png_infopp;

/* Types with names ending 'p' are pointer types.  The corresponding types with
 * names ending 'rp' are identical pointer types except that the pointer is
 * marked 'restrict', which means that it is the only pointer to the object
 * passed to the function.  Applications should not use the 'restrict' types;
 * it is always valid to pass 'p' to a pointer with a function argument of the
 * corresponding 'rp' type.  Different compilers have different rules with
 * regard to type matching in the presence of 'restrict'.  For backward
 * compatibility libpng callbacks never have 'restrict' in their parameters and,
 * consequentially, writing portable application code is extremely difficult if
 * an attempt is made to use 'restrict'.
 */
typedef png_struct * PNG_RESTRICT png_structrp;
typedef const png_struct * PNG_RESTRICT png_const_structrp;
typedef png_info * PNG_RESTRICT png_inforp;
typedef const png_info * PNG_RESTRICT png_const_inforp;

/* Three color definitions.  The order of the red, green, and blue, (and the
 * exact size) is not important, although the size of the fields need to
 * be png_byte or png_uint_16 (as defined below).
 */
typedef struct png_color_struct
{
   png_byte red;
   png_byte green;
   png_byte blue;
} png_color;
typedef png_color * png_colorp;
typedef const png_color * png_const_colorp;
typedef png_color * * png_colorpp;

typedef struct png_color_16_struct
{
   png_byte index;    /* used for palette files */
   png_uint_16 red;   /* for use in red green blue files */
   png_uint_16 green;
   png_uint_16 blue;
   png_uint_16 gray;  /* for use in grayscale files */
} png_color_16;
typedef png_color_16 * png_color_16p;
typedef const png_color_16 * png_const_color_16p;
typedef png_color_16 * * png_color_16pp;

typedef struct png_color_8_struct
{
   png_byte red;   /* for use in red green blue files */
   png_byte green;
   png_byte blue;
   png_byte gray;  /* for use in grayscale files */
   png_byte alpha; /* for alpha channel files */
} png_color_8;
typedef png_color_8 * png_color_8p;
typedef const png_color_8 * png_const_color_8p;
typedef png_color_8 * * png_color_8pp;

/*
 * The following two structures are used for the in-core representation
 * of sPLT chunks.
 */
typedef struct png_sPLT_entry_struct
{
   png_uint_16 red;
   png_uint_16 green;
   png_uint_16 blue;
   png_uint_16 alpha;
   png_uint_16 frequency;
} png_sPLT_entry;
typedef png_sPLT_entry * png_sPLT_entryp;
typedef const png_sPLT_entry * png_const_sPLT_entryp;
typedef png_sPLT_entry * * png_sPLT_entrypp;

/*  When the depth of the sPLT palette is 8 bits, the color and alpha samples
 *  occupy the LSB of their respective members, and the MSB of each member
 *  is zero-filled.  The frequency member always occupies the full 16 bits.
 */

typedef struct png_sPLT_struct
{
   png_charp name;           /* palette name */
   png_byte depth;           /* depth of palette samples */
   png_sPLT_entryp entries;  /* palette entries */
   png_int_32 nentries;      /* number of palette entries */
} png_sPLT_t;
typedef png_sPLT_t * png_sPLT_tp;
typedef const png_sPLT_t * png_const_sPLT_tp;
typedef png_sPLT_t * * png_sPLT_tpp;

#ifdef PNG_TEXT_SUPPORTED
/* png_text holds the contents of a text/ztxt/itxt chunk in a PNG file,
 * and whether that contents is compressed or not.  The "key" field
 * points to a regular zero-terminated C string.  The "text" fields can be a
 * regular C string, an empty string, or a NULL pointer.
 * However, the structure returned by png_get_text() will always contain
 * the "text" field as a regular zero-terminated C string (possibly
 * empty), never a NULL pointer, so it can be safely used in printf() and
 * other string-handling functions.  Note that the "itxt_length", "lang", and
 * "lang_key" members of the structure only exist when the library is built
 * with iTXt chunk support.  Prior to libpng-1.4.0 the library was built by
 * default without iTXt support. Also note that when iTXt *is* supported,
 * the "lang" and "lang_key" fields contain NULL pointers when the
 * "compression" field contains * PNG_TEXT_COMPRESSION_NONE or
 * PNG_TEXT_COMPRESSION_zTXt. Note that the "compression value" is not the
 * same as what appears in the PNG tEXt/zTXt/iTXt chunk's "compression flag"
 * which is always 0 or 1, or its "compression method" which is always 0.
 */
typedef struct png_text_struct
{
   int  compression;       /* compression value:
                             -1: tEXt, none
                              0: zTXt, deflate
                              1: iTXt, none
                              2: iTXt, deflate  */
   png_charp key;          /* keyword, 1-79 character description of "text" */
   png_charp text;         /* comment, may be an empty string (ie "")
                              or a NULL pointer */
   png_size_t text_length; /* length of the text string */
   png_size_t itxt_length; /* length of the itxt string */
   png_charp lang;         /* language code, 0-79 characters
                              or a NULL pointer */
   png_charp lang_key;     /* keyword translated UTF-8 string, 0 or more
                              chars or a NULL pointer */
} png_text;
typedef png_text * png_textp;
typedef const png_text * png_const_textp;
typedef png_text * * png_textpp;
#endif

/* Supported compression types for text in PNG files (tEXt, and zTXt).
 * The values of the PNG_TEXT_COMPRESSION_ defines should NOT be changed. */
#define PNG_TEXT_COMPRESSION_NONE_WR -3
#define PNG_TEXT_COMPRESSION_zTXt_WR -2
#define PNG_TEXT_COMPRESSION_NONE    -1
#define PNG_TEXT_COMPRESSION_zTXt     0
#define PNG_ITXT_COMPRESSION_NONE     1
#define PNG_ITXT_COMPRESSION_zTXt     2
#define PNG_TEXT_COMPRESSION_LAST     3  /* Not a valid value */

/* png_time is a way to hold the time in an machine independent way.
 * Two conversions are provided, both from time_t and struct tm.  There
 * is no portable way to convert to either of these structures, as far
 * as I know.  If you know of a portable way, send it to me.  As a side
 * note - PNG has always been Year 2000 compliant!
 */
typedef struct png_time_struct
{
   png_uint_16 year; /* full year, as in, 1995 */
   png_byte month;   /* month of year, 1 - 12 */
   png_byte day;     /* day of month, 1 - 31 */
   png_byte hour;    /* hour of day, 0 - 23 */
   png_byte minute;  /* minute of hour, 0 - 59 */
   png_byte second;  /* second of minute, 0 - 60 (for leap seconds) */
} png_time;
typedef png_time * png_timep;
typedef const png_time * png_const_timep;
typedef png_time * * png_timepp;

#if defined(PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED) ||\
   defined(PNG_USER_CHUNKS_SUPPORTED)
/* png_unknown_chunk is a structure to hold queued chunks for which there is
 * no specific support.  The idea is that we can use this to queue
 * up private chunks for output even though the library doesn't actually
 * know about their semantics.
 *
 * The data in the structure is set by libpng on read and used on write.
 */
typedef struct png_unknown_chunk_t
{
    png_byte name[5]; /* Textual chunk name with '\0' terminator */
    png_byte *data;   /* Data, should not be modified on read! */
    png_size_t size;

    /* On write 'location' must be set using the flag values listed below.
     * Notice that on read it is set by libpng however the values stored have
     * more bits set than are listed below.  Always treat the value as a
     * bitmask.  On write set only one bit - setting multiple bits may cause the
     * chunk to be written in multiple places.
     */
    png_byte location; /* mode of operation at read time */
}
png_unknown_chunk;

typedef png_unknown_chunk * png_unknown_chunkp;
typedef const png_unknown_chunk * png_const_unknown_chunkp;
typedef png_unknown_chunk * * png_unknown_chunkpp;
#endif

/* Flag values for the unknown chunk location byte. */
#define PNG_HAVE_IHDR  0x01
#define PNG_HAVE_PLTE  0x02
#define PNG_AFTER_IDAT 0x08

/* Maximum positive integer used in PNG is (2^31)-1 */
#define PNG_UINT_31_MAX ((png_uint_32)0x7fffffffL)
#define PNG_UINT_32_MAX ((png_uint_32)(-1))
#define PNG_SIZE_MAX ((png_size_t)(-1))

/* These are constants for fixed point values encoded in the
 * PNG specification manner (x100000)
 */
#define PNG_FP_1    100000
#define PNG_FP_HALF  50000
#define PNG_FP_MAX  ((png_fixed_point)0x7fffffffL)
#define PNG_FP_MIN  (-PNG_FP_MAX)

/* These describe the color_type field in png_info. */
/* color type masks */
#define PNG_COLOR_MASK_PALETTE    1
#define PNG_COLOR_MASK_COLOR      2
#define PNG_COLOR_MASK_ALPHA      4

/* color types.  Note that not all combinations are legal */
#define PNG_COLOR_TYPE_GRAY 0
#define PNG_COLOR_TYPE_PALETTE  (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE)
#define PNG_COLOR_TYPE_RGB        (PNG_COLOR_MASK_COLOR)
#define PNG_COLOR_TYPE_RGB_ALPHA  (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA)
#define PNG_COLOR_TYPE_GRAY_ALPHA (PNG_COLOR_MASK_ALPHA)
/* aliases */
#define PNG_COLOR_TYPE_RGBA  PNG_COLOR_TYPE_RGB_ALPHA
#define PNG_COLOR_TYPE_GA  PNG_COLOR_TYPE_GRAY_ALPHA

/* This is for compression type. PNG 1.0-1.2 only define the single type. */
#define PNG_COMPRESSION_TYPE_BASE 0 /* Deflate method 8, 32K window */
#define PNG_COMPRESSION_TYPE_DEFAULT PNG_COMPRESSION_TYPE_BASE

/* This is for filter type. PNG 1.0-1.2 only define the single type. */
#define PNG_FILTER_TYPE_BASE      0 /* Single row per-byte filtering */
#define PNG_INTRAPIXEL_DIFFERENCING 64 /* Used only in MNG datastreams */
#define PNG_FILTER_TYPE_DEFAULT   PNG_FILTER_TYPE_BASE

/* These are for the interlacing type.  These values should NOT be changed. */
#define PNG_INTERLACE_NONE        0 /* Non-interlaced image */
#define PNG_INTERLACE_ADAM7       1 /* Adam7 interlacing */
#define PNG_INTERLACE_LAST        2 /* Not a valid value */

/* These are for the oFFs chunk.  These values should NOT be changed. */
#define PNG_OFFSET_PIXEL          0 /* Offset in pixels */
#define PNG_OFFSET_MICROMETER     1 /* Offset in micrometers (1/10^6 meter) */
#define PNG_OFFSET_LAST           2 /* Not a valid value */

/* These are for the pCAL chunk.  These values should NOT be changed. */
#define PNG_EQUATION_LINEAR       0 /* Linear transformation */
#define PNG_EQUATION_BASE_E       1 /* Exponential base e transform */
#define PNG_EQUATION_ARBITRARY    2 /* Arbitrary base exponential transform */
#define PNG_EQUATION_HYPERBOLIC   3 /* Hyperbolic sine transformation */
#define PNG_EQUATION_LAST         4 /* Not a valid value */

/* These are for the sCAL chunk.  These values should NOT be changed. */
#define PNG_SCALE_UNKNOWN         0 /* unknown unit (image scale) */
#define PNG_SCALE_METER           1 /* meters per pixel */
#define PNG_SCALE_RADIAN          2 /* radians per pixel */
#define PNG_SCALE_LAST            3 /* Not a valid value */

/* These are for the pHYs chunk.  These values should NOT be changed. */
#define PNG_RESOLUTION_UNKNOWN    0 /* pixels/unknown unit (aspect ratio) */
#define PNG_RESOLUTION_METER      1 /* pixels/meter */
#define PNG_RESOLUTION_LAST       2 /* Not a valid value */

/* These are for the sRGB chunk.  These values should NOT be changed. */
#define PNG_sRGB_INTENT_PERCEPTUAL 0
#define PNG_sRGB_INTENT_RELATIVE   1
#define PNG_sRGB_INTENT_SATURATION 2
#define PNG_sRGB_INTENT_ABSOLUTE   3
#define PNG_sRGB_INTENT_LAST       4 /* Not a valid value */

/* This is for text chunks */
#define PNG_KEYWORD_MAX_LENGTH     79

/* Maximum number of entries in PLTE/sPLT/tRNS arrays */
#define PNG_MAX_PALETTE_LENGTH    256

/* These determine if an ancillary chunk's data has been successfully read
 * from the PNG header, or if the application has filled in the corresponding
 * data in the info_struct to be written into the output file.  The values
 * of the PNG_INFO_<chunk> defines should NOT be changed.
 */
#define PNG_INFO_gAMA 0x0001U
#define PNG_INFO_sBIT 0x0002U
#define PNG_INFO_cHRM 0x0004U
#define PNG_INFO_PLTE 0x0008U
#define PNG_INFO_tRNS 0x0010U
#define PNG_INFO_bKGD 0x0020U
#define PNG_INFO_hIST 0x0040U
#define PNG_INFO_pHYs 0x0080U
#define PNG_INFO_oFFs 0x0100U
#define PNG_INFO_tIME 0x0200U
#define PNG_INFO_pCAL 0x0400U
#define PNG_INFO_sRGB 0x0800U  /* GR-P, 0.96a */
#define PNG_INFO_iCCP 0x1000U  /* ESR, 1.0.6 */
#define PNG_INFO_sPLT 0x2000U  /* ESR, 1.0.6 */
#define PNG_INFO_sCAL 0x4000U  /* ESR, 1.0.6 */
#define PNG_INFO_IDAT 0x8000U  /* ESR, 1.0.6 */

/* This is used for the transformation routines, as some of them
 * change these values for the row.  It also should enable using
 * the routines for other purposes.
 */
typedef struct png_row_info_struct
{
   png_uint_32 width;    /* width of row */
   png_size_t rowbytes;  /* number of bytes in row */
   png_byte color_type;  /* color type of row */
   png_byte bit_depth;   /* bit depth of row */
   png_byte channels;    /* number of channels (1, 2, 3, or 4) */
   png_byte pixel_depth; /* bits per pixel (depth * channels) */
} png_row_info;

typedef png_row_info * png_row_infop;
typedef png_row_info * * png_row_infopp;

/* These are the function types for the I/O functions and for the functions
 * that allow the user to override the default I/O functions with his or her
 * own.  The png_error_ptr type should match that of user-supplied warning
 * and error functions, while the png_rw_ptr type should match that of the
 * user read/write data functions.  Note that the 'write' function must not
 * modify the buffer it is passed. The 'read' function, on the other hand, is
 * expected to return the read data in the buffer.
 */
typedef PNG_CALLBACK(void, *png_error_ptr, (png_structp, png_const_charp));
typedef PNG_CALLBACK(void, *png_rw_ptr, (png_structp, png_bytep, png_size_t));
typedef PNG_CALLBACK(void, *png_flush_ptr, (png_structp));
typedef PNG_CALLBACK(void, *png_read_status_ptr, (png_structp, png_uint_32,
    int));
typedef PNG_CALLBACK(void, *png_write_status_ptr, (png_structp, png_uint_32,
    int));

#ifdef PNG_PROGRESSIVE_READ_SUPPORTED
typedef PNG_CALLBACK(void, *png_progressive_info_ptr, (png_structp, png_infop));
typedef PNG_CALLBACK(void, *png_progressive_end_ptr, (png_structp, png_infop));

/* The following callback receives png_uint_32 row_number, int pass for the
 * png_bytep data of the row.  When transforming an interlaced image the
 * row number is the row number within the sub-image of the interlace pass, so
 * the value will increase to the height of the sub-image (not the full image)
 * then reset to 0 for the next pass.
 *
 * Use PNG_ROW_FROM_PASS_ROW(row, pass) and PNG_COL_FROM_PASS_COL(col, pass) to
 * find the output pixel (x,y) given an interlaced sub-image pixel
 * (row,col,pass).  (See below for these macros.)
 */
typedef PNG_CALLBACK(void, *png_progressive_row_ptr, (png_structp, png_bytep,
    png_uint_32, int));
#endif

#if defined(PNG_READ_USER_TRANSFORM_SUPPORTED) || \
    defined(PNG_WRITE_USER_TRANSFORM_SUPPORTED)
typedef PNG_CALLBACK(void, *png_user_transform_ptr, (png_structp, png_row_infop,
    png_bytep));
#endif

#ifdef PNG_USER_CHUNKS_SUPPORTED
typedef PNG_CALLBACK(int, *png_user_chunk_ptr, (png_structp,
    png_unknown_chunkp));
#endif
#ifdef PNG_UNKNOWN_CHUNKS_SUPPORTED
/* not used anywhere */
/* typedef PNG_CALLBACK(void, *png_unknown_chunk_ptr, (png_structp)); */
#endif

#ifdef PNG_SETJMP_SUPPORTED
/* This must match the function definition in <setjmp.h>, and the application
 * must include this before png.h to obtain the definition of jmp_buf.  The
 * function is required to be PNG_NORETURN, but this is not checked.  If the
 * function does return the application will crash via an abort() or similar
 * system level call.
 *
 * If you get a warning here while building the library you may need to make
 * changes to ensure that pnglibconf.h records the calling convention used by
 * your compiler.  This may be very difficult - try using a different compiler
 * to build the library!
 */
PNG_FUNCTION(void, (PNGCAPI *png_longjmp_ptr), PNGARG((jmp_buf, int)), typedef);
#endif

/* Transform masks for the high-level interface */
#define PNG_TRANSFORM_IDENTITY       0x0000    /* read and write */
#define PNG_TRANSFORM_STRIP_16       0x0001    /* read only */
#define PNG_TRANSFORM_STRIP_ALPHA    0x0002    /* read only */
#define PNG_TRANSFORM_PACKING        0x0004    /* read and write */
#define PNG_TRANSFORM_PACKSWAP       0x0008    /* read and write */
#define PNG_TRANSFORM_EXPAND         0x0010    /* read only */
#define PNG_TRANSFORM_INVERT_MONO    0x0020    /* read and write */
#define PNG_TRANSFORM_SHIFT          0x0040    /* read and write */
#define PNG_TRANSFORM_BGR            0x0080    /* read and write */
#define PNG_TRANSFORM_SWAP_ALPHA     0x0100    /* read and write */
#define PNG_TRANSFORM_SWAP_ENDIAN    0x0200    /* read and write */
#define PNG_TRANSFORM_INVERT_ALPHA   0x0400    /* read and write */
#define PNG_TRANSFORM_STRIP_FILLER   0x0800    /* write only */
/* Added to libpng-1.2.34 */
#define PNG_TRANSFORM_STRIP_FILLER_BEFORE PNG_TRANSFORM_STRIP_FILLER
#define PNG_TRANSFORM_STRIP_FILLER_AFTER 0x1000 /* write only */
/* Added to libpng-1.4.0 */
#define PNG_TRANSFORM_GRAY_TO_RGB   0x2000      /* read only */
/* Added to libpng-1.5.4 */
#define PNG_TRANSFORM_EXPAND_16     0x4000      /* read only */
#if INT_MAX >= 0x8000 /* else this might break */
#define PNG_TRANSFORM_SCALE_16      0x8000      /* read only */
#endif

/* Flags for MNG supported features */
#define PNG_FLAG_MNG_EMPTY_PLTE     0x01
#define PNG_FLAG_MNG_FILTER_64      0x04
#define PNG_ALL_MNG_FEATURES        0x05

/* NOTE: prior to 1.5 these functions had no 'API' style declaration,
 * this allowed the zlib default functions to be used on Windows
 * platforms.  In 1.5 the zlib default malloc (which just calls malloc and
 * ignores the first argument) should be completely compatible with the
 * following.
 */
typedef PNG_CALLBACK(png_voidp, *png_malloc_ptr, (png_structp,
    png_alloc_size_t));
typedef PNG_CALLBACK(void, *png_free_ptr, (png_structp, png_voidp));

/* Section 4: exported functions
 * Here are the function definitions most commonly used.  This is not
 * the place to find out how to use libpng.  See libpng-manual.txt for the
 * full explanation, see example.c for the summary.  This just provides
 * a simple one line description of the use of each function.
 *
 * The PNG_EXPORT() and PNG_EXPORTA() macros used below are defined in
 * pngconf.h and in the *.dfn files in the scripts directory.
 *
 *   PNG_EXPORT(ordinal, type, name, (args));
 *
 *       ordinal:    ordinal that is used while building
 *                   *.def files. The ordinal value is only
 *                   relevant when preprocessing png.h with
 *                   the *.dfn files for building symbol table
 *                   entries, and are removed by pngconf.h.
 *       type:       return type of the function
 *       name:       function name
 *       args:       function arguments, with types
 *
 * When we wish to append attributes to a function prototype we use
 * the PNG_EXPORTA() macro instead.
 *
 *   PNG_EXPORTA(ordinal, type, name, (args), attributes);
 *
 *       ordinal, type, name, and args: same as in PNG_EXPORT().
 *       attributes: function attributes
 */

/* Returns the version number of the library */
PNG_EXPORT(1, png_uint_32, png_access_version_number, (void));

/* Tell lib we have already handled the first <num_bytes> magic bytes.
 * Handling more than 8 bytes from the beginning of the file is an error.
 */
PNG_EXPORT(2, void, png_set_sig_bytes, (png_structrp png_ptr, int num_bytes));

/* Check sig[start] through sig[start + num_to_check - 1] to see if it's a
 * PNG file.  Returns zero if the supplied bytes match the 8-byte PNG
 * signature, and non-zero otherwise.  Having num_to_check == 0 or
 * start > 7 will always fail (ie return non-zero).
 */
PNG_EXPORT(3, int, png_sig_cmp, (png_const_bytep sig, png_size_t start,
    png_size_t num_to_check));

/* Simple signature checking function.  This is the same as calling
 * png_check_sig(sig, n) := !png_sig_cmp(sig, 0, n).
 */
#define png_check_sig(sig, n) !png_sig_cmp((sig), 0, (n))

/* Allocate and initialize png_ptr struct for reading, and any other memory. */
PNG_EXPORTA(4, png_structp, png_create_read_struct,
    (png_const_charp user_png_ver, png_voidp error_ptr,
    png_error_ptr error_fn, png_error_ptr warn_fn),
    PNG_ALLOCATED);

/* Allocate and initialize png_ptr struct for writing, and any other memory */
PNG_EXPORTA(5, png_structp, png_create_write_struct,
    (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn,
    png_error_ptr warn_fn),
    PNG_ALLOCATED);

PNG_EXPORT(6, png_size_t, png_get_compression_buffer_size,
    (png_const_structrp png_ptr));

PNG_EXPORT(7, void, png_set_compression_buffer_size, (png_structrp png_ptr,
    png_size_t size));

/* Moved from pngconf.h in 1.4.0 and modified to ensure setjmp/longjmp
 * match up.
 */
#ifdef PNG_SETJMP_SUPPORTED
/* This function returns the jmp_buf built in to *png_ptr.  It must be
 * supplied with an appropriate 'longjmp' function to use on that jmp_buf
 * unless the default error function is overridden in which case NULL is
 * acceptable.  The size of the jmp_buf is checked against the actual size
 * allocated by the library - the call will return NULL on a mismatch
 * indicating an ABI mismatch.
 */
PNG_EXPORT(8, jmp_buf*, png_set_longjmp_fn, (png_structrp png_ptr,
    png_longjmp_ptr longjmp_fn, size_t jmp_buf_size));
#  define png_jmpbuf(png_ptr) \
      (*png_set_longjmp_fn((png_ptr), longjmp, (sizeof (jmp_buf))))
#else
#  define png_jmpbuf(png_ptr) \
      (LIBPNG_WAS_COMPILED_WITH__PNG_NO_SETJMP)
#endif
/* This function should be used by libpng applications in place of
 * longjmp(png_ptr->jmpbuf, val).  If longjmp_fn() has been set, it
 * will use it; otherwise it will call PNG_ABORT().  This function was
 * added in libpng-1.5.0.
 */
PNG_EXPORTA(9, void, png_longjmp, (png_const_structrp png_ptr, int val),
    PNG_NORETURN);

#ifdef PNG_READ_SUPPORTED
/* Reset the compression stream */
PNG_EXPORTA(10, int, png_reset_zstream, (png_structrp png_ptr), PNG_DEPRECATED);
#endif

/* New functions added in libpng-1.0.2 (not enabled by default until 1.2.0) */
#ifdef PNG_USER_MEM_SUPPORTED
PNG_EXPORTA(11, png_structp, png_create_read_struct_2,
    (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn,
    png_error_ptr warn_fn,
    png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn),
    PNG_ALLOCATED);
PNG_EXPORTA(12, png_structp, png_create_write_struct_2,
    (png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn,
    png_error_ptr warn_fn,
    png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn),
    PNG_ALLOCATED);
#endif

/* Write the PNG file signature. */
PNG_EXPORT(13, void, png_write_sig, (png_structrp png_ptr));

/* Write a PNG chunk - size, type, (optional) data, CRC. */
PNG_EXPORT(14, void, png_write_chunk, (png_structrp png_ptr, png_const_bytep
    chunk_name, png_const_bytep data, png_size_t length));

/* Write the start of a PNG chunk - length and chunk name. */
PNG_EXPORT(15, void, png_write_chunk_start, (png_structrp png_ptr,
    png_const_bytep chunk_name, png_uint_32 length));

/* Write the data of a PNG chunk started with png_write_chunk_start(). */
PNG_EXPORT(16, void, png_write_chunk_data, (png_structrp png_ptr,
    png_const_bytep data, png_size_t length));

/* Finish a chunk started with png_write_chunk_start() (includes CRC). */
PNG_EXPORT(17, void, png_write_chunk_end, (png_structrp png_ptr));

/* Allocate and initialize the info structure */
PNG_EXPORTA(18, png_infop, png_create_info_struct, (png_const_structrp png_ptr),
    PNG_ALLOCATED);

/* DEPRECATED: this function allowed init structures to be created using the
 * default allocation method (typically malloc).  Use is deprecated in 1.6.0 and
 * the API will be removed in the future.
 */
PNG_EXPORTA(19, void, png_info_init_3, (png_infopp info_ptr,
    png_size_t png_info_struct_size), PNG_DEPRECATED);

/* Writes all the PNG information before the image. */
PNG_EXPORT(20, void, png_write_info_before_PLTE,
    (png_structrp png_ptr, png_const_inforp info_ptr));
PNG_EXPORT(21, void, png_write_info,
    (png_structrp png_ptr, png_const_inforp info_ptr));

#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
/* Read the information before the actual image data. */
PNG_EXPORT(22, void, png_read_info,
    (png_structrp png_ptr, png_inforp info_ptr));
#endif

#ifdef PNG_TIME_RFC1123_SUPPORTED
   /* Convert to a US string format: there is no localization support in this
    * routine.  The original implementation used a 29 character buffer in
    * png_struct, this will be removed in future versions.
    */
#if PNG_LIBPNG_VER < 10700
/* To do: remove this from libpng17 (and from libpng17/png.c and pngstruct.h) */
PNG_EXPORTA(23, png_const_charp, png_convert_to_rfc1123, (png_structrp png_ptr,
    png_const_timep ptime),PNG_DEPRECATED);
#endif
PNG_EXPORT(241, int, png_convert_to_rfc1123_buffer, (char out[29],
    png_const_timep ptime));
#endif

#ifdef PNG_CONVERT_tIME_SUPPORTED
/* Convert from a struct tm to png_time */
PNG_EXPORT(24, void, png_convert_from_struct_tm, (png_timep ptime,
    const struct tm * ttime));

/* Convert from time_t to png_time.  Uses gmtime() */
PNG_EXPORT(25, void, png_convert_from_time_t, (png_timep ptime, time_t ttime));
#endif /* CONVERT_tIME */

#ifdef PNG_READ_EXPAND_SUPPORTED
/* Expand data to 24-bit RGB, or 8-bit grayscale, with alpha if available. */
PNG_EXPORT(26, void, png_set_expand, (png_structrp png_ptr));
PNG_EXPORT(27, void, png_set_expand_gray_1_2_4_to_8, (png_structrp png_ptr));
PNG_EXPORT(28, void, png_set_palette_to_rgb, (png_structrp png_ptr));
PNG_EXPORT(29, void, png_set_tRNS_to_alpha, (png_structrp png_ptr));
#endif

#ifdef PNG_READ_EXPAND_16_SUPPORTED
/* Expand to 16-bit channels, forces conversion of palette to RGB and expansion
 * of a tRNS chunk if present.
 */
PNG_EXPORT(221, void, png_set_expand_16, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_BGR_SUPPORTED) || defined(PNG_WRITE_BGR_SUPPORTED)
/* Use blue, green, red order for pixels. */
PNG_EXPORT(30, void, png_set_bgr, (png_structrp png_ptr));
#endif

#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
/* Expand the grayscale to 24-bit RGB if necessary. */
PNG_EXPORT(31, void, png_set_gray_to_rgb, (png_structrp png_ptr));
#endif

#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
/* Reduce RGB to grayscale. */
#define PNG_ERROR_ACTION_NONE  1
#define PNG_ERROR_ACTION_WARN  2
#define PNG_ERROR_ACTION_ERROR 3
#define PNG_RGB_TO_GRAY_DEFAULT (-1)/*for red/green coefficients*/

PNG_FP_EXPORT(32, void, png_set_rgb_to_gray, (png_structrp png_ptr,
    int error_action, double red, double green))
PNG_FIXED_EXPORT(33, void, png_set_rgb_to_gray_fixed, (png_structrp png_ptr,
    int error_action, png_fixed_point red, png_fixed_point green))

PNG_EXPORT(34, png_byte, png_get_rgb_to_gray_status, (png_const_structrp
    png_ptr));
#endif

#ifdef PNG_BUILD_GRAYSCALE_PALETTE_SUPPORTED
PNG_EXPORT(35, void, png_build_grayscale_palette, (int bit_depth,
    png_colorp palette));
#endif

#ifdef PNG_READ_ALPHA_MODE_SUPPORTED
/* How the alpha channel is interpreted - this affects how the color channels
 * of a PNG file are returned to the calling application when an alpha channel,
 * or a tRNS chunk in a palette file, is present.
 *
 * This has no effect on the way pixels are written into a PNG output
 * datastream. The color samples in a PNG datastream are never premultiplied
 * with the alpha samples.
 *
 * The default is to return data according to the PNG specification: the alpha
 * channel is a linear measure of the contribution of the pixel to the
 * corresponding composited pixel, and the color channels are unassociated
 * (not premultiplied).  The gamma encoded color channels must be scaled
 * according to the contribution and to do this it is necessary to undo
 * the encoding, scale the color values, perform the composition and reencode
 * the values.  This is the 'PNG' mode.
 *
 * The alternative is to 'associate' the alpha with the color information by
 * storing color channel values that have been scaled by the alpha.
 * image.  These are the 'STANDARD', 'ASSOCIATED' or 'PREMULTIPLIED' modes
 * (the latter being the two common names for associated alpha color channels).
 *
 * For the 'OPTIMIZED' mode, a pixel is treated as opaque only if the alpha
 * value is equal to the maximum value.
 *
 * The final choice is to gamma encode the alpha channel as well.  This is
 * broken because, in practice, no implementation that uses this choice
 * correctly undoes the encoding before handling alpha composition.  Use this
 * choice only if other serious errors in the software or hardware you use
 * mandate it; the typical serious error is for dark halos to appear around
 * opaque areas of the composited PNG image because of arithmetic overflow.
 *
 * The API function png_set_alpha_mode specifies which of these choices to use
 * with an enumerated 'mode' value and the gamma of the required output:
 */
#define PNG_ALPHA_PNG           0 /* according to the PNG standard */
#define PNG_ALPHA_STANDARD      1 /* according to Porter/Duff */
#define PNG_ALPHA_ASSOCIATED    1 /* as above; this is the normal practice */
#define PNG_ALPHA_PREMULTIPLIED 1 /* as above */
#define PNG_ALPHA_OPTIMIZED     2 /* 'PNG' for opaque pixels, else 'STANDARD' */
#define PNG_ALPHA_BROKEN        3 /* the alpha channel is gamma encoded */

PNG_FP_EXPORT(227, void, png_set_alpha_mode, (png_structrp png_ptr, int mode,
    double output_gamma))
PNG_FIXED_EXPORT(228, void, png_set_alpha_mode_fixed, (png_structrp png_ptr,
    int mode, png_fixed_point output_gamma))
#endif

#if defined(PNG_GAMMA_SUPPORTED) || defined(PNG_READ_ALPHA_MODE_SUPPORTED)
/* The output_gamma value is a screen gamma in libpng terminology: it expresses
 * how to decode the output values, not how they are encoded.
 */
#define PNG_DEFAULT_sRGB -1       /* sRGB gamma and color space */
#define PNG_GAMMA_MAC_18 -2       /* Old Mac '1.8' gamma and color space */
#define PNG_GAMMA_sRGB   220000   /* Television standards--matches sRGB gamma */
#define PNG_GAMMA_LINEAR PNG_FP_1 /* Linear */
#endif

/* The following are examples of calls to png_set_alpha_mode to achieve the
 * required overall gamma correction and, where necessary, alpha
 * premultiplication.
 *
 * png_set_alpha_mode(pp, PNG_ALPHA_PNG, PNG_DEFAULT_sRGB);
 *    This is the default libpng handling of the alpha channel - it is not
 *    pre-multiplied into the color components.  In addition the call states
 *    that the output is for a sRGB system and causes all PNG files without gAMA
 *    chunks to be assumed to be encoded using sRGB.
 *
 * png_set_alpha_mode(pp, PNG_ALPHA_PNG, PNG_GAMMA_MAC);
 *    In this case the output is assumed to be something like an sRGB conformant
 *    display preceeded by a power-law lookup table of power 1.45.  This is how
 *    early Mac systems behaved.
 *
 * png_set_alpha_mode(pp, PNG_ALPHA_STANDARD, PNG_GAMMA_LINEAR);
 *    This is the classic Jim Blinn approach and will work in academic
 *    environments where everything is done by the book.  It has the shortcoming
 *    of assuming that input PNG data with no gamma information is linear - this
 *    is unlikely to be correct unless the PNG files where generated locally.
 *    Most of the time the output precision will be so low as to show
 *    significant banding in dark areas of the image.
 *
 * png_set_expand_16(pp);
 * png_set_alpha_mode(pp, PNG_ALPHA_STANDARD, PNG_DEFAULT_sRGB);
 *    This is a somewhat more realistic Jim Blinn inspired approach.  PNG files
 *    are assumed to have the sRGB encoding if not marked with a gamma value and
 *    the output is always 16 bits per component.  This permits accurate scaling
 *    and processing of the data.  If you know that your input PNG files were
 *    generated locally you might need to replace PNG_DEFAULT_sRGB with the
 *    correct value for your system.
 *
 * png_set_alpha_mode(pp, PNG_ALPHA_OPTIMIZED, PNG_DEFAULT_sRGB);
 *    If you just need to composite the PNG image onto an existing background
 *    and if you control the code that does this you can use the optimization
 *    setting.  In this case you just copy completely opaque pixels to the
 *    output.  For pixels that are not completely transparent (you just skip
 *    those) you do the composition math using png_composite or png_composite_16
 *    below then encode the resultant 8-bit or 16-bit values to match the output
 *    encoding.
 *
 * Other cases
 *    If neither the PNG nor the standard linear encoding work for you because
 *    of the software or hardware you use then you have a big problem.  The PNG
 *    case will probably result in halos around the image.  The linear encoding
 *    will probably result in a washed out, too bright, image (it's actually too
 *    contrasty.)  Try the ALPHA_OPTIMIZED mode above - this will probably
 *    substantially reduce the halos.  Alternatively try:
 *
 * png_set_alpha_mode(pp, PNG_ALPHA_BROKEN, PNG_DEFAULT_sRGB);
 *    This option will also reduce the halos, but there will be slight dark
 *    halos round the opaque parts of the image where the background is light.
 *    In the OPTIMIZED mode the halos will be light halos where the background
 *    is dark.  Take your pick - the halos are unavoidable unless you can get
 *    your hardware/software fixed!  (The OPTIMIZED approach is slightly
 *    faster.)
 *
 * When the default gamma of PNG files doesn't match the output gamma.
 *    If you have PNG files with no gamma information png_set_alpha_mode allows
 *    you to provide a default gamma, but it also sets the ouput gamma to the
 *    matching value.  If you know your PNG files have a gamma that doesn't
 *    match the output you can take advantage of the fact that
 *    png_set_alpha_mode always sets the output gamma but only sets the PNG
 *    default if it is not already set:
 *
 * png_set_alpha_mode(pp, PNG_ALPHA_PNG, PNG_DEFAULT_sRGB);
 * png_set_alpha_mode(pp, PNG_ALPHA_PNG, PNG_GAMMA_MAC);
 *    The first call sets both the default and the output gamma values, the
 *    second call overrides the output gamma without changing the default.  This
 *    is easier than achieving the same effect with png_set_gamma.  You must use
 *    PNG_ALPHA_PNG for the first call - internal checking in png_set_alpha will
 *    fire if more than one call to png_set_alpha_mode and png_set_background is
 *    made in the same read operation, however multiple calls with PNG_ALPHA_PNG
 *    are ignored.
 */

#ifdef PNG_READ_STRIP_ALPHA_SUPPORTED
PNG_EXPORT(36, void, png_set_strip_alpha, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_SWAP_ALPHA_SUPPORTED) || \
    defined(PNG_WRITE_SWAP_ALPHA_SUPPORTED)
PNG_EXPORT(37, void, png_set_swap_alpha, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_INVERT_ALPHA_SUPPORTED) || \
    defined(PNG_WRITE_INVERT_ALPHA_SUPPORTED)
PNG_EXPORT(38, void, png_set_invert_alpha, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_FILLER_SUPPORTED) || defined(PNG_WRITE_FILLER_SUPPORTED)
/* Add a filler byte to 8-bit or 16-bit Gray or 24-bit or 48-bit RGB images. */
PNG_EXPORT(39, void, png_set_filler, (png_structrp png_ptr, png_uint_32 filler,
    int flags));
/* The values of the PNG_FILLER_ defines should NOT be changed */
#  define PNG_FILLER_BEFORE 0
#  define PNG_FILLER_AFTER 1
/* Add an alpha byte to 8-bit or 16-bit Gray or 24-bit or 48-bit RGB images. */
PNG_EXPORT(40, void, png_set_add_alpha, (png_structrp png_ptr,
    png_uint_32 filler, int flags));
#endif /* READ_FILLER || WRITE_FILLER */

#if defined(PNG_READ_SWAP_SUPPORTED) || defined(PNG_WRITE_SWAP_SUPPORTED)
/* Swap bytes in 16-bit depth files. */
PNG_EXPORT(41, void, png_set_swap, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_PACK_SUPPORTED) || defined(PNG_WRITE_PACK_SUPPORTED)
/* Use 1 byte per pixel in 1, 2, or 4-bit depth files. */
PNG_EXPORT(42, void, png_set_packing, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_PACKSWAP_SUPPORTED) || \
    defined(PNG_WRITE_PACKSWAP_SUPPORTED)
/* Swap packing order of pixels in bytes. */
PNG_EXPORT(43, void, png_set_packswap, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_SHIFT_SUPPORTED) || defined(PNG_WRITE_SHIFT_SUPPORTED)
/* Converts files to legal bit depths. */
PNG_EXPORT(44, void, png_set_shift, (png_structrp png_ptr, png_const_color_8p
    true_bits));
#endif

#if defined(PNG_READ_INTERLACING_SUPPORTED) || \
    defined(PNG_WRITE_INTERLACING_SUPPORTED)
/* Have the code handle the interlacing.  Returns the number of passes.
 * MUST be called before png_read_update_info or png_start_read_image,
 * otherwise it will not have the desired effect.  Note that it is still
 * necessary to call png_read_row or png_read_rows png_get_image_height
 * times for each pass.
*/
PNG_EXPORT(45, int, png_set_interlace_handling, (png_structrp png_ptr));
#endif

#if defined(PNG_READ_INVERT_SUPPORTED) || defined(PNG_WRITE_INVERT_SUPPORTED)
/* Invert monochrome files */
PNG_EXPORT(46, void, png_set_invert_mono, (png_structrp png_ptr));
#endif

#ifdef PNG_READ_BACKGROUND_SUPPORTED
/* Handle alpha and tRNS by replacing with a background color.  Prior to
 * libpng-1.5.4 this API must not be called before the PNG file header has been
 * read.  Doing so will result in unexpected behavior and possible warnings or
 * errors if the PNG file contains a bKGD chunk.
 */
PNG_FP_EXPORT(47, void, png_set_background, (png_structrp png_ptr,
    png_const_color_16p background_color, int background_gamma_code,
    int need_expand, double background_gamma))
PNG_FIXED_EXPORT(215, void, png_set_background_fixed, (png_structrp png_ptr,
    png_const_color_16p background_color, int background_gamma_code,
    int need_expand, png_fixed_point background_gamma))
#endif
#ifdef PNG_READ_BACKGROUND_SUPPORTED
#  define PNG_BACKGROUND_GAMMA_UNKNOWN 0
#  define PNG_BACKGROUND_GAMMA_SCREEN  1
#  define PNG_BACKGROUND_GAMMA_FILE    2
#  define PNG_BACKGROUND_GAMMA_UNIQUE  3
#endif

#ifdef PNG_READ_SCALE_16_TO_8_SUPPORTED
/* Scale a 16-bit depth file down to 8-bit, accurately. */
PNG_EXPORT(229, void, png_set_scale_16, (png_structrp png_ptr));
#endif

#ifdef PNG_READ_STRIP_16_TO_8_SUPPORTED
#define PNG_READ_16_TO_8_SUPPORTED /* Name prior to 1.5.4 */
/* Strip the second byte of information from a 16-bit depth file. */
PNG_EXPORT(48, void, png_set_strip_16, (png_structrp png_ptr));
#endif

#ifdef PNG_READ_QUANTIZE_SUPPORTED
/* Turn on quantizing, and reduce the palette to the number of colors
 * available.
 */
PNG_EXPORT(49, void, png_set_quantize, (png_structrp png_ptr,
    png_colorp palette, int num_palette, int maximum_colors,
    png_const_uint_16p histogram, int full_quantize));
#endif

#ifdef PNG_READ_GAMMA_SUPPORTED
/* The threshold on gamma processing is configurable but hard-wired into the
 * library.  The following is the floating point variant.
 */
#define PNG_GAMMA_THRESHOLD (PNG_GAMMA_THRESHOLD_FIXED*.00001)

/* Handle gamma correction. Screen_gamma=(display_exponent).
 * NOTE: this API simply sets the screen and file gamma values. It will
 * therefore override the value for gamma in a PNG file if it is called after
 * the file header has been read - use with care  - call before reading the PNG
 * file for best results!
 *
 * These routines accept the same gamma values as png_set_alpha_mode (described
 * above).  The PNG_GAMMA_ defines and PNG_DEFAULT_sRGB can be passed to either
 * API (floating point or fixed.)  Notice, however, that the 'file_gamma' value
 * is the inverse of a 'screen gamma' value.
 */
PNG_FP_EXPORT(50, void, png_set_gamma, (png_structrp png_ptr,
    double screen_gamma, double override_file_gamma))
PNG_FIXED_EXPORT(208, void, png_set_gamma_fixed, (png_structrp png_ptr,
    png_fixed_point screen_gamma, png_fixed_point override_file_gamma))
#endif

#ifdef PNG_WRITE_FLUSH_SUPPORTED
/* Set how many lines between output flushes - 0 for no flushing */
PNG_EXPORT(51, void, png_set_flush, (png_structrp png_ptr, int nrows));
/* Flush the current PNG output buffer */
PNG_EXPORT(52, void, png_write_flush, (png_structrp png_ptr));
#endif

/* Optional update palette with requested transformations */
PNG_EXPORT(53, void, png_start_read_image, (png_structrp png_ptr));

/* Optional call to update the users info structure */
PNG_EXPORT(54, void, png_read_update_info, (png_structrp png_ptr,
    png_inforp info_ptr));

#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
/* Read one or more rows of image data. */
PNG_EXPORT(55, void, png_read_rows, (png_structrp png_ptr, png_bytepp row,
    png_bytepp display_row, png_uint_32 num_rows));
#endif

#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
/* Read a row of data. */
PNG_EXPORT(56, void, png_read_row, (png_structrp png_ptr, png_bytep row,
    png_bytep display_row));
#endif

#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
/* Read the whole image into memory at once. */
PNG_EXPORT(57, void, png_read_image, (png_structrp png_ptr, png_bytepp image));
#endif

/* Write a row of image data */
PNG_EXPORT(58, void, png_write_row, (png_structrp png_ptr,
    png_const_bytep row));

/* Write a few rows of image data: (*row) is not written; however, the type
 * is declared as writeable to maintain compatibility with previous versions
 * of libpng and to allow the 'display_row' array from read_rows to be passed
 * unchanged to write_rows.
 */
PNG_EXPORT(59, void, png_write_rows, (png_structrp png_ptr, png_bytepp row,
    png_uint_32 num_rows));

/* Write the image data */
PNG_EXPORT(60, void, png_write_image, (png_structrp png_ptr, png_bytepp image));

/* Write the end of the PNG file. */
PNG_EXPORT(61, void, png_write_end, (png_structrp png_ptr,
    png_inforp info_ptr));

#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
/* Read the end of the PNG file. */
PNG_EXPORT(62, void, png_read_end, (png_structrp png_ptr, png_inforp info_ptr));
#endif

/* Free any memory associated with the png_info_struct */
PNG_EXPORT(63, void, png_destroy_info_struct, (png_const_structrp png_ptr,
    png_infopp info_ptr_ptr));

/* Free any memory associated with the png_struct and the png_info_structs */
PNG_EXPORT(64, void, png_destroy_read_struct, (png_structpp png_ptr_ptr,
    png_infopp info_ptr_ptr, png_infopp end_info_ptr_ptr));

/* Free any memory associated with the png_struct and the png_info_structs */
PNG_EXPORT(65, void, png_destroy_write_struct, (png_structpp png_ptr_ptr,
    png_infopp info_ptr_ptr));

/* Set the libpng method of handling chunk CRC errors */
PNG_EXPORT(66, void, png_set_crc_action, (png_structrp png_ptr, int crit_action,
    int ancil_action));

/* Values for png_set_crc_action() say how to handle CRC errors in
 * ancillary and critical chunks, and whether to use the data contained
 * therein.  Note that it is impossible to "discard" data in a critical
 * chunk.  For versions prior to 0.90, the action was always error/quit,
 * whereas in version 0.90 and later, the action for CRC errors in ancillary
 * chunks is warn/discard.  These values should NOT be changed.
 *
 *      value                       action:critical     action:ancillary
 */
#define PNG_CRC_DEFAULT       0  /* error/quit          warn/discard data */
#define PNG_CRC_ERROR_QUIT    1  /* error/quit          error/quit        */
#define PNG_CRC_WARN_DISCARD  2  /* (INVALID)           warn/discard data */
#define PNG_CRC_WARN_USE      3  /* warn/use data       warn/use data     */
#define PNG_CRC_QUIET_USE     4  /* quiet/use data      quiet/use data    */
#define PNG_CRC_NO_CHANGE     5  /* use current value   use current value */

#ifdef PNG_WRITE_SUPPORTED
/* These functions give the user control over the scan-line filtering in
 * libpng and the compression methods used by zlib.  These functions are
 * mainly useful for testing, as the defaults should work with most users.
 * Those users who are tight on memory or want faster performance at the
 * expense of compression can modify them.  See the compression library
 * header file (zlib.h) for an explination of the compression functions.
 */

/* Set the filtering method(s) used by libpng.  Currently, the only valid
 * value for "method" is 0.
 */
PNG_EXPORT(67, void, png_set_filter, (png_structrp png_ptr, int method,
    int filters));
#endif /* WRITE */

/* Flags for png_set_filter() to say which filters to use.  The flags
 * are chosen so that they don't conflict with real filter types
 * below, in case they are supplied instead of the #defined constants.
 * These values should NOT be changed.
 */
#define PNG_NO_FILTERS     0x00
#define PNG_FILTER_NONE    0x08
#define PNG_FILTER_SUB     0x10
#define PNG_FILTER_UP      0x20
#define PNG_FILTER_AVG     0x40
#define PNG_FILTER_PAETH   0x80
#define PNG_FAST_FILTERS (PNG_FILTER_NONE | PNG_FILTER_SUB | PNG_FILTER_UP)
#define PNG_ALL_FILTERS (PNG_FAST_FILTERS | PNG_FILTER_AVG | PNG_FILTER_PAETH)

/* Filter values (not flags) - used in pngwrite.c, pngwutil.c for now.
 * These defines should NOT be changed.
 */
#define PNG_FILTER_VALUE_NONE  0
#define PNG_FILTER_VALUE_SUB   1
#define PNG_FILTER_VALUE_UP    2
#define PNG_FILTER_VALUE_AVG   3
#define PNG_FILTER_VALUE_PAETH 4
#define PNG_FILTER_VALUE_LAST  5

#ifdef PNG_WRITE_SUPPORTED
#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED /* DEPRECATED */
PNG_FP_EXPORT(68, void, png_set_filter_heuristics, (png_structrp png_ptr,
    int heuristic_method, int num_weights, png_const_doublep filter_weights,
    png_const_doublep filter_costs))
PNG_FIXED_EXPORT(209, void, png_set_filter_heuristics_fixed,
    (png_structrp png_ptr, int heuristic_method, int num_weights,
    png_const_fixed_point_p filter_weights,
    png_const_fixed_point_p filter_costs))
#endif /* WRITE_WEIGHTED_FILTER */

/* The following are no longer used and will be removed from libpng-1.7: */
#define PNG_FILTER_HEURISTIC_DEFAULT    0  /* Currently "UNWEIGHTED" */
#define PNG_FILTER_HEURISTIC_UNWEIGHTED 1  /* Used by libpng < 0.95 */
#define PNG_FILTER_HEURISTIC_WEIGHTED   2  /* Experimental feature */
#define PNG_FILTER_HEURISTIC_LAST       3  /* Not a valid value */

/* Set the library compression level.  Currently, valid values range from
 * 0 - 9, corresponding directly to the zlib compression levels 0 - 9
 * (0 - no compression, 9 - "maximal" compression).  Note that tests have
 * shown that zlib compression levels 3-6 usually perform as well as level 9
 * for PNG images, and do considerably fewer caclulations.  In the future,
 * these values may not correspond directly to the zlib compression levels.
 */
#ifdef PNG_WRITE_CUSTOMIZE_COMPRESSION_SUPPORTED
PNG_EXPORT(69, void, png_set_compression_level, (png_structrp png_ptr,
    int level));

PNG_EXPORT(70, void, png_set_compression_mem_level, (png_structrp png_ptr,
    int mem_level));

PNG_EXPORT(71, void, png_set_compression_strategy, (png_structrp png_ptr,
    int strategy));

/* If PNG_WRITE_OPTIMIZE_CMF_SUPPORTED is defined, libpng will use a
 * smaller value of window_bits if it can do so safely.
 */
PNG_EXPORT(72, void, png_set_compression_window_bits, (png_structrp png_ptr,
    int window_bits));

PNG_EXPORT(73, void, png_set_compression_method, (png_structrp png_ptr,
    int method));
#endif /* WRITE_CUSTOMIZE_COMPRESSION */

#ifdef PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED
/* Also set zlib parameters for compressing non-IDAT chunks */
PNG_EXPORT(222, void, png_set_text_compression_level, (png_structrp png_ptr,
    int level));

PNG_EXPORT(223, void, png_set_text_compression_mem_level, (png_structrp png_ptr,
    int mem_level));

PNG_EXPORT(224, void, png_set_text_compression_strategy, (png_structrp png_ptr,
    int strategy));

/* If PNG_WRITE_OPTIMIZE_CMF_SUPPORTED is defined, libpng will use a
 * smaller value of window_bits if it can do so safely.
 */
PNG_EXPORT(225, void, png_set_text_compression_window_bits,
    (png_structrp png_ptr, int window_bits));

PNG_EXPORT(226, void, png_set_text_compression_method, (png_structrp png_ptr,
    int method));
#endif /* WRITE_CUSTOMIZE_ZTXT_COMPRESSION */
#endif /* WRITE */

/* These next functions are called for input/output, memory, and error
 * handling.  They are in the file pngrio.c, pngwio.c, and pngerror.c,
 * and call standard C I/O routines such as fread(), fwrite(), and
 * fprintf().  These functions can be made to use other I/O routines
 * at run time for those applications that need to handle I/O in a
 * different manner by calling png_set_???_fn().  See libpng-manual.txt for
 * more information.
 */

#ifdef PNG_STDIO_SUPPORTED
/* Initialize the input/output for the PNG file to the default functions. */
PNG_EXPORT(74, void, png_init_io, (png_structrp png_ptr, png_FILE_p fp));
#endif

/* Replace the (error and abort), and warning functions with user
 * supplied functions.  If no messages are to be printed you must still
 * write and use replacement functions. The replacement error_fn should
 * still do a longjmp to the last setjmp location if you are using this
 * method of error handling.  If error_fn or warning_fn is NULL, the
 * default function will be used.
 */

PNG_EXPORT(75, void, png_set_error_fn, (png_structrp png_ptr,
    png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warning_fn));

/* Return the user pointer associated with the error functions */
PNG_EXPORT(76, png_voidp, png_get_error_ptr, (png_const_structrp png_ptr));

/* Replace the default data output functions with a user supplied one(s).
 * If buffered output is not used, then output_flush_fn can be set to NULL.
 * If PNG_WRITE_FLUSH_SUPPORTED is not defined at libpng compile time
 * output_flush_fn will be ignored (and thus can be NULL).
 * It is probably a mistake to use NULL for output_flush_fn if
 * write_data_fn is not also NULL unless you have built libpng with
 * PNG_WRITE_FLUSH_SUPPORTED undefined, because in this case libpng's
 * default flush function, which uses the standard *FILE structure, will
 * be used.
 */
PNG_EXPORT(77, void, png_set_write_fn, (png_structrp png_ptr, png_voidp io_ptr,
    png_rw_ptr write_data_fn, png_flush_ptr output_flush_fn));

/* Replace the default data input function with a user supplied one. */
PNG_EXPORT(78, void, png_set_read_fn, (png_structrp png_ptr, png_voidp io_ptr,
    png_rw_ptr read_data_fn));

/* Return the user pointer associated with the I/O functions */
PNG_EXPORT(79, png_voidp, png_get_io_ptr, (png_const_structrp png_ptr));

PNG_EXPORT(80, void, png_set_read_status_fn, (png_structrp png_ptr,
    png_read_status_ptr read_row_fn));

PNG_EXPORT(81, void, png_set_write_status_fn, (png_structrp png_ptr,
    png_write_status_ptr write_row_fn));

#ifdef PNG_USER_MEM_SUPPORTED
/* Replace the default memory allocation functions with user supplied one(s). */
PNG_EXPORT(82, void, png_set_mem_fn, (png_structrp png_ptr, png_voidp mem_ptr,
    png_malloc_ptr malloc_fn, png_free_ptr free_fn));
/* Return the user pointer associated with the memory functions */
PNG_EXPORT(83, png_voidp, png_get_mem_ptr, (png_const_structrp png_ptr));
#endif

#ifdef PNG_READ_USER_TRANSFORM_SUPPORTED
PNG_EXPORT(84, void, png_set_read_user_transform_fn, (png_structrp png_ptr,
    png_user_transform_ptr read_user_transform_fn));
#endif

#ifdef PNG_WRITE_USER_TRANSFORM_SUPPORTED
PNG_EXPORT(85, void, png_set_write_user_transform_fn, (png_structrp png_ptr,
    png_user_transform_ptr write_user_transform_fn));
#endif

#ifdef PNG_USER_TRANSFORM_PTR_SUPPORTED
PNG_EXPORT(86, void, png_set_user_transform_info, (png_structrp png_ptr,
    png_voidp user_transform_ptr, int user_transform_depth,
    int user_transform_channels));
/* Return the user pointer associated with the user transform functions */
PNG_EXPORT(87, png_voidp, png_get_user_transform_ptr,
    (png_const_structrp png_ptr));
#endif

#ifdef PNG_USER_TRANSFORM_INFO_SUPPORTED
/* Return information about the row currently being processed.  Note that these
 * APIs do not fail but will return unexpected results if called outside a user
 * transform callback.  Also note that when transforming an interlaced image the
 * row number is the row number within the sub-image of the interlace pass, so
 * the value will increase to the height of the sub-image (not the full image)
 * then reset to 0 for the next pass.
 *
 * Use PNG_ROW_FROM_PASS_ROW(row, pass) and PNG_COL_FROM_PASS_COL(col, pass) to
 * find the output pixel (x,y) given an interlaced sub-image pixel
 * (row,col,pass).  (See below for these macros.)
 */
PNG_EXPORT(217, png_uint_32, png_get_current_row_number, (png_const_structrp));
PNG_EXPORT(218, png_byte, png_get_current_pass_number, (png_const_structrp));
#endif

#ifdef PNG_READ_USER_CHUNKS_SUPPORTED
/* This callback is called only for *unknown* chunks.  If
 * PNG_HANDLE_AS_UNKNOWN_SUPPORTED is set then it is possible to set known
 * chunks to be treated as unknown, however in this case the callback must do
 * any processing required by the chunk (e.g. by calling the appropriate
 * png_set_ APIs.)
 *
 * There is no write support - on write, by default, all the chunks in the
 * 'unknown' list are written in the specified position.
 *
 * The integer return from the callback function is interpreted thus:
 *
 * negative: An error occurred; png_chunk_error will be called.
 *     zero: The chunk was not handled, the chunk will be saved. A critical
 *           chunk will cause an error at this point unless it is to be saved.
 * positive: The chunk was handled, libpng will ignore/discard it.
 *
 * See "INTERACTION WTIH USER CHUNK CALLBACKS" below for important notes about
 * how this behavior will change in libpng 1.7
 */
PNG_EXPORT(88, void, png_set_read_user_chunk_fn, (png_structrp png_ptr,
    png_voidp user_chunk_ptr, png_user_chunk_ptr read_user_chunk_fn));
#endif

#ifdef PNG_USER_CHUNKS_SUPPORTED
PNG_EXPORT(89, png_voidp, png_get_user_chunk_ptr, (png_const_structrp png_ptr));
#endif

#ifdef PNG_PROGRESSIVE_READ_SUPPORTED
/* Sets the function callbacks for the push reader, and a pointer to a
 * user-defined structure available to the callback functions.
 */
PNG_EXPORT(90, void, png_set_progressive_read_fn, (png_structrp png_ptr,
    png_voidp progressive_ptr, png_progressive_info_ptr info_fn,
    png_progressive_row_ptr row_fn, png_progressive_end_ptr end_fn));

/* Returns the user pointer associated with the push read functions */
PNG_EXPORT(91, png_voidp, png_get_progressive_ptr,
    (png_const_structrp png_ptr));

/* Function to be called when data becomes available */
PNG_EXPORT(92, void, png_process_data, (png_structrp png_ptr,
    png_inforp info_ptr, png_bytep buffer, png_size_t buffer_size));

/* A function which may be called *only* within png_process_data to stop the
 * processing of any more data.  The function returns the number of bytes
 * remaining, excluding any that libpng has cached internally.  A subsequent
 * call to png_process_data must supply these bytes again.  If the argument
 * 'save' is set to true the routine will first save all the pending data and
 * will always return 0.
 */
PNG_EXPORT(219, png_size_t, png_process_data_pause, (png_structrp, int save));

/* A function which may be called *only* outside (after) a call to
 * png_process_data.  It returns the number of bytes of data to skip in the
 * input.  Normally it will return 0, but if it returns a non-zero value the
 * application must skip than number of bytes of input data and pass the
 * following data to the next call to png_process_data.
 */
PNG_EXPORT(220, png_uint_32, png_process_data_skip, (png_structrp));

/* Function that combines rows.  'new_row' is a flag that should come from
 * the callback and be non-NULL if anything needs to be done; the library
 * stores its own version of the new data internally and ignores the passed
 * in value.
 */
PNG_EXPORT(93, void, png_progressive_combine_row, (png_const_structrp png_ptr,
    png_bytep old_row, png_const_bytep new_row));
#endif /* PROGRESSIVE_READ */

PNG_EXPORTA(94, png_voidp, png_malloc, (png_const_structrp png_ptr,
    png_alloc_size_t size), PNG_ALLOCATED);
/* Added at libpng version 1.4.0 */
PNG_EXPORTA(95, png_voidp, png_calloc, (png_const_structrp png_ptr,
    png_alloc_size_t size), PNG_ALLOCATED);

/* Added at libpng version 1.2.4 */
PNG_EXPORTA(96, png_voidp, png_malloc_warn, (png_const_structrp png_ptr,
    png_alloc_size_t size), PNG_ALLOCATED);

/* Frees a pointer allocated by png_malloc() */
PNG_EXPORT(97, void, png_free, (png_const_structrp png_ptr, png_voidp ptr));

/* Free data that was allocated internally */
PNG_EXPORT(98, void, png_free_data, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_uint_32 free_me, int num));

/* Reassign responsibility for freeing existing data, whether allocated
 * by libpng or by the application; this works on the png_info structure passed
 * in, it does not change the state for other png_info structures.
 *
 * It is unlikely that this function works correctly as of 1.6.0 and using it
 * may result either in memory leaks or double free of allocated data.
 */
PNG_EXPORT(99, void, png_data_freer, (png_const_structrp png_ptr,
    png_inforp info_ptr, int freer, png_uint_32 mask));

/* Assignments for png_data_freer */
#define PNG_DESTROY_WILL_FREE_DATA 1
#define PNG_SET_WILL_FREE_DATA 1
#define PNG_USER_WILL_FREE_DATA 2
/* Flags for png_ptr->free_me and info_ptr->free_me */
#define PNG_FREE_HIST 0x0008U
#define PNG_FREE_ICCP 0x0010U
#define PNG_FREE_SPLT 0x0020U
#define PNG_FREE_ROWS 0x0040U
#define PNG_FREE_PCAL 0x0080U
#define PNG_FREE_SCAL 0x0100U
#ifdef PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED
#  define PNG_FREE_UNKN 0x0200U
#endif
/*      PNG_FREE_LIST 0x0400U   removed in 1.6.0 because it is ignored */
#define PNG_FREE_PLTE 0x1000U
#define PNG_FREE_TRNS 0x2000U
#define PNG_FREE_TEXT 0x4000U
#define PNG_FREE_ALL  0x7fffU
#define PNG_FREE_MUL  0x4220U /* PNG_FREE_SPLT|PNG_FREE_TEXT|PNG_FREE_UNKN */

#ifdef PNG_USER_MEM_SUPPORTED
PNG_EXPORTA(100, png_voidp, png_malloc_default, (png_const_structrp png_ptr,
    png_alloc_size_t size), PNG_ALLOCATED PNG_DEPRECATED);
PNG_EXPORTA(101, void, png_free_default, (png_const_structrp png_ptr,
    png_voidp ptr), PNG_DEPRECATED);
#endif

#ifdef PNG_ERROR_TEXT_SUPPORTED
/* Fatal error in PNG image of libpng - can't continue */
PNG_EXPORTA(102, void, png_error, (png_const_structrp png_ptr,
    png_const_charp error_message), PNG_NORETURN);

/* The same, but the chunk name is prepended to the error string. */
PNG_EXPORTA(103, void, png_chunk_error, (png_const_structrp png_ptr,
    png_const_charp error_message), PNG_NORETURN);

#else
/* Fatal error in PNG image of libpng - can't continue */
PNG_EXPORTA(104, void, png_err, (png_const_structrp png_ptr), PNG_NORETURN);
#  define png_error(s1,s2) png_err(s1)
#  define png_chunk_error(s1,s2) png_err(s1)
#endif

#ifdef PNG_WARNINGS_SUPPORTED
/* Non-fatal error in libpng.  Can continue, but may have a problem. */
PNG_EXPORT(105, void, png_warning, (png_const_structrp png_ptr,
    png_const_charp warning_message));

/* Non-fatal error in libpng, chunk name is prepended to message. */
PNG_EXPORT(106, void, png_chunk_warning, (png_const_structrp png_ptr,
    png_const_charp warning_message));
#else
#  define png_warning(s1,s2) ((void)(s1))
#  define png_chunk_warning(s1,s2) ((void)(s1))
#endif

#ifdef PNG_BENIGN_ERRORS_SUPPORTED
/* Benign error in libpng.  Can continue, but may have a problem.
 * User can choose whether to handle as a fatal error or as a warning. */
PNG_EXPORT(107, void, png_benign_error, (png_const_structrp png_ptr,
    png_const_charp warning_message));

#ifdef PNG_READ_SUPPORTED
/* Same, chunk name is prepended to message (only during read) */
PNG_EXPORT(108, void, png_chunk_benign_error, (png_const_structrp png_ptr,
    png_const_charp warning_message));
#endif

PNG_EXPORT(109, void, png_set_benign_errors,
    (png_structrp png_ptr, int allowed));
#else
#  ifdef PNG_ALLOW_BENIGN_ERRORS
#    define png_benign_error png_warning
#    define png_chunk_benign_error png_chunk_warning
#  else
#    define png_benign_error png_error
#    define png_chunk_benign_error png_chunk_error
#  endif
#endif

/* The png_set_<chunk> functions are for storing values in the png_info_struct.
 * Similarly, the png_get_<chunk> calls are used to read values from the
 * png_info_struct, either storing the parameters in the passed variables, or
 * setting pointers into the png_info_struct where the data is stored.  The
 * png_get_<chunk> functions return a non-zero value if the data was available
 * in info_ptr, or return zero and do not change any of the parameters if the
 * data was not available.
 *
 * These functions should be used instead of directly accessing png_info
 * to avoid problems with future changes in the size and internal layout of
 * png_info_struct.
 */
/* Returns "flag" if chunk data is valid in info_ptr. */
PNG_EXPORT(110, png_uint_32, png_get_valid, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, png_uint_32 flag));

/* Returns number of bytes needed to hold a transformed row. */
PNG_EXPORT(111, png_size_t, png_get_rowbytes, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

#ifdef PNG_INFO_IMAGE_SUPPORTED
/* Returns row_pointers, which is an array of pointers to scanlines that was
 * returned from png_read_png().
 */
PNG_EXPORT(112, png_bytepp, png_get_rows, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Set row_pointers, which is an array of pointers to scanlines for use
 * by png_write_png().
 */
PNG_EXPORT(113, void, png_set_rows, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_bytepp row_pointers));
#endif

/* Returns number of color channels in image. */
PNG_EXPORT(114, png_byte, png_get_channels, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

#ifdef PNG_EASY_ACCESS_SUPPORTED
/* Returns image width in pixels. */
PNG_EXPORT(115, png_uint_32, png_get_image_width, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image height in pixels. */
PNG_EXPORT(116, png_uint_32, png_get_image_height, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image bit_depth. */
PNG_EXPORT(117, png_byte, png_get_bit_depth, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image color_type. */
PNG_EXPORT(118, png_byte, png_get_color_type, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image filter_type. */
PNG_EXPORT(119, png_byte, png_get_filter_type, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image interlace_type. */
PNG_EXPORT(120, png_byte, png_get_interlace_type, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image compression_type. */
PNG_EXPORT(121, png_byte, png_get_compression_type, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));

/* Returns image resolution in pixels per meter, from pHYs chunk data. */
PNG_EXPORT(122, png_uint_32, png_get_pixels_per_meter,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));
PNG_EXPORT(123, png_uint_32, png_get_x_pixels_per_meter,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));
PNG_EXPORT(124, png_uint_32, png_get_y_pixels_per_meter,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));

/* Returns pixel aspect ratio, computed from pHYs chunk data.  */
PNG_FP_EXPORT(125, float, png_get_pixel_aspect_ratio,
    (png_const_structrp png_ptr, png_const_inforp info_ptr))
PNG_FIXED_EXPORT(210, png_fixed_point, png_get_pixel_aspect_ratio_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr))

/* Returns image x, y offset in pixels or microns, from oFFs chunk data. */
PNG_EXPORT(126, png_int_32, png_get_x_offset_pixels,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));
PNG_EXPORT(127, png_int_32, png_get_y_offset_pixels,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));
PNG_EXPORT(128, png_int_32, png_get_x_offset_microns,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));
PNG_EXPORT(129, png_int_32, png_get_y_offset_microns,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));

#endif /* EASY_ACCESS */

#ifdef PNG_READ_SUPPORTED
/* Returns pointer to signature string read from PNG header */
PNG_EXPORT(130, png_const_bytep, png_get_signature, (png_const_structrp png_ptr,
    png_const_inforp info_ptr));
#endif

#ifdef PNG_bKGD_SUPPORTED
PNG_EXPORT(131, png_uint_32, png_get_bKGD, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_color_16p *background));
#endif

#ifdef PNG_bKGD_SUPPORTED
PNG_EXPORT(132, void, png_set_bKGD, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_color_16p background));
#endif

#ifdef PNG_cHRM_SUPPORTED
PNG_FP_EXPORT(133, png_uint_32, png_get_cHRM, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, double *white_x, double *white_y, double *red_x,
    double *red_y, double *green_x, double *green_y, double *blue_x,
    double *blue_y))
PNG_FP_EXPORT(230, png_uint_32, png_get_cHRM_XYZ, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, double *red_X, double *red_Y, double *red_Z,
    double *green_X, double *green_Y, double *green_Z, double *blue_X,
    double *blue_Y, double *blue_Z))
PNG_FIXED_EXPORT(134, png_uint_32, png_get_cHRM_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr,
    png_fixed_point *int_white_x, png_fixed_point *int_white_y,
    png_fixed_point *int_red_x, png_fixed_point *int_red_y,
    png_fixed_point *int_green_x, png_fixed_point *int_green_y,
    png_fixed_point *int_blue_x, png_fixed_point *int_blue_y))
PNG_FIXED_EXPORT(231, png_uint_32, png_get_cHRM_XYZ_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr,
    png_fixed_point *int_red_X, png_fixed_point *int_red_Y,
    png_fixed_point *int_red_Z, png_fixed_point *int_green_X,
    png_fixed_point *int_green_Y, png_fixed_point *int_green_Z,
    png_fixed_point *int_blue_X, png_fixed_point *int_blue_Y,
    png_fixed_point *int_blue_Z))
#endif

#ifdef PNG_cHRM_SUPPORTED
PNG_FP_EXPORT(135, void, png_set_cHRM, (png_const_structrp png_ptr,
    png_inforp info_ptr,
    double white_x, double white_y, double red_x, double red_y, double green_x,
    double green_y, double blue_x, double blue_y))
PNG_FP_EXPORT(232, void, png_set_cHRM_XYZ, (png_const_structrp png_ptr,
    png_inforp info_ptr, double red_X, double red_Y, double red_Z,
    double green_X, double green_Y, double green_Z, double blue_X,
    double blue_Y, double blue_Z))
PNG_FIXED_EXPORT(136, void, png_set_cHRM_fixed, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_fixed_point int_white_x,
    png_fixed_point int_white_y, png_fixed_point int_red_x,
    png_fixed_point int_red_y, png_fixed_point int_green_x,
    png_fixed_point int_green_y, png_fixed_point int_blue_x,
    png_fixed_point int_blue_y))
PNG_FIXED_EXPORT(233, void, png_set_cHRM_XYZ_fixed, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_fixed_point int_red_X, png_fixed_point int_red_Y,
    png_fixed_point int_red_Z, png_fixed_point int_green_X,
    png_fixed_point int_green_Y, png_fixed_point int_green_Z,
    png_fixed_point int_blue_X, png_fixed_point int_blue_Y,
    png_fixed_point int_blue_Z))
#endif

#ifdef PNG_gAMA_SUPPORTED
PNG_FP_EXPORT(137, png_uint_32, png_get_gAMA, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, double *file_gamma))
PNG_FIXED_EXPORT(138, png_uint_32, png_get_gAMA_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr,
    png_fixed_point *int_file_gamma))
#endif

#ifdef PNG_gAMA_SUPPORTED
PNG_FP_EXPORT(139, void, png_set_gAMA, (png_const_structrp png_ptr,
    png_inforp info_ptr, double file_gamma))
PNG_FIXED_EXPORT(140, void, png_set_gAMA_fixed, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_fixed_point int_file_gamma))
#endif

#ifdef PNG_hIST_SUPPORTED
PNG_EXPORT(141, png_uint_32, png_get_hIST, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_uint_16p *hist));
#endif

#ifdef PNG_hIST_SUPPORTED
PNG_EXPORT(142, void, png_set_hIST, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_uint_16p hist));
#endif

PNG_EXPORT(143, png_uint_32, png_get_IHDR, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, png_uint_32 *width, png_uint_32 *height,
    int *bit_depth, int *color_type, int *interlace_method,
    int *compression_method, int *filter_method));

PNG_EXPORT(144, void, png_set_IHDR, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth,
    int color_type, int interlace_method, int compression_method,
    int filter_method));

#ifdef PNG_oFFs_SUPPORTED
PNG_EXPORT(145, png_uint_32, png_get_oFFs, (png_const_structrp png_ptr,
   png_const_inforp info_ptr, png_int_32 *offset_x, png_int_32 *offset_y,
   int *unit_type));
#endif

#ifdef PNG_oFFs_SUPPORTED
PNG_EXPORT(146, void, png_set_oFFs, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_int_32 offset_x, png_int_32 offset_y,
    int unit_type));
#endif

#ifdef PNG_pCAL_SUPPORTED
PNG_EXPORT(147, png_uint_32, png_get_pCAL, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_charp *purpose, png_int_32 *X0,
    png_int_32 *X1, int *type, int *nparams, png_charp *units,
    png_charpp *params));
#endif

#ifdef PNG_pCAL_SUPPORTED
PNG_EXPORT(148, void, png_set_pCAL, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_charp purpose, png_int_32 X0, png_int_32 X1,
    int type, int nparams, png_const_charp units, png_charpp params));
#endif

#ifdef PNG_pHYs_SUPPORTED
PNG_EXPORT(149, png_uint_32, png_get_pHYs, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, png_uint_32 *res_x, png_uint_32 *res_y,
    int *unit_type));
#endif

#ifdef PNG_pHYs_SUPPORTED
PNG_EXPORT(150, void, png_set_pHYs, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_uint_32 res_x, png_uint_32 res_y, int unit_type));
#endif

PNG_EXPORT(151, png_uint_32, png_get_PLTE, (png_const_structrp png_ptr,
   png_inforp info_ptr, png_colorp *palette, int *num_palette));

PNG_EXPORT(152, void, png_set_PLTE, (png_structrp png_ptr,
    png_inforp info_ptr, png_const_colorp palette, int num_palette));

#ifdef PNG_sBIT_SUPPORTED
PNG_EXPORT(153, png_uint_32, png_get_sBIT, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_color_8p *sig_bit));
#endif

#ifdef PNG_sBIT_SUPPORTED
PNG_EXPORT(154, void, png_set_sBIT, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_color_8p sig_bit));
#endif

#ifdef PNG_sRGB_SUPPORTED
PNG_EXPORT(155, png_uint_32, png_get_sRGB, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, int *file_srgb_intent));
#endif

#ifdef PNG_sRGB_SUPPORTED
PNG_EXPORT(156, void, png_set_sRGB, (png_const_structrp png_ptr,
    png_inforp info_ptr, int srgb_intent));
PNG_EXPORT(157, void, png_set_sRGB_gAMA_and_cHRM, (png_const_structrp png_ptr,
    png_inforp info_ptr, int srgb_intent));
#endif

#ifdef PNG_iCCP_SUPPORTED
PNG_EXPORT(158, png_uint_32, png_get_iCCP, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_charpp name, int *compression_type,
    png_bytepp profile, png_uint_32 *proflen));
#endif

#ifdef PNG_iCCP_SUPPORTED
PNG_EXPORT(159, void, png_set_iCCP, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_charp name, int compression_type,
    png_const_bytep profile, png_uint_32 proflen));
#endif

#ifdef PNG_sPLT_SUPPORTED
PNG_EXPORT(160, int, png_get_sPLT, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_sPLT_tpp entries));
#endif

#ifdef PNG_sPLT_SUPPORTED
PNG_EXPORT(161, void, png_set_sPLT, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_sPLT_tp entries, int nentries));
#endif

#ifdef PNG_TEXT_SUPPORTED
/* png_get_text also returns the number of text chunks in *num_text */
PNG_EXPORT(162, int, png_get_text, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_textp *text_ptr, int *num_text));
#endif

/* Note while png_set_text() will accept a structure whose text,
 * language, and  translated keywords are NULL pointers, the structure
 * returned by png_get_text will always contain regular
 * zero-terminated C strings.  They might be empty strings but
 * they will never be NULL pointers.
 */

#ifdef PNG_TEXT_SUPPORTED
PNG_EXPORT(163, void, png_set_text, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_textp text_ptr, int num_text));
#endif

#ifdef PNG_tIME_SUPPORTED
PNG_EXPORT(164, png_uint_32, png_get_tIME, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_timep *mod_time));
#endif

#ifdef PNG_tIME_SUPPORTED
PNG_EXPORT(165, void, png_set_tIME, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_timep mod_time));
#endif

#ifdef PNG_tRNS_SUPPORTED
PNG_EXPORT(166, png_uint_32, png_get_tRNS, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_bytep *trans_alpha, int *num_trans,
    png_color_16p *trans_color));
#endif

#ifdef PNG_tRNS_SUPPORTED
PNG_EXPORT(167, void, png_set_tRNS, (png_structrp png_ptr,
    png_inforp info_ptr, png_const_bytep trans_alpha, int num_trans,
    png_const_color_16p trans_color));
#endif

#ifdef PNG_sCAL_SUPPORTED
PNG_FP_EXPORT(168, png_uint_32, png_get_sCAL, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, int *unit, double *width, double *height))
#if defined(PNG_FLOATING_ARITHMETIC_SUPPORTED) || \
   defined(PNG_FLOATING_POINT_SUPPORTED)
/* NOTE: this API is currently implemented using floating point arithmetic,
 * consequently it can only be used on systems with floating point support.
 * In any case the range of values supported by png_fixed_point is small and it
 * is highly recommended that png_get_sCAL_s be used instead.
 */
PNG_FIXED_EXPORT(214, png_uint_32, png_get_sCAL_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr, int *unit,
    png_fixed_point *width, png_fixed_point *height))
#endif
PNG_EXPORT(169, png_uint_32, png_get_sCAL_s,
    (png_const_structrp png_ptr, png_const_inforp info_ptr, int *unit,
    png_charpp swidth, png_charpp sheight));

PNG_FP_EXPORT(170, void, png_set_sCAL, (png_const_structrp png_ptr,
    png_inforp info_ptr, int unit, double width, double height))
PNG_FIXED_EXPORT(213, void, png_set_sCAL_fixed, (png_const_structrp png_ptr,
   png_inforp info_ptr, int unit, png_fixed_point width,
   png_fixed_point height))
PNG_EXPORT(171, void, png_set_sCAL_s, (png_const_structrp png_ptr,
    png_inforp info_ptr, int unit,
    png_const_charp swidth, png_const_charp sheight));
#endif /* sCAL */

#ifdef PNG_SET_UNKNOWN_CHUNKS_SUPPORTED
/* Provide the default handling for all unknown chunks or, optionally, for
 * specific unknown chunks.
 *
 * NOTE: prior to 1.6.0 the handling specified for particular chunks on read was
 * ignored and the default was used, the per-chunk setting only had an effect on
 * write.  If you wish to have chunk-specific handling on read in code that must
 * work on earlier versions you must use a user chunk callback to specify the
 * desired handling (keep or discard.)
 *
 * The 'keep' parameter is a PNG_HANDLE_CHUNK_ value as listed below.  The
 * parameter is interpreted as follows:
 *
 * READ:
 *    PNG_HANDLE_CHUNK_AS_DEFAULT:
 *       Known chunks: do normal libpng processing, do not keep the chunk (but
 *          see the comments below about PNG_HANDLE_AS_UNKNOWN_SUPPORTED)
 *       Unknown chunks: for a specific chunk use the global default, when used
 *          as the default discard the chunk data.
 *    PNG_HANDLE_CHUNK_NEVER:
 *       Discard the chunk data.
 *    PNG_HANDLE_CHUNK_IF_SAFE:
 *       Keep the chunk data if the chunk is not critical else raise a chunk
 *       error.
 *    PNG_HANDLE_CHUNK_ALWAYS:
 *       Keep the chunk data.
 *
 * If the chunk data is saved it can be retrieved using png_get_unknown_chunks,
 * below.  Notice that specifying "AS_DEFAULT" as a global default is equivalent
 * to specifying "NEVER", however when "AS_DEFAULT" is used for specific chunks
 * it simply resets the behavior to the libpng default.
 *
 * INTERACTION WTIH USER CHUNK CALLBACKS:
 * The per-chunk handling is always used when there is a png_user_chunk_ptr
 * callback and the callback returns 0; the chunk is then always stored *unless*
 * it is critical and the per-chunk setting is other than ALWAYS.  Notice that
 * the global default is *not* used in this case.  (In effect the per-chunk
 * value is incremented to at least IF_SAFE.)
 *
 * IMPORTANT NOTE: this behavior will change in libpng 1.7 - the global and
 * per-chunk defaults will be honored.  If you want to preserve the current
 * behavior when your callback returns 0 you must set PNG_HANDLE_CHUNK_IF_SAFE
 * as the default - if you don't do this libpng 1.6 will issue a warning.
 *
 * If you want unhandled unknown chunks to be discarded in libpng 1.6 and
 * earlier simply return '1' (handled).
 *
 * PNG_HANDLE_AS_UNKNOWN_SUPPORTED:
 *    If this is *not* set known chunks will always be handled by libpng and
 *    will never be stored in the unknown chunk list.  Known chunks listed to
 *    png_set_keep_unknown_chunks will have no effect.  If it is set then known
 *    chunks listed with a keep other than AS_DEFAULT will *never* be processed
 *    by libpng, in addition critical chunks must either be processed by the
 *    callback or saved.
 *
 *    The IHDR and IEND chunks must not be listed.  Because this turns off the
 *    default handling for chunks that would otherwise be recognized the
 *    behavior of libpng transformations may well become incorrect!
 *
 * WRITE:
 *    When writing chunks the options only apply to the chunks specified by
 *    png_set_unknown_chunks (below), libpng will *always* write known chunks
 *    required by png_set_ calls and will always write the core critical chunks
 *    (as required for PLTE).
 *
 *    Each chunk in the png_set_unknown_chunks list is looked up in the
 *    png_set_keep_unknown_chunks list to find the keep setting, this is then
 *    interpreted as follows:
 *
 *    PNG_HANDLE_CHUNK_AS_DEFAULT:
 *       Write safe-to-copy chunks and write other chunks if the global
 *       default is set to _ALWAYS, otherwise don't write this chunk.
 *    PNG_HANDLE_CHUNK_NEVER:
 *       Do not write the chunk.
 *    PNG_HANDLE_CHUNK_IF_SAFE:
 *       Write the chunk if it is safe-to-copy, otherwise do not write it.
 *    PNG_HANDLE_CHUNK_ALWAYS:
 *       Write the chunk.
 *
 * Note that the default behavior is effectively the opposite of the read case -
 * in read unknown chunks are not stored by default, in write they are written
 * by default.  Also the behavior of PNG_HANDLE_CHUNK_IF_SAFE is very different
 * - on write the safe-to-copy bit is checked, on read the critical bit is
 * checked and on read if the chunk is critical an error will be raised.
 *
 * num_chunks:
 * ===========
 *    If num_chunks is positive, then the "keep" parameter specifies the manner
 *    for handling only those chunks appearing in the chunk_list array,
 *    otherwise the chunk list array is ignored.
 *
 *    If num_chunks is 0 the "keep" parameter specifies the default behavior for
 *    unknown chunks, as described above.
 *
 *    If num_chunks is negative, then the "keep" parameter specifies the manner
 *    for handling all unknown chunks plus all chunks recognized by libpng
 *    except for the IHDR, PLTE, tRNS, IDAT, and IEND chunks (which continue to
 *    be processed by libpng.
 */
PNG_EXPORT(172, void, png_set_keep_unknown_chunks, (png_structrp png_ptr,
    int keep, png_const_bytep chunk_list, int num_chunks));

/* The "keep" PNG_HANDLE_CHUNK_ parameter for the specified chunk is returned;
 * the result is therefore true (non-zero) if special handling is required,
 * false for the default handling.
 */
PNG_EXPORT(173, int, png_handle_as_unknown, (png_const_structrp png_ptr,
    png_const_bytep chunk_name));
#endif

#ifdef PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED
PNG_EXPORT(174, void, png_set_unknown_chunks, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_const_unknown_chunkp unknowns,
    int num_unknowns));
   /* NOTE: prior to 1.6.0 this routine set the 'location' field of the added
    * unknowns to the location currently stored in the png_struct.  This is
    * invariably the wrong value on write.  To fix this call the following API
    * for each chunk in the list with the correct location.  If you know your
    * code won't be compiled on earlier versions you can rely on
    * png_set_unknown_chunks(write-ptr, png_get_unknown_chunks(read-ptr)) doing
    * the correct thing.
    */

PNG_EXPORT(175, void, png_set_unknown_chunk_location,
    (png_const_structrp png_ptr, png_inforp info_ptr, int chunk, int location));

PNG_EXPORT(176, int, png_get_unknown_chunks, (png_const_structrp png_ptr,
    png_inforp info_ptr, png_unknown_chunkpp entries));
#endif

/* Png_free_data() will turn off the "valid" flag for anything it frees.
 * If you need to turn it off for a chunk that your application has freed,
 * you can use png_set_invalid(png_ptr, info_ptr, PNG_INFO_CHNK);
 */
PNG_EXPORT(177, void, png_set_invalid, (png_const_structrp png_ptr,
    png_inforp info_ptr, int mask));

#ifdef PNG_INFO_IMAGE_SUPPORTED
/* The "params" pointer is currently not used and is for future expansion. */
#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
PNG_EXPORT(178, void, png_read_png, (png_structrp png_ptr, png_inforp info_ptr,
    int transforms, png_voidp params));
#endif
#ifdef PNG_WRITE_SUPPORTED
PNG_EXPORT(179, void, png_write_png, (png_structrp png_ptr, png_inforp info_ptr,
    int transforms, png_voidp params));
#endif
#endif

PNG_EXPORT(180, png_const_charp, png_get_copyright,
    (png_const_structrp png_ptr));
PNG_EXPORT(181, png_const_charp, png_get_header_ver,
    (png_const_structrp png_ptr));
PNG_EXPORT(182, png_const_charp, png_get_header_version,
    (png_const_structrp png_ptr));
PNG_EXPORT(183, png_const_charp, png_get_libpng_ver,
    (png_const_structrp png_ptr));

#ifdef PNG_MNG_FEATURES_SUPPORTED
PNG_EXPORT(184, png_uint_32, png_permit_mng_features, (png_structrp png_ptr,
    png_uint_32 mng_features_permitted));
#endif

/* For use in png_set_keep_unknown, added to version 1.2.6 */
#define PNG_HANDLE_CHUNK_AS_DEFAULT   0
#define PNG_HANDLE_CHUNK_NEVER        1
#define PNG_HANDLE_CHUNK_IF_SAFE      2
#define PNG_HANDLE_CHUNK_ALWAYS       3
#define PNG_HANDLE_CHUNK_LAST         4

/* Strip the prepended error numbers ("#nnn ") from error and warning
 * messages before passing them to the error or warning handler.
 */
#ifdef PNG_ERROR_NUMBERS_SUPPORTED
PNG_EXPORT(185, void, png_set_strip_error_numbers, (png_structrp png_ptr,
    png_uint_32 strip_mode));
#endif

/* Added in libpng-1.2.6 */
#ifdef PNG_SET_USER_LIMITS_SUPPORTED
PNG_EXPORT(186, void, png_set_user_limits, (png_structrp png_ptr,
    png_uint_32 user_width_max, png_uint_32 user_height_max));
PNG_EXPORT(187, png_uint_32, png_get_user_width_max,
    (png_const_structrp png_ptr));
PNG_EXPORT(188, png_uint_32, png_get_user_height_max,
    (png_const_structrp png_ptr));
/* Added in libpng-1.4.0 */
PNG_EXPORT(189, void, png_set_chunk_cache_max, (png_structrp png_ptr,
    png_uint_32 user_chunk_cache_max));
PNG_EXPORT(190, png_uint_32, png_get_chunk_cache_max,
    (png_const_structrp png_ptr));
/* Added in libpng-1.4.1 */
PNG_EXPORT(191, void, png_set_chunk_malloc_max, (png_structrp png_ptr,
    png_alloc_size_t user_chunk_cache_max));
PNG_EXPORT(192, png_alloc_size_t, png_get_chunk_malloc_max,
    (png_const_structrp png_ptr));
#endif

#if defined(PNG_INCH_CONVERSIONS_SUPPORTED)
PNG_EXPORT(193, png_uint_32, png_get_pixels_per_inch,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));

PNG_EXPORT(194, png_uint_32, png_get_x_pixels_per_inch,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));

PNG_EXPORT(195, png_uint_32, png_get_y_pixels_per_inch,
    (png_const_structrp png_ptr, png_const_inforp info_ptr));

PNG_FP_EXPORT(196, float, png_get_x_offset_inches,
    (png_const_structrp png_ptr, png_const_inforp info_ptr))
#ifdef PNG_FIXED_POINT_SUPPORTED /* otherwise not implemented. */
PNG_FIXED_EXPORT(211, png_fixed_point, png_get_x_offset_inches_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr))
#endif

PNG_FP_EXPORT(197, float, png_get_y_offset_inches, (png_const_structrp png_ptr,
    png_const_inforp info_ptr))
#ifdef PNG_FIXED_POINT_SUPPORTED /* otherwise not implemented. */
PNG_FIXED_EXPORT(212, png_fixed_point, png_get_y_offset_inches_fixed,
    (png_const_structrp png_ptr, png_const_inforp info_ptr))
#endif

#  ifdef PNG_pHYs_SUPPORTED
PNG_EXPORT(198, png_uint_32, png_get_pHYs_dpi, (png_const_structrp png_ptr,
    png_const_inforp info_ptr, png_uint_32 *res_x, png_uint_32 *res_y,
    int *unit_type));
#  endif /* pHYs */
#endif  /* INCH_CONVERSIONS */

/* Added in libpng-1.4.0 */
#ifdef PNG_IO_STATE_SUPPORTED
PNG_EXPORT(199, png_uint_32, png_get_io_state, (png_const_structrp png_ptr));

/* Removed from libpng 1.6; use png_get_io_chunk_type. */
PNG_REMOVED(200, png_const_bytep, png_get_io_chunk_name, (png_structrp png_ptr),
    PNG_DEPRECATED)

PNG_EXPORT(216, png_uint_32, png_get_io_chunk_type,
    (png_const_structrp png_ptr));

/* The flags returned by png_get_io_state() are the following: */
#  define PNG_IO_NONE        0x0000   /* no I/O at this moment */
#  define PNG_IO_READING     0x0001   /* currently reading */
#  define PNG_IO_WRITING     0x0002   /* currently writing */
#  define PNG_IO_SIGNATURE   0x0010   /* currently at the file signature */
#  define PNG_IO_CHUNK_HDR   0x0020   /* currently at the chunk header */
#  define PNG_IO_CHUNK_DATA  0x0040   /* currently at the chunk data */
#  define PNG_IO_CHUNK_CRC   0x0080   /* currently at the chunk crc */
#  define PNG_IO_MASK_OP     0x000f   /* current operation: reading/writing */
#  define PNG_IO_MASK_LOC    0x00f0   /* current location: sig/hdr/data/crc */
#endif /* IO_STATE */

/* Interlace support.  The following macros are always defined so that if
 * libpng interlace handling is turned off the macros may be used to handle
 * interlaced images within the application.
 */
#define PNG_INTERLACE_ADAM7_PASSES 7

/* Two macros to return the first row and first column of the original,
 * full, image which appears in a given pass.  'pass' is in the range 0
 * to 6 and the result is in the range 0 to 7.
 */
#define PNG_PASS_START_ROW(pass) (((1&~(pass))<<(3-((pass)>>1)))&7)
#define PNG_PASS_START_COL(pass) (((1& (pass))<<(3-(((pass)+1)>>1)))&7)

/* A macro to return the offset between pixels in the output row for a pair of
 * pixels in the input - effectively the inverse of the 'COL_SHIFT' macro that
 * follows.  Note that ROW_OFFSET is the offset from one row to the next whereas
 * COL_OFFSET is from one column to the next, within a row.
 */
#define PNG_PASS_ROW_OFFSET(pass) ((pass)>2?(8>>(((pass)-1)>>1)):8)
#define PNG_PASS_COL_OFFSET(pass) (1<<((7-(pass))>>1))

/* Two macros to help evaluate the number of rows or columns in each
 * pass.  This is expressed as a shift - effectively log2 of the number or
 * rows or columns in each 8x8 tile of the original image.
 */
#define PNG_PASS_ROW_SHIFT(pass) ((pass)>2?(8-(pass))>>1:3)
#define PNG_PASS_COL_SHIFT(pass) ((pass)>1?(7-(pass))>>1:3)

/* Hence two macros to determine the number of rows or columns in a given
 * pass of an image given its height or width.  In fact these macros may
 * return non-zero even though the sub-image is empty, because the other
 * dimension may be empty for a small image.
 */
#define PNG_PASS_ROWS(height, pass) (((height)+(((1<<PNG_PASS_ROW_SHIFT(pass))\
   -1)-PNG_PASS_START_ROW(pass)))>>PNG_PASS_ROW_SHIFT(pass))
#define PNG_PASS_COLS(width, pass) (((width)+(((1<<PNG_PASS_COL_SHIFT(pass))\
   -1)-PNG_PASS_START_COL(pass)))>>PNG_PASS_COL_SHIFT(pass))

/* For the reader row callbacks (both progressive and sequential) it is
 * necessary to find the row in the output image given a row in an interlaced
 * image, so two more macros:
 */
#define PNG_ROW_FROM_PASS_ROW(y_in, pass) \
   (((y_in)<<PNG_PASS_ROW_SHIFT(pass))+PNG_PASS_START_ROW(pass))
#define PNG_COL_FROM_PASS_COL(x_in, pass) \
   (((x_in)<<PNG_PASS_COL_SHIFT(pass))+PNG_PASS_START_COL(pass))

/* Two macros which return a boolean (0 or 1) saying whether the given row
 * or column is in a particular pass.  These use a common utility macro that
 * returns a mask for a given pass - the offset 'off' selects the row or
 * column version.  The mask has the appropriate bit set for each column in
 * the tile.
 */
#define PNG_PASS_MASK(pass,off) ( \
   ((0x110145AF>>(((7-(off))-(pass))<<2)) & 0xF) | \
   ((0x01145AF0>>(((7-(off))-(pass))<<2)) & 0xF0))

#define PNG_ROW_IN_INTERLACE_PASS(y, pass) \
   ((PNG_PASS_MASK(pass,0) >> ((y)&7)) & 1)
#define PNG_COL_IN_INTERLACE_PASS(x, pass) \
   ((PNG_PASS_MASK(pass,1) >> ((x)&7)) & 1)

#ifdef PNG_READ_COMPOSITE_NODIV_SUPPORTED
/* With these routines we avoid an integer divide, which will be slower on
 * most machines.  However, it does take more operations than the corresponding
 * divide method, so it may be slower on a few RISC systems.  There are two
 * shifts (by 8 or 16 bits) and an addition, versus a single integer divide.
 *
 * Note that the rounding factors are NOT supposed to be the same!  128 and
 * 32768 are correct for the NODIV code; 127 and 32767 are correct for the
 * standard method.
 *
 * [Optimized code by Greg Roelofs and Mark Adler...blame us for bugs. :-) ]
 */

 /* fg and bg should be in `gamma 1.0' space; alpha is the opacity */

#  define png_composite(composite, fg, alpha, bg)         \
     { png_uint_16 temp = (png_uint_16)((png_uint_16)(fg) \
           * (png_uint_16)(alpha)                         \
           + (png_uint_16)(bg)*(png_uint_16)(255          \
           - (png_uint_16)(alpha)) + 128);                \
       (composite) = (png_byte)(((temp + (temp >> 8)) >> 8) & 0xff); }

#  define png_composite_16(composite, fg, alpha, bg)       \
     { png_uint_32 temp = (png_uint_32)((png_uint_32)(fg)  \
           * (png_uint_32)(alpha)                          \
           + (png_uint_32)(bg)*(65535                      \
           - (png_uint_32)(alpha)) + 32768);               \
       (composite) = (png_uint_16)(0xffff & ((temp + (temp >> 16)) >> 16)); }

#else  /* Standard method using integer division */

#  define png_composite(composite, fg, alpha, bg)                        \
     (composite) =                                                       \
         (png_byte)(0xff & (((png_uint_16)(fg) * (png_uint_16)(alpha) +  \
         (png_uint_16)(bg) * (png_uint_16)(255 - (png_uint_16)(alpha)) + \
         127) / 255))

#  define png_composite_16(composite, fg, alpha, bg)                         \
     (composite) =                                                           \
         (png_uint_16)(0xffff & (((png_uint_32)(fg) * (png_uint_32)(alpha) + \
         (png_uint_32)(bg)*(png_uint_32)(65535 - (png_uint_32)(alpha)) +     \
         32767) / 65535))
#endif /* READ_COMPOSITE_NODIV */

#ifdef PNG_READ_INT_FUNCTIONS_SUPPORTED
PNG_EXPORT(201, png_uint_32, png_get_uint_32, (png_const_bytep buf));
PNG_EXPORT(202, png_uint_16, png_get_uint_16, (png_const_bytep buf));
PNG_EXPORT(203, png_int_32, png_get_int_32, (png_const_bytep buf));
#endif

PNG_EXPORT(204, png_uint_32, png_get_uint_31, (png_const_structrp png_ptr,
    png_const_bytep buf));
/* No png_get_int_16 -- may be added if there's a real need for it. */

/* Place a 32-bit number into a buffer in PNG byte order (big-endian). */
#ifdef PNG_WRITE_INT_FUNCTIONS_SUPPORTED
PNG_EXPORT(205, void, png_save_uint_32, (png_bytep buf, png_uint_32 i));
#endif
#ifdef PNG_SAVE_INT_32_SUPPORTED
PNG_EXPORT(206, void, png_save_int_32, (png_bytep buf, png_int_32 i));
#endif

/* Place a 16-bit number into a buffer in PNG byte order.
 * The parameter is declared unsigned int, not png_uint_16,
 * just to avoid potential problems on pre-ANSI C compilers.
 */
#ifdef PNG_WRITE_INT_FUNCTIONS_SUPPORTED
PNG_EXPORT(207, void, png_save_uint_16, (png_bytep buf, unsigned int i));
/* No png_save_int_16 -- may be added if there's a real need for it. */
#endif

#ifdef PNG_USE_READ_MACROS
/* Inline macros to do direct reads of bytes from the input buffer.
 * The png_get_int_32() routine assumes we are using two's complement
 * format for negative values, which is almost certainly true.
 */
#  define PNG_get_uint_32(buf) \
     (((png_uint_32)(*(buf)) << 24) + \
      ((png_uint_32)(*((buf) + 1)) << 16) + \
      ((png_uint_32)(*((buf) + 2)) << 8) + \
      ((png_uint_32)(*((buf) + 3))))

   /* From libpng-1.4.0 until 1.4.4, the png_get_uint_16 macro (but not the
    * function) incorrectly returned a value of type png_uint_32.
    */
#  define PNG_get_uint_16(buf) \
     ((png_uint_16) \
      (((unsigned int)(*(buf)) << 8) + \
       ((unsigned int)(*((buf) + 1)))))

#  define PNG_get_int_32(buf) \
     ((png_int_32)((*(buf) & 0x80) \
      ? -((png_int_32)(((png_get_uint_32(buf)^0xffffffffU)+1U)&0x7fffffffU)) \
      : (png_int_32)png_get_uint_32(buf)))

   /* If PNG_PREFIX is defined the same thing as below happens in pnglibconf.h,
    * but defining a macro name prefixed with PNG_PREFIX.
    */
#  ifndef PNG_PREFIX
#     define png_get_uint_32(buf) PNG_get_uint_32(buf)
#     define png_get_uint_16(buf) PNG_get_uint_16(buf)
#     define png_get_int_32(buf)  PNG_get_int_32(buf)
#  endif
#else
#  ifdef PNG_PREFIX
      /* No macros; revert to the (redefined) function */
#     define PNG_get_uint_32 (png_get_uint_32)
#     define PNG_get_uint_16 (png_get_uint_16)
#     define PNG_get_int_32  (png_get_int_32)
#  endif
#endif

#ifdef PNG_CHECK_FOR_INVALID_INDEX_SUPPORTED
PNG_EXPORT(242, void, png_set_check_for_invalid_index,
    (png_structrp png_ptr, int allowed));
#  ifdef PNG_GET_PALETTE_MAX_SUPPORTED
PNG_EXPORT(243, int, png_get_palette_max, (png_const_structp png_ptr,
    png_const_infop info_ptr));
#  endif
#endif /* CHECK_FOR_INVALID_INDEX */

/*******************************************************************************
 * Section 5: SIMPLIFIED API
 *******************************************************************************
 *
 * Please read the documentation in libpng-manual.txt (TODO: write said
 * documentation) if you don't understand what follows.
 *
 * The simplified API hides the details of both libpng and the PNG file format
 * itself.  It allows PNG files to be read into a very limited number of
 * in-memory bitmap formats or to be written from the same formats.  If these
 * formats do not accomodate your needs then you can, and should, use the more
 * sophisticated APIs above - these support a wide variety of in-memory formats
 * and a wide variety of sophisticated transformations to those formats as well
 * as a wide variety of APIs to manipulate ancillary information.
 *
 * To read a PNG file using the simplified API:
 *
 * 1) Declare a 'png_image' structure (see below) on the stack, set the
 *    version field to PNG_IMAGE_VERSION and the 'opaque' pointer to NULL
 *    (this is REQUIRED, your program may crash if you don't do it.)
 * 2) Call the appropriate png_image_begin_read... function.
 * 3) Set the png_image 'format' member to the required sample format.
 * 4) Allocate a buffer for the image and, if required, the color-map.
 * 5) Call png_image_finish_read to read the image and, if required, the
 *    color-map into your buffers.
 *
 * There are no restrictions on the format of the PNG input itself; all valid
 * color types, bit depths, and interlace methods are acceptable, and the
 * input image is transformed as necessary to the requested in-memory format
 * during the png_image_finish_read() step.  The only caveat is that if you
 * request a color-mapped image from a PNG that is full-color or makes
 * complex use of an alpha channel the transformation is extremely lossy and the
 * result may look terrible.
 *
 * To write a PNG file using the simplified API:
 *
 * 1) Declare a 'png_image' structure on the stack and memset() it to all zero.
 * 2) Initialize the members of the structure that describe the image, setting
 *    the 'format' member to the format of the image samples.
 * 3) Call the appropriate png_image_write... function with a pointer to the
 *    image and, if necessary, the color-map to write the PNG data.
 *
 * png_image is a structure that describes the in-memory format of an image
 * when it is being read or defines the in-memory format of an image that you
 * need to write:
 */
#if defined(PNG_SIMPLIFIED_READ_SUPPORTED) || \
    defined(PNG_SIMPLIFIED_WRITE_SUPPORTED)

#define PNG_IMAGE_VERSION 1

typedef struct png_control *png_controlp;
typedef struct
{
   png_controlp opaque;    /* Initialize to NULL, free with png_image_free */
   png_uint_32  version;   /* Set to PNG_IMAGE_VERSION */
   png_uint_32  width;     /* Image width in pixels (columns) */
   png_uint_32  height;    /* Image height in pixels (rows) */
   png_uint_32  format;    /* Image format as defined below */
   png_uint_32  flags;     /* A bit mask containing informational flags */
   png_uint_32  colormap_entries;
                           /* Number of entries in the color-map */

   /* In the event of an error or warning the following field will be set to a
    * non-zero value and the 'message' field will contain a '\0' terminated
    * string with the libpng error or warning message.  If both warnings and
    * an error were encountered, only the error is recorded.  If there
    * are multiple warnings, only the first one is recorded.
    *
    * The upper 30 bits of this value are reserved, the low two bits contain
    * a value as follows:
    */
#  define PNG_IMAGE_WARNING 1
#  define PNG_IMAGE_ERROR 2
   /*
    * The result is a two-bit code such that a value more than 1 indicates
    * a failure in the API just called:
    *
    *    0 - no warning or error
    *    1 - warning
    *    2 - error
    *    3 - error preceded by warning
    */
#  define PNG_IMAGE_FAILED(png_cntrl) ((((png_cntrl).warning_or_error)&0x03)>1)

   png_uint_32  warning_or_error;

   char         message[64];
} png_image, *png_imagep;

/* The samples of the image have one to four channels whose components have
 * original values in the range 0 to 1.0:
 *
 * 1: A single gray or luminance channel (G).
 * 2: A gray/luminance channel and an alpha channel (GA).
 * 3: Three red, green, blue color channels (RGB).
 * 4: Three color channels and an alpha channel (RGBA).
 *
 * The components are encoded in one of two ways:
 *
 * a) As a small integer, value 0..255, contained in a single byte.  For the
 * alpha channel the original value is simply value/255.  For the color or
 * luminance channels the value is encoded according to the sRGB specification
 * and matches the 8-bit format expected by typical display devices.
 *
 * The color/gray channels are not scaled (pre-multiplied) by the alpha
 * channel and are suitable for passing to color management software.
 *
 * b) As a value in the range 0..65535, contained in a 2-byte integer.  All
 * channels can be converted to the original value by dividing by 65535; all
 * channels are linear.  Color channels use the RGB encoding (RGB end-points) of
 * the sRGB specification.  This encoding is identified by the
 * PNG_FORMAT_FLAG_LINEAR flag below.
 *
 * When the simplified API needs to convert between sRGB and linear colorspaces,
 * the actual sRGB transfer curve defined in the sRGB specification (see the
 * article at http://en.wikipedia.org/wiki/SRGB) is used, not the gamma=1/2.2
 * approximation used elsewhere in libpng.
 *
 * When an alpha channel is present it is expected to denote pixel coverage
 * of the color or luminance channels and is returned as an associated alpha
 * channel: the color/gray channels are scaled (pre-multiplied) by the alpha
 * value.
 *
 * The samples are either contained directly in the image data, between 1 and 8
 * bytes per pixel according to the encoding, or are held in a color-map indexed
 * by bytes in the image data.  In the case of a color-map the color-map entries
 * are individual samples, encoded as above, and the image data has one byte per
 * pixel to select the relevant sample from the color-map.
 */

/* PNG_FORMAT_*
 *
 * #defines to be used in png_image::format.  Each #define identifies a
 * particular layout of sample data and, if present, alpha values.  There are
 * separate defines for each of the two component encodings.
 *
 * A format is built up using single bit flag values.  All combinations are
 * valid.  Formats can be built up from the flag values or you can use one of
 * the predefined values below.  When testing formats always use the FORMAT_FLAG
 * macros to test for individual features - future versions of the library may
 * add new flags.
 *
 * When reading or writing color-mapped images the format should be set to the
 * format of the entries in the color-map then png_image_{read,write}_colormap
 * called to read or write the color-map and set the format correctly for the
 * image data.  Do not set the PNG_FORMAT_FLAG_COLORMAP bit directly!
 *
 * NOTE: libpng can be built with particular features disabled. If you see
 * compiler errors because the definition of one of the following flags has been
 * compiled out it is because libpng does not have the required support.  It is
 * possible, however, for the libpng configuration to enable the format on just
 * read or just write; in that case you may see an error at run time.  You can
 * guard against this by checking for the definition of the appropriate
 * "_SUPPORTED" macro, one of:
 *
 *    PNG_SIMPLIFIED_{READ,WRITE}_{BGR,AFIRST}_SUPPORTED
 */
#define PNG_FORMAT_FLAG_ALPHA    0x01U /* format with an alpha channel */
#define PNG_FORMAT_FLAG_COLOR    0x02U /* color format: otherwise grayscale */
#define PNG_FORMAT_FLAG_LINEAR   0x04U /* 2-byte channels else 1-byte */
#define PNG_FORMAT_FLAG_COLORMAP 0x08U /* image data is color-mapped */

#ifdef PNG_FORMAT_BGR_SUPPORTED
#  define PNG_FORMAT_FLAG_BGR    0x10U /* BGR colors, else order is RGB */
#endif

#ifdef PNG_FORMAT_AFIRST_SUPPORTED
#  define PNG_FORMAT_FLAG_AFIRST 0x20U /* alpha channel comes first */
#endif

/* Commonly used formats have predefined macros.
 *
 * First the single byte (sRGB) formats:
 */
#define PNG_FORMAT_GRAY 0
#define PNG_FORMAT_GA   PNG_FORMAT_FLAG_ALPHA
#define PNG_FORMAT_AG   (PNG_FORMAT_GA|PNG_FORMAT_FLAG_AFIRST)
#define PNG_FORMAT_RGB  PNG_FORMAT_FLAG_COLOR
#define PNG_FORMAT_BGR  (PNG_FORMAT_FLAG_COLOR|PNG_FORMAT_FLAG_BGR)
#define PNG_FORMAT_RGBA (PNG_FORMAT_RGB|PNG_FORMAT_FLAG_ALPHA)
#define PNG_FORMAT_ARGB (PNG_FORMAT_RGBA|PNG_FORMAT_FLAG_AFIRST)
#define PNG_FORMAT_BGRA (PNG_FORMAT_BGR|PNG_FORMAT_FLAG_ALPHA)
#define PNG_FORMAT_ABGR (PNG_FORMAT_BGRA|PNG_FORMAT_FLAG_AFIRST)

/* Then the linear 2-byte formats.  When naming these "Y" is used to
 * indicate a luminance (gray) channel.
 */
#define PNG_FORMAT_LINEAR_Y PNG_FORMAT_FLAG_LINEAR
#define PNG_FORMAT_LINEAR_Y_ALPHA (PNG_FORMAT_FLAG_LINEAR|PNG_FORMAT_FLAG_ALPHA)
#define PNG_FORMAT_LINEAR_RGB (PNG_FORMAT_FLAG_LINEAR|PNG_FORMAT_FLAG_COLOR)
#define PNG_FORMAT_LINEAR_RGB_ALPHA \
   (PNG_FORMAT_FLAG_LINEAR|PNG_FORMAT_FLAG_COLOR|PNG_FORMAT_FLAG_ALPHA)

/* With color-mapped formats the image data is one byte for each pixel, the byte
 * is an index into the color-map which is formatted as above.  To obtain a
 * color-mapped format it is sufficient just to add the PNG_FOMAT_FLAG_COLORMAP
 * to one of the above definitions, or you can use one of the definitions below.
 */
#define PNG_FORMAT_RGB_COLORMAP  (PNG_FORMAT_RGB|PNG_FORMAT_FLAG_COLORMAP)
#define PNG_FORMAT_BGR_COLORMAP  (PNG_FORMAT_BGR|PNG_FORMAT_FLAG_COLORMAP)
#define PNG_FORMAT_RGBA_COLORMAP (PNG_FORMAT_RGBA|PNG_FORMAT_FLAG_COLORMAP)
#define PNG_FORMAT_ARGB_COLORMAP (PNG_FORMAT_ARGB|PNG_FORMAT_FLAG_COLORMAP)
#define PNG_FORMAT_BGRA_COLORMAP (PNG_FORMAT_BGRA|PNG_FORMAT_FLAG_COLORMAP)
#define PNG_FORMAT_ABGR_COLORMAP (PNG_FORMAT_ABGR|PNG_FORMAT_FLAG_COLORMAP)

/* PNG_IMAGE macros
 *
 * These are convenience macros to derive information from a png_image
 * structure.  The PNG_IMAGE_SAMPLE_ macros return values appropriate to the
 * actual image sample values - either the entries in the color-map or the
 * pixels in the image.  The PNG_IMAGE_PIXEL_ macros return corresponding values
 * for the pixels and will always return 1 for color-mapped formats.  The
 * remaining macros return information about the rows in the image and the
 * complete image.
 *
 * NOTE: All the macros that take a png_image::format parameter are compile time
 * constants if the format parameter is, itself, a constant.  Therefore these
 * macros can be used in array declarations and case labels where required.
 * Similarly the macros are also pre-processor constants (sizeof is not used) so
 * they can be used in #if tests.
 *
 * First the information about the samples.
 */
#define PNG_IMAGE_SAMPLE_CHANNELS(fmt)\
   (((fmt)&(PNG_FORMAT_FLAG_COLOR|PNG_FORMAT_FLAG_ALPHA))+1)
   /* Return the total number of channels in a given format: 1..4 */

#define PNG_IMAGE_SAMPLE_COMPONENT_SIZE(fmt)\
   ((((fmt) & PNG_FORMAT_FLAG_LINEAR) >> 2)+1)
   /* Return the size in bytes of a single component of a pixel or color-map
    * entry (as appropriate) in the image: 1 or 2.
    */

#define PNG_IMAGE_SAMPLE_SIZE(fmt)\
   (PNG_IMAGE_SAMPLE_CHANNELS(fmt) * PNG_IMAGE_SAMPLE_COMPONENT_SIZE(fmt))
   /* This is the size of the sample data for one sample.  If the image is
    * color-mapped it is the size of one color-map entry (and image pixels are
    * one byte in size), otherwise it is the size of one image pixel.
    */

#define PNG_IMAGE_MAXIMUM_COLORMAP_COMPONENTS(fmt)\
   (PNG_IMAGE_SAMPLE_CHANNELS(fmt) * 256)
   /* The maximum size of the color-map required by the format expressed in a
    * count of components.  This can be used to compile-time allocate a
    * color-map:
    *
    * png_uint_16 colormap[PNG_IMAGE_MAXIMUM_COLORMAP_COMPONENTS(linear_fmt)];
    *
    * png_byte colormap[PNG_IMAGE_MAXIMUM_COLORMAP_COMPONENTS(sRGB_fmt)];
    *
    * Alternatively use the PNG_IMAGE_COLORMAP_SIZE macro below to use the
    * information from one of the png_image_begin_read_ APIs and dynamically
    * allocate the required memory.
    */

/* Corresponding information about the pixels */
#define PNG_IMAGE_PIXEL_(test,fmt)\
   (((fmt)&PNG_FORMAT_FLAG_COLORMAP)?1:test(fmt))

#define PNG_IMAGE_PIXEL_CHANNELS(fmt)\
   PNG_IMAGE_PIXEL_(PNG_IMAGE_SAMPLE_CHANNELS,fmt)
   /* The number of separate channels (components) in a pixel; 1 for a
    * color-mapped image.
    */

#define PNG_IMAGE_PIXEL_COMPONENT_SIZE(fmt)\
   PNG_IMAGE_PIXEL_(PNG_IMAGE_SAMPLE_COMPONENT_SIZE,fmt)
   /* The size, in bytes, of each component in a pixel; 1 for a color-mapped
    * image.
    */

#define PNG_IMAGE_PIXEL_SIZE(fmt) PNG_IMAGE_PIXEL_(PNG_IMAGE_SAMPLE_SIZE,fmt)
   /* The size, in bytes, of a complete pixel; 1 for a color-mapped image. */

/* Information about the whole row, or whole image */
#define PNG_IMAGE_ROW_STRIDE(image)\
   (PNG_IMAGE_PIXEL_CHANNELS((image).format) * (image).width)
   /* Return the total number of components in a single row of the image; this
    * is the minimum 'row stride', the minimum count of components between each
    * row.  For a color-mapped image this is the minimum number of bytes in a
    * row.
    *
    * WARNING: this macro overflows for some images with more than one component
    * and very large image widths.  libpng will refuse to process an image where
    * this macro would overflow.
    */

#define PNG_IMAGE_BUFFER_SIZE(image, row_stride)\
   (PNG_IMAGE_PIXEL_COMPONENT_SIZE((image).format)*(image).height*(row_stride))
   /* Return the size, in bytes, of an image buffer given a png_image and a row
    * stride - the number of components to leave space for in each row.
    *
    * WARNING: this macro overflows a 32-bit integer for some large PNG images,
    * libpng will refuse to process an image where such an overflow would occur.
    */

#define PNG_IMAGE_SIZE(image)\
   PNG_IMAGE_BUFFER_SIZE(image, PNG_IMAGE_ROW_STRIDE(image))
   /* Return the size, in bytes, of the image in memory given just a png_image;
    * the row stride is the minimum stride required for the image.
    */

#define PNG_IMAGE_COLORMAP_SIZE(image)\
   (PNG_IMAGE_SAMPLE_SIZE((image).format) * (image).colormap_entries)
   /* Return the size, in bytes, of the color-map of this image.  If the image
    * format is not a color-map format this will return a size sufficient for
    * 256 entries in the given format; check PNG_FORMAT_FLAG_COLORMAP if
    * you don't want to allocate a color-map in this case.
    */

/* PNG_IMAGE_FLAG_*
 *
 * Flags containing additional information about the image are held in the
 * 'flags' field of png_image.
 */
#define PNG_IMAGE_FLAG_COLORSPACE_NOT_sRGB 0x01
   /* This indicates the the RGB values of the in-memory bitmap do not
    * correspond to the red, green and blue end-points defined by sRGB.
    */

#define PNG_IMAGE_FLAG_FAST 0x02
   /* On write emphasise speed over compression; the resultant PNG file will be
    * larger but will be produced significantly faster, particular for large
    * images.  Do not use this option for images which will be distributed, only
    * used it when producing intermediate files that will be read back in
    * repeatedly.  For a typical 24-bit image the option will double the read
    * speed at the cost of increasing the image size by 25%, however for many
    * more compressible images the PNG file can be 10 times larger with only a
    * slight speed gain.
    */

#define PNG_IMAGE_FLAG_16BIT_sRGB 0x04
   /* On read if the image is a 16-bit per component image and there is no gAMA
    * or sRGB chunk assume that the components are sRGB encoded.  Notice that
    * images output by the simplified API always have gamma information; setting
    * this flag only affects the interpretation of 16-bit images from an
    * external source.  It is recommended that the application expose this flag
    * to the user; the user can normally easily recognize the difference between
    * linear and sRGB encoding.  This flag has no effect on write - the data
    * passed to the write APIs must have the correct encoding (as defined
    * above.)
    *
    * If the flag is not set (the default) input 16-bit per component data is
    * assumed to be linear.
    *
    * NOTE: the flag can only be set after the png_image_begin_read_ call,
    * because that call initializes the 'flags' field.
    */

#ifdef PNG_SIMPLIFIED_READ_SUPPORTED
/* READ APIs
 * ---------
 *
 * The png_image passed to the read APIs must have been initialized by setting
 * the png_controlp field 'opaque' to NULL (or, safer, memset the whole thing.)
 */
#ifdef PNG_STDIO_SUPPORTED
PNG_EXPORT(234, int, png_image_begin_read_from_file, (png_imagep image,
   const char *file_name));
   /* The named file is opened for read and the image header is filled in
    * from the PNG header in the file.
    */

PNG_EXPORT(235, int, png_image_begin_read_from_stdio, (png_imagep image,
   FILE* file));
   /* The PNG header is read from the stdio FILE object. */
#endif /* STDIO */

PNG_EXPORT(236, int, png_image_begin_read_from_memory, (png_imagep image,
   png_const_voidp memory, png_size_t size));
   /* The PNG header is read from the given memory buffer. */

PNG_EXPORT(237, int, png_image_finish_read, (png_imagep image,
   png_const_colorp background, void *buffer, png_int_32 row_stride,
   void *colormap));
   /* Finish reading the image into the supplied buffer and clean up the
    * png_image structure.
    *
    * row_stride is the step, in byte or 2-byte units as appropriate,
    * between adjacent rows.  A positive stride indicates that the top-most row
    * is first in the buffer - the normal top-down arrangement.  A negative
    * stride indicates that the bottom-most row is first in the buffer.
    *
    * background need only be supplied if an alpha channel must be removed from
    * a png_byte format and the removal is to be done by compositing on a solid
    * color; otherwise it may be NULL and any composition will be done directly
    * onto the buffer.  The value is an sRGB color to use for the background,
    * for grayscale output the green channel is used.
    *
    * background must be supplied when an alpha channel must be removed from a
    * single byte color-mapped output format, in other words if:
    *
    * 1) The original format from png_image_begin_read_from_* had
    *    PNG_FORMAT_FLAG_ALPHA set.
    * 2) The format set by the application does not.
    * 3) The format set by the application has PNG_FORMAT_FLAG_COLORMAP set and
    *    PNG_FORMAT_FLAG_LINEAR *not* set.
    *
    * For linear output removing the alpha channel is always done by compositing
    * on black and background is ignored.
    *
    * colormap must be supplied when PNG_FORMAT_FLAG_COLORMAP is set.  It must
    * be at least the size (in bytes) returned by PNG_IMAGE_COLORMAP_SIZE.
    * image->colormap_entries will be updated to the actual number of entries
    * written to the colormap; this may be less than the original value.
    */

PNG_EXPORT(238, void, png_image_free, (png_imagep image));
   /* Free any data allocated by libpng in image->opaque, setting the pointer to
    * NULL.  May be called at any time after the structure is initialized.
    */
#endif /* SIMPLIFIED_READ */

#ifdef PNG_SIMPLIFIED_WRITE_SUPPORTED
/* WRITE APIS
 * ----------
 * For write you must initialize a png_image structure to describe the image to
 * be written.  To do this use memset to set the whole structure to 0 then
 * initialize fields describing your image.
 *
 * version: must be set to PNG_IMAGE_VERSION
 * opaque: must be initialized to NULL
 * width: image width in pixels
 * height: image height in rows
 * format: the format of the data (image and color-map) you wish to write
 * flags: set to 0 unless one of the defined flags applies; set
 *    PNG_IMAGE_FLAG_COLORSPACE_NOT_sRGB for color format images where the RGB
 *    values do not correspond to the colors in sRGB.
 * colormap_entries: set to the number of entries in the color-map (0 to 256)
 */
#ifdef PNG_SIMPLIFIED_WRITE_STDIO_SUPPORTED
PNG_EXPORT(239, int, png_image_write_to_file, (png_imagep image,
   const char *file, int convert_to_8bit, const void *buffer,
   png_int_32 row_stride, const void *colormap));
   /* Write the image to the named file. */

PNG_EXPORT(240, int, png_image_write_to_stdio, (png_imagep image, FILE *file,
   int convert_to_8_bit, const void *buffer, png_int_32 row_stride,
   const void *colormap));
   /* Write the image to the given (FILE*). */
#endif /* SIMPLIFIED_WRITE_STDIO */

/* With all write APIs if image is in one of the linear formats with 16-bit
 * data then setting convert_to_8_bit will cause the output to be an 8-bit PNG
 * gamma encoded according to the sRGB specification, otherwise a 16-bit linear
 * encoded PNG file is written.
 *
 * With color-mapped data formats the colormap parameter point to a color-map
 * with at least image->colormap_entries encoded in the specified format.  If
 * the format is linear the written PNG color-map will be converted to sRGB
 * regardless of the convert_to_8_bit flag.
 *
 * With all APIs row_stride is handled as in the read APIs - it is the spacing
 * from one row to the next in component sized units (1 or 2 bytes) and if
 * negative indicates a bottom-up row layout in the buffer.  If row_stride is
 * zero, libpng will calculate it for you from the image width and number of
 * channels.
 *
 * Note that the write API does not support interlacing, sub-8-bit pixels or
 * most ancillary chunks.  If you need to write text chunks (e.g. for copyright
 * notices) you need to use one of the other APIs.
 */

PNG_EXPORT(245, int, png_image_write_to_memory, (png_imagep image, void *memory,
   png_alloc_size_t * PNG_RESTRICT memory_bytes, int convert_to_8_bit,
   const void *buffer, png_int_32 row_stride, const void *colormap));
   /* Write the image to the given memory buffer.  The function both writes the
    * whole PNG data stream to *memory and updates *memory_bytes with the count
    * of bytes written.
    *
    * 'memory' may be NULL.  In this case *memory_bytes is not read however on
    * success the number of bytes which would have been written will still be
    * stored in *memory_bytes.  On failure *memory_bytes will contain 0.
    *
    * If 'memory' is not NULL it must point to memory[*memory_bytes] of
    * writeable memory.
    *
    * If the function returns success memory[*memory_bytes] (if 'memory' is not
    * NULL) contains the written PNG data.  *memory_bytes will always be less
    * than or equal to the original value.
    *
    * If the function returns false and *memory_bytes was not changed an error
    * occured during write.  If *memory_bytes was changed, or is not 0 if
    * 'memory' was NULL, the write would have succeeded but for the memory
    * buffer being too small.  *memory_bytes contains the required number of
    * bytes and will be bigger that the original value.
    */

#define png_image_write_get_memory_size(image, size, convert_to_8_bit, buffer,\
   row_stride, colormap)\
   png_image_write_to_memory(&(image), 0, &(size), convert_to_8_bit, buffer,\
         row_stride, colormap)
   /* Return the amount of memory in 'size' required to compress this image.
    * The png_image structure 'image' must be filled in as in the above
    * function and must not be changed before the actual write call, the buffer
    * and all other parameters must also be identical to that in the final
    * write call.  The 'size' variable need not be initialized.
    *
    * NOTE: the macro returns true/false, if false is returned 'size' will be
    * set to zero and the write failed and probably will fail if tried again.
    */

/* You can pre-allocate the buffer by making sure it is of sufficient size
 * regardless of the amount of compression achieved.  The buffer size will
 * always be bigger than the original image and it will never be filled.  The
 * following macros are provided to assist in allocating the buffer.
 */
#define PNG_IMAGE_DATA_SIZE(image) (PNG_IMAGE_SIZE(image)+(image).height)
   /* The number of uncompressed bytes in the PNG byte encoding of the image;
    * uncompressing the PNG IDAT data will give this number of bytes.
    *
    * NOTE: while PNG_IMAGE_SIZE cannot overflow for an image in memory this
    * macro can because of the extra bytes used in the PNG byte encoding.  You
    * need to avoid this macro if your image size approaches 2^30 in width or
    * height.  The same goes for the remainder of these macros; they all produce
    * bigger numbers than the actual in-memory image size.
    */
#ifndef PNG_ZLIB_MAX_SIZE
#  define PNG_ZLIB_MAX_SIZE(b) ((b)+(((b)+7U)>>3)+(((b)+63U)>>6)+11U)
   /* An upper bound on the number of compressed bytes given 'b' uncompressed
    * bytes.  This is based on deflateBounds() in zlib; different
    * implementations of zlib compression may conceivably produce more data so
    * if your zlib implementation is not zlib itself redefine this macro
    * appropriately.
    */
#endif

#define PNG_IMAGE_COMPRESSED_SIZE_MAX(image)\
   PNG_ZLIB_MAX_SIZE((png_alloc_size_t)PNG_IMAGE_DATA_SIZE(image))
   /* An upper bound on the size of the data in the PNG IDAT chunks. */

#define PNG_IMAGE_PNG_SIZE_MAX_(image, image_size)\
   ((8U/*sig*/+25U/*IHDR*/+16U/*gAMA*/+44U/*cHRM*/+12U/*IEND*/+\
    (((image).format&PNG_FORMAT_FLAG_COLORMAP)?/*colormap: PLTE, tRNS*/\
     12U+3U*(image).colormap_entries/*PLTE data*/+\
     (((image).format&PNG_FORMAT_FLAG_ALPHA)?\
      12U/*tRNS*/+(image).colormap_entries:0U):0U)+\
    12U)+(12U*((image_size)/PNG_ZBUF_SIZE))/*IDAT*/+(image_size))
   /* A helper for the following macro; if your compiler cannot handle the
    * following macro use this one with the result of
    * PNG_IMAGE_COMPRESSED_SIZE_MAX(image) as the second argument (most
    * compilers should handle this just fine.)
    */

#define PNG_IMAGE_PNG_SIZE_MAX(image)\
   PNG_IMAGE_PNG_SIZE_MAX_(image, PNG_IMAGE_COMPRESSED_SIZE_MAX(image))
   /* An upper bound on the total length of the PNG data stream for 'image'.
    * The result is of type png_alloc_size_t, on 32-bit systems this may
    * overflow even though PNG_IMAGE_DATA_SIZE does not overflow; the write will
    * run out of buffer space but return a corrected size which should work.
    */
#endif /* SIMPLIFIED_WRITE */
/*******************************************************************************
 *  END OF SIMPLIFIED API
 ******************************************************************************/
#endif /* SIMPLIFIED_{READ|WRITE} */

/*******************************************************************************
 * Section 6: IMPLEMENTATION OPTIONS
 *******************************************************************************
 *
 * Support for arbitrary implementation-specific optimizations.  The API allows
 * particular options to be turned on or off.  'Option' is the number of the
 * option and 'onoff' is 0 (off) or non-0 (on).  The value returned is given
 * by the PNG_OPTION_ defines below.
 *
 * HARDWARE: normally hardware capabilites, such as the Intel SSE instructions,
 *           are detected at run time, however sometimes it may be impossible
 *           to do this in user mode, in which case it is necessary to discover
 *           the capabilities in an OS specific way.  Such capabilities are
 *           listed here when libpng has support for them and must be turned
 *           ON by the application if present.
 *
 * SOFTWARE: sometimes software optimizations actually result in performance
 *           decrease on some architectures or systems, or with some sets of
 *           PNG images.  'Software' options allow such optimizations to be
 *           selected at run time.
 */
#ifdef PNG_SET_OPTION_SUPPORTED
#ifdef PNG_ARM_NEON_API_SUPPORTED
#  define PNG_ARM_NEON   0 /* HARDWARE: ARM Neon SIMD instructions supported */
#endif
#define PNG_MAXIMUM_INFLATE_WINDOW 2 /* SOFTWARE: force maximum window */
#define PNG_SKIP_sRGB_CHECK_PROFILE 4 /* SOFTWARE: Check ICC profile for sRGB */
#define PNG_OPTION_NEXT  6 /* Next option - numbers must be even */

/* Return values: NOTE: there are four values and 'off' is *not* zero */
#define PNG_OPTION_UNSET   0 /* Unset - defaults to off */
#define PNG_OPTION_INVALID 1 /* Option number out of range */
#define PNG_OPTION_OFF     2
#define PNG_OPTION_ON      3

PNG_EXPORT(244, int, png_set_option, (png_structrp png_ptr, int option,
   int onoff));
#endif /* SET_OPTION */

/*******************************************************************************
 *  END OF HARDWARE AND SOFTWARE OPTIONS
 ******************************************************************************/

/* Maintainer: Put new public prototypes here ^, in libpng.3, in project
 * defs, and in scripts/symbols.def.
 */

/* The last ordinal number (this is the *last* one already used; the next
 * one to use is one more than this.)
 */
#ifdef PNG_EXPORT_LAST_ORDINAL
  PNG_EXPORT_LAST_ORDINAL(245);
#endif

#ifdef __cplusplus
}
#endif

#endif /* PNG_VERSION_INFO_ONLY */
/* Do not put anything past this line */
#endif /* PNG_H */
