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


def assert_valid_codesign_config(framework_dir, zip_contents, entitlements, without_entitlements):
  """Exits with exit code 1 if the codesign configuration contents are incorrect.
  All Mach-O binaries found within zip_contents exactly must be listed in
  either entitlements or without_entitlements."""
  if _contains_duplicates(entitlements):
    log_error('ERROR: duplicate value(s) found in entitlements.txt')
    sys.exit(os.EX_DATAERR)

  if _contains_duplicates(without_entitlements):
    log_error('ERROR: duplicate value(s) found in without_entitlements.txt')
    sys.exit(os.EX_DATAERR)

  if _contains_duplicates(entitlements + without_entitlements):
    log_error('ERROR: value(s) found in both entitlements and without_entitlements.txt')
    sys.exit(os.EX_DATAERR)

  binaries = set()
  for zip_content_path in zip_contents:
    # If file, check if Mach-O binary.
    if _is_macho_binary(os.path.join(framework_dir, zip_content_path)):
      binaries.add(zip_content_path)
    # If directory, check transitive closure of files for Mach-O binaries.
    for root, _, files in os.walk(os.path.join(framework_dir, zip_content_path)):
      for file in [os.path.join(root, f) for f in files]:
        if _is_macho_binary(file):
          binaries.add(os.path.relpath(file, framework_dir))

  # Verify that all Mach-O binaries are listed in either entitlements or without_entitlements.
  listed_binaries = set(entitlements + without_entitlements)
  if listed_binaries != binaries:
    log_error(
        'ERROR: binaries listed in entitlements.txt and without_entitlements.txt do not '
        'match the set of binaries in the files to be zipped'
    )
    log_error('Binaries found in files to be zipped:')
    for file in sorted(binaries):
      log_error('    ' + file)

    not_listed = sorted(binaries - listed_binaries)
    if not_listed:
      log_error('Binaries NOT LISTED in entitlements.txt/without_entitlements.txt:')
      for file in not_listed:
        log_error('    ' + file)

    not_found = sorted(listed_binaries - binaries)
    if not_found:
      log_error('Binaries listed in entitlements.txt/without_entitlements.txt but NOT FOUND:')
      for file in not_found:
        log_error('    ' + file)
    sys.exit(os.EX_NOINPUT)


def _contains_duplicates(strings):
  """Returns true if the list of strings contains a duplicate value."""
  return len(strings) != len(set(strings))


def _is_macho_binary(filename):
  """Returns True if the specified path is file and a Mach-O binary."""
  if not os.path.isfile(filename):
    return False

  with open(filename, 'rb') as file:
    chunk = file.read(4)
    return chunk in (
        b'\xca\xfe\xba\xbe',  # Mach-O Universal Big Endian
        b'\xce\xfa\xed\xfe',  # Mach-O Little Endian (32-bit)
        b'\xcf\xfa\xed\xfe',  # Mach-O Little Endian (64-bit)
        b'\xfe\xed\xfa\xce',  # Mach-O Big Endian (32-bit)
        b'\xfe\xed\xfa\xcf',  # Mach-O Big Endian (64-bit)
    )


def buildroot_relative_path(path):
  """Returns the absolute path to the specified buildroot-relative path."""
  buildroot_dir = os.path.abspath(os.path.join(os.path.realpath(__file__), '..', '..', '..', '..'))
  return os.path.join(buildroot_dir, path)


def copy_binary(source_path, destination_path):
  """Copies a binary, preserving POSIX permissions."""
  assert_file(source_path, 'file to copy')
  shutil.copy2(source_path, destination_path)


def copy_tree(source_path, destination_path, symlinks=False):
  """Performs a recursive copy of a directory. If the destination path is
  present, it is deleted first."""
  assert_directory(source_path, 'directory to copy')
  shutil.rmtree(destination_path, True)
  shutil.copytree(source_path, destination_path, symlinks=symlinks)


def create_zip(cwd, zip_filename, paths):
  """Creates a zip archive in cwd, containing a set of cwd-relative files.

  In order to preserve the correct internal structure of macOS frameworks,
  symlinks are preserved.
  """
  subprocess.check_call(['zip', '-r', '-y', zip_filename] + paths, cwd=cwd)


def _dsymutil_path():
  """Returns the path to dsymutil within Flutter's clang toolchain."""
  arch_subpath = 'mac-arm64' if platform.processor() == 'arm' else 'mac-x64'
  dsymutil_path = os.path.join('flutter', 'buildtools', arch_subpath, 'clang', 'bin', 'dsymutil')
  return buildroot_relative_path(dsymutil_path)


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
