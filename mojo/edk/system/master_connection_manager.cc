// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/master_connection_manager.h"

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/waitable_event.h"
#include "mojo/edk/embedder/master_process_delegate.h"
#include "mojo/edk/embedder/platform_channel_pair.h"
#include "mojo/edk/embedder/platform_handle_vector.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/transport_data.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

namespace {

const ProcessIdentifier kFirstSlaveProcessIdentifier = 2;

static_assert(kMasterProcessIdentifier != kInvalidProcessIdentifier,
              "Bad master process identifier");
static_assert(kFirstSlaveProcessIdentifier != kInvalidProcessIdentifier,
              "Bad first slave process identifier");
static_assert(kMasterProcessIdentifier != kFirstSlaveProcessIdentifier,
              "Master and first slave process identifiers are the same");

MessageInTransit::Subtype ConnectionManagerResultToMessageInTransitSubtype(
    ConnectionManager::Result result) {
  switch (result) {
    case ConnectionManager::Result::FAILURE:
      return MessageInTransit::Subtype::CONNECTION_MANAGER_ACK_FAILURE;
    case ConnectionManager::Result::SUCCESS:
      return MessageInTransit::Subtype::CONNECTION_MANAGER_ACK_SUCCESS;
    case ConnectionManager::Result::SUCCESS_CONNECT_SAME_PROCESS:
      return MessageInTransit::Subtype::
          CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_SAME_PROCESS;
    case ConnectionManager::Result::SUCCESS_CONNECT_NEW_CONNECTION:
      return MessageInTransit::Subtype::
          CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_NEW_CONNECTION;
    case ConnectionManager::Result::SUCCESS_CONNECT_REUSE_CONNECTION:
      return MessageInTransit::Subtype::
          CONNECTION_MANAGER_ACK_SUCCESS_CONNECT_REUSE_CONNECTION;
  }
  NOTREACHED();
  return MessageInTransit::Subtype::CONNECTION_MANAGER_ACK_FAILURE;
}

}  // namespace

// MasterConnectionManager::Helper ---------------------------------------------

// |MasterConnectionManager::Helper| is not thread-safe, and must only be used
// on its |owner_|'s private thread.
class MasterConnectionManager::Helper final : public RawChannel::Delegate {
 public:
  Helper(MasterConnectionManager* owner,
         ProcessIdentifier process_identifier,
         embedder::SlaveInfo slave_info,
         embedder::ScopedPlatformHandle platform_handle);
  ~Helper() override;

  void Init();
  embedder::SlaveInfo Shutdown();

 private:
  // |RawChannel::Delegate| methods:
  void OnReadMessage(
      const MessageInTransit::View& message_view,
      embedder::ScopedPlatformHandleVectorPtr platform_handles) override;
  void OnError(Error error) override;

  // Handles an error that's fatal to this object. Note that this probably
  // results in |Shutdown()| being called (in the nested context) and then this
  // object being destroyed.
  void FatalError();

  MasterConnectionManager* const owner_;
  const ProcessIdentifier process_identifier_;
  embedder::SlaveInfo const slave_info_;
  scoped_ptr<RawChannel> raw_channel_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Helper);
};

MasterConnectionManager::Helper::Helper(
    MasterConnectionManager* owner,
    ProcessIdentifier process_identifier,
    embedder::SlaveInfo slave_info,
    embedder::ScopedPlatformHandle platform_handle)
    : owner_(owner),
      process_identifier_(process_identifier),
      slave_info_(slave_info),
      raw_channel_(RawChannel::Create(platform_handle.Pass())) {
}

MasterConnectionManager::Helper::~Helper() {
  DCHECK(!raw_channel_);
}

void MasterConnectionManager::Helper::Init() {
  raw_channel_->Init(this);
}

embedder::SlaveInfo MasterConnectionManager::Helper::Shutdown() {
  raw_channel_->Shutdown();
  raw_channel_.reset();
  return slave_info_;
}

