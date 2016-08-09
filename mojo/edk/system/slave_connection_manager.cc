// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/slave_connection_manager.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/platform/io_thread.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/thread.h"
#include "mojo/edk/system/connection_manager_messages.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/util/make_unique.h"

using mojo::platform::PlatformHandle;
using mojo::platform::PlatformHandleWatcher;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::platform::Thread;
using mojo::util::MakeUnique;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// SlaveConnectionManager ------------------------------------------------------

SlaveConnectionManager::SlaveConnectionManager(
    embedder::PlatformSupport* platform_support)
    : ConnectionManager(platform_support),
      slave_process_delegate_(nullptr),
      private_thread_platform_handle_watcher_(nullptr),
      awaiting_ack_type_(NOT_AWAITING_ACK),
      ack_result_(nullptr),
      ack_peer_process_identifier_(nullptr),
      ack_is_first_(nullptr),
      ack_platform_handle_(nullptr) {}

SlaveConnectionManager::~SlaveConnectionManager() {
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!slave_process_delegate_);
  DCHECK(!private_thread_);
  DCHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);
  DCHECK(!ack_result_);
  DCHECK(!ack_peer_process_identifier_);
  DCHECK(!ack_is_first_);
  DCHECK(!ack_platform_handle_);
}

void SlaveConnectionManager::Init(
    RefPtr<TaskRunner>&& delegate_thread_task_runner,
    embedder::SlaveProcessDelegate* slave_process_delegate,
    ScopedPlatformHandle platform_handle) {
  DCHECK(delegate_thread_task_runner);
  DCHECK(slave_process_delegate);
  DCHECK(platform_handle.is_valid());
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!slave_process_delegate_);
  DCHECK(!private_thread_);

  delegate_thread_task_runner_ = std::move(delegate_thread_task_runner);
  slave_process_delegate_ = slave_process_delegate;
  private_thread_ = platform::CreateAndStartIOThread(
      &private_thread_task_runner_, &private_thread_platform_handle_watcher_);
  // TODO(vtl): With C++14 lambda captures, we'll be able to move
  // |platform_handle|.
  auto raw_platform_handle = platform_handle.release();
  private_thread_task_runner_->PostTask([this, raw_platform_handle]() {
    InitOnPrivateThread(
        ScopedPlatformHandle(PlatformHandle(raw_platform_handle)));
  });
  event_.Wait();
}

void SlaveConnectionManager::Shutdown() {
  AssertNotOnPrivateThread();
  DCHECK(slave_process_delegate_);
  DCHECK(private_thread_);

  // The |Stop()| will actually finish all posted tasks.
  private_thread_task_runner_->PostTask(
      [this]() { ShutdownOnPrivateThread(); });
  private_thread_->Stop();
  private_thread_.reset();
  private_thread_task_runner_ = nullptr;
  private_thread_platform_handle_watcher_ = nullptr;
  slave_process_delegate_ = nullptr;
  delegate_thread_task_runner_ = nullptr;
}

bool SlaveConnectionManager::AllowConnect(
    const ConnectionIdentifier& connection_id) {
  AssertNotOnPrivateThread();

  MutexLocker locker(&mutex_);
  Result result = Result::FAILURE;
  private_thread_task_runner_->PostTask([this, &connection_id, &result]() {
    AllowConnectOnPrivateThread(connection_id, &result);
  });
  event_.Wait();
  DCHECK(result == Result::FAILURE || result == Result::SUCCESS);
  return result == Result::SUCCESS;
}

bool SlaveConnectionManager::CancelConnect(
    const ConnectionIdentifier& connection_id) {
  AssertNotOnPrivateThread();

  MutexLocker locker(&mutex_);
  Result result = Result::FAILURE;
  private_thread_task_runner_->PostTask([this, &connection_id, &result]() {
    CancelConnectOnPrivateThread(connection_id, &result);
  });
  event_.Wait();
  DCHECK(result == Result::FAILURE || result == Result::SUCCESS);
  return result == Result::SUCCESS;
}

ConnectionManager::Result SlaveConnectionManager::Connect(
    const ConnectionIdentifier& connection_id,
    ProcessIdentifier* peer_process_identifier,
    bool* is_first,
    ScopedPlatformHandle* platform_handle) {
  AssertNotOnPrivateThread();
  DCHECK(peer_process_identifier);
  DCHECK(is_first);
  DCHECK(platform_handle);
  DCHECK(!platform_handle->is_valid());  // Not technically wrong, but unlikely.

  MutexLocker locker(&mutex_);
  Result result = Result::FAILURE;
  private_thread_task_runner_->PostTask([this, &connection_id, &result,
                                         peer_process_identifier, is_first,
                                         platform_handle]() {
    ConnectOnPrivateThread(connection_id, &result, peer_process_identifier,
                           is_first, platform_handle);
  });
  event_.Wait();
  return result;
}

