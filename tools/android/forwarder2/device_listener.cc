// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tools/android/forwarder2/device_listener.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/callback.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/single_thread_task_runner.h"
#include "tools/android/forwarder2/command.h"
#include "tools/android/forwarder2/forwarder.h"
#include "tools/android/forwarder2/socket.h"

namespace forwarder2 {

// static
scoped_ptr<DeviceListener> DeviceListener::Create(
    scoped_ptr<Socket> host_socket,
    int listener_port,
    const ErrorCallback& error_callback) {
  scoped_ptr<Socket> listener_socket(new Socket());
  scoped_ptr<DeviceListener> device_listener;
  if (!listener_socket->BindTcp("", listener_port)) {
    LOG(ERROR) << "Device could not bind and listen to local port "
               << listener_port;
    SendCommand(command::BIND_ERROR, listener_port, host_socket.get());
    return device_listener.Pass();
  }
  // In case the |listener_port_| was zero, GetPort() will return the
  // currently (non-zero) allocated port for this socket.
  listener_port = listener_socket->GetPort();
  SendCommand(command::BIND_SUCCESS, listener_port, host_socket.get());
  device_listener.reset(
      new DeviceListener(listener_socket.Pass(), host_socket.Pass(),
                         listener_port, error_callback));
  return device_listener.Pass();
}

DeviceListener::~DeviceListener() {
  DCHECK(deletion_task_runner_->RunsTasksOnCurrentThread());
  deletion_notifier_.Notify();
}

void DeviceListener::Start() {
  thread_.Start();
  AcceptNextClientSoon();
}

void DeviceListener::SetAdbDataSocket(scoped_ptr<Socket> adb_data_socket) {
  thread_.message_loop_proxy()->PostTask(
      FROM_HERE,
      base::Bind(&DeviceListener::OnAdbDataSocketReceivedOnInternalThread,
                 base::Unretained(this), base::Passed(&adb_data_socket)));
}

DeviceListener::DeviceListener(scoped_ptr<Socket> listener_socket,
                               scoped_ptr<Socket> host_socket,
                               int port,
                               const ErrorCallback& error_callback)
    : self_deleter_helper_(this, error_callback),
      listener_socket_(listener_socket.Pass()),
      host_socket_(host_socket.Pass()),
      listener_port_(port),
      deletion_task_runner_(base::MessageLoopProxy::current()),
      thread_("DeviceListener") {
  CHECK(host_socket_.get());
  DCHECK(deletion_task_runner_.get());
  host_socket_->AddEventFd(deletion_notifier_.receiver_fd());
  listener_socket_->AddEventFd(deletion_notifier_.receiver_fd());
}

void DeviceListener::AcceptNextClientSoon() {
  thread_.message_loop_proxy()->PostTask(
      FROM_HERE,
      base::Bind(&DeviceListener::AcceptClientOnInternalThread,
                 base::Unretained(this)));
}

void DeviceListener::AcceptClientOnInternalThread() {
  device_data_socket_.reset(new Socket());
  if (!listener_socket_->Accept(device_data_socket_.get())) {
    if (listener_socket_->DidReceiveEvent()) {
      LOG(INFO) << "Received exit notification, stopped accepting clients.";
      OnInternalThreadError();
      return;
    }
    LOG(WARNING) << "Could not Accept in ListenerSocket.";
    SendCommand(command::ACCEPT_ERROR, listener_port_, host_socket_.get());
    OnInternalThreadError();
    return;
  }
  SendCommand(command::ACCEPT_SUCCESS, listener_port_, host_socket_.get());
  if (!ReceivedCommand(command::HOST_SERVER_SUCCESS,
                       host_socket_.get())) {
    SendCommand(command::ACK, listener_port_, host_socket_.get());
    LOG(ERROR) << "Host could not connect to server.";
    device_data_socket_->Close();
    if (host_socket_->has_error()) {
      LOG(ERROR) << "Adb Control connection lost. "
                 << "Listener port: " << listener_port_;
      OnInternalThreadError();
      return;
    }
    // It can continue if the host forwarder could not connect to the host
    // server but the control connection is still alive (no errors). The device
    // acknowledged that (above), and it can re-try later.
    AcceptNextClientSoon();
    return;
  }
}

void DeviceListener::OnAdbDataSocketReceivedOnInternalThread(
    scoped_ptr<Socket> adb_data_socket) {
  DCHECK(adb_data_socket);
  SendCommand(command::ADB_DATA_SOCKET_SUCCESS, listener_port_,
              host_socket_.get());
  forwarders_manager_.CreateAndStartNewForwarder(
      device_data_socket_.Pass(), adb_data_socket.Pass());
  AcceptNextClientSoon();
}

void DeviceListener::OnInternalThreadError() {
  self_deleter_helper_.MaybeSelfDeleteSoon();
}

}  // namespace forwarder
