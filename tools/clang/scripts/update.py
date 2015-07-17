#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Windows can't run .sh files, so this is a Python implementation of
update.sh. This script should replace update.sh on all platforms eventually."""

import argparse
import contextlib
import cStringIO
import glob
import os
import pipes
import re
import shutil
import subprocess
import stat
import sys
import tarfile
import time
import urllib2
import zipfile

# Do NOT CHANGE this if you don't know what you're doing -- see
# https://code.google.com/p/chromium/wiki/UpdatingClang
# Reverting problematic clang rolls is safe, though.
# Note: this revision is only used for Windows. Other platforms use update.sh.
# TODO(thakis): Use the same revision on Windows and non-Windows.
# TODO(thakis): Remove update.sh, use update.py everywhere.
LLVM_WIN_REVISION = '242415'

use_head_revision = 'LLVM_FORCE_HEAD_REVISION' in os.environ
if use_head_revision:
  LLVM_WIN_REVISION = 'HEAD'

# This is incremented when pushing a new build of Clang at the same revision.
CLANG_SUB_REVISION=1

PACKAGE_VERSION = "%s-%s" % (LLVM_WIN_REVISION, CLANG_SUB_REVISION)

# Path constants. (All of these should be absolute paths.)
THIS_DIR = os.path.abspath(os.path.dirname(__file__))
CHROMIUM_DIR = os.path.abspath(os.path.join(THIS_DIR, '..', '..', '..'))
THIRD_PARTY_DIR = os.path.join(CHROMIUM_DIR, 'third_party')
LLVM_DIR = os.path.join(THIRD_PARTY_DIR, 'llvm')
LLVM_BOOTSTRAP_DIR = os.path.join(THIRD_PARTY_DIR, 'llvm-bootstrap')
LLVM_BOOTSTRAP_INSTALL_DIR = os.path.join(THIRD_PARTY_DIR,
                                          'llvm-bootstrap-install')
CHROME_TOOLS_SHIM_DIR = os.path.join(LLVM_DIR, 'tools', 'chrometools')
LLVM_BUILD_DIR = os.path.join(CHROMIUM_DIR, 'third_party', 'llvm-build',
                              'Release+Asserts')
COMPILER_RT_BUILD_DIR = os.path.join(LLVM_BUILD_DIR, '32bit-compiler-rt')
CLANG_DIR = os.path.join(LLVM_DIR, 'tools', 'clang')
LLD_DIR = os.path.join(LLVM_DIR, 'tools', 'lld')
COMPILER_RT_DIR = os.path.join(LLVM_DIR, 'projects', 'compiler-rt')
LIBCXX_DIR = os.path.join(LLVM_DIR, 'projects', 'libcxx')
LIBCXXABI_DIR = os.path.join(LLVM_DIR, 'projects', 'libcxxabi')
LLVM_BUILD_TOOLS_DIR = os.path.abspath(
    os.path.join(LLVM_DIR, '..', 'llvm-build-tools'))
STAMP_FILE = os.path.join(LLVM_DIR, '..', 'llvm-build', 'cr_build_revision')
BINUTILS_DIR = os.path.join(THIRD_PARTY_DIR, 'binutils')
VERSION = '3.8.0'

# URL for pre-built binaries.
CDS_URL = 'https://commondatastorage.googleapis.com/chromium-browser-clang'

LLVM_REPO_URL='https://llvm.org/svn/llvm-project'
if 'LLVM_REPO_URL' in os.environ:
  LLVM_REPO_URL = os.environ['LLVM_REPO_URL']


def DownloadUrl(url, output_file):
  """Download url into output_file."""
  CHUNK_SIZE = 4096
  TOTAL_DOTS = 10
  sys.stdout.write('Downloading %s ' % url)
  sys.stdout.flush()
  response = urllib2.urlopen(url)
  total_size = int(response.info().getheader('Content-Length').strip())
  bytes_done = 0
  dots_printed = 0
  while True:
    chunk = response.read(CHUNK_SIZE)
    if not chunk:
      break
    output_file.write(chunk)
    bytes_done += len(chunk)
    num_dots = TOTAL_DOTS * bytes_done / total_size
    sys.stdout.write('.' * (num_dots - dots_printed))
    sys.stdout.flush()
    dots_printed = num_dots
  print ' Done.'


def ReadStampFile():
  """Return the contents of the stamp file, or '' if it doesn't exist."""
  try:
    with open(STAMP_FILE, 'r') as f:
      return f.read()
  except IOError:
    return ''


def WriteStampFile(s):
  """Write s to the stamp file."""
  if not os.path.exists(os.path.dirname(STAMP_FILE)):
    os.makedirs(os.path.dirname(STAMP_FILE))
  with open(STAMP_FILE, 'w') as f:
    f.write(s)


