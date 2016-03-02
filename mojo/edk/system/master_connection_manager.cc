// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/master_connection_manager.h"

#include <memory>
#include <unordered_map>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/embedder/master_process_delegate.h"
#include "mojo/edk/platform/io_thread.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/thread.h"
#include "mojo/edk/system/connection_manager_messages.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/transport_data.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::platform::PlatformHandle;
using mojo::platform::PlatformHandleWatcher;
using mojo::platform::PlatformPipe;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::platform::Thread;
using mojo::util::AutoResetWaitableEvent;
using mojo::util::MakeUnique;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

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
         ScopedPlatformHandle platform_handle);
  ~Helper() override;

  void Init(RefPtr<TaskRunner>&& task_runner,
            PlatformHandleWatcher* platform_handle_watcher);
  embedder::SlaveInfo Shutdown();

 private:
  // |RawChannel::Delegate| methods:
  void OnReadMessage(const MessageInTransit::View& message_view,
                     std::unique_ptr<std::vector<ScopedPlatformHandle>>
                         platform_handles) override;
  void OnError(Error error) override;

  // Handles an error that's fatal to this object. Note that this probably
  // results in |Shutdown()| being called (in the nested context) and then this
  // object being destroyed.
  void FatalError();

  MasterConnectionManager* const owner_;
  const ProcessIdentifier process_identifier_;
  embedder::SlaveInfo const slave_info_;
  std::unique_ptr<RawChannel> raw_channel_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Helper);
};

MasterConnectionManager::Helper::Helper(MasterConnectionManager* owner,
                                        ProcessIdentifier process_identifier,
                                        embedder::SlaveInfo slave_info,
                                        ScopedPlatformHandle platform_handle)
    : owner_(owner),
      process_identifier_(process_identifier),
      slave_info_(slave_info),
      raw_channel_(RawChannel::Create(platform_handle.Pass())) {}

MasterConnectionManager::Helper::~Helper() {
  DCHECK(!raw_channel_);
}

void MasterConnectionManager::Helper::Init(
    RefPtr<TaskRunner>&& task_runner,
    PlatformHandleWatcher* platform_handle_watcher) {
  raw_channel_->Init(std::move(task_runner), platform_handle_watcher, this);
}

embedder::SlaveInfo MasterConnectionManager::Helper::Shutdown() {
  raw_channel_->Shutdown();
  raw_channel_.reset();
  return slave_info_;
}

