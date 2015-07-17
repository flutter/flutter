// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/synchronization/condition_variable.h"

#include <windows.h>
#include <stack>

#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/synchronization/lock.h"
#include "base/threading/thread_restrictions.h"
#include "base/time/time.h"

namespace {
// We can't use the linker supported delay-load for kernel32 so all this
// cruft here is to manually late-bind the needed functions.
typedef void (WINAPI *InitializeConditionVariableFn)(PCONDITION_VARIABLE);
typedef BOOL (WINAPI *SleepConditionVariableCSFn)(PCONDITION_VARIABLE,
                                                  PCRITICAL_SECTION, DWORD);
typedef void (WINAPI *WakeConditionVariableFn)(PCONDITION_VARIABLE);
typedef void (WINAPI *WakeAllConditionVariableFn)(PCONDITION_VARIABLE);

InitializeConditionVariableFn initialize_condition_variable_fn;
SleepConditionVariableCSFn sleep_condition_variable_fn;
WakeConditionVariableFn wake_condition_variable_fn;
WakeAllConditionVariableFn wake_all_condition_variable_fn;

bool BindVistaCondVarFunctions() {
  HMODULE kernel32 = GetModuleHandleA("kernel32.dll");
  initialize_condition_variable_fn =
      reinterpret_cast<InitializeConditionVariableFn>(
          GetProcAddress(kernel32, "InitializeConditionVariable"));
  if (!initialize_condition_variable_fn)
    return false;
  sleep_condition_variable_fn =
      reinterpret_cast<SleepConditionVariableCSFn>(
          GetProcAddress(kernel32, "SleepConditionVariableCS"));
  if (!sleep_condition_variable_fn)
    return false;
  wake_condition_variable_fn =
      reinterpret_cast<WakeConditionVariableFn>(
          GetProcAddress(kernel32, "WakeConditionVariable"));
  if (!wake_condition_variable_fn)
    return false;
  wake_all_condition_variable_fn =
      reinterpret_cast<WakeAllConditionVariableFn>(
          GetProcAddress(kernel32, "WakeAllConditionVariable"));
  if (!wake_all_condition_variable_fn)
    return false;
  return true;
}

}  // namespace.

namespace base {
// Abstract base class of the pimpl idiom.
class ConditionVarImpl {
 public:
  virtual ~ConditionVarImpl() {};
  virtual void Wait() = 0;
  virtual void TimedWait(const TimeDelta& max_time) = 0;
  virtual void Broadcast() = 0;
  virtual void Signal() = 0;
};

///////////////////////////////////////////////////////////////////////////////
// Windows Vista and Win7 implementation.
///////////////////////////////////////////////////////////////////////////////

class WinVistaCondVar: public ConditionVarImpl {
 public:
  WinVistaCondVar(Lock* user_lock);
  ~WinVistaCondVar() override {}
  // Overridden from ConditionVarImpl.
  void Wait() override;
  void TimedWait(const TimeDelta& max_time) override;
  void Broadcast() override;
  void Signal() override;

 private:
  base::Lock& user_lock_;
  CONDITION_VARIABLE cv_;
};

WinVistaCondVar::WinVistaCondVar(Lock* user_lock)
    : user_lock_(*user_lock) {
  initialize_condition_variable_fn(&cv_);
  DCHECK(user_lock);
}

void WinVistaCondVar::Wait() {
  TimedWait(TimeDelta::FromMilliseconds(INFINITE));
}

void WinVistaCondVar::TimedWait(const TimeDelta& max_time) {
  base::ThreadRestrictions::AssertWaitAllowed();
  DWORD timeout = static_cast<DWORD>(max_time.InMilliseconds());
  CRITICAL_SECTION* cs = user_lock_.lock_.native_handle();

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  user_lock_.CheckHeldAndUnmark();
#endif

  if (FALSE == sleep_condition_variable_fn(&cv_, cs, timeout)) {
    DCHECK(GetLastError() != WAIT_TIMEOUT);
  }

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  user_lock_.CheckUnheldAndMark();
#endif
}

void WinVistaCondVar::Broadcast() {
  wake_all_condition_variable_fn(&cv_);
}

void WinVistaCondVar::Signal() {
  wake_condition_variable_fn(&cv_);
}

///////////////////////////////////////////////////////////////////////////////
// Windows XP implementation.
///////////////////////////////////////////////////////////////////////////////

class WinXPCondVar : public ConditionVarImpl {
 public:
  WinXPCondVar(Lock* user_lock);
  ~WinXPCondVar() override;
  // Overridden from ConditionVarImpl.
  void Wait() override;
  void TimedWait(const TimeDelta& max_time) override;
  void Broadcast() override;
  void Signal() override;