def GetSvnRevision(svn_repo):
  """Returns current revision of the svn repo at svn_repo."""
  svn_info = subprocess.check_output('svn info ' + svn_repo, shell=True)
  m = re.search(r'Revision: (\d+)', svn_info)
  return m.group(1)


def RmTree(dir):
  """Delete dir."""
  def ChmodAndRetry(func, path, _):
    # Subversion can leave read-only files around.
    if not os.access(path, os.W_OK):
      os.chmod(path, stat.S_IWUSR)
      return func(path)
    raise

  shutil.rmtree(dir, onerror=ChmodAndRetry)


def RunCommand(command, msvc_arch=None, env=None, fail_hard=True):
  """Run command and return success (True) or failure; or if fail_hard is
     True, exit on failure.  If msvc_arch is set, runs the command in a
     shell with the msvc tools for that architecture."""

  if msvc_arch and sys.platform == 'win32':
    command = GetVSVersion().SetupScript(msvc_arch) + ['&&'] + command

  # https://docs.python.org/2/library/subprocess.html:
  # "On Unix with shell=True [...] if args is a sequence, the first item
  # specifies the command string, and any additional items will be treated as
  # additional arguments to the shell itself.  That is to say, Popen does the
  # equivalent of:
  #   Popen(['/bin/sh', '-c', args[0], args[1], ...])"
  #
  # We want to pass additional arguments to command[0], not to the shell,
  # so manually join everything into a single string.
  # Annoyingly, for "svn co url c:\path", pipes.quote() thinks that it should
  # quote c:\path but svn can't handle quoted paths on Windows.  Since on
  # Windows follow-on args are passed to args[0] instead of the shell, don't
  # do the single-string transformation there.
  if sys.platform != 'win32':
    command = ' '.join([pipes.quote(c) for c in command])
  print 'Running', command
  if subprocess.call(command, env=env, shell=True) == 0:
    return True
  print 'Failed.'
  if fail_hard:
    sys.exit(1)
  return False


def CopyFile(src, dst):
  """Copy a file from src to dst."""
  shutil.copy(src, dst)
  print "Copying %s to %s" % (src, dst)


def CopyDirectoryContents(src, dst, filename_filter=None):
  """Copy the files from directory src to dst
  with an optional filename filter."""
  if not os.path.exists(dst):
    os.makedirs(dst)
  for root, _, files in os.walk(src):
    for f in files:
      if filename_filter and not re.match(filename_filter, f):
        continue
      CopyFile(os.path.join(root, f), dst)


def Checkout(name, url, dir):
  """Checkout the SVN module at url into dir. Use name for the log message."""
  print "Checking out %s r%s into '%s'" % (name, LLVM_WIN_REVISION, dir)

  command = ['svn', 'checkout', '--force', url + '@' + LLVM_WIN_REVISION, dir]
  if RunCommand(command, fail_hard=False):
    return

  if os.path.isdir(dir):
    print "Removing %s." % (dir)
    RmTree(dir)

  print "Retrying."
  RunCommand(command)


def RevertPreviouslyPatchedFiles():
  print 'Reverting previously patched files'
  files = [
    '%(clang)s/test/Index/crash-recovery-modules.m',
    '%(clang)s/unittests/libclang/LibclangTest.cpp',
    '%(compiler_rt)s/lib/asan/asan_rtl.cc',
    '%(compiler_rt)s/test/asan/TestCases/Linux/new_array_cookie_test.cc',
    '%(llvm)s/test/DebugInfo/gmlt.ll',
    '%(llvm)s/lib/CodeGen/SpillPlacement.cpp',
    '%(llvm)s/lib/CodeGen/SpillPlacement.h',
    '%(llvm)s/lib/Transforms/Instrumentation/MemorySanitizer.cpp',
    '%(clang)s/test/Driver/env.c',
    '%(clang)s/lib/Frontend/InitPreprocessor.cpp',
    '%(clang)s/test/Frontend/exceptions.c',
    '%(clang)s/test/Preprocessor/predefined-exceptions.m',
    '%(llvm)s/test/Bindings/Go/go.test',
    '%(clang)s/lib/Parse/ParseExpr.cpp',
    '%(clang)s/lib/Parse/ParseTemplate.cpp',
    '%(clang)s/lib/Sema/SemaDeclCXX.cpp',
    '%(clang)s/lib/Sema/SemaExprCXX.cpp',
    '%(clang)s/test/SemaCXX/default2.cpp',
    '%(clang)s/test/SemaCXX/typo-correction-delayed.cpp',
    '%(compiler_rt)s/lib/sanitizer_common/sanitizer_stoptheworld_linux_libcdep.cc',
    '%(compiler_rt)s/test/tsan/signal_segv_handler.cc',
    '%(compiler_rt)s/lib/sanitizer_common/sanitizer_coverage_libcdep.cc',
    '%(compiler_rt)s/cmake/config-ix.cmake',
    '%(compiler_rt)s/CMakeLists.txt',
    '%(compiler_rt)s/lib/ubsan/ubsan_platform.h',
    ]
  for f in files:
    f = f % {
        'clang': CLANG_DIR,
        'compiler_rt': COMPILER_RT_DIR,
        'llvm': LLVM_DIR,
        }
    if os.path.exists(f):
      os.remove(f)  # For unversioned files.
      RunCommand(['svn', 'revert', f])


