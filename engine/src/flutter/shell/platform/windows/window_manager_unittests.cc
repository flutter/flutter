// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/egl/mock_context.h"
#include "flutter/shell/platform/windows/testing/egl/mock_manager.h"
#include "flutter/shell/platform/windows/testing/egl/mock_window_surface.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "flutter/shell/platform/windows/window_manager.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

using ::testing::NiceMock;
using ::testing::Return;

// Builds a mock |WindowSurface| whose lifecycle operations all succeed. Used to
// keep the EGL surface lifecycle deterministic in tests so that resize paths
// (e.g. |FlutterWindowsView::OnFrameGenerated|) do not perform real, flaky
// cross-thread ANGLE/D3D calls against an actual GPU surface.
std::unique_ptr<egl::MockWindowSurface> CreateMockWindowSurface() {
  auto surface = std::make_unique<NiceMock<egl::MockWindowSurface>>();
  ON_CALL(*surface, IsValid).WillByDefault(Return(true));
  ON_CALL(*surface, MakeCurrent).WillByDefault(Return(true));
  ON_CALL(*surface, SetVSyncEnabled).WillByDefault(Return(true));
  ON_CALL(*surface, Destroy).WillByDefault(Return(true));
  return surface;
}

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

    // Replace the engine's EGL manager with a permissive mock so that EGL
    // surface creation and resizing are deterministic and never issue real,
    // cross-thread GPU calls. These tests do not exercise real EGL rendering,
    // and without this, tests that drive |FlutterWindowsView::OnFrameGenerated|
    // from the test thread race the engine's raster thread for the EGL context,
    // intermittently producing an EGL_BAD_ACCESS and a crash. Installed here,
    // before any windows (and thus render surfaces) are created.
    auto egl_manager = std::make_unique<NiceMock<egl::MockManager>>();
    ON_CALL(*egl_manager, CreateWindowSurface)
        .WillByDefault(
            [](HWND, size_t, size_t) { return CreateMockWindowSurface(); });
    ON_CALL(*egl_manager, render_context)
        .WillByDefault(Return(&mock_egl_context_));
    ON_CALL(mock_egl_context_, ClearCurrent).WillByDefault(Return(true));
    ON_CALL(mock_egl_context_, MakeCurrent).WillByDefault(Return(true));
    EngineModifier{engine_.get()}.SetEGLManager(std::move(egl_manager));
  }

  void TearDown() override { engine_->Stop(); }

  int64_t engine_id() { return reinterpret_cast<int64_t>(engine_.get()); }
  flutter::Isolate& isolate() { return *isolate_; }
  RegularWindowCreationRequest* regular_creation_request() {
    return &regular_creation_request_;
  }
  FlutterWindowsEngine* engine() { return engine_.get(); }

 private:
  std::unique_ptr<FlutterWindowsEngine> engine_;
  NiceMock<egl::MockContext> mock_egl_context_;
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

TEST_F(WindowManagerTest, CreateTooltipWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  TooltipWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t tooltip_view_id =
      InternalFlutterWindows_WindowManager_CreateTooltipWindow(
          engine_id(), &creation_request);

  EXPECT_NE(tooltip_view_id, -1);
  HWND tooltip_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), tooltip_view_id);
  EXPECT_NE(tooltip_window_handle, nullptr);
}

TEST_F(WindowManagerTest, TooltipWindowHasNoActivateStyle) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  TooltipWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t tooltip_view_id =
      InternalFlutterWindows_WindowManager_CreateTooltipWindow(
          engine_id(), &creation_request);

  HWND tooltip_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), tooltip_view_id);

  DWORD ex_style = GetWindowLong(tooltip_window_handle, GWL_EXSTYLE);
  EXPECT_TRUE(ex_style & WS_EX_NOACTIVATE);
}

TEST_F(WindowManagerTest, TooltipWindowDoesNotStealFocus) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  // Give focus to the parent window
  SetFocus(parent_window_handle);
  HWND focused_before = GetFocus();

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  TooltipWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t tooltip_view_id =
      InternalFlutterWindows_WindowManager_CreateTooltipWindow(
          engine_id(), &creation_request);

  HWND tooltip_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), tooltip_view_id);

  // Verify focus remains with the parent window
  HWND focused_after = GetFocus();
  EXPECT_EQ(focused_before, focused_after);
  EXPECT_NE(focused_after, tooltip_window_handle);
}

