// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_QUEUE_H_
#define MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_QUEUE_H_

#include <deque>
#include <memory>

#include "mojo/edk/system/message_in_transit.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// A simple queue for |MessageInTransit|s (that owns its messages).
// This class is not thread-safe.
class MessageInTransitQueue {
 public:
  MessageInTransitQueue();
  ~MessageInTransitQueue();

  bool IsEmpty() const { return queue_.empty(); }
  size_t Size() const { return queue_.size(); }

  void AddMessage(std::unique_ptr<MessageInTransit> message) {
    queue_.push_back(message.release());
  }

  std::unique_ptr<MessageInTransit> GetMessage() {
    MessageInTransit* rv = queue_.front();
    queue_.pop_front();
    return std::unique_ptr<MessageInTransit>(rv);
  }

  const MessageInTransit* PeekMessage() const { return queue_.front(); }
  MessageInTransit* PeekMessage() { return queue_.front(); }

  void DiscardMessage() {
    delete queue_.front();
    queue_.pop_front();
  }

  void Clear();

  // Efficiently swaps contents with |*other|.
  void Swap(MessageInTransitQueue* other);

 private:
  // TODO(vtl): When C++11 is available, switch this to a deque of
  // |unique_ptr|s.
  std::deque<MessageInTransit*> queue_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessageInTransitQueue);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_IN_TRANSIT_QUEUE_H_
