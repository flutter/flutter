#!/usr/bin/env python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This script will check out llvm and clang, and then package the results up
to a tgz file."""

import argparse
import fnmatch
import itertools
import os
import shutil
import subprocess
import sys
import tarfile

# Path constants.
THIS_DIR = os.path.dirname(__file__)
THIRD_PARTY_DIR = os.path.join(THIS_DIR, '..', '..', '..', 'third_party')
LLVM_DIR = os.path.join(THIRD_PARTY_DIR, 'llvm')
LLVM_BOOTSTRAP_DIR = os.path.join(THIRD_PARTY_DIR, 'llvm-bootstrap')
LLVM_BOOTSTRAP_INSTALL_DIR = os.path.join(THIRD_PARTY_DIR,
                                          'llvm-bootstrap-install')
LLVM_BUILD_DIR = os.path.join(THIRD_PARTY_DIR, 'llvm-build')
LLVM_RELEASE_DIR = os.path.join(LLVM_BUILD_DIR, 'Release+Asserts')
STAMP_FILE = os.path.join(LLVM_BUILD_DIR, 'cr_build_revision')


def Tee(output, logfile):
  logfile.write(output)
  print output,


def TeeCmd(cmd, logfile, fail_hard=True):
  """Runs cmd and writes the output to both stdout and logfile."""
  # Reading from PIPE can deadlock if one buffer is full but we wait on a
  # different one.  To work around this, pipe the subprocess's stderr to
  # its stdout buffer and don't give it a stdin.
  # shell=True is required in cmd.exe since depot_tools has an svn.bat, and
  # bat files only work with shell=True set.
  proc = subprocess.Popen(cmd, bufsize=1, shell=sys.platform == 'win32',
                          stdin=open(os.devnull), stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT)
  for line in iter(proc.stdout.readline,''):
    Tee(line, logfile)
    if proc.poll() is not None:
      break
  exit_code = proc.wait()
  if exit_code != 0 and fail_hard:
    print 'Failed:', cmd
    sys.exit(1)


def PrintTarProgress(tarinfo):
  print 'Adding', tarinfo.name
  return tarinfo


def main():
  parser = argparse.ArgumentParser(description='build and package clang')
  parser.add_argument('--gcc-toolchain',
                      help="the prefix for the GCC version used for building. "
                           "For /opt/foo/bin/gcc, pass "
                           "'--gcc-toolchain '/opt/foo'")

  args = parser.parse_args()

  with open('buildlog.txt', 'w') as log:
    Tee('Diff in llvm:\n', log)
    TeeCmd(['svn', 'stat', LLVM_DIR], log, fail_hard=False)
    TeeCmd(['svn', 'diff', LLVM_DIR], log, fail_hard=False)
    Tee('Diff in llvm/tools/clang:\n', log)
    TeeCmd(['svn', 'stat', os.path.join(LLVM_DIR, 'tools', 'clang')],
           log, fail_hard=False)
    TeeCmd(['svn', 'diff', os.path.join(LLVM_DIR, 'tools', 'clang')],
           log, fail_hard=False)
    # TODO(thakis): compiler-rt is in projects/compiler-rt on Windows but
    # llvm/compiler-rt elsewhere. So this diff call is currently only right on
    # Windows.
    Tee('Diff in llvm/compiler-rt:\n', log)
    TeeCmd(['svn', 'stat', os.path.join(LLVM_DIR, 'projects', 'compiler-rt')],
           log, fail_hard=False)
    TeeCmd(['svn', 'diff', os.path.join(LLVM_DIR, 'projects', 'compiler-rt')],
           log, fail_hard=False)
    Tee('Diff in llvm/projects/libcxx:\n', log)
    TeeCmd(['svn', 'stat', os.path.join(LLVM_DIR, 'projects', 'libcxx')],
           log, fail_hard=False)
    TeeCmd(['svn', 'diff', os.path.join(LLVM_DIR, 'projects', 'libcxx')],
           log, fail_hard=False)
    Tee('Diff in llvm/projects/libcxxabi:\n', log)
    TeeCmd(['svn', 'stat', os.path.join(LLVM_DIR, 'projects', 'libcxxabi')],
           log, fail_hard=False)
    TeeCmd(['svn', 'diff', os.path.join(LLVM_DIR, 'projects', 'libcxxabi')],
           log, fail_hard=False)

    Tee('Starting build\n', log)

    # Do a clobber build.
    shutil.rmtree(LLVM_BOOTSTRAP_DIR, ignore_errors=True)
    shutil.rmtree(LLVM_BOOTSTRAP_INSTALL_DIR, ignore_errors=True)
    shutil.rmtree(LLVM_BUILD_DIR, ignore_errors=True)

    build_cmd = [sys.executable, os.path.join(THIS_DIR, 'update.py'),
                 '--bootstrap', '--force-local-build', '--run-tests',
                 '--no-stdin-hack']
    if args.gcc_toolchain is not None:
      build_cmd.extend(['--gcc-toolchain', args.gcc_toolchain])
    TeeCmd(build_cmd, log)

  stamp = open(STAMP_FILE).read().rstrip()
  pdir = 'clang-' + stamp
  print pdir
  shutil.rmtree(pdir, ignore_errors=True)

  # Copy a whitelist of files to the directory we're going to tar up.
  # This supports the same patterns that the fnmatch module understands.
  exe_ext = '.exe' if sys.platform == 'win32' else ''
  want = ['bin/llvm-symbolizer' + exe_ext,
          'lib/clang/*/asan_blacklist.txt',
          # Copy built-in headers (lib/clang/3.x.y/include).
          'lib/clang/*/include/*',
          ]
  if sys.platform == 'win32':
    want.append('bin/clang-cl.exe')
  else:
    so_ext = 'dylib' if sys.platform == 'darwin' else 'so'
    want.extend(['bin/clang',
                 'lib/libFindBadConstructs.' + so_ext,
                 'lib/libBlinkGCPlugin.' + so_ext,
                 ])
  if sys.platform == 'darwin':
    want.extend(['bin/libc++.1.dylib',
                 # Copy only the OSX (ASan and profile) and iossim (ASan)
                 # runtime libraries:
                 'lib/clang/*/lib/darwin/*asan_osx*',
                 'lib/clang/*/lib/darwin/*asan_iossim*',
                 'lib/clang/*/lib/darwin/*profile_osx*',
                 ])
  elif sys.platform.startswith('linux'):
    # Copy only
    # lib/clang/*/lib/linux/libclang_rt.{[atm]san,san,ubsan,profile}-*.a ,
    # but not dfsan.
    want.extend(['lib/clang/*/lib/linux/*[atm]san*',
                 'lib/clang/*/lib/linux/*ubsan*',
                 'lib/clang/*/lib/linux/*libclang_rt.san*',
                 'lib/clang/*/lib/linux/*profile*',
                 'lib/clang/*/msan_blacklist.txt',
                 ])
  elif sys.platform == 'win32':
    want.extend(['lib/clang/*/lib/windows/clang_rt.asan*.dll',
                 'lib/clang/*/lib/windows/clang_rt.asan*.lib',
                 'lib/clang/*/include_sanitizer/*',
                 ])
  if args.gcc_toolchain is not None:
    # Copy the stdlibc++.so.6 we linked Clang against so it can run.
    want.append('lib/libstdc++.so.6')

  for root, dirs, files in os.walk(LLVM_RELEASE_DIR):
    # root: third_party/llvm-build/Release+Asserts/lib/..., rel_root: lib/...
    rel_root = root[len(LLVM_RELEASE_DIR)+1:]
    rel_files = [os.path.join(rel_root, f) for f in files]
    wanted_files = list(set(itertools.chain.from_iterable(
        fnmatch.filter(rel_files, p) for p in want)))
    if wanted_files:
      # Guaranteed to not yet exist at this point:
      os.makedirs(os.path.join(pdir, rel_root))
    for f in wanted_files:
      src = os.path.join(LLVM_RELEASE_DIR, f)
      dest = os.path.join(pdir, f)
      shutil.copy(src, dest)
      # Strip libraries.
      if sys.platform == 'darwin' and f.endswith('.dylib'):
        # Fix LC_ID_DYLIB for the ASan dynamic libraries to be relative to
        # @executable_path.
        # TODO(glider): this is transitional. We'll need to fix the dylib
        # name either in our build system, or in Clang. See also
        # http://crbug.com/344836.
        subprocess.call(['install_name_tool', '-id',
                         '@executable_path/' + os.path.basename(dest), dest])
        subprocess.call(['strip', '-x', dest])
      elif (sys.platform.startswith('linux') and
            os.path.splitext(f)[1] in ['.so', '.a']):
        subprocess.call(['strip', '-g', dest])

  # Set up symlinks.
  if sys.platform != 'win32':
    os.symlink('clang', os.path.join(pdir, 'bin', 'clang++'))
    os.symlink('clang', os.path.join(pdir, 'bin', 'clang-cl'))
  if sys.platform == 'darwin':
    os.symlink('libc++.1.dylib', os.path.join(pdir, 'bin', 'libc++.dylib'))
    # Also copy libc++ headers.
    shutil.copytree(os.path.join(LLVM_BOOTSTRAP_INSTALL_DIR, 'include', 'c++'),
                    os.path.join(pdir, 'include', 'c++'))

  # Copy buildlog over.
  shutil.copy('buildlog.txt', pdir)

  # Create archive.
  tar_entries = ['bin', 'lib', 'buildlog.txt']
  if sys.platform == 'darwin':
    tar_entries += ['include']
  with tarfile.open(pdir + '.tgz', 'w:gz') as tar:
    for entry in tar_entries:
      tar.add(os.path.join(pdir, entry), arcname=entry, filter=PrintTarProgress)

  if sys.platform == 'darwin':
    platform = 'Mac'
  elif sys.platform == 'win32':
    platform = 'Win'
  else:
    platform = 'Linux_x64'

  print 'To upload, run:'
  print ('gsutil cp -a public-read %s.tgz '
         'gs://chromium-browser-clang/%s/%s.tgz') % (pdir, platform, pdir)

  # Zip up gold plugin on Linux.
  if sys.platform.startswith('linux'):
    golddir = 'llvmgold-' + stamp
    shutil.rmtree(golddir, ignore_errors=True)
    os.makedirs(os.path.join(golddir, 'lib'))
    shutil.copy(os.path.join(LLVM_RELEASE_DIR, 'lib', 'LLVMgold.so'),
                os.path.join(golddir, 'lib'))
    with tarfile.open(golddir + '.tgz', 'w:gz') as tar:
      tar.add(os.path.join(golddir, 'lib'), arcname='lib',
              filter=PrintTarProgress)
    print ('gsutil cp -a public-read %s.tgz '
           'gs://chromium-browser-clang/%s/%s.tgz') % (golddir, platform,
                                                       golddir)

  # FIXME: Warn if the file already exists on the server.


if __name__ == '__main__':
  sys.exit(main())
