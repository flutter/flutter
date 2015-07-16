// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <vector>

#include "base/logging.h"
#include "base/synchronization/waitable_event.h"
#include "base/synchronization/condition_variable.h"
#include "base/synchronization/lock.h"
#include "base/threading/thread_restrictions.h"

// -----------------------------------------------------------------------------
// A WaitableEvent on POSIX is implemented as a wait-list. Currently we don't
// support cross-process events (where one process can signal an event which
// others are waiting on). Because of this, we can avoid having one thread per
// listener in several cases.
//
// The WaitableEvent maintains a list of waiters, protected by a lock. Each
// waiter is either an async wait, in which case we have a Task and the
// MessageLoop to run it on, or a blocking wait, in which case we have the
// condition variable to signal.
//
// Waiting involves grabbing the lock and adding oneself to the wait list. Async
// waits can be canceled, which means grabbing the lock and removing oneself
// from the list.
//
// Waiting on multiple events is handled by adding a single, synchronous wait to
// the wait-list of many events. An event passes a pointer to itself when
// firing a waiter and so we can store that pointer to find out which event
// triggered.
// -----------------------------------------------------------------------------

namespace base {

// -----------------------------------------------------------------------------
// This is just an abstract base class for waking the two types of waiters
// -----------------------------------------------------------------------------
WaitableEvent::WaitableEvent(bool manual_reset, bool initially_signaled)
    : kernel_(new WaitableEventKernel(manual_reset, initially_signaled)) {
}

WaitableEvent::~WaitableEvent() {
}

void WaitableEvent::Reset() {
  base::AutoLock locked(kernel_->lock_);
  kernel_->signaled_ = false;
}

void WaitableEvent::Signal() {
  base::AutoLock locked(kernel_->lock_);

  if (kernel_->signaled_)
    return;

  if (kernel_->manual_reset_) {
    SignalAll();
    kernel_->signaled_ = true;
  } else {
    // In the case of auto reset, if no waiters were woken, we remain
    // signaled.
    if (!SignalOne())
      kernel_->signaled_ = true;
  }
}

bool WaitableEvent::IsSignaled() {
  base::AutoLock locked(kernel_->lock_);

  const bool result = kernel_->signaled_;
  if (result && !kernel_->manual_reset_)
    kernel_->signaled_ = false;
  return result;
}

// -----------------------------------------------------------------------------
// Synchronous waits

// -----------------------------------------------------------------------------
// This is a synchronous waiter. The thread is waiting on the given condition
// variable and the fired flag in this object.
// -----------------------------------------------------------------------------
class SyncWaiter : public WaitableEvent::Waiter {
 public:
  SyncWaiter()
      : fired_(false),
        signaling_event_(NULL),
        lock_(),
        cv_(&lock_) {
  }

  bool Fire(WaitableEvent* signaling_event) override {
    base::AutoLock locked(lock_);

    if (fired_)
      return false;

    fired_ = true;
    signaling_event_ = signaling_event;

    cv_.Broadcast();

    // Unlike AsyncWaiter objects, SyncWaiter objects are stack-allocated on
    // the blocking thread's stack.  There is no |delete this;| in Fire.  The
    // SyncWaiter object is destroyed when it goes out of scope.

    return true;
  }

  WaitableEvent* signaling_event() const {
    return signaling_event_;
  }

  // ---------------------------------------------------------------------------
  // These waiters are always stack allocated and don't delete themselves. Thus
  // there's no problem and the ABA tag is the same as the object pointer.
  // ---------------------------------------------------------------------------
  bool Compare(void* tag) override { return this == tag; }

  // ---------------------------------------------------------------------------
  // Called with lock held.
  // ---------------------------------------------------------------------------
  bool fired() const {
    return fired_;
  }

  // ---------------------------------------------------------------------------
  // During a TimedWait, we need a way to make sure that an auto-reset
  // WaitableEvent doesn't think that this event has been signaled between
  // unlocking it and removing it from the wait-list. Called with lock held.
  // ---------------------------------------------------------------------------
  void Disable() {
    fired_ = true;
  }

  base::Lock* lock() {
    return &lock_;
  }

  base::ConditionVariable* cv() {
    return &cv_;
  }

