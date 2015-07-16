// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_MESSAGE_H_
#define MOJO_PUBLIC_CPP_BINDINGS_MESSAGE_H_

#include <vector>

#include "mojo/public/cpp/bindings/lib/message_internal.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojo {

// Message is a holder for the data and handles to be sent over a MessagePipe.
// Message owns its data and handles, but a consumer of Message is free to
// mutate the data and handles. The message's data is comprised of a header
// followed by payload.
class Message {
 public:
  Message();
  ~Message();

  // These may only be called on a newly created Message object.
  void AllocUninitializedData(uint32_t num_bytes);
  void AdoptData(uint32_t num_bytes, internal::MessageData* data);

  // Swaps data and handles between this Message and another.
  void Swap(Message* other);

  uint32_t data_num_bytes() const { return data_num_bytes_; }

  // Access the raw bytes of the message.
  const uint8_t* data() const {
    return reinterpret_cast<const uint8_t*>(data_);
  }
  uint8_t* mutable_data() { return reinterpret_cast<uint8_t*>(data_); }

  // Access the header.
  const internal::MessageHeader* header() const { return &data_->header; }

  uint32_t name() const { return data_->header.name; }
  bool has_flag(uint32_t flag) const { return !!(data_->header.flags & flag); }

  // Access the request_id field (if present).
  bool has_request_id() const { return data_->header.version >= 1; }
  uint64_t request_id() const {
    MOJO_DCHECK(has_request_id());
    return static_cast<const internal::MessageHeaderWithRequestID*>(
               &data_->header)->request_id;
  }
  void set_request_id(uint64_t request_id) {
    MOJO_DCHECK(has_request_id());
    static_cast<internal::MessageHeaderWithRequestID*>(&data_->header)
        ->request_id = request_id;
  }

  // Access the payload.
  const uint8_t* payload() const {
    return reinterpret_cast<const uint8_t*>(data_) + data_->header.num_bytes;
  }
  uint8_t* mutable_payload() {
    return reinterpret_cast<uint8_t*>(data_) + data_->header.num_bytes;
  }
  uint32_t payload_num_bytes() const {
    MOJO_DCHECK(data_num_bytes_ >= data_->header.num_bytes);
    return data_num_bytes_ - data_->header.num_bytes;
  }

  // Access the handles.
  const std::vector<Handle>* handles() const { return &handles_; }
  std::vector<Handle>* mutable_handles() { return &handles_; }

 private:
  uint32_t data_num_bytes_;
  internal::MessageData* data_;  // Heap-allocated using malloc.
  std::vector<Handle> handles_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Message);
};

class MessageReceiver {
 public:
  virtual ~MessageReceiver() {}

  // The receiver may mutate the given message.  Returns true if the message
  // was accepted and false otherwise, indicating that the message was invalid
  // or malformed.
  virtual bool Accept(Message* message) MOJO_WARN_UNUSED_RESULT = 0;
};

class MessageReceiverWithResponder : public MessageReceiver {
 public:
  ~MessageReceiverWithResponder() override {}

  // A variant on Accept that registers a MessageReceiver (known as the
  // responder) to handle the response message generated from the given
  // message. The responder's Accept method may be called during
  // AcceptWithResponder or some time after its return.
  //
  // NOTE: Upon returning true, AcceptWithResponder assumes ownership of
  // |responder| and will delete it after calling |responder->Accept| or upon
  // its own destruction.
  //
  virtual bool AcceptWithResponder(Message* message, MessageReceiver* responder)
      MOJO_WARN_UNUSED_RESULT = 0;
};

// A MessageReceiver that is also able to provide status about the state
// of the underlying MessagePipe to which it will be forwarding messages
// received via the |Accept()| call.
class MessageReceiverWithStatus : public MessageReceiver {
 public:
  ~MessageReceiverWithStatus() override {}

  // Returns |true| if this MessageReceiver is currently bound to a MessagePipe,
  // the pipe has not been closed, and the pipe has not encountered an error.
  virtual bool IsValid() = 0;
};

// An alternative to MessageReceiverWithResponder for cases in which it
// is necessary for the implementor of this interface to know about the status
// of the MessagePipe which will carry the responses.
class MessageReceiverWithResponderStatus : public MessageReceiver {
 public:
  ~MessageReceiverWithResponderStatus() override {}

  // A variant on Accept that registers a MessageReceiverWithStatus (known as
  // the responder) to handle the response message generated from the given
  // message. Any of the responder's methods (Accept or IsValid) may be called
  // during  AcceptWithResponder or some time after its return.
  //
  // NOTE: Upon returning true, AcceptWithResponder assumes ownership of
  // |responder| and will delete it after calling |responder->Accept| or upon
  // its own destruction.
  //
  virtual bool AcceptWithResponder(Message* message,
                                   MessageReceiverWithStatus* responder)
      MOJO_WARN_UNUSED_RESULT = 0;
};

// Read a single message from the pipe and dispatch to the given receiver.  The
// receiver may be null, in which case the message is simply discarded.
// Returns MOJO_RESULT_SHOULD_WAIT if the caller should wait on the handle to
// become readable. Returns MOJO_RESULT_OK if a message was dispatched and
// otherwise returns an error code if something went wrong.
//
// NOTE: The message hasn't been validated and may be malformed!
MojoResult ReadAndDispatchMessage(MessagePipeHandle handle,
                                  MessageReceiver* receiver,
                                  bool* receiver_result);

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_MESSAGE_H_
