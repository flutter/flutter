// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_glib.h"

#include <fcntl.h>
#include <math.h>

#include <glib.h>

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "base/synchronization/lock.h"
#include "base/threading/platform_thread.h"

namespace base {

namespace {

// Return a timeout suitable for the glib loop, -1 to block forever,
// 0 to return right away, or a timeout in milliseconds from now.
int GetTimeIntervalMilliseconds(const TimeTicks& from) {
  if (from.is_null())
    return -1;

  // Be careful here.  TimeDelta has a precision of microseconds, but we want a
  // value in milliseconds.  If there are 5.5ms left, should the delay be 5 or
  // 6?  It should be 6 to avoid executing delayed work too early.
  int delay = static_cast<int>(
      ceil((from - TimeTicks::Now()).InMillisecondsF()));

  // If this value is negative, then we need to run delayed work soon.
  return delay < 0 ? 0 : delay;
}

// A brief refresher on GLib:
//     GLib sources have four callbacks: Prepare, Check, Dispatch and Finalize.
// On each iteration of the GLib pump, it calls each source's Prepare function.
// This function should return TRUE if it wants GLib to call its Dispatch, and
// FALSE otherwise.  It can also set a timeout in this case for the next time
// Prepare should be called again (it may be called sooner).
//     After the Prepare calls, GLib does a poll to check for events from the
// system.  File descriptors can be attached to the sources.  The poll may block
// if none of the Prepare calls returned TRUE.  It will block indefinitely, or
// by the minimum time returned by a source in Prepare.
//     After the poll, GLib calls Check for each source that returned FALSE
// from Prepare.  The return value of Check has the same meaning as for Prepare,
// making Check a second chance to tell GLib we are ready for Dispatch.
//     Finally, GLib calls Dispatch for each source that is ready.  If Dispatch
// returns FALSE, GLib will destroy the source.  Dispatch calls may be recursive
// (i.e., you can call Run from them), but Prepare and Check cannot.
//     Finalize is called when the source is destroyed.
// NOTE: It is common for subsytems to want to process pending events while
// doing intensive work, for example the flash plugin. They usually use the
// following pattern (recommended by the GTK docs):
// while (gtk_events_pending()) {
//   gtk_main_iteration();
// }
//
// gtk_events_pending just calls g_main_context_pending, which does the
// following:
// - Call prepare on all the sources.
// - Do the poll with a timeout of 0 (not blocking).
// - Call check on all the sources.
// - *Does not* call dispatch on the sources.
// - Return true if any of prepare() or check() returned true.
//
// gtk_main_iteration just calls g_main_context_iteration, which does the whole
// thing, respecting the timeout for the poll (and block, although it is
// expected not to if gtk_events_pending returned true), and call dispatch.
//
// Thus it is important to only return true from prepare or check if we
// actually have events or work to do. We also need to make sure we keep
// internal state consistent so that if prepare/check return true when called
// from gtk_events_pending, they will still return true when called right
// after, from gtk_main_iteration.
//
// For the GLib pump we try to follow the Windows UI pump model:
// - Whenever we receive a wakeup event or the timer for delayed work expires,
// we run DoWork and/or DoDelayedWork. That part will also run in the other
// event pumps.
// - We also run DoWork, DoDelayedWork, and possibly DoIdleWork in the main
// loop, around event handling.

struct WorkSource : public GSource {
  MessagePumpGlib* pump;
};

gboolean WorkSourcePrepare(GSource* source,
                           gint* timeout_ms) {
  *timeout_ms = static_cast<WorkSource*>(source)->pump->HandlePrepare();
  // We always return FALSE, so that our timeout is honored.  If we were
  // to return TRUE, the timeout would be considered to be 0 and the poll
  // would never block.  Once the poll is finished, Check will be called.
  return FALSE;
}

gboolean WorkSourceCheck(GSource* source) {
  // Only return TRUE if Dispatch should be called.
  return static_cast<WorkSource*>(source)->pump->HandleCheck();
}

gboolean WorkSourceDispatch(GSource* source,
                            GSourceFunc unused_func,
                            gpointer unused_data) {

  static_cast<WorkSource*>(source)->pump->HandleDispatch();
  // Always return TRUE so our source stays registered.
  return TRUE;
}

// I wish these could be const, but g_source_new wants non-const.
GSourceFuncs WorkSourceFuncs = {
  WorkSourcePrepare,
  WorkSourceCheck,
  WorkSourceDispatch,
  NULL
};

// The following is used to make sure we only run the MessagePumpGlib on one
// thread. X only has one message pump so we can only have one UI loop per
// process.
#ifndef NDEBUG

// Tracks the pump the most recent pump that has been run.
struct ThreadInfo {
  // The pump.
  MessagePumpGlib* pump;

