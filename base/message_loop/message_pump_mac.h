// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The basis for all native run loops on the Mac is the CFRunLoop.  It can be
// used directly, it can be used as the driving force behind the similar
// Foundation NSRunLoop, and it can be used to implement higher-level event
// loops such as the NSApplication event loop.
//
// This file introduces a basic CFRunLoop-based implementation of the
// MessagePump interface called CFRunLoopBase.  CFRunLoopBase contains all
// of the machinery necessary to dispatch events to a delegate, but does not
// implement the specific run loop.  Concrete subclasses must provide their
// own DoRun and Quit implementations.
//
// A concrete subclass that just runs a CFRunLoop loop is provided in
// MessagePumpCFRunLoop.  For an NSRunLoop, the similar MessagePumpNSRunLoop
// is provided.
//
// For the application's event loop, an implementation based on AppKit's
// NSApplication event system is provided in MessagePumpNSApplication.
//
// Typically, MessagePumpNSApplication only makes sense on a Cocoa
// application's main thread.  If a CFRunLoop-based message pump is needed on
// any other thread, one of the other concrete subclasses is preferrable.
// MessagePumpMac::Create is defined, which returns a new NSApplication-based
// or NSRunLoop-based MessagePump subclass depending on which thread it is
// called on.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_PUMP_MAC_H_
#define BASE_MESSAGE_LOOP_MESSAGE_PUMP_MAC_H_

#include "base/message_loop/message_pump.h"

#include "base/basictypes.h"

#include <CoreFoundation/CoreFoundation.h>

#include "base/memory/weak_ptr.h"
#include "base/message_loop/timer_slack.h"

#if defined(__OBJC__)
#if defined(OS_IOS)
#import <Foundation/Foundation.h>
#else
#import <AppKit/AppKit.h>

// Clients must subclass NSApplication and implement this protocol if they use
// MessagePumpMac.
@protocol CrAppProtocol
// Must return true if -[NSApplication sendEvent:] is currently on the stack.
// See the comment for |CreateAutoreleasePool()| in the cc file for why this is
// necessary.
- (BOOL)isHandlingSendEvent;
@end
#endif  // !defined(OS_IOS)
#endif  // defined(__OBJC__)

namespace base {

class RunLoop;
class TimeTicks;

// AutoreleasePoolType is a proxy type for autorelease pools. Its definition
// depends on the translation unit (TU) in which this header appears. In pure
// C++ TUs, it is defined as a forward C++ class declaration (that is never
// defined), because autorelease pools are an Objective-C concept. In Automatic
// Reference Counting (ARC) Objective-C TUs, it is similarly defined as a
// forward C++ class declaration, because clang will not allow the type
// "NSAutoreleasePool" in such TUs. Finally, in Manual Retain Release (MRR)
// Objective-C TUs, it is a type alias for NSAutoreleasePool. In all cases, a
// method that takes or returns an NSAutoreleasePool* can use
// AutoreleasePoolType* instead.
#if !defined(__OBJC__) || __has_feature(objc_arc)
class AutoreleasePoolType;
#else   // !defined(__OBJC__) || __has_feature(objc_arc)
typedef NSAutoreleasePool AutoreleasePoolType;
#endif  // !defined(__OBJC__) || __has_feature(objc_arc)

class MessagePumpCFRunLoopBase : public MessagePump {
  // Needs access to CreateAutoreleasePool.
  friend class MessagePumpScopedAutoreleasePool;
 public:
  MessagePumpCFRunLoopBase();
  ~MessagePumpCFRunLoopBase() override;

  // Subclasses should implement the work they need to do in MessagePump::Run
  // in the DoRun method.  MessagePumpCFRunLoopBase::Run calls DoRun directly.
  // This arrangement is used because MessagePumpCFRunLoopBase needs to set
  // up and tear down things before and after the "meat" of DoRun.
  void Run(Delegate* delegate) override;
  virtual void DoRun(Delegate* delegate) = 0;

  void ScheduleWork() override;
  void ScheduleDelayedWork(const TimeTicks& delayed_work_time) override;
  void SetTimerSlack(TimerSlack timer_slack) override;

 protected:
  // Accessors for private data members to be used by subclasses.
  CFRunLoopRef run_loop() const { return run_loop_; }
  int nesting_level() const { return nesting_level_; }
  int run_nesting_level() const { return run_nesting_level_; }

  // Sets this pump's delegate.  Signals the appropriate sources if
  // |delegateless_work_| is true.  |delegate| can be NULL.
  void SetDelegate(Delegate* delegate);

