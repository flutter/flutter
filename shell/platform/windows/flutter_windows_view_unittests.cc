// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_view.h"

#include <comdef.h>
#include <comutil.h>
#include <oleacc.h>

#include <iostream>
#include <vector>

#include "flutter/shell/platform/common/json_message_codec.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_texture_registrar.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_keyboard.h"

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

static bool test_response = false;

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
  MockEmbedderApiForKeyboard(
      modifier,
      [] {
        key_event_logs.push_back(kKeyEventFromChannel);
        return test_response;
      },
      [](const FlutterKeyEvent* event) {
        key_event_logs.push_back(kKeyEventFromEmbedder);
        return test_response;
      });

  engine->RunWithEntrypoint(nullptr);
  return engine;
}

}  // namespace

TEST(FlutterWindowsViewTest, KeySequence) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();

  test_response = false;

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

TEST(FlutterWindowsViewTest, RestartClearsKeyboardState) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(std::move(engine));

  test_response = false;

  // Receives a KeyA down. Events are dispatched and decided unhandled. Now the
  // keyboard key handler is waiting for the redispatched event.
  view.OnKey(kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, false);
  EXPECT_EQ(key_event_logs.size(), 2);
  EXPECT_EQ(key_event_logs[0], kKeyEventFromEmbedder);
  EXPECT_EQ(key_event_logs[1], kKeyEventFromChannel);
  key_event_logs.clear();

  // Resets state so that the keyboard key handler is no longer waiting.
  view.OnPreEngineRestart();

  // Receives another KeyA down. If the state had not been cleared, this event
  // will be considered the redispatched event and ignored.
  view.OnKey(kVirtualKeyA, kScanCodeKeyA, WM_KEYDOWN, 'a', false, false);
  EXPECT_EQ(key_event_logs.size(), 2);
  EXPECT_EQ(key_event_logs[0], kKeyEventFromEmbedder);
  EXPECT_EQ(key_event_logs[1], kKeyEventFromChannel);
  key_event_logs.clear();
}

TEST(FlutterWindowsViewTest, EnableSemantics) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  EngineModifier modifier(engine.get());

  bool semantics_enabled = false;
  modifier.embedder_api().UpdateSemanticsEnabled = MOCK_ENGINE_PROC(
      UpdateSemanticsEnabled,
      [&semantics_enabled](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                           bool enabled) {
        semantics_enabled = enabled;
        return kSuccess;
      });

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(std::move(engine));

  view.OnUpdateSemanticsEnabled(true);
  EXPECT_TRUE(semantics_enabled);
}

TEST(FlutterWindowsEngine, AddSemanticsNodeUpdate) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  EngineModifier modifier(engine.get());
  modifier.embedder_api().UpdateSemanticsEnabled =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine, bool enabled) {
        return kSuccess;
      };

  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(std::move(engine));

  // Enable semantics to instantiate accessibility bridge.
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  ASSERT_TRUE(bridge);

  // Add root node.
  FlutterSemanticsNode node{sizeof(FlutterSemanticsNode), 0};
  node.label = "name";
  node.value = "value";
  node.platform_view_id = -1;
  bridge->AddFlutterSemanticsNodeUpdate(&node);
  bridge->CommitUpdates();

  // Look up the root windows node delegate.
  auto node_delegate = bridge
                           ->GetFlutterPlatformNodeDelegateFromID(
                               AccessibilityBridge::kRootNodeId)
                           .lock();
  ASSERT_TRUE(node_delegate);
  EXPECT_EQ(node_delegate->GetChildCount(), 0);

  // Get the native IAccessible object.
  IAccessible* native_view = node_delegate->GetNativeViewAccessible();
  ASSERT_TRUE(native_view != nullptr);

  // Property lookups will be made against this node itself.
  VARIANT varchild{};
  varchild.vt = VT_I4;
  varchild.lVal = CHILDID_SELF;

  // Verify node name matches our label.
  BSTR bname = nullptr;
  ASSERT_EQ(native_view->get_accName(varchild, &bname), S_OK);
  std::string name(_com_util::ConvertBSTRToString(bname));
  EXPECT_EQ(name, "name");

  // Verify node value matches.
  BSTR bvalue = nullptr;
  ASSERT_EQ(native_view->get_accValue(varchild, &bvalue), S_OK);
  std::string value(_com_util::ConvertBSTRToString(bvalue));
  EXPECT_EQ(value, "value");

  // Verify node type is a group.
  VARIANT varrole{};
  varrole.vt = VT_I4;
  ASSERT_EQ(native_view->get_accRole(varchild, &varrole), S_OK);
  EXPECT_EQ(varrole.lVal, ROLE_SYSTEM_STATICTEXT);
}

}  // namespace testing
}  // namespace flutter
