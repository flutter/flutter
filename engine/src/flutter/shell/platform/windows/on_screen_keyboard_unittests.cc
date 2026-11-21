// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/on_screen_keyboard.h"

#include <chrono>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/task_runner.h"
#include "flutter/shell/platform/windows/testing/mock_on_screen_keyboard.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

HWND DummyHwnd() {
  return reinterpret_cast<HWND>(1);
}

HWND DummyRootHwnd() {
  return reinterpret_cast<HWND>(2);
}

class MockTaskRunner : public TaskRunner {
 public:
  MockTaskRunner()
      : TaskRunner([]() -> uint64_t { return 10000; },
                   [](const FlutterTask*) {}) {}

  void SimulateTimerAwake() { ProcessTasks(); }

  void AdvanceTime(std::chrono::milliseconds delay) { current_time_ += delay; }

 protected:
  void WakeUp() override {}

  TaskTimePoint GetCurrentTimeForTask() const override { return current_time_; }

 private:
  TaskTimePoint current_time_ = TaskTimePoint(
      std::chrono::duration_cast<std::chrono::steady_clock::duration>(
          std::chrono::nanoseconds(10000)));

  FML_DISALLOW_COPY_AND_ASSIGN(MockTaskRunner);
};

struct ApplyCall {
  HWND hwnd;
  bool show;
};

class FakeOnScreenKeyboardWin32Api : public OnScreenKeyboardWin32Api {
 public:
  HWND GetRootWindow(HWND hwnd) const override {
    return hwnd == DummyHwnd() ? DummyRootHwnd() : hwnd;
  }

  bool IsWindowValid(HWND hwnd) const override {
    return valid && hwnd != nullptr;
  }

  bool IsWindowMaximized(HWND /*hwnd*/) const override { return maximized; }

  bool IsWindowMinimized(HWND /*hwnd*/) const override { return false; }

  bool GetClientScreenRect(HWND /*hwnd*/, RECT* rect) const override {
    *rect = client_rect;
    return true;
  }

  bool GetWindowWorkArea(HWND /*hwnd*/, RECT* rect) const override {
    *rect = work_area;
    return true;
  }

  bool GetWindowScreenRect(HWND /*hwnd*/, RECT* rect) const override {
    *rect = window_rect;
    return true;
  }

  bool GetPlacement(HWND /*hwnd*/, WINDOWPLACEMENT* result) const override {
    ++get_placement_count;
    *result = placement;
    return true;
  }

  bool SetPlacement(HWND /*hwnd*/,
                    const WINDOWPLACEMENT& value) const override {
    restored_placements.push_back(value);
    return true;
  }

  bool SetPosition(HWND /*hwnd*/, const RECT& rect) const override {
    positioned_rects.push_back(rect);
    window_rect = rect;
    return true;
  }

  HWINEVENTHOOK SetMoveSizeEndHook(WINEVENTPROC /*callback*/) const override {
    return reinterpret_cast<HWINEVENTHOOK>(3);
  }

  void RemoveWinEventHook(HWINEVENTHOOK /*hook*/) const override {}

  bool valid = true;
  bool maximized = false;
  RECT client_rect{0, 0, 1000, 1000};
  RECT work_area{0, 0, 1000, 1000};
  mutable RECT window_rect{100, 500, 600, 900};
  WINDOWPLACEMENT placement{
      sizeof(WINDOWPLACEMENT), 0, SW_SHOWNORMAL, {10, 20}, {30, 40},
      {100, 500, 600, 900}};
  mutable int get_placement_count = 0;
  mutable std::vector<RECT> positioned_rects;
  mutable std::vector<WINDOWPLACEMENT> restored_placements;
};

class RecordingOnScreenKeyboard : public OnScreenKeyboardWin {
 public:
  RecordingOnScreenKeyboard(TaskRunner* task_runner,
                            std::vector<ApplyCall>* applies)
      : OnScreenKeyboardWin(task_runner,
                            std::make_unique<FakeOnScreenKeyboardWin32Api>()),
        applies_(applies) {}

