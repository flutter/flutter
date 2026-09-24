// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <vector>

#include <dwmapi.h>

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
    context.AddFfiNativeFunction("Signal", CREATE_FFI_LAMBDA([&]() {
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

  // Creates a regular window to act as the parent of a satellite, and returns
  // its window handle.
  HWND CreateParentWindow() {
    return InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
        engine_id(), InternalFlutterWindows_WindowManager_CreateRegularWindow(
                         engine_id(), regular_creation_request()));
  }

  // Places a satellite at the origin of its parent's client area, offset by
  // (20, 30), at its requested size.
  static void OffsetPositionCallback(const WindowSize& child_size,
                                     const WindowRect& parent_rect,
                                     const WindowRect& display_rect,
                                     WindowRect& output_rect) {
    output_rect.left = parent_rect.left + 20;
    output_rect.top = parent_rect.top + 30;
    output_rect.width = child_size.width;
    output_rect.height = child_size.height;
  }

  // Returns a fixed-size, resizable satellite creation request anchored to
  // |parent|.
  static SatelliteWindowCreationRequest SatelliteCreationRequest(
      HWND parent,
      GetWindowPositionCallback get_position_callback) {
    return SatelliteWindowCreationRequest{
        .preferred_size = {.has_preferred_view_size = true,
                           .preferred_view_width = 200,
                           .preferred_view_height = 150},
        .preferred_constraints = {.has_view_constraints = true,
                                  .view_min_width = 100,
                                  .view_min_height = 50,
                                  .view_max_width = 300,
                                  .view_max_height = 200},
        .parent = parent,
        .get_position_callback = get_position_callback,
        .title = L"Satellite",
        .sized_to_content = false,
        .resizable = true};
  }

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
  EXPECT_EQ(view_id, 1);
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
  EXPECT_EQ(view_id, 1);
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
  EXPECT_EQ(view_id, 2);

  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(engine_id(),
                                                                   view_id);
  HostWindow* host_window = HostWindow::GetThisFromHandle(window_handle);
  EXPECT_EQ(host_window->GetOwnerWindow()->GetWindowHandle(),
            parent_window_handle);
}

TEST_F(WindowManagerTest, DeactivatedRegularWindowDoesNotReactivateItself) {
  IsolateScope isolate_scope(isolate());

  // Two independent top-level regular windows (regular windows have no Win32
  // owner). |window_handle| is deactivated while |active_window_handle| holds
  // activation.
  const int64_t window_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), window_view_id);

  const int64_t active_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND active_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), active_view_id);

  SetActiveWindow(active_window_handle);
  ASSERT_EQ(GetActiveWindow(), active_window_handle);

  // A window receiving WM_ACTIVATE with WA_INACTIVE must not focus its own
  // content: SetFocus activates the parent of the focused window (the window
  // itself), which would reactivate the deactivated window, pull it back to the
  // top of the z-order, and take activation away from the active window.
  SendMessage(window_handle, WM_ACTIVATE, MAKEWPARAM(WA_INACTIVE, 0), 0);

  EXPECT_EQ(GetActiveWindow(), active_window_handle);
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

// TODO(team-windows): Fix flakes. See:
// https://github.com/flutter/flutter/issues/177172
TEST_F(WindowManagerTest,
       DISABLED_TooltipWindowUpdatesPositionOnViewSizeChange) {
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        callback_count++;
        last_width = child_size.width;
        last_height = child_size.height;

        rect.left = parent_rect.left + callback_count * 5;
        rect.top = parent_rect.top + callback_count * 5;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
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

// TODO(team-windows): Fix flakes. See:
// https://github.com/flutter/flutter/issues/177172
TEST_F(WindowManagerTest, DISABLED_PopupWindowUpdatesPositionOnViewSizeChange) {
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

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        callback_count++;
        last_width = child_size.width;
        last_height = child_size.height;

        rect.left = parent_rect.left + callback_count * 5;
        rect.top = parent_rect.top + callback_count * 5;
        rect.width = child_size.width;
        rect.height = child_size.height;
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
  EXPECT_GE(view_id, 1);
}

// TODO(team-windows): Fix flakes. See:
// https://github.com/flutter/flutter/issues/177172
TEST_F(WindowManagerTest,
       DISABLED_RegularWindowSizedToContentResizesToContent) {
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

// TODO(team-windows): Fix flakes. See:
// https://github.com/flutter/flutter/issues/177172
TEST_F(
    WindowManagerTest,
    DISABLED_RegularWindowSizedToContentResizableStopsTrackingAfterFirstFrame) {
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

// TODO(team-windows): Fix flakes. See:
// https://github.com/flutter/flutter/issues/177172
TEST_F(WindowManagerTest, DISABLED_DialogWindowSizedToContentResizesToContent) {
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

TEST_F(WindowManagerTest,
       OnPreEngineRestartDestroysWindowsWithoutDispatchingMessages) {
  IsolateScope isolate_scope(isolate());

  static bool received_message = false;
  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) { received_message = true; }};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const int64_t first_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND first_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), first_view_id);
  const int64_t second_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND second_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), second_view_id);

  received_message = false;
  EngineModifier{engine()}.Restart();

  EXPECT_FALSE(received_message);
  EXPECT_FALSE(IsWindow(first_window_handle));
  EXPECT_FALSE(IsWindow(second_window_handle));
}

