#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys
import hashlib

in_file = sys.argv[1]
out_file = sys.argv[2]

out_dir = os.path.dirname(out_file)

data = None
with open(in_file, "rb") as f:
    data = f.read()

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

sha1hash = hashlib.sha1(data).hexdigest()

with open(out_file, "w") as f:
    f.write('#include "services/icu/constants.h"\n')
    f.write("namespace mojo {\n")
    f.write("namespace icu {\n")
    f.write("const size_t kDataSize = %s;\n" % len(data))
    f.write("const char kDataHash[] = \"%s\";\n" % sha1hash)
    f.write("\n}  // namespace icu\n")
    f.write("\n}  // namespace mojo\n")
