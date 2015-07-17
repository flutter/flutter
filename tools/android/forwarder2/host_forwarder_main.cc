// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cstdio>
#include <iostream>
#include <limits>
#include <string>
#include <utility>
#include <vector>

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/compiler_specific.h"
#include "base/containers/hash_tables.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/memory/linked_ptr.h"
#include "base/memory/scoped_vector.h"
#include "base/memory/weak_ptr.h"
#include "base/pickle.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_piece.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/task_runner.h"
#include "base/threading/thread.h"
#include "tools/android/forwarder2/common.h"
#include "tools/android/forwarder2/daemon.h"
#include "tools/android/forwarder2/host_controller.h"
#include "tools/android/forwarder2/pipe_notifier.h"
#include "tools/android/forwarder2/socket.h"
#include "tools/android/forwarder2/util.h"

namespace forwarder2 {
namespace {

const char kLogFilePath[] = "/tmp/host_forwarder_log";
const char kDaemonIdentifier[] = "chrome_host_forwarder_daemon";

const int kBufSize = 256;

// Needs to be global to be able to be accessed from the signal handler.
PipeNotifier* g_notifier = NULL;

// Lets the daemon fetch the exit notifier file descriptor.
int GetExitNotifierFD() {
  DCHECK(g_notifier);
  return g_notifier->receiver_fd();
}

void KillHandler(int signal_number) {
  char buf[kBufSize];
  if (signal_number != SIGTERM && signal_number != SIGINT) {
    snprintf(buf, sizeof(buf), "Ignoring unexpected signal %d.", signal_number);
    SIGNAL_SAFE_LOG(WARNING, buf);
    return;
  }
  snprintf(buf, sizeof(buf), "Received signal %d.", signal_number);
  SIGNAL_SAFE_LOG(WARNING, buf);
  static int s_kill_handler_count = 0;
  CHECK(g_notifier);
  // If for some reason the forwarder get stuck in any socket waiting forever,
  // we can send a SIGKILL or SIGINT three times to force it die
  // (non-nicely). This is useful when debugging.
  ++s_kill_handler_count;
  if (!g_notifier->Notify() || s_kill_handler_count > 2)
    exit(1);
}

// Manages HostController instances. There is one HostController instance for
// each connection being forwarded. Note that forwarding can happen with many
// devices (identified with a serial id).
class HostControllersManager {
 public:
  HostControllersManager()
      : controllers_(new HostControllerMap()),
        has_failed_(false),
        weak_ptr_factory_(this) {
  }

  ~HostControllersManager() {
    if (!thread_.get())
      return;
    // Delete the controllers on the thread they were created on.
    thread_->task_runner()->DeleteSoon(
        FROM_HERE, controllers_.release());
  }

  void HandleRequest(const std::string& adb_path,
                     const std::string& device_serial,
                     int device_port,
                     int host_port,
                     scoped_ptr<Socket> client_socket) {
    // Lazy initialize so that the CLI process doesn't get this thread created.
    InitOnce();
    thread_->task_runner()->PostTask(
        FROM_HERE,
        base::Bind(&HostControllersManager::HandleRequestOnInternalThread,
                   base::Unretained(this), adb_path, device_serial, device_port,
                   host_port, base::Passed(&client_socket)));
  }

  bool has_failed() const { return has_failed_; }

 private:
  typedef base::hash_map<
      std::string, linked_ptr<HostController> > HostControllerMap;

  static std::string MakeHostControllerMapKey(int adb_port, int device_port) {
    return base::StringPrintf("%d:%d", adb_port, device_port);
  }

  void InitOnce() {
    if (thread_.get())
      return;
    at_exit_manager_.reset(new base::AtExitManager());
    thread_.reset(new base::Thread("HostControllersManagerThread"));
    thread_->Start();
  }

