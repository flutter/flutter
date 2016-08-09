## Process this file with automake to produce Makefile.in

# Note: for every library we create, we're explicit about what symbols
# we export.  In order to avoid complications with C++ mangling, we always
# use the regexp for of specifying symbols.

# Make sure that when we re-make ./configure, we get the macros we need
ACLOCAL_AMFLAGS = -I m4

# This is so we can #include <gperftools/foo>
AM_CPPFLAGS = -I$(top_srcdir)/src

if !WITH_STACK_TRACE
AM_CPPFLAGS += -DNO_TCMALLOC_SAMPLES
endif !WITH_STACK_TRACE

# This is mostly based on configure options
AM_CXXFLAGS =

# These are good warnings to turn on by default.  We also tell gcc
# that malloc, free, realloc, mmap, etc. are not builtins (these flags
# are supported since gcc 3.1.1).  gcc doesn't think most of them are
# builtins now in any case, but it's best to be explicit in case that
# changes one day.  gcc ignores functions it doesn't understand.
if GCC
AM_CXXFLAGS += -Wall -Wwrite-strings -Woverloaded-virtual \
               -Wno-sign-compare \
               -fno-builtin-malloc -fno-builtin-free -fno-builtin-realloc \
               -fno-builtin-calloc -fno-builtin-cfree \
               -fno-builtin-memalign -fno-builtin-posix_memalign \
               -fno-builtin-valloc -fno-builtin-pvalloc
# On i386, -mmmx is needed for the mmx-based instructions in
# atomicops-internal-x86.h.
if I386
AM_CXXFLAGS += -mmmx
endif I386
endif GCC
if HAVE_W_NO_UNUSED_RESULT
AM_CXXFLAGS += -Wno-unused-result
endif HAVE_W_NO_UNUSED_RESULT

# The -no-undefined flag allows libtool to generate shared libraries for
# Cygwin and MinGW.  LIBSTDCXX_LA_LINKER_FLAG is used to fix a Solaris bug.
AM_LDFLAGS = -no-undefined $(LIBSTDCXX_LA_LINKER_FLAG)

# We know our low-level code cannot trigger an exception.  On some
# systems, such as cygwin, it would be disastrous if they did, because
# the exception handler might call malloc!  If our low-level routines
# raised an exception within the malloc, they'd deadlock.  Luckily,
# we control all this code, and do not need exceptions for it.
if GCC
NO_EXCEPTIONS = -fno-exceptions
else !GCC
NO_EXCEPTIONS =
endif !GCC

# These are x86-specific, having to do with frame-pointers.  In
# particular, some x86_64 systems do not insert frame pointers by
# default (all i386 systems that I know of, do.  I don't know about
# non-x86 chips).  We need to tell perftools what to do about that.
if X86_64_AND_NO_FP_BY_DEFAULT
if ENABLE_FRAME_POINTERS
AM_CXXFLAGS += -fno-omit-frame-pointer
else
  # TODO(csilvers): check if -fomit-frame-pointer might be in $(CXXFLAGS),
  #                 before setting this.
AM_CXXFLAGS += -DNO_FRAME_POINTER
endif !ENABLE_FRAME_POINTERS
endif X86_64_AND_NO_FP_BY_DEFAULT

# For windows systems (at least, mingw), we need to tell all our
# tests to link in libtcmalloc using -u.  This is because libtcmalloc
# accomplishes its tasks via patching, leaving no work for the linker
# to identify, so the linker will ignore libtcmalloc by default unless
# we explicitly create a dependency via -u.
TCMALLOC_FLAGS =
if MINGW
TCMALLOC_FLAGS += -Wl,-u__tcmalloc
endif MINGW

# If we have objcopy, make malloc/free/etc weak symbols.  That way folks
# can override our malloc if they want to (they can still use tc_malloc).
# Note: the weird-looking symbols are the c++ memory functions:
# (in order) new, new(nothrow), new[], new[](nothrow), delete, delete[]
# In theory this will break if mangling changes, but that seems pretty
# unlikely at this point.  Just in case, I throw in versions with an
# extra underscore as well, which may help on OS X.
if HAVE_OBJCOPY_WEAKEN
WEAKEN = $(OBJCOPY) -W malloc -W free -W realloc -W calloc -W cfree \
         -W memalign -W posix_memalign -W valloc -W pvalloc \
         -W malloc_stats -W mallopt -W mallinfo \
         -W _Znwm -W _ZnwmRKSt9nothrow_t -W _Znam -W _ZnamRKSt9nothrow_t \
         -W _ZdlPv -W _ZdaPv \
         -W __Znwm -W __ZnwmRKSt9nothrow_t -W __Znam -W __ZnamRKSt9nothrow_t \
         -W __ZdlPv -W __ZdaPv
else
WEAKEN = :
endif !HAVE_OBJCOPY_WEAKEN

LIBS_TO_WEAKEN =

perftoolsincludedir = $(includedir)/gperftools
# The .h files you want to install (that is, .h files that people
# who install this package can include in their own applications.)
# We'll add to this later, on a library-by-library basis
perftoolsinclude_HEADERS =
# tcmalloc.h is a special case, because it's a .h.in file
nodist_perftoolsinclude_HEADERS = src/gperftools/tcmalloc.h
noinst_HEADERS = src/gperftools/tcmalloc.h.in

# This is provided for backwards compatibility.  It is populated by
# files that just forward to the canonical location in
# perftoolsincludedir.
googleincludedir = $(includedir)/google
googleinclude_HEADERS =				\
   src/google/heap-checker.h			\
   src/google/heap-profiler.h			\
   src/google/malloc_extension.h		\
   src/google/malloc_extension_c.h		\
   src/google/malloc_hook.h			\
   src/google/malloc_hook_c.h			\
   src/google/profiler.h			\
   src/google/stacktrace.h			\
   src/google/tcmalloc.h                        \
   src/windows/google/tcmalloc.h

docdir = $(prefix)/share/doc/$(PACKAGE)-$(VERSION)
# This is for HTML and other documentation you want to install.
# Add your documentation files (in doc/) in addition to these
# top-level boilerplate files.  Also add a TODO file if you have one.
# We'll add to this later, on a library-by-library basis
dist_doc_DATA = AUTHORS COPYING ChangeLog INSTALL NEWS README README_windows.txt \
                TODO

# The libraries (.so's) you want to install
# We'll add to this later, on a library-by-library basis
lib_LTLIBRARIES =
# This is for 'convenience libraries' -- basically just a container for sources
noinst_LTLIBRARIES =
## The location of the windows project file for each binary we make
WINDOWS_PROJECTS = gperftools.sln

# unittests you want to run when people type 'make check'.
# Note: tests cannot take any arguments!
# In theory, unittests that are scripts should be added to check_SCRIPTS
# instead.  But check_SCRIPTS is definitely a second-class testing mechanims:
# it don't get TESTS_ENVIRONMENT, and it doesn't get success/failure counting
# (in fact, a script failure aborts all the rest of the tests, even with -k).
# So, for scripts, we add the script to tests, and also put in an empty
# rule so automake doesn't try to build the script as a C binary.
TESTS =
# TESTS_ENVIRONMENT sets environment variables for when you run unittest.
# We always get "srcdir" set for free.
# We'll add to this later, on a library-by-library basis.
TESTS_ENVIRONMENT =
# All script tests should be added here
noinst_SCRIPTS =
# If your test calls another program that, like the test itself, shouldn't
# be installed, add it here.  (Stuff in TESTS is automatically added later).
noinst_PROGRAMS =

# Binaries we might build that should be installed
bin_PROGRAMS =

# This is my own var, used for extra libraries I make that I need installed
EXTRA_INSTALL =

## vvvv RULES TO MAKE THE LIBRARIES, BINARIES, AND UNITTESTS

dist_doc_DATA += doc/index.html doc/designstyle.css


### ------- library routines, in src/base

# This is a 'convenience library' -- it's not actually installed or anything
LOGGING_INCLUDES = src/base/logging.h \
                   src/base/commandlineflags.h \
                   src/base/basictypes.h \
                   src/base/dynamic_annotations.h \
                   src/third_party/valgrind.h
noinst_LTLIBRARIES += liblogging.la
liblogging_la_SOURCES = src/base/logging.cc \
                        src/base/dynamic_annotations.c \
                        $(LOGGING_INCLUDES)

SYSINFO_INCLUDES = src/base/sysinfo.h \
                   src/base/logging.h \
                   src/base/commandlineflags.h \
                   src/base/cycleclock.h \
                   src/base/arm_instruction_set_select.h \
                   src/base/basictypes.h
noinst_LTLIBRARIES += libsysinfo.la
libsysinfo_la_SOURCES = src/base/sysinfo.cc \
                        $(SYSINFO_INCLUDES)
