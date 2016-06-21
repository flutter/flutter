// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_pipe_dispatcher.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/handle_transport.h"
#include "mojo/edk/system/local_message_pipe_endpoint.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/options_validation.h"
#include "mojo/edk/system/proxy_message_pipe_endpoint.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

const unsigned kInvalidPort = static_cast<unsigned>(-1);

// MessagePipeDispatcher -------------------------------------------------------

// static
constexpr MojoHandleRights MessagePipeDispatcher::kDefaultHandleRights;

// static
const MojoCreateMessagePipeOptions
    MessagePipeDispatcher::kDefaultCreateOptions = {
        static_cast<uint32_t>(sizeof(MojoCreateMessagePipeOptions)),
        MOJO_CREATE_MESSAGE_PIPE_OPTIONS_FLAG_NONE};

// static
MojoResult MessagePipeDispatcher::ValidateCreateOptions(
    UserPointer<const MojoCreateMessagePipeOptions> in_options,
    MojoCreateMessagePipeOptions* out_options) {
  const MojoCreateMessagePipeOptionsFlags kKnownFlags =
      MOJO_CREATE_MESSAGE_PIPE_OPTIONS_FLAG_NONE;

  *out_options = kDefaultCreateOptions;
  if (in_options.IsNull())
    return MOJO_RESULT_OK;

  UserOptionsReader<MojoCreateMessagePipeOptions> reader(in_options);
  if (!reader.is_valid())
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!OPTIONS_STRUCT_HAS_MEMBER(MojoCreateMessagePipeOptions, flags, reader))
    return MOJO_RESULT_OK;
  if ((reader.options().flags & ~kKnownFlags))
    return MOJO_RESULT_UNIMPLEMENTED;
  out_options->flags = reader.options().flags;

  // Checks for fields beyond |flags|:

  // (Nothing here yet.)

  return MOJO_RESULT_OK;
}

void MessagePipeDispatcher::Init(RefPtr<MessagePipe>&& message_pipe,
                                 unsigned port) {
  DCHECK(message_pipe);
  DCHECK(port == 0 || port == 1);

  message_pipe_ = std::move(message_pipe);
  port_ = port;
}

Dispatcher::Type MessagePipeDispatcher::GetType() const {
  return Type::MESSAGE_PIPE;
}

bool MessagePipeDispatcher::SupportsEntrypointClass(
    EntrypointClass entrypoint_class) const {
  return (entrypoint_class == EntrypointClass::NONE ||
          entrypoint_class == EntrypointClass::MESSAGE_PIPE);
}

// static
RefPtr<MessagePipeDispatcher> MessagePipeDispatcher::CreateRemoteMessagePipe(
    RefPtr<ChannelEndpoint>* channel_endpoint) {
  auto message_pipe = MessagePipe::CreateLocalProxy(channel_endpoint);
  auto dispatcher = MessagePipeDispatcher::Create(kDefaultCreateOptions);
  dispatcher->Init(std::move(message_pipe), 0);
  return dispatcher;
}

// static
RefPtr<MessagePipeDispatcher> MessagePipeDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size) {
  unsigned port = kInvalidPort;
  RefPtr<MessagePipe> message_pipe;
  if (!MessagePipe::Deserialize(channel, source, size, &message_pipe, &port))
    return nullptr;
  DCHECK(message_pipe);
  DCHECK(port == 0 || port == 1);

  auto dispatcher = MessagePipeDispatcher::Create(kDefaultCreateOptions);
  dispatcher->Init(std::move(message_pipe), port);
  return dispatcher;
}

MessagePipeDispatcher::MessagePipeDispatcher() : port_(kInvalidPort) {
}

MessagePipeDispatcher::~MessagePipeDispatcher() {
  // |Close()|/|CloseImplNoLock()| should have taken care of the pipe.
  DCHECK(!message_pipe_);
}

MessagePipe* MessagePipeDispatcher::GetMessagePipeNoLock() const {
  mutex().AssertHeld();
  return message_pipe_.get();
}

unsigned MessagePipeDispatcher::GetPortNoLock() const {
  mutex().AssertHeld();
  return port_;
}

void MessagePipeDispatcher::CancelAllStateNoLock() {
  mutex().AssertHeld();
  message_pipe_->CancelAllState(port_);
}

void MessagePipeDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  message_pipe_->Close(port_);
  message_pipe_ = nullptr;
  port_ = kInvalidPort;
}

RefPtr<Dispatcher>
MessagePipeDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock(
    MessagePipe* message_pipe,
    unsigned port) {
  mutex().AssertHeld();

  // "We" are being sent over our peer.
  // If |message_pipe| is null, the |if| condition below should be false.
  DCHECK(message_pipe_.get());
  if (message_pipe == message_pipe_.get()) {
    // A message pipe dispatcher can't be sent over itself (this should be
    // disallowed by |Core|). Note that |port| is the destination port.
    DCHECK_EQ(port, port_);
    // In this case, |message_pipe_|'s mutex should already be held!
    message_pipe_->CancelAllStateNoLock(port_);
  } else {
    CancelAllStateNoLock();
  }

  // TODO(vtl): Currently, there are no options, so we just use
  // |kDefaultCreateOptions|. Eventually, we'll have to duplicate the options
  // too.
  auto dispatcher = MessagePipeDispatcher::Create(kDefaultCreateOptions);
  dispatcher->Init(std::move(message_pipe_), port_);
  port_ = kInvalidPort;
  return dispatcher;
}

MojoResult MessagePipeDispatcher::WriteMessageImplNoLock(
    UserPointer<const void> bytes,
    uint32_t num_bytes,
    std::vector<HandleTransport>* transports,
    MojoWriteMessageFlags flags) {
  DCHECK(!transports ||
         (transports->size() > 0 &&
          transports->size() <= GetConfiguration().max_message_num_handles));

  mutex().AssertHeld();

  if (num_bytes > GetConfiguration().max_message_num_bytes)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  return message_pipe_->WriteMessage(port_, bytes, num_bytes, transports,
                                     flags);
}

MojoResult MessagePipeDispatcher::ReadMessageImplNoLock(
    UserPointer<void> bytes,
    UserPointer<uint32_t> num_bytes,
    HandleVector* handles,
    uint32_t* num_handles,
    MojoReadMessageFlags flags) {
  mutex().AssertHeld();
  return message_pipe_->ReadMessage(port_, bytes, num_bytes, handles,
                                    num_handles, flags);
}

HandleSignalsState MessagePipeDispatcher::GetHandleSignalsStateImplNoLock()
    const {
  mutex().AssertHeld();
  return message_pipe_->GetHandleSignalsState(port_);
}

MojoResult MessagePipeDispatcher::AddAwakableImplNoLock(
    Awakable* awakable,
    MojoHandleSignals signals,
    bool force,
    uint64_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  return message_pipe_->AddAwakable(port_, awakable, signals, force, context,
                                    signals_state);
}

void MessagePipeDispatcher::RemoveAwakableImplNoLock(
    Awakable* awakable,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  message_pipe_->RemoveAwakable(port_, awakable, signals_state);
}

void MessagePipeDispatcher::StartSerializeImplNoLock(
    Channel* channel,
    size_t* max_size,
    size_t* max_platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  return message_pipe_->StartSerialize(port_, channel, max_size,
                                       max_platform_handles);
}

bool MessagePipeDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.

  bool rv = message_pipe_->EndSerialize(port_, channel, destination,
                                        actual_size, platform_handles);
  message_pipe_ = nullptr;
  port_ = kInvalidPort;
  return rv;
}

}  // namespace system
}  // namespace mojo