void MasterConnectionManager::Helper::OnReadMessage(
    const MessageInTransit::View& message_view,
    embedder::ScopedPlatformHandleVectorPtr platform_handles) {
  if (message_view.type() != MessageInTransit::Type::CONNECTION_MANAGER) {
    LOG(ERROR) << "Invalid message type " << message_view.type();
    FatalError();  // WARNING: This destroys us.
    return;
  }

  // Currently, all the messages simply have a |ConnectionIdentifier| as data.
  if (message_view.num_bytes() != sizeof(ConnectionIdentifier)) {
    LOG(ERROR) << "Invalid message size " << message_view.num_bytes();
    FatalError();  // WARNING: This destroys us.
    return;
  }

  // And none of them should have any platform handles attached.
  if (message_view.transport_data_buffer()) {
    LOG(ERROR) << "Invalid message with transport data";
    FatalError();  // WARNING: This destroys us.
    return;
  }

  const ConnectionIdentifier* connection_id =
      reinterpret_cast<const ConnectionIdentifier*>(message_view.bytes());
  Result result = Result::FAILURE;
  ProcessIdentifier peer_process_identifier = kInvalidProcessIdentifier;
  embedder::ScopedPlatformHandle platform_handle;
  uint32_t num_bytes = 0;
  const void* bytes = nullptr;
  switch (message_view.subtype()) {
    case MessageInTransit::Subtype::CONNECTION_MANAGER_ALLOW_CONNECT:
      result = owner_->AllowConnectImpl(process_identifier_, *connection_id)
                   ? Result::SUCCESS
                   : Result::FAILURE;
      break;
    case MessageInTransit::Subtype::CONNECTION_MANAGER_CANCEL_CONNECT:
      result = owner_->CancelConnectImpl(process_identifier_, *connection_id)
                   ? Result::SUCCESS
                   : Result::FAILURE;
      break;
    case MessageInTransit::Subtype::CONNECTION_MANAGER_CONNECT: {
      result = owner_->ConnectImpl(process_identifier_, *connection_id,
                                   &peer_process_identifier, &platform_handle);
      DCHECK_NE(result, Result::SUCCESS);
      // TODO(vtl): FIXME -- currently, nothing should generate
      // SUCCESS_CONNECT_REUSE_CONNECTION.
      CHECK_NE(result, Result::SUCCESS_CONNECT_REUSE_CONNECTION);
      // Success acks for "connect" have the peer process identifier as data
      // (and also a platform handle in the case of "new connection" -- handled
      // further below).
      if (result != Result::FAILURE) {
        num_bytes = static_cast<uint32_t>(sizeof(peer_process_identifier));
        bytes = &peer_process_identifier;
      }
      break;
    }
    default:
      LOG(ERROR) << "Invalid message subtype " << message_view.subtype();
      FatalError();  // WARNING: This destroys us.
      return;
  }

  scoped_ptr<MessageInTransit> response(new MessageInTransit(
      MessageInTransit::Type::CONNECTION_MANAGER_ACK,
      ConnectionManagerResultToMessageInTransitSubtype(result), num_bytes,
      bytes));

  if (result == Result::SUCCESS_CONNECT_NEW_CONNECTION) {
    DCHECK_EQ(message_view.subtype(),
              MessageInTransit::Subtype::CONNECTION_MANAGER_CONNECT);
    DCHECK(platform_handle.is_valid());
    embedder::ScopedPlatformHandleVectorPtr platform_handles(
        new embedder::PlatformHandleVector());
    platform_handles->push_back(platform_handle.release());
    response->SetTransportData(make_scoped_ptr(
        new TransportData(platform_handles.Pass(),
                          raw_channel_->GetSerializedPlatformHandleSize())));
  } else {
    DCHECK(!platform_handle.is_valid());
  }

  if (!raw_channel_->WriteMessage(response.Pass())) {
    LOG(ERROR) << "WriteMessage failed";
    FatalError();  // WARNING: This destroys us.
    return;
  }
}

