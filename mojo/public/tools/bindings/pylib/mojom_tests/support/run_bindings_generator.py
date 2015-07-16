# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os.path
from subprocess import check_call
import sys


def RunBindingsGenerator(out_dir, root_dir, mojom_file, extra_flags=None):
  out_dir = os.path.abspath(out_dir)
  root_dir = os.path.abspath(root_dir)
  mojom_file = os.path.abspath(mojom_file)

  # The mojom file should be under the root directory somewhere.
  assert mojom_file.startswith(root_dir)
  mojom_reldir = os.path.dirname(os.path.relpath(mojom_file, root_dir))

  # TODO(vtl): Abstract out the "main" functions, so that we can just import
  # the bindings generator (which would be more portable and easier to use in
  # tests).
  this_dir = os.path.dirname(os.path.abspath(__file__))
  # We're in src/mojo/public/tools/bindings/pylib/mojom_tests/support;
  # mojom_bindings_generator.py is in .../bindings.
  bindings_generator = os.path.join(this_dir, os.pardir, os.pardir, os.pardir,
                                    "mojom_bindings_generator.py")

  args = ["python", bindings_generator,
          "-o", os.path.join(out_dir, mojom_reldir)]
  if extra_flags:
    args.extend(extra_flags)
  args.append(mojom_file)

  check_call(args)


def main(argv):
  if len(argv) < 4:
    print "usage: %s out_dir root_dir mojom_file [extra_flags]" % argv[0]
    return 1

  RunBindingsGenerator(argv[1], argv[2], argv[3], extra_flags=argv[4:])
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
