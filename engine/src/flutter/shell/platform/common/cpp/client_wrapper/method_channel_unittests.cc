// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/method_channel.h"

#include <memory>
#include <string>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/standard_method_codec.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

class TestBinaryMessenger : public BinaryMessenger {
 public:
  void Send(const std::string& channel,
            const uint8_t* message,
            const size_t message_size) const override {}

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

// Tests that SetMethodCallHandler sets a handler that correctly interacts with
// the binary messenger.
TEST(MethodChannelTest, Registration) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  const StandardMethodCodec& codec = StandardMethodCodec::GetInstance();
  MethodChannel channel(&messenger, channel_name, &codec);

  bool callback_called = false;
  const std::string method_name("hello");
  channel.SetMethodCallHandler(
      [&callback_called, method_name](const auto& call, auto result) {
        callback_called = true;
        // Ensure that the wrapper recieved a correctly decoded call and a
        // result.
        EXPECT_EQ(call.method_name(), method_name);
        EXPECT_NE(result, nullptr);
      });
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_NE(messenger.last_message_handler(), nullptr);
  // Send a test message to trigger the handler test assertions.
  MethodCall<EncodableValue> call(method_name, nullptr);
  auto message = codec.EncodeMethodCall(call);

  messenger.last_message_handler()(
      message->data(), message->size(),
      [](const uint8_t* reply, const size_t reply_size) {});
  EXPECT_EQ(callback_called, true);
}

// Tests that SetMethodCallHandler with a null handler unregisters the handler.
TEST(MethodChannelTest, Unregistration) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  MethodChannel channel(&messenger, channel_name,
                        &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler([](const auto& call, auto result) {});
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_NE(messenger.last_message_handler(), nullptr);

  channel.SetMethodCallHandler(nullptr);
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_EQ(messenger.last_message_handler(), nullptr);
}

}  // namespace flutter