void MasterConnectionManager::Helper::OnError(Error /*error*/) {
  // Every error (read or write) is fatal (for that particular connection). Read
  // errors are fatal since no more commands will be received from that
  // connection. Write errors are fatal since it is no longer possible to send
  // responses.
  FatalError();  // WARNING: This destroys us.
}

void MasterConnectionManager::Helper::FatalError() {
  owner_->OnError(process_identifier_);  // WARNING: This destroys us.
}

// MasterConnectionManager::PendingConnectionInfo ------------------------------

struct MasterConnectionManager::PendingConnectionInfo {
  // States:
  //   - This is created upon a first "allow connect" (with |first| set
  //     immediately). We then wait for a second "allow connect".
  //   - After the second "allow connect" (and |second| is set), we wait for
  //     "connects" from both |first| and |second|.
  //   - We may then receive "connect" from either |first| or |second|, at which
  //     which point it remains to wait for "connect" from the other.
  // I.e., the valid state transitions are:
  //   AWAITING_SECOND_ALLOW_CONNECT -> AWAITING_CONNECTS_FROM_BOTH
  //       -> {AWAITING_CONNECT_FROM_FIRST,AWAITING_CONNECT_FROM_SECOND}
  enum State {
    AWAITING_SECOND_ALLOW_CONNECT,
    AWAITING_CONNECTS_FROM_BOTH,
    AWAITING_CONNECT_FROM_FIRST,
    AWAITING_CONNECT_FROM_SECOND
  };

  explicit PendingConnectionInfo(ProcessIdentifier first)
      : state(AWAITING_SECOND_ALLOW_CONNECT),
        first(first),
        second(kInvalidProcessIdentifier) {
    DCHECK_NE(first, kInvalidProcessIdentifier);
  }
  ~PendingConnectionInfo() {}

  State state;

  ProcessIdentifier first;
  ProcessIdentifier second;

  // Valid in AWAITING_CONNECT_FROM_{FIRST, SECOND} states.
  embedder::ScopedPlatformHandle remaining_handle;
};

// MasterConnectionManager -----------------------------------------------------

MasterConnectionManager::MasterConnectionManager(
    embedder::PlatformSupport* platform_support)
    : ConnectionManager(platform_support),
      master_process_delegate_(),
      private_thread_("MasterConnectionManagerPrivateThread"),
      next_process_identifier_(kFirstSlaveProcessIdentifier) {
}

MasterConnectionManager::~MasterConnectionManager() {
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!master_process_delegate_);
  DCHECK(!private_thread_.message_loop());
  DCHECK(helpers_.empty());
  DCHECK(pending_connections_.empty());
}

void MasterConnectionManager::Init(
    scoped_refptr<base::TaskRunner> delegate_thread_task_runner,
    embedder::MasterProcessDelegate* master_process_delegate) {
  DCHECK(delegate_thread_task_runner);
  DCHECK(master_process_delegate);
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!master_process_delegate_);
  DCHECK(!private_thread_.message_loop());

  delegate_thread_task_runner_ = delegate_thread_task_runner;
  master_process_delegate_ = master_process_delegate;
  CHECK(private_thread_.StartWithOptions(
      base::Thread::Options(base::MessageLoop::TYPE_IO, 0)));
}

ProcessIdentifier MasterConnectionManager::AddSlave(
    embedder::SlaveInfo slave_info,
    embedder::ScopedPlatformHandle platform_handle) {
  // We don't really care if |slave_info| is non-null or not.
  DCHECK(platform_handle.is_valid());
  AssertNotOnPrivateThread();

  ProcessIdentifier slave_process_identifier;
  {
    MutexLocker locker(&mutex_);
    CHECK_NE(next_process_identifier_, kMasterProcessIdentifier);
    slave_process_identifier = next_process_identifier_;
    next_process_identifier_++;
  }

  // We have to wait for the task to be executed, in case someone calls
  // |AddSlave()| followed immediately by |Shutdown()|.
  base::WaitableEvent event(false, false);
  private_thread_.message_loop()->PostTask(
      FROM_HERE,
      base::Bind(&MasterConnectionManager::AddSlaveOnPrivateThread,
                 base::Unretained(this), base::Unretained(slave_info),
                 base::Passed(&platform_handle), slave_process_identifier,
                 base::Unretained(&event)));
  event.Wait();

  return slave_process_identifier;
}