libsysinfo_la_LIBADD = $(NANOSLEEP_LIBS)

# For MinGW, we use also have to use libwindows Luckily, we need the
# windows.a library in exactly the same place we need spinlock.a
# (pretty much everywhere), so we can use the same variable name for
# each.  We can also optimize the MinGW rule a bit by leaving out
# files we know aren't used on windows, such as
# atomicops-internals-x86.cc.  libwindows also obsoletes the need for
# other files like system_alloc.cc.
if MINGW
WINDOWS_INCLUDES = src/windows/port.h \
                   src/windows/mingw.h \
                   src/windows/mini_disassembler.h \
                   src/windows/mini_disassembler_types.h \
                   src/windows/preamble_patcher.h
noinst_LTLIBRARIES += libwindows.la
libwindows_la_SOURCES = $(WINDOWS_INCLUDES) \
                        src/windows/port.cc \
                        src/windows/ia32_modrm_map.cc \
                        src/windows/ia32_opcode_map.cc \
                        src/windows/mini_disassembler.cc \
                        src/windows/patch_functions.cc \
                        src/windows/preamble_patcher.cc \
                        src/windows/preamble_patcher_with_stub.cc
# patch_functions.cc uses Psapi.lib.  MSVC has a #pragma for that, but not us.
libwindows_la_LIBADD = -lPsapi

SPINLOCK_INCLUDES = src/base/spinlock.h \
                    src/base/spinlock_internal.h \
                    src/base/spinlock_win32-inl.h \
                    src/base/spinlock_linux-inl.h \
                    src/base/spinlock_posix-inl.h \
                    src/base/synchronization_profiling.h \
                    src/base/atomicops-internals-macosx.h \
                    src/base/atomicops-internals-linuxppc.h \
                    src/base/atomicops-internals-arm-generic.h \
                    src/base/atomicops-internals-arm-v6plus.h \
                    src/base/atomicops-internals-windows.h \
                    src/base/atomicops-internals-x86.h
noinst_LTLIBRARIES += libspinlock.la
libspinlock_la_SOURCES = src/base/spinlock.cc \
                         src/base/spinlock_internal.cc \
                         $(SPINLOCK_INCLUDES)

LIBSPINLOCK = libwindows.la libspinlock.la libsysinfo.la liblogging.la

# We also need to tell mingw that sysinfo.cc needs shlwapi.lib.
# (We do this via a #pragma for msvc, but need to do it here for mingw).
libsysinfo_la_LIBADD += -lshlwapi

# There's a windows-specific unittest we can run.  Right now it's
# win64-specific, and relies on masm, so we comment it out.
## TESTS += preamble_patcher_test
## preamble_patcher_test_SOURCES = src/windows/preamble_patcher_test.cc \
##                                 src/windows/shortproc.asm \
##                                 src/windows/auto_testing_hook.h \
##                                 src/windows/preamble_patcher.h \
##                                 src/base/basictypes.h \
##                                 src/base/logging.h
## preamble_patcher_test_LDFLAGS = $(TCMALLOC_FLAGS)
## preamble_patcher_test_LDADD = $(LIBTCMALLOC_MINIMAL)

# patch_functions.cc #includes tcmalloc.cc, so no need to link it in.
TCMALLOC_CC =
# windows has its own system for threads and system memory allocation.
MAYBE_THREADS_CC =
SYSTEM_ALLOC_CC =
else !MINGW
# spinlock is the only code that uses atomicops.
SPINLOCK_INCLUDES = src/base/spinlock.h \
                    src/base/spinlock_internal.h \
                    src/base/atomicops.h \
                    src/base/atomicops-internals-macosx.h \
                    src/base/atomicops-internals-linuxppc.h \
                    src/base/atomicops-internals-windows.h \
                    src/base/atomicops-internals-x86.h

noinst_LTLIBRARIES += libspinlock.la
libspinlock_la_SOURCES = src/base/spinlock.cc \
                         src/base/spinlock_internal.cc \
                         src/base/atomicops-internals-x86.cc \
                         $(SPINLOCK_INCLUDES)
libspinlock_la_LIBADD = $(NANOSLEEP_LIBS)
# spinlock also needs NumCPUs, from libsysinfo, which in turn needs liblogging
LIBSPINLOCK = libspinlock.la libsysinfo.la liblogging.la

TCMALLOC_CC = src/tcmalloc.cc
MAYBE_THREADS_CC = src/maybe_threads.cc
SYSTEM_ALLOC_CC = src/system-alloc.cc
endif !MINGW

# Add this whether or not we're under MinGW, to keep the tarball complete.
WINDOWS_PROJECTS += vsprojects/preamble_patcher_test/preamble_patcher_test.vcproj
# Because we've commented out the test, above, we have to explicitly add
# the test files to the tarball or automake will leave them out.
WINDOWS_PROJECTS += src/windows/preamble_patcher_test.cc \
                    src/windows/shortproc.asm \
                    src/windows/auto_testing_hook.h

### Unittests
TESTS += low_level_alloc_unittest
WINDOWS_PROJECTS += vsprojects/low_level_alloc_unittest/low_level_alloc_unittest.vcproj
LOW_LEVEL_ALLOC_UNITTEST_INCLUDES = src/base/low_level_alloc.h \
                                    src/base/basictypes.h \
                                    src/gperftools/malloc_hook.h \
                                    src/gperftools/malloc_hook_c.h \
                                    src/malloc_hook-inl.h \
                                    src/malloc_hook_mmap_linux.h \
                                    src/malloc_hook_mmap_freebsd.h \
                                    $(SPINLOCK_INCLUDES) \
                                    $(LOGGING_INCLUDES)
low_level_alloc_unittest_SOURCES = src/base/low_level_alloc.cc \
                                   src/malloc_hook.cc \
                                   $(MAYBE_THREADS_CC) \
                                   src/tests/low_level_alloc_unittest.cc \
                                   $(LOW_LEVEL_ALLOC_UNITTEST_INCLUDES)
# By default, MallocHook takes stack traces for use by the heap-checker.
# We don't need that functionality here, so we turn it off to reduce deps.
low_level_alloc_unittest_CXXFLAGS = -DNO_TCMALLOC_SAMPLES
low_level_alloc_unittest_LDADD = $(LIBSPINLOCK)

TESTS += atomicops_unittest
ATOMICOPS_UNITTEST_INCLUDES = src/base/atomicops.h \
                              src/base/atomicops-internals-macosx.h \
                              src/base/atomicops-internals-windows.h \
                              src/base/atomicops-internals-x86.h \
                              $(LOGGING_INCLUDES)
atomicops_unittest_SOURCES = src/tests/atomicops_unittest.cc \
                             $(ATOMICOPS_UNITTEST_INCLUDES)
atomicops_unittest_LDADD = $(LIBSPINLOCK)


### ------- stack trace

if WITH_STACK_TRACE

### The header files we use.  We divide into categories based on directory
S_STACKTRACE_INCLUDES = src/stacktrace_config.h \
                        src/stacktrace_generic-inl.h \
			src/stacktrace_libunwind-inl.h \
			src/stacktrace_arm-inl.h \
			src/stacktrace_powerpc-inl.h \
			src/stacktrace_x86-inl.h \
			src/stacktrace_win32-inl.h \
                        src/base/elf_mem_image.h \
                        src/base/vdso_support.h

SG_STACKTRACE_INCLUDES = src/gperftools/stacktrace.h
STACKTRACE_INCLUDES = $(S_STACKTRACE_INCLUDES) $(SG_STACKTRACE_INCLUDES)
perftoolsinclude_HEADERS += $(SG_STACKTRACE_INCLUDES)

### Making the library
noinst_LTLIBRARIES += libstacktrace.la
libstacktrace_la_SOURCES = src/stacktrace.cc \
                           src/base/elf_mem_image.cc \
                           src/base/vdso_support.cc \
                           $(STACKTRACE_INCLUDES)
libstacktrace_la_LIBADD = $(UNWIND_LIBS) $(LIBSPINLOCK)
STACKTRACE_SYMBOLS = '(GetStackTrace|GetStackFrames|GetStackTraceWithContext|GetStackFramesWithContext)'
libstacktrace_la_LDFLAGS = -export-symbols-regex $(STACKTRACE_SYMBOLS)

### Unittests
TESTS += stacktrace_unittest
STACKTRACE_UNITTEST_INCLUDES = src/config_for_unittests.h \
                               src/base/commandlineflags.h \
                               $(STACKTRACE_INCLUDES) \
                               $(LOGGING_INCLUDES)
stacktrace_unittest_SOURCES = src/tests/stacktrace_unittest.cc \
                              $(STACKTRACE_UNITTEST_INCLUDES)
stacktrace_unittest_LDADD = libstacktrace.la liblogging.la

### Documentation
dist_doc_DATA +=

