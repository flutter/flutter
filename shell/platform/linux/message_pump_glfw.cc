// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/message_pump_glfw.h"

#include <GLFW/glfw3.h>

#include "base/auto_reset.h"
#include "base/logging.h"
#include "base/time/time.h"

namespace shell {

MessagePumpGLFW::MessagePumpGLFW() : in_run_(false), should_quit_(false) {}

MessagePumpGLFW::~MessagePumpGLFW() = default;

scoped_ptr<base::MessagePump> MessagePumpGLFW::Create() {
  return scoped_ptr<MessagePump>(new MessagePumpGLFW());
}

void MessagePumpGLFW::Run(Delegate* delegate) {
  base::AutoReset<bool> auto_reset_keep_running(&should_quit_, false);
  base::AutoReset<bool> auto_reset_in_run(&in_run_, true);

  for (;;) {
    bool did_work = delegate->DoWork();
    if (should_quit_)
      break;

    did_work |= delegate->DoDelayedWork(&delayed_work_time_);
    if (should_quit_)
      break;

    if (did_work)
      continue;

    did_work = delegate->DoIdleWork();
    if (should_quit_)
      break;

    if (did_work)
      continue;

    if (delayed_work_time_.is_null()) {
      glfwWaitEvents();
    } else {
      base::TimeDelta delay = delayed_work_time_ - base::TimeTicks::Now();
      if (delay > base::TimeDelta()) {
        glfwWaitEventsTimeout(delay.InSecondsF());
      } else {
        // It looks like delayed_work_time_ indicates a time in the past, so we
        // need to call DoDelayedWork now.
        delayed_work_time_ = base::TimeTicks();
      }
    }

    if (should_quit_)
      break;
  }
}

void MessagePumpGLFW::Quit() {
  DCHECK(in_run_) << "Quit was called outside of Run!";
  should_quit_ = true;
  ScheduleWork();
}

void MessagePumpGLFW::ScheduleWork() {
  glfwPostEmptyEvent();
}

void MessagePumpGLFW::ScheduleDelayedWork(
    const base::TimeTicks& delayed_work_time) {
  // We know that we can't be blocked on Wait right now since this method can
  // only be called on the same thread as Run, so we only need to update our
  // record of how long to sleep when we do sleep.
  delayed_work_time_ = delayed_work_time;
}

}  // namespace shell
