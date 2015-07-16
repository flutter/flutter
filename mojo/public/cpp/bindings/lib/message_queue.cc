// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/message_queue.h"

#include "mojo/public/cpp/bindings/message.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojo {
namespace internal {

MessageQueue::MessageQueue() {
}

MessageQueue::~MessageQueue() {
  while (!queue_.empty())
    Pop();
}

bool MessageQueue::IsEmpty() const {
  return queue_.empty();
}

Message* MessageQueue::Peek() {
  MOJO_DCHECK(!queue_.empty());
  return queue_.front();
}

void MessageQueue::Push(Message* message) {
  queue_.push(new Message());
  queue_.back()->Swap(message);
}

void MessageQueue::Pop(Message* message) {
  MOJO_DCHECK(!queue_.empty());
  queue_.front()->Swap(message);
  Pop();
}

void MessageQueue::Pop() {
  MOJO_DCHECK(!queue_.empty());
  delete queue_.front();
  queue_.pop();
}

}  // namespace internal
}  // namespace mojo
