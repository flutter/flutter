## Process this file with autoconf to produce configure.
## In general, the safest way to proceed is to run ./autogen.sh

# make sure we're interpreted by some minimal autoconf
AC_PREREQ(2.57)

AC_INIT(gperftools, 2.0, google-perftools@googlegroups.com)
# Update this value for every release!  (A:B:C will map to foo.so.(A-C).C.B)
# http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
TCMALLOC_SO_VERSION=5:0:1
PROFILER_SO_VERSION=3:0:3

AC_SUBST(TCMALLOC_SO_VERSION)
AC_SUBST(PROFILER_SO_VERSION)

# The argument here is just something that should be in the current directory
# (for sanity checking)
AC_CONFIG_SRCDIR(README)
AC_CONFIG_MACRO_DIR([m4])
AC_CANONICAL_HOST
AM_INIT_AUTOMAKE([dist-zip])
AM_CONFIG_HEADER(src/config.h)

# Export the version information (for tc_version and friends)
TC_VERSION_MAJOR=`expr "$PACKAGE_VERSION" : '\([[0-9]]*\)'`
TC_VERSION_MINOR=`expr "$PACKAGE_VERSION" : '[[0-9]]*\.\([[0-9]]*\)'`
TC_VERSION_PATCH=`expr "$PACKAGE_VERSION" : '[[0-9]]*\.[[0-9]]*\(.*\)$'`
AC_SUBST(TC_VERSION_MAJOR)
AC_SUBST(TC_VERSION_MINOR)
AC_SUBST(TC_VERSION_PATCH)
AC_SUBST(PACKAGE_STRING)

# The user can choose not to compile in the heap-profiler, the
# heap-checker, or the cpu-profiler.  There's also the possibility
# for a 'fully minimal' compile, which leaves out the stacktrace
# code as well.  By default, we include all of these that the
# target system supports.
default_enable_cpu_profiler=yes
default_enable_heap_profiler=yes
default_enable_heap_checker=yes
default_enable_debugalloc=yes
default_enable_minimal=no
need_nanosleep=yes   # Used later, to decide if to run ACX_NANOSLEEP
case "$host" in
   *-mingw*) default_enable_minimal=yes; default_enable_debugalloc=no;
             need_nanosleep=no;;
   *-cygwin*) default_enable_heap_checker=no; default_enable_cpu_profiler=no;;
   *-freebsd*) default_enable_heap_checker=no;;
   *-darwin*) default_enable_heap_checker=no;;
esac

AC_ARG_ENABLE([cpu-profiler],
              [AS_HELP_STRING([--disable-cpu-profiler],
                              [do not build the cpu profiler])],
              [],
              [enable_cpu_profiler="$default_enable_cpu_profiler"])
AC_ARG_ENABLE([heap-profiler],
              [AS_HELP_STRING([--disable-heap-profiler],
                              [do not build the heap profiler])],
              [],
              [enable_heap_profiler="$default_enable_heap_profiler"])
AC_ARG_ENABLE([heap-checker],
              [AS_HELP_STRING([--disable-heap-checker],
                              [do not build the heap checker])],
              [],
              [enable_heap_checker="$default_enable_heap_checker"])
AC_ARG_ENABLE([debugalloc],
              [AS_HELP_STRING([--disable-debugalloc],
                              [do not build versions of libs with debugalloc])],
              [],
              [enable_debugalloc="$default_enable_debugalloc"])
AC_ARG_ENABLE([minimal],
              [AS_HELP_STRING([--enable-minimal],
                              [build only tcmalloc-minimal (and maybe tcmalloc-minimal-debug)])],
              [],
              [enable_minimal="$default_enable_minimal"])
if test "$enable_minimal" = yes; then
  enable_cpu_profiler=no
  enable_heap_profiler=no
  enable_heap_checker=no
fi


# Checks for programs.
AC_PROG_CXX
AC_PROG_CC
AC_PROG_CPP
AM_CONDITIONAL(GCC, test "$GCC" = yes)   # let the Makefile know if we're gcc
AM_PROG_CC_C_O      # shrug: autogen.sh suddenly needs this for some reason

# Check if we have an objcopy installed that supports -W
AC_CHECK_TOOL([OBJCOPY], [objcopy], [])
AS_IF([test -n "$OBJCOPY"], [dnl
  AC_CACHE_CHECK([if $OBJCOPY supports -W], gpt_cv_objcopy_weaken, [dnl
    AC_LINK_IFELSE([void foo() {} int main() {return 0;}], [dnl
      AS_IF(["$OBJCOPY" -W foo conftest$ac_exeext /dev/null],
      	    [gpt_cv_objcopy_weaken=yes], [gpt_cv_objcopy_weaken=no])],
    [gpt_cv_objcopy_weaken=no])])],
  [gpt_cv_objcopy_weaken=no])
