# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils: language = c++


cdef extern from "mojo/public/platform/native/system_thunks.h" nogil:
  cdef struct MojoSystemThunks:
    pass

cdef extern size_t MojoSetSystemThunks(const MojoSystemThunks* system_thunks)
