// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdlib.h>
#include <string.h>

#include "mojo/public/cpp/bindings/lib/message_builder.h"
#include "mojo/public/cpp/bindings/lib/message_queue.h"
#include "mojo/public/cpp/bindings/lib/router.h"
#include "mojo/public/cpp/environment/environment.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {
namespace {

void AllocRequestMessage(uint32_t name, const char* text, Message* message) {
  size_t payload_size = strlen(text) + 1;  // Plus null terminator.
  internal::RequestMessageBuilder builder(name, payload_size);
  memcpy(builder.buffer()->Allocate(payload_size), text, payload_size);
  builder.Finish(message);
}

void AllocResponseMessage(uint32_t name,
                          const char* text,
                          uint64_t request_id,
                          Message* message) {
  size_t payload_size = strlen(text) + 1;  // Plus null terminator.
  internal::ResponseMessageBuilder builder(name, payload_size, request_id);
  memcpy(builder.buffer()->Allocate(payload_size), text, payload_size);
  builder.Finish(message);
}

class MessageAccumulator : public MessageReceiver {
 public:
  explicit MessageAccumulator(internal::MessageQueue* queue) : queue_(queue) {}

  bool Accept(Message* message) override {
    queue_->Push(message);
    return true;
  }

 private:
  internal::MessageQueue* queue_;
};

class ResponseGenerator : public MessageReceiverWithResponderStatus {
 public:
  ResponseGenerator() {}

  bool Accept(Message* message) override { return false; }

  bool AcceptWithResponder(Message* message,
                           MessageReceiverWithStatus* responder) override {
    EXPECT_TRUE(message->has_flag(internal::kMessageExpectsResponse));

    bool result = SendResponse(
        message->name(), message->request_id(),
        reinterpret_cast<const char*>(message->payload()), responder);
    EXPECT_TRUE(responder->IsValid());
    delete responder;
    return result;
  }

  bool SendResponse(uint32_t name,
                    uint64_t request_id,
                    const char* request_string,
                    MessageReceiver* responder) {
    Message response;
    std::string response_string(request_string);
    response_string += " world!";
    AllocResponseMessage(name, response_string.c_str(), request_id, &response);

    return responder->Accept(&response);
  }
};

class LazyResponseGenerator : public ResponseGenerator {
 public:
  LazyResponseGenerator() : responder_(nullptr), name_(0), request_id_(0) {}

  ~LazyResponseGenerator() override { delete responder_; }

  bool AcceptWithResponder(Message* message,
                           MessageReceiverWithStatus* responder) override {
    name_ = message->name();
    request_id_ = message->request_id();
    request_string_ =
        std::string(reinterpret_cast<const char*>(message->payload()));
    responder_ = responder;
    return true;
  }

  bool has_responder() const { return !!responder_; }

  bool responder_is_valid() const { return responder_->IsValid(); }

  // Send the response and delete the responder.
  void CompleteWithResponse() { Complete(true); }

  // Delete the responder without sending a response.
  void CompleteWithoutResponse() { Complete(false); }

 private:
  // Completes the request handling by deleting responder_. Optionally
  // also sends a response.
  void Complete(bool send_response) {
    if (send_response) {
      SendResponse(name_, request_id_, request_string_.c_str(), responder_);
    }
    delete responder_;
    responder_ = nullptr;
  }

  MessageReceiverWithStatus* responder_;
  uint32_t name_;
  uint64_t request_id_;
  std::string request_string_;
};

class RouterTest : public testing::Test {
 public:
  RouterTest() {}

  void SetUp() override {
    CreateMessagePipe(nullptr, &handle0_, &handle1_);
  }

  void TearDown() override {}

  void PumpMessages() { loop_.RunUntilIdle(); }

 protected:
  ScopedMessagePipeHandle handle0_;
  ScopedMessagePipeHandle handle1_;

