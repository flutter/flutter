#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Archives a set of dart packages"""

import ast
import optparse
import os
import sys
import zipfile

def IsPackagesPath(path):
  return path.startswith('packages/')

def IsMojomPath(path):
  return path.startswith('mojom/lib/')

def IsMojomDartFile(path):
  return path.endswith('.mojom.dart')

# Strips off mojom/lib/ returning module/interface.mojom.dart
def MojomDartRelativePath(path):
  assert IsMojomPath(path)
  assert IsMojomDartFile(path)
  return os.path.relpath(path, 'mojom/lib/')

# Line is a line from pubspec.yaml
def PackageName(line):
  assert line.startswith("name:")
  return line.split(":")[1].strip()

# pubspec_contents is the contents of a pubspec.yaml file, returns the package
# name.
def FindPackageName(pubspec_contents):
  for line in pubspec_contents.splitlines():
    if line.startswith("name:"):
      return PackageName(line)

# Returns true if path is in lib/.
def IsPathInLib(path):
  return path.startswith("lib/")

# Strips off lib/
def PackageRelativePath(path):
  return os.path.relpath(path, "lib/")

def HasPubspec(paths):
  for path in paths:
    _, filename = os.path.split(path)
    if 'pubspec.yaml' == filename:
      return True
  return False

def ReadPackageName(paths):
  for path in paths:
    _, filename = os.path.split(path)
    if 'pubspec.yaml' == filename:
      with open(path, 'r') as f:
          return FindPackageName(f.read())
  return None

def DoZip(inputs, zip_inputs, output, base_dir):
  files = []
  with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as outfile:
    # Loose file inputs (package source files)
    for f in inputs:
      file_name = os.path.relpath(f, base_dir)
      # We should never see a packages/ path here.
      assert not IsPackagesPath(file_name)
      files.append(file_name)
      outfile.write(f, file_name)

    if HasPubspec(inputs):
      # We are writing out a package, write lib/ into packages/<package_name>
      # so that package:<package_name>/ imports work within the package.
      package_name = ReadPackageName(inputs)
      assert not (package_name is None), "pubspec.yaml does not have a name"
      package_path = os.path.join("packages/", package_name)
      for f in inputs:
        file_name = os.path.relpath(f, base_dir)
        if IsPathInLib(file_name):
          output_name = os.path.join(package_path,
                                     PackageRelativePath(file_name))
          if output_name not in files:
            files.append(output_name)
            outfile.write(f, output_name)

    # zip file inputs (other packages)
    for zf_name in zip_inputs:
      with zipfile.ZipFile(zf_name, 'r') as zf:
        # Attempt to sniff package_name. If this fails, we are processing a zip
        # file with mojom.dart bindings or a packages/ dump.
        package_name = None
        try:
          with zf.open("pubspec.yaml") as pubspec_file:
            package_name = FindPackageName(pubspec_file.read())
        except KeyError:
          pass

        # Iterate over all files in zip file.
        for f in zf.namelist():

          # Copy any direct mojom dependencies into mojom/
          if IsMojomPath(f):
            mojom_dep_copy = os.path.join("lib/mojom/",
                                          MojomDartRelativePath(f))
            if mojom_dep_copy not in files:
              files.append(mojom_dep_copy)
              with zf.open(f) as zff:
                outfile.writestr(mojom_dep_copy, zff.read())

          # Rewrite output file name, if it isn't a packages/ path.
          output_name = None
          if not IsPackagesPath(f):
            if IsMojomDartFile(f) and IsMojomPath(f):
              # Place mojom/lib/*.mojom.dart files into packages/mojom/
              output_name = os.path.join("packages/mojom/",
                                         MojomDartRelativePath(f))
            else:
              # We are processing a package, it must have a package name.
              assert not (package_name is None)
              package_path = os.path.join("packages/", package_name)
              if IsPathInLib(f):
                output_name = os.path.join(package_path, PackageRelativePath(f))
          else:
            output_name = f;

          if output_name is None:
            continue

          if output_name not in files:
            files.append(output_name)
            with zf.open(f) as zff:
              outfile.writestr(output_name, zff.read())


def main():
  parser = optparse.OptionParser()

  parser.add_option('--inputs', help='List of files to archive.')
  parser.add_option('--link-inputs',
      help='List of files to archive. Symbolic links are resolved.')
  parser.add_option('--zip-inputs', help='List of zip files to re-archive.')
  parser.add_option('--output', help='Path to output archive.')
  parser.add_option('--base-dir',
                    help='If provided, the paths in the archive will be '
                    'relative to this directory', default='.')
  options, _ = parser.parse_args()

  inputs = []
  if (options.inputs):
    inputs = ast.literal_eval(options.inputs)
  zip_inputs = []
  if options.zip_inputs:
    zip_inputs = ast.literal_eval(options.zip_inputs)
  output = options.output
  base_dir = options.base_dir

  DoZip(inputs, zip_inputs, output, base_dir)

if __name__ == '__main__':
  sys.exit(main())
