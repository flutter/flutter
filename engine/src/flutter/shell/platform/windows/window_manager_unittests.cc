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
    ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

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
  RegularWindowCreationRequest* regular_creation_request() {
    return &regular_creation_request_;
  }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  std::optional<flutter::Isolate> isolate_;
  RegularWindowCreationRequest regular_creation_request_{
      .preferred_size =
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
          engine_id(), regular_creation_request());
  DestroyWindow(InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
      engine_id(), view_id));

  EXPECT_TRUE(received_message);
}

TEST_F(WindowManagerTest, CreateRegularWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  EXPECT_EQ(view_id, 0);
}

TEST_F(WindowManagerTest, GetWindowHandle) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);
  EXPECT_NE(window_handle, nullptr);
}

TEST_F(WindowManagerTest, GetWindowSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  ActualWindowSize size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);

  EXPECT_EQ(size.width,
            regular_creation_request()->preferred_size.preferred_view_width);
  EXPECT_EQ(size.height,
            regular_creation_request()->preferred_size.preferred_view_height);
}

TEST_F(WindowManagerTest, SetWindowSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  WindowSizeRequest requestedSize{

      .has_preferred_view_size = true,
      .preferred_view_width = 640,
      .preferred_view_height = 480,
  };
  InternalFlutterWindows_WindowManager_SetWindowSize(window_handle,
                                                     &requestedSize);

  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 640);
  EXPECT_EQ(actual_size.height, 480);
}

TEST_F(WindowManagerTest, CanConstrainByMinimiumSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);
  WindowConstraints constraints{.has_view_constraints = true,
                                .view_min_width = 900,
                                .view_min_height = 700,
                                .view_max_width = 10000,
                                .view_max_height = 10000};
  InternalFlutterWindows_WindowManager_SetWindowConstraints(window_handle,
                                                            &constraints);

  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 900);
  EXPECT_EQ(actual_size.height, 700);
}

TEST_F(WindowManagerTest, CanConstrainByMaximumSize) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);
  WindowConstraints constraints{.has_view_constraints = true,
                                .view_min_width = 0,
                                .view_min_height = 0,
                                .view_max_width = 500,
                                .view_max_height = 500};
  InternalFlutterWindows_WindowManager_SetWindowConstraints(window_handle,
                                                            &constraints);

  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 500);
  EXPECT_EQ(actual_size.height, 500);
}

TEST_F(WindowManagerTest, CanFullscreenWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FullscreenRequest request{.fullscreen = true, .has_display_id = false};
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  int screen_width = GetSystemMetrics(SM_CXSCREEN);
  int screen_height = GetSystemMetrics(SM_CYSCREEN);
  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, screen_width);
  EXPECT_EQ(actual_size.height, screen_height);
  EXPECT_TRUE(
      InternalFlutterWindows_WindowManager_GetFullscreen(window_handle));
}

TEST_F(WindowManagerTest, CanUnfullscreenWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FullscreenRequest request{.fullscreen = true, .has_display_id = false};
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  request.fullscreen = false;
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 800);
  EXPECT_EQ(actual_size.height, 600);
  EXPECT_FALSE(
      InternalFlutterWindows_WindowManager_GetFullscreen(window_handle));
}

TEST_F(WindowManagerTest, CanSetWindowSizeWhileFullscreen) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FullscreenRequest request{.fullscreen = true, .has_display_id = false};
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  WindowSizeRequest requestedSize{

      .has_preferred_view_size = true,
      .preferred_view_width = 500,
      .preferred_view_height = 500,
  };
  InternalFlutterWindows_WindowManager_SetWindowSize(window_handle,
                                                     &requestedSize);

  request.fullscreen = false;
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 500);
  EXPECT_EQ(actual_size.height, 500);
}

TEST_F(WindowManagerTest, CanSetWindowConstraintsWhileFullscreen) {
  IsolateScope isolate_scope(isolate());

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FullscreenRequest request{.fullscreen = true, .has_display_id = false};
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  WindowConstraints constraints{.has_view_constraints = true,
                                .view_min_width = 0,
                                .view_min_height = 0,
                                .view_max_width = 500,
                                .view_max_height = 500};
  InternalFlutterWindows_WindowManager_SetWindowConstraints(window_handle,
                                                            &constraints);

  request.fullscreen = false;
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);

  ActualWindowSize actual_size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(actual_size.width, 500);
  EXPECT_EQ(actual_size.height, 500);
}

TEST_F(WindowManagerTest, CreateModelessDialogWindow) {
  IsolateScope isolate_scope(isolate());
  DialogWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = true,
                         .preferred_view_width = 800,
                         .preferred_view_height = 600},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Hello World",
      .parent_or_null = nullptr};
  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  EXPECT_EQ(view_id, 0);
}

TEST_F(WindowManagerTest, CreateModalDialogWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  DialogWindowCreationRequest creation_request{
      .preferred_size =
          {
              .has_preferred_view_size = true,
              .preferred_view_width = 800,
              .preferred_view_height = 600,
          },
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Hello World",
      .parent_or_null = parent_window_handle};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  EXPECT_EQ(view_id, 1);

  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);
  HostWindow* host_window = HostWindow::GetThisFromHandle(window_handle);
  EXPECT_EQ(host_window->GetOwnerWindow()->GetWindowHandle(),
            parent_window_handle);
}

TEST_F(WindowManagerTest, DialogCanNeverBeFullscreen) {
  IsolateScope isolate_scope(isolate());

  DialogWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = true,
                         .preferred_view_width = 800,
                         .preferred_view_height = 600},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Hello World",
      .parent_or_null = nullptr};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FullscreenRequest request{.fullscreen = true, .has_display_id = false};
  InternalFlutterWindows_WindowManager_SetFullscreen(window_handle, &request);
  EXPECT_FALSE(
      InternalFlutterWindows_WindowManager_GetFullscreen(window_handle));
}

}  // namespace testing
}  // namespace flutter