 private:
  Environment env_;
  RunLoop loop_;
};

TEST_F(RouterTest, BasicRequestResponse) {
  internal::Router router0(handle0_.Pass(), internal::FilterChain());
  internal::Router router1(handle1_.Pass(), internal::FilterChain());

  ResponseGenerator generator;
  router1.set_incoming_receiver(&generator);

  Message request;
  AllocRequestMessage(1, "hello", &request);

  internal::MessageQueue message_queue;
  router0.AcceptWithResponder(&request, new MessageAccumulator(&message_queue));

  PumpMessages();

  EXPECT_FALSE(message_queue.IsEmpty());

  Message response;
  message_queue.Pop(&response);

  EXPECT_EQ(std::string("hello world!"),
            std::string(reinterpret_cast<const char*>(response.payload())));

  // Send a second message on the pipe.
  Message request2;
  AllocRequestMessage(1, "hello again", &request2);

  router0.AcceptWithResponder(&request2,
                              new MessageAccumulator(&message_queue));

  PumpMessages();

  EXPECT_FALSE(message_queue.IsEmpty());

  message_queue.Pop(&response);

  EXPECT_EQ(std::string("hello again world!"),
            std::string(reinterpret_cast<const char*>(response.payload())));
}

TEST_F(RouterTest, BasicRequestResponse_Synchronous) {
  internal::Router router0(handle0_.Pass(), internal::FilterChain());
  internal::Router router1(handle1_.Pass(), internal::FilterChain());

  ResponseGenerator generator;
  router1.set_incoming_receiver(&generator);

  Message request;
  AllocRequestMessage(1, "hello", &request);

  internal::MessageQueue message_queue;
  router0.AcceptWithResponder(&request, new MessageAccumulator(&message_queue));

  router1.WaitForIncomingMessage(MOJO_DEADLINE_INDEFINITE);
  router0.WaitForIncomingMessage(MOJO_DEADLINE_INDEFINITE);

  EXPECT_FALSE(message_queue.IsEmpty());

  Message response;
  message_queue.Pop(&response);

  EXPECT_EQ(std::string("hello world!"),
            std::string(reinterpret_cast<const char*>(response.payload())));

  // Send a second message on the pipe.
  Message request2;
  AllocRequestMessage(1, "hello again", &request2);

  router0.AcceptWithResponder(&request2,
                              new MessageAccumulator(&message_queue));

  router1.WaitForIncomingMessage(MOJO_DEADLINE_INDEFINITE);
  router0.WaitForIncomingMessage(MOJO_DEADLINE_INDEFINITE);

  EXPECT_FALSE(message_queue.IsEmpty());

  message_queue.Pop(&response);

  EXPECT_EQ(std::string("hello again world!"),
            std::string(reinterpret_cast<const char*>(response.payload())));
}

TEST_F(RouterTest, RequestWithNoReceiver) {
  internal::Router router0(handle0_.Pass(), internal::FilterChain());
  internal::Router router1(handle1_.Pass(), internal::FilterChain());

  // Without an incoming receiver set on router1, we expect router0 to observe
  // an error as a result of sending a message.

  Message request;
  AllocRequestMessage(1, "hello", &request);

  internal::MessageQueue message_queue;
  router0.AcceptWithResponder(&request, new MessageAccumulator(&message_queue));

  PumpMessages();

  EXPECT_TRUE(router0.encountered_error());
  EXPECT_TRUE(router1.encountered_error());
  EXPECT_TRUE(message_queue.IsEmpty());
}

// Tests Router using the LazyResponseGenerator. The responses will not be
// sent until after the requests have been accepted.
TEST_F(RouterTest, LazyResponses) {
  internal::Router router0(handle0_.Pass(), internal::FilterChain());
  internal::Router router1(handle1_.Pass(), internal::FilterChain());

  LazyResponseGenerator generator;
  router1.set_incoming_receiver(&generator);

  Message request;
  AllocRequestMessage(1, "hello", &request);

  internal::MessageQueue message_queue;
  router0.AcceptWithResponder(&request, new MessageAccumulator(&message_queue));
  PumpMessages();

  // The request has been received but the response has not been sent yet.
  EXPECT_TRUE(message_queue.IsEmpty());

  // Send the response.
  EXPECT_TRUE(generator.responder_is_valid());
  generator.CompleteWithResponse();
  PumpMessages();

  // Check the response.
  EXPECT_FALSE(message_queue.IsEmpty());
  Message response;
  message_queue.Pop(&response);
  EXPECT_EQ(std::string("hello world!"),
            std::string(reinterpret_cast<const char*>(response.payload())));

  // Send a second message on the pipe.
  Message request2;
  AllocRequestMessage(1, "hello again", &request2);

  router0.AcceptWithResponder(&request2,
                              new MessageAccumulator(&message_queue));
  PumpMessages();

  // The request has been received but the response has not been sent yet.
  EXPECT_TRUE(message_queue.IsEmpty());

  // Send the second response.
  EXPECT_TRUE(generator.responder_is_valid());
  generator.CompleteWithResponse();
  PumpMessages();

  // Check the second response.
  EXPECT_FALSE(message_queue.IsEmpty());
  message_queue.Pop(&response);
  EXPECT_EQ(std::string("hello again world!"),
            std::string(reinterpret_cast<const char*>(response.payload())));
}

// Tests that if the receiving application destroys the responder_ without
// sending a response, then we close the Pipe as a way of signalling an
// error condition to the caller.
TEST_F(RouterTest, MissingResponses) {
  internal::Router router0(handle0_.Pass(), internal::FilterChain());
  internal::Router router1(handle1_.Pass(), internal::FilterChain());

  LazyResponseGenerator generator;
  router1.set_incoming_receiver(&generator);

  Message request;
  AllocRequestMessage(1, "hello", &request);

  internal::MessageQueue message_queue;
  router0.AcceptWithResponder(&request, new MessageAccumulator(&message_queue));
  PumpMessages();

  // The request has been received but no response has been sent.
  EXPECT_TRUE(message_queue.IsEmpty());

  // Destroy the responder MessagerReceiver but don't send any response.
  // This should close the pipe.
  generator.CompleteWithoutResponse();
  PumpMessages();

  // Check that no response was received.
  EXPECT_TRUE(message_queue.IsEmpty());

  // There is no direct way to test whether or not the pipe has been closed.
  // The only thing we can do is try to send a second message on the pipe
  // and observe that an error occurs.
  Message request2;
  AllocRequestMessage(1, "hello again", &request2);
  router0.AcceptWithResponder(&request2,
                              new MessageAccumulator(&message_queue));
  PumpMessages();

  // Make sure there was an error.
  EXPECT_TRUE(router0.encountered_error());
}

TEST_F(RouterTest, LateResponse) {
  // Test that things won't blow up if we try to send a message to a
  // MessageReceiver, which was given to us via AcceptWithResponder,
  // after the router has gone away.

  LazyResponseGenerator generator;
  {
    internal::Router router0(handle0_.Pass(), internal::FilterChain());
    internal::Router router1(handle1_.Pass(), internal::FilterChain());

    router1.set_incoming_receiver(&generator);

    Message request;
    AllocRequestMessage(1, "hello", &request);

    internal::MessageQueue message_queue;
    router0.AcceptWithResponder(&request,
                                new MessageAccumulator(&message_queue));

    PumpMessages();

    EXPECT_TRUE(generator.has_responder());
  }

  EXPECT_FALSE(generator.responder_is_valid());
  generator.CompleteWithResponse();  // This should end up doing nothing.
}

}  // namespace
}  // namespace test
}  // namespace mojo
