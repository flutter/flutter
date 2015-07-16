# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils: language = c++

from libc.stdint cimport uintptr_t
from libcpp cimport bool

import mojo_system
import mojo_system_impl

cdef extern from "third_party/cython/python_export.h":
  pass

cdef extern from "base/memory/scoped_ptr.h":
  cdef cppclass scoped_ptr[T]:
    scoped_ptr(T*)

cdef extern from "mojo/edk/embedder/platform_support.h" \
    namespace "mojo::embedder" nogil:
  cdef cppclass PlatformSupport:
    pass

cdef extern from "mojo/edk/embedder/simple_platform_support.h" \
    namespace "mojo::embedder" nogil:
  cdef cppclass SimplePlatformSupport(PlatformSupport):
    SimplePlatformSupport()

cdef extern from "mojo/edk/embedder/embedder.h" nogil:
  cdef void InitCEmbedder "mojo::embedder::Init"(
      scoped_ptr[PlatformSupport] platform_support)

cdef extern from "mojo/public/platform/native/system_thunks.h" nogil:
  cdef struct MojoSystemThunks:
    pass
  cdef MojoSystemThunks MojoMakeSystemThunks()

cdef extern from "mojo/edk/embedder/test_embedder.h" nogil:
  cdef bool ShutdownCEmbedderForTest "mojo::embedder::test::Shutdown"()

def Init():
  InitCEmbedder(scoped_ptr[PlatformSupport](
      new SimplePlatformSupport()))
  cdef MojoSystemThunks thunks = MojoMakeSystemThunks()
  mojo_system.SetSystemThunks(<uintptr_t>(&thunks))
  mojo_system_impl.SetSystemThunks(<uintptr_t>(&thunks))

def ShutdownForTest():
  return ShutdownCEmbedderForTest()
