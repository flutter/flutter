// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel.h"

#include <algorithm>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/endpoint_relayer.h"
#include "mojo/edk/system/transport_data.h"
#include "mojo/edk/util/string_printf.h"

using mojo::platform::PlatformHandleWatcher;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::util::MakeRefCounted;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;
using mojo::util::StringPrintf;

namespace mojo {
namespace system {

namespace {

struct SerializedEndpoint {
  // This is the endpoint ID on the receiving side, and should be a "remote ID".
  // (The receiving side should already have had an endpoint attached and been
  // run via the |Channel|s. This endpoint will have both IDs assigned, so this
  // ID is only needed to associate that endpoint with a particular dispatcher.)
  ChannelEndpointId receiver_endpoint_id;
};

}  // namespace

void Channel::Init(RefPtr<TaskRunner>&& io_task_runner,
                   PlatformHandleWatcher* io_watcher,
                   std::unique_ptr<RawChannel> raw_channel) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(raw_channel);

  // No need to take |mutex_|, since this must be called before this object
  // becomes thread-safe.
  DCHECK(!is_running_);
  raw_channel_ = std::move(raw_channel);
  raw_channel_->Init(std::move(io_task_runner), io_watcher, this);
  is_running_ = true;
}

void Channel::SetChannelManager(ChannelManager* channel_manager) {
  DCHECK(channel_manager);

  MutexLocker locker(&mutex_);
  DCHECK(!is_shutting_down_);
  DCHECK(!channel_manager_);
  channel_manager_ = channel_manager;
}

void Channel::Shutdown() {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

  IdToEndpointMap to_destroy;
  {
    MutexLocker locker(&mutex_);
    if (!is_running_)
      return;

    // Note: Don't reset |raw_channel_|, in case we're being called from within
    // |OnReadMessage()| or |OnError()|.
    raw_channel_->Shutdown();
    is_running_ = false;

    // We need to deal with it outside the lock.
    std::swap(to_destroy, local_id_to_endpoint_map_);
  }

  size_t num_live = 0;
  size_t num_zombies = 0;
  for (IdToEndpointMap::iterator it = to_destroy.begin();
       it != to_destroy.end(); ++it) {
    if (it->second) {
      num_live++;
      it->second->DetachFromChannel();
    } else {
      num_zombies++;
    }
  }
  DVLOG_IF(2, num_live || num_zombies) << "Shut down Channel with " << num_live
                                       << " live endpoints and " << num_zombies
                                       << " zombies";
}

void Channel::WillShutdownSoon() {
  MutexLocker locker(&mutex_);
  is_shutting_down_ = true;
  channel_manager_ = nullptr;
}

void Channel::SetBootstrapEndpoint(RefPtr<ChannelEndpoint>&& endpoint) {
  // Used for both local and remote IDs.
  ChannelEndpointId bootstrap_id = ChannelEndpointId::GetBootstrap();
  SetBootstrapEndpointWithIds(std::move(endpoint), bootstrap_id, bootstrap_id);
}

void Channel::SetBootstrapEndpointWithIds(RefPtr<ChannelEndpoint>&& endpoint,
                                          ChannelEndpointId local_id,
                                          ChannelEndpointId remote_id) {
  DCHECK(endpoint);

  {
    MutexLocker locker(&mutex_);

    DLOG_IF(WARNING, is_shutting_down_)
        << "SetBootstrapEndpoint() while shutting down";

    // There must not be an endpoint with that ID already.
    DCHECK(local_id_to_endpoint_map_.find(local_id) ==
           local_id_to_endpoint_map_.end());

    local_id_to_endpoint_map_[local_id] = endpoint;
  }

  endpoint->AttachAndRun(this, local_id, remote_id);
}

bool Channel::WriteMessage(std::unique_ptr<MessageInTransit> message) {
  MutexLocker locker(&mutex_);
  if (!is_running_) {
    // TODO(vtl): I think this is probably not an error condition, but I should
    // think about it (and the shutdown sequence) more carefully.
    LOG(WARNING) << "WriteMessage() after shutdown";
    return false;
  }

  DLOG_IF(WARNING, is_shutting_down_) << "WriteMessage() while shutting down";
  return raw_channel_->WriteMessage(std::move(message));
}

bool Channel::IsWriteBufferEmpty() {
  MutexLocker locker(&mutex_);
  if (!is_running_)
    return true;
  return raw_channel_->IsWriteBufferEmpty();
}

void Channel::DetachEndpoint(ChannelEndpoint* endpoint,
                             ChannelEndpointId local_id,
                             ChannelEndpointId remote_id) {
  // Keep a reference to |this| to prevent this |Channel| from being deleted
  // while this function is running. Without this, if |Shutdown()| is started on
  // the I/O thread immediately after |mutex_| is released below and finishes
  // before |SendControlMessage()| gets to run, |this| could be deleted while
  // this function is still running.
  RefPtr<Channel> self(this);

  if (!DetachEndpointInternal(endpoint, local_id, remote_id))
    return;

  // Note: Send the remove message outside the lock.
  if (!SendControlMessage(MessageInTransit::Subtype::CHANNEL_REMOVE_ENDPOINT,
                          local_id, remote_id, 0, nullptr)) {
    HandleLocalError(
        StringPrintf("Failed to send message to remove remote endpoint (local "
                     "ID %u, remote ID %u)",
                     static_cast<unsigned>(local_id.value()),
                     static_cast<unsigned>(remote_id.value()))
            .c_str());
  }
}

size_t Channel::GetSerializedEndpointSize() const {
  return sizeof(SerializedEndpoint);
}

void Channel::SerializeEndpointWithClosedPeer(
    void* destination,
    MessageInTransitQueue* message_queue) {
  // We can actually just pass no client to |SerializeEndpointWithLocalPeer()|.
  SerializeEndpointWithLocalPeer(destination, message_queue, nullptr, 0);
}

RefPtr<ChannelEndpoint> Channel::SerializeEndpointWithLocalPeer(
    void* destination,
    MessageInTransitQueue* message_queue,
    RefPtr<ChannelEndpointClient>&& endpoint_client,
    unsigned endpoint_client_port) {
  DCHECK(destination);
  // Allow |endpoint_client| to be null, for use by
  // |SerializeEndpointWithClosedPeer()|.

  auto endpoint = MakeRefCounted<ChannelEndpoint>(
      std::move(endpoint_client), endpoint_client_port, message_queue);

  SerializedEndpoint* s = static_cast<SerializedEndpoint*>(destination);
  s->receiver_endpoint_id = AttachAndRunEndpoint(endpoint.Clone());
  DVLOG(2) << "Serializing endpoint with local or closed peer (remote ID = "
           << s->receiver_endpoint_id << ")";

  return endpoint;
}

void Channel::SerializeEndpointWithRemotePeer(
    void* destination,
    MessageInTransitQueue* message_queue,
    RefPtr<ChannelEndpoint>&& peer_endpoint) {
  DCHECK(destination);
  DCHECK(peer_endpoint);

  DVLOG(1) << "Direct message pipe passing across multiple channels not yet "
              "implemented; will proxy";
  // Create and set up an |EndpointRelayer| to proxy.
  // TODO(vtl): If we were to own/track the relayer directly (rather than owning
  // it via its |ChannelEndpoint|s), then we might be able to make
  // |ChannelEndpoint|'s |client_| pointer a raw pointer.
  auto relayer = MakeRefCounted<EndpointRelayer>();
  auto endpoint =
      MakeRefCounted<ChannelEndpoint>(relayer.Clone(), 0, message_queue);
  relayer->Init(endpoint.Clone(), peer_endpoint.Clone());
  peer_endpoint->ReplaceClient(std::move(relayer), 1);

  SerializedEndpoint* s = static_cast<SerializedEndpoint*>(destination);
  s->receiver_endpoint_id = AttachAndRunEndpoint(std::move(endpoint));
  DVLOG(2) << "Serializing endpoint with remote peer (remote ID = "
           << s->receiver_endpoint_id << ")";
}

RefPtr<IncomingEndpoint> Channel::DeserializeEndpoint(const void* source) {
  const SerializedEndpoint* s = static_cast<const SerializedEndpoint*>(source);
  ChannelEndpointId local_id = s->receiver_endpoint_id;
  // No need to check the validity of |local_id| -- if it's not valid, it simply
  // won't be in |incoming_endpoints_|.
  DVLOG_IF(2, !local_id.is_valid() || !local_id.is_remote())
      << "Attempt to get incoming endpoint for invalid ID " << local_id;

  MutexLocker locker(&mutex_);

  auto it = incoming_endpoints_.find(local_id);
  if (it == incoming_endpoints_.end()) {
    LOG(ERROR) << "Failed to deserialize endpoint (ID = " << local_id << ")";
    return nullptr;
  }

  DVLOG(2) << "Deserializing endpoint (new local ID = " << local_id << ")";

  RefPtr<IncomingEndpoint> rv = std::move(it->second);
  incoming_endpoints_.erase(it);
  return rv;
}

size_t Channel::GetSerializedPlatformHandleSize() const {
  // TODO(vtl): Having to lock |mutex_| here is a bit unfortunate. Maybe we
  // should get the size in |Init()| and cache it?
  MutexLocker locker(&mutex_);
  return raw_channel_->GetSerializedPlatformHandleSize();
}

Channel::Channel(embedder::PlatformSupport* platform_support)
    : platform_support_(platform_support),
      is_running_(false),
      is_shutting_down_(false),
      channel_manager_(nullptr) {}

Channel::~Channel() {
  // The channel should have been shut down first.
  DCHECK(!is_running_);
}

bool Channel::DetachEndpointInternal(ChannelEndpoint* endpoint,
                                     ChannelEndpointId local_id,
                                     ChannelEndpointId remote_id) {
  DCHECK(endpoint);
  DCHECK(local_id.is_valid());

  if (!remote_id.is_valid())
    return false;  // Nothing to do.

  MutexLocker locker(&mutex_);
  if (!is_running_)
    return false;

  IdToEndpointMap::iterator it = local_id_to_endpoint_map_.find(local_id);
  // We detach immediately if we receive a remove message, so it's possible
  // that the local ID is no longer in |local_id_to_endpoint_map_|, or even
  // that it's since been reused for another endpoint. In both cases, there's
  // nothing more to do.
  if (it == local_id_to_endpoint_map_.end() || it->second.get() != endpoint)
    return false;

  DCHECK(it->second);
  it->second = nullptr;
  return true;
}

void Channel::OnReadMessage(
    const MessageInTransit::View& message_view,
    std::unique_ptr<std::vector<ScopedPlatformHandle>> platform_handles) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