// Verifies that |OnEngineShutdown| destroys popup windows BEFORE clearing
// |on_message_|, so the WM_DESTROY round-trip reaches the isolate. Without
// this, |PopupWindowControllerWin32._destroyed| would never be set during
// engine shutdown and queued FFI calls (e.g. updatePosition) would
// dereference stale HostWindow pointers.
TEST_F(WindowManagerTest, OnEngineShutdownDispatchesWmDestroyForPopupWindow) {
  IsolateScope isolate_scope(isolate());

  static std::vector<UINT> received_messages;
  received_messages.clear();
  WindowingInitRequest init_request{.on_message = [](WindowsMessage* message) {
    received_messages.push_back(message->message);
  }};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
      };

  PopupWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  InternalFlutterWindows_WindowManager_CreatePopupWindow(engine_id(),
                                                         &creation_request);

  received_messages.clear();
  engine()->window_manager()->OnEngineShutdown();

  EXPECT_NE(std::find(received_messages.begin(), received_messages.end(),
                      static_cast<UINT>(WM_DESTROY)),
            received_messages.end());
}

// Same as above for tooltips.
TEST_F(WindowManagerTest, OnEngineShutdownDispatchesWmDestroyForTooltipWindow) {
  IsolateScope isolate_scope(isolate());

  static std::vector<UINT> received_messages;
  received_messages.clear();
  WindowingInitRequest init_request{.on_message = [](WindowsMessage* message) {
    received_messages.push_back(message->message);
  }};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const int64_t parent_view_id =
      InternalFlutterWindows_WindowManager_CreateRegularWindow(
          engine_id(), regular_creation_request());
  const HWND parent_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), parent_view_id);

  auto position_callback =
      [](const WindowSize& child_size, const WindowRect& parent_rect,
         const WindowRect& display_rect, WindowRect& rect) {
        rect.left = parent_rect.left + 10;
        rect.top = parent_rect.top + 10;
        rect.width = child_size.width;
        rect.height = child_size.height;
      };

  TooltipWindowCreationRequest creation_request{
      .preferred_constraints = {.has_view_constraints = true,
                                .view_min_width = 100,
                                .view_min_height = 50,
                                .view_max_width = 300,
                                .view_max_height = 200},
      .parent = parent_window_handle,
      .get_position_callback = position_callback};

  InternalFlutterWindows_WindowManager_CreateTooltipWindow(engine_id(),
                                                           &creation_request);

  received_messages.clear();
  engine()->window_manager()->OnEngineShutdown();

  EXPECT_NE(std::find(received_messages.begin(), received_messages.end(),
                      static_cast<UINT>(WM_DESTROY)),
            received_messages.end());
}

TEST_F(WindowManagerTest, CreateSatelliteWindow) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);

  const int64_t satellite_view_id =
      InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
          engine_id(), &creation_request);

  EXPECT_GE(satellite_view_id, 0);
  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), satellite_view_id);
  EXPECT_NE(satellite_window_handle, nullptr);
}

