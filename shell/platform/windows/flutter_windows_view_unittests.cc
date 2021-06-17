// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>
#include <vector>

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_texture_registrar.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

constexpr uint64_t kScanCodeKeyA = 0x1e;
constexpr uint64_t kVirtualKeyA = 0x41;

namespace {

// A struct to use as a FlutterPlatformMessageResponseHandle so it can keep the
// callbacks and user data passed to the engine's
// PlatformMessageCreateResponseHandle for use in the SendPlatformMessage
// overridden function.
struct TestResponseHandle {
  FlutterDesktopBinaryReply callback;
  void* user_data;
};

static const bool test_response = false;

constexpr uint64_t kKeyEventFromChannel = 0x11;
constexpr uint64_t kKeyEventFromEmbedder = 0x22;
static std::vector<int> key_event_logs;

std::unique_ptr<std::vector<uint8_t>> keyHandlingResponse(bool handled) {
  rapidjson::Document document;
  auto& allocator = document.GetAllocator();
  document.SetObject();
  document.AddMember("handled", test_response, allocator);
  return flutter::JsonMessageCodec::GetInstance().EncodeMessage(document);
}

// Returns an engine instance configured with dummy project path values, and
// overridden methods for sending platform messages, so that the engine can
// respond as if the framework were connected.
std::unique_ptr<FlutterWindowsEngine> GetTestEngine() {
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"C:\\foo\\flutter_assets";
  properties.icu_data_path = L"C:\\foo\\icudtl.dat";
  properties.aot_library_path = L"C:\\foo\\aot.so";
  FlutterProjectBundle project(properties);
  auto engine = std::make_unique<FlutterWindowsEngine>(project);

  EngineModifier modifier(engine.get());

  // This mock handles channel messages.  This mock handles key events sent
  // through the message channel is recorded in `key_event_logs`.
  modifier.embedder_api().SendPlatformMessage =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         const FlutterPlatformMessage* message) {
        if (std::string(message->channel) == std::string("flutter/settings")) {
          return kSuccess;
        }
        if (std::string(message->channel) == std::string("flutter/keyevent")) {
          key_event_logs.push_back(kKeyEventFromChannel);
          auto response = keyHandlingResponse(true);
          const TestResponseHandle* response_handle =
              reinterpret_cast<const TestResponseHandle*>(
                  message->response_handle);
          if (response_handle->callback != nullptr) {
            response_handle->callback(response->data(), response->size(),
                                      response_handle->user_data);
          }
          return kSuccess;
        }
        return kSuccess;
      };

  // This mock handles key events sent through the embedder API,
  // and records it in `key_event_logs`.
  modifier.embedder_api().SendKeyEvent =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine, const FlutterKeyEvent* event,
         FlutterKeyEventCallback callback, void* user_data) {
        key_event_logs.push_back(kKeyEventFromEmbedder);
        if (callback != nullptr) {
          callback(test_response, user_data);
        }
        return kSuccess;
      };

  // The following mocks enable channel mocking.
  modifier.embedder_api().PlatformMessageCreateResponseHandle =
      [](auto engine, auto data_callback, auto user_data, auto response_out) {
        TestResponseHandle* response_handle = new TestResponseHandle();
        response_handle->user_data = user_data;
        response_handle->callback = data_callback;
        *response_out = reinterpret_cast<FlutterPlatformMessageResponseHandle*>(
            response_handle);
        return kSuccess;
      };

  modifier.embedder_api().PlatformMessageReleaseResponseHandle =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
         FlutterPlatformMessageResponseHandle* response) {
        const TestResponseHandle* response_handle =
            reinterpret_cast<const TestResponseHandle*>(response);
        delete response_handle;
        return kSuccess;
      };

  // The following mocks allows RunWithEntrypoint to be run, which creates a
  // non-empty FlutterEngine and enables SendKeyEvent.

  modifier.embedder_api().Run =
      [](size_t version, const FlutterRendererConfig* config,
         const FlutterProjectArgs* args, void* user_data,
         FLUTTER_API_SYMBOL(FlutterEngine) * engine_out) {
        *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(1);

        return kSuccess;
      };
  modifier.embedder_api().UpdateLocales =
      [](auto engine, const FlutterLocale** locales, size_t locales_count) {
        return kSuccess;
      };
  modifier.embedder_api().SendWindowMetricsEvent =
      [](auto engine, const FlutterWindowMetricsEvent* event) {
        return kSuccess;
      };
  modifier.embedder_api().Shutdown = [](auto engine) { return kSuccess; };

  engine->RunWithEntrypoint(nullptr);
  return engine;
}

}  // namespace

TEST(FlutterWindowsViewTest, KeySequence) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(std::move(engine));

  view.OnKey(kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, false);

  EXPECT_EQ(key_event_logs.size(), 2);
  EXPECT_EQ(key_event_logs[0], kKeyEventFromEmbedder);
  EXPECT_EQ(key_event_logs[1], kKeyEventFromChannel);

  key_event_logs.clear();
}

}  // namespace testing
}  // namespace flutter
