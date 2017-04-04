// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/win/message_loop_win.h"

namespace fml {

MessageLoopWin::MessageLoopWin()
    : timer_(CreateWaitableTimer(NULL, FALSE, NULL)) {
  FTL_CHECK(timer_.is_valid());
}

MessageLoopWin::~MessageLoopWin() = default;

void MessageLoopWin::Run() {
  running_ = true;

  while (running_) {
    FTL_CHECK(WaitForSingleObject(timer_.get(), INFINITE) == 0);
    RunExpiredTasksNow();
  }
}

void MessageLoopWin::Terminate() {
  running_ = false;
  WakeUp(ftl::TimePoint::Now());
}

void MessageLoopWin::WakeUp(ftl::TimePoint time_point) {
  LARGE_INTEGER due_time = {0};
  ftl::TimePoint now = ftl::TimePoint::Now();
  if (time_point > now) {
    due_time.QuadPart = (time_point - now).ToNanoseconds() / -100;
  }
  FTL_CHECK(SetWaitableTimer(timer_.get(), &due_time, 0, NULL, NULL, FALSE));
}

}  // namespace fml
