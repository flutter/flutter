/*
 * Copyright (C) 2006 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef SkUserConfig_DEFINED
#define SkUserConfig_DEFINED

/*  SkTypes.h, the root of the public header files, does the following trick:

    #include <SkPreConfig.h>
    #include <SkUserConfig.h>
    #include <SkPostConfig.h>

    SkPreConfig.h runs first, and it is responsible for initializing certain
    skia defines.

    SkPostConfig.h runs last, and its job is to just check that the final
    defines are consistent (i.e. that we don't have mutually conflicting
    defines).

    SkUserConfig.h (this file) runs in the middle. It gets to change or augment
    the list of flags initially set in preconfig, and then postconfig checks
    that everything still makes sense.

    Below are optional defines that add, subtract, or change default behavior
    in Skia. Your port can locally edit this file to enable/disable flags as
    you choose, or these can be delared on your command line (i.e. -Dfoo).

    By default, this include file will always default to having all of the flags
    commented out, so including it will have no effect.
*/

///////////////////////////////////////////////////////////////////////////////

/*  Scalars (the fractional value type in skia) can be implemented either as
    floats or 16.16 integers (fixed). Exactly one of these two symbols must be
    defined.
*/
//#define SK_SCALAR_IS_FLOAT
//#define SK_SCALAR_IS_FIXED


/*  Somewhat independent of how SkScalar is implemented, Skia also wants to know
    if it can use floats at all. Naturally, if SK_SCALAR_IS_FLOAT is defined,
    then so muse SK_CAN_USE_FLOAT, but if scalars are fixed, SK_CAN_USE_FLOAT
    can go either way.
 */
//#define SK_CAN_USE_FLOAT

/*  For some performance-critical scalar operations, skia will optionally work
    around the standard float operators if it knows that the CPU does not have
    native support for floats. If your environment uses software floating point,
    define this flag.
 */
//#define SK_SOFTWARE_FLOAT


/*  Skia has lots of debug-only code. Often this is just null checks or other
    parameter checking, but sometimes it can be quite intrusive (e.g. check that
    each 32bit pixel is in premultiplied form). This code can be very useful
    during development, but will slow things down in a shipping product.

    By default, these mutually exclusive flags are defined in SkPreConfig.h,
    based on the presence or absence of NDEBUG, but that decision can be changed
    here.
 */
//#define SK_DEBUG
//#define SK_RELEASE

#ifdef DCHECK_ALWAYS_ON
    #undef SK_RELEASE
    #define SK_DEBUG
#endif

/*  If, in debugging mode, Skia needs to stop (presumably to invoke a debugger)
    it will call SK_CRASH(). If this is not defined it, it is defined in
    SkPostConfig.h to write to an illegal address
 */
//#define SK_CRASH() *(int *)(uintptr_t)0 = 0


/*  preconfig will have attempted to determine the endianness of the system,
    but you can change these mutually exclusive flags here.
 */
//#define SK_CPU_BENDIAN
//#define SK_CPU_LENDIAN


/*  Some compilers don't support long long for 64bit integers. If yours does
    not, define this to the appropriate type.
 */
//#define SkLONGLONG int64_t


/*  Some envorinments do not suport writable globals (eek!). If yours does not,
    define this flag.
 */
//#define SK_USE_RUNTIME_GLOBALS

/*  If zlib is available and you want to support the flate compression
    algorithm (used in PDF generation), define SK_ZLIB_INCLUDE to be the
    include path.
 */
//#define SK_ZLIB_INCLUDE <zlib.h>
#define SK_ZLIB_INCLUDE "third_party/zlib/zlib.h"

/*  Define this to allow PDF scalars above 32k.  The PDF/A spec doesn't allow
    them, but modern PDF interpreters should handle them just fine.
 */
//#define SK_ALLOW_LARGE_PDF_SCALARS

/*  Define this to provide font subsetter for font subsetting when generating
    PDF documents.
 */
#define SK_SFNTLY_SUBSETTER \
    "third_party/sfntly/cpp/src/sample/chromium/font_subsetter.h"

/*  To write debug messages to a console, skia will call SkDebugf(...) following
    printf conventions (e.g. const char* format, ...). If you want to redirect
    this to something other than printf, define yours here
 */
//#define SkDebugf(...)  MyFunction(__VA_ARGS__)


/*  If SK_DEBUG is defined, then you can optionally define SK_SUPPORT_UNITTEST
    which will run additional self-tests at startup. These can take a long time,
    so this flag is optional.
 */
#ifdef SK_DEBUG
#define SK_SUPPORT_UNITTEST
#endif

/* If cross process SkPictureImageFilters are not explicitly enabled then
   they are always disabled.
 */
#ifndef SK_ALLOW_CROSSPROCESS_PICTUREIMAGEFILTERS
    #ifndef SK_DISALLOW_CROSSPROCESS_PICTUREIMAGEFILTERS
        #define SK_DISALLOW_CROSSPROCESS_PICTUREIMAGEFILTERS
    #endif
#endif


/* If your system embeds skia and has complex event logging, define this
   symbol to name a file that maps the following macros to your system's
   equivalents:
       SK_TRACE_EVENT0(event)
       SK_TRACE_EVENT1(event, name1, value1)
       SK_TRACE_EVENT2(event, name1, value1, name2, value2)
   src/utils/SkDebugTrace.h has a trivial implementation that writes to
   the debug output stream. If SK_USER_TRACE_INCLUDE_FILE is not defined,
   SkTrace.h will define the above three macros to do nothing.
*/
#undef SK_USER_TRACE_INCLUDE_FILE

