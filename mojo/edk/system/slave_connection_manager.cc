// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/slave_connection_manager.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/system/message_in_transit.h"

namespace mojo {
namespace system {

// SlaveConnectionManager ------------------------------------------------------

SlaveConnectionManager::SlaveConnectionManager(
    embedder::PlatformSupport* platform_support)
    : ConnectionManager(platform_support),
      slave_process_delegate_(),
      private_thread_("SlaveConnectionManagerPrivateThread"),
      awaiting_ack_type_(NOT_AWAITING_ACK),
      ack_result_(nullptr),
      ack_peer_process_identifier_(nullptr),
      ack_platform_handle_(nullptr),
      event_(false, false) {  // Auto-reset, not initially signalled.
}

SlaveConnectionManager::~SlaveConnectionManager() {
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!slave_process_delegate_);
  DCHECK(!private_thread_.message_loop());
  DCHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);
  DCHECK(!ack_result_);
  DCHECK(!ack_peer_process_identifier_);
  DCHECK(!ack_platform_handle_);
}

void SlaveConnectionManager::Init(
    scoped_refptr<base::TaskRunner> delegate_thread_task_runner,
    embedder::SlaveProcessDelegate* slave_process_delegate,
    embedder::ScopedPlatformHandle platform_handle) {
  DCHECK(delegate_thread_task_runner);
  DCHECK(slave_process_delegate);
  DCHECK(platform_handle.is_valid());
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!slave_process_delegate_);
  DCHECK(!private_thread_.message_loop());

  delegate_thread_task_runner_ = delegate_thread_task_runner;
  slave_process_delegate_ = slave_process_delegate;
  CHECK(private_thread_.StartWithOptions(
      base::Thread::Options(base::MessageLoop::TYPE_IO, 0)));
  private_thread_.message_loop()->PostTask(
      FROM_HERE,
      base::Bind(&SlaveConnectionManager::InitOnPrivateThread,
                 base::Unretained(this), base::Passed(&platform_handle)));
  event_.Wait();
}

void SlaveConnectionManager::Shutdown() {
  AssertNotOnPrivateThread();
  DCHECK(slave_process_delegate_);
  DCHECK(private_thread_.message_loop());

  // The |Stop()| will actually finish all posted tasks.
  private_thread_.message_loop()->PostTask(
      FROM_HERE, base::Bind(&SlaveConnectionManager::ShutdownOnPrivateThread,
                            base::Unretained(this)));
  private_thread_.Stop();
  slave_process_delegate_ = nullptr;
  delegate_thread_task_runner_ = nullptr;
}

bool SlaveConnectionManager::AllowConnect(
    const ConnectionIdentifier& connection_id) {
  AssertNotOnPrivateThread();

  MutexLocker locker(&mutex_);
  Result result = Result::FAILURE;
  private_thread_.message_loop()->PostTask(
      FROM_HERE,
      base::Bind(&SlaveConnectionManager::AllowConnectOnPrivateThread,
                 base::Unretained(this), connection_id, &result));
  event_.Wait();
  DCHECK(result == Result::FAILURE || result == Result::SUCCESS);
  return result == Result::SUCCESS;
}

bool SlaveConnectionManager::CancelConnect(
    const ConnectionIdentifier& connection_id) {
  AssertNotOnPrivateThread();

  MutexLocker locker(&mutex_);
  Result result = Result::FAILURE;
  private_thread_.message_loop()->PostTask(
      FROM_HERE,
      base::Bind(&SlaveConnectionManager::CancelConnectOnPrivateThread,
                 base::Unretained(this), connection_id, &result));
  event_.Wait();
  DCHECK(result == Result::FAILURE || result == Result::SUCCESS);
  return result == Result::SUCCESS;
}

ConnectionManager::Result SlaveConnectionManager::Connect(
    const ConnectionIdentifier& connection_id,
    ProcessIdentifier* peer_process_identifier,
    embedder::ScopedPlatformHandle* platform_handle) {
  AssertNotOnPrivateThread();

  MutexLocker locker(&mutex_);
  Result result = Result::FAILURE;
  private_thread_.message_loop()->PostTask(
      FROM_HERE, base::Bind(&SlaveConnectionManager::ConnectOnPrivateThread,
                            base::Unretained(this), connection_id, &result,
                            peer_process_identifier, platform_handle));
  event_.Wait();
  return result;
}