AM_CONDITIONAL(HAVE_OBJCOPY_WEAKEN, test $gpt_cv_objcopy_weaken = yes)

case $host_os in
  *mingw*)
    # Disabling fast install keeps libtool from creating wrapper scripts
    # around the executables it builds.  Such scripts have caused failures on
    # MinGW.  Using this option means an extra link step is executed during
    # "make install".
    AC_DISABLE_FAST_INSTALL
    ;;
   *)
    AC_ENABLE_FAST_INSTALL
    ;;
esac

AC_PROG_LIBTOOL
AC_SUBST(LIBTOOL_DEPS)
AM_CONDITIONAL(USE_LIBTOOL, test "x$LIBTOOL" != "x")

AC_C_INLINE
AX_C___ATTRIBUTE__

# Check whether some low-level functions/files are available
AC_HEADER_STDC

# TODO(csilvers): we could remove a lot when WITH_CPU_PROFILER etc is "no".
AC_CHECK_TYPES([__int64])       # defined in some windows platforms
AC_CHECK_TYPES([struct mallinfo],,, [#include <malloc.h>])
AC_CHECK_TYPES([Elf32_Versym],,, [#include <elf.h>])   # for vdso_support.h
AC_CHECK_FUNCS(sbrk)            # for tcmalloc to get memory
AC_CHECK_FUNCS(geteuid)         # for turning off services when run as root
AC_CHECK_HEADERS(features.h)    # for vdso_support.h
AC_CHECK_HEADERS(malloc.h)      # some systems define stuff there, others not
AC_CHECK_HEADERS(sys/malloc.h)  # where some versions of OS X put malloc.h
AC_CHECK_HEADERS(malloc/malloc.h)  # another place OS X puts malloc.h (?)
AC_CHECK_HEADERS(glob.h)        # for heap-profile-table (cleaning up profiles)
AC_CHECK_HEADERS(execinfo.h)    # for stacktrace? and heapchecker_unittest
AC_CHECK_HEADERS(libunwind.h)   # for stacktrace
AC_CHECK_HEADERS(unwind.h)      # for stacktrace
AC_CHECK_HEADERS(sched.h)       # for being nice in our spinlock code
AC_CHECK_HEADERS(conflict-signal.h)      # defined on some windows platforms?
AC_CHECK_HEADERS(sys/prctl.h)   # for thread_lister (needed by leak-checker)
AC_CHECK_HEADERS(linux/ptrace.h)# also needed by leak-checker
AC_CHECK_HEADERS(sys/syscall.h)
AC_CHECK_HEADERS(sys/socket.h)  # optional; for forking out to symbolizer
AC_CHECK_HEADERS(sys/wait.h)    # optional; for forking out to symbolizer
AC_CHECK_HEADERS(poll.h)        # optional; for forking out to symbolizer
AC_CHECK_HEADERS(fcntl.h)       # for tcmalloc_unittest
AC_CHECK_HEADERS(grp.h)         # for heapchecker_unittest
AC_CHECK_HEADERS(pwd.h)         # for heapchecker_unittest
AC_CHECK_HEADERS(sys/resource.h)         # for memalign_unittest.cc
AC_CHECK_HEADERS(valgrind.h)    # we have a local copy if this isn't found
AC_CHECK_HEADERS(sys/cdefs.h)   # Where glibc defines __THROW
AC_CHECK_HEADERS(features.h)    # Where __GLIBC__ is defined
# We also need <ucontext.h>/<sys/ucontext.h>, but we get those from
# AC_PC_FROM_UCONTEXT, below.

# We override a lot of memory allocation routines, not all of which are
# standard.  For those the system doesn't declare, we'll declare ourselves.
AC_CHECK_DECLS([cfree,
                posix_memalign,
                memalign,
                valloc,
                pvalloc],,,
               [#define _XOPEN_SOURCE 600
                #include <stdlib.h>
                #include <malloc.h>])

if test "$ac_cv_type_struct_mallinfo" = yes; then
  AC_SUBST(ac_cv_have_struct_mallinfo, 1)   # gperftools/tcmalloc.h needs this
else
  AC_SUBST(ac_cv_have_struct_mallinfo, 0)
fi

# We need to check for mmap.  cygwin supports mmap, but the autoconf
# test doesn't work on cygwin:
#    http://www.cygwin.com/ml/cygwin/2002-04/msg00412.html
# This workaround comes from
#    http://cygwin.com/ml/cygwin/2004-11/msg00138.html
case "$host" in
  *-*-cygwin*)
	       ac_cv_func_mmap_fixed_mapped=yes
               AC_DEFINE(HAVE_MMAP, 1,
                         [Define to 1 if you have a working `mmap' system call.])
               ;;
            *) AC_FUNC_MMAP
               ;;
esac

# If AtomicWord != Atomic32, we need to define two versions of all the
# atomicops functions.  If they're the same, we want to define only one.
AC_MSG_CHECKING([if int32_t is the same type as intptr_t])
AC_TRY_COMPILE([#include <stdint.h>],
	       [int32_t v1 = 0; intptr_t v2 = 0; return (&v1 - &v2)],
               [AC_DEFINE(INT32_EQUALS_INTPTR, 1,
                          Define to 1 if int32_t is equivalent to intptr_t)
                AC_MSG_RESULT([yes])],
               [AC_MSG_RESULT([no])])

# We want to access the "PC" (Program Counter) register from a struct
# ucontext.  Every system has its own way of doing that.  We try all the
# possibilities we know about.  Note REG_PC should come first (REG_RIP
# is also defined on solaris, but does the wrong thing).  But don't
# bother if we're not doing cpu-profiling.
# [*] means that we've not actually tested one of these systems
if test "$enable_cpu_profiler" = yes; then
  AC_PC_FROM_UCONTEXT(AC_MSG_WARN(Could not find the PC.  Will not try to compile libprofiler...);
                      enable_cpu_profiler=no)
fi

# Some tests test the behavior of .so files, and only make sense for dynamic.
AM_CONDITIONAL(ENABLE_STATIC, test "$enable_static" = yes)

# We want to link in libunwind if it exists
AC_CHECK_LIB(unwind, backtrace, UNWIND_LIBS=-lunwind, UNWIND_LIBS=)
AC_SUBST(UNWIND_LIBS)

# On x86_64, instead of libunwind, we can choose to compile with frame-pointers
# (This isn't needed on i386, where -fno-omit-frame-pointer is the default).
AC_ARG_ENABLE(frame_pointers,
              AS_HELP_STRING([--enable-frame-pointers],
                             [On x86_64 systems, compile with -fno-omit-frame-pointer (see INSTALL)]),
	      , enable_frame_pointers=no)
AM_CONDITIONAL(ENABLE_FRAME_POINTERS, test "$enable_frame_pointers" = yes)

# Some x86_64 systems do not insert frame pointers by default (all
# i386 systems that I know of, do.  I don't know about non-x86 chips).
# We want to see if the current system is one of those.
AC_COMPILE_IFELSE([AC_LANG_PROGRAM(, [return __x86_64__ == 1 ? 0 : 1])],
                  [is_x86_64=yes], [is_x86_64=no])
OLD_CFLAGS="$CFLAGS"
CFLAGS="$CFLAGS -S -O2 -o fp.s"
# This test will always fail because we don't name our output file properly.
# We do our own determination of success/failure in the grep, below.
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([int f(int x) {return x;}], [return f(0);])],
                  [:], [:])
AM_CONDITIONAL(X86_64_AND_NO_FP_BY_DEFAULT,
               test "$is_x86_64" = yes && ! grep 'mov.*rsp.*rbp' fp.s >/dev/null 2>&1)
rm fp.s
CFLAGS="$OLD_CFLAGS"

# We need to know if we're i386 so we can turn on -mmms, which is not
# on by default for i386 (it is for x86_64).
AC_COMPILE_IFELSE([AC_LANG_PROGRAM(, [return __i386__ == 1 ? 0 : 1])],
                  [is_i386=yes], [is_i386=no])
AM_CONDITIONAL(I386, test "$is_i386" = yes)

# See if the compiler supports -Wno-unused-result.
# Newer ubuntu's turn on -D_FORTIFY_SOURCE=2, enabling
# __attribute__((warn_unused_result)) for things like write(),
# which we don't care about.
AC_CACHE_CHECK([if the compiler supports -Wno-unused-result],
               perftools_cv_w_no_unused_result,
	       [OLD_CFLAGS="$CFLAGS"
	        CFLAGS="$CFLAGS -Wno-error -Wno-unused-result"
		# gcc doesn't warn about unknown flags unless it's
		# also warning for some other purpose, hence the
		# divide-by-0.  (We use -Wno-error to make sure the
		# divide-by-0 doesn't cause this test to fail!)
	        AC_COMPILE_IFELSE([AC_LANG_PROGRAM(, return 1/0)],
	                          perftools_cv_w_no_unused_result=yes,
                                  perftools_cv_w_no_unused_result=no)
	        CFLAGS="$OLD_CFLAGS"])
AM_CONDITIONAL(HAVE_W_NO_UNUSED_RESULT,
	       test "$perftools_cv_w_no_unused_result" = yes)

# Defines PRIuS
AC_COMPILER_CHARACTERISTICS

# Also make sure we get standard PRI... definitions, even with glibc.
# We have to use AH_VERBATIM because we need the #ifdef guard (gcc buglet)
AH_VERBATIM([__STDC_FORMAT_MACROS],
            [/* C99 says: define this to get the PRI... macros from stdint.h */
#ifndef __STDC_FORMAT_MACROS
# define __STDC_FORMAT_MACROS 1
#endif])

# Check if __builtin_stack_pointer() is available (for elfcore.h)
AC_MSG_CHECKING([for __builtin_stack_pointer()])
AC_LINK_IFELSE([AC_LANG_PROGRAM(, [void *sp = __builtin_stack_pointer()])],
               [AC_DEFINE(HAVE_BUILTIN_STACK_POINTER, 1,
                      Define to 1 if compiler supports __builtin_stack_pointer)
                AC_MSG_RESULT([yes])],
               [AC_MSG_RESULT([no])])

# Check if __environ is available (for GetenvBeforeMain)
AC_MSG_CHECKING([for __environ])
AC_LINK_IFELSE([AC_LANG_PROGRAM([#include <unistd.h>],
                                [char **env = __environ])],
               [AC_DEFINE(HAVE___ENVIRON, 1,
                          [Define to 1 if compiler supports __environ])
                AC_MSG_RESULT([yes])],
               [AC_MSG_RESULT([no])])

# If we support __thread, that can speed up tcmalloc a bit.
# Note, however, that our code tickles a bug in gcc < 4.1.2
# involving TLS and -fPIC (which our libraries will use) on x86:
#   http://gcc.gnu.org/ml/gcc-bugs/2006-09/msg02275.html
AC_MSG_CHECKING([for __thread])
AC_LINK_IFELSE([AC_LANG_PROGRAM([#if defined(__GNUC__) && (defined(__i386__) || defined(__x86_64__)) && ((__GNUC__ < 4) || (__GNUC__ == 4 && __GNUC_MINOR__ < 1) || (__GNUC__ == 4 && __GNUC_MINOR__ == 1 && __GNUC_PATCHLEVEL__ < 2))
#error gcc has this bug: http://gcc.gnu.org/ml/gcc-bugs/2006-09/msg02275.html
#endif], [static __thread int p = 0])],
               [AC_DEFINE(HAVE_TLS, 1,
                          Define to 1 if compiler supports __thread)
                AC_MSG_RESULT([yes])],
               [AC_MSG_RESULT([no])])

# glibc's __malloc_hook/etc were declared volatile starting in glibc 2.14
AC_MSG_CHECKING([if __malloc_hook is declared volatile])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([#include <malloc.h>
void* (* volatile __malloc_hook)(size_t, const void*) = 0;],)],
                  [AC_DEFINE(MALLOC_HOOK_MAYBE_VOLATILE, volatile,
                             Define to 'volatile' if __malloc_hook is declared volatile)
                   AC_MSG_RESULT([yes])],
                  [AC_DEFINE(MALLOC_HOOK_MAYBE_VOLATILE, )
                   AC_MSG_RESULT([no])])

# Nanosleep requires extra libraries on some architectures (solaris).
# This sets NANOSLEEP_LIBS.  nanosleep doesn't exist on mingw, which
# is fine for us because we don't compile libspinlock, which uses it.
if test "$need_nanosleep" = yes; then
  ACX_NANOSLEEP
  AC_SUBST(NANOSLEEP_LIBS)
fi

# Solaris 10 6/06 has a bug where /usr/sfw/lib/libstdc++.la is empty.
# If so, we replace it with our own version.
LIBSTDCXX_LA_LINKER_FLAG=
if test -f /usr/sfw/lib/libstdc++.la && ! test -s /usr/sfw/lib/libstdc++.la
then
  LIBSTDCXX_LA_LINKER_FLAG='-L$(top_srcdir)/src/solaris'
fi
AC_SUBST(LIBSTDCXX_LA_LINKER_FLAG)

# We also need to check if the kernel supports __thread, which requires uname()
AC_CHECK_DECLS(uname,,, [#include <sys/utsname.h>])

# In fact, a lot of the code in this directory depends on pthreads
ACX_PTHREAD

# Find out what namespace 'normal' STL code lives in
AC_CXX_STL_NAMESPACE

# Figure out where libc has program_invocation_name
AC_PROGRAM_INVOCATION_NAME

# Make the install prefix available, to figure out where to look for pprof
AC_INSTALL_PREFIX

# For windows, this has a non-trivial value (__declspec(export)), but any
# system that uses configure wants this to be the empty string.
AC_DEFINE(PERFTOOLS_DLL_DECL,,
          [Always the empty-string on non-windows systems.
           On windows, should be "__declspec(dllexport)".
	   This way, when we compile the dll, we export our functions/classes.
	   It's safe to define this here because config.h is only used
	   internally, to compile the DLL, and every DLL source file
	   #includes "config.h" before anything else.])

# In theory, config.h files shouldn't need a header guard, but we do,
# because we (maybe) #include windows/mingw.h from within config.h,
# and it #includes other .h files.  These all have header guards, so
# the end result is if config.h is #included twice, its #undefs get
# evaluated twice, but all the ones in mingw.h/etc only get evaluated
# once, potentially causing trouble.  c.f.
#   http://code.google.com/p/gperftools/issues/detail?id=246
AH_TOP([
#ifndef GPERFTOOLS_CONFIG_H_
#define GPERFTOOLS_CONFIG_H_
])

AH_VERBATIM([PTHREADS_CRASHES_IF_RUN_TOO_EARLY],
	    [/* Mark the systems where we know it's bad if pthreads runs too
   early before main (before threads are initialized, presumably).  */
#ifdef __FreeBSD__
#define PTHREADS_CRASHES_IF_RUN_TOO_EARLY 1
#endif])

# MinGW uses autoconf, but also needs the windows shim routines
# (since it doesn't have its own support for, say, pthreads).
# This requires us to #include a special header file, and also to
# link in some windows versions of .o's instead of the unix versions.
#
# Also, manually mark systems where we have to be careful how early
# we run pthreads.  TODO(csilvers): turn this into an autoconf check.
AH_BOTTOM([
#ifdef __MINGW32__
#include "windows/mingw.h"
#endif

#endif  /* #ifndef GPERFTOOLS_CONFIG_H_ */
])
AM_CONDITIONAL(MINGW, expr $host : '.*-mingw' >/dev/null 2>&1)
AM_CONDITIONAL(OSX, expr $host : '.*-apple-darwin.*' >/dev/null 2>&1)

# Redhat 7 (and below?) has sys/ucontext.h, but if you try to #include
# it directly, the compiler gets upset.  So we pretend we don't have
# it.
if cat /etc/redhat-release 2>/dev/null | grep "Red Hat Linux release 7" >/dev/null 2>&1; then
AC_DEFINE(HAVE_SYS_UCONTEXT_H, 0, [<sys/ucontext.h> is broken on redhat 7])
fi

# Export the --enable flags we set above.  We do this at the end so
# other configure rules can enable or disable targets based on what
# they find.
AM_CONDITIONAL(WITH_CPU_PROFILER, test "$enable_cpu_profiler" = yes)
AM_CONDITIONAL(WITH_HEAP_PROFILER, test "$enable_heap_profiler" = yes)
AM_CONDITIONAL(WITH_HEAP_CHECKER, test "$enable_heap_checker" = yes)
AM_CONDITIONAL(WITH_DEBUGALLOC, test "$enable_debugalloc" = yes)
# We make tcmalloc.so if either heap-profiler or heap-checker is asked for.
AM_CONDITIONAL(WITH_HEAP_PROFILER_OR_CHECKER,
               test "$enable_heap_profiler" = yes -o \
                    "$enable_heap_checker" = yes)
# If we don't use any profilers, we don't need stack traces (or pprof)
AM_CONDITIONAL(WITH_STACK_TRACE, test "$enable_cpu_profiler" = yes -o \
                                      "$enable_heap_profiler" = yes -o \
                                      "$enable_heap_checker" = yes)

# Write generated configuration file
AC_CONFIG_FILES([Makefile
                 src/gperftools/tcmalloc.h src/windows/gperftools/tcmalloc.h])
AC_OUTPUT
