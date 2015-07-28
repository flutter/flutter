// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_QUEUE_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_QUEUE_H_

#include <queue>

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
class Message;

namespace test {

// A queue for Message objects.
class MessageQueue {
 public:
  MessageQueue();
  ~MessageQueue();

  bool IsEmpty() const;

  // This method copies the message data and steals ownership of its handles.
  void Push(Message* message);

  // Removes the next message from the queue, copying its data and transferring
  // ownership of its handles to the given |message|.
  void Pop(Message* message);

 private:
  void Pop();

  std::queue<Message*> queue_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessageQueue);
};

}  // namespace test
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_QUEUE_H_