void MasterConnectionManager::Helper::OnReadMessage(
    const MessageInTransit::View& message_view,
    std::unique_ptr<std::vector<ScopedPlatformHandle>> platform_handles) {
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
  // Note: It's important to fully zero-initialize |data|, including padding,
  // since it'll be sent to another process.
  ConnectionManagerAckSuccessConnectData data = {};
  ScopedPlatformHandle platform_handle;
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
                                   &data.peer_process_identifier,
                                   &data.is_first, &platform_handle);
      DCHECK_NE(result, Result::SUCCESS);
      // Success acks for "connect" have the peer process identifier as data
      // (and also a platform handle in the case of "new connection" -- handled
      // further below).
      if (result != Result::FAILURE) {
        num_bytes = static_cast<uint32_t>(sizeof(data));
        bytes = &data;
      }
      break;
    }
    default:
      LOG(ERROR) << "Invalid message subtype " << message_view.subtype();
      FatalError();  // WARNING: This destroys us.
      return;
  }

  std::unique_ptr<MessageInTransit> response(new MessageInTransit(
      MessageInTransit::Type::CONNECTION_MANAGER_ACK,
      ConnectionManagerResultToMessageInTransitSubtype(result), num_bytes,
      bytes));

  if (result == Result::SUCCESS_CONNECT_NEW_CONNECTION) {
    DCHECK_EQ(message_view.subtype(),
              MessageInTransit::Subtype::CONNECTION_MANAGER_CONNECT);
    DCHECK(platform_handle.is_valid());
    auto platform_handles = MakeUnique<std::vector<ScopedPlatformHandle>>();
    platform_handles->push_back(std::move(platform_handle));
    response->SetTransportData(MakeUnique<TransportData>(
        std::move(platform_handles),
        raw_channel_->GetSerializedPlatformHandleSize()));
  } else {
    DCHECK(!platform_handle.is_valid());
  }

  if (!raw_channel_->WriteMessage(std::move(response))) {
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

// MasterConnectionManager::PendingConnectInfo ---------------------------------

struct MasterConnectionManager::PendingConnectInfo {
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
  enum class State {
    AWAITING_SECOND_ALLOW_CONNECT,
    AWAITING_CONNECTS_FROM_BOTH,
    AWAITING_CONNECT_FROM_FIRST,
    AWAITING_CONNECT_FROM_SECOND
  };

  explicit PendingConnectInfo(ProcessIdentifier first)
      : state(State::AWAITING_SECOND_ALLOW_CONNECT),
        first(first),
        second(kInvalidProcessIdentifier) {
    DCHECK_NE(first, kInvalidProcessIdentifier);
  }
  ~PendingConnectInfo() {}

  State state;

  ProcessIdentifier first;
  ProcessIdentifier second;
};

// MasterConnectionManager::ProcessConnections ---------------------------------

class MasterConnectionManager::ProcessConnections {
 public:
  enum class ConnectionStatus { NONE, PENDING, RUNNING };

  ProcessConnections() {}
  ~ProcessConnections() {
    // TODO(vtl): Log a warning if there are connections pending? (This might be
    // very spammy, since the |MasterConnectionManager| may have many
    // |ProcessConnections|.
    for (auto& p : process_connections_)
      p.second.CloseIfNecessary();
  }

  // If |pending_platform_handle| is non-null and the status is |PENDING| this
  // will "return"/pass the stored pending platform handle. Warning: In that
  // case, this has the side effect of changing the state to |RUNNING|.
  ConnectionStatus GetConnectionStatus(
      ProcessIdentifier to_process_identifier,
      ScopedPlatformHandle* pending_platform_handle) {
    DCHECK(!pending_platform_handle || !pending_platform_handle->is_valid());

    auto it = process_connections_.find(to_process_identifier);
    if (it == process_connections_.end())
      return ConnectionStatus::NONE;
    if (!it->second.is_valid())
      return ConnectionStatus::RUNNING;
    // Pending:
    if (pending_platform_handle) {
      pending_platform_handle->reset(it->second);
      it->second = PlatformHandle();
    }
    return ConnectionStatus::PENDING;
  }

  void AddConnection(ProcessIdentifier to_process_identifier,
                     ConnectionStatus status,
                     ScopedPlatformHandle pending_platform_handle) {
    DCHECK(process_connections_.find(to_process_identifier) ==
           process_connections_.end());

    if (status == ConnectionStatus::RUNNING) {
      DCHECK(!pending_platform_handle.is_valid());
      process_connections_[to_process_identifier] = PlatformHandle();
    } else if (status == ConnectionStatus::PENDING) {
      DCHECK(pending_platform_handle.is_valid());
      process_connections_[to_process_identifier] =
          pending_platform_handle.release();
    } else {
      NOTREACHED();
    }
  }

 private:
  // TODO(vtl): Make |second| |ScopedPlatformHandle|s.
  std::unordered_map<ProcessIdentifier, PlatformHandle>
      process_connections_;  // "Owns" any valid platform handles.

  MOJO_DISALLOW_COPY_AND_ASSIGN(ProcessConnections);
};

// MasterConnectionManager -----------------------------------------------------

MasterConnectionManager::MasterConnectionManager(
    embedder::PlatformSupport* platform_support)
    : ConnectionManager(platform_support),
      master_process_delegate_(nullptr),
      private_thread_platform_handle_watcher_(nullptr),
      next_process_identifier_(kFirstSlaveProcessIdentifier) {
  connections_[kMasterProcessIdentifier] = new ProcessConnections();
}

MasterConnectionManager::~MasterConnectionManager() {
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!master_process_delegate_);
  DCHECK(!private_thread_);
  DCHECK(helpers_.empty());
  DCHECK(pending_connects_.empty());
}

