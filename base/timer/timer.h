// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// OneShotTimer and RepeatingTimer provide a simple timer API.  As the names
// suggest, OneShotTimer calls you back once after a time delay expires.
// RepeatingTimer on the other hand calls you back periodically with the
// prescribed time interval.
//
// OneShotTimer and RepeatingTimer both cancel the timer when they go out of
// scope, which makes it easy to ensure that you do not get called when your
// object has gone out of scope.  Just instantiate a OneShotTimer or
// RepeatingTimer as a member variable of the class for which you wish to
// receive timer events.
//
// Sample RepeatingTimer usage:
//
//   class MyClass {
//    public:
//     void StartDoingStuff() {
//       timer_.Start(FROM_HERE, TimeDelta::FromSeconds(1),
//                    this, &MyClass::DoStuff);
//     }
//     void StopDoingStuff() {
//       timer_.Stop();
//     }
//    private:
//     void DoStuff() {
//       // This method is called every second to do stuff.
//       ...
//     }
//     base::RepeatingTimer<MyClass> timer_;
//   };
//
// Both OneShotTimer and RepeatingTimer also support a Reset method, which
// allows you to easily defer the timer event until the timer delay passes once
// again.  So, in the above example, if 0.5 seconds have already passed,
// calling Reset on timer_ would postpone DoStuff by another 1 second.  In
// other words, Reset is shorthand for calling Stop and then Start again with
// the same arguments.
//
// NOTE: These APIs are not thread safe. Always call from the same thread.

#ifndef BASE_TIMER_TIMER_H_
#define BASE_TIMER_TIMER_H_

// IMPORTANT: If you change timer code, make sure that all tests (including
// disabled ones) from timer_unittests.cc pass locally. Some are disabled
// because they're flaky on the buildbot, but when you run them locally you
// should be able to tell the difference.

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/callback.h"
#include "base/location.h"
#include "base/time/time.h"

namespace base {

class BaseTimerTaskInternal;
class SingleThreadTaskRunner;

//-----------------------------------------------------------------------------
// This class wraps MessageLoop::PostDelayedTask to manage delayed and repeating
// tasks. It must be destructed on the same thread that starts tasks. There are
// DCHECKs in place to verify this.
//
class BASE_EXPORT Timer {
 public:
  // Construct a timer in repeating or one-shot mode. Start or SetTaskInfo must
  // be called later to set task info. |retain_user_task| determines whether the
  // user_task is retained or reset when it runs or stops.
  Timer(bool retain_user_task, bool is_repeating);

  // Construct a timer with retained task info.
  Timer(const tracked_objects::Location& posted_from,
        TimeDelta delay,
        const base::Closure& user_task,
        bool is_repeating);

  virtual ~Timer();

  // Returns true if the timer is running (i.e., not stopped).
  virtual bool IsRunning() const;

  // Returns the current delay for this timer.
  virtual TimeDelta GetCurrentDelay() const;

  // Set the task runner on which the task should be scheduled. This method can
  // only be called before any tasks have been scheduled. The task runner must
  // run tasks on the same thread the timer is used on.
  virtual void SetTaskRunner(scoped_refptr<SingleThreadTaskRunner> task_runner);

  // Start the timer to run at the given |delay| from now. If the timer is
  // already running, it will be replaced to call the given |user_task|.
  virtual void Start(const tracked_objects::Location& posted_from,
                     TimeDelta delay,
                     const base::Closure& user_task);

  // Call this method to stop and cancel the timer.  It is a no-op if the timer
  // is not running.
  virtual void Stop();

  // Call this method to reset the timer delay. The user_task_ must be set. If
  // the timer is not running, this will start it by posting a task.
  virtual void Reset();

  const base::Closure& user_task() const { return user_task_; }
  const TimeTicks& desired_run_time() const { return desired_run_time_; }

 protected:
  // Used to initiate a new delayed task.  This has the side-effect of disabling
  // scheduled_task_ if it is non-null.
  void SetTaskInfo(const tracked_objects::Location& posted_from,
                   TimeDelta delay,
                   const base::Closure& user_task);

  void set_user_task(const Closure& task) { user_task_ = task; }
  void set_desired_run_time(TimeTicks desired) { desired_run_time_ = desired; }
  void set_is_running(bool running) { is_running_ = running; }

  const tracked_objects::Location& posted_from() const { return posted_from_; }
  bool retain_user_task() const { return retain_user_task_; }
  bool is_repeating() const { return is_repeating_; }
  bool is_running() const { return is_running_; }

 private:
  friend class BaseTimerTaskInternal;

  // Allocates a new scheduled_task_ and posts it on the current MessageLoop
  // with the given |delay|. scheduled_task_ must be NULL. scheduled_run_time_
  // and desired_run_time_ are reset to Now() + delay.
  void PostNewScheduledTask(TimeDelta delay);

