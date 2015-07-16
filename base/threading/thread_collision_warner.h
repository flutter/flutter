// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_THREADING_THREAD_COLLISION_WARNER_H_
#define BASE_THREADING_THREAD_COLLISION_WARNER_H_

#include <memory>

#include "base/atomicops.h"
#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/compiler_specific.h"

// A helper class alongside macros to be used to verify assumptions about thread
// safety of a class.
//
// Example: Queue implementation non thread-safe but still usable if clients
//          are synchronized somehow.
//
//          In this case the macro DFAKE_SCOPED_LOCK has to be
//          used, it checks that if a thread is inside the push/pop then
//          noone else is still inside the pop/push
//
// class NonThreadSafeQueue {
//  public:
//   ...
//   void push(int) { DFAKE_SCOPED_LOCK(push_pop_); ... }
//   int pop() { DFAKE_SCOPED_LOCK(push_pop_); ... }
//   ...
//  private:
//   DFAKE_MUTEX(push_pop_);
// };
//
//
// Example: Queue implementation non thread-safe but still usable if clients
//          are synchronized somehow, it calls a method to "protect" from
//          a "protected" method
//
//          In this case the macro DFAKE_SCOPED_RECURSIVE_LOCK
//          has to be used, it checks that if a thread is inside the push/pop
//          then noone else is still inside the pop/push
//
// class NonThreadSafeQueue {
//  public:
//   void push(int) {
//     DFAKE_SCOPED_LOCK(push_pop_);
//     ...
//   }
//   int pop() {
//     DFAKE_SCOPED_RECURSIVE_LOCK(push_pop_);
//     bar();
//     ...
//   }
//   void bar() { DFAKE_SCOPED_RECURSIVE_LOCK(push_pop_); ... }
//   ...
//  private:
//   DFAKE_MUTEX(push_pop_);
// };
//
//
// Example: Queue implementation not usable even if clients are synchronized,
//          so only one thread in the class life cycle can use the two members
//          push/pop.
//
//          In this case the macro DFAKE_SCOPED_LOCK_THREAD_LOCKED pins the
//          specified
//          critical section the first time a thread enters push or pop, from
//          that time on only that thread is allowed to execute push or pop.
//
// class NonThreadSafeQueue {
//  public:
//   ...
//   void push(int) { DFAKE_SCOPED_LOCK_THREAD_LOCKED(push_pop_); ... }
//   int pop() { DFAKE_SCOPED_LOCK_THREAD_LOCKED(push_pop_); ... }
//   ...
//  private:
//   DFAKE_MUTEX(push_pop_);
// };
//
//
// Example: Class that has to be contructed/destroyed on same thread, it has
//          a "shareable" method (with external synchronization) and a not
//          shareable method (even with external synchronization).
//
//          In this case 3 Critical sections have to be defined
//
// class ExoticClass {
//  public:
//   ExoticClass() { DFAKE_SCOPED_LOCK_THREAD_LOCKED(ctor_dtor_); ... }
//   ~ExoticClass() { DFAKE_SCOPED_LOCK_THREAD_LOCKED(ctor_dtor_); ... }
//
//   void Shareable() { DFAKE_SCOPED_LOCK(shareable_section_); ... }
//   void NotShareable() { DFAKE_SCOPED_LOCK_THREAD_LOCKED(ctor_dtor_); ... }
//   ...
//  private:
//   DFAKE_MUTEX(ctor_dtor_);
//   DFAKE_MUTEX(shareable_section_);
// };


#if !defined(NDEBUG)

// Defines a class member that acts like a mutex. It is used only as a
// verification tool.
#define DFAKE_MUTEX(obj) \
     mutable base::ThreadCollisionWarner obj
// Asserts the call is never called simultaneously in two threads. Used at
// member function scope.
#define DFAKE_SCOPED_LOCK(obj) \
     base::ThreadCollisionWarner::ScopedCheck s_check_##obj(&obj)
// Asserts the call is never called simultaneously in two threads. Used at
// member function scope. Same as DFAKE_SCOPED_LOCK but allows recursive locks.
#define DFAKE_SCOPED_RECURSIVE_LOCK(obj) \
     base::ThreadCollisionWarner::ScopedRecursiveCheck sr_check_##obj(&obj)