void SlaveConnectionManager::InitOnPrivateThread(
    embedder::ScopedPlatformHandle platform_handle) {
  AssertOnPrivateThread();

  raw_channel_ = RawChannel::Create(platform_handle.Pass());
  raw_channel_->Init(this);
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
  if (!raw_channel_->WriteMessage(make_scoped_ptr(new MessageInTransit(
          MessageInTransit::Type::CONNECTION_MANAGER,
          MessageInTransit::Subtype::CONNECTION_MANAGER_ALLOW_CONNECT,
          sizeof(connection_id), &connection_id)))) {
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
  if (!raw_channel_->WriteMessage(make_scoped_ptr(new MessageInTransit(
          MessageInTransit::Type::CONNECTION_MANAGER,
          MessageInTransit::Subtype::CONNECTION_MANAGER_CANCEL_CONNECT,
          sizeof(connection_id), &connection_id)))) {
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
    embedder::ScopedPlatformHandle* platform_handle) {
  DCHECK(result);
  DCHECK(platform_handle);
  DCHECK(!platform_handle->is_valid());  // Not technically wrong, but unlikely.
  AssertOnPrivateThread();
  // This should only posted (from another thread, to |private_thread_|) with
  // the lock held (until this thread triggers |event_|).
  DCHECK(!mutex_.TryLock());
  DCHECK_EQ(awaiting_ack_type_, NOT_AWAITING_ACK);

  DVLOG(1) << "Sending Connect: connection ID " << connection_id.ToString();
  if (!raw_channel_->WriteMessage(make_scoped_ptr(new MessageInTransit(
          MessageInTransit::Type::CONNECTION_MANAGER,
          MessageInTransit::Subtype::CONNECTION_MANAGER_CONNECT,
          sizeof(connection_id), &connection_id)))) {
    // Don't tear things down; possibly we'll still read some messages.
    *result = Result::FAILURE;
    platform_handle->reset();
    event_.Signal();
    return;
  }
  awaiting_ack_type_ = AWAITING_CONNECT_ACK;
  ack_result_ = result;
  ack_peer_process_identifier_ = peer_process_identifier;
  ack_platform_handle_ = platform_handle;
}

void SlaveConnectionManager::OnReadMessage(
    const MessageInTransit::View& message_view,
    embedder::ScopedPlatformHandleVectorPtr platform_handles) {
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
      DCHECK(!ack_platform_handle_);
    } else {
      // Success acks for "connect" always have a |ProcessIdentifier| as data.
      CHECK_EQ(num_bytes, sizeof(ProcessIdentifier));
      *ack_peer_process_identifier_ =
          *reinterpret_cast<const ProcessIdentifier*>(message_view.bytes());

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
          ack_platform_handle_->reset(platform_handles->at(0));
          platform_handles->at(0) = embedder::PlatformHandle();
          break;
        case MessageInTransit::Subtype::
            CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_REUSE_CONNECTION:
          DCHECK_EQ(num_platform_handles, 0u);
          *ack_result_ = Result::SUCCESS_CONNECT_REUSE_CONNECTION;
          ack_platform_handle_->reset();
          // TODO(vtl): FIXME -- currently, nothing should generate
          // SUCCESS_CONNECT_REUSE_CONNECTION.
          CHECK(false);
          break;
        default:
          CHECK(false);
      }
    }
  }

  awaiting_ack_type_ = NOT_AWAITING_ACK;
  ack_result_ = nullptr;
  ack_peer_process_identifier_ = nullptr;
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
  delegate_thread_task_runner_->PostTask(
      FROM_HERE, base::Bind(&embedder::SlaveProcessDelegate::OnMasterDisconnect,
                            base::Unretained(slave_process_delegate_)));
}

void SlaveConnectionManager::AssertNotOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|. (If not,
  // the subsequent |DCHECK_NE()| is invalid, since the current thread may not
  // have a message loop.)
  DCHECK(private_thread_.message_loop());
  DCHECK_NE(base::MessageLoop::current(), private_thread_.message_loop());
}

void SlaveConnectionManager::AssertOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|.
  DCHECK(private_thread_.message_loop());
  DCHECK_EQ(base::MessageLoop::current(), private_thread_.message_loop());
}

}  // namespace system
}  // namespace mojo