  switch (message_view.type()) {
    case MessageInTransit::Type::ENDPOINT_CLIENT:
    case MessageInTransit::Type::ENDPOINT:
      OnReadMessageForEndpoint(message_view, std::move(platform_handles));
      break;
    case MessageInTransit::Type::CHANNEL:
      OnReadMessageForChannel(message_view, std::move(platform_handles));
      break;
    default:
      HandleRemoteError(StringPrintf("Received message of invalid type %u",
                                     static_cast<unsigned>(message_view.type()))
                            .c_str());
      break;
  }
}

void Channel::OnError(Error error) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

  switch (error) {
    case ERROR_READ_SHUTDOWN:
      // The other side was cleanly closed, so this isn't actually an error.
      DVLOG(1) << "RawChannel read error (shutdown)";
      break;
    case ERROR_READ_BROKEN: {
      MutexLocker locker(&mutex_);
      LOG_IF(ERROR, !is_shutting_down_)
          << "RawChannel read error (connection broken)";
      break;
    }
    case ERROR_READ_BAD_MESSAGE:
      // Receiving a bad message means either a bug, data corruption, or
      // malicious attack (probably due to some other bug).
      LOG(ERROR) << "RawChannel read error (received bad message)";
      break;
    case ERROR_READ_UNKNOWN:
      LOG(ERROR) << "RawChannel read error (unknown)";
      break;
    case ERROR_WRITE:
      // Write errors are slightly notable: they probably shouldn't happen under
      // normal operation (but maybe the other side crashed).
      LOG(WARNING) << "RawChannel write error";
      break;
  }
  Shutdown();
}

