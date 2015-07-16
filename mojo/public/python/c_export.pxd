# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils: language = c++


# If the definition below is not present, cython-compiled modules do not expose
# an init method as they should.
cdef extern from "third_party/cython/python_export.h":
  pass