  // ID of the thread the pump was run on.
  PlatformThreadId thread_id;
};

// Used for accesing |thread_info|.
static LazyInstance<Lock>::Leaky thread_info_lock = LAZY_INSTANCE_INITIALIZER;

// If non-NULL it means a MessagePumpGlib exists and has been Run. This is
// destroyed when the MessagePump is destroyed.
ThreadInfo* thread_info = NULL;

void CheckThread(MessagePumpGlib* pump) {
  AutoLock auto_lock(thread_info_lock.Get());
  if (!thread_info) {
    thread_info = new ThreadInfo;
    thread_info->pump = pump;
    thread_info->thread_id = PlatformThread::CurrentId();
  }
  DCHECK(thread_info->thread_id == PlatformThread::CurrentId()) <<
      "Running MessagePumpGlib on two different threads; "
      "this is unsupported by GLib!";
}

void PumpDestroyed(MessagePumpGlib* pump) {
  AutoLock auto_lock(thread_info_lock.Get());
  if (thread_info && thread_info->pump == pump) {
    delete thread_info;
    thread_info = NULL;
  }
}

#endif

}  // namespace

struct MessagePumpGlib::RunState {
  Delegate* delegate;

  // Used to flag that the current Run() invocation should return ASAP.
  bool should_quit;

  // Used to count how many Run() invocations are on the stack.
  int run_depth;

