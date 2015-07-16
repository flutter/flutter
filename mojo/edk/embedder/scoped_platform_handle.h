// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_SCOPED_PLATFORM_HANDLE_H_
#define MOJO_EDK_EMBEDDER_SCOPED_PLATFORM_HANDLE_H_

#include "base/move.h"
#include "mojo/edk/embedder/platform_handle.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/c/system/macros.h"

namespace mojo {
namespace embedder {

class MOJO_SYSTEM_IMPL_EXPORT ScopedPlatformHandle {
  MOVE_ONLY_TYPE_WITH_MOVE_CONSTRUCTOR_FOR_CPP_03(ScopedPlatformHandle)

 public:
  ScopedPlatformHandle() {}
  explicit ScopedPlatformHandle(PlatformHandle handle) : handle_(handle) {}
  ~ScopedPlatformHandle() { handle_.CloseIfNecessary(); }

  // Move-only constructor and operator=.
  ScopedPlatformHandle(ScopedPlatformHandle&& other)
      : handle_(other.release()) {}

  ScopedPlatformHandle& operator=(ScopedPlatformHandle&& other) {
    if (this != &other)
      handle_ = other.release();
    return *this;
  }

  const PlatformHandle& get() const { return handle_; }

  void swap(ScopedPlatformHandle& other) {
    PlatformHandle temp = handle_;
    handle_ = other.handle_;
    other.handle_ = temp;
  }

  PlatformHandle release() MOJO_WARN_UNUSED_RESULT {
    PlatformHandle rv = handle_;
    handle_ = PlatformHandle();
    return rv;
  }

  void reset(PlatformHandle handle = PlatformHandle()) {
    handle_.CloseIfNecessary();
    handle_ = handle;
  }

  bool is_valid() const { return handle_.is_valid(); }

 private:
  PlatformHandle handle_;
};

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_SCOPED_PLATFORM_HANDLE_H_
