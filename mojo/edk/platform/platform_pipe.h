// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_PLATFORM_PIPE_H_
#define MOJO_EDK_PLATFORM_PLATFORM_PIPE_H_

#include "mojo/edk/platform/scoped_platform_handle.h"

namespace mojo {
namespace platform {

// A helper class for creating a pair of |PlatformHandle|s that are connected by
// a suitable (platform-specific) bidirectional "pipe" (e.g., Unix domain
// socket). The resulting handles can then be used in the same process (e.g., in
// tests) or between processes.
//
// Note: On POSIX platforms, to write to the "pipe", use
// |PlatformPipe{Write,Writev}()| (from platform_pipe_utils_posix.h) instead of
// |write()|, |writev()|, etc. Otherwise, you have to worry about platform
// differences in suppressing |SIGPIPE|.
class PlatformPipe {
 public:
  PlatformPipe();
  ~PlatformPipe();

  ScopedPlatformHandle handle0;
  ScopedPlatformHandle handle1;
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_PLATFORM_PIPE_H_