  // Returns the task runner on which the task should be scheduled. If the
  // corresponding task_runner_ field is null, the task runner for the current
  // thread is returned.
  scoped_refptr<SingleThreadTaskRunner> GetTaskRunner();

  // Disable scheduled_task_ and abandon it so that it no longer refers back to
  // this object.
  void AbandonScheduledTask();

  // Called by BaseTimerTaskInternal when the MessageLoop runs it.
  void RunScheduledTask();

  // Stop running task (if any) and abandon scheduled task (if any).
  void StopAndAbandon() {
    Stop();
    AbandonScheduledTask();
  }

  // When non-NULL, the scheduled_task_ is waiting in the MessageLoop to call
  // RunScheduledTask() at scheduled_run_time_.
  BaseTimerTaskInternal* scheduled_task_;

  // The task runner on which the task should be scheduled. If it is null, the
  // task runner for the current thread should be used.
  scoped_refptr<SingleThreadTaskRunner> task_runner_;

  // Location in user code.
  tracked_objects::Location posted_from_;
  // Delay requested by user.
  TimeDelta delay_;
  // user_task_ is what the user wants to be run at desired_run_time_.
  base::Closure user_task_;

  // The estimated time that the MessageLoop will run the scheduled_task_ that
  // will call RunScheduledTask(). This time can be a "zero" TimeTicks if the
  // task must be run immediately.
  TimeTicks scheduled_run_time_;

  // The desired run time of user_task_. The user may update this at any time,
  // even if their previous request has not run yet. If desired_run_time_ is
  // greater than scheduled_run_time_, a continuation task will be posted to
  // wait for the remaining time. This allows us to reuse the pending task so as
  // not to flood the MessageLoop with orphaned tasks when the user code
  // excessively Stops and Starts the timer. This time can be a "zero" TimeTicks
  // if the task must be run immediately.
  TimeTicks desired_run_time_;

  // Thread ID of current MessageLoop for verifying single-threaded usage.
  int thread_id_;

  // Repeating timers automatically post the task again before calling the task
  // callback.
  const bool is_repeating_;

  // If true, hold on to the user_task_ closure object for reuse.
  const bool retain_user_task_;

  // If true, user_task_ is scheduled to run sometime in the future.
  bool is_running_;

  DISALLOW_COPY_AND_ASSIGN(Timer);
};

//-----------------------------------------------------------------------------
// This class is an implementation detail of OneShotTimer and RepeatingTimer.
// Please do not use this class directly.
template <class Receiver, bool kIsRepeating>
class BaseTimerMethodPointer : public Timer {
 public:
  typedef void (Receiver::*ReceiverMethod)();

  // This is here to work around the fact that Timer::Start is "hidden" by the
  // Start definition below, rather than being overloaded.
  // TODO(tim): We should remove uses of BaseTimerMethodPointer::Start below
  // and convert callers to use the base::Closure version in Timer::Start,
  // see bug 148832.
  using Timer::Start;

  BaseTimerMethodPointer() : Timer(kIsRepeating, kIsRepeating) {}

  // Start the timer to run at the given |delay| from now. If the timer is
  // already running, it will be replaced to call a task formed from
  // |reviewer->*method|.
  virtual void Start(const tracked_objects::Location& posted_from,
                     TimeDelta delay,
                     Receiver* receiver,
                     ReceiverMethod method) {
    Timer::Start(posted_from, delay,
                 base::Bind(method, base::Unretained(receiver)));
  }
};

//-----------------------------------------------------------------------------
// A simple, one-shot timer.  See usage notes at the top of the file.
template <class Receiver>
class OneShotTimer : public BaseTimerMethodPointer<Receiver, false> {};

//-----------------------------------------------------------------------------
// A simple, repeating timer.  See usage notes at the top of the file.
template <class Receiver>
class RepeatingTimer : public BaseTimerMethodPointer<Receiver, true> {};

//-----------------------------------------------------------------------------
// A Delay timer is like The Button from Lost. Once started, you have to keep
// calling Reset otherwise it will call the given method in the MessageLoop
// thread.
//
// Once created, it is inactive until Reset is called. Once |delay| seconds have
// passed since the last call to Reset, the callback is made. Once the callback
// has been made, it's inactive until Reset is called again.
//
// If destroyed, the timeout is canceled and will not occur even if already
// inflight.
template <class Receiver>
class DelayTimer : protected Timer {
 public:
  typedef void (Receiver::*ReceiverMethod)();

  DelayTimer(const tracked_objects::Location& posted_from,
             TimeDelta delay,
             Receiver* receiver,
             ReceiverMethod method)
      : Timer(posted_from, delay,
              base::Bind(method, base::Unretained(receiver)),
              false) {}

  void Reset() override { Timer::Reset(); }
};

}  // namespace base

#endif  // BASE_TIMER_TIMER_H_
