// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/threading/non_thread_safe.h"
#include "base/threading/simple_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

// Duplicated from base/threading/non_thread_safe.h so that we can be
// good citizens there and undef the macro.
#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON))
#define ENABLE_NON_THREAD_SAFE 1
#else
#define ENABLE_NON_THREAD_SAFE 0
#endif

namespace base {

namespace {

// Simple class to exersice the basics of NonThreadSafe.
// Both the destructor and DoStuff should verify that they were
// called on the same thread as the constructor.
class NonThreadSafeClass : public NonThreadSafe {
 public:
  NonThreadSafeClass() {}

  // Verifies that it was called on the same thread as the constructor.
  void DoStuff() {
    DCHECK(CalledOnValidThread());
  }

  void DetachFromThread() {
    NonThreadSafe::DetachFromThread();
  }

  static void MethodOnDifferentThreadImpl();
  static void DestructorOnDifferentThreadImpl();

 private:
  DISALLOW_COPY_AND_ASSIGN(NonThreadSafeClass);
};

// Calls NonThreadSafeClass::DoStuff on another thread.
class CallDoStuffOnThread : public SimpleThread {
 public:
  explicit CallDoStuffOnThread(NonThreadSafeClass* non_thread_safe_class)
      : SimpleThread("call_do_stuff_on_thread"),
        non_thread_safe_class_(non_thread_safe_class) {
  }

  void Run() override { non_thread_safe_class_->DoStuff(); }

 private:
  NonThreadSafeClass* non_thread_safe_class_;

  DISALLOW_COPY_AND_ASSIGN(CallDoStuffOnThread);
};

// Deletes NonThreadSafeClass on a different thread.
class DeleteNonThreadSafeClassOnThread : public SimpleThread {
 public:
  explicit DeleteNonThreadSafeClassOnThread(
      NonThreadSafeClass* non_thread_safe_class)
      : SimpleThread("delete_non_thread_safe_class_on_thread"),
        non_thread_safe_class_(non_thread_safe_class) {
  }

  void Run() override { non_thread_safe_class_.reset(); }

 private:
  scoped_ptr<NonThreadSafeClass> non_thread_safe_class_;

  DISALLOW_COPY_AND_ASSIGN(DeleteNonThreadSafeClassOnThread);
};

}  // namespace

TEST(NonThreadSafeTest, CallsAllowedOnSameThread) {
  scoped_ptr<NonThreadSafeClass> non_thread_safe_class(
      new NonThreadSafeClass);

  // Verify that DoStuff doesn't assert.
  non_thread_safe_class->DoStuff();

  // Verify that the destructor doesn't assert.
  non_thread_safe_class.reset();
}

TEST(NonThreadSafeTest, DetachThenDestructOnDifferentThread) {
  scoped_ptr<NonThreadSafeClass> non_thread_safe_class(
      new NonThreadSafeClass);

  // Verify that the destructor doesn't assert when called on a different thread
  // after a detach.
  non_thread_safe_class->DetachFromThread();
  DeleteNonThreadSafeClassOnThread delete_on_thread(
      non_thread_safe_class.release());

  delete_on_thread.Start();
  delete_on_thread.Join();
}

#if GTEST_HAS_DEATH_TEST || !ENABLE_NON_THREAD_SAFE

void NonThreadSafeClass::MethodOnDifferentThreadImpl() {
  scoped_ptr<NonThreadSafeClass> non_thread_safe_class(
      new NonThreadSafeClass);

  // Verify that DoStuff asserts in debug builds only when called
  // on a different thread.
  CallDoStuffOnThread call_on_thread(non_thread_safe_class.get());

  call_on_thread.Start();
  call_on_thread.Join();
}

#if ENABLE_NON_THREAD_SAFE
TEST(NonThreadSafeDeathTest, MethodNotAllowedOnDifferentThreadInDebug) {
  ASSERT_DEATH({
      NonThreadSafeClass::MethodOnDifferentThreadImpl();
    }, "");
}
#else
TEST(NonThreadSafeTest, MethodAllowedOnDifferentThreadInRelease) {
  NonThreadSafeClass::MethodOnDifferentThreadImpl();
}
#endif  // ENABLE_NON_THREAD_SAFE

void NonThreadSafeClass::DestructorOnDifferentThreadImpl() {
  scoped_ptr<NonThreadSafeClass> non_thread_safe_class(
      new NonThreadSafeClass);

  // Verify that the destructor asserts in debug builds only
  // when called on a different thread.
  DeleteNonThreadSafeClassOnThread delete_on_thread(
      non_thread_safe_class.release());

  delete_on_thread.Start();
  delete_on_thread.Join();
}

#if ENABLE_NON_THREAD_SAFE
TEST(NonThreadSafeDeathTest, DestructorNotAllowedOnDifferentThreadInDebug) {
  ASSERT_DEATH({
      NonThreadSafeClass::DestructorOnDifferentThreadImpl();
    }, "");
}
#else
TEST(NonThreadSafeTest, DestructorAllowedOnDifferentThreadInRelease) {
  NonThreadSafeClass::DestructorOnDifferentThreadImpl();
}
#endif  // ENABLE_NON_THREAD_SAFE

#endif  // GTEST_HAS_DEATH_TEST || !ENABLE_NON_THREAD_SAFE

// Just in case we ever get lumped together with other compilation units.
#undef ENABLE_NON_THREAD_SAFE

}  // namespace base
