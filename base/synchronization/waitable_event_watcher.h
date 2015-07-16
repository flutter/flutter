// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SYNCHRONIZATION_WAITABLE_EVENT_WATCHER_H_
#define BASE_SYNCHRONIZATION_WAITABLE_EVENT_WATCHER_H_

#include "base/base_export.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include "base/win/object_watcher.h"
#else
#include "base/callback.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/waitable_event.h"
#endif

namespace base {

class Flag;
class AsyncWaiter;
class AsyncCallbackTask;
class WaitableEvent;

// This class provides a way to wait on a WaitableEvent asynchronously.
//
// Each instance of this object can be waiting on a single WaitableEvent. When
// the waitable event is signaled, a callback is made in the thread of a given
// MessageLoop. This callback can be deleted by deleting the waiter.
//
// Typical usage:
//
//   class MyClass {
//    public:
//     void DoStuffWhenSignaled(WaitableEvent *waitable_event) {
//       watcher_.StartWatching(waitable_event,
//           base::Bind(&MyClass::OnWaitableEventSignaled, this);
//     }
//    private:
//     void OnWaitableEventSignaled(WaitableEvent* waitable_event) {
//       // OK, time to do stuff!
//     }
//     base::WaitableEventWatcher watcher_;
//   };
//
// In the above example, MyClass wants to "do stuff" when waitable_event
// becomes signaled. WaitableEventWatcher makes this task easy. When MyClass
// goes out of scope, the watcher_ will be destroyed, and there is no need to
// worry about OnWaitableEventSignaled being called on a deleted MyClass
// pointer.
//
// BEWARE: With automatically reset WaitableEvents, a signal may be lost if it
// occurs just before a WaitableEventWatcher is deleted. There is currently no
// safe way to stop watching an automatic reset WaitableEvent without possibly
// missing a signal.
//
// NOTE: you /are/ allowed to delete the WaitableEvent while still waiting on
// it with a Watcher. It will act as if the event was never signaled.

class BASE_EXPORT WaitableEventWatcher
#if defined(OS_WIN)
    : public win::ObjectWatcher::Delegate {
#else
    : public MessageLoop::DestructionObserver {
#endif
 public:
  typedef Callback<void(WaitableEvent*)> EventCallback;
  WaitableEventWatcher();
  ~WaitableEventWatcher() override;

  // When @event is signaled, the given callback is called on the thread of the
  // current message loop when StartWatching is called.
  bool StartWatching(WaitableEvent* event, const EventCallback& callback);

  // Cancel the current watch. Must be called from the same thread which
  // started the watch.
  //
  // Does nothing if no event is being watched, nor if the watch has completed.
  // The callback will *not* be called for the current watch after this
  // function returns. Since the callback runs on the same thread as this
  // function, it cannot be called during this function either.
  void StopWatching();

  // Return the currently watched event, or NULL if no object is currently being
  // watched.
  WaitableEvent* GetWatchedEvent();

  // Return the callback that will be invoked when the event is
  // signaled.
  const EventCallback& callback() const { return callback_; }

 private:
#if defined(OS_WIN)
  void OnObjectSignaled(HANDLE h) override;
  win::ObjectWatcher watcher_;
#else
  // Implementation of MessageLoop::DestructionObserver
  void WillDestroyCurrentMessageLoop() override;

  MessageLoop* message_loop_;
  scoped_refptr<Flag> cancel_flag_;
  AsyncWaiter* waiter_;
  base::Closure internal_callback_;
  scoped_refptr<WaitableEvent::WaitableEventKernel> kernel_;
#endif

  WaitableEvent* event_;
  EventCallback callback_;
};

}  // namespace base

#endif  // BASE_SYNCHRONIZATION_WAITABLE_EVENT_WATCHER_H_
