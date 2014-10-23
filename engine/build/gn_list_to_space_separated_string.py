# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

# Converts its arguments to a single GN-style string, with each element
# quoted and separated by a space.
result = ""
for i in sys.argv[1:]:
    result += '"%s" ' % i
print result