  // Invoked when a HostController instance reports an error (e.g. due to a
  // device connectivity issue). Note that this could be called after the
  // controller manager was destroyed which is why a weak pointer is used.
  static void DeleteHostController(
      const base::WeakPtr<HostControllersManager>& manager_ptr,
      scoped_ptr<HostController> host_controller) {
    HostController* const controller = host_controller.release();
    HostControllersManager* const manager = manager_ptr.get();
    if (!manager) {
      // Note that |controller| is not leaked in this case since the host
      // controllers manager owns the controllers. If the manager was deleted
      // then all the controllers (including |controller|) were also deleted.
      return;
    }
    DCHECK(manager->thread_->task_runner()->RunsTasksOnCurrentThread());
    // Note that this will delete |controller| which is owned by the map.
    DeleteRefCountedValueInMap(
        MakeHostControllerMapKey(
            controller->adb_port(), controller->device_port()),
        manager->controllers_.get());
  }

  void HandleRequestOnInternalThread(const std::string& adb_path,
                                     const std::string& device_serial,
                                     int device_port,
                                     int host_port,
                                     scoped_ptr<Socket> client_socket) {
    const int adb_port = GetAdbPortForDevice(adb_path, device_serial);
    if (adb_port < 0) {
      SendMessage(
          "ERROR: could not get adb port for device. You might need to add "
          "'adb' to your PATH or provide the device serial id.",
          client_socket.get());
      return;
    }
    if (device_port < 0) {
      // Remove the previously created host controller.
      const std::string controller_key = MakeHostControllerMapKey(
          adb_port, -device_port);
      const bool controller_did_exist = DeleteRefCountedValueInMap(
          controller_key, controllers_.get());
      SendMessage(
          !controller_did_exist ? "ERROR: could not unmap port" : "OK",
          client_socket.get());

      RemoveAdbPortForDeviceIfNeeded(adb_path, device_serial);
      return;
    }
    if (host_port < 0) {
      SendMessage("ERROR: missing host port", client_socket.get());
      return;
    }
    const bool use_dynamic_port_allocation = device_port == 0;
    if (!use_dynamic_port_allocation) {
      const std::string controller_key = MakeHostControllerMapKey(
          adb_port, device_port);
      if (controllers_->find(controller_key) != controllers_->end()) {
        LOG(INFO) << "Already forwarding device port " << device_port
                  << " to host port " << host_port;
        SendMessage(base::StringPrintf("%d:%d", device_port, host_port),
                    client_socket.get());
        return;
      }
    }
    // Create a new host controller.
    scoped_ptr<HostController> host_controller(
        HostController::Create(
            device_port, host_port, adb_port, GetExitNotifierFD(),
            base::Bind(&HostControllersManager::DeleteHostController,
                       weak_ptr_factory_.GetWeakPtr())));
    if (!host_controller.get()) {
      has_failed_ = true;
      SendMessage("ERROR: Connection to device failed.", client_socket.get());
      return;
    }
    // Get the current allocated port.
    device_port = host_controller->device_port();
    LOG(INFO) << "Forwarding device port " << device_port << " to host port "
              << host_port;
    const std::string msg = base::StringPrintf("%d:%d", device_port, host_port);
    if (!SendMessage(msg, client_socket.get()))
      return;
    host_controller->Start();
    controllers_->insert(
        std::make_pair(MakeHostControllerMapKey(adb_port, device_port),
                       linked_ptr<HostController>(host_controller.release())));
  }