// ===== Begin Chrome-specific definitions =====

#ifdef SK_DEBUG
#define SK_REF_CNT_MIXIN_INCLUDE "sk_ref_cnt_ext_debug.h"
#else
#define SK_REF_CNT_MIXIN_INCLUDE "sk_ref_cnt_ext_release.h"
#endif

#define SK_SCALAR_IS_FLOAT
#undef SK_SCALAR_IS_FIXED

#define SK_MSCALAR_IS_FLOAT
#undef SK_MSCALAR_IS_DOUBLE

#define GR_MAX_OFFSCREEN_AA_DIM     512

// Log the file and line number for assertions.
#define SkDebugf(...) SkDebugf_FileLine(__FILE__, __LINE__, false, __VA_ARGS__)
SK_API void SkDebugf_FileLine(const char* file, int line, bool fatal,
                              const char* format, ...);

// Marking the debug print as "fatal" will cause a debug break, so we don't need
// a separate crash call here.
#define SK_DEBUGBREAK(cond) do { if (!(cond)) { \
    SkDebugf_FileLine(__FILE__, __LINE__, true, \
    "%s:%d: failed assertion \"%s\"\n", \
    __FILE__, __LINE__, #cond); } } while (false)

#if defined(SK_BUILD_FOR_WIN32)

#define SK_BUILD_FOR_WIN

// Skia uses this deprecated bzero function to fill zeros into a string.
#define bzero(str, len) memset(str, 0, len)

#elif defined(SK_BUILD_FOR_MAC)

#define SK_CPU_LENDIAN
#undef  SK_CPU_BENDIAN

#elif defined(SK_BUILD_FOR_UNIX) || defined(SK_BUILD_FOR_ANDROID)

// Prefer FreeType's emboldening algorithm to Skia's
// TODO: skia used to just use hairline, but has improved since then, so
// we should revisit this choice...
#define SK_USE_FREETYPE_EMBOLDEN

#if defined(SK_BUILD_FOR_UNIX) && defined(SK_CPU_BENDIAN)
// Above we set the order for ARGB channels in registers. I suspect that, on
// big endian machines, you can keep this the same and everything will work.
// The in-memory order will be different, of course, but as long as everything
// is reading memory as words rather than bytes, it will all work. However, if
// you find that colours are messed up I thought that I would leave a helpful
// locator for you. Also see the comments in
// base/gfx/bitmap_platform_device_linux.h
#error Read the comment at this location
#endif

#endif

// The default crash macro writes to badbeef which can cause some strange
// problems. Instead, pipe this through to the logging function as a fatal
// assertion.
#define SK_CRASH() SkDebugf_FileLine(__FILE__, __LINE__, true, "SK_CRASH")

// These flags are no longer defined in Skia, but we have them (temporarily)
// until we update our call-sites (typically these are for API changes).
//
// Remove these as we update our sites.
//
#ifndef    SK_SUPPORT_LEGACY_GETTOPDEVICE
#   define SK_SUPPORT_LEGACY_GETTOPDEVICE
#endif

#ifndef    SK_LEGACY_DRAWPICTURECALLBACK
#   define SK_LEGACY_DRAWPICTURECALLBACK
#endif

#ifndef    SK_SUPPORT_LEGACY_GETDEVICE
#   define SK_SUPPORT_LEGACY_GETDEVICE
#endif

#ifndef    SK_SUPPORT_LEGACY_PUBLIC_IMAGEINFO_FIELDS
#   define SK_SUPPORT_LEGACY_PUBLIC_IMAGEINFO_FIELDS
#endif

#ifndef    SK_IGNORE_ETC1_SUPPORT
#   define SK_IGNORE_ETC1_SUPPORT
#endif

#ifndef    SK_SUPPORT_LEGACY_BOOL_ONGETINFO
#   define SK_SUPPORT_LEGACY_BOOL_ONGETINFO
#endif

#ifndef    SK_IGNORE_GPU_DITHER
#   define SK_IGNORE_GPU_DITHER
#endif

#ifndef    SK_SUPPORT_LEGACY_INT_COLORMATRIX
#   define SK_SUPPORT_LEGACY_INT_COLORMATRIX
#endif

#ifndef    SK_LEGACY_STROKE_CURVES
#   define SK_LEGACY_STROKE_CURVES
#endif

///////////////////////// Imported from BUILD.gn and skia_common.gypi

/* In some places Skia can use static initializers for global initialization,
 *  or fall back to lazy runtime initialization. Chrome always wants the latter.
 */
#define SK_ALLOW_STATIC_GLOBAL_INITIALIZERS 0

/* Forcing the unoptimized path for the offset image filter in skia until
 * all filters used in Blink support the optimized path properly
 */
#define SK_DISABLE_OFFSETIMAGEFILTER_OPTIMIZATION

/* This flag forces Skia not to use typographic metrics with GDI.
 */
#define SK_GDI_ALWAYS_USE_TEXTMETRICS_FOR_FONT_METRICS

#define IGNORE_ROT_AA_RECT_OPT
#define SK_IGNORE_BLURRED_RRECT_OPT
#define SK_USE_DISCARDABLE_SCALEDIMAGECACHE
#define SK_WILL_NEVER_DRAW_PERSPECTIVE_TEXT

#define SK_ATTR_DEPRECATED          SK_NOTHING_ARG1
#define SK_ENABLE_INST_COUNT        0
#define GR_GL_CUSTOM_SETUP_HEADER   "GrGLConfig_chrome.h"

// ===== End Chrome-specific definitions =====

#endif