endif WITH_STACK_TRACE

### ------- pprof

# If we are not compiling with stacktrace support, pprof is worthless
if WITH_STACK_TRACE

bin_SCRIPTS = src/pprof

### Unittests

check_SCRIPTS = pprof_unittest
pprof_unittest: $(top_srcdir)/src/pprof
	$(top_srcdir)/src/pprof -test

# Let unittests find pprof if they need to run it
TESTS_ENVIRONMENT += PPROF_PATH=$(top_srcdir)/src/pprof

### Documentation
dist_man_MANS = doc/pprof.1
dist_doc_DATA += doc/pprof_remote_servers.html

# On MSVC, we need our own versions of addr2line and nm to work with pprof.
WINDOWS_PROJECTS += vsprojects/nm-pdb/nm-pdb.vcproj
WINDOWS_PROJECTS += vsprojects/addr2line-pdb/addr2line-pdb.vcproj
# This is a slight abuse of WINDOWS_PROJECTS, but not much
WINDOWS_PROJECTS += src/windows/nm-pdb.c \
                    src/windows/addr2line-pdb.c

endif WITH_STACK_TRACE

### ------- tcmalloc_minimal (thread-caching malloc)

### The header files we use.  We divide into categories based on directory
S_TCMALLOC_MINIMAL_INCLUDES = src/common.h \
                              src/internal_logging.h \
                              src/system-alloc.h \
                              src/packed-cache-inl.h \
                              $(SPINLOCK_INCLUDES) \
                              src/tcmalloc_guard.h \
                              src/base/commandlineflags.h \
                              src/base/basictypes.h \
                              src/pagemap.h \
                              src/sampler.h \
                              src/central_freelist.h \
                              src/linked_list.h \
                              src/libc_override.h \
                              src/libc_override_gcc_and_weak.h \
                              src/libc_override_glibc.h \
                              src/libc_override_osx.h \
                              src/libc_override_redefine.h \
                              src/page_heap.h \
                              src/page_heap_allocator.h \
                              src/span.h \
                              src/static_vars.h \
                              src/symbolize.h \
                              src/thread_cache.h \
                              src/stack_trace_table.h \
                              src/base/thread_annotations.h \
                              src/malloc_hook-inl.h \
                              src/malloc_hook_mmap_linux.h \
                              src/malloc_hook_mmap_freebsd.h \
                              src/maybe_threads.h
SG_TCMALLOC_MINIMAL_INCLUDES = src/gperftools/malloc_hook.h \
                               src/gperftools/malloc_hook_c.h \
                               src/gperftools/malloc_extension.h \
                               src/gperftools/malloc_extension_c.h \
                               src/gperftools/stacktrace.h
TCMALLOC_MINIMAL_INCLUDES = $(S_TCMALLOC_MINIMAL_INCLUDES) $(SG_TCMALLOC_MINIMAL_INCLUDES)
perftoolsinclude_HEADERS += $(SG_TCMALLOC_MINIMAL_INCLUDES)

### Making the library

# As we describe at the top of this file, we want to turn off exceptions
# for all files in this library -- except tcmalloc.cc which needs them
# to fulfill its API.  Automake doesn't allow per-file CXXFLAGS, so we need
# to separate into two libraries.
noinst_LTLIBRARIES += libtcmalloc_minimal_internal.la
libtcmalloc_minimal_internal_la_SOURCES = src/common.cc \
                                          src/internal_logging.cc \
                                          $(SYSTEM_ALLOC_CC) \
                                          src/memfs_malloc.cc \
                                          src/central_freelist.cc \
                                          src/page_heap.cc \
                                          src/sampler.cc \
                                          src/span.cc \
                                          src/stack_trace_table.cc \
                                          src/static_vars.cc \
                                          src/symbolize.cc \
                                          src/thread_cache.cc \
                                          src/malloc_hook.cc \
                                          src/malloc_extension.cc \
                                          $(MAYBE_THREADS_CC) \
                                          $(TCMALLOC_MINIMAL_INCLUDES)
# We #define NO_TCMALLOC_SAMPLES, since sampling is turned off for _minimal.
libtcmalloc_minimal_internal_la_CXXFLAGS = -DNO_TCMALLOC_SAMPLES \
                                           -DNO_HEAP_CHECK \
                                           $(PTHREAD_CFLAGS) -DNDEBUG \
                                           $(AM_CXXFLAGS) $(NO_EXCEPTIONS)
libtcmalloc_minimal_internal_la_LDFLAGS = $(PTHREAD_CFLAGS)
libtcmalloc_minimal_internal_la_LIBADD = $(PTHREAD_LIBS) $(LIBSPINLOCK)

lib_LTLIBRARIES += libtcmalloc_minimal.la
WINDOWS_PROJECTS += vsprojects/libtcmalloc_minimal/libtcmalloc_minimal.vcproj
libtcmalloc_minimal_la_SOURCES = $(TCMALLOC_CC) $(TCMALLOC_MINIMAL_INCLUDES)
libtcmalloc_minimal_la_CXXFLAGS = -DNO_TCMALLOC_SAMPLES \
                                  $(PTHREAD_CFLAGS) -DNDEBUG $(AM_CXXFLAGS)
# -version-info gets passed to libtool
libtcmalloc_minimal_la_LDFLAGS = $(PTHREAD_CFLAGS) -version-info @TCMALLOC_SO_VERSION@
libtcmalloc_minimal_la_LIBADD = libtcmalloc_minimal_internal.la $(PTHREAD_LIBS)

# For windows, we're playing around with trying to do some stacktrace
# support even with libtcmalloc_minimal.  For everyone else, though,
# we turn off all stack-trace activity for libtcmalloc_minimal.
# TODO(csilvers): when we're done experimenting, do something principled here
if MINGW
LIBTCMALLOC_MINIMAL = libtcmalloc_minimal.la libstacktrace.la
else !MINGW
LIBTCMALLOC_MINIMAL = libtcmalloc_minimal.la
endif !MINGW

LIBS_TO_WEAKEN += libtcmalloc_minimal.la

### Unittests

# Commented out for the moment because malloc(very_big_num) is broken in
# standard libc!  At least, in some situations, some of the time.
## TESTS += malloc_unittest
## MALLOC_UNITEST_INCLUDES = src/gperftools/malloc_extension.h \
##                           src/gperftools/malloc_hook.h \
##                           src/gperftools/malloc_hook_c.h \
##                           src/malloc_hook-inl.h \
##                           src/malloc_hook_mmap_linux.h \
##                           src/malloc_hook_mmap_freebsd.h \
##                           src/base/basictypes.h \
##                           src/maybe_threads.h
## malloc_unittest_SOURCES = src/tests/tcmalloc_unittest.cc \
##                           src/malloc_hook.cc \
##                           src/malloc_extension.cc \
##                           $(MAYBE_THREADS_CC) \
##                           $(MALLOC_UNITTEST_INCLUDES)
## malloc_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
## malloc_unittest_LDFLAGS = $(PTHREAD_CFLAGS)
## malloc_unittest_LDADD = $(PTHREAD_LIBS)

TESTS += tcmalloc_minimal_unittest
WINDOWS_PROJECTS += vsprojects/tcmalloc_minimal_unittest/tcmalloc_minimal_unittest.vcproj
WINDOWS_PROJECTS += vsprojects/tmu-static/tmu-static.vcproj
tcmalloc_minimal_unittest_SOURCES = src/tests/tcmalloc_unittest.cc \
                                    src/tests/testutil.h src/tests/testutil.cc \
                                    $(TCMALLOC_UNITTEST_INCLUDES)
tcmalloc_minimal_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
tcmalloc_minimal_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
# We want libtcmalloc last on the link line, but due to a bug in
# libtool involving convenience libs, they need to come last on the
# link line in order to get dependency ordering right.  This is ok:
# convenience libraries are .a's, so tcmalloc is still the last .so.
# We also put pthreads after tcmalloc, because some pthread
# implementations define their own malloc, and we need to go on the
# first linkline to make sure our malloc 'wins'.
tcmalloc_minimal_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) \
                                  liblogging.la $(PTHREAD_LIBS)

TESTS += tcmalloc_minimal_large_unittest
WINDOWS_PROJECTS += vsprojects/tcmalloc_minimal_large/tcmalloc_minimal_large_unittest.vcproj
tcmalloc_minimal_large_unittest_SOURCES = src/tests/tcmalloc_large_unittest.cc
tcmalloc_minimal_large_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
tcmalloc_minimal_large_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
tcmalloc_minimal_large_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

