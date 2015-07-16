/* Modified for Chromium to support stlport and libc++ adaptively */
/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

/* We want to detect which header files to include for the unordered (hash)
   collections standardized in C++11 but first introduced as part of TR1.
   Specifically, we want to avoid including ext/ headers when using libc++ as
   it will generate noisy build warnings.

   We take a several-tier approach. First, attempt to use clang's __has_include
   and test for libc++'s configuration header. If that isn't available, include
   <new> which will define libc++'s version macro (if using libc++).

   There are no really good alternative headers that do less work. For example,
   ciso646 and cstdbool and commonly recommended, but they both have issues.
   The first has side effects with MSVC, and the second does not exists on Apple
   platforms (the system libstdc++ is too old).

   This dynamic check is necessary to allow using this normally dynamically
   generated header with Chromium's many supported build configurations. It
   should be expanded to import the right header on other platforms as
   desired. */

#if defined(__has_include)
#if __has_include(<__config>)
#include <__config>
#else // __has_include(<__config>)
#include <new>
#endif // __has_include(<__config>)
#endif // defined(__has_include)

/* the name of <hash_map> */
#if defined(_LIBCPP_VERSION)
#define HASH_MAP_CLASS unordered_map
#else
#define HASH_MAP_CLASS hash_map
#endif

/* the location of <unordered_map> or <hash_map> */
#if defined(USE_STLPORT)
#define HASH_MAP_H <hash_map>
#elif defined(_LIBCPP_VERSION)
#define HASH_MAP_H <unordered_map>
#else
#define HASH_MAP_H <ext/hash_map>
#endif

/* the namespace of hash_map/hash_set */
#if defined(USE_STLPORT) || defined(_LIBCPP_VERSION)
#define HASH_NAMESPACE std
#else
#define HASH_NAMESPACE __gnu_cxx
#endif

/* the name of <hash_set> */
#if defined(_LIBCPP_VERSION)
#define HASH_SET_CLASS unordered_set
#else
#define HASH_SET_CLASS hash_set
#endif

/* the location of <unordered_set> or <hash_set> */
#if defined(USE_STLPORT)
#define HASH_SET_H <hash_set>
#elif defined(_LIBCPP_VERSION)
#define HASH_SET_H <unordered_set>
#else
#define HASH_SET_H <ext/hash_set>
#endif

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the `ftruncate' function. */
#define HAVE_FTRUNCATE 1

/* define if the compiler has hash_map */
#define HAVE_HASH_MAP 1

/* define if the compiler has hash_set */
#define HAVE_HASH_SET 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <limits.h> header file. */
#define HAVE_LIMITS_H 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* Define to 1 if you have the `mkdir' function. */
#define HAVE_MKDIR 1

/* Define if you have POSIX threads libraries and header files. */
#define HAVE_PTHREAD 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strchr' function. */
#define HAVE_STRCHR 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strtol' function. */
#define HAVE_STRTOL 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Enable classes using zlib compression. */
#define HAVE_ZLIB 1

/* Name of package */
#define PACKAGE "protobuf"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "protobuf@googlegroups.com"

/* Define to the full name of this package. */
#define PACKAGE_NAME "Protocol Buffers"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "Protocol Buffers 2.3.0"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "protobuf"

/* Define to the version of this package. */
#define PACKAGE_VERSION "2.3.0"

/* Define to necessary symbol if this constant uses a non-standard name on
   your system. */
/* #undef PTHREAD_CREATE_JOINABLE */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Version number of package */
#define VERSION "2.3.0"

/* Define to 1 if on AIX 3.
   System headers sometimes define this.
   We just want to avoid a redefinition error message.  */
#ifndef _ALL_SOURCE
/* # undef _ALL_SOURCE */
#endif

/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif

/* Define to 1 if on MINIX. */
/* #undef _MINIX */

/* Define to 2 if the system does not provide POSIX.1 features except with
   this defined. */
/* #undef _POSIX_1_SOURCE */

/* Define to 1 if you need to in order for `stat' and other things to work. */
/* #undef _POSIX_SOURCE */

/* Enable extensions on Solaris.  */
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