def ApplyLocalPatches():
  # There's no patch program on Windows by default.  We don't need patches on
  # Windows yet, and maybe this not working on Windows will motivate us to
  # remove patches over time.
  assert sys.platform != 'win32'

  # Apply patch for tests failing with --disable-pthreads (llvm.org/PR11974)
  clang_patches = [ r"""\
--- test/Index/crash-recovery-modules.m	(revision 202554)
+++ test/Index/crash-recovery-modules.m	(working copy)
@@ -12,6 +12,8 @@
 
 // REQUIRES: crash-recovery
 // REQUIRES: shell
+// XFAIL: *
+//    (PR11974)
 
 @import Crash;
""", r"""\
--- unittests/libclang/LibclangTest.cpp (revision 215949)
+++ unittests/libclang/LibclangTest.cpp (working copy)
@@ -431,7 +431,7 @@
   EXPECT_EQ(0U, clang_getNumDiagnostics(ClangTU));
 }

-TEST_F(LibclangReparseTest, ReparseWithModule) {
+TEST_F(LibclangReparseTest, DISABLED_ReparseWithModule) {
   const char *HeaderTop = "#ifndef H\n#define H\nstruct Foo { int bar;";
   const char *HeaderBottom = "\n};\n#endif\n";
   const char *MFile = "#include \"HeaderFile.h\"\nint main() {"
"""
      ]

  # This Go bindings test doesn't work after bootstrap on Linux, PR21552.
  llvm_patches = [ r"""\
--- test/Bindings/Go/go.test    (revision 223109)
+++ test/Bindings/Go/go.test    (working copy)
@@ -1,3 +1,3 @@
-; RUN: llvm-go test llvm.org/llvm/bindings/go/llvm
+; RUN: true
 
 ; REQUIRES: shell
"""
      ]

  # The UBSan run-time, which is now bundled with the ASan run-time, doesn't
  # work on Mac OS X 10.8 (PR23539).
  compiler_rt_patches = [ r"""\
--- CMakeLists.txt	(revision 241602)
+++ CMakeLists.txt	(working copy)
@@ -305,6 +305,7 @@
       list(APPEND SANITIZER_COMMON_SUPPORTED_OS iossim)
     endif()
   endif()
+  set(SANITIZER_MIN_OSX_VERSION "10.7")
   if(SANITIZER_MIN_OSX_VERSION VERSION_LESS "10.7")
     message(FATAL_ERROR "Too old OS X version: ${SANITIZER_MIN_OSX_VERSION}")
   endif()
"""
      ]

  for path, patches in [(LLVM_DIR, llvm_patches),
                        (CLANG_DIR, clang_patches),
                        (COMPILER_RT_DIR, compiler_rt_patches)]:
    print 'Applying patches in', path
    for patch in patches:
      print patch
      p = subprocess.Popen( ['patch', '-p0', '-d', path], stdin=subprocess.PIPE)
      (stdout, stderr) = p.communicate(input=patch)
      if p.returncode != 0:
        raise RuntimeError('stdout %s, stderr %s' % (stdout, stderr))


def DeleteChromeToolsShim():
  shutil.rmtree(CHROME_TOOLS_SHIM_DIR, ignore_errors=True)


