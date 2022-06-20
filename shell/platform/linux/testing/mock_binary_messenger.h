// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_BINARY_MESSENGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_BINARY_MESSENGER_H_

#include <unordered_map>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

#include "gmock/gmock.h"

namespace flutter {
namespace testing {

// Mock for FlBinaryMessenger.
class MockBinaryMessenger {
 public:
  MockBinaryMessenger();
  ~MockBinaryMessenger();

  operator FlBinaryMessenger*();

  MOCK_METHOD5(fl_binary_messenger_set_message_handler_on_channel,
               void(FlBinaryMessenger* messenger,
                    const gchar* channel,
                    FlBinaryMessengerMessageHandler handler,
                    gpointer user_data,
                    GDestroyNotify destroy_notify));

  MOCK_METHOD4(fl_binary_messenger_send_response,
               gboolean(FlBinaryMessenger* messenger,
                        FlBinaryMessengerResponseHandle* response_handle,
                        GBytes* response,
                        GError** error));

  MOCK_METHOD6(fl_binary_messenger_send_on_channel,
               void(FlBinaryMessenger* messenger,
                    const gchar* channel,
                    GBytes* message,
                    GCancellable* cancellable,
                    GAsyncReadyCallback callback,
                    gpointer user_data));

  MOCK_METHOD3(fl_binary_messenger_send_on_channel_finish,
               GBytes*(FlBinaryMessenger* messenger,
                       GAsyncResult* result,
                       GError** error));

  bool HasMessageHandler(const gchar* channel) const;

  void SetMessageHandler(const gchar* channel,
                         FlBinaryMessengerMessageHandler handler,
                         gpointer user_data);

  void ReceiveMessage(const gchar* channel, GBytes* message);

 private:
  FlBinaryMessenger* instance_ = nullptr;
  std::unordered_map<std::string, FlBinaryMessengerMessageHandler>
      message_handlers;
  std::unordered_map<std::string, FlBinaryMessengerResponseHandle*>
      response_handles;
  std::unordered_map<std::string, gpointer> user_datas;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_BINARY_MESSENGER_H_
