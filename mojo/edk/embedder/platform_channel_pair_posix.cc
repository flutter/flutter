// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/platform_channel_pair.h"

#include <fcntl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/posix/global_descriptors.h"
#include "base/strings/string_number_conversions.h"
#include "build/build_config.h"
#include "mojo/edk/embedder/platform_handle.h"

namespace mojo {
namespace embedder {

namespace {

bool IsTargetDescriptorUsed(
    const base::FileHandleMappingVector& file_handle_mapping,
    int target_fd) {
  for (size_t i = 0; i < file_handle_mapping.size(); i++) {
    if (file_handle_mapping[i].second == target_fd)
      return true;
  }
  return false;
}

}  // namespace

PlatformChannelPair::PlatformChannelPair() {
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

  server_handle_.reset(PlatformHandle(fds[0]));
  DCHECK(server_handle_.is_valid());
  client_handle_.reset(PlatformHandle(fds[1]));
  DCHECK(client_handle_.is_valid());
}

// static
ScopedPlatformHandle PlatformChannelPair::PassClientHandleFromParentProcess(
    const base::CommandLine& command_line) {
  std::string client_fd_string =
      command_line.GetSwitchValueASCII(kMojoPlatformChannelHandleSwitch);
  int client_fd = -1;
  if (client_fd_string.empty() ||
      !base::StringToInt(client_fd_string, &client_fd) ||
      client_fd < base::GlobalDescriptors::kBaseDescriptor) {
    LOG(ERROR) << "Missing or invalid --" << kMojoPlatformChannelHandleSwitch;
    return ScopedPlatformHandle();
  }

  return ScopedPlatformHandle(PlatformHandle(client_fd));
}

void PlatformChannelPair::PrepareToPassClientHandleToChildProcess(
    base::CommandLine* command_line,
    base::FileHandleMappingVector* handle_passing_info) const {
  DCHECK(command_line);
  DCHECK(handle_passing_info);
  // This is an arbitrary sanity check. (Note that this guarantees that the loop
  // below will terminate sanely.)
  CHECK_LT(handle_passing_info->size(), 1000u);

  DCHECK(client_handle_.is_valid());

  // Find a suitable FD to map our client handle to in the child process.
  // This has quadratic time complexity in the size of |*handle_passing_info|,
  // but |*handle_passing_info| should be very small (usually/often empty).
  int target_fd = base::GlobalDescriptors::kBaseDescriptor;
  while (IsTargetDescriptorUsed(*handle_passing_info, target_fd))
    target_fd++;

  handle_passing_info->push_back(
      std::pair<int, int>(client_handle_.get().fd, target_fd));
  // Log a warning if the command line already has the switch, but "clobber" it
  // anyway, since it's reasonably likely that all the switches were just copied
  // from the parent.
  LOG_IF(WARNING, command_line->HasSwitch(kMojoPlatformChannelHandleSwitch))
      << "Child command line already has switch --"
      << kMojoPlatformChannelHandleSwitch << "="
      << command_line->GetSwitchValueASCII(kMojoPlatformChannelHandleSwitch);
  // (Any existing switch won't actually be removed from the command line, but
  // the last one appended takes precedence.)
  command_line->AppendSwitchASCII(kMojoPlatformChannelHandleSwitch,
                                  base::IntToString(target_fd));
}

}  // namespace embedder
}  // namespace mojo
