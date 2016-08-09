# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A wrapper to run yasm.

Its main job is to provide a Python wrapper for GN integration, and to write
the makefile-style output yasm generates in stdout to a .d file for dependency
management of .inc files.

Run with:
  python run_yasm.py <yasm_binary_path> <all other yasm args>

Note that <all other yasm args> must include an explicit output file (-o). This
script will append a ".d" to this and write the dependencies there. This script
will add "-M" to cause yasm to write the deps to stdout, so you don't need to
specify that.
"""

import argparse
import sys
import subprocess

# Extract the output file name from the yasm command line so we can generate a
# .d file with the same base name.
parser = argparse.ArgumentParser()
parser.add_argument("-o", dest="objfile")
options, _ = parser.parse_known_args()

objfile = options.objfile
depfile = objfile + '.d'

# Assemble.
result_code = subprocess.call(sys.argv[1:])
if result_code != 0:
  sys.exit(result_code)

# Now generate the .d file listing the dependencies. The -M option makes yasm
# write the Makefile-style dependencies to stdout, but it seems that inhibits
# generating any compiled output so we need to do this in a separate pass.
# However, outputting deps seems faster than actually assembling, and yasm is
# so fast anyway this is not a big deal.
#
# This guarantees proper dependency management for assembly files. Otherwise,
# we would have to require people to manually specify the .inc files they
# depend on in the build file, which will surely be wrong or out-of-date in
# some cases.
deps = subprocess.check_output(sys.argv[1:] + ['-M'])
with open(depfile, "wb") as f:
  f.write(deps)

