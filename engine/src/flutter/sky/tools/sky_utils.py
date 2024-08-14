#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import platform
import shutil
import subprocess
import sys


def assert_directory(path, what):
  """Logs an error and exits with EX_NOINPUT if the specified directory doesn't exist."""
  if not os.path.isdir(path):
    log_error('Cannot find %s at %s' % (what, path))
    sys.exit(os.EX_NOINPUT)


def assert_file(path, what):
  """Logs an error and exits with EX_NOINPUT if the specified file doesn't exist."""
  if not os.path.isfile(path):
    log_error('Cannot find %s at %s' % (what, path))
    sys.exit(os.EX_NOINPUT)


def buildroot_relative_path(path):
  """Returns the absolute path to the specified buildroot-relative path."""
  buildroot_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..', '..', '..', '..'))
  return os.path.join(buildroot_dir, path)


def copy_binary(source_path, destination_path):
  """Copies a binary, preserving POSIX permissions."""
  assert_file(source_path, 'file to copy')
  shutil.copy2(source_path, destination_path)


def copy_tree(source_path, destination_path, symlinks=False):
  """Performs a recursive copy of a directory.
  If the destination path is present, it is deleted first."""
  assert_directory(source_path, 'directory to copy')
  shutil.rmtree(destination_path, True)
  shutil.copytree(source_path, destination_path, symlinks=symlinks)


def create_fat_macos_framework(fat_framework, arm64_framework, x64_framework):
  """Creates a fat framework from two arm64 and x64 frameworks."""
  # Clone the arm64 framework bundle as a starting point.
  copy_tree(arm64_framework, fat_framework, symlinks=True)
  _regenerate_symlinks(fat_framework)
  lipo([get_framework_dylib_path(arm64_framework),
        get_framework_dylib_path(x64_framework)], get_framework_dylib_path(fat_framework))
  _set_framework_permissions(fat_framework)


def _regenerate_symlinks(framework_path):
  """Regenerates the framework symlink structure.

  When building on the bots, the framework is produced in one shard, uploaded
  to LUCI's content-addressable storage cache (CAS), then pulled down in
  another shard. When that happens, symlinks are dereferenced, resulting a
  corrupted framework. This regenerates the expected symlink farm.
  """
  # If the dylib is symlinked, assume symlinks are all fine and bail out.
  # The shutil.rmtree calls below only work on directories, and fail on symlinks.
  framework_name = get_framework_name(framework_path)
  framework_binary = get_framework_dylib_path(framework_path)
  if os.path.islink(os.path.join(framework_path, framework_name)):
    return

  # Delete any existing files/directories.
  os.remove(framework_binary)
  shutil.rmtree(os.path.join(framework_path, 'Headers'), True)
  shutil.rmtree(os.path.join(framework_path, 'Modules'), True)
  shutil.rmtree(os.path.join(framework_path, 'Resources'), True)
  current_version_path = os.path.join(framework_path, 'Versions', 'Current')
  shutil.rmtree(current_version_path, True)

  # Recreate the expected framework symlinks.
  os.symlink('A', current_version_path)
  os.symlink(os.path.join(current_version_path, framework_name), framework_binary)
  os.symlink(os.path.join(current_version_path, 'Headers'), os.path.join(framework_path, 'Headers'))
  os.symlink(os.path.join(current_version_path, 'Modules'), os.path.join(framework_path, 'Modules'))
  os.symlink(
      os.path.join(current_version_path, 'Resources'), os.path.join(framework_path, 'Resources')
  )


def _set_framework_permissions(framework_dir):
  """Sets framework contents to be world readable, and world executable if user-executable."""
  # Make the framework readable and executable: u=rwx,go=rx.
  subprocess.check_call(['chmod', '755', framework_dir])

  # Add group and other readability to all files.
  subprocess.check_call(['chmod', '-R', 'og+r', framework_dir])

  # Find all the files below the target dir with owner execute permission and
  # set og+x where it had the execute permission set for the owner.
  find_subprocess = subprocess.Popen(['find', framework_dir, '-perm', '-100', '-print0'],
                                     stdout=subprocess.PIPE)
  xargs_subprocess = subprocess.Popen(['xargs', '-0', 'chmod', 'og+x'],
                                      stdin=find_subprocess.stdout)
  find_subprocess.wait()
  xargs_subprocess.wait()


def create_zip(cwd, zip_filename, paths, symlinks=False):
  """Creates a zip archive in cwd, containing a set of cwd-relative files."""
  options = ['-r']
  if symlinks:
    options.append('-y')
  subprocess.check_call(['zip'] + options + [zip_filename] + paths, cwd=cwd)


def _dsymutil_path():
  """Returns the path to dsymutil within Flutter's clang toolchain."""
  arch_subpath = 'mac-arm64' if platform.processor() == 'arm' else 'mac-x64'
  dsymutil_path = os.path.join('flutter', 'buildtools', arch_subpath, 'clang', 'bin', 'dsymutil')
  return buildroot_relative_path(dsymutil_path)


def get_framework_name(framework_dir):
  """Returns Foo given /path/to/Foo.framework."""
  return os.path.splitext(os.path.basename(framework_dir))[0]


def get_framework_dylib_path(framework_dir):
  """Returns /path/to/Foo.framework/Versions/A/Foo given /path/to/Foo.framework."""
  return os.path.join(framework_dir, 'Versions', 'A', get_framework_name(framework_dir))


def extract_dsym(binary_path, dsym_out_path):
  """Extracts a dSYM bundle from the specified Mach-O binary."""
  arch_dir = 'mac-arm64' if platform.processor() == 'arm' else 'mac-x64'
  dsymutil = buildroot_relative_path(
      os.path.join('flutter', 'buildtools', arch_dir, 'clang', 'bin', 'dsymutil')
  )
  subprocess.check_call([dsymutil, '-o', dsym_out_path, binary_path])


def lipo(input_binaries, output_binary):
  """Uses lipo to create a fat binary from a set of input binaries."""
  subprocess.check_call(['lipo'] + input_binaries + ['-create', '-output', output_binary])


def log_error(message):
  """Writes the message to stderr, followed by a newline."""
  print(message, file=sys.stderr)


def strip_binary(binary_path, unstripped_copy_path):
  """Makes a copy of an unstripped binary, then strips symbols from the binary."""
  assert_file(binary_path, 'binary to strip')
  shutil.copyfile(binary_path, unstripped_copy_path)
  subprocess.check_call(['strip', '-x', '-S', binary_path])


def write_codesign_config(output_path, paths):
  """Writes an Apple codesign configuration file containing the specified paths."""
  with open(output_path, mode='w', encoding='utf-8') as file:
    if paths:
      file.write('\n'.join(paths) + '\n')