ProcessIdentifier MasterConnectionManager::AddSlaveAndBootstrap(
    embedder::SlaveInfo slave_info,
    embedder::ScopedPlatformHandle platform_handle,
    const ConnectionIdentifier& connection_id) {
  ProcessIdentifier slave_process_identifier =
      AddSlave(slave_info, platform_handle.Pass());

  MutexLocker locker(&mutex_);
  DCHECK(pending_connections_.find(connection_id) ==
         pending_connections_.end());
  PendingConnectionInfo* info =
      new PendingConnectionInfo(kMasterProcessIdentifier);
  info->state = PendingConnectionInfo::AWAITING_CONNECTS_FROM_BOTH;
  info->second = slave_process_identifier;
  pending_connections_[connection_id] = info;

  return slave_process_identifier;
}

void MasterConnectionManager::Shutdown() {
  AssertNotOnPrivateThread();
  DCHECK(master_process_delegate_);
  DCHECK(private_thread_.message_loop());

  // The |Stop()| will actually finish all posted tasks.
  private_thread_.message_loop()->PostTask(
      FROM_HERE, base::Bind(&MasterConnectionManager::ShutdownOnPrivateThread,
                            base::Unretained(this)));
  private_thread_.Stop();
  DCHECK(helpers_.empty());
  DCHECK(pending_connections_.empty());
  master_process_delegate_ = nullptr;
  delegate_thread_task_runner_ = nullptr;
}

bool MasterConnectionManager::AllowConnect(
    const ConnectionIdentifier& connection_id) {
  AssertNotOnPrivateThread();
  return AllowConnectImpl(kMasterProcessIdentifier, connection_id);
}

bool MasterConnectionManager::CancelConnect(
    const ConnectionIdentifier& connection_id) {
  AssertNotOnPrivateThread();
  return CancelConnectImpl(kMasterProcessIdentifier, connection_id);
}

ConnectionManager::Result MasterConnectionManager::Connect(
    const ConnectionIdentifier& connection_id,
    ProcessIdentifier* peer_process_identifier,
    embedder::ScopedPlatformHandle* platform_handle) {
  return ConnectImpl(kMasterProcessIdentifier, connection_id,
                     peer_process_identifier, platform_handle);
}

bool MasterConnectionManager::AllowConnectImpl(
    ProcessIdentifier process_identifier,
    const ConnectionIdentifier& connection_id) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);

  MutexLocker locker(&mutex_);

  auto it = pending_connections_.find(connection_id);
  if (it == pending_connections_.end()) {
    pending_connections_[connection_id] =
        new PendingConnectionInfo(process_identifier);
    // TODO(vtl): Track process identifier -> pending connections also (so these
    // can be removed efficiently if that process disconnects).
    DVLOG(1) << "New pending connection ID " << connection_id.ToString()
             << ": AllowConnect() from first process identifier "
             << process_identifier;
    return true;
  }

  PendingConnectionInfo* info = it->second;
  if (info->state == PendingConnectionInfo::AWAITING_SECOND_ALLOW_CONNECT) {
    info->state = PendingConnectionInfo::AWAITING_CONNECTS_FROM_BOTH;
    info->second = process_identifier;
    DVLOG(1) << "Pending connection ID " << connection_id.ToString()
             << ": AllowConnect() from second process identifier "
             << process_identifier;
    return true;
  }

  // Someone's behaving badly, but we don't know who (it might not be the
  // caller).
  LOG(ERROR) << "AllowConnect() from process " << process_identifier
             << " for connection ID " << connection_id.ToString()
             << " already in state " << info->state;
  pending_connections_.erase(it);
  delete info;
  return false;
}

