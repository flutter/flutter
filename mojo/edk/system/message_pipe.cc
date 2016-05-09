// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_pipe.h"

#include <memory>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/handle_transport.h"
#include "mojo/edk/system/incoming_endpoint.h"
#include "mojo/edk/system/local_message_pipe_endpoint.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/system/message_pipe_endpoint.h"
#include "mojo/edk/system/proxy_message_pipe_endpoint.h"
#include "mojo/edk/util/make_unique.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::util::MakeRefCounted;
using mojo::util::MakeUnique;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

// static
RefPtr<MessagePipe> MessagePipe::CreateLocalLocal()
    MOJO_NO_THREAD_SAFETY_ANALYSIS {
  RefPtr<MessagePipe> message_pipe = AdoptRef(new MessagePipe());
  message_pipe->endpoints_[0].reset(new LocalMessagePipeEndpoint());
  message_pipe->endpoints_[1].reset(new LocalMessagePipeEndpoint());
  return message_pipe;
}

// static
RefPtr<MessagePipe> MessagePipe::CreateLocalProxy(
    RefPtr<ChannelEndpoint>* channel_endpoint) MOJO_NO_THREAD_SAFETY_ANALYSIS {
  DCHECK(!*channel_endpoint);  // Not technically wrong, but unlikely.
  RefPtr<MessagePipe> message_pipe = AdoptRef(new MessagePipe());
  message_pipe->endpoints_[0].reset(new LocalMessagePipeEndpoint());
  *channel_endpoint = MakeRefCounted<ChannelEndpoint>(message_pipe.Clone(), 1);
  message_pipe->endpoints_[1].reset(
      new ProxyMessagePipeEndpoint(channel_endpoint->Clone()));
  return message_pipe;
}

// static
RefPtr<MessagePipe> MessagePipe::CreateLocalProxyFromExisting(
    MessageInTransitQueue* message_queue,
    RefPtr<ChannelEndpoint>&& channel_endpoint) MOJO_NO_THREAD_SAFETY_ANALYSIS {
  DCHECK(message_queue);
  RefPtr<MessagePipe> message_pipe = AdoptRef(new MessagePipe());
  message_pipe->endpoints_[0].reset(
      new LocalMessagePipeEndpoint(message_queue));
  if (channel_endpoint) {
    bool attached_to_channel = channel_endpoint->ReplaceClient(message_pipe, 1);
    message_pipe->endpoints_[1].reset(
        new ProxyMessagePipeEndpoint(std::move(channel_endpoint)));
    if (!attached_to_channel)
      message_pipe->OnDetachFromChannel(1);
  } else {
    // This means that the proxy side was already closed; we only need to inform
    // the local side of this.
    // TODO(vtl): This is safe to do without locking (but perhaps slightly
    // dubious), since no other thread has access to |message_pipe| yet.
    message_pipe->endpoints_[0]->OnPeerClose();
  }
  return message_pipe;
}

// static
RefPtr<MessagePipe> MessagePipe::CreateProxyLocal(
    RefPtr<ChannelEndpoint>* channel_endpoint) MOJO_NO_THREAD_SAFETY_ANALYSIS {
  DCHECK(!*channel_endpoint);  // Not technically wrong, but unlikely.
  RefPtr<MessagePipe> message_pipe = AdoptRef(new MessagePipe());
  *channel_endpoint = MakeRefCounted<ChannelEndpoint>(message_pipe, 0);
  message_pipe->endpoints_[0].reset(
      new ProxyMessagePipeEndpoint(channel_endpoint->Clone()));
  message_pipe->endpoints_[1].reset(new LocalMessagePipeEndpoint());
  return message_pipe;
}

// static
unsigned MessagePipe::GetPeerPort(unsigned port) {
  DCHECK(port == 0 || port == 1);
  return port ^ 1;
}

// static
bool MessagePipe::Deserialize(Channel* channel,
                              const void* source,
                              size_t size,
                              RefPtr<MessagePipe>* message_pipe,
                              unsigned* port) {
  DCHECK(!*message_pipe);  // Not technically wrong, but unlikely.

  if (size != channel->GetSerializedEndpointSize()) {
    LOG(ERROR) << "Invalid serialized message pipe";
    return false;
  }

  RefPtr<IncomingEndpoint> incoming_endpoint =
      channel->DeserializeEndpoint(source);
  if (!incoming_endpoint)
    return false;

  *message_pipe = incoming_endpoint->ConvertToMessagePipe();
  DCHECK(*message_pipe);
  *port = 0;
  return true;
}

MessagePipeEndpoint::Type MessagePipe::GetType(unsigned port) {
  DCHECK(port == 0 || port == 1);
  MutexLocker locker(&mutex_);
  DCHECK(endpoints_[port]);

  return endpoints_[port]->GetType();
}