 protected:
  void ApplyVisibility(HWND hwnd, bool show) override {
    applies_->push_back(ApplyCall{hwnd, show});
  }

 private:
  std::vector<ApplyCall>* applies_;

  FML_DISALLOW_COPY_AND_ASSIGN(RecordingOnScreenKeyboard);
};

}  // namespace

TEST(OnScreenKeyboardTest, NullHwndIsNoOp) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);

  keyboard.Display(nullptr);
  keyboard.Dismiss(nullptr);
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_TRUE(applies.empty());
}

TEST(OnScreenKeyboardTest, DisplayAppliesAfterDebounce) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);
  HWND hwnd = DummyHwnd();

  keyboard.Display(hwnd);
  runner.SimulateTimerAwake();
  EXPECT_TRUE(applies.empty());

  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(applies.size(), 1u);
  EXPECT_EQ(applies[0].hwnd, hwnd);
  EXPECT_TRUE(applies[0].show);
}

TEST(OnScreenKeyboardTest, DismissWhileAlreadyHiddenIsNoOp) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);

  keyboard.Dismiss(DummyHwnd());
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_TRUE(applies.empty());
}

TEST(OnScreenKeyboardTest, DisplayThenDismissCoalescesToHide) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);
  HWND hwnd = DummyHwnd();

  keyboard.Display(hwnd);
  keyboard.Dismiss(hwnd);
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(applies.size(), 1u);
  EXPECT_EQ(applies[0].hwnd, hwnd);
  EXPECT_FALSE(applies[0].show);
}

TEST(OnScreenKeyboardTest, DismissThenDisplayCoalescesToShow) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);
  HWND hwnd = DummyHwnd();

  keyboard.Dismiss(hwnd);
  keyboard.Display(hwnd);
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(applies.size(), 1u);
  EXPECT_EQ(applies[0].hwnd, hwnd);
  EXPECT_TRUE(applies[0].show);
}

TEST(OnScreenKeyboardTest, DestroyBeforeDebounceDoesNotApply) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  HWND hwnd = DummyHwnd();

  {
    auto keyboard =
        std::make_unique<RecordingOnScreenKeyboard>(&runner, &applies);
    keyboard->Display(hwnd);
  }

  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_TRUE(applies.empty());
}

TEST(OnScreenKeyboardTest, StubReportsHidden) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);

  EXPECT_FALSE(keyboard.shown());
  EXPECT_EQ(keyboard.physical_bottom_inset(), 0.0);

  bool called = false;
  keyboard.SetVisibilityChangedCallback([&called]() { called = true; });
  keyboard.Display(DummyHwnd());
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_FALSE(called);
}

TEST(OnScreenKeyboardTest, MockCanBeConstructed) {
  MockOnScreenKeyboard keyboard;
  EXPECT_CALL(keyboard, shown()).WillOnce(::testing::Return(false));
  EXPECT_FALSE(keyboard.shown());
}

TEST(OnScreenKeyboardTest, ComputeBottomInsetEmptyIntersection) {
  RECT client{0, 0, 800, 600};
  RECT occluded{900, 0, 1100, 200};
  EXPECT_EQ(OnScreenKeyboardWin::ComputeBottomInset(client, occluded), 0.0);
}

TEST(OnScreenKeyboardTest, ComputeBottomInsetKeyboardFromBottom) {
  RECT client{0, 0, 800, 600};
  RECT occluded{0, 400, 800, 600};
  EXPECT_EQ(OnScreenKeyboardWin::ComputeBottomInset(client, occluded), 200.0);
}

TEST(OnScreenKeyboardTest, ComputeBottomInsetClampedToClientHeight) {
  RECT client{0, 0, 800, 600};
  RECT occluded{0, -100, 800, 700};
  EXPECT_EQ(OnScreenKeyboardWin::ComputeBottomInset(client, occluded), 600.0);
}

