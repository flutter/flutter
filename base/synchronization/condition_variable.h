// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ConditionVariable wraps pthreads condition variable synchronization or, on
// Windows, simulates it.  This functionality is very helpful for having
// several threads wait for an event, as is common with a thread pool managed
// by a master.  The meaning of such an event in the (worker) thread pool
// scenario is that additional tasks are now available for processing.  It is
// used in Chrome in the DNS prefetching system to notify worker threads that
// a queue now has items (tasks) which need to be tended to.  A related use
// would have a pool manager waiting on a ConditionVariable, waiting for a
// thread in the pool to announce (signal) that there is now more room in a
// (bounded size) communications queue for the manager to deposit tasks, or,
// as a second example, that the queue of tasks is completely empty and all
// workers are waiting.
//
// USAGE NOTE 1: spurious signal events are possible with this and
// most implementations of condition variables.  As a result, be
// *sure* to retest your condition before proceeding.  The following
// is a good example of doing this correctly:
//
// while (!work_to_be_done()) Wait(...);
//
// In contrast do NOT do the following:
//
// if (!work_to_be_done()) Wait(...);  // Don't do this.
//
// Especially avoid the above if you are relying on some other thread only
// issuing a signal up *if* there is work-to-do.  There can/will
// be spurious signals.  Recheck state on waiting thread before
// assuming the signal was intentional. Caveat caller ;-).
//
// USAGE NOTE 2: Broadcast() frees up all waiting threads at once,
// which leads to contention for the locks they all held when they
// called Wait().  This results in POOR performance.  A much better
// approach to getting a lot of threads out of Wait() is to have each
// thread (upon exiting Wait()) call Signal() to free up another
// Wait'ing thread.  Look at condition_variable_unittest.cc for
// both examples.
//
// Broadcast() can be used nicely during teardown, as it gets the job
// done, and leaves no sleeping threads... and performance is less
// critical at that point.
//
// The semantics of Broadcast() are carefully crafted so that *all*
// threads that were waiting when the request was made will indeed
// get signaled.  Some implementations mess up, and don't signal them
// all, while others allow the wait to be effectively turned off (for
// a while while waiting threads come around).  This implementation
// appears correct, as it will not "lose" any signals, and will guarantee
// that all threads get signaled by Broadcast().
//
// This implementation offers support for "performance" in its selection of
// which thread to revive.  Performance, in direct contrast with "fairness,"
// assures that the thread that most recently began to Wait() is selected by
// Signal to revive.  Fairness would (if publicly supported) assure that the
// thread that has Wait()ed the longest is selected. The default policy
// may improve performance, as the selected thread may have a greater chance of
// having some of its stack data in various CPU caches.
//
// For a discussion of the many very subtle implementation details, see the FAQ
// at the end of condition_variable_win.cc.

#ifndef BASE_SYNCHRONIZATION_CONDITION_VARIABLE_H_
#define BASE_SYNCHRONIZATION_CONDITION_VARIABLE_H_

#include "build/build_config.h"

#if defined(OS_POSIX)
#include <pthread.h>
#endif

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/synchronization/lock.h"

namespace base {

class ConditionVarImpl;
class TimeDelta;

class BASE_EXPORT ConditionVariable {
 public:
  // Construct a cv for use with ONLY one user lock.
  explicit ConditionVariable(Lock* user_lock);

  ~ConditionVariable();

  // Wait() releases the caller's critical section atomically as it starts to
  // sleep, and the reacquires it when it is signaled.
  void Wait();
  void TimedWait(const TimeDelta& max_time);

  // Broadcast() revives all waiting threads.
  void Broadcast();
  // Signal() revives one waiting thread.
  void Signal();

 private:

#if defined(OS_WIN)
  ConditionVarImpl* impl_;
#elif defined(OS_POSIX)
  pthread_cond_t condition_;
  pthread_mutex_t* user_mutex_;
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  base::Lock* user_lock_;     // Needed to adjust shadow lock state on wait.
#endif

#endif

  DISALLOW_COPY_AND_ASSIGN(ConditionVariable);
};

}  // namespace base

#endif  // BASE_SYNCHRONIZATION_CONDITION_VARIABLE_H_