void MessagePipe::CancelAllAwakables(unsigned port) {
  MutexLocker locker(&mutex_);
  CancelAllAwakablesNoLock(port);
}

void MessagePipe::Close(unsigned port) {
  DCHECK(port == 0 || port == 1);

  unsigned peer_port = GetPeerPort(port);

  MutexLocker locker(&mutex_);
  // The endpoint's |OnPeerClose()| may have been called first and returned
  // false, which would have resulted in its destruction.
  if (!endpoints_[port])
    return;

  endpoints_[port]->Close();
  if (endpoints_[peer_port]) {
    if (!endpoints_[peer_port]->OnPeerClose())
      endpoints_[peer_port].reset();
  }
  endpoints_[port].reset();
}

// TODO(vtl): Handle flags.
MojoResult MessagePipe::WriteMessage(unsigned port,
                                     UserPointer<const void> bytes,
                                     uint32_t num_bytes,
                                     std::vector<HandleTransport>* transports,
                                     MojoWriteMessageFlags flags) {
  DCHECK(port == 0 || port == 1);

  MutexLocker locker(&mutex_);
  return EnqueueMessageNoLock(
      GetPeerPort(port),
      MakeUnique<MessageInTransit>(
          MessageInTransit::Type::ENDPOINT_CLIENT,
          MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA, num_bytes, bytes),
      transports);
}

MojoResult MessagePipe::ReadMessage(unsigned port,
                                    UserPointer<void> bytes,
                                    UserPointer<uint32_t> num_bytes,
                                    HandleVector* handles,
                                    uint32_t* num_handles,
                                    MojoReadMessageFlags flags) {
  DCHECK(port == 0 || port == 1);

  MutexLocker locker(&mutex_);
  DCHECK(endpoints_[port]);

  return endpoints_[port]->ReadMessage(bytes, num_bytes, handles, num_handles,
                                       flags);
}

HandleSignalsState MessagePipe::GetHandleSignalsState(unsigned port) const {
  DCHECK(port == 0 || port == 1);

  MutexLocker locker(&mutex_);
  DCHECK(endpoints_[port]);

  return endpoints_[port]->GetHandleSignalsState();
}

MojoResult MessagePipe::AddAwakable(unsigned port,
                                    Awakable* awakable,
                                    MojoHandleSignals signals,
                                    uint32_t context,
                                    HandleSignalsState* signals_state) {
  DCHECK(port == 0 || port == 1);

  MutexLocker locker(&mutex_);
  DCHECK(endpoints_[port]);

  return endpoints_[port]->AddAwakable(awakable, signals, context,
                                       signals_state);
}

void MessagePipe::RemoveAwakable(unsigned port,
                                 Awakable* awakable,
                                 HandleSignalsState* signals_state) {
  DCHECK(port == 0 || port == 1);

  MutexLocker locker(&mutex_);
  DCHECK(endpoints_[port]);

  endpoints_[port]->RemoveAwakable(awakable, signals_state);
}

void MessagePipe::StartSerialize(unsigned /*port*/,
                                 Channel* channel,
                                 size_t* max_size,
                                 size_t* max_platform_handles) {
  *max_size = channel->GetSerializedEndpointSize();
  *max_platform_handles = 0;
}

bool MessagePipe::EndSerialize(
    unsigned port,
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* /*platform_handles*/) {
  DCHECK(port == 0 || port == 1);

  MutexLocker locker(&mutex_);
  DCHECK(endpoints_[port]);

  // The port being serialized must be local.
  DCHECK_EQ(endpoints_[port]->GetType(), MessagePipeEndpoint::kTypeLocal);

  unsigned peer_port = GetPeerPort(port);
  MessageInTransitQueue* message_queue =
      static_cast<LocalMessagePipeEndpoint*>(endpoints_[port].get())
          ->message_queue();
  // The replacement for |endpoints_[port]|, if any.
  MessagePipeEndpoint* replacement_endpoint = nullptr;

  // The three cases below correspond to the ones described above
  // |Channel::SerializeEndpoint...()| (in channel.h).
  if (!endpoints_[peer_port]) {
    // Case 1: (known-)closed peer port. There's no reason for us to continue to
    // exist afterwards.
    channel->SerializeEndpointWithClosedPeer(destination, message_queue);
  } else if (endpoints_[peer_port]->GetType() ==
             MessagePipeEndpoint::kTypeLocal) {
    // Case 2: local peer port. We replace |port|'s |LocalMessagePipeEndpoint|
    // with a |ProxyMessagePipeEndpoint| hooked up to the |ChannelEndpoint| that
    // the |Channel| returns to us.
    RefPtr<ChannelEndpoint> channel_endpoint =
        channel->SerializeEndpointWithLocalPeer(
            destination, message_queue, RefPtr<ChannelEndpointClient>(this),
            port);
    replacement_endpoint =
        new ProxyMessagePipeEndpoint(std::move(channel_endpoint));
  } else {
    // Case 3: remote peer port. We get the |peer_port|'s |ChannelEndpoint| and
    // pass it to the |Channel|. There's no reason for us to continue to exist
    // afterwards.
    DCHECK_EQ(endpoints_[peer_port]->GetType(),
              MessagePipeEndpoint::kTypeProxy);
    ProxyMessagePipeEndpoint* peer_endpoint =
        static_cast<ProxyMessagePipeEndpoint*>(endpoints_[peer_port].get());
    RefPtr<ChannelEndpoint> peer_channel_endpoint =
        peer_endpoint->ReleaseChannelEndpoint();
    channel->SerializeEndpointWithRemotePeer(destination, message_queue,
                                             std::move(peer_channel_endpoint));
    // No need to call |Close()| after |ReleaseChannelEndpoint()|.
    endpoints_[peer_port].reset();
  }

  endpoints_[port]->Close();
  endpoints_[port].reset(replacement_endpoint);

  *actual_size = channel->GetSerializedEndpointSize();
  return true;
}