def CreateChromeToolsShim():
  """Hooks the Chrome tools into the LLVM build.

  Several Chrome tools have dependencies on LLVM/Clang libraries. The LLVM build
  detects implicit tools in the tools subdirectory, so this helper install a
  shim CMakeLists.txt that forwards to the real directory for the Chrome tools.

  Note that the shim directory name intentionally has no - or _. The implicit
  tool detection logic munges them in a weird way."""
  assert not any(i in os.path.basename(CHROME_TOOLS_SHIM_DIR) for i in '-_')
  os.mkdir(CHROME_TOOLS_SHIM_DIR)
  with file(os.path.join(CHROME_TOOLS_SHIM_DIR, 'CMakeLists.txt'), 'w') as f:
    f.write('# Automatically generated by tools/clang/scripts/update.py. ' +
            'Do not edit.\n')
    f.write('# Since tools/clang is located in another directory, use the \n')
    f.write('# two arg version to specify where build artifacts go. CMake\n')
    f.write('# disallows reuse of the same binary dir for multiple source\n')
    f.write('# dirs, so the build artifacts need to go into a subdirectory.\n')
    f.write('# dirs, so the build artifacts need to go into a subdirectory.\n')
    f.write('if (CHROMIUM_TOOLS_SRC)\n')
    f.write('  add_subdirectory(${CHROMIUM_TOOLS_SRC} ' +
              '${CMAKE_CURRENT_BINARY_DIR}/a)\n')
    f.write('endif (CHROMIUM_TOOLS_SRC)\n')


def AddCMakeToPath():
  """Download CMake and add it to PATH."""
  if sys.platform == 'win32':
    zip_name = 'cmake-3.2.2-win32-x86.zip'
    cmake_dir = os.path.join(LLVM_BUILD_TOOLS_DIR,
                             'cmake-3.2.2-win32-x86', 'bin')
  else:
    suffix = 'Darwin' if sys.platform == 'darwin' else 'Linux'
    zip_name = 'cmake310_%s.tgz' % suffix
    cmake_dir = os.path.join(LLVM_BUILD_TOOLS_DIR, 'cmake310', 'bin')
  if not os.path.exists(cmake_dir):
    if not os.path.exists(LLVM_BUILD_TOOLS_DIR):
      os.makedirs(LLVM_BUILD_TOOLS_DIR)
    # The cmake archive is smaller than 20 MB, small enough to keep in memory:
    with contextlib.closing(cStringIO.StringIO()) as f:
      DownloadUrl(CDS_URL + '/tools/' + zip_name, f)
      f.seek(0)
      if zip_name.endswith('.zip'):
        zipfile.ZipFile(f).extractall(path=LLVM_BUILD_TOOLS_DIR)
      else:
        tarfile.open(mode='r:gz', fileobj=f).extractall(path=
            LLVM_BUILD_TOOLS_DIR)
  os.environ['PATH'] = cmake_dir + os.pathsep + os.environ.get('PATH', '')

vs_version = None
def GetVSVersion():
  global vs_version
  if vs_version:
    return vs_version

  # Try using the toolchain in depot_tools.
  # This sets environment variables used by SelectVisualStudioVersion below.
  sys.path.append(os.path.join(CHROMIUM_DIR, 'build'))
  import vs_toolchain
  vs_toolchain.SetEnvironmentAndGetRuntimeDllDirs()

  # Use gyp to find the MSVS installation, either in depot_tools as per above,
  # or a system-wide installation otherwise.
  sys.path.append(os.path.join(CHROMIUM_DIR, 'tools', 'gyp', 'pylib'))
  import gyp.MSVSVersion
  vs_version = gyp.MSVSVersion.SelectVisualStudioVersion('2013')
  return vs_version