# This tests it works to LD_PRELOAD libtcmalloc (tests maybe_threads.cc)
# In theory this should work under mingw, but mingw has trouble running
# shell scripts that end in .exe.  And it doesn't seem to build shared
# libraries anyway (so can't be LD_PRELOADed) -- in fact, anybody who
# chooses not to build shared libraries won't be able to run this test.
# TODO(csilvers): figure out how to nix ".exe" or otherwise work under mingw
if !MINGW
if !ENABLE_STATIC
TESTS += maybe_threads_unittest.sh$(EXEEXT)
maybe_threads_unittest_sh_SOURCES = src/tests/maybe_threads_unittest.sh
noinst_SCRIPTS += $(maybe_threads_unittest_sh_SOURCES)
# This script preloads libtcmalloc, and calls two other binaries as well
# TODO(csilvers): replace by 'if ! cmp $^ $@ >/dev/null 2>&; then ...; fi'
maybe_threads_unittest.sh$(EXEEXT): $(top_srcdir)/$(maybe_threads_unittest_sh_SOURCES) \
                           $(LIBTCMALLOC_MINIMAL) \
                           low_level_alloc_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(maybe_threads_unittest_sh_SOURCES) $@
endif !ENABLE_STATIC
endif !MINGW

# These all tests components of tcmalloc_minimal

TESTS += addressmap_unittest
WINDOWS_PROJECTS += vsprojects/addressmap_unittest/addressmap_unittest.vcproj
ADDRESSMAP_UNITTEST_INCLUDES = src/addressmap-inl.h \
                               src/base/commandlineflags.h \
                               $(LOGGING_INCLUDES)
addressmap_unittest_SOURCES = src/tests/addressmap_unittest.cc \
                              $(ADDRESSMAP_UNITTEST_INCLUDES)
if MINGW
addressmap_unittest_SOURCES += src/windows/port.h src/windows/port.cc
endif MINGW
addressmap_unittest_CXXFLAGS = -g $(AM_CXXFLAGS)
addressmap_unittest_LDADD = liblogging.la

if !MINGW
TESTS += system_alloc_unittest
system_alloc_unittest_SOURCES = src/config_for_unittests.h \
                                src/tests/system-alloc_unittest.cc
system_alloc_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
system_alloc_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
system_alloc_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)
endif !MINGW

TESTS += packed_cache_test
WINDOWS_PROJECTS += vsprojects/packed-cache_test/packed-cache_test.vcproj
packed_cache_test_SOURCES = src/tests/packed-cache_test.cc
packed_cache_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
packed_cache_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
packed_cache_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += frag_unittest
WINDOWS_PROJECTS += vsprojects/frag_unittest/frag_unittest.vcproj
frag_unittest_SOURCES = src/tests/frag_unittest.cc src/config_for_unittests.h
frag_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
frag_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
frag_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += markidle_unittest
WINDOWS_PROJECTS += vsprojects/markidle_unittest/markidle_unittest.vcproj
markidle_unittest_SOURCES = src/tests/markidle_unittest.cc \
                            src/config_for_unittests.h \
                            src/tests/testutil.h src/tests/testutil.cc
markidle_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
markidle_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
markidle_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += current_allocated_bytes_test
WINDOWS_PROJECTS += vsprojects/current_allocated_bytes_test/current_allocated_bytes_test.vcproj
current_allocated_bytes_test_SOURCES = src/tests/current_allocated_bytes_test.cc \
                                       src/config_for_unittests.h
current_allocated_bytes_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
current_allocated_bytes_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
current_allocated_bytes_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += malloc_hook_test
WINDOWS_PROJECTS += vsprojects/malloc_hook_test/malloc_hook_test.vcproj
malloc_hook_test_SOURCES = src/tests/malloc_hook_test.cc \
                           src/config_for_unittests.h \
                           src/base/logging.h \
                           src/gperftools/malloc_hook.h \
                           src/tests/testutil.h src/tests/testutil.cc
malloc_hook_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
malloc_hook_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
malloc_hook_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += malloc_extension_test
WINDOWS_PROJECTS += vsprojects/malloc_extension_test/malloc_extension_test.vcproj
malloc_extension_test_SOURCES = src/tests/malloc_extension_test.cc \
                                src/config_for_unittests.h \
                                src/base/logging.h \
                                src/gperftools/malloc_extension.h \
                                src/gperftools/malloc_extension_c.h
malloc_extension_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
malloc_extension_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
malloc_extension_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

# This doesn't work with static linkage, because libtcmalloc.a isn't
# happy with C linkage (it misses the stdc++ library).  Likewise with
# mingw, which links foo.a even though it doesn't set ENABLE_STATIC.
# TODO(csilvers): set enable_static=true in configure.ac:36?
if !MINGW
if !ENABLE_STATIC
TESTS += malloc_extension_c_test
malloc_extension_c_test_SOURCES = src/tests/malloc_extension_c_test.c \
                                  src/gperftools/malloc_extension.h \
                                  src/gperftools/malloc_extension_c.h
malloc_extension_c_test_CFLAGS = $(PTHREAD_CFLAGS) $(AM_CFLAGS)
# -ansi here is just to help ensure the code is bog-standard C.
if GCC
malloc_extension_c_test_CFLAGS += -ansi
endif GCC
malloc_extension_c_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
malloc_extension_c_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)
endif !ENABLE_STATIC
endif !MINGW

if !MINGW
if !OSX
TESTS += memalign_unittest
memalign_unittest_SOURCES = src/tests/memalign_unittest.cc \
                            src/tcmalloc.h \
                            src/config_for_unittests.h \
                            src/tests/testutil.h src/tests/testutil.cc
memalign_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
memalign_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
memalign_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)
endif !OSX
endif !MINGW

TESTS += page_heap_test
WINDOWS_PROJECTS += vsprojects/page_heap_test/page_heap_test.vcproj
page_heap_test_SOURCES = src/tests/page_heap_test.cc \
                         src/config_for_unittests.h \
                         src/base/logging.h \
                         src/common.h \
                         src/page_heap.h
page_heap_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
page_heap_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
page_heap_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += pagemap_unittest
WINDOWS_PROJECTS += vsprojects/pagemap_unittest/pagemap_unittest.vcproj
pagemap_unittest_SOURCES = src/tests/pagemap_unittest.cc \
                           src/config_for_unittests.h \
                           src/base/logging.h \
                           src/pagemap.h
pagemap_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
pagemap_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
pagemap_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += realloc_unittest
WINDOWS_PROJECTS += vsprojects/realloc_unittest/realloc_unittest.vcproj
realloc_unittest_SOURCES = src/tests/realloc_unittest.cc \
                           src/config_for_unittests.h \
                           src/base/logging.h
realloc_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
realloc_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
realloc_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += stack_trace_table_test
WINDOWS_PROJECTS += vsprojects/stack_trace_table_test/stack_trace_table_test.vcproj
stack_trace_table_test_SOURCES = src/tests/stack_trace_table_test.cc \
                                 src/config_for_unittests.h
stack_trace_table_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
stack_trace_table_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
stack_trace_table_test_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

TESTS += thread_dealloc_unittest
WINDOWS_PROJECTS += vsprojects/thread_dealloc_unittest/thread_dealloc_unittest.vcproj
thread_dealloc_unittest_SOURCES = src/tests/thread_dealloc_unittest.cc \
                                  src/config_for_unittests.h \
                                  src/tests/testutil.h src/tests/testutil.cc
thread_dealloc_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
thread_dealloc_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
thread_dealloc_unittest_LDADD = $(LIBTCMALLOC_MINIMAL) $(PTHREAD_LIBS)

### Documentation
dist_doc_DATA += doc/tcmalloc.html \
                 doc/overview.gif \
                 doc/pageheap.gif \
                 doc/spanmap.gif \
                 doc/threadheap.gif \
                 doc/t-test1.times.txt \
                 doc/tcmalloc-opspercpusec.vs.threads.1024.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.128.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.131072.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.16384.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.2048.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.256.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.32768.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.4096.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.512.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.64.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.65536.bytes.png 	\
                 doc/tcmalloc-opspercpusec.vs.threads.8192.bytes.png 	\
                 doc/tcmalloc-opspersec.vs.size.1.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.12.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.16.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.2.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.20.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.3.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.4.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.5.threads.png 		\
                 doc/tcmalloc-opspersec.vs.size.8.threads.png

# I don't know how to say "distribute the .dot files but don't install them";
# noinst doesn't seem to work with data.  I separate them out anyway, in case
# one day we figure it out.  Regardless, installing the dot files isn't the
# end of the world.
dist_doc_DATA += doc/overview.dot \
                 doc/pageheap.dot \
                 doc/spanmap.dot \
                 doc/threadheap.dot


### ------- tcmalloc_minimal_debug (thread-caching malloc with debugallocation)

# Like tcmalloc.cc, debugallocation.cc needs exceptions to fulfill its
# API.  Luckily, we can reuse everything else from tcmalloc_minimal.

if WITH_DEBUGALLOC

