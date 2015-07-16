// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_CHANNEL_PAIR_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_CHANNEL_PAIR_H_

#include "base/memory/scoped_ptr.h"
#include "base/process/launch.h"
#include "build/build_config.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace base {
class CommandLine;
}

namespace mojo {
namespace embedder {

// It would be nice to refactor base/process/launch.h to have a more platform-
// independent way of representing handles that are passed to child processes.
#if defined(OS_WIN)
using HandlePassingInformation = base::HandlesToInheritVector;
#elif defined(OS_POSIX)
using HandlePassingInformation = base::FileHandleMappingVector;
#else
#error "Unsupported."
#endif

// This is used to create a pair of |PlatformHandle|s that are connected by a
// suitable (platform-specific) bidirectional "pipe" (e.g., socket on POSIX,
// named pipe on Windows). The resulting handles can then be used in the same
// process (e.g., in tests) or between processes. (The "server" handle is the
// one that will be used in the process that created the pair, whereas the
// "client" handle is the one that will be used in a different process.)
//
// This class provides facilities for passing the client handle to a child
// process. The parent should call |PrepareToPassClientHandlelToChildProcess()|
// to get the data needed to do this, spawn the child using that data, and then
// call |ChildProcessLaunched()|. Note that on Windows this facility (will) only
// work on Vista and later (TODO(vtl)).
//
// Note: |PlatformChannelPair()|, |PassClientHandleFromParentProcess()| and
// |PrepareToPassClientHandleToChildProcess()| have platform-specific
// implementations.
//
// Note: On POSIX platforms, to write to the "pipe", use
// |PlatformChannel{Write,Writev}()| (from platform_channel_utils_posix.h)
// instead of |write()|, |writev()|, etc. Otherwise, you have to worry about
// platform differences in suppressing |SIGPIPE|.
class MOJO_SYSTEM_IMPL_EXPORT PlatformChannelPair {
 public:
  PlatformChannelPair();
  ~PlatformChannelPair();

  ScopedPlatformHandle PassServerHandle();

  // For in-process use (e.g., in tests or to pass over another channel).
  ScopedPlatformHandle PassClientHandle();

  // To be called in the child process, after the parent process called
  // |PrepareToPassClientHandleToChildProcess()| and launched the child (using
  // the provided data), to create a client handle connected to the server
  // handle (in the parent process).
  static ScopedPlatformHandle PassClientHandleFromParentProcess(
      const base::CommandLine& command_line);

  // Prepares to pass the client channel to a new child process, to be launched
  // using |LaunchProcess()| (from base/launch.h). Modifies |*command_line| and
  // |*handle_passing_info| as needed.
  // Note: For Windows, this method only works on Vista and later.
  void PrepareToPassClientHandleToChildProcess(
      base::CommandLine* command_line,
      HandlePassingInformation* handle_passing_info) const;

  // To be called once the child process has been successfully launched, to do
  // any cleanup necessary.
  void ChildProcessLaunched();

 private:
  static const char kMojoPlatformChannelHandleSwitch[];

  ScopedPlatformHandle server_handle_;
  ScopedPlatformHandle client_handle_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(PlatformChannelPair);
};

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_CHANNEL_PAIR_H_
