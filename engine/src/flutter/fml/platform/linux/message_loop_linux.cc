// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/linux/message_loop_linux.h"

#include <sys/epoll.h>
#include <unistd.h>

#include "flutter/fml/platform/linux/timerfd.h"
#include "lib/fxl/files/eintr_wrapper.h"

namespace fml {

static constexpr int kClockType = CLOCK_MONOTONIC;

MessageLoopLinux::MessageLoopLinux()
    : epoll_fd_(HANDLE_EINTR(::epoll_create(1 /* unused */))),
      timer_fd_(::timerfd_create(kClockType, TFD_NONBLOCK | TFD_CLOEXEC)),
      running_(false) {
  FXL_CHECK(epoll_fd_.is_valid());
  FXL_CHECK(timer_fd_.is_valid());
  bool added_source = AddOrRemoveTimerSource(true);
  FXL_CHECK(added_source);
}

MessageLoopLinux::~MessageLoopLinux() {
  bool removed_source = AddOrRemoveTimerSource(false);
  FXL_CHECK(removed_source);
}

bool MessageLoopLinux::AddOrRemoveTimerSource(bool add) {
  struct epoll_event event = {};

  event.events = EPOLLIN;
  // The data is just for informational purposes so we know when we were worken
  // by the FD.
  event.data.fd = timer_fd_.get();

  int ctl_result =
      ::epoll_ctl(epoll_fd_.get(), add ? EPOLL_CTL_ADD : EPOLL_CTL_DEL,
                  timer_fd_.get(), &event);
  return ctl_result == 0;
}

void MessageLoopLinux::Run() {
  running_ = true;

  while (running_) {
    struct epoll_event event = {};

    int epoll_result = HANDLE_EINTR(
        ::epoll_wait(epoll_fd_.get(), &event, 1, -1 /* timeout */));

    // Errors are fatal.
    if (event.events & (EPOLLERR | EPOLLHUP)) {
      running_ = false;
      continue;
    }

    // Timeouts are fatal since we specified an infinite timeout already.
    // Likewise, > 1 is not possible since we waited for one result.
    if (epoll_result != 1) {
      running_ = false;
      continue;
    }

    if (event.data.fd == timer_fd_.get()) {
      OnEventFired();
    }
  }
}

void MessageLoopLinux::Terminate() {
  running_ = false;
  WakeUp(fxl::TimePoint::Now());
}

void MessageLoopLinux::WakeUp(fxl::TimePoint time_point) {
  bool result = TimerRearm(timer_fd_.get(), time_point);
  FXL_DCHECK(result);
}

void MessageLoopLinux::OnEventFired() {
  if (TimerDrain(timer_fd_.get())) {
    RunExpiredTasksNow();
  }
}

}  // namespace fml
