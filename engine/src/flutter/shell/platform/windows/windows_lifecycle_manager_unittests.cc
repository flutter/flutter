// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_lifecycle_manager.h"

#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class WindowsLifecycleManagerTest : public WindowsTest {};

static void WaitUntilUpdated(const WindowsLifecycleManager& manager) {
  while (manager.IsUpdateStateScheduled()) {
    ::MSG msg;
    if (::GetMessage(&msg, nullptr, 0, 0)) {
      ::TranslateMessage(&msg);
      ::DispatchMessage(&msg);
    }
  }
}

TEST_F(WindowsLifecycleManagerTest, StateTransitions) {
  FlutterWindowsEngineBuilder builder{GetContext()};
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();

  WindowsLifecycleManager manager{engine.get()};
  HWND win1 = reinterpret_cast<HWND>(1);
  HWND win2 = reinterpret_cast<HWND>(2);

  // Hidden to inactive upon window shown.
  manager.SetLifecycleState(AppLifecycleState::kHidden);
  manager.OnWindowStateEvent(win1, WindowStateEvent::kShow);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kInactive);

  // Showing a second window does not change state.
  manager.OnWindowStateEvent(win2, WindowStateEvent::kShow);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kInactive);

  // Inactive to resumed upon window focus.
  manager.OnWindowStateEvent(win2, WindowStateEvent::kFocus);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kResumed);

  // Showing a second window does not change state.
  manager.OnWindowStateEvent(win1, WindowStateEvent::kFocus);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kResumed);

  // Unfocusing one window does not change state while another is focused.
  manager.OnWindowStateEvent(win1, WindowStateEvent::kUnfocus);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kResumed);

  // Unfocusing final remaining focused window transitions to inactive.
  manager.OnWindowStateEvent(win2, WindowStateEvent::kUnfocus);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kInactive);

  // Hiding one of two visible windows does not change state.
  manager.OnWindowStateEvent(win2, WindowStateEvent::kHide);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kInactive);

  // Hiding only visible window transitions to hidden.
  manager.OnWindowStateEvent(win1, WindowStateEvent::kHide);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kHidden);

  // Transition directly from resumed to hidden when the window is hidden.
  manager.OnWindowStateEvent(win1, WindowStateEvent::kShow);
  manager.OnWindowStateEvent(win1, WindowStateEvent::kFocus);
  manager.OnWindowStateEvent(win1, WindowStateEvent::kHide);
  WaitUntilUpdated(manager);
  EXPECT_EQ(manager.GetLifecycleState(), AppLifecycleState::kHidden);
}

}  // namespace testing
}  // namespace flutter
