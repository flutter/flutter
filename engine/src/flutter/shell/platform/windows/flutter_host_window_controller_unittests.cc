// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/windowing_handler.h"

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_method_codec.h"
#include "flutter/shell/platform/windows/flutter_host_window_controller.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/test_binary_messenger.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

constexpr char kChannelName[] = "flutter/windowing";
constexpr char kOnWindowDestroyedMethod[] = "onWindowDestroyed";
constexpr char kViewIdKey[] = "viewId";

// Process the next Win32 message if there is one. This can be used to
// pump the Windows platform thread task runner.
void PumpMessage() {
  ::MSG msg;
  if (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
}

class FlutterHostWindowControllerTest : public WindowsTest {
 public:
  FlutterHostWindowControllerTest() = default;
  virtual ~FlutterHostWindowControllerTest() = default;

 protected:
  void SetUp() override {
    InitializeCOM();
    FlutterWindowsEngineBuilder builder(GetContext());
    engine_ = builder.Build();
    controller_ = std::make_unique<FlutterHostWindowController>(engine_.get());
  }

  FlutterWindowsEngine* engine() { return engine_.get(); }
  FlutterHostWindowController* host_window_controller() {
    return controller_.get();
  }

 private:
  void InitializeCOM() const {
    FML_CHECK(SUCCEEDED(::CoInitializeEx(nullptr, COINIT_MULTITHREADED)));
  }

  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::unique_ptr<FlutterHostWindowController> controller_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterHostWindowControllerTest);
};

}  // namespace

TEST_F(FlutterHostWindowControllerTest, CreateRegularWindow) {
  // Define parameters for the window to be created.
  WindowCreationSettings const settings = {
      .archetype = WindowArchetype::kRegular,
      .size = {800.0, 600.0},
      .title = "window",
  };

  // Create the window.
  std::optional<WindowMetadata> const result =
      host_window_controller()->CreateHostWindow(settings);

  // Validate the returned metadata.
  ASSERT_TRUE(result.has_value());
  EXPECT_NE(engine()->view(result->view_id), nullptr);
  EXPECT_GE(result->size.width(), settings.size.width());
  EXPECT_GE(result->size.height(), settings.size.height());
  EXPECT_FALSE(result->parent_id.has_value());

  // Verify the window exists and the view has the expected dimensions.
  FlutterHostWindow* const window =
      host_window_controller()->GetHostWindow(result->view_id);
  ASSERT_NE(window, nullptr);
  RECT client_rect;
  GetClientRect(window->GetWindowHandle(), &client_rect);
  EXPECT_EQ(client_rect.right - client_rect.left, settings.size.width());
  EXPECT_EQ(client_rect.bottom - client_rect.top, settings.size.height());
}

TEST_F(FlutterHostWindowControllerTest, CreatePopup) {
  // Create a top-level window first.
  WindowCreationSettings const parent_settings = {
      .archetype = WindowArchetype::kRegular,
      .size = {800.0, 600.0},
      .title = "parent",
  };
  std::optional<WindowMetadata> const parent_result =
      host_window_controller()->CreateHostWindow(parent_settings);
  ASSERT_NE(parent_result, std::nullopt);

  // Define parameters for the popup to be created.
  WindowCreationSettings const popup_settings = {
      .archetype = WindowArchetype::kPopup,
      .size = {200.0, 200.0},
      .parent_view_id = parent_result->view_id,
      .positioner = WindowPositioner{},
  };

  // Create popup parented to top-level window.
  std::optional<WindowMetadata> const popup_result =
      host_window_controller()->CreateHostWindow(popup_settings);

  // Validate the returned metadata.
  ASSERT_TRUE(popup_result.has_value());
  EXPECT_NE(engine()->view(popup_result->view_id), nullptr);
  EXPECT_GE(popup_result->size.width(), popup_settings.size.width());
  EXPECT_GE(popup_result->size.height(), popup_settings.size.height());
  ASSERT_TRUE(popup_result->parent_id.has_value());
  EXPECT_EQ(popup_result->parent_id.value(), parent_result->view_id);
  EXPECT_TRUE(popup_result->relative_position.has_value());

  // Verify the popup exists and the view has the expected dimensions.
  FlutterHostWindow* const window =
      host_window_controller()->GetHostWindow(popup_result->view_id);
  ASSERT_NE(window, nullptr);
  RECT client_rect;
  GetClientRect(window->GetWindowHandle(), &client_rect);
  EXPECT_EQ(client_rect.right - client_rect.left, popup_settings.size.width());
  EXPECT_EQ(client_rect.bottom - client_rect.top, popup_settings.size.height());
}

TEST_F(FlutterHostWindowControllerTest, DestroyWindow) {
  bool done = false;

  // Test messenger with a handler for onWindowDestroyed.
  TestBinaryMessenger messenger([&](const std::string& channel,
                                    const uint8_t* message, size_t size,
                                    BinaryReply reply) {
    // Ensure the message is sent on the windowing channel.
    ASSERT_EQ(channel, kChannelName);

    // Ensure the decoded method call is valid.
    auto const method = StandardMethodCodec::GetInstance().DecodeMethodCall(
        std::vector<uint8_t>(message, message + size));
    ASSERT_NE(method, nullptr);

    // Handle the onWindowDestroyed method.
    if (method->method_name() == kOnWindowDestroyedMethod) {
      // Validate the method arguments.
      auto const& args = *method->arguments();
      ASSERT_TRUE(std::holds_alternative<EncodableMap>(args));
      auto const& args_map = std::get<EncodableMap>(args);

      // Ensure the viewId is present but not valid anymore.
      auto const& it_viewId = args_map.find(EncodableValue(kViewIdKey));
      ASSERT_NE(it_viewId, args_map.end());
      auto const* value_viewId = std::get_if<FlutterViewId>(&it_viewId->second);
      ASSERT_NE(value_viewId, nullptr);
      EXPECT_GE(*value_viewId, 0);
      EXPECT_EQ(engine()->view(*value_viewId), nullptr);

      done = true;
    }
  });

  // Create the windowing handler with the test messenger.
  WindowingHandler windowing_handler(&messenger, host_window_controller());

  // Define parameters for the window to be created.
  WindowCreationSettings const settings = {
      .archetype = WindowArchetype::kRegular,
      .size = {800.0, 600.0},
      .title = "window",
  };

  // Create the window.
  std::optional<WindowMetadata> const result =
      host_window_controller()->CreateHostWindow(settings);
  ASSERT_TRUE(result.has_value());

  // Destroy the window and ensure onWindowDestroyed was invoked.
  EXPECT_TRUE(host_window_controller()->DestroyHostWindow(result->view_id));

  // Pump messages for the Windows platform task runner.
  while (!done) {
    PumpMessage();
  }
}

}  // namespace testing
}  // namespace flutter
