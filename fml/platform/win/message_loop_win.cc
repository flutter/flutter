// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/win/message_loop_win.h"

namespace fml {

MessageLoopWin::MessageLoopWin()
    : timer_(CreateWaitableTimer(NULL, FALSE, NULL)) {
  FXL_CHECK(timer_.is_valid());
}

MessageLoopWin::~MessageLoopWin() = default;

void MessageLoopWin::Run() {
  running_ = true;

  while (running_) {
    FXL_CHECK(WaitForSingleObject(timer_.get(), INFINITE) == 0);
    RunExpiredTasksNow();
  }
}

void MessageLoopWin::Terminate() {
  running_ = false;
  WakeUp(fxl::TimePoint::Now());
}

void MessageLoopWin::WakeUp(fxl::TimePoint time_point) {
  LARGE_INTEGER due_time = {0};
  fxl::TimePoint now = fxl::TimePoint::Now();
  if (time_point > now) {
    due_time.QuadPart = (time_point - now).ToNanoseconds() / -100;
  }
  FXL_CHECK(SetWaitableTimer(timer_.get(), &due_time, 0, NULL, NULL, FALSE));
}

}  // namespace fml
