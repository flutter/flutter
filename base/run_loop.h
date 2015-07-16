// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_RUN_LOOP_H_
#define BASE_RUN_LOOP_H_

#include "base/base_export.h"
#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "base/message_loop/message_loop.h"

namespace base {
#if defined(OS_ANDROID)
class MessagePumpForUI;
#endif

#if defined(OS_WIN)
class MessagePumpDispatcher;
#endif

#if defined(OS_IOS)
class MessagePumpUIApplication;
#endif

// Helper class to Run a nested MessageLoop. Please do not use nested
// MessageLoops in production code! If you must, use this class instead of
// calling MessageLoop::Run/Quit directly. RunLoop::Run can only be called once
// per RunLoop lifetime. Create a RunLoop on the stack and call Run/Quit to run
// a nested MessageLoop.
class BASE_EXPORT RunLoop {
 public:
  RunLoop();
#if defined(OS_WIN)
  explicit RunLoop(MessagePumpDispatcher* dispatcher);
#endif
  ~RunLoop();

  // Run the current MessageLoop. This blocks until Quit is called. Before
  // calling Run, be sure to grab an AsWeakPtr or the QuitClosure in order to
  // stop the MessageLoop asynchronously. MessageLoop::Quit and QuitNow will
  // also trigger a return from Run, but those are deprecated.
  void Run();

  // Run the current MessageLoop until it doesn't find any tasks or messages in
  // the queue (it goes idle). WARNING: This may never return! Only use this
  // when repeating tasks such as animated web pages have been shut down.
  void RunUntilIdle();

  bool running() const { return running_; }

  // Quit an earlier call to Run(). There can be other nested RunLoops servicing
  // the same task queue (MessageLoop); Quitting one RunLoop has no bearing on
  // the others. Quit can be called before, during or after Run. If called
  // before Run, Run will return immediately when called. Calling Quit after the
  // RunLoop has already finished running has no effect.
  //
  // WARNING: You must NEVER assume that a call to Quit will terminate the
  // targetted message loop. If a nested message loop continues running, the
  // target may NEVER terminate. It is very easy to livelock (run forever) in
  // such a case.
  void Quit();

  // Convenience method to get a closure that safely calls Quit (has no effect
  // if the RunLoop instance is gone).
  //
  // Example:
  //   RunLoop run_loop;
  //   PostTask(run_loop.QuitClosure());
  //   run_loop.Run();
  base::Closure QuitClosure();

 private:
  friend class MessageLoop;
#if defined(OS_ANDROID)
  // Android doesn't support the blocking MessageLoop::Run, so it calls
  // BeforeRun and AfterRun directly.
  friend class base::MessagePumpForUI;
#endif

#if defined(OS_IOS)
  // iOS doesn't support the blocking MessageLoop::Run, so it calls
  // BeforeRun directly.
  friend class base::MessagePumpUIApplication;
#endif

  // Return false to abort the Run.
  bool BeforeRun();
  void AfterRun();

  MessageLoop* loop_;

  // Parent RunLoop or NULL if this is the top-most RunLoop.
  RunLoop* previous_run_loop_;

#if defined(OS_WIN)
  MessagePumpDispatcher* dispatcher_;
#endif

  // Used to count how many nested Run() invocations are on the stack.
  int run_depth_;

  bool run_called_;
  bool quit_called_;
  bool running_;

  // Used to record that QuitWhenIdle() was called on the MessageLoop, meaning
  // that we should quit Run once it becomes idle.
  bool quit_when_idle_received_;

  // WeakPtrFactory for QuitClosure safety.
  base::WeakPtrFactory<RunLoop> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(RunLoop);
};

}  // namespace base

#endif  // BASE_RUN_LOOP_H_
