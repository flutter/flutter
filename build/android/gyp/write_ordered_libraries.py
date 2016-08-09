#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes dependency ordered list of native libraries.

The list excludes any Android system libraries, as those are not bundled with
the APK.

This list of libraries is used for several steps of building an APK.
In the component build, the --input-libraries only needs to be the top-level
library (i.e. libcontent_shell_content_view). This will then use readelf to
inspect the shared libraries and determine the full list of (non-system)
libraries that should be included in the APK.
"""

# TODO(cjhopman): See if we can expose the list of library dependencies from
# gyp, rather than calculating it ourselves.
# http://crbug.com/225558

import optparse
import os
import re
import sys

from util import build_utils

_readelf = None
_library_dirs = None

_library_re = re.compile(
    '.*NEEDED.*Shared library: \[(?P<library_name>.+)\]')


def SetReadelfPath(path):
  global _readelf
  _readelf = path


def SetLibraryDirs(dirs):
  global _library_dirs
  _library_dirs = dirs


def FullLibraryPath(library_name):
  assert _library_dirs is not None
  for directory in _library_dirs:
    path = '%s/%s' % (directory, library_name)
    if os.path.exists(path):
      return path
  return library_name


def IsSystemLibrary(library_name):
  # If the library doesn't exist in the libraries directory, assume that it is
  # an Android system library.
  return not os.path.exists(FullLibraryPath(library_name))


def CallReadElf(library_or_executable):
  assert _readelf is not None
  readelf_cmd = [_readelf,
                 '-d',
                 FullLibraryPath(library_or_executable)]
  return build_utils.CheckOutput(readelf_cmd)


def GetDependencies(library_or_executable):
  elf = CallReadElf(library_or_executable)
  return set(_library_re.findall(elf))


def GetNonSystemDependencies(library_name):
  all_deps = GetDependencies(library_name)
  return set((lib for lib in all_deps if not IsSystemLibrary(lib)))


def GetSortedTransitiveDependencies(libraries):
  """Returns all transitive library dependencies in dependency order."""
  return build_utils.GetSortedTransitiveDependencies(
      libraries, GetNonSystemDependencies)


def GetSortedTransitiveDependenciesForBinaries(binaries):
  if binaries[0].endswith('.so'):
    libraries = [os.path.basename(lib) for lib in binaries]
  else:
    assert len(binaries) == 1
    all_deps = GetDependencies(binaries[0])
    libraries = [lib for lib in all_deps if not IsSystemLibrary(lib)]

  return GetSortedTransitiveDependencies(libraries)


def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--input-libraries',
      help='A list of top-level input libraries.')
  parser.add_option('--libraries-dir',
      help='The directory which contains shared libraries.')
  parser.add_option('--readelf', help='Path to the readelf binary.')
  parser.add_option('--output', help='Path to the generated .json file.')
  parser.add_option('--stamp', help='Path to touch on success.')

  options, _ = parser.parse_args()

  SetReadelfPath(options.readelf)
  SetLibraryDirs(options.libraries_dir.split(','))

  libraries = build_utils.ParseGypList(options.input_libraries)
  if len(libraries):
    libraries = GetSortedTransitiveDependenciesForBinaries(libraries)

  # Convert to "base" library names: e.g. libfoo.so -> foo
  java_libraries_list = (
      '{%s}' % ','.join(['"%s"' % s[3:-3] for s in libraries]))

  out_json = {
      'libraries': libraries,
      'lib_paths': [FullLibraryPath(l) for l in libraries],
      'java_libraries_list': java_libraries_list
      }
  build_utils.WriteJson(
      out_json,
      options.output,
      only_if_changed=True)

  if options.stamp:
    build_utils.Touch(options.stamp)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        libraries + build_utils.GetPythonDependencies())


if __name__ == '__main__':
  sys.exit(main())