TEST_F(WindowManagerTest, SatelliteWindowUsesPositionCallbackAfterFirstFrame) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SetWindowPos(parent_window_handle, nullptr, 200, 100, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);

  const int64_t satellite_view_id =
      InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
          engine_id(), &creation_request);
  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), satellite_view_id);

  FlutterWindowsView* view =
      engine()->GetViewFromTopLevelWindow(satellite_window_handle);
  ASSERT_NE(view, nullptr);

  // The positioner runs once the satellite has rendered its first frame, while
  // the window is still hidden.
  view->OnFramePresented();
  engine()->task_runner()->ProcessTasks();

  // |OffsetPositionCallback| places the satellite at the parent's client-area
  // origin, offset by (20, 30).
  RECT parent_client_rect;
  GetClientRect(parent_window_handle, &parent_client_rect);
  POINT parent_top_left = {parent_client_rect.left, parent_client_rect.top};
  ClientToScreen(parent_window_handle, &parent_top_left);

  // Compare against the window frame rather than the window rectangle: the
  // placement aligns the frame, not the window rectangle (which includes the
  // invisible drop-shadow border), with the requested origin.
  RECT satellite_frame;
  ASSERT_EQ(DwmGetWindowAttribute(satellite_window_handle,
                                  DWMWA_EXTENDED_FRAME_BOUNDS, &satellite_frame,
                                  sizeof(satellite_frame)),
            S_OK);

  EXPECT_EQ(satellite_frame.left, parent_top_left.x + 20);
  EXPECT_EQ(satellite_frame.top, parent_top_left.y + 30);
}

TEST_F(WindowManagerTest, SatelliteWindowIsHiddenUntilFirstFrame) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);

  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));
  ASSERT_NE(satellite_window_handle, nullptr);

  // The satellite is placed by the positioner before it is shown, so that the
  // move is never visible to the user.
  EXPECT_FALSE(IsWindowVisible(satellite_window_handle));

  FlutterWindowsView* view =
      engine()->GetViewFromTopLevelWindow(satellite_window_handle);
  ASSERT_NE(view, nullptr);
  view->OnFramePresented();
  engine()->task_runner()->ProcessTasks();

  EXPECT_TRUE(IsWindowVisible(satellite_window_handle));
}

TEST_F(WindowManagerTest, SatelliteWindowHandlesNullPositionCallback) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, nullptr);

  const int64_t satellite_view_id =
      InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
          engine_id(), &creation_request);

  EXPECT_GE(satellite_view_id, 0);
  EXPECT_NE(InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
                engine_id(), satellite_view_id),
            nullptr);
}

TEST_F(WindowManagerTest, SatelliteWindowFollowsParentMovement) {
  IsolateScope isolate_scope(isolate());

  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) {}};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const HWND parent_window_handle = CreateParentWindow();
  SetWindowPos(parent_window_handle, nullptr, 200, 100, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));

  RECT satellite_rect_before;
  GetWindowRect(satellite_window_handle, &satellite_rect_before);

  // Move the parent by (+50, +100). SetWindowPos dispatches
  // WM_WINDOWPOSCHANGED synchronously, so the satellite moves before it
  // returns.
  SetWindowPos(parent_window_handle, nullptr, 250, 200, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  RECT satellite_rect_after;
  GetWindowRect(satellite_window_handle, &satellite_rect_after);

  EXPECT_EQ(satellite_rect_after.left, satellite_rect_before.left + 50);
  EXPECT_EQ(satellite_rect_after.top, satellite_rect_before.top + 100);
}

TEST_F(WindowManagerTest, SatelliteWindowDoesNotMoveWhenParentOnlyResizes) {
  IsolateScope isolate_scope(isolate());

  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) {}};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const HWND parent_window_handle = CreateParentWindow();
  SetWindowPos(parent_window_handle, nullptr, 200, 100, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));

  RECT satellite_rect_before;
  GetWindowRect(satellite_window_handle, &satellite_rect_before);

  SetWindowPos(parent_window_handle, nullptr, 0, 0, 640, 480,
               SWP_NOMOVE | SWP_NOZORDER);

  RECT satellite_rect_after;
  GetWindowRect(satellite_window_handle, &satellite_rect_after);

  EXPECT_EQ(satellite_rect_after.left, satellite_rect_before.left);
  EXPECT_EQ(satellite_rect_after.top, satellite_rect_before.top);
}

TEST_F(WindowManagerTest, SatelliteWindowCannotBeMinimized) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);

  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));

  SendMessage(satellite_window_handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);

  EXPECT_FALSE(IsIconic(satellite_window_handle));
}

