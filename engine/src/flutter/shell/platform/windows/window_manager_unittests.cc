// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "flutter/shell/platform/windows/window_manager.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

class WindowManagerTest : public WindowsTest {
 public:
  WindowManagerTest() = default;
  virtual ~WindowManagerTest() = default;

 protected:
  void SetUp() override {
    auto& context = GetContext();
    FlutterWindowsEngineBuilder builder(context);

    engine_ = builder.Build();
    ASSERT_TRUE(engine_);

    engine_->SetRootIsolateCreateCallback(context.GetRootIsolateCallback());
    ASSERT_TRUE(engine_->Run("testWindowController"));

    bool signalled = false;
    context.AddNativeFunction(
        "Signal", CREATE_NATIVE_ENTRY([&](Dart_NativeArguments args) {
          isolate_ = flutter::Isolate::Current();
          signalled = true;
        }));
    while (!signalled) {
      engine_->task_runner()->ProcessTasks();
    }
  }

  void TearDown() override { engine_->Stop(); }

  int64_t engine_id() { return reinterpret_cast<int64_t>(engine_.get()); }
  flutter::Isolate& isolate() { return *isolate_; }
  WindowCreationRequest* creation_request() { return &creation_request_; }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::optional<flutter::Isolate> isolate_;
  WindowCreationRequest creation_request_{
      .content_size =
          {
              .has_preferred_view_size = true,
              .preferred_view_width = 800,
              .preferred_view_height = 600,
          },
  };

  FML_DISALLOW_COPY_AND_ASSIGN(WindowManagerTest);
};

}  // namespace

TEST_F(WindowManagerTest, WindowingInitialize) {
  IsolateScope isolate_scope(isolate());

  static bool received_message = false;
  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) { received_message = true; }};

  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);
  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), creation_request());
  DestroyWindow(InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
      engine_id(), view_id));

  EXPECT_TRUE(received_message);
}

TEST_F(WindowManagerTest, HasTopLevelWindows) {
  IsolateScope isolate_scope(isolate());

  bool has_top_level_windows =
      InternalFlutterWindows_WindowManager_HasTopLevelWindows(engine_id());
  EXPECT_FALSE(has_top_level_windows);

  InternalFlutterWindows_WindowManager_CreateRegularWindow(engine_id(),
                                                           creation_request());
  has_top_level_windows =
      InternalFlutterWindows_WindowManager_HasTopLevelWindows(engine_id());
  EXPECT_TRUE(has_top_level_windows);
}

TEST_F(WindowManagerTest, CreateRegularWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), creation_request());
  EXPECT_EQ(view_id, 0);
}

TEST_F(WindowManagerTest, GetWindowHandle) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);
  EXPECT_NE(window_handle, nullptr);
}

TEST_F(WindowManagerTest, GetWindowSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FlutterWindowSize size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);

  EXPECT_EQ(size.width, creation_request()->content_size.preferred_view_width);
  EXPECT_EQ(size.height,
            creation_request()->content_size.preferred_view_height);
}

TEST_F(WindowManagerTest, SetWindowSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  WindowSizing requestedSize{
      .has_preferred_view_size = true,
      .preferred_view_width = 640,
      .preferred_view_height = 480,
  };
  InternalFlutterWindows_WindowManager_SetWindowContentSize(window_handle,
                                                            &requestedSize);

  FlutterWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 640);
  EXPECT_EQ(actual_size.height, 480);
}

}  // namespace testing
}  // namespace flutter