lib_LTLIBRARIES += libtcmalloc_minimal_debug.la
libtcmalloc_minimal_debug_la_SOURCES = src/debugallocation.cc \
                                       $(TCMALLOC_MINIMAL_INCLUDES)
libtcmalloc_minimal_debug_la_CXXFLAGS = $(libtcmalloc_minimal_la_CXXFLAGS) \
                                        -DTCMALLOC_FOR_DEBUGALLOCATION
# version_info gets passed to libtool
libtcmalloc_minimal_debug_la_LDFLAGS = $(libtcmalloc_minimal_la_LDFLAGS) \
                                       -version-info @TCMALLOC_SO_VERSION@
libtcmalloc_minimal_debug_la_LIBADD = $(libtcmalloc_minimal_la_LIBADD)

LIBS_TO_WEAKEN += libtcmalloc_minimal_debug.la

### Unittests

TESTS += tcmalloc_minimal_debug_unittest
tcmalloc_minimal_debug_unittest_SOURCES = $(tcmalloc_minimal_unittest_SOURCES)
tcmalloc_minimal_debug_unittest_CXXFLAGS = $(tcmalloc_minimal_unittest_CXXFLAGS) \
                                           -DDEBUGALLOCATION
tcmalloc_minimal_debug_unittest_LDFLAGS = $(tcmalloc_minimal_unittest_LDFLAGS)
tcmalloc_minimal_debug_unittest_LDADD = libtcmalloc_minimal_debug.la $(PTHREAD_LIBS)

TESTS += malloc_extension_debug_test
malloc_extension_debug_test_SOURCES = $(malloc_extension_test_SOURCES)
malloc_extension_debug_test_CXXFLAGS = $(malloc_extension_test_CXXFLAGS)
malloc_extension_debug_test_LDFLAGS = $(malloc_extension_test_LDFLAGS)
malloc_extension_debug_test_LDADD = libtcmalloc_minimal_debug.la $(PTHREAD_LIBS)

if !MINGW
if !OSX
TESTS += memalign_debug_unittest
memalign_debug_unittest_SOURCES = $(memalign_unittest_SOURCES)
memalign_debug_unittest_CXXFLAGS = $(memalign_unittest_CXXFLAGS)
memalign_debug_unittest_LDFLAGS = $(memalign_unittest_LDFLAGS)
memalign_debug_unittest_LDADD = libtcmalloc_minimal_debug.la $(PTHREAD_LIBS)
endif !OSX
endif !MINGW

TESTS += realloc_debug_unittest
realloc_debug_unittest_SOURCES = $(realloc_unittest_SOURCES)
realloc_debug_unittest_CXXFLAGS = $(realloc_unittest_CXXFLAGS)
realloc_debug_unittest_LDFLAGS = $(realloc_unittest_LDFLAGS)
realloc_debug_unittest_LDADD = libtcmalloc_minimal_debug.la $(PTHREAD_LIBS)

# debugallocation_test checks that we print a proper stacktrace when
# debug-allocs fail, so we can't run it if we don't have stacktrace info.
if WITH_STACK_TRACE
TESTS += debugallocation_test.sh$(EXEEXT)
debugallocation_test_sh_SOURCES = src/tests/debugallocation_test.sh
noinst_SCRIPTS += $(debugallocation_test_sh_SOURCES)
debugallocation_test.sh$(EXEEXT): $(top_srcdir)/$(debugallocation_test_sh_SOURCES) \
                                  debugallocation_test
	rm -f $@
	cp -p $(top_srcdir)/$(debugallocation_test_sh_SOURCES) $@

# This is the sub-program used by debugallocation_test.sh
noinst_PROGRAMS += debugallocation_test
debugallocation_test_SOURCES = src/tests/debugallocation_test.cc
debugallocation_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
debugallocation_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
debugallocation_test_LDADD = libtcmalloc_debug.la $(PTHREAD_LIBS)
endif WITH_STACK_TRACE

endif WITH_DEBUGALLOC


### ------- tcmalloc (thread-caching malloc + heap profiler + heap checker)

if WITH_HEAP_PROFILER_OR_CHECKER

### The header files we use.  We divide into categories based on directory
S_TCMALLOC_INCLUDES = $(S_TCMALLOC_MINIMAL_INCLUDES) \
                      $(LOGGING_INCLUDES) \
                      src/addressmap-inl.h \
                      src/raw_printer.h \
                      src/base/elfcore.h \
                      src/base/googleinit.h \
                      src/base/linux_syscall_support.h \
                      src/base/linuxthreads.h \
                      src/base/stl_allocator.h \
                      src/base/sysinfo.h \
                      src/base/thread_lister.h \
                      src/heap-profile-table.h
SG_TCMALLOC_INCLUDES = $(SG_TCMALLOC_MINIMAL_INCLUDES) \
                       src/gperftools/heap-profiler.h \
                       src/gperftools/heap-checker.h
TCMALLOC_INCLUDES = $(S_TCMALLOC_INCLUDES) $(SG_TCMALLOC_INCLUDES)
perftoolsinclude_HEADERS += $(SG_TCMALLOC_INCLUDES)

### Making the library

# As we describe at the top of this file, we want to turn off exceptions
# for all files in this library -- except tcmalloc.cc which needs them
# to fulfill its API.  Automake doesn't allow per-file CXXFLAGS, so we need
# to separate into two libraries.
noinst_LTLIBRARIES += libtcmalloc_internal.la
libtcmalloc_internal_la_SOURCES = $(libtcmalloc_minimal_internal_la_SOURCES) \
                                  $(TCMALLOC_INCLUDES) \
                                  src/base/low_level_alloc.cc \
                                  src/heap-profile-table.cc \
                                  src/heap-profiler.cc \
                                  src/raw_printer.cc \
                                  src/memory_region_map.cc
libtcmalloc_internal_la_CXXFLAGS = $(PTHREAD_CFLAGS) -DNDEBUG \
                                   $(AM_CXXFLAGS) $(NO_EXCEPTIONS)
libtcmalloc_internal_la_LDFLAGS = $(PTHREAD_CFLAGS)
libtcmalloc_internal_la_LIBADD = libstacktrace.la $(PTHREAD_LIBS)

lib_LTLIBRARIES += libtcmalloc.la
libtcmalloc_la_SOURCES = $(TCMALLOC_CC) $(TCMALLOC_INCLUDES)
libtcmalloc_la_CXXFLAGS = $(PTHREAD_CFLAGS) -DNDEBUG $(AM_CXXFLAGS)
libtcmalloc_la_LDFLAGS = $(PTHREAD_CFLAGS) -version-info @TCMALLOC_SO_VERSION@
libtcmalloc_la_LIBADD = libtcmalloc_internal.la $(PTHREAD_LIBS)

if WITH_HEAP_CHECKER
# heap-checker-bcad is last, in hopes its global ctor will run first.
# (Note this is added to libtcmalloc.la, not libtcmalloc_internal.la,
# but that's ok; the internal/external distinction is only useful for
# cygwin, and cygwin doesn't use HEAP_CHECKER anyway.)
HEAP_CHECKER_SOURCES = src/base/thread_lister.c \
                       src/base/linuxthreads.cc \
                       src/heap-checker.cc \
                       src/heap-checker-bcad.cc
libtcmalloc_la_SOURCES += $(HEAP_CHECKER_SOURCES)
else !WITH_HEAP_CHECKER
HEAP_CHECKER_SOURCES =
libtcmalloc_internal_la_CXXFLAGS += -DNO_HEAP_CHECK
libtcmalloc_la_CXXFLAGS += -DNO_HEAP_CHECK
endif !WITH_HEAP_CHECKER

LIBTCMALLOC = libtcmalloc.la

LIBS_TO_WEAKEN += libtcmalloc.la

### Unittests

TESTS += tcmalloc_unittest
TCMALLOC_UNITTEST_INCLUDES = src/config_for_unittests.h \
                             src/gperftools/malloc_extension.h
tcmalloc_unittest_SOURCES = src/tests/tcmalloc_unittest.cc \
                            src/tcmalloc.h \
                            src/tests/testutil.h src/tests/testutil.cc \
                            $(TCMALLOC_UNITTEST_INCLUDES)
tcmalloc_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
tcmalloc_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
# We want libtcmalloc last on the link line, but due to a bug in
# libtool involving convenience libs, they need to come last on the
# link line in order to get dependency ordering right.  This is ok:
# convenience libraries are .a's, so tcmalloc is still the last .so.
# We also put pthreads after tcmalloc, because some pthread
# implementations define their own malloc, and we need to go on the
# first linkline to make sure our malloc 'wins'.
tcmalloc_unittest_LDADD = $(LIBTCMALLOC) liblogging.la $(PTHREAD_LIBS)

