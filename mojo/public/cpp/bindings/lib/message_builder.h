// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_BUILDER_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_BUILDER_H_

#include <stdint.h>

#include "mojo/public/cpp/bindings/lib/fixed_buffer.h"
#include "mojo/public/cpp/bindings/lib/message_internal.h"

namespace mojo {
class Message;

namespace internal {

class MessageBuilder {
 public:
  MessageBuilder(uint32_t name, size_t payload_size);
  ~MessageBuilder();

  Buffer* buffer() { return &buf_; }

  // Call Finish when done making allocations in |buffer()|. Upon return,
  // |message| will contain the message data, and |buffer()| will no longer be
  // valid to reference.
  void Finish(Message* message);

 protected:
  explicit MessageBuilder(size_t size);
  FixedBuffer buf_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessageBuilder);
};

class MessageWithRequestIDBuilder : public MessageBuilder {
 public:
  MessageWithRequestIDBuilder(uint32_t name,
                              size_t payload_size,
                              uint32_t flags,
                              uint64_t request_id);
};

class RequestMessageBuilder : public MessageWithRequestIDBuilder {
 public:
  RequestMessageBuilder(uint32_t name, size_t payload_size)
      : MessageWithRequestIDBuilder(name,
                                    payload_size,
                                    kMessageExpectsResponse,
                                    0) {}
};

class ResponseMessageBuilder : public MessageWithRequestIDBuilder {
 public:
  ResponseMessageBuilder(uint32_t name,
                         size_t payload_size,
                         uint64_t request_id)
      : MessageWithRequestIDBuilder(name,
                                    payload_size,
                                    kMessageIsResponse,
                                    request_id) {}
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MESSAGE_BUILDER_H_
