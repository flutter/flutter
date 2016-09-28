// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/local_message_pipe_endpoint.h"

#include <string.h>

#include <utility>

#include "base/logging.h"
#include "mojo/edk/system/message_in_transit.h"

namespace mojo {
namespace system {

LocalMessagePipeEndpoint::LocalMessagePipeEndpoint(
    MessageInTransitQueue* message_queue)
    : is_open_(true), is_peer_open_(true) {
  if (message_queue)
    message_queue_.Swap(message_queue);
}

LocalMessagePipeEndpoint::~LocalMessagePipeEndpoint() {
  DCHECK(!is_open_);
  DCHECK(message_queue_.IsEmpty());  // Should be implied by not being open.
}

MessagePipeEndpoint::Type LocalMessagePipeEndpoint::GetType() const {
  return kTypeLocal;
}

bool LocalMessagePipeEndpoint::OnPeerClose() {
  DCHECK(is_open_);
  DCHECK(is_peer_open_);

  HandleSignalsState old_state = GetHandleSignalsState();
  is_peer_open_ = false;
  HandleSignalsState new_state = GetHandleSignalsState();

  if (!new_state.equals(old_state))
    awakable_list_.OnStateChange(old_state, new_state);

  return true;
}

void LocalMessagePipeEndpoint::EnqueueMessage(
    std::unique_ptr<MessageInTransit> message) {
  DCHECK(is_open_);
  DCHECK(is_peer_open_);

  HandleSignalsState old_state = GetHandleSignalsState();
  message_queue_.AddMessage(std::move(message));
  HandleSignalsState new_state = GetHandleSignalsState();

  if (!new_state.equals(old_state))
    awakable_list_.OnStateChange(old_state, new_state);
}

void LocalMessagePipeEndpoint::Close() {
  DCHECK(is_open_);
  is_open_ = false;
  message_queue_.Clear();
}

void LocalMessagePipeEndpoint::CancelAllState() {
  DCHECK(is_open_);
  awakable_list_.CancelAndRemoveAll();
}

MojoResult LocalMessagePipeEndpoint::ReadMessage(
    UserPointer<void> bytes,
    UserPointer<uint32_t> num_bytes,
    HandleVector* handles,
    uint32_t* num_handles,
    MojoReadMessageFlags flags) {
  DCHECK(is_open_);
  DCHECK(!handles || handles->empty());

  const uint32_t max_bytes = num_bytes.IsNull() ? 0 : num_bytes.Get();
  const uint32_t max_num_handles = num_handles ? *num_handles : 0;

  if (message_queue_.IsEmpty()) {
    return is_peer_open_ ? MOJO_RESULT_SHOULD_WAIT
                         : MOJO_RESULT_FAILED_PRECONDITION;
  }

  // TODO(vtl): If |flags & MOJO_READ_MESSAGE_FLAG_MAY_DISCARD|, we could pop
  // and release the lock immediately.
  bool enough_space = true;
  MessageInTransit* message = message_queue_.PeekMessage();
  if (!num_bytes.IsNull())
    num_bytes.Put(message->num_bytes());
  if (message->num_bytes() <= max_bytes)
    bytes.PutArray(message->bytes(), message->num_bytes());
  else
    enough_space = false;

  if (HandleVector* queued_handles = message->handles()) {
    if (num_handles)
      *num_handles = static_cast<uint32_t>(queued_handles->size());
    if (enough_space) {
      if (queued_handles->empty()) {
        // Nothing to do.
      } else if (queued_handles->size() <= max_num_handles) {
        DCHECK(handles);
        handles->swap(*queued_handles);
      } else {
        enough_space = false;
      }
    }
  } else {
    if (num_handles)
      *num_handles = 0;
  }

  message = nullptr;

  if (enough_space || (flags & MOJO_READ_MESSAGE_FLAG_MAY_DISCARD)) {
    HandleSignalsState old_state = GetHandleSignalsState();
    message_queue_.DiscardMessage();
    HandleSignalsState new_state = GetHandleSignalsState();

    if (!new_state.equals(old_state))
      awakable_list_.OnStateChange(old_state, new_state);
  }

  if (!enough_space)
    return MOJO_RESULT_RESOURCE_EXHAUSTED;

  return MOJO_RESULT_OK;
}

HandleSignalsState LocalMessagePipeEndpoint::GetHandleSignalsState() const {
  HandleSignalsState rv;
  if (!message_queue_.IsEmpty()) {
    rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_READABLE;
    rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_READABLE;
  }
  if (is_peer_open_) {
    rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_WRITABLE;
    rv.satisfiable_signals |=
        MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE;
  } else {
    rv.satisfied_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  }
  rv.satisfiable_signals |= MOJO_HANDLE_SIGNAL_PEER_CLOSED;
  return rv;
}

MojoResult LocalMessagePipeEndpoint::AddAwakable(
    Awakable* awakable,
    uint64_t context,
    bool persistent,
    MojoHandleSignals signals,
    HandleSignalsState* signals_state) {
  DCHECK(is_open_);

  HandleSignalsState state = GetHandleSignalsState();
  if (signals_state)
    *signals_state = state;
  MojoResult rv = MOJO_RESULT_OK;
  bool should_add = persistent;
  if (state.satisfies(signals))
    rv = MOJO_RESULT_ALREADY_EXISTS;
  else if (!state.can_satisfy(signals))
    rv = MOJO_RESULT_FAILED_PRECONDITION;
  else
    should_add = true;

  if (should_add)
    awakable_list_.Add(awakable, context, persistent, signals, state);
  return rv;
}

void LocalMessagePipeEndpoint::RemoveAwakable(
    bool match_context,
    Awakable* awakable,
    uint64_t context,
    HandleSignalsState* signals_state) {
  DCHECK(is_open_);
  awakable_list_.Remove(match_context, awakable, context);
  if (signals_state)
    *signals_state = GetHandleSignalsState();
}

}  // namespace system
}  // namespace mojo
