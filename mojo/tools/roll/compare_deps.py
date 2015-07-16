#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import re
import sys
import utils

if len(sys.argv) != 2:
  print "usage: compare_deps.py <chromium DEPS file>"
  sys.exit(1)

chromium_deps_path = sys.argv[1]
mojo_deps_path = os.path.join(utils.mojo_root_dir, "DEPS")

chromium_deps = ""

with open(chromium_deps_path) as chromium_deps_file:
  chromium_deps = chromium_deps_file.read()

found_mismatch = False

with open(mojo_deps_path) as mojo_deps_file:
  for line in mojo_deps_file:
    m = re.search("[0-9a-f]{32}", line)
    if m:
      git_hash = m.group(0)
      if not git_hash in chromium_deps:
        print "%s in mojo DEPS but not in chromium DEPS" % git_hash
        print "line %s" % line.strip()
        found_mismatch = True

if found_mismatch:
  sys.exit(1)
