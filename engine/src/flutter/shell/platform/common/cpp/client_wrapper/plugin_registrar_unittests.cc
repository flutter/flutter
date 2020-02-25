// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <vector>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/cpp/client_wrapper/testing/stub_flutter_api.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

// Stub implementation to validate calls to the API.
class TestApi : public testing::StubFlutterApi {
 public:
  // |flutter::testing::StubFlutterApi|
  bool MessengerSend(const char* channel,
                     const uint8_t* message,
                     const size_t message_size) override {
    last_data_sent_ = message;
    return message_engine_result;
  }

  bool MessengerSendWithReply(const char* channel,
                              const uint8_t* message,
                              const size_t message_size,
                              const FlutterDesktopBinaryReply reply,
                              void* user_data) override {
    last_data_sent_ = message;
    return message_engine_result;
  }

  // Called for FlutterDesktopMessengerSetCallback.
  void MessengerSetCallback(const char* channel,
                            FlutterDesktopMessageCallback callback,
                            void* user_data) override {
    last_callback_set_ = callback;
  }

  const uint8_t* last_data_sent() { return last_data_sent_; }
  FlutterDesktopMessageCallback last_callback_set() {
    return last_callback_set_;
  }

 private:
  const uint8_t* last_data_sent_ = nullptr;
  FlutterDesktopMessageCallback last_callback_set_ = nullptr;
};

}  // namespace

// Tests that the registrar returns a messenger that passes Send through to the
// C API.
TEST(MethodCallTest, MessengerSend) {
  testing::ScopedStubFlutterApi scoped_api_stub(std::make_unique<TestApi>());
  auto test_api = static_cast<TestApi*>(scoped_api_stub.stub());

  auto dummy_registrar_handle =
      reinterpret_cast<FlutterDesktopPluginRegistrarRef>(1);
  PluginRegistrar registrar(dummy_registrar_handle);
  BinaryMessenger* messenger = registrar.messenger();

  std::vector<uint8_t> message = {1, 2, 3, 4};
  messenger->Send("some_channel", &message[0], message.size());
  EXPECT_EQ(test_api->last_data_sent(), &message[0]);
}

// Tests that the registrar returns a messenger that passes callback
// registration and unregistration through to the C API.
TEST(MethodCallTest, MessengerSetMessageHandler) {
  testing::ScopedStubFlutterApi scoped_api_stub(std::make_unique<TestApi>());
  auto test_api = static_cast<TestApi*>(scoped_api_stub.stub());

  auto dummy_registrar_handle =
      reinterpret_cast<FlutterDesktopPluginRegistrarRef>(1);
  PluginRegistrar registrar(dummy_registrar_handle);
  BinaryMessenger* messenger = registrar.messenger();
  const std::string channel_name("foo");

  // Register.
  BinaryMessageHandler binary_handler = [](const uint8_t* message,
                                           const size_t message_size,
                                           BinaryReply reply) {};
  messenger->SetMessageHandler(channel_name, std::move(binary_handler));
  EXPECT_NE(test_api->last_callback_set(), nullptr);

  // Unregister.
  messenger->SetMessageHandler(channel_name, nullptr);
  EXPECT_EQ(test_api->last_callback_set(), nullptr);
}

}  // namespace flutter
