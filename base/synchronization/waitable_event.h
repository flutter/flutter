// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SYNCHRONIZATION_WAITABLE_EVENT_H_
#define BASE_SYNCHRONIZATION_WAITABLE_EVENT_H_

#include "base/base_export.h"
#include "base/basictypes.h"

#if defined(OS_WIN)
#include "base/win/scoped_handle.h"
#endif

#if defined(OS_POSIX)
#include <list>
#include <utility>
#include "base/memory/ref_counted.h"
#include "base/synchronization/lock.h"
#endif

namespace base {

class TimeDelta;

// A WaitableEvent can be a useful thread synchronization tool when you want to
// allow one thread to wait for another thread to finish some work. For
// non-Windows systems, this can only be used from within a single address
// space.
//
// Use a WaitableEvent when you would otherwise use a Lock+ConditionVariable to
// protect a simple boolean value.  However, if you find yourself using a
// WaitableEvent in conjunction with a Lock to wait for a more complex state
// change (e.g., for an item to be added to a queue), then you should probably
// be using a ConditionVariable instead of a WaitableEvent.
//
// NOTE: On Windows, this class provides a subset of the functionality afforded
// by a Windows event object.  This is intentional.  If you are writing Windows
// specific code and you need other features of a Windows event, then you might
// be better off just using an Windows event directly.
class BASE_EXPORT WaitableEvent {
 public:
  // If manual_reset is true, then to set the event state to non-signaled, a
  // consumer must call the Reset method.  If this parameter is false, then the
  // system automatically resets the event state to non-signaled after a single
  // waiting thread has been released.
  WaitableEvent(bool manual_reset, bool initially_signaled);

#if defined(OS_WIN)
  // Create a WaitableEvent from an Event HANDLE which has already been
  // created. This objects takes ownership of the HANDLE and will close it when
  // deleted.
  explicit WaitableEvent(win::ScopedHandle event_handle);
#endif

  ~WaitableEvent();

  // Put the event in the un-signaled state.
  void Reset();

  // Put the event in the signaled state.  Causing any thread blocked on Wait
  // to be woken up.
  void Signal();

  // Returns true if the event is in the signaled state, else false.  If this
  // is not a manual reset event, then this test will cause a reset.
  bool IsSignaled();

  // Wait indefinitely for the event to be signaled. Wait's return "happens
  // after" |Signal| has completed. This means that it's safe for a
  // WaitableEvent to synchronise its own destruction, like this:
  //
  //   WaitableEvent *e = new WaitableEvent;
  //   SendToOtherThread(e);
  //   e->Wait();
  //   delete e;
  void Wait();

  // Wait up until max_time has passed for the event to be signaled.  Returns
  // true if the event was signaled.  If this method returns false, then it
  // does not necessarily mean that max_time was exceeded.
  //
  // TimedWait can synchronise its own destruction like |Wait|.
  bool TimedWait(const TimeDelta& max_time);

#if defined(OS_WIN)
  HANDLE handle() const { return handle_.Get(); }
#endif

  // Wait, synchronously, on multiple events.
  //   waitables: an array of WaitableEvent pointers
  //   count: the number of elements in @waitables
  //
  // returns: the index of a WaitableEvent which has been signaled.
  //
  // You MUST NOT delete any of the WaitableEvent objects while this wait is
  // happening, however WaitMany's return "happens after" the |Signal| call
  // that caused it has completed, like |Wait|.
  static size_t WaitMany(WaitableEvent** waitables, size_t count);

  // For asynchronous waiting, see WaitableEventWatcher

  // This is a private helper class. It's here because it's used by friends of
  // this class (such as WaitableEventWatcher) to be able to enqueue elements
  // of the wait-list
  class Waiter {
   public:
    // Signal the waiter to wake up.
    //
    // Consider the case of a Waiter which is in multiple WaitableEvent's
    // wait-lists. Each WaitableEvent is automatic-reset and two of them are
    // signaled at the same time. Now, each will wake only the first waiter in
    // the wake-list before resetting. However, if those two waiters happen to
    // be the same object (as can happen if another thread didn't have a chance
    // to dequeue the waiter from the other wait-list in time), two auto-resets
    // will have happened, but only one waiter has been signaled!
    //
    // Because of this, a Waiter may "reject" a wake by returning false. In
    // this case, the auto-reset WaitableEvent shouldn't act as if anything has
    // been notified.
    virtual bool Fire(WaitableEvent* signaling_event) = 0;

    // Waiters may implement this in order to provide an extra condition for
    // two Waiters to be considered equal. In WaitableEvent::Dequeue, if the
    // pointers match then this function is called as a final check. See the
    // comments in ~Handle for why.
    virtual bool Compare(void* tag) = 0;

   protected:
    virtual ~Waiter() {}
  };

 private:
  friend class WaitableEventWatcher;

#if defined(OS_WIN)
  win::ScopedHandle handle_;
#else
  // On Windows, one can close a HANDLE which is currently being waited on. The
  // MSDN documentation says that the resulting behaviour is 'undefined', but
  // it doesn't crash. However, if we were to include the following members
  // directly then, on POSIX, one couldn't use WaitableEventWatcher to watch an
  // event which gets deleted. This mismatch has bitten us several times now,
  // so we have a kernel of the WaitableEvent, which is reference counted.
  // WaitableEventWatchers may then take a reference and thus match the Windows
  // behaviour.
  struct WaitableEventKernel :
      public RefCountedThreadSafe<WaitableEventKernel> {
   public:
    WaitableEventKernel(bool manual_reset, bool initially_signaled);

    bool Dequeue(Waiter* waiter, void* tag);

    base::Lock lock_;
    const bool manual_reset_;
    bool signaled_;
    std::list<Waiter*> waiters_;

   private:
    friend class RefCountedThreadSafe<WaitableEventKernel>;
    ~WaitableEventKernel();
  };

  typedef std::pair<WaitableEvent*, size_t> WaiterAndIndex;

  // When dealing with arrays of WaitableEvent*, we want to sort by the address
  // of the WaitableEvent in order to have a globally consistent locking order.
  // In that case we keep them, in sorted order, in an array of pairs where the
  // second element is the index of the WaitableEvent in the original,
  // unsorted, array.
  static size_t EnqueueMany(WaiterAndIndex* waitables,
                            size_t count, Waiter* waiter);

  bool SignalAll();
  bool SignalOne();
  void Enqueue(Waiter* waiter);

  scoped_refptr<WaitableEventKernel> kernel_;
#endif

  DISALLOW_COPY_AND_ASSIGN(WaitableEvent);
};

}  // namespace base

#endif  // BASE_SYNCHRONIZATION_WAITABLE_EVENT_H_