TEST(OnScreenKeyboardTest, ComputeBottomInsetEmptyClientIsZero) {
  RECT client{0, 0, 800, 0};
  RECT occluded{0, -100, 800, 100};
  EXPECT_EQ(OnScreenKeyboardWin::ComputeBottomInset(client, occluded), 0.0);
}

TEST(OnScreenKeyboardTest, SmallWindowMovesAboveOcclusionWithoutResizing) {
  RECT window{100, 500, 600, 900};
  RECT work_area{0, 0, 1000, 1000};
  RECT occluded{0, 700, 1000, 1000};

  RECT adjusted = OnScreenKeyboardWin::ComputeWindowRectAboveOcclusion(
      window, work_area, occluded);

  EXPECT_EQ(adjusted.left, 100);
  EXPECT_EQ(adjusted.top, 300);
  EXPECT_EQ(adjusted.right, 600);
  EXPECT_EQ(adjusted.bottom, 700);
}

TEST(OnScreenKeyboardTest, TallWindowResizesToAvailableArea) {
  RECT window{100, 50, 600, 950};
  RECT work_area{0, 0, 1000, 1000};
  RECT occluded{0, 700, 1000, 1000};

  RECT adjusted = OnScreenKeyboardWin::ComputeWindowRectAboveOcclusion(
      window, work_area, occluded);

  EXPECT_EQ(adjusted.left, 100);
  EXPECT_EQ(adjusted.top, 0);
  EXPECT_EQ(adjusted.right, 600);
  EXPECT_EQ(adjusted.bottom, 700);
}

TEST(OnScreenKeyboardTest, WindowAlreadyAboveOcclusionIsUnchanged) {
  RECT window{100, 100, 600, 600};
  RECT work_area{0, 0, 1000, 1000};
  RECT occluded{0, 700, 1000, 1000};

  RECT adjusted = OnScreenKeyboardWin::ComputeWindowRectAboveOcclusion(
      window, work_area, occluded);

  EXPECT_EQ(adjusted.left, window.left);
  EXPECT_EQ(adjusted.top, window.top);
  EXPECT_EQ(adjusted.right, window.right);
  EXPECT_EQ(adjusted.bottom, window.bottom);
}

TEST(OnScreenKeyboardTest, WindowBesideOcclusionIsUnchanged) {
  RECT window{0, 500, 400, 900};
  RECT work_area{0, 0, 1200, 1000};
  RECT occluded{600, 700, 1200, 1000};

  RECT adjusted = OnScreenKeyboardWin::ComputeWindowRectAboveOcclusion(
      window, work_area, occluded);

  EXPECT_EQ(adjusted.left, window.left);
  EXPECT_EQ(adjusted.top, window.top);
  EXPECT_EQ(adjusted.right, window.right);
  EXPECT_EQ(adjusted.bottom, window.bottom);
}

TEST(OnScreenKeyboardTest, OccludedDipAtScale1IsUnchangedPhysical) {
  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  POINT origin{0, 0};
  RECT screen = OnScreenKeyboardWin::OccludedDipToPhysicalScreenRect(
      occluded, 1.0, origin);
  EXPECT_EQ(screen.left, 0);
  EXPECT_EQ(screen.top, 400);
  EXPECT_EQ(screen.right, 800);
  EXPECT_EQ(screen.bottom, 600);
}

TEST(OnScreenKeyboardTest, OccludedDipAtScale15IsPhysicalPixels) {
  // 200 DIP occlusion at 150% scale is 300 physical px, not 200.
  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  POINT origin{0, 0};
  RECT screen = OnScreenKeyboardWin::OccludedDipToPhysicalScreenRect(
      occluded, 1.5, origin);
  EXPECT_EQ(screen.left, 0);
  EXPECT_EQ(screen.top, 600);
  EXPECT_EQ(screen.right, 1200);
  EXPECT_EQ(screen.bottom, 900);
}