  void RemoveAdbPortForDeviceIfNeeded(const std::string& adb_path,
                                      const std::string& device_serial) {
    base::hash_map<std::string, int>::const_iterator it =
        device_serial_to_adb_port_map_.find(device_serial);
    if (it == device_serial_to_adb_port_map_.end())
      return;

    int port = it->second;
    const std::string prefix = base::StringPrintf("%d:", port);
    for (HostControllerMap::const_iterator others = controllers_->begin();
         others != controllers_->end(); ++others) {
      if (others->first.find(prefix) == 0U)
        return;
    }
    // No other port is being forwarded to this device:
    // - Remove it from our internal serial -> adb port map.
    // - Remove from "adb forward" command.
    LOG(INFO) << "Device " << device_serial << " has no more ports.";
    device_serial_to_adb_port_map_.erase(device_serial);
    const std::string serial_part = device_serial.empty() ?
        std::string() : std::string("-s ") + device_serial;
    const std::string command = base::StringPrintf(
        "%s %s forward --remove tcp:%d",
        adb_path.c_str(),
        serial_part.c_str(),
        port);
    const int ret = system(command.c_str());
    LOG(INFO) << command << " ret: " << ret;
    // Wait for the socket to be fully unmapped.
    const std::string port_mapped_cmd = base::StringPrintf(
        "lsof -nPi:%d",
        port);
    const int poll_interval_us = 500 * 1000;
    int retries = 3;
    while (retries) {
      const int port_unmapped = system(port_mapped_cmd.c_str());
      LOG(INFO) << "Device " << device_serial << " port " << port << " unmap "
                << port_unmapped;
      if (port_unmapped)
        break;
      --retries;
      usleep(poll_interval_us);
    }
  }

  int GetAdbPortForDevice(const std::string adb_path,
                          const std::string& device_serial) {
    base::hash_map<std::string, int>::const_iterator it =
        device_serial_to_adb_port_map_.find(device_serial);
    if (it != device_serial_to_adb_port_map_.end())
      return it->second;
    Socket bind_socket;
    CHECK(bind_socket.BindTcp("127.0.0.1", 0));
    const int port = bind_socket.GetPort();
    bind_socket.Close();
    const std::string serial_part = device_serial.empty() ?
        std::string() : std::string("-s ") + device_serial;
    const std::string command = base::StringPrintf(
        "%s %s forward tcp:%d localabstract:chrome_device_forwarder",
        adb_path.c_str(),
        serial_part.c_str(),
        port);
    LOG(INFO) << command;
    const int ret = system(command.c_str());
    if (ret < 0 || !WIFEXITED(ret) || WEXITSTATUS(ret) != 0)
      return -1;
    device_serial_to_adb_port_map_[device_serial] = port;
    return port;
  }

  bool SendMessage(const std::string& msg, Socket* client_socket) {
    bool result = client_socket->WriteString(msg);
    DCHECK(result);
    if (!result)
      has_failed_ = true;
    return result;
  }

  base::hash_map<std::string, int> device_serial_to_adb_port_map_;
  scoped_ptr<HostControllerMap> controllers_;
  bool has_failed_;
  scoped_ptr<base::AtExitManager> at_exit_manager_;  // Needed by base::Thread.
  scoped_ptr<base::Thread> thread_;
  base::WeakPtrFactory<HostControllersManager> weak_ptr_factory_;
};

class ServerDelegate : public Daemon::ServerDelegate {
 public:
  ServerDelegate(const std::string& adb_path)
      : adb_path_(adb_path), has_failed_(false) {}

  bool has_failed() const {
    return has_failed_ || controllers_manager_.has_failed();
  }

  // Daemon::ServerDelegate:
  void Init() override {
    LOG(INFO) << "Starting host process daemon (pid=" << getpid() << ")";
    DCHECK(!g_notifier);
    g_notifier = new PipeNotifier();
    signal(SIGTERM, KillHandler);
    signal(SIGINT, KillHandler);
  }

  void OnClientConnected(scoped_ptr<Socket> client_socket) override {
    char buf[kBufSize];
    const int bytes_read = client_socket->Read(buf, sizeof(buf));
    if (bytes_read <= 0) {
      if (client_socket->DidReceiveEvent())
        return;
      PError("Read()");
      has_failed_ = true;
      return;
    }
    const base::Pickle command_pickle(buf, bytes_read);
    base::PickleIterator pickle_it(command_pickle);
    std::string device_serial;
    CHECK(pickle_it.ReadString(&device_serial));
    int device_port;
    if (!pickle_it.ReadInt(&device_port)) {
      client_socket->WriteString("ERROR: missing device port");
      return;
    }
    int host_port;
    if (!pickle_it.ReadInt(&host_port))
      host_port = -1;
    controllers_manager_.HandleRequest(adb_path_, device_serial, device_port,
                                       host_port, client_socket.Pass());
  }