TEST_F(WindowManagerTest, TooltipWindowReturnsNoActivateOnMouseClick) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  TooltipWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t tooltip_view_id =
      InternalFlutterWindows_WindowManager_CreateTooltipWindow(
          engine_id(), &creation_request);

  HWND tooltip_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), tooltip_view_id);

  // Send WM_MOUSEACTIVATE message to the tooltip window
  LRESULT result = SendMessage(tooltip_window_handle, WM_MOUSEACTIVATE,
                               reinterpret_cast<WPARAM>(parent_window_handle),
                               MAKELPARAM(HTCLIENT, WM_LBUTTONDOWN));

  // Verify the tooltip returns MA_NOACTIVATE
  EXPECT_EQ(result, MA_NOACTIVATE);
}

TEST_F(WindowManagerTest, TooltipWindowUpdatesPositionOnViewSizeChange) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  // Track the child size passed to the callback
  static int callback_count = 0;
  static int last_width = 0;
  static int last_height = 0;

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    callback_count++;
    last_width = child_size.width;
    last_height = child_size.height;

    // Use malloc since the caller will use free()
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + callback_count * 5;
    rect->top = parent_rect.top + callback_count * 5;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  TooltipWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  // Reset callback tracking
  callback_count = 0;
  last_width = 0;
  last_height = 0;

  const int64_t tooltip_view_id =
      InternalFlutterWindows_WindowManager_CreateTooltipWindow(
          engine_id(), &creation_request);

  HWND tooltip_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), tooltip_view_id);

  // Get the view associated with the tooltip window
  FlutterWindowsView* view =
      engine()->GetViewFromTopLevelWindow(tooltip_window_handle);
  ASSERT_NE(view, nullptr);

  // Get initial position
  RECT initial_rect;
  GetWindowRect(tooltip_window_handle, &initial_rect);
  int initial_callback_count = callback_count;

  // Simulate a frame being generated with new dimensions
  // This should trigger DidUpdateViewSize which calls UpdatePosition
  view->OnFrameGenerated(150, 100);

  // Process any pending tasks to ensure the callback is executed
  engine()->task_runner()->ProcessTasks();

  // Verify the callback was called again with the new dimensions
  EXPECT_GT(callback_count, initial_callback_count);
  EXPECT_EQ(last_width, 150);
  EXPECT_EQ(last_height, 100);

  // Get new position and verify it changed
  RECT new_rect;
  GetWindowRect(tooltip_window_handle, &new_rect);

  // The position should have changed due to our callback logic
  // (we offset by callback_count * 5)
  EXPECT_NE(initial_rect.left, new_rect.left);
  EXPECT_NE(initial_rect.top, new_rect.top);
}

TEST_F(WindowManagerTest, CreatePopupWindow) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  PopupWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t popup_view_id =
      InternalFlutterWindows_WindowManager_CreatePopupWindow(engine_id(),
                                                             &creation_request);

  EXPECT_NE(popup_view_id, -1);
  HWND popup_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), popup_view_id);
  EXPECT_NE(popup_window_handle, nullptr);
}

TEST_F(WindowManagerTest, PopupWindowHasNoActivateStyle) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  PopupWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t popup_view_id =
      InternalFlutterWindows_WindowManager_CreatePopupWindow(engine_id(),
                                                             &creation_request);

  HWND popup_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), popup_view_id);

  DWORD ex_style = GetWindowLong(popup_window_handle, GWL_EXSTYLE);
  EXPECT_TRUE(ex_style & WS_EX_NOACTIVATE);
}

TEST_F(WindowManagerTest, PopupWindowDoesNotStealFocus) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  // Give focus to the parent window
  SetFocus(parent_window_handle);
  HWND focused_before = GetFocus();

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + 10;
    rect->top = parent_rect.top + 10;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  PopupWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  const int64_t popup_view_id =
      InternalFlutterWindows_WindowManager_CreatePopupWindow(engine_id(),
                                                             &creation_request);

  HWND popup_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), popup_view_id);

  // Verify focus remains with the parent window
  HWND focused_after = GetFocus();
  EXPECT_EQ(focused_before, focused_after);
  EXPECT_NE(focused_after, popup_window_handle);
}