TEST(OnScreenKeyboardTest, OccludedDipAtScale2IsPhysicalPixels) {
  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  POINT origin{0, 0};
  RECT screen = OnScreenKeyboardWin::OccludedDipToPhysicalScreenRect(
      occluded, 2.0, origin);
  EXPECT_EQ(screen.left, 0);
  EXPECT_EQ(screen.top, 800);
  EXPECT_EQ(screen.right, 1600);
  EXPECT_EQ(screen.bottom, 1200);
}

TEST(OnScreenKeyboardTest, BottomInsetAtScale1) {
  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  POINT origin{0, 0};
  RECT view_client{0, 0, 800, 600};
  EXPECT_EQ(OnScreenKeyboardWin::ComputePhysicalBottomInset(
                occluded, 1.0, origin, view_client),
            200.0);
}

TEST(OnScreenKeyboardTest, BottomInsetAtScale15) {
  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  POINT origin{100, 50};
  RECT view_client{100, 50, 1300, 950};
  EXPECT_EQ(OnScreenKeyboardWin::ComputePhysicalBottomInset(
                occluded, 1.5, origin, view_client),
            300.0);
}

TEST(OnScreenKeyboardTest, ShowingUpdatesInsetWithoutTryHide) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);

  bool called = false;
  keyboard.SetVisibilityChangedCallback([&called]() { called = true; });

  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  RECT view_client{0, 0, 800, 600};
  keyboard.HandleVisibilityEvent(nullptr, true, occluded, 1.0, POINT{0, 0},
                                 view_client);

  EXPECT_TRUE(called);
  EXPECT_TRUE(keyboard.shown());
  EXPECT_EQ(keyboard.physical_bottom_inset(), 200.0);
  EXPECT_TRUE(applies.empty());
}

TEST(OnScreenKeyboardTest, HidingClearsInset) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);

  OnScreenKeyboardWin::DipRect occluded{0, 400, 800, 200};
  RECT view_client{0, 0, 800, 600};
  keyboard.HandleVisibilityEvent(nullptr, true, occluded, 1.0, POINT{0, 0},
                                 view_client);
  keyboard.HandleVisibilityEvent(nullptr, false, OnScreenKeyboardWin::DipRect{},
                                 1.0, POINT{0, 0}, RECT{});

  EXPECT_FALSE(keyboard.shown());
  EXPECT_EQ(keyboard.physical_bottom_inset(), 0.0);
  EXPECT_TRUE(applies.empty());
}

TEST(OnScreenKeyboardTest, InvalidHwndDoesNotCrash) {
  MockTaskRunner runner;
  auto api = std::make_unique<FakeOnScreenKeyboardWin32Api>();
  FakeOnScreenKeyboardWin32Api* api_ptr = api.get();
  api_ptr->valid = false;
  OnScreenKeyboardWin keyboard(&runner, std::move(api));
  bool called = false;
  keyboard.SetVisibilityChangedCallback([&called]() { called = true; });

  keyboard.Display(DummyHwnd());
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_FALSE(keyboard.shown());
  EXPECT_EQ(keyboard.physical_bottom_inset(), 0.0);
  EXPECT_FALSE(called);
  EXPECT_TRUE(api_ptr->positioned_rects.empty());
}

TEST(OnScreenKeyboardTest, HidingDoesNotCancelPendingDisplay) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);
  HWND hwnd = DummyHwnd();

  keyboard.Display(hwnd);
  keyboard.HandleVisibilityEvent(nullptr, false, OnScreenKeyboardWin::DipRect{},
                                 1.0, POINT{0, 0}, RECT{});
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(applies.size(), 1u);
  EXPECT_TRUE(applies[0].show);
}

TEST(OnScreenKeyboardTest, ClientClearedCancelsPendingDisplay) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);
  HWND hwnd = DummyHwnd();

  keyboard.Display(hwnd);
  keyboard.OnClientCleared();
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_TRUE(applies.empty());
}

TEST(OnScreenKeyboardTest, ClientClearedKeepsPendingDismiss) {
  MockTaskRunner runner;
  std::vector<ApplyCall> applies;
  RecordingOnScreenKeyboard keyboard(&runner, &applies);
  HWND hwnd = DummyHwnd();

  keyboard.Display(hwnd);
  keyboard.Dismiss(hwnd);
  keyboard.OnClientCleared();
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(applies.size(), 1u);
  EXPECT_FALSE(applies[0].show);
}