// Asserts the code is always executed in the same thread.
#define DFAKE_SCOPED_LOCK_THREAD_LOCKED(obj) \
     base::ThreadCollisionWarner::Check check_##obj(&obj)

#else

#define DFAKE_MUTEX(obj) typedef void InternalFakeMutexType##obj
#define DFAKE_SCOPED_LOCK(obj) ((void)0)
#define DFAKE_SCOPED_RECURSIVE_LOCK(obj) ((void)0)
#define DFAKE_SCOPED_LOCK_THREAD_LOCKED(obj) ((void)0)

#endif

namespace base {

// The class ThreadCollisionWarner uses an Asserter to notify the collision
// AsserterBase is the interfaces and DCheckAsserter is the default asserter
// used. During the unit tests is used another class that doesn't "DCHECK"
// in case of collision (check thread_collision_warner_unittests.cc)
struct BASE_EXPORT AsserterBase {
  virtual ~AsserterBase() {}
  virtual void warn() = 0;
};

struct BASE_EXPORT DCheckAsserter : public AsserterBase {
  ~DCheckAsserter() override {}
  void warn() override;
};

class BASE_EXPORT ThreadCollisionWarner {
 public:
  // The parameter asserter is there only for test purpose
  explicit ThreadCollisionWarner(AsserterBase* asserter = new DCheckAsserter())
      : valid_thread_id_(0),
        counter_(0),
        asserter_(asserter) {}

  ~ThreadCollisionWarner() {
    delete asserter_;
  }

  // This class is meant to be used through the macro
  // DFAKE_SCOPED_LOCK_THREAD_LOCKED
  // it doesn't leave the critical section, as opposed to ScopedCheck,
  // because the critical section being pinned is allowed to be used only
  // from one thread
  class BASE_EXPORT Check {
   public:
    explicit Check(ThreadCollisionWarner* warner)
        : warner_(warner) {
      warner_->EnterSelf();
    }

    ~Check() {}

   private:
    ThreadCollisionWarner* warner_;

    DISALLOW_COPY_AND_ASSIGN(Check);
  };

  // This class is meant to be used through the macro
  // DFAKE_SCOPED_LOCK
  class BASE_EXPORT ScopedCheck {
   public:
    explicit ScopedCheck(ThreadCollisionWarner* warner)
        : warner_(warner) {
      warner_->Enter();
    }

    ~ScopedCheck() {
      warner_->Leave();
    }

   private:
    ThreadCollisionWarner* warner_;

    DISALLOW_COPY_AND_ASSIGN(ScopedCheck);
  };

  // This class is meant to be used through the macro
  // DFAKE_SCOPED_RECURSIVE_LOCK
  class BASE_EXPORT ScopedRecursiveCheck {
   public:
    explicit ScopedRecursiveCheck(ThreadCollisionWarner* warner)
        : warner_(warner) {
      warner_->EnterSelf();
    }

    ~ScopedRecursiveCheck() {
      warner_->Leave();
    }

   private:
    ThreadCollisionWarner* warner_;

    DISALLOW_COPY_AND_ASSIGN(ScopedRecursiveCheck);
  };

 private:
  // This method stores the current thread identifier and does a DCHECK
  // if a another thread has already done it, it is safe if same thread
  // calls this multiple time (recursion allowed).
  void EnterSelf();

  // Same as EnterSelf but recursion is not allowed.
  void Enter();

  // Removes the thread_id stored in order to allow other threads to
  // call EnterSelf or Enter.
  void Leave();

  // This stores the thread id that is inside the critical section, if the
  // value is 0 then no thread is inside.
  volatile subtle::Atomic32 valid_thread_id_;

  // Counter to trace how many time a critical section was "pinned"
  // (when allowed) in order to unpin it when counter_ reaches 0.
  volatile subtle::Atomic32 counter_;

  // Here only for class unit tests purpose, during the test I need to not
  // DCHECK but notify the collision with something else.
  AsserterBase* asserter_;

  DISALLOW_COPY_AND_ASSIGN(ThreadCollisionWarner);
};

}  // namespace base

#endif  // BASE_THREADING_THREAD_COLLISION_WARNER_H_
