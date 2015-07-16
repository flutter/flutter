// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_UTILITY_RUN_LOOP_H_
#define MOJO_PUBLIC_CPP_UTILITY_RUN_LOOP_H_

#include <map>
#include <queue>

#include "mojo/public/cpp/bindings/callback.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {

class RunLoopHandler;

// Watches handles for signals and calls event handlers when they occur. Also
// executes delayed tasks. This class should only be used by a single thread.
class RunLoop {
 public:
  RunLoop();
  ~RunLoop();

  // Sets up state needed for RunLoop. This must be invoked before creating a
  // RunLoop.
  static void SetUp();

  // Cleans state created by Setup().
  static void TearDown();

  // Returns the RunLoop for the current thread. Returns null if not yet
  // created.
  static RunLoop* current();

  // Registers a RunLoopHandler for the specified handle. It is an error to
  // register more than one handler for a handle, and crashes the process.
  //
  // The handler's OnHandleReady() method is invoked after one of the signals in
  // |handle_signals| occurs. Note that the handler remains registered until
  // explicitly removed or an error occurs.
  //
  // The handler's OnHandleError() method is invoked if the deadline elapses, an
  // error is detected, or the RunLoop is being destroyed. The handler is
  // automatically unregistered before calling OnHandleError(), so it will not
  // receive any further notifications.
  void AddHandler(RunLoopHandler* handler,
                  const Handle& handle,
                  MojoHandleSignals handle_signals,
                  MojoDeadline deadline);
  void RemoveHandler(const Handle& handle);
  bool HasHandler(const Handle& handle) const;

  // Runs the loop servicing handles and tasks as they are ready. This returns
  // when Quit() is invoked, or there are no more handles nor tasks.
  void Run();

  // Runs the loop servicing any handles and tasks that are ready. Does not wait
  // for handles or tasks to become ready before returning. Returns early if
  // Quit() is invoked.
  void RunUntilIdle();

  void Quit();

  // Adds a task to be performed after delay has elapsed. Must be posted to the
  // current thread's RunLoop.
  void PostDelayedTask(const Closure& task, MojoTimeTicks delay);

 private:
  struct RunState;
  struct WaitState;

  // Contains the data needed to track a request to AddHandler().
  struct HandlerData {
    HandlerData()
        : handler(nullptr),
          handle_signals(MOJO_HANDLE_SIGNAL_NONE),
          deadline(0),
          id(0) {}

    RunLoopHandler* handler;
    MojoHandleSignals handle_signals;
    MojoTimeTicks deadline;
    // See description of |RunLoop::next_handler_id_| for details.
    int id;
  };

  typedef std::map<Handle, HandlerData> HandleToHandlerData;

  // Used for NotifyHandlers to specify whether HandlerData's |deadline|
  // should be checked prior to notifying.
  enum CheckDeadline { CHECK_DEADLINE, IGNORE_DEADLINE };

  // Mode of operation of the run loop.
  enum RunMode { UNTIL_EMPTY, UNTIL_IDLE };

  // Runs the loop servicing any handles and tasks that are ready. If
  // |run_mode| is |UNTIL_IDLE|, does not wait for handles or tasks to become
  // ready before returning. Returns early if Quit() is invoked.
  void RunInternal(RunMode run_mode);

  // Do one unit of delayed work, if eligible. Returns true is a task was run.
  bool DoDelayedWork();

  // Waits for a handle to be ready or until the next task must be run. Returns
  // after servicing at least one handle (or there are no more handles) unless
  // a task must be run or |non_blocking| is true, in which case it will also
  // return if no task is registered and servicing at least one handle would
  // require blocking. Returns true if a RunLoopHandler was notified.
  bool Wait(bool non_blocking);

  // Notifies handlers of |error|.  If |check| == CHECK_DEADLINE, this will
  // only notify handlers whose deadline has expired and skips the rest.
  // Returns true if a RunLoopHandler was notified.
  bool NotifyHandlers(MojoResult error, CheckDeadline check);

  // Returns the state needed to pass to WaitMany().
  WaitState GetWaitState(bool non_blocking) const;

  HandleToHandlerData handler_data_;

  // If non-null we're running (inside Run()). Member references a value on the
  // stack.
  RunState* run_state_;

  // An ever increasing value assigned to each HandlerData::id. Used to detect
  // uniqueness while notifying. That is, while notifying expired timers we copy
  // |handler_data_| and only notify handlers whose id match. If the id does not
  // match it means the handler was removed then added so that we shouldn't
  // notify it.
  int next_handler_id_;

  struct PendingTask {
    PendingTask(const Closure& task,
                MojoTimeTicks runtime,
                uint64_t sequence_number);
    ~PendingTask();

    bool operator<(const PendingTask& other) const;

    Closure task;
    MojoTimeTicks run_time;
    uint64_t sequence_number;
  };
  // An ever increasing sequence number attached to each pending task in order
  // to preserve relative order of tasks posted at the 'same' time.
  uint64_t next_sequence_number_;
  typedef std::priority_queue<PendingTask> DelayedTaskQueue;
  DelayedTaskQueue delayed_tasks_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(RunLoop);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_UTILITY_RUN_LOOP_H_
