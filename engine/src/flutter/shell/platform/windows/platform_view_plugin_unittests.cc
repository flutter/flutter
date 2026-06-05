// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_view_plugin.h"

#include <optional>
#include <string>

#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {
namespace {

constexpr char kPlatformViewType[] = "test_view";
constexpr PlatformViewId kPlatformViewId = 42;

uint64_t TestGetCurrentTime() {
  return 0;
}

struct FactoryCallState {
  int calls = 0;
  HWND hwnd = reinterpret_cast<HWND>(0x1234);
  HWND parent = nullptr;
  std::string type;
  PlatformViewId id = -1;
};

HWND TestPlatformViewFactory(
    const FlutterPlatformViewCreationParameters* params) {
  auto state = static_cast<FactoryCallState*>(params->user_data);
  state->calls++;
  state->parent = params->parent_window;
  state->type = params->platform_view_type;
  state->id = params->platform_view_id;
  return state->hwnd;
}

class PlatformViewPluginTest : public ::testing::Test {
 public:
  PlatformViewPluginTest()
      : task_runner_(TestGetCurrentTime, [](const FlutterTask*) {}),
        plugin_(&messenger_, &task_runner_) {}

 protected:
  FlutterPlatformViewTypeEntry MakeTypeEntry(FactoryCallState* state) {
    FlutterPlatformViewTypeEntry entry = {};
    entry.struct_size = sizeof(FlutterPlatformViewTypeEntry);
    entry.factory = TestPlatformViewFactory;
    entry.user_data = state;
    return entry;
  }

  TestBinaryMessenger messenger_;
  TaskRunner task_runner_;
  PlatformViewPlugin plugin_;
};

TEST_F(PlatformViewPluginTest, AddPlatformViewQueuesViewForInstantiation) {
  FactoryCallState state;
  plugin_.RegisterPlatformViewType(kPlatformViewType, MakeTypeEntry(&state));

  EXPECT_TRUE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));

  EXPECT_EQ(state.calls, 0);
  EXPECT_EQ(plugin_.GetNativeHandleForId(kPlatformViewId), std::nullopt);
}

TEST_F(PlatformViewPluginTest, InstantiatePlatformViewCreatesHwndOnce) {
  FactoryCallState state;
  HWND parent = reinterpret_cast<HWND>(0x5678);
  plugin_.RegisterPlatformViewType(kPlatformViewType, MakeTypeEntry(&state));
  ASSERT_TRUE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));

  EXPECT_TRUE(plugin_.InstantiatePlatformView(kPlatformViewId, parent));

  EXPECT_EQ(state.calls, 1);
  EXPECT_EQ(state.parent, parent);
  EXPECT_EQ(state.type, kPlatformViewType);
  EXPECT_EQ(state.id, kPlatformViewId);
  std::optional<HWND> handle = plugin_.GetNativeHandleForId(kPlatformViewId);
  ASSERT_TRUE(handle.has_value());
  EXPECT_EQ(handle.value(), state.hwnd);

  EXPECT_TRUE(plugin_.InstantiatePlatformView(kPlatformViewId, parent));
  EXPECT_EQ(state.calls, 1);
}

TEST_F(PlatformViewPluginTest, AddPlatformViewRejectsUnknownType) {
  EXPECT_FALSE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));
  EXPECT_EQ(plugin_.GetNativeHandleForId(kPlatformViewId), std::nullopt);
}

TEST_F(PlatformViewPluginTest, AddPlatformViewRejectsDuplicateId) {
  FactoryCallState state;
  plugin_.RegisterPlatformViewType(kPlatformViewType, MakeTypeEntry(&state));

  EXPECT_TRUE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));
  EXPECT_FALSE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));

  EXPECT_TRUE(plugin_.InstantiatePlatformView(kPlatformViewId, nullptr));
  EXPECT_FALSE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));
}

TEST_F(PlatformViewPluginTest, InstantiateUnknownPlatformViewDoesNothing) {
  EXPECT_FALSE(plugin_.InstantiatePlatformView(kPlatformViewId, nullptr));

  EXPECT_EQ(plugin_.GetNativeHandleForId(kPlatformViewId), std::nullopt);
}

TEST_F(PlatformViewPluginTest, FocusPlatformViewFailsBeforeInstantiation) {
  FactoryCallState state;
  plugin_.RegisterPlatformViewType(kPlatformViewType, MakeTypeEntry(&state));

  EXPECT_FALSE(plugin_.FocusPlatformView(
      kPlatformViewId, FocusChangeDirection::kProgrammatic, true));

  ASSERT_TRUE(plugin_.AddPlatformView(kPlatformViewId, kPlatformViewType));
  EXPECT_FALSE(plugin_.FocusPlatformView(
      kPlatformViewId, FocusChangeDirection::kProgrammatic, true));
}

}  // namespace
}  // namespace testing
}  // namespace flutter