void Channel::OnReadMessageForEndpoint(
    const MessageInTransit::View& message_view,
    std::unique_ptr<std::vector<ScopedPlatformHandle>> platform_handles) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(message_view.type() == MessageInTransit::Type::ENDPOINT_CLIENT ||
         message_view.type() == MessageInTransit::Type::ENDPOINT);

  ChannelEndpointId local_id = message_view.destination_id();
  if (!local_id.is_valid()) {
    HandleRemoteError("Received message with no destination ID");
    return;
  }

  RefPtr<ChannelEndpoint> endpoint;
  {
    MutexLocker locker(&mutex_);

    // Since we own |raw_channel_|, and this method and |Shutdown()| should only
    // be called from the creation thread, |raw_channel_| should never be null
    // here.
    DCHECK(is_running_);

    IdToEndpointMap::const_iterator it =
        local_id_to_endpoint_map_.find(local_id);
    if (it != local_id_to_endpoint_map_.end()) {
      // Ignore messages for zombie endpoints (not an error).
      if (!it->second) {
        DVLOG(2) << "Ignoring downstream message for zombie endpoint (local ID "
                    "= " << local_id
                 << ", remote ID = " << message_view.source_id() << ")";
        return;
      }

      endpoint = it->second;
    }
  }
  if (!endpoint) {
    HandleRemoteError(
        StringPrintf(
            "Received a message for nonexistent local destination ID %u",
            static_cast<unsigned>(local_id.value()))
            .c_str());
    // This is strongly indicative of some problem. However, it's not a fatal
    // error, since it may indicate a buggy (or hostile) remote process. Don't
    // die even for Debug builds, since handling this properly needs to be
    // tested (TODO(vtl)).
    DLOG(ERROR) << "This should not happen under normal operation.";
    return;
  }

  std::unique_ptr<MessageInTransit> message(new MessageInTransit(message_view));
  if (message_view.transport_data_buffer_size() > 0) {
    DCHECK(message_view.transport_data_buffer());
    message->SetHandles(TransportData::DeserializeHandles(
        message_view.transport_data_buffer(),
        message_view.transport_data_buffer_size(), std::move(platform_handles),
        this));
  }

  endpoint->OnReadMessage(std::move(message));
}

