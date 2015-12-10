// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_HANDLE_H_
#define MOJO_EDK_PLATFORM_PLATFORM_HANDLE_H_

namespace mojo {
namespace platform {

class ScopedPlatformHandle;

// A thin wrapper for an OS handle (just a file descriptor on POSIX) on any
// given platform.
struct PlatformHandle {
  PlatformHandle() : fd(-1) {}
  explicit PlatformHandle(int fd) : fd(fd) {}

  // Closes this handle if it's valid (and sets it to be invalid).
  void CloseIfNecessary();

  bool is_valid() const { return fd != -1; }

  // Creates a duplicate of this handle. On failure, or if this is an invalid
  // handle, this returns an invalid handle.
  ScopedPlatformHandle Duplicate() const;

  int fd;

  // Copy and assignment allowed.
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_HANDLE_H_
