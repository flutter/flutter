// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_host_window_controller.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

class FlutterHostWindowControllerTest : public WindowsTest {
 public:
  FlutterHostWindowControllerTest() = default;
  virtual ~FlutterHostWindowControllerTest() = default;

 protected:
  void SetUp() override {
    auto& context = GetContext();
    FlutterWindowsEngineBuilder builder(context);
    builder.SetSwitches({"--enable-windowing=true"});

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
              .has_size = true,
              .width = 800,
              .height = 600,
          },
  };

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterHostWindowControllerTest);
};

}  // namespace

TEST_F(FlutterHostWindowControllerTest, WindowingInitialize) {
  IsolateScope isolate_scope(isolate());

  static bool received_message = false;
  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) { received_message = true; }};

  FlutterWindowingInitialize(engine_id(), &init_request);
  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  DestroyWindow(FlutterGetWindowHandle(engine_id(), view_id));

  EXPECT_TRUE(received_message);
}

TEST_F(FlutterHostWindowControllerTest, HasTopLevelWindows) {
  IsolateScope isolate_scope(isolate());

  bool has_top_level_windows = FlutterWindowingHasTopLevelWindows(engine_id());
  EXPECT_FALSE(has_top_level_windows);

  FlutterCreateRegularWindow(engine_id(), creation_request());
  has_top_level_windows = FlutterWindowingHasTopLevelWindows(engine_id());
  EXPECT_TRUE(has_top_level_windows);
}

TEST_F(FlutterHostWindowControllerTest, CreateRegularWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  EXPECT_EQ(view_id, 0);
}

TEST_F(FlutterHostWindowControllerTest, GetWindowHandle) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  const HWND window_handle = FlutterGetWindowHandle(engine_id(), view_id);
  EXPECT_NE(window_handle, nullptr);
}

TEST_F(FlutterHostWindowControllerTest, GetWindowSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  const HWND window_handle = FlutterGetWindowHandle(engine_id(), view_id);

  FlutterWindowSize size = FlutterGetWindowContentSize(window_handle);

  EXPECT_EQ(size.width, creation_request()->content_size.width);
  EXPECT_EQ(size.height, creation_request()->content_size.height);
}

TEST_F(FlutterHostWindowControllerTest, GetWindowState) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  const HWND window_handle = FlutterGetWindowHandle(engine_id(), view_id);
  const int64_t window_state = FlutterGetWindowState(window_handle);
  EXPECT_EQ(window_state, static_cast<int64_t>(WindowState::kRestored));
}

TEST_F(FlutterHostWindowControllerTest, SetWindowState) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  const HWND window_handle = FlutterGetWindowHandle(engine_id(), view_id);

  const std::array kWindowStates = {
      static_cast<int64_t>(WindowState::kRestored),
      static_cast<int64_t>(WindowState::kMaximized),
      static_cast<int64_t>(WindowState::kMinimized),
  };

  for (const auto requested_state : kWindowStates) {
    FlutterSetWindowState(window_handle, requested_state);
    const int64_t actual_state = FlutterGetWindowState(window_handle);
    EXPECT_EQ(actual_state, requested_state);
  }
}

TEST_F(FlutterHostWindowControllerTest, SetWindowSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      FlutterCreateRegularWindow(engine_id(), creation_request());
  const HWND window_handle = FlutterGetWindowHandle(engine_id(), view_id);

  FlutterWindowSizing requestedSize{
      .has_size = true,
      .width = 640,
      .height = 480,
  };
  FlutterSetWindowContentSize(window_handle, &requestedSize);

  FlutterWindowSize actual_size = FlutterGetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 640);
  EXPECT_EQ(actual_size.height, 480);
}

}  // namespace testing
}  // namespace flutter
