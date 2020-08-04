// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <string>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/basic_message_channel.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/standard_message_codec.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

class TestBinaryMessenger : public BinaryMessenger {
 public:
  void Send(const std::string& channel,
            const uint8_t* message,
            const size_t message_size,
            BinaryReply reply) const override {}

  void SetMessageHandler(const std::string& channel,
                         BinaryMessageHandler handler) override {
    last_message_handler_channel_ = channel;
    last_message_handler_ = handler;
  }

  std::string last_message_handler_channel() {
    return last_message_handler_channel_;
  }

  BinaryMessageHandler last_message_handler() { return last_message_handler_; }

 private:
  std::string last_message_handler_channel_;
  BinaryMessageHandler last_message_handler_;
};

}  // namespace

// Tests that SetMessageHandler sets a handler that correctly interacts with
// the binary messenger.
TEST(BasicMessageChannelTest, Registration) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  const StandardMessageCodec& codec = StandardMessageCodec::GetInstance();
  BasicMessageChannel channel(&messenger, channel_name, &codec);

  bool callback_called = false;
  const std::string message_value("hello");
  channel.SetMessageHandler(
      [&callback_called, message_value](const auto& message, auto reply) {
        callback_called = true;
        // Ensure that the wrapper recieved a correctly decoded message and a
        // reply.
        EXPECT_EQ(std::get<std::string>(message), message_value);
        EXPECT_NE(reply, nullptr);
      });
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_NE(messenger.last_message_handler(), nullptr);
  // Send a test message to trigger the handler test assertions.
  auto message = codec.EncodeMessage(EncodableValue(message_value));

  messenger.last_message_handler()(
      message->data(), message->size(),
      [](const uint8_t* reply, const size_t reply_size) {});
  EXPECT_EQ(callback_called, true);
}

// Tests that SetMessageHandler with a null handler unregisters the handler.
TEST(BasicMessageChannelTest, Unregistration) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  BasicMessageChannel channel(&messenger, channel_name,
                              &flutter::StandardMessageCodec::GetInstance());

  channel.SetMessageHandler([](const auto& message, auto reply) {});
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_NE(messenger.last_message_handler(), nullptr);

  channel.SetMessageHandler(nullptr);
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_EQ(messenger.last_message_handler(), nullptr);
}

}  // namespace flutter