TEST_F(WindowManagerTest, PopupWindowUpdatesPositionOnViewSizeChange) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  // Track the child size passed to the callback
  static int callback_count = 0;
  static int last_width = 0;
  static int last_height = 0;

  auto position_callback = [](const WindowSize& child_size,
                              const WindowRect& parent_rect,
                              const WindowRect& output_rect) -> WindowRect* {
    callback_count++;
    last_width = child_size.width;
    last_height = child_size.height;

    // Use malloc since the caller will use free()
    WindowRect* rect = static_cast<WindowRect*>(malloc(sizeof(WindowRect)));
    rect->left = parent_rect.left + callback_count * 5;
    rect->top = parent_rect.top + callback_count * 5;
    rect->width = child_size.width;
    rect->height = child_size.height;
    return rect;
  };

  PopupWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  // Reset callback tracking
  callback_count = 0;
  last_width = 0;
  last_height = 0;

  const int64_t popup_view_id =
      InternalFlutterWindows_WindowManager_CreatePopupWindow(engine_id(),
                                                             &creation_request);

  HWND popup_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), popup_view_id);

  // Get the view associated with the popup window
  FlutterWindowsView* view =
      engine()->GetViewFromTopLevelWindow(popup_window_handle);
  ASSERT_NE(view, nullptr);

  // Get initial position
  RECT initial_rect;
  GetWindowRect(popup_window_handle, &initial_rect);
  int initial_callback_count = callback_count;

  // Simulate a frame being generated with new dimensions
  // This should trigger DidUpdateViewSize which calls UpdatePosition
  view->OnFrameGenerated(150, 100);

  // Process any pending tasks to ensure the callback is executed
  engine()->task_runner()->ProcessTasks();

  // Verify the callback was called again with the new dimensions
  EXPECT_GT(callback_count, initial_callback_count);
  EXPECT_EQ(last_width, 150);
  EXPECT_EQ(last_height, 100);

  // Get new position and verify it changed
  RECT new_rect;
  GetWindowRect(popup_window_handle, &new_rect);

  // The position should have changed due to our callback logic
  // (we offset by callback_count * 5)
  EXPECT_NE(initial_rect.left, new_rect.left);
  EXPECT_NE(initial_rect.top, new_rect.top);
}

TEST_F(WindowManagerTest, CreateRegularWindowSizedToContent) {
  IsolateScope isolate_scope(isolate());

  RegularWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Sized To Content",
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), &creation_request);
  EXPECT_GE(view_id, 0);
}

TEST_F(WindowManagerTest, RegularWindowSizedToContentResizesToContent) {
  IsolateScope isolate_scope(isolate());

  RegularWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Sized To Content",
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FlutterWindowsView* view = engine()->GetViewFromTopLevelWindow(window_handle);
  ASSERT_NE(view, nullptr);

  view->OnFrameGenerated(300, 200);
  engine()->task_runner()->ProcessTasks();

  ActualWindowSize size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(size.width, 300);
  EXPECT_EQ(size.height, 200);
}

TEST_F(WindowManagerTest,
       RegularWindowSizedToContentNonResizableHasNoThickFrame) {
  IsolateScope isolate_scope(isolate());

  RegularWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Sized To Content Non-Resizable",
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  const LONG style = GetWindowLong(window_handle, GWL_STYLE);
  EXPECT_EQ(style & WS_THICKFRAME, 0L);
  EXPECT_EQ(style & WS_MAXIMIZEBOX, 0L);
}

TEST_F(WindowManagerTest, RegularWindowSizedToContentResizableHasThickFrame) {
  IsolateScope isolate_scope(isolate());

  RegularWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Sized To Content Resizable",
      .sized_to_content = true,
      .resizable = true};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  const LONG style = GetWindowLong(window_handle, GWL_STYLE);
  EXPECT_NE(style & WS_THICKFRAME, 0L);
  EXPECT_NE(style & WS_MAXIMIZEBOX, 0L);
}