void SlaveConnectionManager::InitOnPrivateThread(
    ScopedPlatformHandle platform_handle) {
  AssertOnPrivateThread();

  raw_channel_ = RawChannel::Create(platform_handle.Pass());
  raw_channel_->Init(private_thread_task_runner_.Clone(),
                     private_thread_platform_handle_watcher_, this);
  event_.Signal();
}

void SlaveConnectionManager::ShutdownOnPrivateThread() {
  AssertOnPrivateThread();

  CHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);
  if (raw_channel_) {
    raw_channel_->Shutdown();
    raw_channel_.reset();
  }
}

void SlaveConnectionManager::AllowConnectOnPrivateThread(
    const ConnectionIdentifier& connection_id,
    Result* result) {
  DCHECK(result);
  AssertOnPrivateThread();
  // This should only posted (from another thread, to |private_thread_|) with
  // the lock held (until this thread triggers |event_|).
  DCHECK(!mutex_.TryLock());
  DCHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);

  DVLOG(1) << "Sending AllowConnect: connection ID "
           << connection_id.ToString();
  if (!raw_channel_->WriteMessage(MakeUnique<MessageInTransit>(
          MessageInTransit::Type::CONNECTION_MANAGER,
          MessageInTransit::Subtype::CONNECTION_MANAGER_ALLOW_CONNECT,
          sizeof(connection_id), &connection_id))) {
    // Don't tear things down; possibly we'll still read some messages.
    *result = Result::FAILURE;
    event_.Signal();
    return;
  }
  awaiting_ack_type_ = AWAITING_ACCEPT_CONNECT_ACK;
  ack_result_ = result;
}

void SlaveConnectionManager::CancelConnectOnPrivateThread(
    const ConnectionIdentifier& connection_id,
    Result* result) {
  DCHECK(result);
  AssertOnPrivateThread();
  // This should only posted (from another thread, to |private_thread_|) with
  // the lock held (until this thread triggers |event_|).
  DCHECK(!mutex_.TryLock());
  DCHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);

  DVLOG(1) << "Sending CancelConnect: connection ID "
           << connection_id.ToString();
  if (!raw_channel_->WriteMessage(MakeUnique<MessageInTransit>(
          MessageInTransit::Type::CONNECTION_MANAGER,
          MessageInTransit::Subtype::CONNECTION_MANAGER_CANCEL_CONNECT,
          sizeof(connection_id), &connection_id))) {
    // Don't tear things down; possibly we'll still read some messages.
    *result = Result::FAILURE;
    event_.Signal();
    return;
  }
  awaiting_ack_type_ = AWAITING_CANCEL_CONNECT_ACK;
  ack_result_ = result;
}

void SlaveConnectionManager::ConnectOnPrivateThread(
    const ConnectionIdentifier& connection_id,
    Result* result,
    ProcessIdentifier* peer_process_identifier,
    bool* is_first,
    ScopedPlatformHandle* platform_handle) {
  DCHECK(result);
  AssertOnPrivateThread();
  // This should only posted (from another thread, to |private_thread_|) with
  // the lock held (until this thread triggers |event_|).
  DCHECK(!mutex_.TryLock());
  DCHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);

  DVLOG(1) << "Sending Connect: connection ID " << connection_id.ToString();
  if (!raw_channel_->WriteMessage(MakeUnique<MessageInTransit>(
          MessageInTransit::Type::CONNECTION_MANAGER,
          MessageInTransit::Subtype::CONNECTION_MANAGER_CONNECT,
          sizeof(connection_id), &connection_id))) {
    // Don't tear things down; possibly we'll still read some messages.
    *result = Result::FAILURE;
    platform_handle->reset();
    event_.Signal();
    return;
  }
  awaiting_ack_type_ = AWAITING_CONNECT_ACK;
  ack_result_ = result;
  ack_peer_process_identifier_ = peer_process_identifier;
  ack_is_first_ = is_first;
  ack_platform_handle_ = platform_handle;
}

