// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_proc_table.h"

#include "gtest/gtest.h"

namespace flutter {
namespace testing {

// Verifies that |IsWindows11OrGreater| agrees with the version reported by
// |RtlGetVersion| on the host running the test. This exercises the runtime
// resolution of |RtlGetVersion| from ntdll.dll and the build-number based
// comparison used to gate Windows 11-only compositing features.
TEST(WindowsProcTableTest, IsWindows11OrGreaterMatchesRtlGetVersion) {
  using RtlGetVersion_ = LONG(__stdcall*)(POSVERSIONINFOW);
  HMODULE ntdll = ::GetModuleHandleW(L"ntdll.dll");
  ASSERT_NE(ntdll, nullptr);
  auto rtl_get_version = reinterpret_cast<RtlGetVersion_>(
      ::GetProcAddress(ntdll, "RtlGetVersion"));
  ASSERT_NE(rtl_get_version, nullptr);

  OSVERSIONINFOW version_info = {};
  version_info.dwOSVersionInfoSize = sizeof(version_info);
  ASSERT_EQ(rtl_get_version(&version_info), 0);

  bool const expected =
      version_info.dwMajorVersion > 10 || (version_info.dwMajorVersion == 10 &&
                                           version_info.dwBuildNumber >= 22000);

  WindowsProcTable proc_table;
  EXPECT_EQ(proc_table.IsWindows11OrGreater(), expected);
}

}  // namespace testing
}  // namespace flutter