  // Return an autorelease pool to wrap around any work being performed.
  // In some cases, CreateAutoreleasePool may return nil intentionally to
  // preventing an autorelease pool from being created, allowing any
  // objects autoreleased by work to fall into the current autorelease pool.
  virtual AutoreleasePoolType* CreateAutoreleasePool();

 private:
  // Timer callback scheduled by ScheduleDelayedWork.  This does not do any
  // work, but it signals work_source_ so that delayed work can be performed
  // within the appropriate priority constraints.
  static void RunDelayedWorkTimer(CFRunLoopTimerRef timer, void* info);

  // Perform highest-priority work.  This is associated with work_source_
  // signalled by ScheduleWork or RunDelayedWorkTimer.  The static method calls
  // the instance method; the instance method returns true if it resignalled
  // work_source_ to be called again from the loop.
  static void RunWorkSource(void* info);
  bool RunWork();

  // Perform idle-priority work.  This is normally called by PreWaitObserver,
  // but is also associated with idle_work_source_.  When this function
  // actually does perform idle work, it will resignal that source.  The
  // static method calls the instance method; the instance method returns
  // true if idle work was done.
  static void RunIdleWorkSource(void* info);
  bool RunIdleWork();

  // Perform work that may have been deferred because it was not runnable
  // within a nested run loop.  This is associated with
  // nesting_deferred_work_source_ and is signalled by
  // MaybeScheduleNestingDeferredWork when returning from a nested loop,
  // so that an outer loop will be able to perform the necessary tasks if it
  // permits nestable tasks.
  static void RunNestingDeferredWorkSource(void* info);
  bool RunNestingDeferredWork();

  // Schedules possible nesting-deferred work to be processed before the run
  // loop goes to sleep, exits, or begins processing sources at the top of its
  // loop.  If this function detects that a nested loop had run since the
  // previous attempt to schedule nesting-deferred work, it will schedule a
  // call to RunNestingDeferredWorkSource.
  void MaybeScheduleNestingDeferredWork();

  // Observer callback responsible for performing idle-priority work, before
  // the run loop goes to sleep.  Associated with idle_work_observer_.
  static void PreWaitObserver(CFRunLoopObserverRef observer,
                              CFRunLoopActivity activity, void* info);

  // Observer callback called before the run loop processes any sources.
  // Associated with pre_source_observer_.
  static void PreSourceObserver(CFRunLoopObserverRef observer,
                                CFRunLoopActivity activity, void* info);

  // Observer callback called when the run loop starts and stops, at the
  // beginning and end of calls to CFRunLoopRun.  This is used to maintain
  // nesting_level_.  Associated with enter_exit_observer_.
  static void EnterExitObserver(CFRunLoopObserverRef observer,
                                CFRunLoopActivity activity, void* info);

  // Called by EnterExitObserver after performing maintenance on nesting_level_.
  // This allows subclasses an opportunity to perform additional processing on
  // the basis of run loops starting and stopping.
  virtual void EnterExitRunLoop(CFRunLoopActivity activity);

  // The thread's run loop.
  CFRunLoopRef run_loop_;

  // The timer, sources, and observers are described above alongside their
  // callbacks.
  CFRunLoopTimerRef delayed_work_timer_;
  CFRunLoopSourceRef work_source_;
  CFRunLoopSourceRef idle_work_source_;
  CFRunLoopSourceRef nesting_deferred_work_source_;
  CFRunLoopObserverRef pre_wait_observer_;
  CFRunLoopObserverRef pre_source_observer_;
  CFRunLoopObserverRef enter_exit_observer_;

  // (weak) Delegate passed as an argument to the innermost Run call.
  Delegate* delegate_;

  // The time that delayed_work_timer_ is scheduled to fire.  This is tracked
  // independently of CFRunLoopTimerGetNextFireDate(delayed_work_timer_)
  // to be able to reset the timer properly after waking from system sleep.
  // See PowerStateNotification.
  CFAbsoluteTime delayed_work_fire_time_;

  base::TimerSlack timer_slack_;

  // The recursion depth of the currently-executing CFRunLoopRun loop on the
  // run loop's thread.  0 if no run loops are running inside of whatever scope
  // the object was created in.
  int nesting_level_;

  // The recursion depth (calculated in the same way as nesting_level_) of the
  // innermost executing CFRunLoopRun loop started by a call to Run.
  int run_nesting_level_;

  // The deepest (numerically highest) recursion depth encountered since the
  // most recent attempt to run nesting-deferred work.
  int deepest_nesting_level_;

