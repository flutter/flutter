// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>
#include "flutter/shell/platform/windows/flutter_windows_display_monitor.h"

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

MockWindowsProcTable* g_windows_proc_table = nullptr;

class FlutterWindowsDisplayMonitorTest : public WindowsTest {};

// Test that the display monitor correctly handles multiple monitors
TEST_F(FlutterWindowsDisplayMonitorTest, MultipleMonitors) {
  FlutterWindowsEngineBuilder builder(GetContext());
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();

  auto mock_windows_proc_table =
      std::make_shared<NiceMock<MockWindowsProcTable>>();

  // Set up expectations of the mock to return 2 monitors
  EXPECT_CALL(*mock_windows_proc_table, GetSystemMetrics(SM_CMONITORS))
      .WillRepeatedly(Return(2));

  // Set up EnumDisplayDevices to return two valid display devices
  DISPLAY_DEVICE display_device1 = {0};
  display_device1.cb = sizeof(DISPLAY_DEVICE);
  display_device1.StateFlags = DISPLAY_DEVICE_ATTACHED_TO_DESKTOP;
  wcscpy_s(display_device1.DeviceName, L"TestDevice1");

  DISPLAY_DEVICE display_device2 = {0};
  display_device2.cb = sizeof(DISPLAY_DEVICE);
  display_device2.StateFlags = DISPLAY_DEVICE_ATTACHED_TO_DESKTOP;
  wcscpy_s(display_device2.DeviceName, L"TestDevice2");

  // First call to EnumDisplayDevices with index 0
  EXPECT_CALL(*mock_windows_proc_table, EnumDisplayDevices(nullptr, 0, _, 0))
      .WillOnce(
          DoAll(::testing::SetArgPointee<2>(display_device1), Return(TRUE)));

  // Call EnumDisplayDevices with index 1
  EXPECT_CALL(*mock_windows_proc_table, EnumDisplayDevices(nullptr, 1, _, 0))
      .WillOnce(
          DoAll(::testing::SetArgPointee<2>(display_device2), Return(TRUE)));

  // Call EnumDisplayDevices with index 2 (returns FALSE to end enumeration)
  EXPECT_CALL(*mock_windows_proc_table, EnumDisplayDevices(nullptr, 2, _, 0))
      .WillOnce(Return(FALSE));

  DEVMODE device_mode1 = {0};
  device_mode1.dmSize = sizeof(DEVMODE);
  device_mode1.dmPelsWidth = 1920;
  device_mode1.dmPelsHeight = 1080;
  device_mode1.dmDisplayFrequency = 60;
  device_mode1.dmPosition.x = 0;
  device_mode1.dmPosition.y = 0;

  DEVMODE device_mode2 = {0};
  device_mode2.dmSize = sizeof(DEVMODE);
  device_mode2.dmPelsWidth = 2560;
  device_mode2.dmPelsHeight = 1440;
  device_mode2.dmDisplayFrequency = 144;
  device_mode2.dmPosition.x = 1920;
  device_mode2.dmPosition.y = 0;

  EXPECT_CALL(*mock_windows_proc_table,
              EnumDisplaySettings(::testing::StrEq(L"TestDevice1"),
                                  ENUM_CURRENT_SETTINGS, _))
      .WillOnce(DoAll(::testing::SetArgPointee<2>(device_mode1), Return(TRUE)));
  EXPECT_CALL(*mock_windows_proc_table,
              EnumDisplaySettings(::testing::StrEq(L"TestDevice2"),
                                  ENUM_CURRENT_SETTINGS, _))
      .WillOnce(DoAll(::testing::SetArgPointee<2>(device_mode2), Return(TRUE)));

  // Set up MonitorFromPoint to return valid monitor handles
  HMONITOR mock_monitor1 = reinterpret_cast<HMONITOR>(123);
  HMONITOR mock_monitor2 = reinterpret_cast<HMONITOR>(456);

  // Calculate center points for the monitors
  LONG center_x1 = device_mode1.dmPosition.x + (device_mode1.dmPelsWidth / 2);
  LONG center_y1 = device_mode1.dmPosition.y + (device_mode1.dmPelsHeight / 2);
  LONG center_x2 = device_mode2.dmPosition.x + (device_mode2.dmPelsWidth / 2);
  LONG center_y2 = device_mode2.dmPosition.y + (device_mode2.dmPelsHeight / 2);

  EXPECT_CALL(*mock_windows_proc_table,
              MonitorFromPoint(AllOf(Field(&POINT::x, center_x1),
                                     Field(&POINT::y, center_y1)),
                               MONITOR_DEFAULTTONULL))
      .WillOnce(Return(mock_monitor1));
  EXPECT_CALL(*mock_windows_proc_table,
              MonitorFromPoint(AllOf(Field(&POINT::x, center_x2),
                                     Field(&POINT::y, center_y2)),
                               MONITOR_DEFAULTTONULL))
      .WillOnce(Return(mock_monitor2));

  // Set up GetDpiForMonitor to return different DPI values
  EXPECT_CALL(*mock_windows_proc_table, GetDpiForMonitor(mock_monitor1, _))
      .WillRepeatedly(Return(96));  // Default/Standard DPI
  EXPECT_CALL(*mock_windows_proc_table, GetDpiForMonitor(mock_monitor2, _))
      .WillRepeatedly(Return(144));  // High DPI

  // Create the display monitor with the mock engine and proc table
  auto display_monitor = std::make_unique<FlutterWindowsDisplayMonitor>(
      engine.get(), mock_windows_proc_table);

  display_monitor->UpdateDisplays();
}

// Test that the display monitor correctly handles a display change message
TEST_F(FlutterWindowsDisplayMonitorTest, HandleDisplayChangeMessage) {
  // Create a mock engine
  FlutterWindowsEngineBuilder builder(GetContext());
  std::unique_ptr<FlutterWindowsEngine> engine = builder.Build();

  // Create a mock Windows proc table
  auto mock_windows_proc_table =
      std::make_shared<NiceMock<MockWindowsProcTable>>();

  // Set up expectations for the mock
  EXPECT_CALL(*mock_windows_proc_table, GetSystemMetrics(_))
      .WillRepeatedly(Return(1));  // Return 1 monitor

  // Create the display monitor with the mock engine and proc table
  auto display_monitor = std::make_unique<FlutterWindowsDisplayMonitor>(
      engine.get(), mock_windows_proc_table);

  // Test handling a display change message
  HWND dummy_hwnd = reinterpret_cast<HWND>(1);
  LRESULT result = 0;

  // Verify that WM_DISPLAYCHANGE is handled
  EXPECT_TRUE(display_monitor->HandleWindowMessage(dummy_hwnd, WM_DISPLAYCHANGE,
                                                   0, 0, &result));

  // Verify that WM_DPICHANGED is handled
  EXPECT_TRUE(display_monitor->HandleWindowMessage(dummy_hwnd, WM_DPICHANGED, 0,
                                                   0, &result));

  // Verify that other messages are not handled
  EXPECT_FALSE(display_monitor->HandleWindowMessage(dummy_hwnd, WM_PAINT, 0, 0,
                                                    &result));
}

}  // namespace testing
}  // namespace flutter
