// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/display_manager.h"

#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/testing/mock_windows_proc_table.h"
#include "flutter/shell/platform/windows/testing/windows_test.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// Returns a Flutter project with the required path values to create
// a test engine.
FlutterProjectBundle GetTestProject() {
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"C:\\foo\\flutter_assets";
  properties.icu_data_path = L"C:\\foo\\icudtl.dat";
  properties.aot_library_path = L"C:\\foo\\aot.so";

  return FlutterProjectBundle{properties};
}

void PumpMessage() {
  ::MSG msg;
  if (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
}

class DisplayManagerTest : public WindowsTest {};

class MockFlutterWindowsEngine : public FlutterWindowsEngine {
 public:
  explicit MockFlutterWindowsEngine(
      std::shared_ptr<WindowsProcTable> windows_proc_table = nullptr)
      : FlutterWindowsEngine(GetTestProject(), std::move(windows_proc_table)) {}
  MOCK_METHOD(bool, running, (), (const, override));
  MOCK_METHOD(void,
              OnDisplaysChanged,
              (std::vector<FlutterEngineDisplay> const&),
              (const, override));
};
}  // namespace

TEST_F(DisplayManagerTest, CanGetSingleMonitorInfo) {
  auto windows_proc_table = std::make_shared<MockWindowsProcTable>();
  auto engine = MockFlutterWindowsEngine(windows_proc_table);
  DisplayManager manager(&engine);

  HMONITOR fake = reinterpret_cast<HMONITOR>(0x1234);
  EXPECT_CALL(*windows_proc_table, EnumDisplayMonitors)
      .WillOnce(::testing::Invoke(
          [=](HDC, LPCRECT, MONITORENUMPROC callback, LPARAM dwData) -> BOOL {
            callback(fake, nullptr, nullptr, dwData);
            return TRUE;
          }));
  EXPECT_CALL(*windows_proc_table, GetMonitorInfo)
      .WillOnce(::testing::Invoke([=](HMONITOR, LPMONITORINFO info) -> BOOL {
        info->rcMonitor.right = 800;
        info->rcMonitor.left = 0;
        info->rcMonitor.bottom = 600;
        info->rcMonitor.top = 0;
        return TRUE;
      }));
  EXPECT_CALL(*windows_proc_table, EnumDisplaySettingsW)
      .WillOnce(::testing::Return(FALSE));
  auto const displays = manager.displays();
  EXPECT_THAT(displays.size(), ::testing::Eq(1));
  EXPECT_THAT(displays[0].single_display, ::testing::Eq(true));
  EXPECT_THAT(displays[0].display_id,
              ::testing::Eq(reinterpret_cast<FlutterEngineDisplayId>(fake)));
  EXPECT_THAT(displays[0].width, ::testing::Eq(800));
  EXPECT_THAT(displays[0].height, ::testing::Eq(600));
  EXPECT_THAT(displays[0].refresh_rate, ::testing::Eq(0));
}

TEST_F(DisplayManagerTest, CanGetWithDisplayMonitorSettings) {
  auto windows_proc_table = std::make_shared<MockWindowsProcTable>();
  auto engine = MockFlutterWindowsEngine(windows_proc_table);
  DisplayManager manager(&engine);

  HMONITOR fake = reinterpret_cast<HMONITOR>(0x1234);
  EXPECT_CALL(*windows_proc_table, EnumDisplayMonitors)
      .WillOnce(::testing::Invoke(
          [=](HDC, LPCRECT, MONITORENUMPROC callback, LPARAM dwData) -> BOOL {
            callback(fake, nullptr, nullptr, dwData);
            return TRUE;
          }));
  EXPECT_CALL(*windows_proc_table, GetMonitorInfo)
      .WillOnce(::testing::Invoke([=](HMONITOR, LPMONITORINFO info) -> BOOL {
        info->rcMonitor.right = 800;
        info->rcMonitor.left = 0;
        info->rcMonitor.bottom = 600;
        info->rcMonitor.top = 0;
        return TRUE;
      }));
  EXPECT_CALL(*windows_proc_table, EnumDisplaySettingsW)
      .WillOnce(::testing::Invoke([=](LPCWSTR, DWORD, DEVMODEW* lpDevMode) {
        lpDevMode->dmDisplayFrequency = 1234;
        return TRUE;
      }));
  auto const displays = manager.displays();
  EXPECT_THAT(displays[0].refresh_rate, ::testing::Eq(1234));
}

