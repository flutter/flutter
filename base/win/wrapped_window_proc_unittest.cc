// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_loop.h"
#include "base/win/wrapped_window_proc.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

DWORD kExceptionCode = 12345;
WPARAM kCrashMsg = 98765;

// A trivial WindowProc that generates an exception.
LRESULT CALLBACK TestWindowProc(HWND hwnd, UINT message,
                                WPARAM wparam, LPARAM lparam) {
  if (message == kCrashMsg)
    RaiseException(kExceptionCode, 0, 0, NULL);
  return DefWindowProc(hwnd, message, wparam, lparam);
}

// This class implements an exception filter that can be queried about a past
// exception.
class TestWrappedExceptionFiter {
 public:
  TestWrappedExceptionFiter() : called_(false) {
    EXPECT_FALSE(s_filter_);
    s_filter_ = this;
  }

  ~TestWrappedExceptionFiter() {
    EXPECT_EQ(s_filter_, this);
    s_filter_ = NULL;
  }

  bool called() {
    return called_;
  }

  // The actual exception filter just records the exception.
  static int Filter(EXCEPTION_POINTERS* info) {
    EXPECT_FALSE(s_filter_->called_);
    if (info->ExceptionRecord->ExceptionCode == kExceptionCode)
      s_filter_->called_ = true;
    return EXCEPTION_EXECUTE_HANDLER;
  }

 private:
  bool called_;
  static TestWrappedExceptionFiter* s_filter_;
};
TestWrappedExceptionFiter* TestWrappedExceptionFiter::s_filter_ = NULL;

}  // namespace.

TEST(WrappedWindowProc, CatchesExceptions) {
  HINSTANCE hinst = GetModuleHandle(NULL);
  std::wstring class_name(L"TestClass");

  WNDCLASS wc = {0};
  wc.lpfnWndProc = base::win::WrappedWindowProc<TestWindowProc>;
  wc.hInstance = hinst;
  wc.lpszClassName = class_name.c_str();
  RegisterClass(&wc);

  HWND window = CreateWindow(class_name.c_str(), 0, 0, 0, 0, 0, 0, HWND_MESSAGE,
                             0, hinst, 0);
  ASSERT_TRUE(window);

  // Before generating the exception we make sure that the filter will see it.
  TestWrappedExceptionFiter wrapper;
  base::win::WinProcExceptionFilter old_filter =
      base::win::SetWinProcExceptionFilter(TestWrappedExceptionFiter::Filter);

  SendMessage(window, kCrashMsg, 0, 0);
  EXPECT_TRUE(wrapper.called());

  base::win::SetWinProcExceptionFilter(old_filter);
}