 private:
  bool fired_;
  WaitableEvent* signaling_event_;  // The WaitableEvent which woke us
  base::Lock lock_;
  base::ConditionVariable cv_;
};

void WaitableEvent::Wait() {
  bool result = TimedWait(TimeDelta::FromSeconds(-1));
  DCHECK(result) << "TimedWait() should never fail with infinite timeout";
}

bool WaitableEvent::TimedWait(const TimeDelta& max_time) {
  base::ThreadRestrictions::AssertWaitAllowed();
  const TimeTicks end_time(TimeTicks::Now() + max_time);
  const bool finite_time = max_time.ToInternalValue() >= 0;

  kernel_->lock_.Acquire();
  if (kernel_->signaled_) {
    if (!kernel_->manual_reset_) {
      // In this case we were signaled when we had no waiters. Now that
      // someone has waited upon us, we can automatically reset.
      kernel_->signaled_ = false;
    }

    kernel_->lock_.Release();
    return true;
  }

  SyncWaiter sw;
  sw.lock()->Acquire();

  Enqueue(&sw);
  kernel_->lock_.Release();
  // We are violating locking order here by holding the SyncWaiter lock but not
  // the WaitableEvent lock. However, this is safe because we don't lock @lock_
  // again before unlocking it.

  for (;;) {
    const TimeTicks current_time(TimeTicks::Now());

    if (sw.fired() || (finite_time && current_time >= end_time)) {
      const bool return_value = sw.fired();

      // We can't acquire @lock_ before releasing the SyncWaiter lock (because
      // of locking order), however, in between the two a signal could be fired
      // and @sw would accept it, however we will still return false, so the
      // signal would be lost on an auto-reset WaitableEvent. Thus we call
      // Disable which makes sw::Fire return false.
      sw.Disable();
      sw.lock()->Release();

      // This is a bug that has been enshrined in the interface of
      // WaitableEvent now: |Dequeue| is called even when |sw.fired()| is true,
      // even though it'll always return false in that case. However, taking
      // the lock ensures that |Signal| has completed before we return and
      // means that a WaitableEvent can synchronise its own destruction.
      kernel_->lock_.Acquire();
      kernel_->Dequeue(&sw, &sw);
      kernel_->lock_.Release();

      return return_value;
    }

    if (finite_time) {
      const TimeDelta max_wait(end_time - current_time);
      sw.cv()->TimedWait(max_wait);
    } else {
      sw.cv()->Wait();
    }
  }
}

// -----------------------------------------------------------------------------
// Synchronous waiting on multiple objects.

static bool  // StrictWeakOrdering
cmp_fst_addr(const std::pair<WaitableEvent*, unsigned> &a,
             const std::pair<WaitableEvent*, unsigned> &b) {
  return a.first < b.first;
}

// static
size_t WaitableEvent::WaitMany(WaitableEvent** raw_waitables,
                               size_t count) {
  base::ThreadRestrictions::AssertWaitAllowed();
  DCHECK(count) << "Cannot wait on no events";

  // We need to acquire the locks in a globally consistent order. Thus we sort
  // the array of waitables by address. We actually sort a pairs so that we can
  // map back to the original index values later.
  std::vector<std::pair<WaitableEvent*, size_t> > waitables;
  waitables.reserve(count);
  for (size_t i = 0; i < count; ++i)
    waitables.push_back(std::make_pair(raw_waitables[i], i));

  DCHECK_EQ(count, waitables.size());

  sort(waitables.begin(), waitables.end(), cmp_fst_addr);

  // The set of waitables must be distinct. Since we have just sorted by
  // address, we can check this cheaply by comparing pairs of consecutive
  // elements.
  for (size_t i = 0; i < waitables.size() - 1; ++i) {
    DCHECK(waitables[i].first != waitables[i+1].first);
  }

  SyncWaiter sw;

  const size_t r = EnqueueMany(&waitables[0], count, &sw);
  if (r) {
    // One of the events is already signaled. The SyncWaiter has not been
    // enqueued anywhere. EnqueueMany returns the count of remaining waitables
    // when the signaled one was seen, so the index of the signaled event is
    // @count - @r.
    return waitables[count - r].second;
  }

  // At this point, we hold the locks on all the WaitableEvents and we have
  // enqueued our waiter in them all.
  sw.lock()->Acquire();
    // Release the WaitableEvent locks in the reverse order
    for (size_t i = 0; i < count; ++i) {
      waitables[count - (1 + i)].first->kernel_->lock_.Release();
    }

    for (;;) {
      if (sw.fired())
        break;

      sw.cv()->Wait();
    }
  sw.lock()->Release();

  // The address of the WaitableEvent which fired is stored in the SyncWaiter.
  WaitableEvent *const signaled_event = sw.signaling_event();
  // This will store the index of the raw_waitables which fired.
  size_t signaled_index = 0;

  // Take the locks of each WaitableEvent in turn (except the signaled one) and
  // remove our SyncWaiter from the wait-list
  for (size_t i = 0; i < count; ++i) {
    if (raw_waitables[i] != signaled_event) {
      raw_waitables[i]->kernel_->lock_.Acquire();
        // There's no possible ABA issue with the address of the SyncWaiter here
        // because it lives on the stack. Thus the tag value is just the pointer
        // value again.
        raw_waitables[i]->kernel_->Dequeue(&sw, &sw);
      raw_waitables[i]->kernel_->lock_.Release();
    } else {
      // By taking this lock here we ensure that |Signal| has completed by the
      // time we return, because |Signal| holds this lock. This matches the
      // behaviour of |Wait| and |TimedWait|.
      raw_waitables[i]->kernel_->lock_.Acquire();
      raw_waitables[i]->kernel_->lock_.Release();
      signaled_index = i;
    }
  }

  return signaled_index;
}

// -----------------------------------------------------------------------------
// If return value == 0:
//   The locks of the WaitableEvents have been taken in order and the Waiter has
//   been enqueued in the wait-list of each. None of the WaitableEvents are
//   currently signaled
// else:
//   None of the WaitableEvent locks are held. The Waiter has not been enqueued
//   in any of them and the return value is the index of the first WaitableEvent
//   which was signaled, from the end of the array.
// -----------------------------------------------------------------------------
// static
size_t WaitableEvent::EnqueueMany
    (std::pair<WaitableEvent*, size_t>* waitables,
     size_t count, Waiter* waiter) {
  if (!count)
    return 0;

  waitables[0].first->kernel_->lock_.Acquire();
    if (waitables[0].first->kernel_->signaled_) {
      if (!waitables[0].first->kernel_->manual_reset_)
        waitables[0].first->kernel_->signaled_ = false;
      waitables[0].first->kernel_->lock_.Release();
      return count;
    }

    const size_t r = EnqueueMany(waitables + 1, count - 1, waiter);
    if (r) {
      waitables[0].first->kernel_->lock_.Release();
    } else {
      waitables[0].first->Enqueue(waiter);
    }

    return r;
}

// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// Private functions...

WaitableEvent::WaitableEventKernel::WaitableEventKernel(bool manual_reset,
                                                        bool initially_signaled)
    : manual_reset_(manual_reset),
      signaled_(initially_signaled) {
}

WaitableEvent::WaitableEventKernel::~WaitableEventKernel() {
}

// -----------------------------------------------------------------------------
// Wake all waiting waiters. Called with lock held.
// -----------------------------------------------------------------------------
bool WaitableEvent::SignalAll() {
  bool signaled_at_least_one = false;

  for (std::list<Waiter*>::iterator
       i = kernel_->waiters_.begin(); i != kernel_->waiters_.end(); ++i) {
    if ((*i)->Fire(this))
      signaled_at_least_one = true;
  }

  kernel_->waiters_.clear();
  return signaled_at_least_one;
}

// ---------------------------------------------------------------------------
// Try to wake a single waiter. Return true if one was woken. Called with lock
// held.
// ---------------------------------------------------------------------------
bool WaitableEvent::SignalOne() {
  for (;;) {
    if (kernel_->waiters_.empty())
      return false;

    const bool r = (*kernel_->waiters_.begin())->Fire(this);
    kernel_->waiters_.pop_front();
    if (r)
      return true;
  }
}

// -----------------------------------------------------------------------------
// Add a waiter to the list of those waiting. Called with lock held.
// -----------------------------------------------------------------------------
void WaitableEvent::Enqueue(Waiter* waiter) {
  kernel_->waiters_.push_back(waiter);
}

// -----------------------------------------------------------------------------
// Remove a waiter from the list of those waiting. Return true if the waiter was
// actually removed. Called with lock held.
// -----------------------------------------------------------------------------
bool WaitableEvent::WaitableEventKernel::Dequeue(Waiter* waiter, void* tag) {
  for (std::list<Waiter*>::iterator
       i = waiters_.begin(); i != waiters_.end(); ++i) {
    if (*i == waiter && (*i)->Compare(tag)) {
      waiters_.erase(i);
      return true;
    }
  }

  return false;
}

// -----------------------------------------------------------------------------

}  // namespace base
