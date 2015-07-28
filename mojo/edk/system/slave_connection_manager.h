// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_SLAVE_CONNECTION_MANAGER_H_
#define MOJO_EDK_SYSTEM_SLAVE_CONNECTION_MANAGER_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "mojo/edk/embedder/scoped_platform_handle.h"
#include "mojo/edk/embedder/slave_process_delegate.h"
#include "mojo/edk/system/connection_manager.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace base {
class TaskRunner;
}

namespace mojo {

namespace embedder {
class SlaveProcessDelegate;
}

namespace system {

// The |ConnectionManager| implementation for slave processes.
//
// This class is thread-safe (except that no public methods may be called from
// its internal, private thread), with condition that |Init()| be called before
// anything else and |Shutdown()| be called before destruction (and no other
// public methods may be called during/after |Shutdown()|).
class MOJO_SYSTEM_IMPL_EXPORT SlaveConnectionManager final
    : public ConnectionManager,
      public RawChannel::Delegate {
 public:
  // Note: None of the public methods may be called from |private_thread_|.

  // |platform_support| must be valid and remain alive until after |Shutdown()|
  // has completed.
  explicit SlaveConnectionManager(embedder::PlatformSupport* platform_support);
  ~SlaveConnectionManager() override;

  // No other methods may be called until after this has been called.
  // |delegate_thread_task_runner| should be the task runner for the "delegate
  // thread", on which |slave_process_delegate|'s methods will be called. Both
  // must stay alive at least until after |Shutdown()| has been called.
  void Init(scoped_refptr<base::TaskRunner> delegate_thread_task_runner,
            embedder::SlaveProcessDelegate* slave_process_delegate,
            embedder::ScopedPlatformHandle platform_handle);

  // |ConnectionManager| methods:
  void Shutdown() override;
  bool AllowConnect(const ConnectionIdentifier& connection_id) override;
  bool CancelConnect(const ConnectionIdentifier& connection_id) override;
  Result Connect(const ConnectionIdentifier& connection_id,
                 ProcessIdentifier* peer_process_identifier,
                 embedder::ScopedPlatformHandle* platform_handle) override;

 private:
  // These should only be called on |private_thread_|:
  void InitOnPrivateThread(embedder::ScopedPlatformHandle platform_handle);
  void ShutdownOnPrivateThread();
  void AllowConnectOnPrivateThread(const ConnectionIdentifier& connection_id,
                                   Result* result);
  void CancelConnectOnPrivateThread(const ConnectionIdentifier& connection_id,
                                    Result* result);
  void ConnectOnPrivateThread(const ConnectionIdentifier& connection_id,
                              Result* result,
                              ProcessIdentifier* peer_process_identifier,
                              embedder::ScopedPlatformHandle* platform_handle);

  // |RawChannel::Delegate| methods (only called on |private_thread_|):
  void OnReadMessage(
      const MessageInTransit::View& message_view,
      embedder::ScopedPlatformHandleVectorPtr platform_handles) override;
  void OnError(Error error) override;

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
  // |private_thread_|. (Note that |slave_process_delegate_| may only be called
  // from the delegate thread.)
  scoped_refptr<base::TaskRunner> delegate_thread_task_runner_;
  embedder::SlaveProcessDelegate* slave_process_delegate_;

  // This is a private I/O thread on which this class does the bulk of its work.
  // It is started in |Init()| and terminated in |Shutdown()|.
  // TODO(vtl): This isn't really necessary.
  base::Thread private_thread_;

  // Only accessed on |private_thread_|:
  scoped_ptr<RawChannel> raw_channel_;
  enum AwaitingAckType {
    NOT_AWAITING_ACK,
    AWAITING_ACCEPT_CONNECT_ACK,
    AWAITING_CANCEL_CONNECT_ACK,
    AWAITING_CONNECT_ACK
  };
  AwaitingAckType awaiting_ack_type_;
  Result* ack_result_;
  // Used only when waiting for the ack to "connect":
  ProcessIdentifier* ack_peer_process_identifier_;
  embedder::ScopedPlatformHandle* ack_platform_handle_;

  // The (synchronous) |ConnectionManager| methods are implemented in the
  // following way (T is any thread other than |private_thread_|):
  //
  // On thread T:
  //  1. |F()| is called, where F is one of the |ConnectionManager| methods.
  //  2. |lock_| is acquired.
  //  3. |FImpl()| is posted to |private_thread_|.
  //  4. |event_| is waited on (while holding |lock_|!).
  //
  // On |private_thread_| (all with |lock_| held!):
  //  4.1. |FImpl()| is executed, writes an "F" message to |raw_channel_|, and
  //       sets |awaiting_ack_type_| appropriately (it must not be "set"
  //       before).
  //  4.2. [Control returns to |private_thread_|'s message loop.]
  //  4.3. Eventually, |raw_channel_| calls |OnReadMessage()| with a message,
  //       which must be response (|awaiting_ack_type_| must still be set).
  //  4.4. |*ack_result_| and possibly |*ack_platform_handle_| are written to.
  //       |awaiting_ack_type_| is "unset".
  //  4.5. |event_| is triggered.
  //
  // Back on thread T:
  //  6. |lock_| is released.
  //  7. [Return from |F()|.]
  //
  // TODO(vtl): This is all a hack. It'd really suffice to have a version of
  // |RawChannel| with fully synchronous reading and writing.
  Mutex mutex_;
  base::WaitableEvent event_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SlaveConnectionManager);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_SLAVE_CONNECTION_MANAGER_H_
