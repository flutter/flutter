// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/daemon.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <string>

#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/posix/eintr_wrapper.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/stringprintf.h"
#include "tools/android/forwarder2/common.h"
#include "tools/android/forwarder2/socket.h"

namespace forwarder2 {
namespace {

const int kBufferSize = 256;

// Timeout constant used for polling when connecting to the daemon's Unix Domain
// Socket and also when waiting for its death when it is killed.
const int kNumTries = 100;
const int kIdleTimeMSec = 20;

void InitLoggingForDaemon(const std::string& log_file) {
  logging::LoggingSettings settings;
  settings.logging_dest =
      log_file.empty() ?
      logging::LOG_TO_SYSTEM_DEBUG_LOG : logging::LOG_TO_FILE;
  settings.log_file = log_file.c_str();
  settings.lock_log = logging::DONT_LOCK_LOG_FILE;
  CHECK(logging::InitLogging(settings));
}

bool RunServerAcceptLoop(const std::string& welcome_message,
                         Socket* server_socket,
                         Daemon::ServerDelegate* server_delegate) {
  bool failed = false;
  for (;;) {
    scoped_ptr<Socket> client_socket(new Socket());
    if (!server_socket->Accept(client_socket.get())) {
      if (server_socket->DidReceiveEvent())
        break;
      PError("Accept()");
      failed = true;
      break;
    }
    if (!client_socket->Write(welcome_message.c_str(),
                              welcome_message.length() + 1)) {
      PError("Write()");
      failed = true;
      continue;
    }
    server_delegate->OnClientConnected(client_socket.Pass());
  }
  return !failed;
}

void SigChildHandler(int signal_number) {
  DCHECK_EQ(signal_number, SIGCHLD);
  int status;
  pid_t child_pid = waitpid(-1 /* any child */, &status, WNOHANG);
  if (child_pid < 0) {
    PError("waitpid");
    return;
  }
  if (child_pid == 0)
    return;
  if (WIFEXITED(status) && WEXITSTATUS(status) == 0)
    return;
  // Avoid using StringAppendF() since it's unsafe in a signal handler due to
  // its use of LOG().
  FixedSizeStringBuilder<256> string_builder;
  string_builder.Append("Daemon (pid=%d) died unexpectedly with ", child_pid);
  if (WIFEXITED(status))
    string_builder.Append("status %d.", WEXITSTATUS(status));
  else if (WIFSIGNALED(status))
    string_builder.Append("signal %d.", WTERMSIG(status));
  else
    string_builder.Append("unknown reason.");
  SIGNAL_SAFE_LOG(ERROR, string_builder.buffer());
}

scoped_ptr<Socket> ConnectToUnixDomainSocket(
    const std::string& socket_name,
    int tries_count,
    int idle_time_msec,
    const std::string& expected_welcome_message) {
  for (int i = 0; i < tries_count; ++i) {
    scoped_ptr<Socket> socket(new Socket());
    if (!socket->ConnectUnix(socket_name)) {
      if (idle_time_msec)
        usleep(idle_time_msec * 1000);
      continue;
    }
    char buf[kBufferSize];
    DCHECK(expected_welcome_message.length() + 1 <= sizeof(buf));
    memset(buf, 0, sizeof(buf));
    if (socket->Read(buf, expected_welcome_message.length() + 1) < 0) {
      perror("read");
      continue;
    }
    if (expected_welcome_message != buf) {
      LOG(ERROR) << "Unexpected message read from daemon: " << buf;
      break;
    }
    return socket.Pass();
  }
  return scoped_ptr<Socket>();
}

}  // namespace

Daemon::Daemon(const std::string& log_file_path,
               const std::string& identifier,
               ClientDelegate* client_delegate,
               ServerDelegate* server_delegate,
               GetExitNotifierFDCallback get_exit_fd_callback)
  : log_file_path_(log_file_path),
    identifier_(identifier),
    client_delegate_(client_delegate),
    server_delegate_(server_delegate),
    get_exit_fd_callback_(get_exit_fd_callback) {
  DCHECK(client_delegate_);
  DCHECK(server_delegate_);
  DCHECK(get_exit_fd_callback_);
}

Daemon::~Daemon() {}

bool Daemon::SpawnIfNeeded() {
  const int kSingleTry = 1;
  const int kNoIdleTime = 0;
  scoped_ptr<Socket> client_socket = ConnectToUnixDomainSocket(
      identifier_, kSingleTry, kNoIdleTime, identifier_);
  if (!client_socket) {
    switch (fork()) {
      case -1:
        PError("fork()");
        return false;
      // Child.
      case 0: {
        if (setsid() < 0) {  // Detach the child process from its parent.
          PError("setsid()");
          exit(1);
        }
        InitLoggingForDaemon(log_file_path_);
        CloseFD(STDIN_FILENO);
        CloseFD(STDOUT_FILENO);
        CloseFD(STDERR_FILENO);
        const int null_fd = open("/dev/null", O_RDWR);
        CHECK_EQ(null_fd, STDIN_FILENO);
        CHECK_EQ(dup(null_fd), STDOUT_FILENO);
        CHECK_EQ(dup(null_fd), STDERR_FILENO);
        Socket command_socket;
        if (!command_socket.BindUnix(identifier_)) {
          scoped_ptr<Socket> client_socket = ConnectToUnixDomainSocket(
              identifier_, kSingleTry, kNoIdleTime, identifier_);
          if (client_socket.get()) {
            // The daemon was spawned by a concurrent process.
            exit(0);
          }
          PError("bind()");
          exit(1);
        }
        server_delegate_->Init();
        command_socket.AddEventFd(get_exit_fd_callback_());
        return RunServerAcceptLoop(
            identifier_, &command_socket, server_delegate_);
      }
      default:
        break;
    }
  }
  // Parent.
  // Install the custom SIGCHLD handler.
  sigset_t blocked_signals_set;
  if (sigprocmask(0 /* first arg ignored */, NULL, &blocked_signals_set) < 0) {
    PError("sigprocmask()");
    return false;
  }
  struct sigaction old_action;
  struct sigaction new_action;
  memset(&new_action, 0, sizeof(new_action));
  new_action.sa_handler = SigChildHandler;
  new_action.sa_flags = SA_NOCLDSTOP;
  sigemptyset(&new_action.sa_mask);
  if (sigaction(SIGCHLD, &new_action, &old_action) < 0) {
    PError("sigaction()");
    return false;
  }
  // Connect to the daemon's Unix Domain Socket.
  bool failed = false;
  if (!client_socket) {
    client_socket = ConnectToUnixDomainSocket(
        identifier_, kNumTries, kIdleTimeMSec, identifier_);
    if (!client_socket) {
      LOG(ERROR) << "Could not connect to daemon's Unix Daemon socket";
      failed = true;
    }
  }
  if (!failed)
    client_delegate_->OnDaemonReady(client_socket.get());
  // Restore the previous signal action for SIGCHLD.
  if (sigaction(SIGCHLD, &old_action, NULL) < 0) {
    PError("sigaction");
    failed = true;
  }
  return !failed;
}

bool Daemon::Kill() {
  pid_t daemon_pid = Socket::GetUnixDomainSocketProcessOwner(identifier_);
  if (daemon_pid < 0) {
    LOG(ERROR) << "No forwarder daemon seems to be running";
    return true;
  }
  if (kill(daemon_pid, SIGTERM) < 0) {
    if (errno == ESRCH /* invalid PID */) {
      // The daemon exited for some reason (e.g. kill by a process other than
      // us) right before the call to kill() above.
      LOG(ERROR) << "Could not kill daemon with PID " << daemon_pid;
      return true;
    }
    PError("kill");
    return false;
  }
  for (int i = 0; i < kNumTries; ++i) {
    const pid_t previous_pid = daemon_pid;
    daemon_pid = Socket::GetUnixDomainSocketProcessOwner(identifier_);
    if (daemon_pid < 0)
      return true;
    // Since we are polling we might not see the 'daemon exited' event if
    // another daemon was spawned during our idle period.
    if (daemon_pid != previous_pid) {
      LOG(WARNING) << "Daemon (pid=" << previous_pid
                   << ") was successfully killed but a new daemon (pid="
                   << daemon_pid << ") seems to be running now.";
      return true;
    }
    usleep(kIdleTimeMSec * 1000);
  }
  LOG(ERROR) << "Timed out while killing daemon. "
                "It might still be tearing down.";
  return false;
}

}  // namespace forwarder2