void MasterConnectionManager::Init(
    RefPtr<TaskRunner>&& delegate_thread_task_runner,
    embedder::MasterProcessDelegate* master_process_delegate) {
  DCHECK(delegate_thread_task_runner);
  DCHECK(master_process_delegate);
  DCHECK(!delegate_thread_task_runner_);
  DCHECK(!master_process_delegate_);
  DCHECK(!private_thread_);

  delegate_thread_task_runner_ = std::move(delegate_thread_task_runner);
  master_process_delegate_ = master_process_delegate;
  private_thread_ = platform::CreateAndStartIOThread(
      &private_thread_task_runner_, &private_thread_platform_handle_watcher_);
}

ProcessIdentifier MasterConnectionManager::AddSlave(
    embedder::SlaveInfo slave_info,
    ScopedPlatformHandle platform_handle) {
  // We don't really care if |slave_info| is non-null or not.
  DCHECK(platform_handle.is_valid());
  AssertNotOnPrivateThread();

  ProcessIdentifier slave_process_identifier;
  {
    MutexLocker locker(&mutex_);
    CHECK_NE(next_process_identifier_, kMasterProcessIdentifier);
    slave_process_identifier = next_process_identifier_;
    next_process_identifier_++;
    DCHECK(connections_.find(slave_process_identifier) == connections_.end());
    connections_[slave_process_identifier] = new ProcessConnections();
  }

  // We have to wait for the task to be executed, in case someone calls
  // |AddSlave()| followed immediately by |Shutdown()|.
  AutoResetWaitableEvent event;
  // TODO(vtl): With C++14 lambda captures, we'll be able to move
  // |platform_handle|.
  auto raw_platform_handle = platform_handle.release();
  private_thread_task_runner_->PostTask([this, slave_info, raw_platform_handle,
                                         slave_process_identifier, &event]() {
    AddSlaveOnPrivateThread(slave_info,
                            ScopedPlatformHandle(raw_platform_handle),
                            slave_process_identifier, &event);
  });
  event.Wait();

  return slave_process_identifier;
}

ProcessIdentifier MasterConnectionManager::AddSlaveAndBootstrap(
    embedder::SlaveInfo slave_info,
    ScopedPlatformHandle platform_handle,
    const ConnectionIdentifier& connection_id) {
  ProcessIdentifier slave_process_identifier =
      AddSlave(slave_info, platform_handle.Pass());

  MutexLocker locker(&mutex_);
  DCHECK(pending_connects_.find(connection_id) == pending_connects_.end());
  PendingConnectInfo* info = new PendingConnectInfo(kMasterProcessIdentifier);
  info->state = PendingConnectInfo::State::AWAITING_CONNECTS_FROM_BOTH;
  info->second = slave_process_identifier;
  pending_connects_[connection_id] = info;

  return slave_process_identifier;
}

void MasterConnectionManager::Shutdown() {
  AssertNotOnPrivateThread();
  DCHECK(master_process_delegate_);
  DCHECK(private_thread_);

  // The |Stop()| will actually finish all posted tasks.
  private_thread_task_runner_->PostTask(
      [this]() { ShutdownOnPrivateThread(); });
  private_thread_->Stop();
  private_thread_.reset();
  private_thread_task_runner_ = nullptr;
  private_thread_platform_handle_watcher_ = nullptr;
  DCHECK(helpers_.empty());
  DCHECK(pending_connects_.empty());
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
    bool* is_first,
    ScopedPlatformHandle* platform_handle) {
  return ConnectImpl(kMasterProcessIdentifier, connection_id,
                     peer_process_identifier, is_first, platform_handle);
}

bool MasterConnectionManager::AllowConnectImpl(
    ProcessIdentifier process_identifier,
    const ConnectionIdentifier& connection_id) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);

  MutexLocker locker(&mutex_);

  auto it = pending_connects_.find(connection_id);
  if (it == pending_connects_.end()) {
    pending_connects_[connection_id] =
        new PendingConnectInfo(process_identifier);
    // TODO(vtl): Track process identifier -> pending connections also (so these
    // can be removed efficiently if that process disconnects).
    DVLOG(1) << "New pending connection ID " << connection_id.ToString()
             << ": AllowConnect() from first process identifier "
             << process_identifier;
    return true;
  }

  PendingConnectInfo* info = it->second;
  if (info->state == PendingConnectInfo::State::AWAITING_SECOND_ALLOW_CONNECT) {
    info->state = PendingConnectInfo::State::AWAITING_CONNECTS_FROM_BOTH;
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
             << " already in state " << static_cast<int>(info->state);
  pending_connects_.erase(it);
  delete info;
  return false;
}

