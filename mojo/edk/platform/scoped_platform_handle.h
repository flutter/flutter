// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_SCOPED_PLATFORM_HANDLE_H_
#define MOJO_EDK_PLATFORM_SCOPED_PLATFORM_HANDLE_H_

#include "mojo/edk/platform/platform_handle.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

// Scoper for |PlatformHandle|s, which are just file descriptors.
class ScopedPlatformHandle {
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

  // Forwards to |PlatformHandle::Duplicate()|.
  ScopedPlatformHandle Duplicate() const { return handle_.Duplicate(); }

 private:
  PlatformHandle handle_;

  MOJO_MOVE_ONLY_TYPE(ScopedPlatformHandle);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_SCOPED_PLATFORM_HANDLE_H_