void Channel::OnReadMessageForChannel(
    const MessageInTransit::View& message_view,
    std::unique_ptr<std::vector<ScopedPlatformHandle>> platform_handles) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK_EQ(message_view.type(), MessageInTransit::Type::CHANNEL);

  // Currently, no channel messages take platform handles.
  if (platform_handles) {
    HandleRemoteError(
        "Received invalid channel message (has platform handles)");
    NOTREACHED();
    return;
  }

  switch (message_view.subtype()) {
    case MessageInTransit::Subtype::CHANNEL_ATTACH_AND_RUN_ENDPOINT:
      DVLOG(2) << "Handling channel message to attach and run endpoint (local "
                  "ID " << message_view.destination_id() << ", remote ID "
               << message_view.source_id() << ")";
      if (!OnAttachAndRunEndpoint(message_view.destination_id(),
                                  message_view.source_id())) {
        HandleRemoteError(
            "Received invalid channel message to attach and run endpoint");
      }
      break;
    case MessageInTransit::Subtype::CHANNEL_REMOVE_ENDPOINT:
      DVLOG(2) << "Handling channel message to remove endpoint (local ID "
               << message_view.destination_id() << ", remote ID "
               << message_view.source_id() << ")";
      if (!OnRemoveEndpoint(message_view.destination_id(),
                            message_view.source_id())) {
        HandleRemoteError(
            "Received invalid channel message to remove endpoint");
      }
      break;
    case MessageInTransit::Subtype::CHANNEL_REMOVE_ENDPOINT_ACK:
      DVLOG(2) << "Handling channel message to ack remove endpoint (local ID "
               << message_view.destination_id() << ", remote ID "
               << message_view.source_id() << ")";
      if (!OnRemoveEndpointAck(message_view.destination_id())) {
        HandleRemoteError(
            "Received invalid channel message to ack remove endpoint");
      }
      break;
    default:
      HandleRemoteError("Received invalid channel message");
      NOTREACHED();
      break;
  }
}

bool Channel::OnAttachAndRunEndpoint(ChannelEndpointId local_id,
                                     ChannelEndpointId remote_id) {
  // We should only get this for remotely-created local endpoints, so our local
  // ID should be "remote".
  if (!local_id.is_valid() || !local_id.is_remote()) {
    DVLOG(2) << "Received attach and run endpoint with invalid local ID";
    return false;
  }

  // Conversely, the remote end should be "local".
  if (!remote_id.is_valid() || remote_id.is_remote()) {
    DVLOG(2) << "Received attach and run endpoint with invalid remote ID";
    return false;
  }

  // Create/initialize an |IncomingEndpoint| and thus an endpoint (outside the
  // lock).
  auto incoming_endpoint = MakeRefCounted<IncomingEndpoint>();
  RefPtr<ChannelEndpoint> endpoint = incoming_endpoint->Init();

  bool success = true;
  {
    MutexLocker locker(&mutex_);

    if (local_id_to_endpoint_map_.find(local_id) ==
        local_id_to_endpoint_map_.end()) {
      DCHECK(incoming_endpoints_.find(local_id) == incoming_endpoints_.end());

      // TODO(vtl): Use emplace when we move to C++11 unordered_maps. (It'll
      // avoid some refcount churn.)
      local_id_to_endpoint_map_[local_id] = endpoint;
      incoming_endpoints_[local_id] = incoming_endpoint;
    } else {
      // We need to call |Close()| outside the lock.
      success = false;
    }
  }
  if (!success) {
    DVLOG(2) << "Received attach and run endpoint for existing local ID";
    incoming_endpoint->Close();
    return false;
  }

  endpoint->AttachAndRun(this, local_id, remote_id);
  return true;
}