bool MasterConnectionManager::CancelConnectImpl(
    ProcessIdentifier process_identifier,
    const ConnectionIdentifier& connection_id) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);

  MutexLocker locker(&mutex_);

  auto it = pending_connects_.find(connection_id);
  if (it == pending_connects_.end()) {
    // Not necessarily the caller's fault, and not necessarily an error.
    DVLOG(1) << "CancelConnect() from process " << process_identifier
             << " for connection ID " << connection_id.ToString()
             << " which is not (or no longer) pending";
    return true;
  }

  PendingConnectInfo* info = it->second;
  if (process_identifier != info->first && process_identifier != info->second) {
    LOG(ERROR) << "CancelConnect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " which is neither connectee";
    return false;
  }

  // Just erase it. The other side may also try to cancel, in which case it'll
  // "fail" in the first if statement above (we assume that connection IDs never
  // collide, so there's no need to carefully track both sides).
  pending_connects_.erase(it);
  delete info;
  return true;
}

ConnectionManager::Result MasterConnectionManager::ConnectImpl(
    ProcessIdentifier process_identifier,
    const ConnectionIdentifier& connection_id,
    ProcessIdentifier* peer_process_identifier,
    bool* is_first,
    ScopedPlatformHandle* platform_handle) {
  DCHECK_NE(process_identifier, kInvalidProcessIdentifier);
  DCHECK(peer_process_identifier);
  DCHECK(is_first);
  DCHECK(platform_handle);
  DCHECK(!platform_handle->is_valid());  // Not technically wrong, but unlikely.

  MutexLocker locker(&mutex_);

  auto it = pending_connects_.find(connection_id);
  if (it == pending_connects_.end()) {
    // Not necessarily the caller's fault.
    LOG(ERROR) << "Connect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " which is not pending";
    return Result::FAILURE;
  }

  PendingConnectInfo* info = it->second;
  ProcessIdentifier peer;
  if (info->state == PendingConnectInfo::State::AWAITING_CONNECTS_FROM_BOTH) {
    if (process_identifier == info->first) {
      info->state = PendingConnectInfo::State::AWAITING_CONNECT_FROM_SECOND;
      peer = info->second;
    } else if (process_identifier == info->second) {
      info->state = PendingConnectInfo::State::AWAITING_CONNECT_FROM_FIRST;
      peer = info->first;
    } else {
      LOG(ERROR) << "Connect() from process " << process_identifier
                 << " for connection ID " << connection_id.ToString()
                 << " which is neither connectee";
      return Result::FAILURE;
    }

    DVLOG(1) << "Connection ID " << connection_id.ToString()
             << ": first Connect() from process identifier "
             << process_identifier;
    *peer_process_identifier = peer;
    *is_first = true;
    return ConnectImplHelperNoLock(process_identifier, peer, platform_handle);
  }

  // The remaining cases all result in |it| being removed from
  // |pending_connects_| and deleting |info|.
  pending_connects_.erase(it);
  std::unique_ptr<PendingConnectInfo> info_deleter(info);

  // |remaining_connectee| should be the same as |process_identifier|.
  ProcessIdentifier remaining_connectee;
  if (info->state == PendingConnectInfo::State::AWAITING_CONNECT_FROM_FIRST) {
    remaining_connectee = info->first;
    peer = info->second;
  } else if (info->state ==
             PendingConnectInfo::State::AWAITING_CONNECT_FROM_SECOND) {
    remaining_connectee = info->second;
    peer = info->first;
  } else {
    // Someone's behaving badly, but we don't know who (it might not be the
    // caller).
    LOG(ERROR) << "Connect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " in state " << static_cast<int>(info->state);
    return Result::FAILURE;
  }

  if (process_identifier != remaining_connectee) {
    LOG(ERROR) << "Connect() from process " << process_identifier
               << " for connection ID " << connection_id.ToString()
               << " which is not the remaining connectee";
    return Result::FAILURE;
  }

  DVLOG(1) << "Connection ID " << connection_id.ToString()
           << ": second Connect() from process identifier "
           << process_identifier;
  *peer_process_identifier = peer;
  *is_first = false;
  return ConnectImplHelperNoLock(process_identifier, peer, platform_handle);
}