  // Define Event class that is used to form circularly linked lists.
  // The list container is an element with NULL as its handle_ value.
  // The actual list elements have a non-zero handle_ value.
  // All calls to methods MUST be done under protection of a lock so that links
  // can be validated.  Without the lock, some links might asynchronously
  // change, and the assertions would fail (as would list change operations).
  class Event {
   public:
    // Default constructor with no arguments creates a list container.
    Event();
    ~Event();

    // InitListElement transitions an instance from a container, to an element.
    void InitListElement();

    // Methods for use on lists.
    bool IsEmpty() const;
    void PushBack(Event* other);
    Event* PopFront();
    Event* PopBack();

    // Methods for use on list elements.
    // Accessor method.
    HANDLE handle() const;
    // Pull an element from a list (if it's in one).
    Event* Extract();

    // Method for use on a list element or on a list.
    bool IsSingleton() const;

   private:
    // Provide pre/post conditions to validate correct manipulations.
    bool ValidateAsDistinct(Event* other) const;
    bool ValidateAsItem() const;
    bool ValidateAsList() const;
    bool ValidateLinks() const;

    HANDLE handle_;
    Event* next_;
    Event* prev_;
    DISALLOW_COPY_AND_ASSIGN(Event);
  };

  // Note that RUNNING is an unlikely number to have in RAM by accident.
  // This helps with defensive destructor coding in the face of user error.
  enum RunState { SHUTDOWN = 0, RUNNING = 64213 };

  // Internal implementation methods supporting Wait().
  Event* GetEventForWaiting();
  void RecycleEvent(Event* used_event);

  RunState run_state_;

  // Private critical section for access to member data.
  base::Lock internal_lock_;

  // Lock that is acquired before calling Wait().
  base::Lock& user_lock_;

  // Events that threads are blocked on.
  Event waiting_list_;

  // Free list for old events.
  Event recycling_list_;
  int recycling_list_size_;

