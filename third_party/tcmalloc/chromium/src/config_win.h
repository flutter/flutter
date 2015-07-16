/* A manual version of config.h fit for windows machines. */

/* Sometimes we accidentally #include this config.h instead of the one
   in .. -- this is particularly true for msys/mingw, which uses the
   unix config.h but also runs code in the windows directory.
   */
#ifdef __MINGW32__
#include "../config.h"
#define GOOGLE_PERFTOOLS_WINDOWS_CONFIG_H_
#endif

#ifndef GOOGLE_PERFTOOLS_WINDOWS_CONFIG_H_
#define GOOGLE_PERFTOOLS_WINDOWS_CONFIG_H_

/* define this if you are linking tcmalloc statically and overriding the
 * default allocators.
 * For instructions on how to use this mode, see
 * http://groups.google.com/group/google-perftools/browse_thread/thread/41cd3710af85e57b
 */
#define WIN32_OVERRIDE_ALLOCATORS

/* the location of <hash_map> */
#define HASH_MAP_H  <hash_map>

/* the namespace of hash_map/hash_set */
#define HASH_NAMESPACE  stdext

/* the location of <hash_set> */
#define HASH_SET_H  <hash_set>

/* Define to 1 if your libc has a snprintf implementation */
#undef HAVE_SNPRINTF

/* Define to 1 if compiler supports __builtin_stack_pointer */
#undef HAVE_BUILTIN_STACK_POINTER

/* Define to 1 if you have the <conflict-signal.h> header file. */
#undef HAVE_CONFLICT_SIGNAL_H

/* Define to 1 if you have the <cygwin/signal.h> header file. */
#undef HAVE_CYGWIN_SIGNAL_H

/* Define to 1 if you have the declaration of `cfree', and to 0 if you don't.
   */
#undef HAVE_DECL_CFREE

/* Define to 1 if you have the declaration of `memalign', and to 0 if you
   don't. */
#undef HAVE_DECL_MEMALIGN

/* Define to 1 if you have the declaration of `posix_memalign', and to 0 if
   you don't. */
#undef HAVE_DECL_POSIX_MEMALIGN

/* Define to 1 if you have the declaration of `pvalloc', and to 0 if you
   don't. */
#undef HAVE_DECL_PVALLOC

/* Define to 1 if you have the declaration of `uname', and to 0 if you don't.
   */
#undef HAVE_DECL_UNAME

/* Define to 1 if you have the declaration of `valloc', and to 0 if you don't.
   */
#undef HAVE_DECL_VALLOC

/* Define to 1 if you have the <dlfcn.h> header file. */
#undef HAVE_DLFCN_H

/* Define to 1 if the system has the type `Elf32_Versym'. */
#undef HAVE_ELF32_VERSYM

/* Define to 1 if you have the <execinfo.h> header file. */
#undef HAVE_EXECINFO_H

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the <features.h> header file. */
#undef HAVE_FEATURES_H

/* Define to 1 if you have the `geteuid' function. */
#undef HAVE_GETEUID

/* Define to 1 if you have the `getpagesize' function. */
#define HAVE_GETPAGESIZE 1   /* we define it in windows/port.cc */

/* Define to 1 if you have the <glob.h> header file. */
#undef HAVE_GLOB_H

/* Define to 1 if you have the <grp.h> header file. */
#undef HAVE_GRP_H

/* define if the compiler has hash_map */
#define HAVE_HASH_MAP 1

/* define if the compiler has hash_set */
#define HAVE_HASH_SET 1

/* Define to 1 if you have the <inttypes.h> header file. */
#undef HAVE_INTTYPES_H

/* Define to 1 if you have the <libunwind.h> header file. */
#undef HAVE_LIBUNWIND_H

/* Define to 1 if you have the <linux/ptrace.h> header file. */
#undef HAVE_LINUX_PTRACE_H

/* Define to 1 if you have the <malloc.h> header file. */
#undef HAVE_MALLOC_H

/* Define to 1 if you have the <malloc/malloc.h> header file. */
#undef HAVE_MALLOC_MALLOC_H

/* Define to 1 if you have the <memory.h> header file. */
#undef HAVE_MEMORY_H

/* Define to 1 if you have a working `mmap' system call. */
#undef HAVE_MMAP

/* define if the compiler implements namespaces */
#define HAVE_NAMESPACES 1

/* Define to 1 if you have the <poll.h> header file. */
#undef HAVE_POLL_H

/* define if libc has program_invocation_name */
#undef HAVE_PROGRAM_INVOCATION_NAME

/* Define if you have POSIX threads libraries and header files. */
#undef HAVE_PTHREAD

/* Define to 1 if you have the <pwd.h> header file. */
#undef HAVE_PWD_H

/* Define to 1 if you have the `sbrk' function. */
#undef HAVE_SBRK
/* Define to 1 if you have the <sched.h> header file. */
#undef HAVE_SCHED_H