def UpdateClang(args):
  print 'Updating Clang to %s...' % PACKAGE_VERSION
  if ReadStampFile() == PACKAGE_VERSION:
    print 'Already up to date.'
    return 0

  # Reset the stamp file in case the build is unsuccessful.
  WriteStampFile('')

  if not args.force_local_build:
    cds_file = "clang-%s.tgz" %  PACKAGE_VERSION
    cds_full_url = CDS_URL + '/Win/' + cds_file

    # Check if there's a prebuilt binary and if so just fetch that. That's
    # faster, and goma relies on having matching binary hashes on client and
    # server too.
    print 'Trying to download prebuilt clang'

    # clang packages are smaller than 50 MB, small enough to keep in memory.
    with contextlib.closing(cStringIO.StringIO()) as f:
      try:
        DownloadUrl(cds_full_url, f)
        f.seek(0)
        tarfile.open(mode='r:gz', fileobj=f).extractall(path=LLVM_BUILD_DIR)
        print 'clang %s unpacked' % PACKAGE_VERSION
        # Download the gold plugin if requested to by an environment variable.
        # This is used by the CFI ClusterFuzz bot.
        if 'LLVM_DOWNLOAD_GOLD_PLUGIN' in os.environ:
          RunCommand(['python', CHROMIUM_DIR+'/build/download_gold_plugin.py'])
        WriteStampFile(PACKAGE_VERSION)
        return 0
      except urllib2.HTTPError:
        print 'Did not find prebuilt clang %s, building locally' % cds_file

  AddCMakeToPath()

  RevertPreviouslyPatchedFiles()
  DeleteChromeToolsShim()

  Checkout('LLVM', LLVM_REPO_URL + '/llvm/trunk', LLVM_DIR)
  Checkout('Clang', LLVM_REPO_URL + '/cfe/trunk', CLANG_DIR)
  if sys.platform == 'win32':
    Checkout('LLD', LLVM_REPO_URL + '/lld/trunk', LLD_DIR)
  Checkout('compiler-rt', LLVM_REPO_URL + '/compiler-rt/trunk', COMPILER_RT_DIR)
  if sys.platform == 'darwin':
    # clang needs a libc++ checkout, else -stdlib=libc++ won't find includes
    # (i.e. this is needed for bootstrap builds).
    Checkout('libcxx', LLVM_REPO_URL + '/libcxx/trunk', LIBCXX_DIR)
    # While we're bundling our own libc++ on OS X, we need to compile libc++abi
    # into it too (since OS X 10.6 doesn't have libc++abi.dylib either).
    Checkout('libcxxabi', LLVM_REPO_URL + '/libcxxabi/trunk', LIBCXXABI_DIR)

  if args.with_patches and sys.platform != 'win32':
    ApplyLocalPatches()

  cc, cxx = None, None
  cflags = cxxflags = ldflags = []

  # LLVM uses C++11 starting in llvm 3.5. On Linux, this means libstdc++4.7+ is
  # needed, on OS X it requires libc++. clang only automatically links to libc++
  # when targeting OS X 10.9+, so add stdlib=libc++ explicitly so clang can run
  # on OS X versions as old as 10.7.
  # TODO(thakis): Some bots are still on 10.6 (nacl...), so for now bundle
  # libc++.dylib.  Remove this once all bots are on 10.7+, then use
  # -DLLVM_ENABLE_LIBCXX=ON and change deployment_target to 10.7.
  deployment_target = ''

  if sys.platform == 'darwin':
    # When building on 10.9, /usr/include usually doesn't exist, and while
    # Xcode's clang automatically sets a sysroot, self-built clangs don't.
    cflags = ['-isysroot', subprocess.check_output(
        ['xcrun', '--show-sdk-path']).rstrip()]
    cxxflags = ['-stdlib=libc++', '-nostdinc++',
                '-I' + os.path.join(LIBCXX_DIR, 'include')] + cflags
    if args.bootstrap:
      deployment_target = '10.6'

  base_cmake_args = ['-GNinja',
                     '-DCMAKE_BUILD_TYPE=Release',
                     '-DLLVM_ENABLE_ASSERTIONS=ON',
                     '-DLLVM_ENABLE_THREADS=OFF',
                     ]

  if args.bootstrap:
    print 'Building bootstrap compiler'
    if not os.path.exists(LLVM_BOOTSTRAP_DIR):
      os.makedirs(LLVM_BOOTSTRAP_DIR)
    os.chdir(LLVM_BOOTSTRAP_DIR)
    bootstrap_args = base_cmake_args + [
        '-DLLVM_TARGETS_TO_BUILD=host',
        '-DCMAKE_INSTALL_PREFIX=' + LLVM_BOOTSTRAP_INSTALL_DIR,
        '-DCMAKE_C_FLAGS=' + ' '.join(cflags),
        '-DCMAKE_CXX_FLAGS=' + ' '.join(cxxflags),
        ]
    if cc is not None:  bootstrap_args.append('-DCMAKE_C_COMPILER=' + cc)
    if cxx is not None: bootstrap_args.append('-DCMAKE_CXX_COMPILER=' + cxx)
    RunCommand(['cmake'] + bootstrap_args + [LLVM_DIR], msvc_arch='x64')
    RunCommand(['ninja'], msvc_arch='x64')
    if args.run_tests:
      RunCommand(['ninja', 'check-all'], msvc_arch='x64')
    RunCommand(['ninja', 'install'], msvc_arch='x64')

    if sys.platform == 'win32':
      cc = os.path.join(LLVM_BOOTSTRAP_INSTALL_DIR, 'bin', 'clang-cl.exe')
      cxx = os.path.join(LLVM_BOOTSTRAP_INSTALL_DIR, 'bin', 'clang-cl.exe')
      # CMake has a hard time with backslashes in compiler paths:
      # https://stackoverflow.com/questions/13050827
      cc = cc.replace('\\', '/')
      cxx = cxx.replace('\\', '/')
    else:
      cc = os.path.join(LLVM_BOOTSTRAP_INSTALL_DIR, 'bin', 'clang')
      cxx = os.path.join(LLVM_BOOTSTRAP_INSTALL_DIR, 'bin', 'clang++')
    print 'Building final compiler'

  if sys.platform == 'darwin':
    # Build libc++.dylib while some bots are still on OS X 10.6.
    libcxxbuild = os.path.join(LLVM_BUILD_DIR, 'libcxxbuild')
    if os.path.isdir(libcxxbuild):
      RmTree(libcxxbuild)
    libcxxflags = ['-O3', '-std=c++11', '-fstrict-aliasing']

    # libcxx and libcxxabi both have a file stdexcept.cpp, so put their .o files
    # into different subdirectories.
    os.makedirs(os.path.join(libcxxbuild, 'libcxx'))
    os.chdir(os.path.join(libcxxbuild, 'libcxx'))
    RunCommand(['c++', '-c'] + cxxflags + libcxxflags +
                glob.glob(os.path.join(LIBCXX_DIR, 'src', '*.cpp')))

    os.makedirs(os.path.join(libcxxbuild, 'libcxxabi'))
    os.chdir(os.path.join(libcxxbuild, 'libcxxabi'))
    RunCommand(['c++', '-c'] + cxxflags + libcxxflags +
               glob.glob(os.path.join(LIBCXXABI_DIR, 'src', '*.cpp')) +
               ['-I' + os.path.join(LIBCXXABI_DIR, 'include')])

    os.chdir(libcxxbuild)
    libdir = os.path.join(LIBCXX_DIR, 'lib')
    RunCommand(['cc'] + glob.glob('libcxx/*.o') + glob.glob('libcxxabi/*.o') +
        ['-o', 'libc++.1.dylib', '-dynamiclib', '-nodefaultlibs',
         '-current_version', '1', '-compatibility_version', '1', '-lSystem',
         '-install_name', '@executable_path/libc++.dylib',
         '-Wl,-unexported_symbols_list,' + libdir + '/libc++unexp.exp',
         '-Wl,-force_symbols_not_weak_list,' + libdir + '/notweak.exp',
         '-Wl,-force_symbols_weak_list,' + libdir + '/weak.exp'])
    if os.path.exists('libc++.dylib'):
      os.remove('libc++.dylib')
    os.symlink('libc++.1.dylib', 'libc++.dylib')
    ldflags += ['-stdlib=libc++', '-L' + libcxxbuild]

    if args.bootstrap:
      # Now that the libc++ headers have been installed and libc++.dylib is
      # built, delete the libc++ checkout again so that it's not part of the
      # main build below -- the libc++(abi) tests don't pass on OS X in
      # bootstrap builds (http://llvm.org/PR24068)
      RmTree(LIBCXX_DIR)
      RmTree(LIBCXXABI_DIR)
      cxxflags = ['-stdlib=libc++', '-nostdinc++',
                  '-I' + os.path.join(LLVM_BOOTSTRAP_INSTALL_DIR,
                                      'include/c++/v1')
                  ] + cflags

  # Build clang.
  binutils_incdir = ''
  if sys.platform.startswith('linux'):
    binutils_incdir = os.path.join(BINUTILS_DIR, 'Linux_x64/Release/include')

  # If building at head, define a macro that plugins can use for #ifdefing
  # out code that builds at head, but not at LLVM_WIN_REVISION or vice versa.
  if use_head_revision:
    cflags += ['-DLLVM_FORCE_HEAD_REVISION']
    cxxflags += ['-DLLVM_FORCE_HEAD_REVISION']

  CreateChromeToolsShim()

  deployment_env = None
  if deployment_target:
    deployment_env = os.environ.copy()
    deployment_env['MACOSX_DEPLOYMENT_TARGET'] = deployment_target

  cmake_args = base_cmake_args + [
      '-DLLVM_BINUTILS_INCDIR=' + binutils_incdir,
      '-DCMAKE_C_FLAGS=' + ' '.join(cflags),
      '-DCMAKE_CXX_FLAGS=' + ' '.join(cxxflags),
      '-DCMAKE_EXE_LINKER_FLAGS=' + ' '.join(ldflags),
      '-DCMAKE_SHARED_LINKER_FLAGS=' + ' '.join(ldflags),
      '-DCMAKE_MODULE_LINKER_FLAGS=' + ' '.join(ldflags),
      '-DCMAKE_INSTALL_PREFIX=' + LLVM_BUILD_DIR,
      '-DCHROMIUM_TOOLS_SRC=%s' % os.path.join(CHROMIUM_DIR, 'tools', 'clang'),
      '-DCHROMIUM_TOOLS=%s' % ';'.join(args.tools)]
  # TODO(thakis): Unconditionally append this to base_cmake_args instead once
  # compiler-rt can build with clang-cl on Windows (http://llvm.org/PR23698)
  cc_args = base_cmake_args if sys.platform != 'win32' else cmake_args
  if cc is not None:  cc_args.append('-DCMAKE_C_COMPILER=' + cc)
  if cxx is not None: cc_args.append('-DCMAKE_CXX_COMPILER=' + cxx)

  if not os.path.exists(LLVM_BUILD_DIR):
    os.makedirs(LLVM_BUILD_DIR)
  os.chdir(LLVM_BUILD_DIR)
  RunCommand(['cmake'] + cmake_args + [LLVM_DIR],
             msvc_arch='x64', env=deployment_env)
  RunCommand(['ninja'], msvc_arch='x64')

  if args.tools:
    # If any Chromium tools were built, install those now.
    RunCommand(['ninja', 'cr-install'], msvc_arch='x64')

  if sys.platform == 'darwin':
    CopyFile(os.path.join(LLVM_BUILD_DIR, 'libc++.1.dylib'),
             os.path.join(LLVM_BUILD_DIR, 'bin'))
    # See http://crbug.com/256342
    RunCommand(['strip', '-x', os.path.join(LLVM_BUILD_DIR, 'bin', 'clang')])
  elif sys.platform.startswith('linux'):
    RunCommand(['strip', os.path.join(LLVM_BUILD_DIR, 'bin', 'clang')])

  # Do an x86 build of compiler-rt to get the 32-bit ASan run-time.
  # TODO(hans): Remove once the regular build above produces this.
  if not os.path.exists(COMPILER_RT_BUILD_DIR):
    os.makedirs(COMPILER_RT_BUILD_DIR)
  os.chdir(COMPILER_RT_BUILD_DIR)
  # TODO(thakis): Add this once compiler-rt can build with clang-cl (see
  # above).
  #if args.bootstrap and sys.platform == 'win32':
    # The bootstrap compiler produces 64-bit binaries by default.
    #cflags += ['-m32']
    #cxxflags += ['-m32']
  compiler_rt_args = base_cmake_args + [
      '-DCMAKE_C_FLAGS=' + ' '.join(cflags),
      '-DCMAKE_CXX_FLAGS=' + ' '.join(cxxflags)]
  if sys.platform != 'win32':
    compiler_rt_args += ['-DLLVM_CONFIG_PATH=' +
                         os.path.join(LLVM_BUILD_DIR, 'bin', 'llvm-config')]
  RunCommand(['cmake'] + compiler_rt_args + [LLVM_DIR],
              msvc_arch='x86', env=deployment_env)
  RunCommand(['ninja', 'compiler-rt'], msvc_arch='x86')

  # TODO(hans): Make this (and the .gypi and .isolate files) version number
  # independent.
  if sys.platform == 'win32':
    platform = 'windows'
  elif sys.platform == 'darwin':
    platform = 'darwin'
  else:
    assert sys.platform.startswith('linux')
    platform = 'linux'
  asan_rt_lib_src_dir = os.path.join(COMPILER_RT_BUILD_DIR, 'lib', 'clang',
                                     VERSION, 'lib', platform)
  asan_rt_lib_dst_dir = os.path.join(LLVM_BUILD_DIR, 'lib', 'clang',
                                     VERSION, 'lib', platform)
  CopyDirectoryContents(asan_rt_lib_src_dir, asan_rt_lib_dst_dir,
                        r'^.*-i386\.lib$')
  CopyDirectoryContents(asan_rt_lib_src_dir, asan_rt_lib_dst_dir,
                        r'^.*-i386\.dll$')

  CopyFile(os.path.join(asan_rt_lib_src_dir, '..', '..', 'asan_blacklist.txt'),
           os.path.join(asan_rt_lib_dst_dir, '..', '..'))

  if sys.platform == 'win32':
    # Make an extra copy of the sanitizer headers, to be put on the include path
    # of the fallback compiler.
    sanitizer_include_dir = os.path.join(LLVM_BUILD_DIR, 'lib', 'clang',
                                         VERSION, 'include', 'sanitizer')
    aux_sanitizer_include_dir = os.path.join(LLVM_BUILD_DIR, 'lib', 'clang',
                                             VERSION, 'include_sanitizer',
                                             'sanitizer')
    if not os.path.exists(aux_sanitizer_include_dir):
      os.makedirs(aux_sanitizer_include_dir)
    for _, _, files in os.walk(sanitizer_include_dir):
      for f in files:
        CopyFile(os.path.join(sanitizer_include_dir, f),
                 aux_sanitizer_include_dir)

  # Run tests.
  if args.run_tests or use_head_revision:
    os.chdir(LLVM_BUILD_DIR)
    RunCommand(GetVSVersion().SetupScript('x64') +
               ['&&', 'ninja', 'cr-check-all'])
  if args.run_tests:
    os.chdir(LLVM_BUILD_DIR)
    RunCommand(GetVSVersion().SetupScript('x64') +
               ['&&', 'ninja', 'check-all'])

  WriteStampFile(PACKAGE_VERSION)
  print 'Clang update was successful.'
  return 0