# This makes sure it's safe to link in both tcmalloc and
# tcmalloc_minimal.  (One would never do this on purpose, but perhaps
# by accident...)  When we can compile libprofiler, we also link it in
# to make sure that works too.  NOTE: On OS X, it's *not* safe to
# link both in (we end up with two copies of every global var, and
# the code tends to pick one arbitrarily), so don't run the test there.
# (We define these outside the 'if' because they're reused below.)
tcmalloc_both_unittest_srcs = src/tests/tcmalloc_unittest.cc \
                              src/tests/testutil.h src/tests/testutil.cc \
                              $(TCMALLOC_UNITTEST_INCLUDES)
tcmalloc_both_unittest_cflags = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
tcmalloc_both_unittest_lflags = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
if WITH_CPU_PROFILER
# We want libtcmalloc last on the link line, but due to a bug in
# libtool involving convenience libs, they need to come last on the
# link line in order to get dependency ordering right.  This is ok:
# convenience libraries are .a's, so tcmalloc is still the last .so.
# We also put pthreads after tcmalloc, because some pthread
# implementations define their own malloc, and we need to go on the
# first linkline to make sure our malloc 'wins'.
tcmalloc_both_unittest_ladd = $(LIBTCMALLOC) $(LIBTCMALLOC_MINIMAL) \
                              libprofiler.la liblogging.la $(PTHREAD_LIBS)
else
tcmalloc_both_unittest_ladd = $(LIBTCMALLOC) $(LIBTCMALLOC_MINIMAL) \
                              liblogging.la $(PTHREAD_LIBS)
endif !WITH_CPU_PROFILER
if !OSX
TESTS += tcmalloc_both_unittest
tcmalloc_both_unittest_SOURCES = $(tcmalloc_both_unittest_srcs)
tcmalloc_both_unittest_CXXFLAGS = $(tcmalloc_both_unittest_cflags)
tcmalloc_both_unittest_LDFLAGS = $(tcmalloc_both_unittest_lflags)
tcmalloc_both_unittest_LDADD = $(tcmalloc_both_unittest_ladd)
endif !OSX

TESTS += tcmalloc_large_unittest
tcmalloc_large_unittest_SOURCES = src/tests/tcmalloc_large_unittest.cc
tcmalloc_large_unittest_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
tcmalloc_large_unittest_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
tcmalloc_large_unittest_LDADD = $(LIBTCMALLOC) $(PTHREAD_LIBS)

TESTS += raw_printer_test
raw_printer_test_SOURCES = src/tests/raw_printer_test.cc
raw_printer_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
raw_printer_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
raw_printer_test_LDADD = $(LIBTCMALLOC) $(PTHREAD_LIBS)

# sampler_test and sampling_test both require sampling to be turned
# on, which it's not by default.  Use the "standard" value of 2^19.
TESTS_ENVIRONMENT += TCMALLOC_SAMPLE_PARAMETER=524288

TESTS += sampler_test
WINDOWS_PROJECTS += vsprojects/sampler_test/sampler_test.vcproj
sampler_test_SOURCES = src/tests/sampler_test.cc \
                       src/config_for_unittests.h
sampler_test_CXXFLAGS = $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
sampler_test_LDFLAGS = $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
sampler_test_LDADD = $(LIBTCMALLOC) $(PTHREAD_LIBS) -lm


# These unittests often need to run binaries.  They're in the current dir
TESTS_ENVIRONMENT += BINDIR=.
TESTS_ENVIRONMENT += TMPDIR=/tmp/perftools

TESTS += sampling_test.sh$(EXEEXT)
sampling_test_sh_SOURCES = src/tests/sampling_test.sh
noinst_SCRIPTS += $(sampling_test_sh_SOURCES)
sampling_test.sh$(EXEEXT): $(top_srcdir)/$(sampling_test_sh_SOURCES) \
                           sampling_test
	rm -f $@
	cp -p $(top_srcdir)/$(sampling_test_sh_SOURCES) $@

# This is the sub-program used by sampling_test.sh
# The -g is so pprof can get symbol information.
noinst_PROGRAMS += sampling_test
SAMPLING_TEST_INCLUDES = src/config_for_unittests.h \
                         src/base/logging.h \
                         src/gperftools/malloc_extension.h
sampling_test_SOURCES = src/tests/sampling_test.cc \
                        $(SAMPLING_TEST_INCLUDES)
sampling_test_CXXFLAGS = -g $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
sampling_test_LDFLAGS = -g $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
sampling_test_LDADD = $(LIBTCMALLOC) $(PTHREAD_LIBS)

endif WITH_HEAP_PROFILER_OR_CHECKER

if WITH_HEAP_PROFILER

TESTS += heap-profiler_unittest.sh$(EXEEXT)
heap_profiler_unittest_sh_SOURCES = src/tests/heap-profiler_unittest.sh
noinst_SCRIPTS += $(heap_profiler_unittest_sh_SOURCES)
heap-profiler_unittest.sh$(EXEEXT): $(top_srcdir)/$(heap_profiler_unittest_sh_SOURCES) \
                                    heap-profiler_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(heap_profiler_unittest_sh_SOURCES) $@

# These are sub-programs used by heap-profiler_unittest.sh
noinst_PROGRAMS += heap-profiler_unittest
HEAP_PROFILER_UNITTEST_INCLUDES = src/config_for_unittests.h \
                                  src/gperftools/heap-profiler.h
heap_profiler_unittest_SOURCES = src/tests/heap-profiler_unittest.cc \
                                 $(HEAP_PROFILER_UNITTEST_INCLUDES)
heap_profiler_unittest_CXXFLAGS = -g $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
heap_profiler_unittest_LDFLAGS = -g $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
heap_profiler_unittest_LDADD = $(LIBTCMALLOC) $(PTHREAD_LIBS)

# Tests the compatibility include-headers in google/.  Requires a function
# defined in the heap-profiler, which is why the test lives here.
TESTS += simple_compat_test
simple_compat_test_SOURCES = src/tests/simple_compat_test.cc \
                             $(googleinclude_HEADERS)
simple_compat_test_LDFLAGS = $(TCMALLOC_FLAGS)
simple_compat_test_LDADD = $(LIBTCMALLOC)

endif WITH_HEAP_PROFILER

if WITH_HEAP_CHECKER

TESTS += heap-checker_unittest.sh$(EXEEXT)
heap_checker_unittest_sh_SOURCES = src/tests/heap-checker_unittest.sh
noinst_SCRIPTS += $(heap_checker_unittest_sh_SOURCES)
heap-checker_unittest.sh$(EXEEXT): $(top_srcdir)/$(heap_checker_unittest_sh_SOURCES) \
                                   heap-checker_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(heap_checker_unittest_sh_SOURCES) $@

TESTS += heap-checker-death_unittest.sh$(EXEEXT)
heap_checker_death_unittest_sh_SOURCES = src/tests/heap-checker-death_unittest.sh
noinst_SCRIPTS += $(top_srcdir)/$(heap_checker_death_unittest_sh_SOURCES)
heap-checker-death_unittest.sh$(EXEEXT): $(heap_checker_death_unittest_sh_SOURCES) \
                                         heap-checker_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(heap_checker_death_unittest_sh_SOURCES) $@

# These are sub-programs used by heap-checker_unittest.sh
noinst_PROGRAMS += heap-checker_unittest
HEAP_CHECKER_UNITTEST_INCLUDES = src/config_for_unittests.h \
                                 src/memory_region_map.h \
                                 src/base/commandlineflags.h \
                                 src/base/googleinit.h \
                                 src/gperftools/heap-checker.h \
                                 $(LOGGING_INCLUDES)
heap_checker_unittest_SOURCES = src/tests/heap-checker_unittest.cc \
                                $(HEAP_CHECKER_UNITTEST_INCLUDES)
heap_checker_unittest_CXXFLAGS = -g $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
heap_checker_unittest_LDFLAGS = -g $(PTHREAD_CFLAGS) $(TCMALLOC_FLAGS)
# We want libtcmalloc last on the link line, but due to a bug in
# libtool involving convenience libs, they need to come last on the
# link line in order to get dependency ordering right.  This is ok:
# convenience libraries are .a's, so tcmalloc is still the last .so.
# We also put pthreads after tcmalloc, because some pthread
# implementations define their own malloc, and we need to go on the
# first linkline to make sure our malloc 'wins'.
heap_checker_unittest_LDADD = $(LIBTCMALLOC) liblogging.la $(PTHREAD_LIBS)

endif WITH_HEAP_CHECKER

### Documentation (above and beyond tcmalloc_minimal documentation)
if WITH_HEAP_PROFILER
dist_doc_DATA += doc/heapprofile.html doc/heap-example1.png
endif WITH_HEAP_PROFILER

if WITH_HEAP_CHECKER
dist_doc_DATA += doc/heap_checker.html
endif WITH_HEAP_CHECKER