  // The number of allocated, but not yet deleted events.
  int allocation_counter_;
};

WinXPCondVar::WinXPCondVar(Lock* user_lock)
    : run_state_(RUNNING),
      user_lock_(*user_lock),
      recycling_list_size_(0),
      allocation_counter_(0) {
  DCHECK(user_lock);
}

WinXPCondVar::~WinXPCondVar() {
  AutoLock auto_lock(internal_lock_);
  run_state_ = SHUTDOWN;  // Prevent any more waiting.

  DCHECK_EQ(recycling_list_size_, allocation_counter_);
  if (recycling_list_size_ != allocation_counter_) {  // Rare shutdown problem.
    // There are threads of execution still in this->TimedWait() and yet the
    // caller has instigated the destruction of this instance :-/.
    // A common reason for such "overly hasty" destruction is that the caller
    // was not willing to wait for all the threads to terminate.  Such hasty
    // actions are a violation of our usage contract, but we'll give the
    // waiting thread(s) one last chance to exit gracefully (prior to our
    // destruction).
    // Note: waiting_list_ *might* be empty, but recycling is still pending.
    AutoUnlock auto_unlock(internal_lock_);
    Broadcast();  // Make sure all waiting threads have been signaled.
    Sleep(10);  // Give threads a chance to grab internal_lock_.
    // All contained threads should be blocked on user_lock_ by now :-).
  }  // Reacquire internal_lock_.

  DCHECK_EQ(recycling_list_size_, allocation_counter_);
}

void WinXPCondVar::Wait() {
  // Default to "wait forever" timing, which means have to get a Signal()
  // or Broadcast() to come out of this wait state.
  TimedWait(TimeDelta::FromMilliseconds(INFINITE));
}

void WinXPCondVar::TimedWait(const TimeDelta& max_time) {
  base::ThreadRestrictions::AssertWaitAllowed();
  Event* waiting_event;
  HANDLE handle;
  {
    AutoLock auto_lock(internal_lock_);
    if (RUNNING != run_state_) return;  // Destruction in progress.
    waiting_event = GetEventForWaiting();
    handle = waiting_event->handle();
    DCHECK(handle);
  }  // Release internal_lock.

  {
    AutoUnlock unlock(user_lock_);  // Release caller's lock
    WaitForSingleObject(handle, static_cast<DWORD>(max_time.InMilliseconds()));
    // Minimize spurious signal creation window by recycling asap.
    AutoLock auto_lock(internal_lock_);
    RecycleEvent(waiting_event);
    // Release internal_lock_
  }  // Reacquire callers lock to depth at entry.
}

// Broadcast() is guaranteed to signal all threads that were waiting (i.e., had
// a cv_event internally allocated for them) before Broadcast() was called.
void WinXPCondVar::Broadcast() {
  std::stack<HANDLE> handles;  // See FAQ-question-10.
  {
    AutoLock auto_lock(internal_lock_);
    if (waiting_list_.IsEmpty())
      return;
    while (!waiting_list_.IsEmpty())
      // This is not a leak from waiting_list_.  See FAQ-question 12.
      handles.push(waiting_list_.PopBack()->handle());
  }  // Release internal_lock_.
  while (!handles.empty()) {
    SetEvent(handles.top());
    handles.pop();
  }
}

// Signal() will select one of the waiting threads, and signal it (signal its
// cv_event).  For better performance we signal the thread that went to sleep
// most recently (LIFO).  If we want fairness, then we wake the thread that has
// been sleeping the longest (FIFO).
void WinXPCondVar::Signal() {
  HANDLE handle;
  {
    AutoLock auto_lock(internal_lock_);
    if (waiting_list_.IsEmpty())
      return;  // No one to signal.
    // Only performance option should be used.
    // This is not a leak from waiting_list.  See FAQ-question 12.
     handle = waiting_list_.PopBack()->handle();  // LIFO.
  }  // Release internal_lock_.
  SetEvent(handle);
}

// GetEventForWaiting() provides a unique cv_event for any caller that needs to
// wait.  This means that (worst case) we may over time create as many cv_event
// objects as there are threads simultaneously using this instance's Wait()
// functionality.
WinXPCondVar::Event* WinXPCondVar::GetEventForWaiting() {
  // We hold internal_lock, courtesy of Wait().
  Event* cv_event;
  if (0 == recycling_list_size_) {
    DCHECK(recycling_list_.IsEmpty());
    cv_event = new Event();
    cv_event->InitListElement();
    allocation_counter_++;
    DCHECK(cv_event->handle());
  } else {
    cv_event = recycling_list_.PopFront();
    recycling_list_size_--;
  }
  waiting_list_.PushBack(cv_event);
  return cv_event;
}

// RecycleEvent() takes a cv_event that was previously used for Wait()ing, and
// recycles it for use in future Wait() calls for this or other threads.
// Note that there is a tiny chance that the cv_event is still signaled when we
// obtain it, and that can cause spurious signals (if/when we re-use the
// cv_event), but such is quite rare (see FAQ-question-5).
void WinXPCondVar::RecycleEvent(Event* used_event) {
  // We hold internal_lock, courtesy of Wait().
  // If the cv_event timed out, then it is necessary to remove it from
  // waiting_list_.  If it was selected by Broadcast() or Signal(), then it is
  // already gone.
  used_event->Extract();  // Possibly redundant
  recycling_list_.PushBack(used_event);
  recycling_list_size_++;
}
//------------------------------------------------------------------------------
// The next section provides the implementation for the private Event class.
//------------------------------------------------------------------------------

// Event provides a doubly-linked-list of events for use exclusively by the
// ConditionVariable class.

// This custom container was crafted because no simple combination of STL
// classes appeared to support the functionality required.  The specific
// unusual requirement for a linked-list-class is support for the Extract()
// method, which can remove an element from a list, potentially for insertion
// into a second list.  Most critically, the Extract() method is idempotent,
// turning the indicated element into an extracted singleton whether it was
// contained in a list or not.  This functionality allows one (or more) of
// threads to do the extraction.  The iterator that identifies this extractable
// element (in this case, a pointer to the list element) can be used after
// arbitrary manipulation of the (possibly) enclosing list container.  In
// general, STL containers do not provide iterators that can be used across
// modifications (insertions/extractions) of the enclosing containers, and
// certainly don't provide iterators that can be used if the identified
// element is *deleted* (removed) from the container.

// It is possible to use multiple redundant containers, such as an STL list,
// and an STL map, to achieve similar container semantics.  This container has
// only O(1) methods, while the corresponding (multiple) STL container approach
// would have more complex O(log(N)) methods (yeah... N isn't that large).
// Multiple containers also makes correctness more difficult to assert, as
// data is redundantly stored and maintained, which is generally evil.

WinXPCondVar::Event::Event() : handle_(0) {
  next_ = prev_ = this;  // Self referencing circular.
}

WinXPCondVar::Event::~Event() {
  if (0 == handle_) {
    // This is the list holder
    while (!IsEmpty()) {
      Event* cv_event = PopFront();
      DCHECK(cv_event->ValidateAsItem());
      delete cv_event;
    }
  }
  DCHECK(IsSingleton());
  if (0 != handle_) {
    int ret_val = CloseHandle(handle_);
    DCHECK(ret_val);
  }
}

// Change a container instance permanently into an element of a list.
void WinXPCondVar::Event::InitListElement() {
  DCHECK(!handle_);
  handle_ = CreateEvent(NULL, false, false, NULL);
  DCHECK(handle_);
}

// Methods for use on lists.
bool WinXPCondVar::Event::IsEmpty() const {
  DCHECK(ValidateAsList());
  return IsSingleton();
}

void WinXPCondVar::Event::PushBack(Event* other) {
  DCHECK(ValidateAsList());
  DCHECK(other->ValidateAsItem());
  DCHECK(other->IsSingleton());
  // Prepare other for insertion.
  other->prev_ = prev_;
  other->next_ = this;
  // Cut into list.
  prev_->next_ = other;
  prev_ = other;
  DCHECK(ValidateAsDistinct(other));
}

WinXPCondVar::Event* WinXPCondVar::Event::PopFront() {
  DCHECK(ValidateAsList());
  DCHECK(!IsSingleton());
  return next_->Extract();
}

WinXPCondVar::Event* WinXPCondVar::Event::PopBack() {
  DCHECK(ValidateAsList());
  DCHECK(!IsSingleton());
  return prev_->Extract();
}

// Methods for use on list elements.
// Accessor method.
HANDLE WinXPCondVar::Event::handle() const {
  DCHECK(ValidateAsItem());
  return handle_;
}

// Pull an element from a list (if it's in one).
WinXPCondVar::Event* WinXPCondVar::Event::Extract() {
  DCHECK(ValidateAsItem());
  if (!IsSingleton()) {
    // Stitch neighbors together.
    next_->prev_ = prev_;
    prev_->next_ = next_;
    // Make extractee into a singleton.
    prev_ = next_ = this;
  }
  DCHECK(IsSingleton());
  return this;
}

// Method for use on a list element or on a list.
bool WinXPCondVar::Event::IsSingleton() const {
  DCHECK(ValidateLinks());
  return next_ == this;
}

// Provide pre/post conditions to validate correct manipulations.
bool WinXPCondVar::Event::ValidateAsDistinct(Event* other) const {
  return ValidateLinks() && other->ValidateLinks() && (this != other);
}

bool WinXPCondVar::Event::ValidateAsItem() const {
  return (0 != handle_) && ValidateLinks();
}

bool WinXPCondVar::Event::ValidateAsList() const {
  return (0 == handle_) && ValidateLinks();
}

bool WinXPCondVar::Event::ValidateLinks() const {
  // Make sure both of our neighbors have links that point back to us.
  // We don't do the O(n) check and traverse the whole loop, and instead only
  // do a local check to (and returning from) our immediate neighbors.
  return (next_->prev_ == this) && (prev_->next_ == this);
}


/*
FAQ On WinXPCondVar subtle implementation details:

1) What makes this problem subtle?  Please take a look at "Strategies
for Implementing POSIX Condition Variables on Win32" by Douglas
C. Schmidt and Irfan Pyarali.
http://www.cs.wustl.edu/~schmidt/win32-cv-1.html It includes
discussions of numerous flawed strategies for implementing this
functionality.  I'm not convinced that even the final proposed
implementation has semantics that are as nice as this implementation
(especially with regard to Broadcast() and the impact on threads that
try to Wait() after a Broadcast() has been called, but before all the
original waiting threads have been signaled).

2) Why can't you use a single wait_event for all threads that call
Wait()?  See FAQ-question-1, or consider the following: If a single
event were used, then numerous threads calling Wait() could release
their cs locks, and be preempted just before calling
WaitForSingleObject().  If a call to Broadcast() was then presented on
a second thread, it would be impossible to actually signal all
waiting(?) threads.  Some number of SetEvent() calls *could* be made,
but there could be no guarantee that those led to to more than one
signaled thread (SetEvent()'s may be discarded after the first!), and
there could be no guarantee that the SetEvent() calls didn't just
awaken "other" threads that hadn't even started waiting yet (oops).
Without any limit on the number of requisite SetEvent() calls, the
system would be forced to do many such calls, allowing many new waits
to receive spurious signals.

3) How does this implementation cause spurious signal events?  The
cause in this implementation involves a race between a signal via
time-out and a signal via Signal() or Broadcast().  The series of
actions leading to this are:

a) Timer fires, and a waiting thread exits the line of code:

    WaitForSingleObject(waiting_event, max_time.InMilliseconds());

b) That thread (in (a)) is randomly pre-empted after the above line,
leaving the waiting_event reset (unsignaled) and still in the
waiting_list_.

c) A call to Signal() (or Broadcast()) on a second thread proceeds, and
selects the waiting cv_event (identified in step (b)) as the event to revive
via a call to SetEvent().

d) The Signal() method (step c) calls SetEvent() on waiting_event (step b).

e) The waiting cv_event (step b) is now signaled, but no thread is
waiting on it.

f) When that waiting_event (step b) is reused, it will immediately
be signaled (spuriously).


4) Why do you recycle events, and cause spurious signals?  First off,
the spurious events are very rare.  They can only (I think) appear
when the race described in FAQ-question-3 takes place.  This should be
very rare.  Most(?)  uses will involve only timer expiration, or only
Signal/Broadcast() actions.  When both are used, it will be rare that
the race will appear, and it would require MANY Wait() and signaling
activities.  If this implementation did not recycle events, then it
would have to create and destroy events for every call to Wait().
That allocation/deallocation and associated construction/destruction
would be costly (per wait), and would only be a rare benefit (when the
race was "lost" and a spurious signal took place). That would be bad
(IMO) optimization trade-off.  Finally, such spurious events are
allowed by the specification of condition variables (such as
implemented in Vista), and hence it is better if any user accommodates
such spurious events (see usage note in condition_variable.h).

5) Why don't you reset events when you are about to recycle them, or
about to reuse them, so that the spurious signals don't take place?
The thread described in FAQ-question-3 step c may be pre-empted for an
arbitrary length of time before proceeding to step d.  As a result,
the wait_event may actually be re-used *before* step (e) is reached.
As a result, calling reset would not help significantly.

6) How is it that the callers lock is released atomically with the
entry into a wait state?  We commit to the wait activity when we
allocate the wait_event for use in a given call to Wait().  This
allocation takes place before the caller's lock is released (and
actually before our internal_lock_ is released).  That allocation is
the defining moment when "the wait state has been entered," as that
thread *can* now be signaled by a call to Broadcast() or Signal().
Hence we actually "commit to wait" before releasing the lock, making
the pair effectively atomic.

8) Why do you need to lock your data structures during waiting, as the
caller is already in possession of a lock?  We need to Acquire() and
Release() our internal lock during Signal() and Broadcast().  If we tried
to use a callers lock for this purpose, we might conflict with their
external use of the lock.  For example, the caller may use to consistently
hold a lock on one thread while calling Signal() on another, and that would
block Signal().

9) Couldn't a more efficient implementation be provided if you
preclude using more than one external lock in conjunction with a
single ConditionVariable instance?  Yes, at least it could be viewed
as a simpler API (since you don't have to reiterate the lock argument
in each Wait() call).  One of the constructors now takes a specific
lock as an argument, and a there are corresponding Wait() calls that
don't specify a lock now.  It turns that the resulting implmentation
can't be made more efficient, as the internal lock needs to be used by
Signal() and Broadcast(), to access internal data structures.  As a
result, I was not able to utilize the user supplied lock (which is
being used by the user elsewhere presumably) to protect the private
member access.

9) Since you have a second lock, how can be be sure that there is no
possible deadlock scenario?  Our internal_lock_ is always the last
lock acquired, and the first one released, and hence a deadlock (due
to critical section problems) is impossible as a consequence of our
lock.

10) When doing a Broadcast(), why did you copy all the events into
an STL queue, rather than making a linked-loop, and iterating over it?
The iterating during Broadcast() is done so outside the protection
of the internal lock. As a result, other threads, such as the thread
wherein a related event is waiting, could asynchronously manipulate
the links around a cv_event.  As a result, the link structure cannot
be used outside a lock.  Broadcast() could iterate over waiting
events by cycling in-and-out of the protection of the internal_lock,
but that appears more expensive than copying the list into an STL
stack.

11) Why did the lock.h file need to be modified so much for this
change?  Central to a Condition Variable is the atomic release of a
lock during a Wait().  This places Wait() functionality exactly
mid-way between the two classes, Lock and Condition Variable.  Given
that there can be nested Acquire()'s of locks, and Wait() had to
Release() completely a held lock, it was necessary to augment the Lock
class with a recursion counter. Even more subtle is the fact that the
recursion counter (in a Lock) must be protected, as many threads can
access it asynchronously.  As a positive fallout of this, there are
now some DCHECKS to be sure no one Release()s a Lock more than they
Acquire()ed it, and there is ifdef'ed functionality that can detect
nested locks (legal under windows, but not under Posix).

12) Why is it that the cv_events removed from list in Broadcast() and Signal()
are not leaked?  How are they recovered??  The cv_events that appear to leak are
taken from the waiting_list_.  For each element in that list, there is currently
a thread in or around the WaitForSingleObject() call of Wait(), and those
threads have references to these otherwise leaked events. They are passed as
arguments to be recycled just aftre returning from WaitForSingleObject().

13) Why did you use a custom container class (the linked list), when STL has
perfectly good containers, such as an STL list?  The STL list, as with any
container, does not guarantee the utility of an iterator across manipulation
(such as insertions and deletions) of the underlying container.  The custom
double-linked-list container provided that assurance.  I don't believe any
combination of STL containers provided the services that were needed at the same
O(1) efficiency as the custom linked list.  The unusual requirement
for the container class is that a reference to an item within a container (an
iterator) needed to be maintained across an arbitrary manipulation of the
container.  This requirement exposes itself in the Wait() method, where a
waiting_event must be selected prior to the WaitForSingleObject(), and then it
must be used as part of recycling to remove the related instance from the
waiting_list.  A hash table (STL map) could be used, but I was embarrased to
use a complex and relatively low efficiency container when a doubly linked list
provided O(1) performance in all required operations.  Since other operations
to provide performance-and/or-fairness required queue (FIFO) and list (LIFO)
containers, I would also have needed to use an STL list/queue as well as an STL
map.  In the end I decided it would be "fun" to just do it right, and I
put so many assertions (DCHECKs) into the container class that it is trivial to
code review and validate its correctness.

*/

ConditionVariable::ConditionVariable(Lock* user_lock)
    : impl_(NULL) {
  static bool use_vista_native_cv = BindVistaCondVarFunctions();
  if (use_vista_native_cv)
    impl_= new WinVistaCondVar(user_lock);
  else
    impl_ = new WinXPCondVar(user_lock);
}

ConditionVariable::~ConditionVariable() {
  delete impl_;
}

void ConditionVariable::Wait() {
  impl_->Wait();
}

void ConditionVariable::TimedWait(const TimeDelta& max_time) {
  impl_->TimedWait(max_time);
}

void ConditionVariable::Broadcast() {
  impl_->Broadcast();
}

void ConditionVariable::Signal() {
  impl_->Signal();
}

}  // namespace base
