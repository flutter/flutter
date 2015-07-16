// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <signal.h>
#include <stdlib.h>

#include <iostream>
#include <string>

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/strings/string_piece.h"
#include "base/strings/stringprintf.h"
#include "base/threading/thread.h"
#include "tools/android/forwarder2/common.h"
#include "tools/android/forwarder2/daemon.h"
#include "tools/android/forwarder2/device_controller.h"
#include "tools/android/forwarder2/pipe_notifier.h"

namespace forwarder2 {
namespace {

// Leaky global instance, accessed from the signal handler.
forwarder2::PipeNotifier* g_notifier = NULL;

const int kBufSize = 256;

const char kUnixDomainSocketPath[] = "chrome_device_forwarder";
const char kDaemonIdentifier[] = "chrome_device_forwarder_daemon";

void KillHandler(int /* unused */) {
  CHECK(g_notifier);
  if (!g_notifier->Notify())
    exit(1);
}

// Lets the daemon fetch the exit notifier file descriptor.
int GetExitNotifierFD() {
  DCHECK(g_notifier);
  return g_notifier->receiver_fd();
}

class ServerDelegate : public Daemon::ServerDelegate {
 public:
  ServerDelegate() : initialized_(false) {}

  ~ServerDelegate() override {
    if (!controller_thread_.get())
      return;
    // The DeviceController instance, if any, is constructed on the controller
    // thread. Make sure that it gets deleted on that same thread. Note that
    // DeleteSoon() is not used here since it would imply reading |controller_|
    // from the main thread while it's set on the internal thread.
    controller_thread_->message_loop_proxy()->PostTask(
        FROM_HERE,
        base::Bind(&ServerDelegate::DeleteControllerOnInternalThread,
                   base::Unretained(this)));
  }

  void DeleteControllerOnInternalThread() {
    DCHECK(
        controller_thread_->message_loop_proxy()->RunsTasksOnCurrentThread());
    controller_.reset();
  }

  // Daemon::ServerDelegate:
  void Init() override {
    DCHECK(!g_notifier);
    g_notifier = new forwarder2::PipeNotifier();
    signal(SIGTERM, KillHandler);
    signal(SIGINT, KillHandler);
    controller_thread_.reset(new base::Thread("controller_thread"));
    controller_thread_->Start();
  }

  void OnClientConnected(scoped_ptr<Socket> client_socket) override {
    if (initialized_) {
      client_socket->WriteString("OK");
      return;
    }
    controller_thread_->message_loop()->PostTask(
        FROM_HERE,
        base::Bind(&ServerDelegate::StartController, base::Unretained(this),
                   GetExitNotifierFD(), base::Passed(&client_socket)));
    initialized_ = true;
  }

 private:
  void StartController(int exit_notifier_fd, scoped_ptr<Socket> client_socket) {
    DCHECK(!controller_.get());
    scoped_ptr<DeviceController> controller(
        DeviceController::Create(kUnixDomainSocketPath, exit_notifier_fd));
    if (!controller.get()) {
      client_socket->WriteString(
          base::StringPrintf("ERROR: Could not initialize device controller "
                             "with ADB socket path: %s",
                             kUnixDomainSocketPath));
      return;
    }
    controller_.swap(controller);
    controller_->Start();
    client_socket->WriteString("OK");
    client_socket->Close();
  }

  scoped_ptr<DeviceController> controller_;
  scoped_ptr<base::Thread> controller_thread_;
  bool initialized_;
};

class ClientDelegate : public Daemon::ClientDelegate {
 public:
  ClientDelegate() : has_failed_(false) {}

  bool has_failed() const { return has_failed_; }

  // Daemon::ClientDelegate:
  void OnDaemonReady(Socket* daemon_socket) override {
    char buf[kBufSize];
    const int bytes_read = daemon_socket->Read(
        buf, sizeof(buf) - 1 /* leave space for null terminator */);
    CHECK_GT(bytes_read, 0);
    DCHECK(static_cast<unsigned int>(bytes_read) < sizeof(buf));
    buf[bytes_read] = 0;
    base::StringPiece msg(buf, bytes_read);
    if (msg.starts_with("ERROR")) {
      LOG(ERROR) << msg;
      has_failed_ = true;
      return;
    }
  }

 private:
  bool has_failed_;
};

int RunDeviceForwarder(int argc, char** argv) {
  base::CommandLine::Init(argc, argv);  // Needed by logging.
  const bool kill_server =
      base::CommandLine::ForCurrentProcess()->HasSwitch("kill-server");
  if ((kill_server && argc != 2) || (!kill_server && argc != 1)) {
    std::cerr << "Usage: device_forwarder [--kill-server]" << std::endl;
    return 1;
  }
  base::AtExitManager at_exit_manager;  // Used by base::Thread.
  ClientDelegate client_delegate;
  ServerDelegate daemon_delegate;
  const char kLogFilePath[] = "";  // Log to logcat.
  Daemon daemon(kLogFilePath, kDaemonIdentifier, &client_delegate,
                &daemon_delegate, &GetExitNotifierFD);

  if (kill_server)
    return !daemon.Kill();

  if (!daemon.SpawnIfNeeded())
    return 1;
  return client_delegate.has_failed();
}

}  // namespace
}  // namespace forwarder2

int main(int argc, char** argv) {
  return forwarder2::RunDeviceForwarder(argc, argv);
}
