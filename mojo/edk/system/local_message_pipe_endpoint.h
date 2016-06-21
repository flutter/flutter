// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_LOCAL_MESSAGE_PIPE_ENDPOINT_H_
#define MOJO_EDK_SYSTEM_LOCAL_MESSAGE_PIPE_ENDPOINT_H_

#include "mojo/edk/system/awakable_list.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/message_in_transit_queue.h"
#include "mojo/edk/system/message_pipe_endpoint.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class LocalMessagePipeEndpoint final : public MessagePipeEndpoint {
 public:
  // If |message_queue| is non-null, its contents will be taken as the queue of
  // (already-received) messages.
  explicit LocalMessagePipeEndpoint(
      MessageInTransitQueue* message_queue = nullptr);
  ~LocalMessagePipeEndpoint() override;

  // |MessagePipeEndpoint| implementation:
  Type GetType() const override;
  bool OnPeerClose() override;
  void EnqueueMessage(std::unique_ptr<MessageInTransit> message) override;

  // There's a dispatcher for |LocalMessagePipeEndpoint|s, so we have to
  // implement/override these:
  void Close() override;
  void CancelAllState() override;
  MojoResult ReadMessage(UserPointer<void> bytes,
                         UserPointer<uint32_t> num_bytes,
                         HandleVector* handles,
                         uint32_t* num_handles,
                         MojoReadMessageFlags flags) override;
  HandleSignalsState GetHandleSignalsState() const override;
  MojoResult AddAwakable(Awakable* awakable,
                         MojoHandleSignals signals,
                         bool force,
                         uint64_t context,
                         HandleSignalsState* signals_state) override;
  void RemoveAwakable(Awakable* awakable,
                      HandleSignalsState* signals_state) override;

  // This is only to be used by |MessagePipe|:
  MessageInTransitQueue* message_queue() { return &message_queue_; }

 private:
  bool is_open_;
  bool is_peer_open_;

  // Queue of incoming messages.
  MessageInTransitQueue message_queue_;
  AwakableList awakable_list_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(LocalMessagePipeEndpoint);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_LOCAL_MESSAGE_PIPE_ENDPOINT_H_