 private:
  std::string adb_path_;
  bool has_failed_;
  HostControllersManager controllers_manager_;

  DISALLOW_COPY_AND_ASSIGN(ServerDelegate);
};

class ClientDelegate : public Daemon::ClientDelegate {
 public:
  ClientDelegate(const base::Pickle& command_pickle)
      : command_pickle_(command_pickle), has_failed_(false) {}

  bool has_failed() const { return has_failed_; }

  // Daemon::ClientDelegate:
  void OnDaemonReady(Socket* daemon_socket) override {
    // Send the forward command to the daemon.
    CHECK_EQ(static_cast<long>(command_pickle_.size()),
             daemon_socket->WriteNumBytes(command_pickle_.data(),
                                          command_pickle_.size()));
    char buf[kBufSize];
    const int bytes_read = daemon_socket->Read(
        buf, sizeof(buf) - 1 /* leave space for null terminator */);
    CHECK_GT(bytes_read, 0);
    DCHECK(static_cast<size_t>(bytes_read) < sizeof(buf));
    buf[bytes_read] = 0;
    base::StringPiece msg(buf, bytes_read);
    if (msg.starts_with("ERROR")) {
      LOG(ERROR) << msg;
      has_failed_ = true;
      return;
    }
    printf("%s\n", buf);
  }

 private:
  const base::Pickle command_pickle_;
  bool has_failed_;
};

void ExitWithUsage() {
  std::cerr << "Usage: host_forwarder [options]\n\n"
               "Options:\n"
               "  --serial-id=[0-9A-Z]{16}]\n"
               "  --map DEVICE_PORT HOST_PORT\n"
               "  --unmap DEVICE_PORT\n"
               "  --adb PATH_TO_ADB\n"
               "  --kill-server\n";
  exit(1);
}

int PortToInt(const std::string& s) {
  int value;
  // Note that 0 is a valid port (used for dynamic port allocation).
  if (!base::StringToInt(s, &value) || value < 0 ||
      value > std::numeric_limits<uint16>::max()) {
    LOG(ERROR) << "Could not convert string " << s << " to port";
    ExitWithUsage();
  }
  return value;
}

int RunHostForwarder(int argc, char** argv) {
  base::CommandLine::Init(argc, argv);
  const base::CommandLine& cmd_line = *base::CommandLine::ForCurrentProcess();
  std::string adb_path = "adb";
  bool kill_server = false;

  base::Pickle pickle;
  pickle.WriteString(
      cmd_line.HasSwitch("serial-id") ?
          cmd_line.GetSwitchValueASCII("serial-id") : std::string());

  const std::vector<std::string> args = cmd_line.GetArgs();
  if (cmd_line.HasSwitch("kill-server")) {
    kill_server = true;
  } else if (cmd_line.HasSwitch("unmap")) {
    if (args.size() != 1)
      ExitWithUsage();
    // Note the minus sign below.
    pickle.WriteInt(-PortToInt(args[0]));
  } else if (cmd_line.HasSwitch("map")) {
    if (args.size() != 2)
      ExitWithUsage();
    pickle.WriteInt(PortToInt(args[0]));
    pickle.WriteInt(PortToInt(args[1]));
  } else {
    ExitWithUsage();
  }

  if (cmd_line.HasSwitch("adb")) {
    adb_path = cmd_line.GetSwitchValueASCII("adb");
  }

  if (kill_server && args.size() > 0)
    ExitWithUsage();

  ClientDelegate client_delegate(pickle);
  ServerDelegate daemon_delegate(adb_path);
  Daemon daemon(
      kLogFilePath, kDaemonIdentifier, &client_delegate, &daemon_delegate,
      &GetExitNotifierFD);

  if (kill_server)
    return !daemon.Kill();
  if (!daemon.SpawnIfNeeded())
    return 1;

  return client_delegate.has_failed() || daemon_delegate.has_failed();
}

}  // namespace
}  // namespace forwarder2

int main(int argc, char** argv) {
  return forwarder2::RunHostForwarder(argc, argv);
}