/* Define to 1 if you have the <stdint.h> header file. */
#undef HAVE_STDINT_H

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#undef HAVE_STRINGS_H

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if the system has the type `struct mallinfo'. */
#undef HAVE_STRUCT_MALLINFO

/* Define to 1 if you have the <sys/cdefs.h> header file. */
#undef HAVE_SYS_CDEFS_H

/* Define to 1 if you have the <sys/malloc.h> header file. */
#undef HAVE_SYS_MALLOC_H

/* Define to 1 if you have the <sys/param.h> header file. */
#undef HAVE_SYS_PARAM_H

/* Define to 1 if you have the <sys/prctl.h> header file. */
#undef HAVE_SYS_PRCTL_H

/* Define to 1 if you have the <sys/resource.h> header file. */
#undef HAVE_SYS_RESOURCE_H

/* Define to 1 if you have the <sys/socket.h> header file. */
#undef HAVE_SYS_SOCKET_H

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/syscall.h> header file. */
#undef HAVE_SYS_SYSCALL_H

/* Define to 1 if you have the <sys/time.h> header file. */
#undef HAVE_SYS_TIME_H

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* <sys/ucontext.h> is broken on redhat 7 */
#undef HAVE_SYS_UCONTEXT_H

/* Define to 1 if you have the <sys/wait.h> header file. */
#undef HAVE_SYS_WAIT_H

/* Define to 1 if compiler supports __thread */
#undef HAVE_TLS

/* Define to 1 if you have the <ucontext.h> header file. */
#undef HAVE_UCONTEXT_H

/* Define to 1 if you have the <unistd.h> header file. */
#undef HAVE_UNISTD_H

/* Define to 1 if you have the <unwind.h> header file. */
#undef HAVE_UNWIND_H

/* define if your compiler has __attribute__ */
#undef HAVE___ATTRIBUTE__

/* Define to 1 if compiler supports __environ */
#undef HAVE___ENVIRON

/* Define to 1 if the system has the type `__int64'. */
#define HAVE___INT64 1

/* prefix where we look for installed files */
#undef INSTALL_PREFIX

/* Define to 1 if int32_t is equivalent to intptr_t */
#undef INT32_EQUALS_INTPTR

/* Define to the sub-directory in which libtool stores uninstalled libraries.
   */
#undef LT_OBJDIR

/* Define to 1 if your C compiler doesn't accept -c and -o together. */
#undef NO_MINUS_C_MINUS_O

/* Name of package */
#undef PACKAGE

/* Define to the address where bug reports for this package should be sent. */
#undef PACKAGE_BUGREPORT

/* Define to the full name of this package. */
#undef PACKAGE_NAME

/* Define to the full name and version of this package. */
#undef PACKAGE_STRING

/* Define to the one symbol short name of this package. */
#undef PACKAGE_TARNAME

/* Define to the home page for this package. */
#undef PACKAGE_URL

/* Define to the version of this package. */
#undef PACKAGE_VERSION

/* How to access the PC from a struct ucontext */
#undef PC_FROM_UCONTEXT

/* Always the empty-string on non-windows systems. On windows, should be
   "__declspec(dllexport)". This way, when we compile the dll, we export our
   functions/classes. It's safe to define this here because config.h is only
   used internally, to compile the DLL, and every DLL source file #includes
   "config.h" before anything else. */
#ifndef PERFTOOLS_DLL_DECL
# define PERFTOOLS_IS_A_DLL  1   /* not set if you're statically linking */
# define PERFTOOLS_DLL_DECL  __declspec(dllexport)
# define PERFTOOLS_DLL_DECL_FOR_UNITTESTS  __declspec(dllimport)
#endif

/* printf format code for printing a size_t and ssize_t */
#define PRIdS  "Id"

/* printf format code for printing a size_t and ssize_t */
#define PRIuS  "Iu"

/* printf format code for printing a size_t and ssize_t */
#define PRIxS  "Ix"

/* Define to necessary symbol if this constant uses a non-standard name on
   your system. */
#undef PTHREAD_CREATE_JOINABLE

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* the namespace where STL code like vector<> is defined */
#define STL_NAMESPACE  std

/* Version number of package */
#undef VERSION

/* C99 says: define this to get the PRI... macros from stdint.h */
#ifndef __STDC_FORMAT_MACROS
# define __STDC_FORMAT_MACROS 1
#endif

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
#undef inline
#endif

// ---------------------------------------------------------------------
// Extra stuff not found in config.h.in

// This must be defined before the windows.h is included.  We need at
// least 0x0400 for mutex.h to have access to TryLock, and at least
// 0x0501 for patch_functions.cc to have access to GetModuleHandleEx.
// (This latter is an optimization we could take out if need be.)
#ifndef _WIN32_WINNT
# define _WIN32_WINNT 0x0501
#endif

// We want to make sure not to ever try to #include heap-checker.h
#define NO_HEAP_CHECK 1

// TODO(csilvers): include windows/port.h in every relevant source file instead?
#include "windows/port.h"

#endif  /* GOOGLE_PERFTOOLS_WINDOWS_CONFIG_H_ */
