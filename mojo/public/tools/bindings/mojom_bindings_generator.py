#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The frontend for the Mojo bindings system."""


import argparse
import imp
import os
import pprint
import sys

# Disable lint check for finding modules:
# pylint: disable=F0401

def _GetDirAbove(dirname):
  """Returns the directory "above" this file containing |dirname| (which must
  also be "above" this file)."""
  path = os.path.abspath(__file__)
  while True:
    path, tail = os.path.split(path)
    assert tail
    if tail == dirname:
      return path

# Manually check for the command-line flag. (This isn't quite right, since it
# ignores, e.g., "--", but it's close enough.)
if "--use_bundled_pylibs" in sys.argv[1:]:
  sys.path.insert(0, os.path.join(_GetDirAbove("public"), "public/third_party"))

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "pylib"))

from mojom.error import Error
import mojom.fileutil as fileutil
from mojom.generate.data import OrderedModuleFromData
from mojom.parse.parser import Parse
from mojom.parse.translate import Translate


def LoadGenerators(generators_string):
  if not generators_string:
    return []  # No generators.

  script_dir = os.path.dirname(os.path.abspath(__file__))
  generators = []
  for generator_name in [s.strip() for s in generators_string.split(",")]:
    # "Built-in" generators:
    if generator_name.lower() == "c++":
      generator_name = os.path.join(script_dir, "generators",
                                    "mojom_cpp_generator.py")
    elif generator_name.lower() == "dart":
      generator_name = os.path.join(script_dir, "generators",
                                    "mojom_dart_generator.py")
    elif generator_name.lower() == "go":
      generator_name = os.path.join(script_dir, "generators",
                                    "mojom_go_generator.py")
    elif generator_name.lower() == "javascript":
      generator_name = os.path.join(script_dir, "generators",
                                    "mojom_js_generator.py")
    elif generator_name.lower() == "java":
      generator_name = os.path.join(script_dir, "generators",
                                    "mojom_java_generator.py")
    elif generator_name.lower() == "python":
      generator_name = os.path.join(script_dir, "generators",
                                    "mojom_python_generator.py")
    # Specified generator python module:
    elif generator_name.endswith(".py"):
      pass
    else:
      print "Unknown generator name %s" % generator_name
      sys.exit(1)
    generator_module = imp.load_source(os.path.basename(generator_name)[:-3],
                                       generator_name)
    generators.append(generator_module)
  return generators


def MakeImportStackMessage(imported_filename_stack):
  """Make a (human-readable) message listing a chain of imports. (Returned
  string begins with a newline (if nonempty) and does not end with one.)"""
  return ''.join(
      reversed(["\n  %s was imported by %s" % (a, b) for (a, b) in \
                    zip(imported_filename_stack[1:], imported_filename_stack)]))


def FindImportFile(dir_name, file_name, search_dirs):
  for search_dir in [dir_name] + search_dirs:
    path = os.path.join(search_dir, file_name)
    if os.path.isfile(path):
      return path
  return os.path.join(dir_name, file_name)

class MojomProcessor(object):
  def __init__(self, should_generate):
    self._should_generate = should_generate
    self._processed_files = {}
    self._parsed_files = {}

  def ProcessFile(self, args, remaining_args, generator_modules, filename):
    self._ParseFileAndImports(filename, args.import_directories, [])

    return self._GenerateModule(args, remaining_args, generator_modules,
        filename)

  def _GenerateModule(self, args, remaining_args, generator_modules, filename):
    # Return the already-generated module.
    if filename in self._processed_files:
      return self._processed_files[filename]
    tree = self._parsed_files[filename]

    dirname, name = os.path.split(filename)
    mojom = Translate(tree, name)
    if args.debug_print_intermediate:
      pprint.PrettyPrinter().pprint(mojom)

    # Process all our imports first and collect the module object for each.
    # We use these to generate proper type info.
    for import_data in mojom['imports']:
      import_filename = FindImportFile(dirname,
                                       import_data['filename'],
                                       args.import_directories)
      import_data['module'] = self._GenerateModule(
          args, remaining_args, generator_modules, import_filename)

    module = OrderedModuleFromData(mojom)

    # Set the path as relative to the source root.
    module.path = os.path.relpath(os.path.abspath(filename),
                                  os.path.abspath(args.depth))

    # Normalize to unix-style path here to keep the generators simpler.
    module.path = module.path.replace('\\', '/')

    if self._should_generate(filename):
      for generator_module in generator_modules:
        generator = generator_module.Generator(module, args.output_dir)
        filtered_args = []
        if hasattr(generator_module, 'GENERATOR_PREFIX'):
          prefix = '--' + generator_module.GENERATOR_PREFIX + '_'
          filtered_args = [arg for arg in remaining_args
                           if arg.startswith(prefix)]
        generator.GenerateFiles(filtered_args)

    # Save result.
    self._processed_files[filename] = module
    return module

  def _ParseFileAndImports(self, filename, import_directories,
      imported_filename_stack):
    # Ignore already-parsed files.
    if filename in self._parsed_files:
      return

    if filename in imported_filename_stack:
      print "%s: Error: Circular dependency" % filename + \
          MakeImportStackMessage(imported_filename_stack + [filename])
      sys.exit(1)

    try:
      with open(filename) as f:
        source = f.read()
    except IOError as e:
      print "%s: Error: %s" % (e.filename, e.strerror) + \
          MakeImportStackMessage(imported_filename_stack + [filename])
      sys.exit(1)

    try:
      tree = Parse(source, filename)
    except Error as e:
      full_stack = imported_filename_stack + [filename]
      print str(e) + MakeImportStackMessage(full_stack)
      sys.exit(1)

    dirname = os.path.split(filename)[0]
    for imp_entry in tree.import_list:
      import_filename = FindImportFile(dirname,
          imp_entry.import_filename, import_directories)
      self._ParseFileAndImports(import_filename, import_directories,
          imported_filename_stack + [filename])

    self._parsed_files[filename] = tree


def main():
  parser = argparse.ArgumentParser(
      description="Generate bindings from mojom files.")
  parser.add_argument("filename", nargs="+",
                      help="mojom input file")
  parser.add_argument("-d", "--depth", dest="depth", default=".",
                      help="depth from source root")
  parser.add_argument("-o", "--output_dir", dest="output_dir", default=".",
                      help="output directory for generated files")
  parser.add_argument("-g", "--generators", dest="generators_string",
                      metavar="GENERATORS",
                      default="c++,dart,go,javascript,java,python",
                      help="comma-separated list of generators")
  parser.add_argument("--debug_print_intermediate", action="store_true",
                      help="print the intermediate representation")
  parser.add_argument("-I", dest="import_directories", action="append",
                      metavar="directory", default=[],
                      help="add a directory to be searched for import files")
  parser.add_argument("--use_bundled_pylibs", action="store_true",
                      help="use Python modules bundled in the SDK")
  (args, remaining_args) = parser.parse_known_args()

  generator_modules = LoadGenerators(args.generators_string)

  fileutil.EnsureDirectoryExists(args.output_dir)

  processor = MojomProcessor(lambda filename: filename in args.filename)
  for filename in args.filename:
    processor.ProcessFile(args, remaining_args, generator_modules, filename)

  return 0


if __name__ == "__main__":
  sys.exit(main())