def main():
  if not sys.platform in ['win32', 'cygwin']:
    # For non-Windows, fall back to update.sh.
    # TODO(hans): Make update.py replace update.sh completely.

    # This script is called by gclient. gclient opens its hooks subprocesses
    # with (stdout=subprocess.PIPE, stderr=subprocess.STDOUT) and then does
    # custom output processing that breaks printing '\r' characters for
    # single-line updating status messages as printed by curl and wget.
    # Work around this by setting stderr of the update.sh process to stdin (!):
    # gclient doesn't redirect stdin, and while stdin itself is read-only, a
    # dup()ed sys.stdin is writable, try
    #   fd2 = os.dup(sys.stdin.fileno()); os.write(fd2, 'hi')
    # TODO: Fix gclient instead, http://crbug.com/95350
    if '--no-stdin-hack' in sys.argv:
      sys.argv.remove('--no-stdin-hack')
      stderr = None
    else:
      try:
        stderr = os.fdopen(os.dup(sys.stdin.fileno()))
      except:
        stderr = sys.stderr
    return subprocess.call(
        [os.path.join(os.path.dirname(__file__), 'update.sh')] + sys.argv[1:],
        stderr=stderr)

  parser = argparse.ArgumentParser(description='Build Clang.')
  parser.add_argument('--bootstrap', action='store_true',
                      help='first build clang with CC, then with itself.')
  parser.add_argument('--if-needed', action='store_true',
                      help="run only if the script thinks clang is needed")
  parser.add_argument('--force-local-build', action='store_true',
                      help="don't try to download prebuild binaries")
  parser.add_argument('--print-revision', action='store_true',
                      help='print current clang revision and exit.')
  parser.add_argument('--print-clang-version', action='store_true',
                      help='print current clang version (e.g. x.y.z) and exit.')
  parser.add_argument('--run-tests', action='store_true',
                      help='run tests after building; only for local builds')
  parser.add_argument('--tools', nargs='*',
                      help='select which chrome tools to build',
                      default=['plugins', 'blink_gc_plugin'])
  parser.add_argument('--without-patches', action='store_false',
                      help="don't apply patches (default)", dest='with_patches',
                      default=True)

  # For now, these flags are only used for the non-Windows flow, but argparser
  # gets mad if it sees a flag it doesn't recognize.
  parser.add_argument('--no-stdin-hack', action='store_true')

  args = parser.parse_args()

  if args.if_needed:
    is_clang_required = False
    # clang is always used on Mac and Linux.
    if sys.platform == 'darwin' or sys.platform.startswith('linux'):
      is_clang_required = True
    # clang requested via $GYP_DEFINES.
    if re.search(r'\b(clang|asan|lsan|msan|tsan)=1',
                 os.environ.get('GYP_DEFINES', '')):
      is_clang_required = True
    # clang previously downloaded, keep it up-to-date.
    # If you don't want this, delete third_party/llvm-build on your machine.
    if os.path.isdir(LLVM_BUILD_DIR):
      is_clang_required = True
    if not is_clang_required:
      return 0
    if re.search(r'\b(make_clang_dir)=', os.environ.get('GYP_DEFINES', '')):
      print 'Skipping Clang update (make_clang_dir= was set in GYP_DEFINES).'
      return 0

  global LLVM_WIN_REVISION, PACKAGE_VERSION
  if args.print_revision:
    if use_head_revision:
      print GetSvnRevision(LLVM_DIR)
    else:
      print PACKAGE_VERSION
    return 0

  if args.print_clang_version:
    sys.stdout.write(VERSION)
    return 0

  # Don't buffer stdout, so that print statements are immediately flushed.
  # Do this only after --print-revision has been handled, else we'll get
  # an error message when this script is run from gn for some reason.
  sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

  if use_head_revision:
    # Use a real revision number rather than HEAD to make sure that the stamp
    # file logic works.
    LLVM_WIN_REVISION = GetSvnRevision(LLVM_REPO_URL)
    PACKAGE_VERSION = LLVM_WIN_REVISION + '-0'

    args.force_local_build = True
    # Skip local patches when using HEAD: they probably don't apply anymore.
    args.with_patches = False

  return UpdateClang(args)


if __name__ == '__main__':
  sys.exit(main())