TEST_F(WindowManagerTest, SatelliteWindowCanReparent) {
  IsolateScope isolate_scope(isolate());

  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) {}};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const HWND parent1_handle = CreateParentWindow();
  SetWindowPos(parent1_handle, nullptr, 100, 100, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);
  const HWND parent2_handle = CreateParentWindow();
  SetWindowPos(parent2_handle, nullptr, 500, 500, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent1_handle, OffsetPositionCallback);
  const HWND satellite_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));

  RECT satellite_rect_before;
  GetWindowRect(satellite_handle, &satellite_rect_before);

  // Reparenting must not move the satellite.
  InternalFlutterWindows_WindowManager_SetSatelliteParent(satellite_handle,
                                                          parent2_handle);

  RECT satellite_rect_after;
  GetWindowRect(satellite_handle, &satellite_rect_after);
  EXPECT_EQ(satellite_rect_after.left, satellite_rect_before.left);
  EXPECT_EQ(satellite_rect_after.top, satellite_rect_before.top);

  // The satellite now follows the new parent...
  RECT parent2_rect;
  GetWindowRect(parent2_handle, &parent2_rect);
  SetWindowPos(parent2_handle, nullptr, parent2_rect.left + 30,
               parent2_rect.top + 40, 0, 0, SWP_NOSIZE | SWP_NOZORDER);

  RECT satellite_rect_moved;
  GetWindowRect(satellite_handle, &satellite_rect_moved);
  EXPECT_EQ(satellite_rect_moved.left, satellite_rect_after.left + 30);
  EXPECT_EQ(satellite_rect_moved.top, satellite_rect_after.top + 40);

  // ...and no longer follows the old one.
  RECT parent1_rect;
  GetWindowRect(parent1_handle, &parent1_rect);
  SetWindowPos(parent1_handle, nullptr, parent1_rect.left + 70,
               parent1_rect.top + 80, 0, 0, SWP_NOSIZE | SWP_NOZORDER);

  RECT satellite_rect_final;
  GetWindowRect(satellite_handle, &satellite_rect_final);
  EXPECT_EQ(satellite_rect_final.left, satellite_rect_moved.left);
  EXPECT_EQ(satellite_rect_final.top, satellite_rect_moved.top);
}

TEST_F(WindowManagerTest, CreateSatelliteWindowSizedToContent) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SetWindowPos(parent_window_handle, nullptr, 200, 100, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  creation_request.preferred_size = {.has_preferred_view_size = false};
  creation_request.sized_to_content = true;

  const int64_t satellite_view_id =
      InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
          engine_id(), &creation_request);
  ASSERT_GE(satellite_view_id, 0);
  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(), satellite_view_id);
  ASSERT_NE(satellite_window_handle, nullptr);

  FlutterWindowsView* view =
      engine()->GetViewFromTopLevelWindow(satellite_window_handle);
  ASSERT_NE(view, nullptr);
  EXPECT_TRUE(view->IsSizedToContent());
}

TEST_F(WindowManagerTest,
       SatelliteWindowSizedToContentUsesPositionCallbackAfterFirstFrame) {
  IsolateScope isolate_scope(isolate());

  const HWND parent_window_handle = CreateParentWindow();
  SetWindowPos(parent_window_handle, nullptr, 200, 100, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER);

  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  creation_request.preferred_size = {.has_preferred_view_size = false};
  creation_request.sized_to_content = true;

  const HWND satellite_window_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));
  ASSERT_NE(satellite_window_handle, nullptr);

  FlutterWindowsView* view =
      engine()->GetViewFromTopLevelWindow(satellite_window_handle);
  ASSERT_NE(view, nullptr);

  // A sized-to-content satellite does not know its size until the first frame,
  // so the positioner only runs once that frame has been generated.
  view->OnFrameGenerated(150, 100);
  engine()->task_runner()->ProcessTasks();

  RECT parent_client_rect;
  GetClientRect(parent_window_handle, &parent_client_rect);
  POINT parent_top_left = {parent_client_rect.left, parent_client_rect.top};
  ClientToScreen(parent_window_handle, &parent_top_left);

  // As on the creation path, the positioner's origin applies to the window
  // frame rather than the window rectangle.
  RECT satellite_frame;
  ASSERT_EQ(DwmGetWindowAttribute(satellite_window_handle,
                                  DWMWA_EXTENDED_FRAME_BOUNDS, &satellite_frame,
                                  sizeof(satellite_frame)),
            S_OK);
  EXPECT_EQ(satellite_frame.left, parent_top_left.x + 20);
  EXPECT_EQ(satellite_frame.top, parent_top_left.y + 30);
}

