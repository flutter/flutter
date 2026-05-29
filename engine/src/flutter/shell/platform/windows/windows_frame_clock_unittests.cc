// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_frame_clock.h"

#include <windows.h>

#include <atomic>
#include <chrono>
#include <functional>

#include "gtest/gtest.h"

namespace flutter {
namespace testing {
namespace {

std::atomic_uint64_t g_time_nanos = 0;

uint64_t CurrentTime() {
  return g_time_nanos.load();
}

void PumpUntil(TaskRunner& task_runner,
               const std::function<bool()>& condition) {
  auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
  while (!condition() && std::chrono::steady_clock::now() < deadline) {
    task_runner.PollOnce(std::chrono::milliseconds(1));
  }
}

}  // namespace

TEST(WindowsFrameClockTest, SignalsVsyncFromDisplayWaiter) {
  TaskRunner task_runner(CurrentTime, [](const FlutterTask*) {});
  HANDLE vsync_event = ::CreateEvent(nullptr, FALSE, FALSE, nullptr);
  ASSERT_NE(vsync_event, nullptr);
  WindowsFrameClock frame_clock(
      &task_runner, CurrentTime,
      [](HWND hwnd) { return std::chrono::nanoseconds(16'666'667); },
      [vsync_event](HWND hwnd) {
        return ::WaitForSingleObject(vsync_event, INFINITE) == WAIT_OBJECT_0;
      });

  intptr_t received_baton = 0;
  uint64_t received_start_time = 0;
  uint64_t received_target_time = 0;
  bool called = false;

  g_time_nanos = 123'000'000;
  frame_clock.AwaitVsync(
      42, [&](intptr_t baton, uint64_t start_time, uint64_t target_time) {
        received_baton = baton;
        received_start_time = start_time;
        received_target_time = target_time;
        called = true;
      });

  g_time_nanos = 456'000'000;
  ::SetEvent(vsync_event);
  PumpUntil(task_runner, [&called] { return called; });

  ASSERT_TRUE(called);
  EXPECT_EQ(received_baton, 42);
  EXPECT_EQ(received_start_time, 456'000'000u);
  EXPECT_EQ(received_target_time, 472'666'667u);

  ::CloseHandle(vsync_event);
}

TEST(WindowsFrameClockTest, UpdatesFramePacingWindow) {
  TaskRunner task_runner(CurrentTime, [](const FlutterTask*) {});
  std::atomic<HWND> waited_hwnd = nullptr;
  WindowsFrameClock frame_clock(
      &task_runner, CurrentTime,
      [](HWND hwnd) { return std::chrono::nanoseconds(8'333'333); },
      [&waited_hwnd](HWND hwnd) {
        waited_hwnd = hwnd;
        return true;
      });
  HWND first_window = reinterpret_cast<HWND>(1);
  HWND second_window = reinterpret_cast<HWND>(2);
  frame_clock.SetFramePacingWindow(first_window);
  frame_clock.SetFramePacingWindow(second_window);

  bool called = false;
  g_time_nanos = 1'000;
  frame_clock.AwaitVsync(
      7, [&](intptr_t baton, uint64_t start_time, uint64_t target_time) {
        called = true;
        EXPECT_EQ(baton, 7);
        EXPECT_EQ(start_time, 2'000u);
        EXPECT_EQ(target_time, 8'335'333u);
      });

  g_time_nanos = 2'000;
  PumpUntil(task_runner, [&called] { return called; });
  EXPECT_TRUE(called);
  EXPECT_EQ(waited_hwnd.load(), second_window);
}

TEST(WindowsFrameClockTest, FallsBackWhenDisplayWaiterIsUnavailable) {
  TaskRunner task_runner(CurrentTime, [](const FlutterTask*) {});
  WindowsFrameClock frame_clock(
      &task_runner, CurrentTime,
      [](HWND hwnd) { return std::chrono::nanoseconds(16'666'667); },
      [](HWND hwnd) { return false; });

  bool called = false;
  uint64_t received_start_time = 0;
  uint64_t received_target_time = 0;

  g_time_nanos = 9'000;
  frame_clock.AwaitVsync(
      3, [&](intptr_t baton, uint64_t start_time, uint64_t target_time) {
        EXPECT_EQ(baton, 3);
        received_start_time = start_time;
        received_target_time = target_time;
        called = true;
      });

  PumpUntil(task_runner, [&called] { return called; });
  ASSERT_TRUE(called);
  EXPECT_EQ(received_start_time, 9'000u);
  EXPECT_EQ(received_target_time, 16'675'667u);
}

TEST(WindowsFrameClockTest, InvokesVsyncCallbackWithoutTaskRunnerPump) {
  TaskRunner task_runner(CurrentTime, [](const FlutterTask*) {});
  HANDLE vsync_event = ::CreateEvent(nullptr, FALSE, FALSE, nullptr);
  ASSERT_NE(vsync_event, nullptr);
  WindowsFrameClock frame_clock(
      &task_runner, CurrentTime,
      [](HWND hwnd) { return std::chrono::nanoseconds(1'000'000); },
      [vsync_event](HWND hwnd) {
        return ::WaitForSingleObject(vsync_event, INFINITE) == WAIT_OBJECT_0;
      });

  std::atomic_bool called = false;

  g_time_nanos = 10'000'000;
  frame_clock.AwaitVsync(
      17, [&](intptr_t baton, uint64_t start_time, uint64_t target_time) {
        EXPECT_EQ(baton, 17);
        EXPECT_EQ(target_time - start_time, 1'000'000u);
        called = true;
      });

  g_time_nanos = 11'000'000;
  ::SetEvent(vsync_event);
  auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
  while (!called && std::chrono::steady_clock::now() < deadline) {
    ::Sleep(1);
  }

  EXPECT_TRUE(called);
  ::CloseHandle(vsync_event);
}

}  // namespace testing
}  // namespace flutter
