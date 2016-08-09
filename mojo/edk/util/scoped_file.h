// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_UTIL_SCOPED_FILE_H_
#define MOJO_EDK_UTIL_SCOPED_FILE_H_

#include <stdio.h>

#include <memory>

namespace mojo {
namespace util {
namespace internal {

// Functor for |ScopedFILE| (below).
struct ScopedFILECloser {
  inline void operator()(FILE* x) const {
    if (x)
      fclose(x);
  }
};

}  // namespace internal

// Automatically closes |FILE*|s.
using ScopedFILE = std::unique_ptr<FILE, internal::ScopedFILECloser>;

}  // namespace util
}  // namespace mojo

#endif  // MOJO_EDK_UTIL_SCOPED_FILE_H_
