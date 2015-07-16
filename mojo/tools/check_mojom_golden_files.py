#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os.path
import sys
from filecmp import dircmp
from shutil import rmtree
from tempfile import mkdtemp
from mopy.paths import Paths

paths = Paths()

sys.path.insert(0, os.path.join(paths.mojo_dir, "public", "tools", "bindings",
                                "pylib"))
from mojom_tests.support.find_files import FindFiles
from mojom_tests.support.run_bindings_generator import RunBindingsGenerator


def _ProcessDircmpResults(results, verbose=False):
  """Prints results of directory comparison and returns true if they are
  identical (note: the "left" directory should be the golden directory)."""
  rv = not (bool(results.left_only) or bool(results.right_only) or \
            bool(results.common_funny) or bool(results.funny_files) or \
            bool(results.diff_files))
  if verbose:
    for f in results.left_only:
      print "%s exists in golden directory but not in current output" % f
    for f in results.right_only:
      print "%s exists in current output but not in golden directory" % f
    for f in results.common_funny + results.funny_files:
      print "Unable to compare %s between golden directory and current output" \
          % f
    for f in results.diff_files:
      print "%s differs between golden directory and current output" % f
  for r in results.subdirs.values():
    # If we're being verbose, check subdirectories even if we know that there
    # are differences. Note that it's "... and rv" to avoid the short-circuit.
    if rv or verbose:
      rv = _ProcessDircmpResults(r, verbose=verbose) and rv
  return rv


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--generate_golden_files", action="store_true",
                      help=("generate golden files (does not obliterate "
                            "directory"))
  parser.add_argument("--keep_temp_dir", action="store_true",
                      help="don't delete the temporary directory")
  parser.add_argument("--verbose", action="store_true",
                      help="spew excess verbiage")
  parser.add_argument("golden_dir", metavar="GOLDEN_DIR",
                      help="directory with the golden files")
  args = parser.parse_args()

  if args.generate_golden_files:
    if os.path.exists(args.golden_dir):
      print "WARNING: golden directory %s already exists" % args.golden_dir
    out_dir = args.golden_dir
  else:
    if not os.path.exists(args.golden_dir):
      print "ERROR: golden directory %s does not exist" % args.golden_dir
      return 1
    out_dir = mkdtemp()
  if args.verbose:
    print "Generating files to %s ..." % out_dir

  mojom_files = FindFiles(paths.mojo_dir, "*.mojom")
  for mojom_file in mojom_files:
    if args.verbose:
      print "  Processing %s ..." % os.path.relpath(mojom_file, paths.mojo_dir)
    # TODO(vtl): This may wrong, since the path can be overridden in the .gyp
    # file.
    RunBindingsGenerator(out_dir, paths.mojo_dir, mojom_file,
                         ["-I", paths.src_root])

  if args.generate_golden_files:
    return 0

  identical = _ProcessDircmpResults(dircmp(args.golden_dir, out_dir, ignore=[]),
                                    verbose=args.verbose)

  if args.keep_temp_dir:
    if args.verbose:
      print "Not removing %s ..." % out_dir
  else:
    if args.verbose:
      print "Removing %s ..." % out_dir
    rmtree(out_dir)

  if not identical:
    print "FAILURE: current output differs from golden files"
    return 1

  print "SUCCESS: current output identical to golden files"
  return 0


if __name__ == '__main__':
  sys.exit(main())