  // "Delegateless" work flags are set when work is ready to be performed but
  // must wait until a delegate is available to process it.  This can happen
  // when a MessagePumpCFRunLoopBase is instantiated and work arrives without
  // any call to Run on the stack.  The Run method will check for delegateless
  // work on entry and redispatch it as needed once a delegate is available.
  bool delegateless_work_;
  bool delegateless_idle_work_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpCFRunLoopBase);
};

class BASE_EXPORT MessagePumpCFRunLoop : public MessagePumpCFRunLoopBase {
 public:
  MessagePumpCFRunLoop();
  ~MessagePumpCFRunLoop() override;

  void DoRun(Delegate* delegate) override;
  void Quit() override;

 private:
  void EnterExitRunLoop(CFRunLoopActivity activity) override;

  // True if Quit is called to stop the innermost MessagePump
  // (innermost_quittable_) but some other CFRunLoopRun loop (nesting_level_)
  // is running inside the MessagePump's innermost Run call.
  bool quit_pending_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpCFRunLoop);
};

class BASE_EXPORT MessagePumpNSRunLoop : public MessagePumpCFRunLoopBase {
 public:
  MessagePumpNSRunLoop();
  ~MessagePumpNSRunLoop() override;

  void DoRun(Delegate* delegate) override;
  void Quit() override;

 private:
  // A source that doesn't do anything but provide something signalable
  // attached to the run loop.  This source will be signalled when Quit
  // is called, to cause the loop to wake up so that it can stop.
  CFRunLoopSourceRef quit_source_;

  // False after Quit is called.
  bool keep_running_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpNSRunLoop);
};

#if defined(OS_IOS)
// This is a fake message pump.  It attaches sources to the main thread's
// CFRunLoop, so PostTask() will work, but it is unable to drive the loop
// directly, so calling Run() or Quit() are errors.
class MessagePumpUIApplication : public MessagePumpCFRunLoopBase {
 public:
  MessagePumpUIApplication();
  ~MessagePumpUIApplication() override;
  void DoRun(Delegate* delegate) override;
  void Quit() override;

  // This message pump can not spin the main message loop directly.  Instead,
  // call |Attach()| to set up a delegate.  It is an error to call |Run()|.
  virtual void Attach(Delegate* delegate);

 private:
  RunLoop* run_loop_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpUIApplication);
};

#else

class MessagePumpNSApplication : public MessagePumpCFRunLoopBase {
 public:
  MessagePumpNSApplication();
  ~MessagePumpNSApplication() override;

  void DoRun(Delegate* delegate) override;
  void Quit() override;

 private:
  // False after Quit is called.
  bool keep_running_;

  // True if DoRun is managing its own run loop as opposed to letting
  // -[NSApplication run] handle it.  The outermost run loop in the application
  // is managed by -[NSApplication run], inner run loops are handled by a loop
  // in DoRun.
  bool running_own_loop_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpNSApplication);
};

class MessagePumpCrApplication : public MessagePumpNSApplication {
 public:
  MessagePumpCrApplication();
  ~MessagePumpCrApplication() override;

 protected:
  // Returns nil if NSApp is currently in the middle of calling
  // -sendEvent.  Requires NSApp implementing CrAppProtocol.
  AutoreleasePoolType* CreateAutoreleasePool() override;

 private:
  DISALLOW_COPY_AND_ASSIGN(MessagePumpCrApplication);
};
#endif  // !defined(OS_IOS)

class BASE_EXPORT MessagePumpMac {
 public:
  // If not on the main thread, returns a new instance of
  // MessagePumpNSRunLoop.
  //
  // On the main thread, if NSApp exists and conforms to
  // CrAppProtocol, creates an instances of MessagePumpCrApplication.
  //
  // Otherwise creates an instance of MessagePumpNSApplication using a
  // default NSApplication.
  static MessagePump* Create();

#if !defined(OS_IOS)
  // If a pump is created before the required CrAppProtocol is
  // created, the wrong MessagePump subclass could be used.
  // UsingCrApp() returns false if the message pump was created before
  // NSApp was initialized, or if NSApp does not implement
  // CrAppProtocol.  NSApp must be initialized before calling.
  static bool UsingCrApp();

  // Wrapper to query -[NSApp isHandlingSendEvent] from C++ code.
  // Requires NSApp to implement CrAppProtocol.
  static bool IsHandlingSendEvent();
#endif  // !defined(OS_IOS)

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(MessagePumpMac);
};

// Tasks posted to the message loop are posted under this mode, as well
// as kCFRunLoopCommonModes.
extern const CFStringRef BASE_EXPORT kMessageLoopExclusiveRunLoopMode;

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_PUMP_MAC_H_
