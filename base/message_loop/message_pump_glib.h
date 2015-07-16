// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_PUMP_GLIB_H_
#define BASE_MESSAGE_LOOP_MESSAGE_PUMP_GLIB_H_

#include "base/base_export.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_pump.h"
#include "base/observer_list.h"
#include "base/time/time.h"

typedef struct _GMainContext GMainContext;
typedef struct _GPollFD GPollFD;
typedef struct _GSource GSource;

namespace base {

// This class implements a base MessagePump needed for TYPE_UI MessageLoops on
// platforms using GLib.
class BASE_EXPORT MessagePumpGlib : public MessagePump {
 public:
  MessagePumpGlib();
  ~MessagePumpGlib() override;

  // Internal methods used for processing the pump callbacks.  They are
  // public for simplicity but should not be used directly.  HandlePrepare
  // is called during the prepare step of glib, and returns a timeout that
  // will be passed to the poll. HandleCheck is called after the poll
  // has completed, and returns whether or not HandleDispatch should be called.
  // HandleDispatch is called if HandleCheck returned true.
  int HandlePrepare();
  bool HandleCheck();
  void HandleDispatch();

  // Overridden from MessagePump:
  void Run(Delegate* delegate) override;
  void Quit() override;
  void ScheduleWork() override;
  void ScheduleDelayedWork(const TimeTicks& delayed_work_time) override;

 private:
  bool ShouldQuit() const;

  // We may make recursive calls to Run, so we save state that needs to be
  // separate between them in this structure type.
  struct RunState;

  RunState* state_;

  // This is a GLib structure that we can add event sources to.  We use the
  // default GLib context, which is the one to which all GTK events are
  // dispatched.
  GMainContext* context_;

  // This is the time when we need to do delayed work.
  TimeTicks delayed_work_time_;

  // The work source.  It is shared by all calls to Run and destroyed when
  // the message pump is destroyed.
  GSource* work_source_;

  // We use a wakeup pipe to make sure we'll get out of the glib polling phase
  // when another thread has scheduled us to do some work.  There is a glib
  // mechanism g_main_context_wakeup, but this won't guarantee that our event's
  // Dispatch() will be called.
  int wakeup_pipe_read_;
  int wakeup_pipe_write_;
  // Use a scoped_ptr to avoid needing the definition of GPollFD in the header.
  scoped_ptr<GPollFD> wakeup_gpollfd_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpGlib);
};

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_PUMP_GLIB_H_
