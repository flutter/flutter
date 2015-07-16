// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/device_controller.h"

#include <utility>

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/callback_helpers.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/single_thread_task_runner.h"
#include "tools/android/forwarder2/command.h"
#include "tools/android/forwarder2/device_listener.h"
#include "tools/android/forwarder2/socket.h"
#include "tools/android/forwarder2/util.h"

namespace forwarder2 {

// static
scoped_ptr<DeviceController> DeviceController::Create(
    const std::string& adb_unix_socket,
    int exit_notifier_fd) {
  scoped_ptr<DeviceController> device_controller;
  scoped_ptr<Socket> host_socket(new Socket());
  if (!host_socket->BindUnix(adb_unix_socket)) {
    PLOG(ERROR) << "Could not BindAndListen DeviceController socket on port "
                << adb_unix_socket << ": ";
    return device_controller.Pass();
  }
  LOG(INFO) << "Listening on Unix Domain Socket " << adb_unix_socket;
  device_controller.reset(
      new DeviceController(host_socket.Pass(), exit_notifier_fd));
  return device_controller.Pass();
}

DeviceController::~DeviceController() {
  DCHECK(construction_task_runner_->RunsTasksOnCurrentThread());
}

void DeviceController::Start() {
  AcceptHostCommandSoon();
}

DeviceController::DeviceController(scoped_ptr<Socket> host_socket,
                                   int exit_notifier_fd)
    : host_socket_(host_socket.Pass()),
      exit_notifier_fd_(exit_notifier_fd),
      construction_task_runner_(base::MessageLoopProxy::current()),
      weak_ptr_factory_(this) {
  host_socket_->AddEventFd(exit_notifier_fd);
}

void DeviceController::AcceptHostCommandSoon() {
  base::MessageLoopProxy::current()->PostTask(
      FROM_HERE,
      base::Bind(&DeviceController::AcceptHostCommandInternal,
                 base::Unretained(this)));
}

void DeviceController::AcceptHostCommandInternal() {
  scoped_ptr<Socket> socket(new Socket);
  if (!host_socket_->Accept(socket.get())) {
    if (!host_socket_->DidReceiveEvent())
      PLOG(ERROR) << "Could not Accept DeviceController socket";
    else
      LOG(INFO) << "Received exit notification";
    return;
  }
  base::ScopedClosureRunner accept_next_client(
      base::Bind(&DeviceController::AcceptHostCommandSoon,
                 base::Unretained(this)));
  // So that |socket| doesn't block on read if it has notifications.
  socket->AddEventFd(exit_notifier_fd_);
  int port;
  command::Type command;
  if (!ReadCommand(socket.get(), &port, &command)) {
    LOG(ERROR) << "Invalid command received.";
    return;
  }
  const ListenersMap::iterator listener_it = listeners_.find(port);
  DeviceListener* const listener = listener_it == listeners_.end()
      ? static_cast<DeviceListener*>(NULL) : listener_it->second.get();
  switch (command) {
    case command::LISTEN: {
      if (listener != NULL) {
        LOG(WARNING) << "Already forwarding port " << port
                     << ". Attempting to restart the listener.\n";
        DeleteRefCountedValueInMapFromIterator(listener_it, &listeners_);
      }
      scoped_ptr<DeviceListener> new_listener(
          DeviceListener::Create(
              socket.Pass(), port,
              base::Bind(&DeviceController::DeleteListenerOnError,
                         weak_ptr_factory_.GetWeakPtr())));
      if (!new_listener)
        return;
      new_listener->Start();
      // |port| can be zero, to allow dynamically allocated port, so instead, we
      // call DeviceListener::listener_port() to retrieve the currently
      // allocated port to this new listener.
      const int listener_port = new_listener->listener_port();
      listeners_.insert(
          std::make_pair(listener_port,
                         linked_ptr<DeviceListener>(new_listener.release())));
      LOG(INFO) << "Forwarding device port " << listener_port << " to host.";
      break;
    }
    case command::DATA_CONNECTION:
      if (listener == NULL) {
        LOG(ERROR) << "Data Connection command received, but "
                   << "listener has not been set up yet for port " << port;
        // After this point it is assumed that, once we close our Adb Data
        // socket, the Adb forwarder command will propagate the closing of
        // sockets all the way to the host side.
        break;
      }
      listener->SetAdbDataSocket(socket.Pass());
      break;
    case command::UNLISTEN:
      LOG(INFO) << "Unmapping port " << port;
      if (!listener) {
        LOG(ERROR) << "No listener found for port " << port;
        SendCommand(command::UNLISTEN_ERROR, port, socket.get());
        break;
      }
      DeleteRefCountedValueInMapFromIterator(listener_it, &listeners_);
      SendCommand(command::UNLISTEN_SUCCESS, port, socket.get());
      break;
    default:
      // TODO(felipeg): add a KillAllListeners command.
      LOG(ERROR) << "Invalid command received. Port: " << port
                 << " Command: " << command;
  }
}

// static
void DeviceController::DeleteListenerOnError(
      const base::WeakPtr<DeviceController>& device_controller_ptr,
      scoped_ptr<DeviceListener> device_listener) {
  DeviceListener* const listener = device_listener.release();
  DeviceController* const controller = device_controller_ptr.get();
  if (!controller) {
    // |listener| was already deleted by the controller that did have its
    // ownership.
    return;
  }
  DCHECK(controller->construction_task_runner_->RunsTasksOnCurrentThread());
  bool listener_did_exist = DeleteRefCountedValueInMap(
      listener->listener_port(), &controller->listeners_);
  DCHECK(listener_did_exist);
  // Note that |listener| was deleted by DeleteRefCountedValueInMap().
}

}  // namespace forwarder
