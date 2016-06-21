// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_PIPE_ENDPOINT_H_
#define MOJO_EDK_SYSTEM_MESSAGE_PIPE_ENDPOINT_H_

#include <stdint.h>

#include <memory>
#include <vector>

#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/c/system/message_pipe.h"
#include "mojo/public/c/system/result.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class ChannelEndpoint;
class Awakable;

// This is an interface to one of the ends of a message pipe, and is used by
// |MessagePipe|. Its most important role is to provide a sink for messages
// (i.e., a place where messages can be sent). It has a secondary role: When the
// endpoint is local (i.e., in the current process), there'll be a dispatcher
// corresponding to the endpoint. In that case, the implementation of
// |MessagePipeEndpoint| also implements the functionality required by the
// dispatcher, e.g., to read messages and to wait. Implementations of this class
// are not thread-safe; instances are protected by |MesssagePipe|'s lock.
class MessagePipeEndpoint {
 public:
  virtual ~MessagePipeEndpoint() {}

  enum Type { kTypeLocal, kTypeProxy };
  virtual Type GetType() const = 0;

  // All implementations must implement these.
  // Returns false if the endpoint should be closed and destroyed, else true.
  virtual bool OnPeerClose() = 0;
  // Implements |MessagePipe::EnqueueMessage()|. The major differences are that:
  //  a) Dispatchers have been vetted and cloned/attached to the message.
  //  b) At this point, we cannot report failure (if, e.g., a channel is torn
  //     down at this point, we should silently swallow the message).
  virtual void EnqueueMessage(std::unique_ptr<MessageInTransit> message) = 0;
  virtual void Close() = 0;

  // Implementations must override these if they represent a local endpoint,
  // i.e., one for which there's a |MessagePipeDispatcher| (and thus a handle).
  // An implementation for a proxy endpoint (for which there's no dispatcher)
  // needs not override these methods, since they should never be called.
  //
  // These methods implement the methods of the same name in |MessagePipe|,
  // though |MessagePipe|'s implementation may have to do a little more if the
  // operation involves both endpoints.
  virtual void CancelAllState();
  virtual MojoResult ReadMessage(UserPointer<void> bytes,
                                 UserPointer<uint32_t> num_bytes,
                                 HandleVector* handles,
                                 uint32_t* num_handles,
                                 MojoReadMessageFlags flags);
  virtual HandleSignalsState GetHandleSignalsState() const;
  virtual MojoResult AddAwakable(Awakable* awakable,
                                 MojoHandleSignals signals,
                                 bool force,
                                 uint64_t context,
                                 HandleSignalsState* signals_state);
  virtual void RemoveAwakable(Awakable* awakable,
                              HandleSignalsState* signals_state);

  // Implementations must override these if they represent a proxy endpoint. An
  // implementation for a local endpoint needs not override these methods, since
  // they should never be called.
  virtual void Attach(ChannelEndpoint* channel_endpoint);

 protected:
  MessagePipeEndpoint() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(MessagePipeEndpoint);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_PIPE_ENDPOINT_H_
