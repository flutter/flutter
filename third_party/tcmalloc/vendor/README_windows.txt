--- COMPILING

This project has begun being ported to Windows.  A working solution
file exists in this directory:
    gperftools.sln

You can load this solution file into VC++ 7.1 (Visual Studio 2003) or
later -- in the latter case, it will automatically convert the files
to the latest format for you.

When you build the solution, it will create a number of unittests,
which you can run by hand (or, more easily, under the Visual Studio
debugger) to make sure everything is working properly on your system.
The binaries will end up in a directory called "debug" or "release" in
the top-level directory (next to the .sln file).  It will also create
two binaries, nm-pdb and addr2line-pdb, which you should install in
the same directory you install the 'pprof' perl script.

I don't know very much about how to install DLLs on Windows, so you'll
have to figure out that part for yourself.  If you choose to just
re-use the existing .sln, make sure you set the IncludeDir's
appropriately!  Look at the properties for libtcmalloc_minimal.dll.

Note that these systems are set to build in Debug mode by default.
You may want to change them to Release mode.

To use tcmalloc_minimal in your own projects, you should only need to
build the dll and install it someplace, so you can link it into
further binaries.  To use the dll, you need to add the following to
the linker line of your executable:
   "libtcmalloc_minimal.lib" /INCLUDE:"__tcmalloc" 

Here is how to accomplish this in Visual Studio 2005 (VC8):

1) Have your executable depend on the tcmalloc library by selecting
   "Project Dependencies..." from the "Project" menu.  Your executable
   should depend on "libtcmalloc_minimal".

2) Have your executable depend on a tcmalloc symbol -- this is
   necessary so the linker doesn't "optimize out" the libtcmalloc
   dependency -- by right-clicking on your executable's project (in
   the solution explorer), selecting Properties from the pull-down
   menu, then selecting "Configuration Properties" -> "Linker" ->
   "Input".  Then, in the "Force Symbol References" field, enter the
   text "__tcmalloc" (without the quotes).  Be sure to do this for both
   debug and release modes!

You can also link tcmalloc code in statically -- see the example
project tcmalloc_minimal_unittest-static, which does this.  For this
to work, you'll need to add "/D PERFTOOLS_DLL_DECL=" to the compile
line of every perftools .cc file.  You do not need to depend on the
tcmalloc symbol in this case (that is, you don't need to do either
step 1 or step 2 from above).

An alternative to all the above is to statically link your application
with libc, and then replace its malloc with tcmalloc.  This allows you
to just build and link your program normally; the tcmalloc support
comes in a post-processing step.  This is more reliable than the above
technique (which depends on run-time patching, which is inherently
fragile), though more work to set up.  For details, see
   https://groups.google.com/group/google-perftools/browse_thread/thread/41cd3710af85e57b


--- THE HEAP-PROFILER

The heap-profiler has had a preliminary port to Windows.  It has not
been well tested, and probably does not work at all when Frame Pointer
Optimization (FPO) is enabled -- that is, in release mode.  The other
features of perftools, such as the cpu-profiler and leak-checker, have
not yet been ported to Windows at all.


--- WIN64

The function-patcher has to disassemble code, and is very
x86-specific.  However, the rest of perftools should work fine for
both x86 and x64.  In particular, if you use the 'statically link with
libc, and replace its malloc with tcmalloc' approach, mentioned above,
it should be possible to use tcmalloc with 64-bit windows.

As of perftools 1.10, there is some support for disassembling x86_64
instructions, for work with win64.  This work is preliminary, but the
test file preamble_patcher_test.cc is provided to play around with
that a bit.  preamble_patcher_test will not compile on win32.


--- ISSUES

NOTE FOR WIN2K USERS: According to reports
(http://code.google.com/p/gperftools/issues/detail?id=127)
the stack-tracing necessary for the heap-profiler does not work on
Win2K.  The best workaround is, if you are building on a Win2k system
is to add "/D NO_TCMALLOC_SAMPLES=" to your build, to turn off the
stack-tracing.  You will not be able to use the heap-profiler if you
do this.

NOTE ON _MSIZE and _RECALLOC: The tcmalloc version of _msize returns
the size of the region tcmalloc allocated for you -- which is at least
as many bytes you asked for, but may be more.  (btw, these *are* bytes
you own, even if you didn't ask for all of them, so it's correct code
to access all of them if you want.)  Unfortunately, the Windows CRT
_recalloc() routine assumes that _msize returns exactly as many bytes
as were requested.  As a result, _recalloc() may not zero out new
bytes correctly.  IT'S SAFEST NOT TO USE _RECALLOC WITH TCMALLOC.
_recalloc() is a tricky routine to use in any case (it's not safe to
use with realloc, for instance).


I have little experience with Windows programming, so there may be
better ways to set this up than I've done!  If you run across any
problems, please post to the google-perftools Google Group, or report
them on the gperftools Google Code site:
   http://groups.google.com/group/google-perftools
   http://code.google.com/p/gperftools/issues/list

-- craig

Last modified: 2 February 2012