bool MasterConnectionManager::CancelConnectImpl(
    ProcessIdentifier process_identifier,
    const ConnectionIdentifier& connection_id) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);

  MutexLocker locker(&mutex_);

  auto it = pending_connections_.find(connection_id);
  if (it == pending_connections_.end()) {
    // Not necessarily the caller's fault, and not necessarily an error.
    DVLOG(1) << "CancelConnect() from process " << process_identifier
             << " for connection ID " << connection_id.ToString()
             << " which is not (or no longer) pending";
    return true;
  }

  PendingConnectionInfo* info = it->second;
  if (process_identifier != info->first && process_identifier != info->second) {
    LOG(ERROR) << "CancelConnect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " which is neither connectee";
    return false;
  }

  // Just erase it. The other side may also try to cancel, in which case it'll
  // "fail" in the first if statement above (we assume that connection IDs never
  // collide, so there's no need to carefully track both sides).
  pending_connections_.erase(it);
  delete info;
  return true;
}

ConnectionManager::Result MasterConnectionManager::ConnectImpl(
    ProcessIdentifier process_identifier,
    const ConnectionIdentifier& connection_id,
    ProcessIdentifier* peer_process_identifier,
    embedder::ScopedPlatformHandle* platform_handle) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);
  DCHECK(peer_process_identifier);
  DCHECK(platform_handle);
  DCHECK(!platform_handle->is_valid());  // Not technically wrong, but unlikely.

  MutexLocker locker(&mutex_);

  auto it = pending_connections_.find(connection_id);
  if (it == pending_connections_.end()) {
    // Not necessarily the caller's fault.
    LOG(ERROR) << "Connect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " which is not pending";
    return Result::FAILURE;
  }

  PendingConnectionInfo* info = it->second;
  if (info->state == PendingConnectionInfo::AWAITING_CONNECTS_FROM_BOTH) {
    DCHECK(!info->remaining_handle.is_valid());

    if (process_identifier == info->first) {
      info->state = PendingConnectionInfo::AWAITING_CONNECT_FROM_SECOND;
      *peer_process_identifier = info->second;
    } else if (process_identifier == info->second) {
      info->state = PendingConnectionInfo::AWAITING_CONNECT_FROM_FIRST;
      *peer_process_identifier = info->first;
    } else {
      LOG(ERROR) << "Connect() from process " << process_identifier
                 << " for connection ID " << connection_id.ToString()
                 << " which is neither connectee";
      return Result::FAILURE;
    }

    // TODO(vtl): FIXME -- add stuff for SUCCESS_CONNECT_REUSE_CONNECTION here.
    Result result = Result::FAILURE;
    if (info->first == info->second) {
      platform_handle->reset();
      DCHECK(!info->remaining_handle.is_valid());
      result = Result::SUCCESS_CONNECT_SAME_PROCESS;
    } else {
      embedder::PlatformChannelPair platform_channel_pair;
      *platform_handle = platform_channel_pair.PassServerHandle();
      DCHECK(platform_handle->is_valid());
      info->remaining_handle = platform_channel_pair.PassClientHandle();
      DCHECK(info->remaining_handle.is_valid());
      result = Result::SUCCESS_CONNECT_NEW_CONNECTION;
    }
    DVLOG(1) << "Connection ID " << connection_id.ToString()
             << ": first Connect() from process identifier "
             << process_identifier;
    return result;
  }

  ProcessIdentifier remaining_connectee;
  ProcessIdentifier peer;
  if (info->state == PendingConnectionInfo::AWAITING_CONNECT_FROM_FIRST) {
    remaining_connectee = info->first;
    peer = info->second;
  } else if (info->state ==
             PendingConnectionInfo::AWAITING_CONNECT_FROM_SECOND) {
    remaining_connectee = info->second;
    peer = info->first;
  } else {
    // Someone's behaving badly, but we don't know who (it might not be the
    // caller).
    LOG(ERROR) << "Connect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " in state " << info->state;
    pending_connections_.erase(it);
    delete info;
    return Result::FAILURE;
  }

  if (process_identifier != remaining_connectee) {
    LOG(ERROR) << "Connect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " which is not the remaining connectee";
    pending_connections_.erase(it);
    delete info;
    return Result::FAILURE;
  }

  *peer_process_identifier = peer;

  // TODO(vtl): FIXME -- add stuff for SUCCESS_CONNECT_REUSE_CONNECTION here.
  Result result = Result::FAILURE;
  if (info->first == info->second) {
    platform_handle->reset();
    DCHECK(!info->remaining_handle.is_valid());
    result = Result::SUCCESS_CONNECT_SAME_PROCESS;
  } else {
    *platform_handle = info->remaining_handle.Pass();
    DCHECK(platform_handle->is_valid());
    result = Result::SUCCESS_CONNECT_NEW_CONNECTION;
  }
  pending_connections_.erase(it);
  delete info;
  DVLOG(1) << "Connection ID " << connection_id.ToString()
           << ": second Connect() from process identifier "
           << process_identifier;
  return result;
}

