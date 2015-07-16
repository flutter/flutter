// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_HOST_CONTROLLER_H_
#define TOOLS_ANDROID_FORWARDER2_HOST_CONTROLLER_H_

#include <string>

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "base/threading/thread.h"
#include "tools/android/forwarder2/forwarders_manager.h"
#include "tools/android/forwarder2/pipe_notifier.h"
#include "tools/android/forwarder2/self_deleter_helper.h"
#include "tools/android/forwarder2/socket.h"

namespace forwarder2 {

// This class partners with DeviceController and has the same lifetime and
// threading characteristics as DeviceListener. In a nutshell, this class
// operates on its own thread and is destroyed on the thread it was constructed
// on. The class' deletion can happen in two different ways:
// - Its destructor was called by its owner (HostControllersManager).
// - Its internal thread requested self-deletion after an error happened. In
//   this case the owner (HostControllersManager) is notified on the
//   construction thread through the provided ErrorCallback invoked with the
//   HostController instance. When this callback is invoked, it's up to the
//   owner to delete the instance.
class HostController {
 public:
  // Callback used for self-deletion when an error happens so that the client
  // can perform some cleanup work before deleting the HostController instance.
  typedef base::Callback<void (scoped_ptr<HostController>)> ErrorCallback;

  // If |device_port| is zero then a dynamic port is allocated (and retrievable
  // through device_port() below).
  static scoped_ptr<HostController> Create(int device_port,
                                           int host_port,
                                           int adb_port,
                                           int exit_notifier_fd,
                                           const ErrorCallback& error_callback);

  ~HostController();

  // Starts the internal controller thread.
  void Start();

  int adb_port() const { return adb_port_; }

  int device_port() const { return device_port_; }

 private:
  HostController(int device_port,
                 int host_port,
                 int adb_port,
                 int exit_notifier_fd,
                 const ErrorCallback& error_callback,
                 scoped_ptr<Socket> adb_control_socket,
                 scoped_ptr<PipeNotifier> delete_controller_notifier);

  void ReadNextCommandSoon();
  void ReadCommandOnInternalThread();

  void StartForwarder(scoped_ptr<Socket> host_server_data_socket);

  // Note that this gets also called when ~HostController() is invoked.
  void OnInternalThreadError();

  void UnmapPortOnDevice();

  SelfDeleterHelper<HostController> self_deleter_helper_;
  const int device_port_;
  const int host_port_;
  const int adb_port_;
  // Used to notify the controller when the process is killed.
  const int global_exit_notifier_fd_;
  scoped_ptr<Socket> adb_control_socket_;
  // Used to cancel the pending blocking IO operations when the host controller
  // instance is deleted.
  scoped_ptr<PipeNotifier> delete_controller_notifier_;
  // Task runner used for deletion set at deletion time (i.e. the object is
  // deleted on the same thread it is created on).
  const scoped_refptr<base::SingleThreadTaskRunner> deletion_task_runner_;
  base::Thread thread_;
  ForwardersManager forwarders_manager_;

  DISALLOW_COPY_AND_ASSIGN(HostController);
};

}  // namespace forwarder2

#endif  // TOOLS_ANDROID_FORWARDER2_HOST_CONTROLLER_H_