### ------- tcmalloc with debugallocation

if WITH_DEBUGALLOC
if WITH_HEAP_PROFILER_OR_CHECKER

lib_LTLIBRARIES += libtcmalloc_debug.la
libtcmalloc_debug_la_SOURCES = src/debugallocation.cc $(HEAP_CHECKER_SOURCES) \
                               $(TCMALLOC_INCLUDES)
libtcmalloc_debug_la_CXXFLAGS = $(libtcmalloc_la_CXXFLAGS) \
                                -DTCMALLOC_FOR_DEBUGALLOCATION
libtcmalloc_debug_la_LDFLAGS = $(libtcmalloc_la_LDFLAGS) \
                               -version-info @TCMALLOC_SO_VERSION@
libtcmalloc_debug_la_LIBADD = $(libtcmalloc_la_LIBADD)

LIBS_TO_WEAKEN += libtcmalloc_debug.la

### Unittests

TESTS += tcmalloc_debug_unittest
tcmalloc_debug_unittest_SOURCES = $(tcmalloc_unittest_SOURCES)
tcmalloc_debug_unittest_CXXFLAGS = $(tcmalloc_unittest_CXXFLAGS) \
                                   -DDEBUGALLOCATION
tcmalloc_debug_unittest_LDFLAGS = $(tcmalloc_unittest_LDFLAGS)
tcmalloc_debug_unittest_LDADD = libtcmalloc_debug.la $(PTHREAD_LIBS)

TESTS += sampler_debug_test
sampler_debug_test_SOURCES = $(sampler_test_SOURCES)
sampler_debug_test_CXXFLAGS = $(samples_test_CXXFLAGS)
sampler_debug_test_LDFLAGS = $(sampler_test_LDFLAGS)
sampler_debug_test_LDADD = libtcmalloc_debug.la $(PTHREAD_LIBS) -lm

TESTS += sampling_debug_test.sh$(EXEEXT)
sampling_debug_test_sh_SOURCES = src/tests/sampling_test.sh
sampling_debug_test.sh$(EXEEXT): $(top_srcdir)/$(sampling_test_sh_SOURCES) \
                                 sampling_debug_test
	rm -f $@
	cp -p $(top_srcdir)/$(sampling_test_sh_SOURCES) $@

# This is the sub-program using by sampling_debug_test.sh
# The -g is so pprof can get symbol information.
noinst_PROGRAMS += sampling_debug_test
sampling_debug_test_SOURCES = $(sampling_test_SOURCES)
sampling_debug_test_CXXFLAGS = $(sampling_test_CXXFLAGS)
sampling_debug_test_LDFLAGS = $(sampling_test_LDFLAGS)
sampling_debug_test_LDADD = libtcmalloc_debug.la $(PTHREAD_LIBS)

endif WITH_HEAP_PROFILER_OR_CHECKER

if WITH_HEAP_PROFILER

TESTS += heap-profiler_debug_unittest.sh$(EXEEXT)
heap_profiler_debug_unittest_sh_SOURCES = src/tests/heap-profiler_unittest.sh
heap-profiler_debug_unittest.sh$(EXEEXT): $(top_srcdir)/$(heap_profiler_unittest_sh_SOURCES) \
                                    heap-profiler_debug_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(heap_profiler_unittest_sh_SOURCES) $@

# These are sub-programs used by heap-profiler_debug_unittest.sh
noinst_PROGRAMS += heap-profiler_debug_unittest
heap_profiler_debug_unittest_SOURCES = $(heap_profiler_unittest_SOURCES)
heap_profiler_debug_unittest_CXXFLAGS = $(heap_profiler_unittest_CXXFLAGS)
heap_profiler_debug_unittest_LDFLAGS = $(heap_profiler_unittest_LDFLAGS)
heap_profiler_debug_unittest_LDADD = libtcmalloc_debug.la $(PTHREAD_LIBS)

endif WITH_HEAP_PROFILER

if WITH_HEAP_CHECKER

TESTS += heap-checker_debug_unittest.sh$(EXEEXT)
heap_checker_debug_unittest_sh_SOURCES = src/tests/heap-checker_unittest.sh
heap-checker_debug_unittest.sh$(EXEEXT): $(top_srcdir)/$(heap_checker_unittest_sh_SOURCES) \
                                   heap-checker_debug_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(heap_checker_unittest_sh_SOURCES) $@

# These are sub-programs used by heap-checker_debug_unittest.sh
noinst_PROGRAMS += heap-checker_debug_unittest
heap_checker_debug_unittest_SOURCES = $(heap_checker_unittest_SOURCES)
heap_checker_debug_unittest_CXXFLAGS = $(heap_checker_unittest_CXXFLAGS)
heap_checker_debug_unittest_LDFLAGS = $(heap_checker_unittest_LDFLAGS)
# We want libtcmalloc last on the link line, but due to a bug in
# libtool involving convenience libs, they need to come last on the
# link line in order to get dependency ordering right.  This is ok:
# convenience libraries are .a's, so tcmalloc is still the last .so.
heap_checker_debug_unittest_LDADD = libtcmalloc_debug.la liblogging.la \
                                    $(PTHREAD_LIBS)

endif WITH_HEAP_CHECKER
endif WITH_DEBUGALLOC


### ------- CPU profiler

if WITH_CPU_PROFILER

### The header files we use.  We divide into categories based on directory
S_CPU_PROFILER_INCLUDES = src/profiledata.h \
                          src/profile-handler.h \
                          src/getpc.h \
                          src/base/basictypes.h \
                          src/base/commandlineflags.h \
                          src/base/googleinit.h \
                          src/base/logging.h \
                          src/base/simple_mutex.h \
                          src/base/sysinfo.h \
                          $(SPINLOCK_INCLUDES) \
                          $(LOGGING_INCLUDES)
SG_CPU_PROFILER_INCLUDES = src/gperftools/profiler.h \
                           src/gperftools/stacktrace.h
CPU_PROFILER_INCLUDES = $(S_CPU_PROFILER_INCLUDES) $(SG_CPU_PROFILER_INCLUDES)
perftoolsinclude_HEADERS += $(SG_CPU_PROFILER_INCLUDES)

### Making the library
lib_LTLIBRARIES += libprofiler.la
libprofiler_la_SOURCES = src/profiler.cc \
                         src/profile-handler.cc \
                         src/profiledata.cc \
                         $(CPU_PROFILER_INCLUDES)
libprofiler_la_LIBADD = libstacktrace.la
# We have to include ProfileData for profiledata_unittest
CPU_PROFILER_SYMBOLS = '(ProfilerStart|ProfilerStartWithOptions|ProfilerStop|ProfilerFlush|ProfilerEnable|ProfilerDisable|ProfilingIsEnabledForAllThreads|ProfilerRegisterThread|ProfilerGetCurrentState|ProfilerState|ProfileData|ProfileHandler)'
libprofiler_la_LDFLAGS = -export-symbols-regex $(CPU_PROFILER_SYMBOLS) \
                         -version-info @PROFILER_SO_VERSION@

# See discussion above (under LIBTCMALLOC_MINIMAL) for why we do this.
# Basically it's to work around systems where --rpath doesn't work right.
LIBPROFILER = libstacktrace.la libprofiler.la

### Unittests
TESTS += getpc_test
#WINDOWS_PROJECTS += vsprojects/getpc_test/getpc_test.vcproj
getpc_test_SOURCES = src/tests/getpc_test.cc src/getpc.h

TESTS += profiledata_unittest
#WINDOWS_PROJECTS += vsprojects/profiledata_unittest/profiledata_unittest.vcproj
profiledata_unittest_SOURCES = src/tests/profiledata_unittest.cc \
                               src/profiledata.h \
                               src/base/commandlineflags.h \
                               src/base/logging.h \
                               src/base/basictypes.h
profiledata_unittest_LDADD = $(LIBPROFILER)

TESTS += profile_handler_unittest
profile_handler_unittest_SOURCES = src/tests/profile-handler_unittest.cc \
                                   src/profile-handler.h
profile_handler_unittest_CXXFLAGS = $(PTHREAD_CFLAGS)
profile_handler_unittest_LDFLAGS = $(PTHREAD_CFLAGS)
profile_handler_unittest_LDADD = $(LIBPROFILER) $(PTHREAD_LIBS)

TESTS += profiler_unittest.sh$(EXEEXT)
profiler_unittest_sh_SOURCES = src/tests/profiler_unittest.sh
noinst_SCRIPTS += $(profiler_unittest_sh_SOURCES)
profiler_unittest.sh$(EXEEXT): $(top_srcdir)/$(profiler_unittest_sh_SOURCES) \
                               profiler1_unittest profiler2_unittest \
                               profiler3_unittest profiler4_unittest
	rm -f $@
	cp -p $(top_srcdir)/$(profiler_unittest_sh_SOURCES) $@

