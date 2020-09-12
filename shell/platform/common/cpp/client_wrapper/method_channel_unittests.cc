// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/method_channel.h"

#include <memory>
#include <string>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/method_result_functions.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/standard_method_codec.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

class TestBinaryMessenger : public BinaryMessenger {
 public:
  void Send(const std::string& channel,
            const uint8_t* message,
            size_t message_size,
            BinaryReply reply) const override {
    send_called_ = true;
    last_reply_handler_ = reply;
  }

  void SetMessageHandler(const std::string& channel,
                         BinaryMessageHandler handler) override {
    last_message_handler_channel_ = channel;
    last_message_handler_ = handler;
  }

  bool send_called() { return send_called_; }

  BinaryReply last_reply_handler() { return last_reply_handler_; }

  std::string last_message_handler_channel() {
    return last_message_handler_channel_;
  }

  BinaryMessageHandler last_message_handler() { return last_message_handler_; }

 private:
  mutable bool send_called_ = false;
  mutable BinaryReply last_reply_handler_;
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
        result->Success();
      });
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_NE(messenger.last_message_handler(), nullptr);
  // Send a test message to trigger the handler test assertions.
  MethodCall<> call(method_name, nullptr);
  auto message = codec.EncodeMethodCall(call);

  messenger.last_message_handler()(
      message->data(), message->size(),
      [](const uint8_t* reply, size_t reply_size) {});
  EXPECT_TRUE(callback_called);
}

// Tests that SetMethodCallHandler with a null handler unregisters the handler.
TEST(MethodChannelTest, Unregistration) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  MethodChannel channel(&messenger, channel_name,
                        &StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler([](const auto& call, auto result) {});
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_NE(messenger.last_message_handler(), nullptr);

  channel.SetMethodCallHandler(nullptr);
  EXPECT_EQ(messenger.last_message_handler_channel(), channel_name);
  EXPECT_EQ(messenger.last_message_handler(), nullptr);
}

TEST(MethodChannelTest, InvokeWithoutResponse) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  MethodChannel channel(&messenger, channel_name,
                        &StandardMethodCodec::GetInstance());

  channel.InvokeMethod("foo", nullptr);
  EXPECT_TRUE(messenger.send_called());
  EXPECT_EQ(messenger.last_reply_handler(), nullptr);
}

TEST(MethodChannelTest, InvokeWithResponse) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  MethodChannel channel(&messenger, channel_name,
                        &StandardMethodCodec::GetInstance());

  bool received_reply = false;
  const std::string reply = "bar";
  auto result_handler = std::make_unique<MethodResultFunctions<>>(
      [&received_reply, reply](const EncodableValue* success_value) {
        received_reply = true;
        EXPECT_EQ(std::get<std::string>(*success_value), reply);
      },
      nullptr, nullptr);

  channel.InvokeMethod("foo", nullptr, std::move(result_handler));
  EXPECT_TRUE(messenger.send_called());
  ASSERT_NE(messenger.last_reply_handler(), nullptr);

  // Call the underlying reply handler to ensure it's processed correctly.
  EncodableValue reply_value(reply);
  std::unique_ptr<std::vector<uint8_t>> encoded_reply =
      StandardMethodCodec::GetInstance().EncodeSuccessEnvelope(&reply_value);
  messenger.last_reply_handler()(encoded_reply->data(), encoded_reply->size());
  EXPECT_TRUE(received_reply);
}

TEST(MethodChannelTest, InvokeNotImplemented) {
  TestBinaryMessenger messenger;
  const std::string channel_name("some_channel");
  MethodChannel channel(&messenger, channel_name,
                        &StandardMethodCodec::GetInstance());

  bool received_not_implemented = false;
  auto result_handler = std::make_unique<MethodResultFunctions<>>(
      nullptr, nullptr,
      [&received_not_implemented]() { received_not_implemented = true; });

  channel.InvokeMethod("foo", nullptr, std::move(result_handler));
  EXPECT_EQ(messenger.send_called(), true);
  ASSERT_NE(messenger.last_reply_handler(), nullptr);

  // Call the underlying reply handler to ensure it's reported as unimplemented.
  messenger.last_reply_handler()(nullptr, 0);
  EXPECT_TRUE(received_not_implemented);
}

}  // namespace flutter