void SlaveConnectionManager::OnReadMessage(
    const MessageInTransit::View& message_view,
    std::unique_ptr<std::vector<ScopedPlatformHandle>> platform_handles) {
  AssertOnPrivateThread();

  // Set |*ack_result_| to failure by default.
  *ack_result_ = Result::FAILURE;

  // Note: Since we should be able to trust the master, simply crash (i.e.,
  // |CHECK()|-fail) if it sends us something invalid.

  // Unsolicited message.
  CHECK_NE(awaiting_ack_type_, NOT_AWAITING_ACK);
  // Bad message type.
  CHECK_EQ(message_view.type(), MessageInTransit::Type::CONNECTION_MANAGER_ACK);

  size_t num_bytes = message_view.num_bytes();
  size_t num_platform_handles = platform_handles ? platform_handles->size() : 0;

  if (message_view.subtype() ==
      MessageInTransit::Subtype::CONNECTION_MANAGER_ACK_FAILURE) {
    // Failure acks never have any contents.
    DCHECK_EQ(num_bytes, 0u);
    DCHECK_EQ(num_platform_handles, 0u);
    // Leave |*ack_result_| as failure.
  } else {
    if (awaiting_ack_type_ != AWAITING_CONNECT_ACK) {
      // In the non-"connect" case, there's only one type of success ack, which
      // never has any contents.
      CHECK_EQ(message_view.subtype(),
               MessageInTransit::Subtype::CONNECTION_MANAGER_ACK_SUCCESS);
      DCHECK_EQ(num_bytes, 0u);
      DCHECK_EQ(num_platform_handles, 0u);
      *ack_result_ = Result::SUCCESS;
      DCHECK(!ack_peer_process_identifier_);
      DCHECK(!ack_is_first_);
      DCHECK(!ack_platform_handle_);
    } else {
      // Success acks for "connect" always have a
      // |ConnectionManagerAckSuccessConnectData| as data.
      CHECK_EQ(num_bytes, sizeof(ConnectionManagerAckSuccessConnectData));
      const ConnectionManagerAckSuccessConnectData& data =
          *static_cast<const ConnectionManagerAckSuccessConnectData*>(
              message_view.bytes());
      *ack_peer_process_identifier_ = data.peer_process_identifier;
      *ack_is_first_ = data.is_first;

      switch (message_view.subtype()) {
        case MessageInTransit::Subtype::
            CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_SAME_PROCESS:
          DCHECK_EQ(num_platform_handles, 0u);
          *ack_result_ = Result::SUCCESS_CONNECT_SAME_PROCESS;
          ack_platform_handle_->reset();
          break;
        case MessageInTransit::Subtype::
            CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_NEW_CONNECTION:
          CHECK_EQ(num_platform_handles, 1u);
          *ack_result_ = Result::SUCCESS_CONNECT_NEW_CONNECTION;
          *ack_platform_handle_ = std::move(platform_handles->at(0));
          break;
        case MessageInTransit::Subtype::
            CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_REUSE_CONNECTION:
          DCHECK_EQ(num_platform_handles, 0u);
          *ack_result_ = Result::SUCCESS_CONNECT_REUSE_CONNECTION;
          ack_platform_handle_->reset();
          break;
        default:
          CHECK(false);
      }
    }
  }

  awaiting_ack_type_ = NOT_AWAITING_ACK;
  ack_result_ = nullptr;
  ack_peer_process_identifier_ = nullptr;
  ack_is_first_ = nullptr;
  ack_platform_handle_ = nullptr;
  event_.Signal();
}

void SlaveConnectionManager::OnError(Error error) {
  AssertOnPrivateThread();

  // Ignore write errors, since we may still have some messages to read.
  if (error == RawChannel::Delegate::ERROR_WRITE)
    return;

  raw_channel_->Shutdown();
  raw_channel_.reset();

  DCHECK(slave_process_delegate_);
  // TODO(vtl): With C++14 lambda captures, we'll be able to avoid this
  // nonsense.
  auto slave_process_delegate = slave_process_delegate_;
  delegate_thread_task_runner_->PostTask([slave_process_delegate]() {
    slave_process_delegate->OnMasterDisconnect();
  });
}

void SlaveConnectionManager::AssertNotOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|.
  DCHECK(!private_thread_task_runner_->RunsTasksOnCurrentThread());
}

void SlaveConnectionManager::AssertOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|.
  DCHECK(private_thread_task_runner_->RunsTasksOnCurrentThread());
}

}  // namespace system
}  // namespace mojo