  // This keeps the state of whether the pump got signaled that there was new
  // work to be done. Since we eat the message on the wake up pipe as soon as
  // we get it, we keep that state here to stay consistent.
  bool has_work;
};

MessagePumpGlib::MessagePumpGlib()
    : state_(NULL),
      context_(g_main_context_default()),
      wakeup_gpollfd_(new GPollFD) {
  // Create our wakeup pipe, which is used to flag when work was scheduled.
  int fds[2];
  int ret = pipe(fds);
  DCHECK_EQ(ret, 0);
  (void)ret;  // Prevent warning in release mode.

  wakeup_pipe_read_  = fds[0];
  wakeup_pipe_write_ = fds[1];
  wakeup_gpollfd_->fd = wakeup_pipe_read_;
  wakeup_gpollfd_->events = G_IO_IN;

  work_source_ = g_source_new(&WorkSourceFuncs, sizeof(WorkSource));
  static_cast<WorkSource*>(work_source_)->pump = this;
  g_source_add_poll(work_source_, wakeup_gpollfd_.get());
  // Use a low priority so that we let other events in the queue go first.
  g_source_set_priority(work_source_, G_PRIORITY_DEFAULT_IDLE);
  // This is needed to allow Run calls inside Dispatch.
  g_source_set_can_recurse(work_source_, TRUE);
  g_source_attach(work_source_, context_);
}

MessagePumpGlib::~MessagePumpGlib() {
#ifndef NDEBUG
  PumpDestroyed(this);
#endif
  g_source_destroy(work_source_);
  g_source_unref(work_source_);
  close(wakeup_pipe_read_);
  close(wakeup_pipe_write_);
}

// Return the timeout we want passed to poll.
int MessagePumpGlib::HandlePrepare() {
  // We know we have work, but we haven't called HandleDispatch yet. Don't let
  // the pump block so that we can do some processing.
  if (state_ &&  // state_ may be null during tests.
      state_->has_work)
    return 0;

  // We don't think we have work to do, but make sure not to block
  // longer than the next time we need to run delayed work.
  return GetTimeIntervalMilliseconds(delayed_work_time_);
}

bool MessagePumpGlib::HandleCheck() {
  if (!state_)  // state_ may be null during tests.
    return false;

  // We usually have a single message on the wakeup pipe, since we are only
  // signaled when the queue went from empty to non-empty, but there can be
  // two messages if a task posted a task, hence we read at most two bytes.
  // The glib poll will tell us whether there was data, so this read
  // shouldn't block.
  if (wakeup_gpollfd_->revents & G_IO_IN) {
    char msg[2];
    const int num_bytes = HANDLE_EINTR(read(wakeup_pipe_read_, msg, 2));
    if (num_bytes < 1) {
      NOTREACHED() << "Error reading from the wakeup pipe.";
    }
    DCHECK((num_bytes == 1 && msg[0] == '!') ||
           (num_bytes == 2 && msg[0] == '!' && msg[1] == '!'));
    // Since we ate the message, we need to record that we have more work,
    // because HandleCheck() may be called without HandleDispatch being called
    // afterwards.
    state_->has_work = true;
  }

  if (state_->has_work)
    return true;

  if (GetTimeIntervalMilliseconds(delayed_work_time_) == 0) {
    // The timer has expired. That condition will stay true until we process
    // that delayed work, so we don't need to record this differently.
    return true;
  }

  return false;
}

void MessagePumpGlib::HandleDispatch() {
  state_->has_work = false;
  if (state_->delegate->DoWork()) {
    // NOTE: on Windows at this point we would call ScheduleWork (see
    // MessagePumpGlib::HandleWorkMessage in message_pump_win.cc). But here,
    // instead of posting a message on the wakeup pipe, we can avoid the
    // syscalls and just signal that we have more work.
    state_->has_work = true;
  }

  if (state_->should_quit)
    return;

  state_->delegate->DoDelayedWork(&delayed_work_time_);
}

void MessagePumpGlib::Run(Delegate* delegate) {
#ifndef NDEBUG
  CheckThread(this);
#endif

  RunState state;
  state.delegate = delegate;
  state.should_quit = false;
  state.run_depth = state_ ? state_->run_depth + 1 : 1;
  state.has_work = false;

  RunState* previous_state = state_;
  state_ = &state;

  // We really only do a single task for each iteration of the loop.  If we
  // have done something, assume there is likely something more to do.  This
  // will mean that we don't block on the message pump until there was nothing
  // more to do.  We also set this to true to make sure not to block on the
  // first iteration of the loop, so RunUntilIdle() works correctly.
  bool more_work_is_plausible = true;

  // We run our own loop instead of using g_main_loop_quit in one of the
  // callbacks.  This is so we only quit our own loops, and we don't quit
  // nested loops run by others.  TODO(deanm): Is this what we want?
  for (;;) {
    // Don't block if we think we have more work to do.
    bool block = !more_work_is_plausible;

    more_work_is_plausible = g_main_context_iteration(context_, block);
    if (state_->should_quit)
      break;

    more_work_is_plausible |= state_->delegate->DoWork();
    if (state_->should_quit)
      break;

    more_work_is_plausible |=
        state_->delegate->DoDelayedWork(&delayed_work_time_);
    if (state_->should_quit)
      break;

    if (more_work_is_plausible)
      continue;

    more_work_is_plausible = state_->delegate->DoIdleWork();
    if (state_->should_quit)
      break;
  }

  state_ = previous_state;
}

void MessagePumpGlib::Quit() {
  if (state_) {
    state_->should_quit = true;
  } else {
    NOTREACHED() << "Quit called outside Run!";
  }
}

void MessagePumpGlib::ScheduleWork() {
  // This can be called on any thread, so we don't want to touch any state
  // variables as we would then need locks all over.  This ensures that if
  // we are sleeping in a poll that we will wake up.
  char msg = '!';
  if (HANDLE_EINTR(write(wakeup_pipe_write_, &msg, 1)) != 1) {
    NOTREACHED() << "Could not write to the UI message loop wakeup pipe!";
  }
}

void MessagePumpGlib::ScheduleDelayedWork(const TimeTicks& delayed_work_time) {
  // We need to wake up the loop in case the poll timeout needs to be
  // adjusted.  This will cause us to try to do work, but that's ok.
  delayed_work_time_ = delayed_work_time;
  ScheduleWork();
}

bool MessagePumpGlib::ShouldQuit() const {
  CHECK(state_);
  return state_->should_quit;
}

}  // namespace base
