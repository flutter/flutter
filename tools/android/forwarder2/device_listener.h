// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_DEVICE_LISTENER_H_
#define TOOLS_ANDROID_FORWARDER2_DEVICE_LISTENER_H_

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/threading/thread.h"
#include "tools/android/forwarder2/forwarders_manager.h"
#include "tools/android/forwarder2/pipe_notifier.h"
#include "tools/android/forwarder2/self_deleter_helper.h"
#include "tools/android/forwarder2/socket.h"

namespace base {
class SingleThreadTaskRunner;
}  // namespace base

namespace forwarder2 {

class Forwarder;

// A DeviceListener instance is used in the device_forwarder program to bind to
// a specific device-side |port| and wait for client connections. When a
// connection happens, it informs the corresponding HostController instance
// running on the host, through |host_socket|. Then the class expects a call to
// its SetAdbDataSocket() method (performed by the device controller) once the
// host opened a new connection to the device. When this happens, a new internal
// Forwarder instance is started.
// Note that instances of this class are owned by the device controller which
// creates and destroys them on the same thread. In case an internal error
// happens on the DeviceListener's internal thread, the DeviceListener
// can also self-delete by executing the user-provided callback on the thread
// the DeviceListener was created on.
// Note that the DeviceListener's destructor joins its internal thread (i.e.
// waits for its completion) which means that the internal thread is guaranteed
// not to be running anymore once the object is deleted.
class DeviceListener {
 public:
  // Callback that is used for self-deletion on error to let the device
  // controller perform some additional cleanup work (e.g. removing the device
  // listener instance from its internal map before deleting it).
  typedef base::Callback<void (scoped_ptr<DeviceListener>)> ErrorCallback;

  static scoped_ptr<DeviceListener> Create(scoped_ptr<Socket> host_socket,
                                           int port,
                                           const ErrorCallback& error_callback);

  ~DeviceListener();

  void Start();

  void SetAdbDataSocket(scoped_ptr<Socket> adb_data_socket);

  int listener_port() const { return listener_port_; }

 private:
  DeviceListener(scoped_ptr<Socket> listener_socket,
                 scoped_ptr<Socket> host_socket,
                 int port,
                 const ErrorCallback& error_callback);

  // Pushes an AcceptClientOnInternalThread() task to the internal thread's
  // message queue in order to wait for a new client soon.
  void AcceptNextClientSoon();

  void AcceptClientOnInternalThread();

  void OnAdbDataSocketReceivedOnInternalThread(
      scoped_ptr<Socket> adb_data_socket);

  void OnInternalThreadError();

  SelfDeleterHelper<DeviceListener> self_deleter_helper_;
  // Used for the listener thread to be notified on destruction. We have one
  // notifier per Listener thread since each Listener thread may be requested to
  // exit for different reasons independently from each other and independent
  // from the main program, ex. when the host requests to forward/listen the
  // same port again.  Both the |host_socket_| and |listener_socket_| must share
  // the same receiver file descriptor from |deletion_notifier_| and it is set
  // in the constructor.
  PipeNotifier deletion_notifier_;
  // The local device listener socket for accepting connections from the local
  // port (listener_port_).
  const scoped_ptr<Socket> listener_socket_;
  // The listener socket for sending control commands.
  const scoped_ptr<Socket> host_socket_;
  scoped_ptr<Socket> device_data_socket_;
  const int listener_port_;
  // Task runner used for deletion set at construction time (i.e. the object is
  // deleted on the same thread it is created on).
  scoped_refptr<base::SingleThreadTaskRunner> deletion_task_runner_;
  base::Thread thread_;
  ForwardersManager forwarders_manager_;

  DISALLOW_COPY_AND_ASSIGN(DeviceListener);
};

}  // namespace forwarder

#endif  // TOOLS_ANDROID_FORWARDER2_DEVICE_LISTENER_H_
