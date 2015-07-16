// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_DAEMON_H_
#define TOOLS_ANDROID_FORWARDER2_DAEMON_H_

#include <string>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"

namespace forwarder2 {

class Socket;

// Provides a way to spawn a daemon and communicate with it.
class Daemon {
 public:
  // Callback used by the daemon to shutdown properly. See pipe_notifier.h for
  // more details.
  typedef int (*GetExitNotifierFDCallback)();

  class ClientDelegate {
   public:
    virtual ~ClientDelegate() {}

    // Called after the daemon is ready to receive commands.
    virtual void OnDaemonReady(Socket* daemon_socket) = 0;
  };

  class ServerDelegate {
   public:
    virtual ~ServerDelegate() {}

    // Called after the daemon bound its Unix Domain Socket. This can be used to
    // setup signal handlers or perform global initialization.
    virtual void Init() = 0;

    virtual void OnClientConnected(scoped_ptr<Socket> client_socket) = 0;
  };

  // |identifier| should be a unique string identifier. It is used to
  // bind/connect the underlying Unix Domain Socket.
  // Note that this class does not take ownership of |client_delegate| and
  // |server_delegate|.
  Daemon(const std::string& log_file_path,
         const std::string& identifier,
         ClientDelegate* client_delegate,
         ServerDelegate* server_delegate,
         GetExitNotifierFDCallback get_exit_fd_callback);

  ~Daemon();

  // Returns whether the daemon was successfully spawned. Note that this does
  // not necessarily mean that the current process was forked in case the daemon
  // is already running.
  bool SpawnIfNeeded();

  // Kills the daemon and blocks until it exited. Returns whether it succeeded.
  bool Kill();

 private:
  const std::string log_file_path_;
  const std::string identifier_;
  ClientDelegate* const client_delegate_;
  ServerDelegate* const server_delegate_;
  const GetExitNotifierFDCallback get_exit_fd_callback_;

  DISALLOW_COPY_AND_ASSIGN(Daemon);
};

}  // namespace forwarder2

#endif  // TOOLS_ANDROID_FORWARDER2_DAEMON_H_
