// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_pipe_dispatcher.h"

#include "base/logging.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/local_message_pipe_endpoint.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/options_validation.h"
#include "mojo/edk/system/proxy_message_pipe_endpoint.h"

namespace mojo {
namespace system {

const unsigned kInvalidPort = static_cast<unsigned>(-1);

// MessagePipeDispatcher -------------------------------------------------------

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

void MessagePipeDispatcher::Init(scoped_refptr<MessagePipe> message_pipe,
                                 unsigned port) {
  DCHECK(message_pipe);
  DCHECK(port == 0 || port == 1);

  message_pipe_ = message_pipe;
  port_ = port;
}

Dispatcher::Type MessagePipeDispatcher::GetType() const {
  return Type::MESSAGE_PIPE;
}

// static
scoped_refptr<MessagePipeDispatcher>
MessagePipeDispatcher::CreateRemoteMessagePipe(
    scoped_refptr<ChannelEndpoint>* channel_endpoint) {
  scoped_refptr<MessagePipe> message_pipe(
      MessagePipe::CreateLocalProxy(channel_endpoint));
  scoped_refptr<MessagePipeDispatcher> dispatcher =
      Create(kDefaultCreateOptions);
  dispatcher->Init(message_pipe, 0);
  return dispatcher;
}

// static
scoped_refptr<MessagePipeDispatcher> MessagePipeDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size) {
  unsigned port = kInvalidPort;
  scoped_refptr<MessagePipe> message_pipe;
  if (!MessagePipe::Deserialize(channel, source, size, &message_pipe, &port))
    return nullptr;
  DCHECK(message_pipe);
  DCHECK(port == 0 || port == 1);

  scoped_refptr<MessagePipeDispatcher> dispatcher =
      Create(kDefaultCreateOptions);
  dispatcher->Init(message_pipe, port);
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

void MessagePipeDispatcher::CancelAllAwakablesNoLock() {
  mutex().AssertHeld();
  message_pipe_->CancelAllAwakables(port_);
}

void MessagePipeDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  message_pipe_->Close(port_);
  message_pipe_ = nullptr;
  port_ = kInvalidPort;
}

scoped_refptr<Dispatcher>
MessagePipeDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock() {
  mutex().AssertHeld();

  // TODO(vtl): Currently, there are no options, so we just use
  // |kDefaultCreateOptions|. Eventually, we'll have to duplicate the options
  // too.
  scoped_refptr<MessagePipeDispatcher> rv = Create(kDefaultCreateOptions);
  rv->Init(message_pipe_, port_);
  message_pipe_ = nullptr;
  port_ = kInvalidPort;
  return scoped_refptr<Dispatcher>(rv.get());
}

MojoResult MessagePipeDispatcher::WriteMessageImplNoLock(
    UserPointer<const void> bytes,
    uint32_t num_bytes,
    std::vector<DispatcherTransport>* transports,
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
    DispatcherVector* dispatchers,
    uint32_t* num_dispatchers,
    MojoReadMessageFlags flags) {
  mutex().AssertHeld();
  return message_pipe_->ReadMessage(port_, bytes, num_bytes, dispatchers,
                                    num_dispatchers, flags);
}

HandleSignalsState MessagePipeDispatcher::GetHandleSignalsStateImplNoLock()
    const {
  mutex().AssertHeld();
  return message_pipe_->GetHandleSignalsState(port_);
}

MojoResult MessagePipeDispatcher::AddAwakableImplNoLock(
    Awakable* awakable,
    MojoHandleSignals signals,
    uint32_t context,
    HandleSignalsState* signals_state) {
  mutex().AssertHeld();
  return message_pipe_->AddAwakable(port_, awakable, signals, context,
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
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.
  return message_pipe_->StartSerialize(port_, channel, max_size,
                                       max_platform_handles);
}

bool MessagePipeDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* channel,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.

  bool rv = message_pipe_->EndSerialize(port_, channel, destination,
                                        actual_size, platform_handles);
  message_pipe_ = nullptr;
  port_ = kInvalidPort;
  return rv;
}

// MessagePipeDispatcherTransport ----------------------------------------------

MessagePipeDispatcherTransport::MessagePipeDispatcherTransport(
    DispatcherTransport transport)
    : DispatcherTransport(transport) {
  DCHECK_EQ(message_pipe_dispatcher()->GetType(),
            Dispatcher::Type::MESSAGE_PIPE);
}

}  // namespace system
}  // namespace mojo
