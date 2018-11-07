// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/win/message_loop_win.h"

#include "flutter/fml/logging.h"

namespace fml {

MessageLoopWin::MessageLoopWin()
    : timer_(CreateWaitableTimer(NULL, FALSE, NULL)) {
  FML_CHECK(timer_.is_valid());
}

MessageLoopWin::~MessageLoopWin() = default;

void MessageLoopWin::Run() {
  running_ = true;

  while (running_) {
    FML_CHECK(WaitForSingleObject(timer_.get(), INFINITE) == 0);
    RunExpiredTasksNow();
  }
}

void MessageLoopWin::Terminate() {
  running_ = false;
  WakeUp(fml::TimePoint::Now());
}

void MessageLoopWin::WakeUp(fml::TimePoint time_point) {
  LARGE_INTEGER due_time = {0};
  fml::TimePoint now = fml::TimePoint::Now();
  if (time_point > now) {
    due_time.QuadPart = (time_point - now).ToNanoseconds() / -100;
  }
  FML_CHECK(SetWaitableTimer(timer_.get(), &due_time, 0, NULL, NULL, FALSE));
}

}  // namespace fml
