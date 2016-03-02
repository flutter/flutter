// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_IPC_SUPPORT_H_
#define MOJO_EDK_SYSTEM_IPC_SUPPORT_H_

#include <functional>
#include <memory>

#include "mojo/edk/embedder/process_type.h"
#include "mojo/edk/embedder/slave_info.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/system/channel_id.h"
#include "mojo/edk/system/connection_identifier.h"
#include "mojo/edk/system/process_identifier.h"
#include "mojo/edk/util/gtest_prod_utils.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
class ProcessDelegate;
}

namespace platform {
class PlatformHandleWatcher;
}

namespace system {

class ChannelManager;
class ConnectionManager;
class MessagePipeDispatcher;

// This test (and its helper function) need to be friended.
FORWARD_DECLARE_TEST(IPCSupportTest, MasterSlaveInternal);
FORWARD_DECLARE_TEST(IPCSupportTest, MultiprocessMasterSlaveInternal);
void MultiprocessMasterSlaveInternalTestChildTest();

// |IPCSupport| encapsulates all the objects that are needed to support IPC for
// a single "process" (whether that be a master or a slave).
//
// ("Process" typically means a real process, but for testing purposes, multiple
// instances can coexist within a single real process.)
//
// Each "process" must have an |embedder::PlatformSupport| and a suitable
// |embedder::ProcessDelegate|, together with an I/O thread and a thread on
// which to call delegate methods (which may be the same as the I/O thread).
//
// For testing purposes within a single real process, except for the I/O thread,
// these may be shared between "processes" (i.e., instances of |IPCSupport|) --
// there must be a separate I/O thread for each |IPCSupport|.
//
// Except for |ShutdownOnIOThread()|, this class is thread-safe. (No methods may
// be called during/after |ShutdownOnIOThread()|.)
class IPCSupport {
 public:
  // Constructor: initializes for the given |process_type|; |process_delegate|
  // must match the process type. |platform_handle| is only used for slave
  // processes.
  //
  // All the (pointer) arguments must remain alive (and, in the case of task
  // runners, continue to process tasks) until |ShutdownOnIOThread()| has been
  // called.
  IPCSupport(embedder::PlatformSupport* platform_support,
             embedder::ProcessType process_type,
             util::RefPtr<platform::TaskRunner>&& delegate_thread_task_runner,
             embedder::ProcessDelegate* process_delegate,
             util::RefPtr<platform::TaskRunner>&& io_task_runner,
             platform::PlatformHandleWatcher* io_watcher,
             platform::ScopedPlatformHandle platform_handle);
  // Note: This object must be shut down before destruction (see
  // |ShutdownOnIOThread()|).
  ~IPCSupport();

  // This must be called (exactly once) on the I/O thread before this object is
  // destroyed (which may happen on any thread). Note: This does *not* call the
  // process delegate's |OnShutdownComplete()|.
  void ShutdownOnIOThread();

  // Generates a new (unique) connection identifier, for use with
  // |ConnectToSlave()| and |ConnectToMaster()|, below.
  ConnectionIdentifier GenerateConnectionIdentifier();

  // Called in the master process to connect a slave process to the IPC system.
  //
  // |connection_id| should be a unique connection identifier, which will also
  // be given to the slave (in |ConnectToMaster()|, below). |slave_info| is
  // context for the caller (it is treated as an opaque value by this class).
  // |platform_handle| should be the master's handle to an OS "pipe" between
  // master and slave. This will then bootstrap a |Channel| between master and
  // slave together with an initial message pipe (returning a dispatcher for the
  // master's side).
  //
  // |callback| will be run after the |Channel| is created, either using
  // |callback_thread_task_runner| (if it is non-null) or on the I/O thread.
  // |*channel_id| will be set to the ID for the channel (immediately); the
  // channel may be destroyed using this ID, but only after the callback has
  // been run.
  //
  // TODO(vtl): Add some more channel management functionality to this class.
  // Maybe make this callback interface more sane.
  util::RefPtr<MessagePipeDispatcher> ConnectToSlave(
      const ConnectionIdentifier& connection_id,
      embedder::SlaveInfo slave_info,
      platform::ScopedPlatformHandle platform_handle,
      std::function<void()>&& callback,
      util::RefPtr<platform::TaskRunner>&& callback_thread_task_runner,
      ChannelId* channel_id);

  // Called in a slave process to connect it to the master process and thus the
  // IPC system, creating a |Channel| and an initial message pipe (return a
  // dispatcher for the slave's side). See |ConnectToSlave()|, above.
  //
  // |callback|, |callback_thread_task_runner|, and |channel_id| are as in
  // |ConnectToSlave()|.
  //
  // TODO(vtl): |ConnectToSlave()|'s channel management TODO also applies here.
  util::RefPtr<MessagePipeDispatcher> ConnectToMaster(
      const ConnectionIdentifier& connection_id,
      std::function<void()>&& callback,
      util::RefPtr<platform::TaskRunner>&& callback_thread_task_runner,
      ChannelId* channel_id);

  embedder::ProcessType process_type() const { return process_type_; }
  embedder::ProcessDelegate* process_delegate() const {
    return process_delegate_;
  }
  const util::RefPtr<platform::TaskRunner>& delegate_thread_task_runner()
      const {
    return delegate_thread_task_runner_;
  }
  const util::RefPtr<platform::TaskRunner>& io_task_runner() const {
    return io_task_runner_;
  }
  // TODO(vtl): The things that use the following should probably be moved into
  // this class.
  ChannelManager* channel_manager() const { return channel_manager_.get(); }

 private:
  // These test |ConnectToSlaveInternal()| and |ConnectToMasterInternal()|.
  FRIEND_TEST_ALL_PREFIXES(IPCSupportTest, MasterSlaveInternal);
  FRIEND_TEST_ALL_PREFIXES(IPCSupportTest, MultiprocessMasterSlaveInternal);
  friend void MultiprocessMasterSlaveInternalTestChildTest();

  // Helper for |ConnectToSlave()|. Connects (using the connection manager) to
  // the slave using |platform_handle| (a handle to an OS "pipe" between master
  // and slave) and creates a second OS "pipe" between the master and slave
  // (returning the master's handle). |*slave_process_identifier| will be set to
  // the process identifier assigned to the slave.
  platform::ScopedPlatformHandle ConnectToSlaveInternal(
      const ConnectionIdentifier& connection_id,
      embedder::SlaveInfo slave_info,
      platform::ScopedPlatformHandle platform_handle,
      ProcessIdentifier* slave_process_identifier);

  // Helper for |ConnectToMaster()|. Connects (using the connection manager) to
  // the master (using the handle to the OS "pipe" that was given to
  // |SlaveConnectionManager::Init()|) and creates a second OS "pipe" between
  // the master and slave (returning the slave's handle).
  platform::ScopedPlatformHandle ConnectToMasterInternal(
      const ConnectionIdentifier& connection_id);

  ConnectionManager* connection_manager() const {
    return connection_manager_.get();
  }

  // These are all set on construction and reset by |ShutdownOnIOThread()|.
  embedder::ProcessType process_type_;
  util::RefPtr<platform::TaskRunner> delegate_thread_task_runner_;
  embedder::ProcessDelegate* process_delegate_;
  util::RefPtr<platform::TaskRunner> io_task_runner_;
  platform::PlatformHandleWatcher* io_watcher_;

  std::unique_ptr<ConnectionManager> connection_manager_;
  std::unique_ptr<ChannelManager> channel_manager_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(IPCSupport);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_IPC_SUPPORT_H_
