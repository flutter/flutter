// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the class declared in
// //mojo/edk/platform/platform_pipe.h.

#include "mojo/edk/platform/platform_pipe.h"

#include <fcntl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/logging.h"
#include "build/build_config.h"
#include "mojo/edk/platform/platform_handle.h"

namespace mojo {
namespace platform {

PlatformPipe::PlatformPipe() {
  // Create the Unix domain socket and set the ends to nonblocking.
  int fds[2];
  // TODO(vtl): Maybe fail gracefully if |socketpair()| fails.
  PCHECK(socketpair(AF_UNIX, SOCK_STREAM, 0, fds) == 0);
  PCHECK(fcntl(fds[0], F_SETFL, O_NONBLOCK) == 0);
  PCHECK(fcntl(fds[1], F_SETFL, O_NONBLOCK) == 0);

#if defined(OS_MACOSX)
  // This turns off |SIGPIPE| when writing to a closed socket (causing it to
  // fail with |EPIPE| instead). On Linux, we have to use |send...()| with
  // |MSG_NOSIGNAL| -- which is not supported on Mac -- instead.
  int no_sigpipe = 1;
  PCHECK(setsockopt(fds[0], SOL_SOCKET, SO_NOSIGPIPE, &no_sigpipe,
                    sizeof(no_sigpipe)) == 0);
  PCHECK(setsockopt(fds[1], SOL_SOCKET, SO_NOSIGPIPE, &no_sigpipe,
                    sizeof(no_sigpipe)) == 0);
#endif  // defined(OS_MACOSX)

  handle0.reset(PlatformHandle(fds[0]));
  DCHECK(handle0.is_valid());
  handle1.reset(PlatformHandle(fds[1]));
  DCHECK(handle1.is_valid());
}

PlatformPipe::~PlatformPipe() {}

}  // namespace platform
}  // namespace mojo