ConnectionManager::Result MasterConnectionManager::ConnectImplHelperNoLock(
    ProcessIdentifier process_identifier,
    ProcessIdentifier peer_process_identifier,
    ScopedPlatformHandle* platform_handle) {
  if (process_identifier == peer_process_identifier) {
    platform_handle->reset();
    DVLOG(1) << "Connect: same process";
    return Result::SUCCESS_CONNECT_SAME_PROCESS;
  }

  // We should know about the process identified by |process_identifier|.
  DCHECK(connections_.find(process_identifier) != connections_.end());
  ProcessConnections* process_connections = connections_[process_identifier];
  // We should also know about the peer.
  DCHECK(connections_.find(peer_process_identifier) != connections_.end());
  switch (process_connections->GetConnectionStatus(peer_process_identifier,
                                                   platform_handle)) {
    case ProcessConnections::ConnectionStatus::NONE: {
      // TODO(vtl): In the "second connect" case, this should never be reached
      // (but it's not easy to DCHECK this invariant here).
      process_connections->AddConnection(
          peer_process_identifier,
          ProcessConnections::ConnectionStatus::RUNNING,
          ScopedPlatformHandle());
      PlatformPipe platform_pipe;
      *platform_handle = platform_pipe.handle0.Pass();

      connections_[peer_process_identifier]->AddConnection(
          process_identifier, ProcessConnections::ConnectionStatus::PENDING,
          platform_pipe.handle1.Pass());
      break;
    }
    case ProcessConnections::ConnectionStatus::PENDING:
      DCHECK(connections_[peer_process_identifier]->GetConnectionStatus(
                 process_identifier, nullptr) ==
             ProcessConnections::ConnectionStatus::RUNNING);
      break;
    case ProcessConnections::ConnectionStatus::RUNNING:
      // |process_identifier| already has a connection to
      // |peer_process_identifier|, so it should reuse that.
      platform_handle->reset();
      DVLOG(1) << "Connect: reuse connection";
      return Result::SUCCESS_CONNECT_REUSE_CONNECTION;
  }
  DCHECK(platform_handle->is_valid());
  DVLOG(1) << "Connect: new connection";
  return Result::SUCCESS_CONNECT_NEW_CONNECTION;
}

void MasterConnectionManager::ShutdownOnPrivateThread() {
  AssertOnPrivateThread();

  if (!pending_connects_.empty()) {
    DVLOG(1) << "Shutting down with connections pending";
    for (auto& p : pending_connects_)
      delete p.second;
    pending_connects_.clear();
  }

  for (auto& p : connections_)
    delete p.second;
  connections_.clear();

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
    ScopedPlatformHandle platform_handle,
    ProcessIdentifier slave_process_identifier,
    AutoResetWaitableEvent* event) {
  DCHECK(platform_handle.is_valid());
  DCHECK(event);
  AssertOnPrivateThread();

  std::unique_ptr<Helper> helper(new Helper(
      this, slave_process_identifier, slave_info, platform_handle.Pass()));
  helper->Init(private_thread_task_runner_.Clone(),
               private_thread_platform_handle_watcher_);

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
    for (auto it = pending_connects_.begin(); it != pending_connects_.end();) {
      if (it->second->first == process_identifier ||
          it->second->second == process_identifier) {
        auto it_to_erase = it;
        ++it;
        delete it_to_erase->second;
        pending_connects_.erase(it_to_erase);
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
  // TODO(vtl): With C++14 lambda captures, this can be made less silly.
  auto master_process_delegate = master_process_delegate_;
  delegate_thread_task_runner_->PostTask(
      [master_process_delegate, slave_info]() {
        master_process_delegate->OnSlaveDisconnect(slave_info);
      });
}

void MasterConnectionManager::AssertNotOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|.
  DCHECK(!private_thread_task_runner_->RunsTasksOnCurrentThread());
}

void MasterConnectionManager::AssertOnPrivateThread() const {
  // This should only be called after |Init()| and before |Shutdown()|.
  DCHECK(private_thread_task_runner_->RunsTasksOnCurrentThread());
}

}  // namespace system
}  // namespace mojo