TEST_F(WindowManagerTest,
       RegularWindowSizedToContentResizableStopsTrackingAfterFirstFrame) {
  IsolateScope isolate_scope(isolate());

  RegularWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Sized To Content Resizable",
      .sized_to_content = true,
      .resizable = true};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FlutterWindowsView* view = engine()->GetViewFromTopLevelWindow(window_handle);
  ASSERT_NE(view, nullptr);

  view->OnFrameGenerated(300, 200);
  engine()->task_runner()->ProcessTasks();

  EXPECT_FALSE(view->IsSizedToContent());
}

TEST_F(WindowManagerTest, CreateModelessDialogSizedToContent) {
  IsolateScope isolate_scope(isolate());

  DialogWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Modeless Dialog Sized To Content",
      .parent_or_null = nullptr,
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  EXPECT_GE(view_id, 0);
}

TEST_F(WindowManagerTest, CreateModalDialogSizedToContent) {
  IsolateScope isolate_scope(isolate());

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  DialogWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Modal Dialog Sized To Content",
      .parent_or_null = parent_window_handle,
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  EXPECT_GE(view_id, 0);
}

TEST_F(WindowManagerTest, DialogWindowSizedToContentResizesToContent) {
  IsolateScope isolate_scope(isolate());

  DialogWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Dialog Sized To Content",
      .parent_or_null = nullptr,
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  FlutterWindowsView* view = engine()->GetViewFromTopLevelWindow(window_handle);
  ASSERT_NE(view, nullptr);

  view->OnFrameGenerated(300, 200);
  engine()->task_runner()->ProcessTasks();

  ActualWindowSize size =
      InternalFlutterWindows_WindowManager_GetWindowContentSize(window_handle);
  EXPECT_EQ(size.width, 300);
  EXPECT_EQ(size.height, 200);
}

TEST_F(WindowManagerTest,
       DialogWindowSizedToContentNonResizableHasNoThickFrame) {
  IsolateScope isolate_scope(isolate());

  DialogWindowCreationRequest creation_request{
      .preferred_size = {.has_preferred_view_size = false},
      .preferred_constraints = {.has_view_constraints = false},
      .title = L"Dialog Sized To Content Non-Resizable",
      .parent_or_null = nullptr,
      .sized_to_content = true,
      .resizable = false};

  const int64_t view_id =
      InternalFlutterWindows_WindowManager_CreateDialogWindow(
          engine_id(), &creation_request);
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);

  const LONG style = GetWindowLong(window_handle, GWL_STYLE);
  EXPECT_EQ(style & WS_THICKFRAME, 0L);
}

TEST_F(WindowManagerTest, UpdateTooltipPositionWithNullHandleDoesNotCrash) {
  IsolateScope isolate_scope(isolate());

  InternalFlutterWindows_WindowManager_UpdateTooltipPosition(nullptr);
}

TEST_F(WindowManagerTest, UpdatePopupPositionWithNullHandleDoesNotCrash) {
  IsolateScope isolate_scope(isolate());

  InternalFlutterWindows_WindowManager_UpdatePopupPosition(nullptr);
}

TEST_F(WindowManagerTest,
       UpdateTooltipPositionWithNonFlutterHandleDoesNotCrash) {
  IsolateScope isolate_scope(isolate());

  // A handle that is valid but not a Flutter HostWindow (e.g., the desktop
  // window) causes GetThisFromHandle to return nullptr because the class name
  // does not match. The call must not dereference the null result.
  InternalFlutterWindows_WindowManager_UpdateTooltipPosition(
      GetDesktopWindow());
}

TEST_F(WindowManagerTest, UpdatePopupPositionWithNonFlutterHandleDoesNotCrash) {
  IsolateScope isolate_scope(isolate());

  // A handle that is valid but not a Flutter HostWindow (e.g., the desktop
  // window) causes GetThisFromHandle to return nullptr because the class name
  // does not match. The call must not dereference the null result.
  InternalFlutterWindows_WindowManager_UpdatePopupPosition(GetDesktopWindow());
}

}  // namespace testing
}  // namespace flutter
