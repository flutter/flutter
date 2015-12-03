// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_HANDLE_H_
#define MOJO_EDK_PLATFORM_PLATFORM_HANDLE_H_

namespace mojo {
namespace platform {

// A |PlatformHandle| is just a file descriptor on POSIX.
struct PlatformHandle {
  PlatformHandle() : fd(-1) {}
  explicit PlatformHandle(int fd) : fd(fd) {}

  void CloseIfNecessary();

  bool is_valid() const { return fd != -1; }

  int fd;
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_HANDLE_H_