TEST_F(WindowManagerTest, SatelliteWindowCannotBeReparentedToItself) {
  IsolateScope isolate_scope(isolate());

  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) {}};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  const HWND satellite_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &creation_request));

  // Anchoring a satellite to itself would make parent-movement propagation
  // recurse forever, so the request must be rejected.
  InternalFlutterWindows_WindowManager_SetSatelliteParent(satellite_handle,
                                                          satellite_handle);

  RECT parent_rect;
  GetWindowRect(parent_window_handle, &parent_rect);
  RECT satellite_rect_before;
  GetWindowRect(satellite_handle, &satellite_rect_before);

  // The satellite still tracks its original parent.
  SetWindowPos(parent_window_handle, nullptr, parent_rect.left + 15,
               parent_rect.top + 25, 0, 0, SWP_NOSIZE | SWP_NOZORDER);

  RECT satellite_rect_after;
  GetWindowRect(satellite_handle, &satellite_rect_after);
  EXPECT_EQ(satellite_rect_after.left, satellite_rect_before.left + 15);
  EXPECT_EQ(satellite_rect_after.top, satellite_rect_before.top + 25);
}

TEST_F(WindowManagerTest, SatelliteWindowCannotBeReparentedToItsOwnSatellite) {
  IsolateScope isolate_scope(isolate());

  WindowingInitRequest init_request{
      .on_message = [](WindowsMessage* message) {}};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest outer_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  const HWND outer_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &outer_request));

  SatelliteWindowCreationRequest inner_request =
      SatelliteCreationRequest(outer_handle, OffsetPositionCallback);
  const HWND inner_handle =
      InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle(
          engine_id(),
          InternalFlutterWindows_WindowManager_CreateSatelliteWindow(
              engine_id(), &inner_request));

  // |outer| already anchors |inner|, so anchoring |outer| to |inner| would
  // close a cycle and must be rejected.
  InternalFlutterWindows_WindowManager_SetSatelliteParent(outer_handle,
                                                          inner_handle);

  RECT parent_rect;
  GetWindowRect(parent_window_handle, &parent_rect);
  RECT outer_rect_before;
  GetWindowRect(outer_handle, &outer_rect_before);
  RECT inner_rect_before;
  GetWindowRect(inner_handle, &inner_rect_before);

  // Moving the root window still propagates down the chain exactly once.
  SetWindowPos(parent_window_handle, nullptr, parent_rect.left + 10,
               parent_rect.top + 20, 0, 0, SWP_NOSIZE | SWP_NOZORDER);

  RECT outer_rect_after;
  GetWindowRect(outer_handle, &outer_rect_after);
  RECT inner_rect_after;
  GetWindowRect(inner_handle, &inner_rect_after);
  EXPECT_EQ(outer_rect_after.left, outer_rect_before.left + 10);
  EXPECT_EQ(outer_rect_after.top, outer_rect_before.top + 20);
  EXPECT_EQ(inner_rect_after.left, inner_rect_before.left + 10);
  EXPECT_EQ(inner_rect_after.top, inner_rect_before.top + 20);
}

TEST_F(WindowManagerTest, OnEngineShutdownDispatchesWmDestroyForSatellite) {
  IsolateScope isolate_scope(isolate());

  static std::vector<UINT> received_messages;
  received_messages.clear();
  WindowingInitRequest init_request{.on_message = [](WindowsMessage* message) {
    received_messages.push_back(message->message);
  }};
  InternalFlutterWindows_WindowManager_Initialize(engine_id(), &init_request);

  const HWND parent_window_handle = CreateParentWindow();
  SatelliteWindowCreationRequest creation_request =
      SatelliteCreationRequest(parent_window_handle, OffsetPositionCallback);
  InternalFlutterWindows_WindowManager_CreateSatelliteWindow(engine_id(),
                                                             &creation_request);

  received_messages.clear();
  engine()->window_manager()->OnEngineShutdown();

  EXPECT_NE(std::find(received_messages.begin(), received_messages.end(),
                      static_cast<UINT>(WM_DESTROY)),
            received_messages.end());
}

}  // namespace testing
}  // namespace flutter
