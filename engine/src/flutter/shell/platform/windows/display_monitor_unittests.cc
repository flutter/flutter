// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>
#include "flutter/shell/platform/windows/display_monitor.h"

#include <string>
#include "flutter/shell/platform/windows/testing/flutter_windows_engine_builder.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "shell/platform/windows/testing/mock_windows_proc_table.h"

// Mock Windows API functions to avoid hardware dependencies
#define MOCK_WINDOWS_API

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::AllOf;
using ::testing::AtLeast;
using ::testing::DoAll;
using ::testing::Field;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::SetArgPointee;
using ::testing::StrEq;

class DisplayMonitorTest : public WindowsTest {};

// Test that the display monitor correctly handles multiple monitors
TEST_F(DisplayMonitorTest, MultipleMonitors) {
  auto mock_windows_proc_table =
      std::make_shared<NiceMock<MockWindowsProcTable>>();

  FlutterWindowsEngineBuilder builder(GetContext());
  builder.SetWindowsProcTable(mock_windows_proc_table);
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();

  HMONITOR mock_monitor1 = reinterpret_cast<HMONITOR>(123);
  HMONITOR mock_monitor2 = reinterpret_cast<HMONITOR>(456);

  MONITORINFOEXW monitor_info1 = {};
  monitor_info1.cbSize = sizeof(MONITORINFOEXW);
  monitor_info1.rcMonitor = {0, 0, 1920, 1080};
  monitor_info1.rcWork = {0, 0, 1920, 1080};
  monitor_info1.dwFlags = MONITORINFOF_PRIMARY;
  wcscpy_s(monitor_info1.szDevice, L"\\\\.\\DISPLAY1");

  MONITORINFOEXW monitor_info2 = {};
  monitor_info2.cbSize = sizeof(MONITORINFOEXW);
  monitor_info2.rcMonitor = {1920, 0, 1920 + 2560, 1440};
  monitor_info2.rcWork = {1920, 0, 1920 + 2560, 1440};
  monitor_info2.dwFlags = 0;
  wcscpy_s(monitor_info2.szDevice, L"\\\\.\\DISPLAY2");

  EXPECT_CALL(*mock_windows_proc_table, GetMonitorInfoW(mock_monitor1, _))
      .WillOnce(DoAll(SetArgPointee<1>(monitor_info1), Return(TRUE)));
  EXPECT_CALL(*mock_windows_proc_table, GetMonitorInfoW(mock_monitor2, _))
      .WillOnce(DoAll(SetArgPointee<1>(monitor_info2), Return(TRUE)));

  EXPECT_CALL(*mock_windows_proc_table,
              EnumDisplayMonitors(nullptr, nullptr, _, _))
      .WillOnce([&](HDC hdc, LPCRECT lprcClip, MONITORENUMPROC lpfnEnum,
                    LPARAM dwData) {
        lpfnEnum(mock_monitor1, nullptr, &monitor_info1.rcMonitor, dwData);
        lpfnEnum(mock_monitor2, nullptr, &monitor_info2.rcMonitor, dwData);
        return TRUE;
      });

  // Set up GetDpiForMonitor to return different DPI values
  EXPECT_CALL(*mock_windows_proc_table, GetDpiForMonitor(mock_monitor1, _))
      .WillRepeatedly(Return(96));  // Default/Standard DPI
  EXPECT_CALL(*mock_windows_proc_table, GetDpiForMonitor(mock_monitor2, _))
      .WillRepeatedly(Return(144));  // High DPI

  EXPECT_CALL(*mock_windows_proc_table, EnumDisplaySettings(_, _, _))
      .WillRepeatedly(Return(TRUE));

  // Create the display monitor with the mock engine
  auto display_monitor = std::make_unique<DisplayMonitor>(engine.get());

  display_monitor->UpdateDisplays();
}

// Test that the display monitor correctly handles a display change message
TEST_F(DisplayMonitorTest, HandleDisplayChangeMessage) {
  // Create a mock Windows proc table
  auto mock_windows_proc_table =
      std::make_shared<NiceMock<MockWindowsProcTable>>();

  // Create a mock engine
  FlutterWindowsEngineBuilder builder(GetContext());
  builder.SetWindowsProcTable(mock_windows_proc_table);
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();

  EXPECT_CALL(*mock_windows_proc_table, EnumDisplayMonitors(_, _, _, _))
      .WillRepeatedly(Return(TRUE));

  // Create the display monitor with the mock engine
  auto display_monitor = std::make_unique<DisplayMonitor>(engine.get());

  // Test handling a display change message
  HWND dummy_hwnd = reinterpret_cast<HWND>(1);
  LRESULT result = 0;

  // Verify that WM_DISPLAYCHANGE is handled
  EXPECT_FALSE(display_monitor->HandleWindowMessage(
      dummy_hwnd, WM_DISPLAYCHANGE, 0, 0, &result));

  // Verify that WM_DPICHANGED is handled
  EXPECT_FALSE(display_monitor->HandleWindowMessage(dummy_hwnd, WM_DPICHANGED,
                                                    0, 0, &result));

  // Verify that other messages are not handled
  EXPECT_FALSE(display_monitor->HandleWindowMessage(dummy_hwnd, WM_PAINT, 0, 0,
                                                    &result));
}

}  // namespace testing
}  // namespace flutter