void MasterConnectionManager::ShutdownOnPrivateThread() {
  AssertOnPrivateThread();

  if (!pending_connections_.empty()) {
    DVLOG(1) << "Shutting down with connections pending";
    for (auto& p : pending_connections_)
      delete p.second;
    pending_connections_.clear();
  }

  if (!helpers_.empty()) {
    DVLOG(1) << "Shutting down with slaves still connected";
    for (auto& p : helpers_) {
      embedder::SlaveInfo slave_info = p.second->Shutdown();
      delete p.second;
      CallOnSlaveDisconnect(slave_info);
    }
    helpers_.clear();
  }
}

void MasterConnectionManager::AddSlaveOnPrivateThread(
    embedder::SlaveInfo slave_info,
    embedder::ScopedPlatformHandle platform_handle,
    ProcessIdentifier slave_process_identifier,
    base::WaitableEvent* event) {
  DCHECK(platform_handle.is_valid());
  DCHECK(event);
  AssertOnPrivateThread();

  scoped_ptr<Helper> helper(new Helper(this, slave_process_identifier,
                                       slave_info, platform_handle.Pass()));
  helper->Init();

  DCHECK(helpers_.find(slave_process_identifier) == helpers_.end());
  helpers_[slave_process_identifier] = helper.release();

  DVLOG(1) << "Added slave process identifier " << slave_process_identifier;
  event->Signal();
}

void MasterConnectionManager::OnError(ProcessIdentifier process_identifier) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);
  AssertOnPrivateThread();

  auto it = helpers_.find(process_identifier);
  DCHECK(it != helpers_.end());
  Helper* helper = it->second;
  embedder::SlaveInfo slave_info = helper->Shutdown();
  helpers_.erase(it);
  delete helper;

  {
    MutexLocker locker(&mutex_);

    // TODO(vtl): This isn't very efficient.
    for (auto it = pending_connections_.begin();
         it != pending_connections_.end();) {
      if (it->second->first == process_identifier ||
          it->second->second == process_identifier) {
        auto it_to_erase = it;
        ++it;
        delete it_to_erase->second;
        pending_connections_.erase(it_to_erase);
      } else {
        ++it;
      }
    }
  }

  CallOnSlaveDisconnect(slave_info);
}

void MasterConnectionManager::CallOnSlaveDisconnect(
    embedder::SlaveInfo slave_info) {
  AssertOnPrivateThread();
  DCHECK(master_process_delegate_);
  delegate_thread_task_runner_->PostTask(
      FROM_HERE, base::Bind(&embedder::MasterProcessDelegate::OnSlaveDisconnect,
                            base::Unretained(master_process_delegate_),
                            base::Unretained(slave_info)));
}

void MasterConnectionManager::AssertNotOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|. (If not,
  // the subsequent |DCHECK_NE()| is invalid, since the current thread may not
  // have a message loop.)
  DCHECK(private_thread_.message_loop());
  DCHECK_NE(base::MessageLoop::current(), private_thread_.message_loop());
}

void MasterConnectionManager::AssertOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|.
  DCHECK(private_thread_.message_loop());
  DCHECK_EQ(base::MessageLoop::current(), private_thread_.message_loop());
}

}  // namespace system
}  // namespace mojo