bool Channel::OnRemoveEndpoint(ChannelEndpointId local_id,
                               ChannelEndpointId remote_id) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

  RefPtr<ChannelEndpoint> endpoint;
  {
    MutexLocker locker(&mutex_);

    IdToEndpointMap::iterator it = local_id_to_endpoint_map_.find(local_id);
    if (it == local_id_to_endpoint_map_.end()) {
      DVLOG(2) << "Remove endpoint error: not found";
      return false;
    }

    if (!it->second) {
      // Remove messages "crossed"; we have to wait for the ack.
      return true;
    }

    endpoint = std::move(it->second);
    local_id_to_endpoint_map_.erase(it);
    // Detach and send the remove ack message outside the lock.
  }

  endpoint->DetachFromChannel();

  if (!SendControlMessage(
          MessageInTransit::Subtype::CHANNEL_REMOVE_ENDPOINT_ACK, local_id,
          remote_id, 0, nullptr)) {
    HandleLocalError(
        StringPrintf("Failed to send message to ack remove remote endpoint "
                     "(local ID %u, remote ID %u)",
                     static_cast<unsigned>(local_id.value()),
                     static_cast<unsigned>(remote_id.value()))
            .c_str());
  }

  return true;
}

bool Channel::OnRemoveEndpointAck(ChannelEndpointId local_id) {
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  DCHECK(thread_checker_.IsCreationThreadCurrent());
#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)

  MutexLocker locker(&mutex_);

  IdToEndpointMap::iterator it = local_id_to_endpoint_map_.find(local_id);
  if (it == local_id_to_endpoint_map_.end()) {
    DVLOG(2) << "Remove endpoint ack error: not found";
    return false;
  }

  if (it->second) {
    DVLOG(2) << "Remove endpoint ack error: wrong state";
    return false;
  }

  local_id_to_endpoint_map_.erase(it);
  return true;
}

void Channel::HandleRemoteError(const char* error_message) {
  // TODO(vtl): Is this how we really want to handle this? Probably we want to
  // terminate the connection, since it's spewing invalid stuff.
  LOG(WARNING) << error_message;
}

void Channel::HandleLocalError(const char* error_message) {
  // TODO(vtl): Is this how we really want to handle this?
  // Sometimes we'll want to propagate the error back to the message pipe
  // (endpoint), and notify it that the remote is (effectively) closed.
  // Sometimes we'll want to kill the channel (and notify all the endpoints that
  // their remotes are dead.
  LOG(WARNING) << error_message;
}

// Note: |endpoint| being a |RefPtr| makes this function safe, since it keeps
// the endpoint alive even after the lock is released.
ChannelEndpointId Channel::AttachAndRunEndpoint(
    RefPtr<ChannelEndpoint>&& endpoint) {
  DCHECK(endpoint);

  ChannelEndpointId local_id;
  ChannelEndpointId remote_id;
  {
    MutexLocker locker(&mutex_);

    DLOG_IF(WARNING, is_shutting_down_)
        << "AttachAndRunEndpoint() while shutting down";

    do {
      local_id = local_id_generator_.GetNext();
    } while (local_id_to_endpoint_map_.find(local_id) !=
             local_id_to_endpoint_map_.end());

    // TODO(vtl): We also need to check for collisions of remote IDs here.
    remote_id = remote_id_generator_.GetNext();

    local_id_to_endpoint_map_[local_id] = endpoint;
  }

  if (!SendControlMessage(
          MessageInTransit::Subtype::CHANNEL_ATTACH_AND_RUN_ENDPOINT, local_id,
          remote_id, 0, nullptr)) {
    HandleLocalError(
        StringPrintf("Failed to send message to run remote endpoint (local "
                     "ID %u, remote ID %u)",
                     static_cast<unsigned>(local_id.value()),
                     static_cast<unsigned>(remote_id.value()))
            .c_str());
    // TODO(vtl): Should we continue on to |AttachAndRun()|?
  }

  endpoint->AttachAndRun(this, local_id, remote_id);
  return remote_id;
}

bool Channel::SendControlMessage(MessageInTransit::Subtype subtype,
                                 ChannelEndpointId local_id,
                                 ChannelEndpointId remote_id,
                                 uint32_t num_bytes,
                                 const void* bytes) {
  DVLOG(2) << "Sending channel control message: subtype " << subtype
           << ", local ID " << local_id << ", remote ID " << remote_id;
  std::unique_ptr<MessageInTransit> message(new MessageInTransit(
      MessageInTransit::Type::CHANNEL, subtype, num_bytes, bytes));
  message->set_source_id(local_id);
  message->set_destination_id(remote_id);
  return WriteMessage(std::move(message));
}

}  // namespace system
}  // namespace mojo