TEST(OnScreenKeyboardTest,
     IntermediateShowingGeometryAppliesOnlyFinalPlacementAfterDebounce) {
  MockTaskRunner runner;
  auto api = std::make_unique<FakeOnScreenKeyboardWin32Api>();
  FakeOnScreenKeyboardWin32Api* api_ptr = api.get();
  OnScreenKeyboardWin keyboard(&runner, std::move(api));

  keyboard.HandleVisibilityEvent(
      DummyHwnd(), true, OnScreenKeyboardWin::DipRect{0, 700, 1000, 300}, 1.0,
      POINT{0, 0}, api_ptr->client_rect);
  const std::chrono::milliseconds half_debounce =
      OnScreenKeyboardWin::kDisplayDismissDebounce / 2;
  runner.AdvanceTime(half_debounce);
  keyboard.HandleVisibilityEvent(
      DummyHwnd(), true, OnScreenKeyboardWin::DipRect{0, 600, 1000, 400}, 1.0,
      POINT{0, 0}, api_ptr->client_rect);

  runner.AdvanceTime(half_debounce);
  runner.SimulateTimerAwake();
  EXPECT_TRUE(api_ptr->positioned_rects.empty());
  runner.AdvanceTime(half_debounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(api_ptr->positioned_rects.size(), 1u);
  EXPECT_EQ(api_ptr->positioned_rects[0].left, 100);
  EXPECT_EQ(api_ptr->positioned_rects[0].top, 200);
  EXPECT_EQ(api_ptr->positioned_rects[0].right, 600);
  EXPECT_EQ(api_ptr->positioned_rects[0].bottom, 600);
  EXPECT_EQ(api_ptr->get_placement_count, 1);
}

TEST(OnScreenKeyboardTest, HidingRestoresSavedWindowPlacement) {
  MockTaskRunner runner;
  auto api = std::make_unique<FakeOnScreenKeyboardWin32Api>();
  FakeOnScreenKeyboardWin32Api* api_ptr = api.get();
  const WINDOWPLACEMENT original = api_ptr->placement;
  OnScreenKeyboardWin keyboard(&runner, std::move(api));

  keyboard.HandleVisibilityEvent(
      DummyHwnd(), true, OnScreenKeyboardWin::DipRect{0, 600, 1000, 400}, 1.0,
      POINT{0, 0}, api_ptr->client_rect);
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();
  ASSERT_EQ(api_ptr->positioned_rects.size(), 1u);

  keyboard.HandleVisibilityEvent(nullptr, false, OnScreenKeyboardWin::DipRect{},
                                 1.0, POINT{0, 0}, RECT{});
  EXPECT_TRUE(api_ptr->restored_placements.empty());
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(api_ptr->restored_placements.size(), 1u);
  const WINDOWPLACEMENT& restored = api_ptr->restored_placements[0];
  EXPECT_EQ(restored.length, original.length);
  EXPECT_EQ(restored.flags, original.flags);
  EXPECT_EQ(restored.showCmd, original.showCmd);
  EXPECT_EQ(restored.ptMinPosition.x, original.ptMinPosition.x);
  EXPECT_EQ(restored.ptMinPosition.y, original.ptMinPosition.y);
  EXPECT_EQ(restored.ptMaxPosition.x, original.ptMaxPosition.x);
  EXPECT_EQ(restored.ptMaxPosition.y, original.ptMaxPosition.y);
  EXPECT_EQ(restored.rcNormalPosition.left, original.rcNormalPosition.left);
  EXPECT_EQ(restored.rcNormalPosition.top, original.rcNormalPosition.top);
  EXPECT_EQ(restored.rcNormalPosition.right, original.rcNormalPosition.right);
  EXPECT_EQ(restored.rcNormalPosition.bottom, original.rcNormalPosition.bottom);
}

TEST(OnScreenKeyboardTest, UserMoveUpdatesPlacementRestoredAfterHiding) {
  MockTaskRunner runner;
  auto api = std::make_unique<FakeOnScreenKeyboardWin32Api>();
  FakeOnScreenKeyboardWin32Api* api_ptr = api.get();
  OnScreenKeyboardWin keyboard(&runner, std::move(api));

  keyboard.HandleVisibilityEvent(
      DummyHwnd(), true, OnScreenKeyboardWin::DipRect{0, 600, 1000, 400}, 1.0,
      POINT{0, 0}, api_ptr->client_rect);
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  const WINDOWPLACEMENT moved_placement{
      sizeof(WINDOWPLACEMENT), 0, SW_SHOWNORMAL, {11, 21}, {31, 41},
      {200, 400, 700, 800}};
  api_ptr->placement = moved_placement;
  api_ptr->window_rect = moved_placement.rcNormalPosition;
  keyboard.OnRootWindowMoveSizeEnded(DummyRootHwnd());

  keyboard.HandleVisibilityEvent(nullptr, false, OnScreenKeyboardWin::DipRect{},
                                 1.0, POINT{0, 0}, RECT{});
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  ASSERT_EQ(api_ptr->restored_placements.size(), 1u);
  const WINDOWPLACEMENT& restored = api_ptr->restored_placements[0];
  EXPECT_EQ(restored.ptMinPosition.x, moved_placement.ptMinPosition.x);
  EXPECT_EQ(restored.ptMinPosition.y, moved_placement.ptMinPosition.y);
  EXPECT_EQ(restored.ptMaxPosition.x, moved_placement.ptMaxPosition.x);
  EXPECT_EQ(restored.ptMaxPosition.y, moved_placement.ptMaxPosition.y);
  EXPECT_EQ(restored.rcNormalPosition.left,
            moved_placement.rcNormalPosition.left);
  EXPECT_EQ(restored.rcNormalPosition.top,
            moved_placement.rcNormalPosition.top);
  EXPECT_EQ(restored.rcNormalPosition.right,
            moved_placement.rcNormalPosition.right);
  EXPECT_EQ(restored.rcNormalPosition.bottom,
            moved_placement.rcNormalPosition.bottom);
}

TEST(OnScreenKeyboardTest, MaximizedWindowUsesInsetsWithoutChangingPlacement) {
  MockTaskRunner runner;
  auto api = std::make_unique<FakeOnScreenKeyboardWin32Api>();
  FakeOnScreenKeyboardWin32Api* api_ptr = api.get();
  api_ptr->maximized = true;
  OnScreenKeyboardWin keyboard(&runner, std::move(api));
  std::vector<double> insets;
  keyboard.SetVisibilityChangedCallback([&keyboard, &insets]() {
    insets.push_back(keyboard.physical_bottom_inset());
  });

  keyboard.HandleVisibilityEvent(
      DummyHwnd(), true, OnScreenKeyboardWin::DipRect{0, 700, 1000, 300}, 1.0,
      POINT{0, 0}, api_ptr->client_rect);
  keyboard.HandleVisibilityEvent(
      DummyHwnd(), true, OnScreenKeyboardWin::DipRect{0, 600, 1000, 400}, 1.0,
      POINT{0, 0}, api_ptr->client_rect);
  runner.AdvanceTime(OnScreenKeyboardWin::kDisplayDismissDebounce);
  runner.SimulateTimerAwake();

  EXPECT_TRUE(api_ptr->positioned_rects.empty());
  EXPECT_EQ(api_ptr->get_placement_count, 0);
  EXPECT_TRUE(api_ptr->restored_placements.empty());
  ASSERT_EQ(insets.size(), 2u);
  EXPECT_EQ(insets[0], 300.0);
  EXPECT_EQ(insets[1], 400.0);
  EXPECT_EQ(keyboard.physical_bottom_inset(), 400.0);
}

}  // namespace testing
}  // namespace flutter
