// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MASTER_CONNECTION_MANAGER_H_
#define MOJO_EDK_SYSTEM_MASTER_CONNECTION_MANAGER_H_

#include <stdint.h>

#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "base/threading/thread.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/system/connection_manager.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace base {
class TaskRunner;
class WaitableEvent;
}

namespace mojo {

namespace embedder {
class MasterProcessDelegate;
using SlaveInfo = void*;
}

namespace system {

// The |ConnectionManager| implementation for the master process.
//
// This class is thread-safe (except that no public methods may be called from
// its internal, private thread), with condition that |Init()| be called before
// anything else and |Shutdown()| be called before destruction (and no other
// public methods may be called during/after |Shutdown()|).
class MOJO_SYSTEM_IMPL_EXPORT MasterConnectionManager final
    : public ConnectionManager {
 public:
  // Note: None of the public methods may be called from |private_thread_|.

  // |platform_support| must be valid and remain alive until after |Shutdown()|
  // has completed.
  explicit MasterConnectionManager(embedder::PlatformSupport* platform_support);
  ~MasterConnectionManager() override;

  // No other methods may be called until after this has been called.
  // |delegate_thread_task_runner| should be the task runner for the "delegate
  // thread", on which |master_process_delegate|'s methods will be called. Both
  // must stay alive at least until after |Shutdown()| has been called.
  void Init(scoped_refptr<base::TaskRunner> delegate_thread_task_runner,
            embedder::MasterProcessDelegate* master_process_delegate)
      MOJO_NOT_THREAD_SAFE;

  // Adds a slave process and sets up/tracks a connection to that slave (using
  // |platform_handle|). |slave_info| is used by the caller/implementation of
  // |embedder::MasterProcessDelegate| to track this process. It must remain
  // alive until the delegate's |OnSlaveDisconnect()| is called with it as the
  // argument. |OnSlaveDisconnect()| will always be called for each slave,
  // assuming proper shutdown. Returns the process identifier for the
  // newly-added slave.
  ProcessIdentifier AddSlave(embedder::SlaveInfo slave_info,
                             embedder::ScopedPlatformHandle platform_handle);

  // Like |AddSlave()|, but allows a connection to be bootstrapped: both the
  // master and slave may call |Connect()| with |connection_id| immediately (as
  // if both had already called |AllowConnect()|). |connection_id| must be
  // unique (i.e., not previously used).
  // TODO(vtl): Is |AddSlave()| really needed? (It's probably mostly useful for
  // tests.)
  ProcessIdentifier AddSlaveAndBootstrap(
      embedder::SlaveInfo slave_info,
      embedder::ScopedPlatformHandle platform_handle,
      const ConnectionIdentifier& connection_id);

  // |ConnectionManager| methods:
  void Shutdown() override MOJO_NOT_THREAD_SAFE;
  bool AllowConnect(const ConnectionIdentifier& connection_id) override;
  bool CancelConnect(const ConnectionIdentifier& connection_id) override;
  Result Connect(const ConnectionIdentifier& connection_id,
                 ProcessIdentifier* peer_process_identifier,
                 embedder::ScopedPlatformHandle* platform_handle) override;

 private:
  class Helper;

  // These should be thread-safe and may be called on any thread, including
  // |private_thread_|:
  bool AllowConnectImpl(ProcessIdentifier process_identifier,
                        const ConnectionIdentifier& connection_id);
  bool CancelConnectImpl(ProcessIdentifier process_identifier,
                         const ConnectionIdentifier& connection_id);
  Result ConnectImpl(ProcessIdentifier process_identifier,
                     const ConnectionIdentifier& connection_id,
                     ProcessIdentifier* peer_process_identifier,
                     embedder::ScopedPlatformHandle* platform_handle);

  // These should only be called on |private_thread_|:
  void ShutdownOnPrivateThread() MOJO_NOT_THREAD_SAFE;
  // Signals |*event| on completion.
  void AddSlaveOnPrivateThread(embedder::SlaveInfo slave_info,
                               embedder::ScopedPlatformHandle platform_handle,
                               ProcessIdentifier slave_process_identifier,
                               base::WaitableEvent* event);
  // Called by |Helper::OnError()|.
  void OnError(ProcessIdentifier process_identifier);
  // Posts a call to |master_process_delegate_->OnSlaveDisconnect()|.
  void CallOnSlaveDisconnect(embedder::SlaveInfo slave_info);

  // Asserts that the current thread is *not* |private_thread_| (no-op if
  // DCHECKs are not enabled). This should only be called while
  // |private_thread_| is alive (i.e., after |Init()| but before |Shutdown()|).
  void AssertNotOnPrivateThread() const;

  // Asserts that the current thread is |private_thread_| (no-op if DCHECKs are
  // not enabled). This should only be called while |private_thread_| is alive
  // (i.e., after |Init()| but before |Shutdown()|).
  void AssertOnPrivateThread() const;

  // These are set in |Init()| before |private_thread_| exists and only cleared
  // in |Shutdown()| after |private_thread_| is dead. Thus it's safe to "use" on
  // |private_thread_|. (Note that |master_process_delegate_| may only be called
  // from the delegate thread.)
  scoped_refptr<base::TaskRunner> delegate_thread_task_runner_;
  embedder::MasterProcessDelegate* master_process_delegate_;

  // This is a private I/O thread on which this class does the bulk of its work.
  // It is started in |Init()| and terminated in |Shutdown()|.
  base::Thread private_thread_;

  // The following members are only accessed on |private_thread_|:
  base::hash_map<ProcessIdentifier, Helper*> helpers_;  // Owns its values.

  // Note: |mutex_| is not needed in the constructor, |Init()|,
  // |Shutdown()|/|ShutdownOnPrivateThread()|, or the destructor
  Mutex mutex_;

  ProcessIdentifier next_process_identifier_ MOJO_GUARDED_BY(mutex_);

  struct PendingConnectionInfo;
  base::hash_map<ConnectionIdentifier, PendingConnectionInfo*>
      pending_connections_ MOJO_GUARDED_BY(mutex_);  // Owns its values.

  MOJO_DISALLOW_COPY_AND_ASSIGN(MasterConnectionManager);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MASTER_CONNECTION_MANAGER_H_