TEST_F(DisplayManagerTest, CanGetMultipleMonitorInfo) {
  auto windows_proc_table = std::make_shared<MockWindowsProcTable>();
  auto engine = MockFlutterWindowsEngine(windows_proc_table);
  DisplayManager manager(&engine);

  ::testing::InSequence seq;
  HMONITOR first = reinterpret_cast<HMONITOR>(0x1234);
  HMONITOR second = reinterpret_cast<HMONITOR>(0x1234);
  EXPECT_CALL(*windows_proc_table, EnumDisplayMonitors)
      .WillOnce(::testing::Invoke(
          [=](HDC, LPCRECT, MONITORENUMPROC callback, LPARAM dwData) -> BOOL {
            callback(first, nullptr, nullptr, dwData);
            callback(second, nullptr, nullptr, dwData);
            return TRUE;
          }));

  // First monitor
  EXPECT_CALL(*windows_proc_table, GetMonitorInfo)
      .WillOnce(::testing::Invoke([=](HMONITOR, LPMONITORINFO info) -> BOOL {
        info->rcMonitor.right = 800;
        info->rcMonitor.left = 0;
        info->rcMonitor.bottom = 600;
        info->rcMonitor.top = 0;
        return TRUE;
      }));
  EXPECT_CALL(*windows_proc_table, EnumDisplaySettingsW)
      .WillOnce(::testing::Return(FALSE));

  // Second monitor
  EXPECT_CALL(*windows_proc_table, GetMonitorInfo)
      .WillOnce(::testing::Invoke([=](HMONITOR, LPMONITORINFO info) -> BOOL {
        info->rcMonitor.right = 400;
        info->rcMonitor.left = 0;
        info->rcMonitor.bottom = 300;
        info->rcMonitor.top = 0;
        return TRUE;
      }));
  EXPECT_CALL(*windows_proc_table, EnumDisplaySettingsW)
      .WillOnce(::testing::Return(FALSE));

  auto const displays = manager.displays();
  EXPECT_THAT(displays.size(), ::testing::Eq(2));
  EXPECT_THAT(displays[0].single_display, ::testing::Eq(false));
  EXPECT_THAT(displays[0].display_id,
              ::testing::Eq(reinterpret_cast<FlutterEngineDisplayId>(first)));
  EXPECT_THAT(displays[0].width, ::testing::Eq(800));
  EXPECT_THAT(displays[0].height, ::testing::Eq(600));
  EXPECT_THAT(displays[0].refresh_rate, ::testing::Eq(0));

  EXPECT_THAT(displays[1].single_display, ::testing::Eq(false));
  EXPECT_THAT(displays[1].display_id,
              ::testing::Eq(reinterpret_cast<FlutterEngineDisplayId>(second)));
  EXPECT_THAT(displays[1].width, ::testing::Eq(400));
  EXPECT_THAT(displays[1].height, ::testing::Eq(300));
  EXPECT_THAT(displays[1].refresh_rate, ::testing::Eq(0));
}

TEST_F(DisplayManagerTest, OnDisplaysChangedIsCalledOnDisplayChangeMessage) {
  auto windows_proc_table = std::make_shared<MockWindowsProcTable>();
  auto engine = MockFlutterWindowsEngine(windows_proc_table);
  DisplayManager manager(&engine);

  HMONITOR fake = reinterpret_cast<HMONITOR>(0x1234);
  EXPECT_CALL(*windows_proc_table, EnumDisplayMonitors)
      .WillOnce(::testing::Invoke(
          [=](HDC, LPCRECT, MONITORENUMPROC callback, LPARAM dwData) -> BOOL {
            callback(fake, nullptr, nullptr, dwData);
            return TRUE;
          }));
  EXPECT_CALL(*windows_proc_table, GetMonitorInfo)
      .WillOnce(::testing::Invoke([=](HMONITOR, LPMONITORINFO info) -> BOOL {
        info->rcMonitor.right = 800;
        info->rcMonitor.left = 0;
        info->rcMonitor.bottom = 600;
        info->rcMonitor.top = 0;
        return TRUE;
      }));
  EXPECT_CALL(*windows_proc_table, EnumDisplaySettingsW)
      .WillOnce(::testing::Return(FALSE));
  EXPECT_CALL(engine, running).WillOnce(::testing::Return(true));
  EXPECT_CALL(engine, OnDisplaysChanged).Times(1);

  ::SendMessage(manager.get_window_handle(), WM_DISPLAYCHANGE, 0, 0);
  PumpMessage();
}

TEST_F(DisplayManagerTest, OnDisplaysChangedIsCalledOnDevniceChangeMessage) {
  auto windows_proc_table = std::make_shared<MockWindowsProcTable>();
  auto engine = MockFlutterWindowsEngine(windows_proc_table);
  DisplayManager manager(&engine);

  HMONITOR fake = reinterpret_cast<HMONITOR>(0x1234);
  EXPECT_CALL(*windows_proc_table, EnumDisplayMonitors)
      .WillOnce(::testing::Invoke(
          [=](HDC, LPCRECT, MONITORENUMPROC callback, LPARAM dwData) -> BOOL {
            callback(fake, nullptr, nullptr, dwData);
            return TRUE;
          }));
  EXPECT_CALL(*windows_proc_table, GetMonitorInfo)
      .WillOnce(::testing::Invoke([=](HMONITOR, LPMONITORINFO info) -> BOOL {
        info->rcMonitor.right = 800;
        info->rcMonitor.left = 0;
        info->rcMonitor.bottom = 600;
        info->rcMonitor.top = 0;
        return TRUE;
      }));
  EXPECT_CALL(*windows_proc_table, EnumDisplaySettingsW)
      .WillOnce(::testing::Return(FALSE));
  EXPECT_CALL(engine, running).WillOnce(::testing::Return(true));
  EXPECT_CALL(engine, OnDisplaysChanged).Times(1);

  ::SendMessage(manager.get_window_handle(), WM_DEVICECHANGE, 0, 0);
  PumpMessage();
}
}  // namespace testing
}  // namespace flutter