void MessagePipe::CancelAllAwakablesNoLock(unsigned port) {
  DCHECK(port == 0 || port == 1);
  mutex_.AssertHeld();
  DCHECK(endpoints_[port]);
  endpoints_[port]->CancelAllAwakables();
}

bool MessagePipe::OnReadMessage(unsigned port, MessageInTransit* message) {
  MutexLocker locker(&mutex_);

  if (!endpoints_[port]) {
    // This will happen only on the rare occasion that the call to
    // |OnReadMessage()| is racing with us calling
    // |ChannelEndpoint::ReplaceClient()|, in which case we reject the message,
    // and the |ChannelEndpoint| can retry (calling the new client's
    // |OnReadMessage()|).
    return false;
  }

  // This is called when the |ChannelEndpoint| for the
  // |ProxyMessagePipeEndpoint| |port| receives a message (from the |Channel|).
  // We need to pass this message on to its peer port (typically a
  // |LocalMessagePipeEndpoint|).
  MojoResult result = EnqueueMessageNoLock(
      GetPeerPort(port), std::unique_ptr<MessageInTransit>(message), nullptr);
  DLOG_IF(WARNING, result != MOJO_RESULT_OK)
      << "EnqueueMessageNoLock() failed (result  = " << result << ")";
  return true;
}

void MessagePipe::OnDetachFromChannel(unsigned port) {
  Close(port);
}

MessagePipe::MessagePipe() {}

MessagePipe::~MessagePipe() {
  // Owned by the dispatchers. The owning dispatchers should only release us via
  // their |Close()| method, which should inform us of being closed via our
  // |Close()|. Thus these should already be null.
  DCHECK(!endpoints_[0]);
  DCHECK(!endpoints_[1]);
}

MojoResult MessagePipe::EnqueueMessageNoLock(
    unsigned port,
    std::unique_ptr<MessageInTransit> message,
    std::vector<HandleTransport>* transports) {
  DCHECK(port == 0 || port == 1);
  DCHECK(message);

  DCHECK_EQ(message->type(), MessageInTransit::Type::ENDPOINT_CLIENT);
  DCHECK(endpoints_[GetPeerPort(port)]);

  // The destination port need not be open, unlike the source port.
  if (!endpoints_[port])
    return MOJO_RESULT_FAILED_PRECONDITION;

  if (transports) {
    MojoResult result = AttachTransportsNoLock(port, message.get(), transports);
    if (result != MOJO_RESULT_OK)
      return result;
  }

  // The endpoint's |EnqueueMessage()| may not report failure.
  endpoints_[port]->EnqueueMessage(std::move(message));
  return MOJO_RESULT_OK;
}

MojoResult MessagePipe::AttachTransportsNoLock(
    unsigned port,
    MessageInTransit* message,
    std::vector<HandleTransport>* transports) {
  DCHECK(!message->has_handles());

  // Clone the handles and attach them to the message. (This must be done as a
  // separate loop, since we want to leave the handles alone on failure.)
  std::unique_ptr<HandleVector> handles(new HandleVector());
  handles->reserve(transports->size());
  for (size_t i = 0; i < transports->size(); i++) {
    if ((*transports)[i].is_valid()) {
      handles->push_back(
          transports->at(i).CreateEquivalentHandleAndClose(this, port));
    } else {
      LOG(WARNING) << "Enqueueing null dispatcher";
      handles->push_back(Handle());
    }
  }
  message->SetHandles(std::move(handles));
  return MOJO_RESULT_OK;
}

}  // namespace system
}  // namespace mojo