# These are sub-programs used by profiler_unittest.sh
noinst_PROGRAMS += profiler1_unittest profiler2_unittest profiler3_unittest \
                   profiler4_unittest
PROFILER_UNITTEST_INCLUDES = src/config_for_unittests.h \
                             src/gperftools/profiler.h
PROFILER_UNITTEST_SRCS = src/tests/profiler_unittest.cc \
                         src/tests/testutil.h src/tests/testutil.cc \
                         $(PROFILER_UNITTEST_INCLUDES)
profiler1_unittest_SOURCES = $(PROFILER_UNITTEST_SRCS)
profiler1_unittest_CXXFLAGS = -g -DNO_THREADS $(AM_CXXFLAGS)
profiler1_unittest_LDADD = $(LIBPROFILER)
profiler2_unittest_SOURCES = $(PROFILER_UNITTEST_SRCS)
profiler2_unittest_CXXFLAGS = -g -DNO_THREADS $(AM_CXXFLAGS)
profiler2_unittest_LDADD = -lstacktrace -lprofiler
# We depend on -lprofiler but haven't yet said how to build it.  Do so now.
profiler2_unittest_DEPENDENCIES = $(LIBPROFILER)
profiler3_unittest_SOURCES = $(PROFILER_UNITTEST_SRCS)
profiler3_unittest_CXXFLAGS = -g $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
profiler3_unittest_LDFLAGS = $(PTHREAD_CFLAGS)
profiler3_unittest_LDADD = $(LIBPROFILER) $(PTHREAD_LIBS)
profiler4_unittest_SOURCES = $(PROFILER_UNITTEST_SRCS)
profiler4_unittest_CXXFLAGS = -g $(PTHREAD_CFLAGS) $(AM_CXXFLAGS)
profiler4_unittest_LDFLAGS = $(PTHREAD_CFLAGS)
profiler4_unittest_LDADD = -lstacktrace -lprofiler $(PTHREAD_LIBS)
# We depend on -lprofiler but haven't yet said how to build it.  Do so now.
profiler4_unittest_DEPENDENCIES = $(LIBPROFILER)


### Documentation
dist_doc_DATA += doc/cpuprofile.html \
                 doc/cpuprofile-fileformat.html \
                 doc/pprof-test-big.gif \
                 doc/pprof-test.gif \
                 doc/pprof-vsnprintf-big.gif \
                 doc/pprof-vsnprintf.gif

endif WITH_CPU_PROFILER


### ------- CPU profiler and heap checker, in one!

# Ideally, folks who wanted to use both tcmalloc and libprofiler,
# could just link them both into their application.  But while this
# works fine for .so files, it does not for .a files.  The easiest way
# around this -- and I've tried a bunch of the hard ways -- is to just
# to create another set of libraries that has both functionality in it.

if WITH_HEAP_PROFILER_OR_CHECKER
if WITH_CPU_PROFILER

lib_LTLIBRARIES += libtcmalloc_and_profiler.la
libtcmalloc_and_profiler_la_SOURCES = $(libtcmalloc_la_SOURCES) $(libprofiler_la_SOURCES)
libtcmalloc_and_profiler_la_CXXFLAGS = $(libtcmalloc_la_CXXFLAGS) $(libprofiler_la_CXXFLAGS)
# Since this library is meant to be used as a .a, I don't worry as much
# about .so versioning.  I just give the libtcmalloc version number.
# TODO(csilvers): use -export-symbols-regex?
libtcmalloc_and_profiler_la_LDFLAGS = $(PTHREAD_CFLAGS) \
                                      -version-info @TCMALLOC_SO_VERSION@
# We don't include libprofiler_la_LIBADD here because all it adds is
# libstacktrace.la, which we already get via libtcmalloc.  Trying to
# specify it twice causes link-time duplicate-definition errors. :-(
libtcmalloc_and_profiler_la_LIBADD = $(libtcmalloc_la_LIBADD)

TESTS += tcmalloc_and_profiler_unittest
tcmalloc_and_profiler_unittest_SOURCES = $(tcmalloc_both_unittest_srcs)
tcmalloc_and_profiler_unittest_CXXFLAGS = $(tcmalloc_both_unittest_cflags)
tcmalloc_and_profiler_unittest_LDFLAGS = $(tcmalloc_both_unittest_lflags)
tcmalloc_and_profiler_unittest_LDADD = libtcmalloc_and_profiler.la

LIBS_TO_WEAKEN += libtcmalloc_and_profiler.la

endif WITH_CPU_PROFILER
endif WITH_HEAP_PROFILER_OR_CHECKER

## ^^^^ END OF RULES TO MAKE YOUR LIBRARIES, BINARIES, AND UNITTESTS


# Do the weakening on some exported libtcmalloc symbols.
install-exec-local: all-local
all-local: $(LIBS_TO_WEAKEN)
	for la in $(LIBS_TO_WEAKEN); do lib=".libs/`basename $$la .la`.a"; [ ! -f "$$lib" ] || $(WEAKEN) "$$lib"; done


# This should always include $(TESTS), but may also include other
# binaries that you compile but don't want automatically installed.
# We'll add to this later, on a library-by-library basis
noinst_PROGRAMS += $(TESTS)

rpm: dist-gzip packages/rpm.sh packages/rpm/rpm.spec
	@cd packages && ./rpm.sh ${PACKAGE} ${VERSION}

deb: dist-gzip packages/deb.sh packages/deb/*
	@cd packages && ./deb.sh ${PACKAGE} ${VERSION}

# http://linux.die.net/man/1/pkg-config, http://pkg-config.freedesktop.org/wiki
pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libtcmalloc.pc libtcmalloc_minimal.pc \
                 libtcmalloc_debug.pc libtcmalloc_minimal_debug.pc \
                 libprofiler.pc
CLEANFILES = $(pkgconfig_DATA)

# I get the description and URL lines from the rpm spec. I use sed to
# try to rewrite exec_prefix, libdir, and includedir in terms of
# prefix, if possible.
libtcmalloc.pc: Makefile packages/rpm/rpm.spec
	echo 'prefix=$(prefix)' > "$@".tmp
	echo 'exec_prefix='`echo '$(exec_prefix)' | sed 's@^$(prefix)@$${prefix}@'` >> "$@".tmp
	echo 'libdir='`echo '$(libdir)' | sed 's@^$(exec_prefix)@$${exec_prefix}@'` >> "$@".tmp
	echo 'includedir='`echo '$(includedir)' | sed 's@^$(prefix)@$${prefix}@'` >> "$@".tmp
	echo '' >> "$@".tmp
	echo 'Name: $(PACKAGE)' >> "$@".tmp
	echo 'Version: $(VERSION)' >> "$@".tmp
	-grep '^Summary:' $(top_srcdir)/packages/rpm/rpm.spec | sed s/^Summary:/Description:/ | head -n1 >> "$@".tmp
	-grep '^URL: ' $(top_srcdir)/packages/rpm/rpm.spec >> "$@".tmp
	echo 'Requires:' >> "$@".tmp
	echo 'Libs: -L$${libdir} -ltcmalloc' >> "$@".tmp
	echo 'Libs.private: $(PTHREAD_CFLAGS) $(PTHREAD_LIBS)' >> "$@".tmp
	echo 'Cflags: -I$${includedir}' >> "$@".tmp
	mv -f "$@".tmp "$@"

# The other versions are mostly the same.
libtcmalloc_minimal.pc: libtcmalloc.pc
	cat libtcmalloc.pc | sed s/-ltcmalloc/-ltcmalloc_minimal/ > "$@"

libtcmalloc_debug.pc: libtcmalloc.pc
	cat libtcmalloc.pc | sed s/-ltcmalloc/-ltcmalloc_debug/ > "$@"

libtcmalloc_minimal_debug.pc: libtcmalloc.pc
	cat libtcmalloc.pc | sed s/-ltcmalloc/-ltcmalloc_minimal_debug/ > "$@"

libprofiler.pc: libtcmalloc.pc
	cat libtcmalloc.pc | sed s/-ltcmalloc/-lprofiler/ > "$@"

libtool: $(LIBTOOL_DEPS)
	$(SHELL) ./config.status --recheck

# Windows wants write permission to .vcproj files and maybe even sln files.
dist-hook:
	test -e "$(distdir)/vsprojects" \
	   && chmod -R u+w $(distdir)/*.sln $(distdir)/vsprojects/

EXTRA_DIST = packages/rpm.sh packages/rpm/rpm.spec packages/deb.sh packages/deb \
             $(SCRIPTS) libtool \
             src/windows/get_mangled_names.cc src/windows/override_functions.cc \
             src/windows/config.h src/windows/gperftools/tcmalloc.h \
             $(WINDOWS_PROJECTS) \
             src/solaris/libstdc++.la
