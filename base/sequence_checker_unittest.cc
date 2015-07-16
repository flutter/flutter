// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/sequence_checker.h"
#include "base/single_thread_task_runner.h"
#include "base/test/sequenced_worker_pool_owner.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

// Duplicated from base/sequence_checker.h so that we can be good citizens
// there and undef the macro.
#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON))
#define ENABLE_SEQUENCE_CHECKER 1
#else
#define ENABLE_SEQUENCE_CHECKER 0
#endif

namespace base {

namespace {

const size_t kNumWorkerThreads = 3;

// Simple class to exercise the basics of SequenceChecker.
// DoStuff should verify that it's called on a valid sequenced thread.
// SequenceCheckedObject can be destroyed on any thread (like WeakPtr).
class SequenceCheckedObject {
 public:
  SequenceCheckedObject() {}
  ~SequenceCheckedObject() {}

  // Verifies that it was called on the same thread as the constructor.
  void DoStuff() {
    DCHECK(sequence_checker_.CalledOnValidSequencedThread());
  }

  void DetachFromSequence() {
    sequence_checker_.DetachFromSequence();
  }

 private:
  SequenceChecker sequence_checker_;

  DISALLOW_COPY_AND_ASSIGN(SequenceCheckedObject);
};

class SequenceCheckerTest : public testing::Test {
 public:
  SequenceCheckerTest() : other_thread_("sequence_checker_test_other_thread") {}

  void SetUp() override {
    other_thread_.Start();
    ResetPool();
  }

  void TearDown() override {
    other_thread_.Stop();
    pool()->Shutdown();
  }

 protected:
  base::Thread* other_thread() { return &other_thread_; }

  const scoped_refptr<SequencedWorkerPool>& pool() {
    return pool_owner_->pool();
  }

  void PostDoStuffToWorkerPool(SequenceCheckedObject* sequence_checked_object,
                               const std::string& token_name) {
    pool()->PostNamedSequencedWorkerTask(
        token_name,
        FROM_HERE,
        base::Bind(&SequenceCheckedObject::DoStuff,
                   base::Unretained(sequence_checked_object)));
  }

  void PostDoStuffToOtherThread(
      SequenceCheckedObject* sequence_checked_object) {
    other_thread()->task_runner()->PostTask(
        FROM_HERE, base::Bind(&SequenceCheckedObject::DoStuff,
                              base::Unretained(sequence_checked_object)));
  }

  void PostDeleteToOtherThread(
      scoped_ptr<SequenceCheckedObject> sequence_checked_object) {
    other_thread()->message_loop()->DeleteSoon(
        FROM_HERE,
        sequence_checked_object.release());
  }

  // Destroys the SequencedWorkerPool instance, blocking until it is fully shut
  // down, and creates a new instance.
  void ResetPool() {
    pool_owner_.reset(new SequencedWorkerPoolOwner(kNumWorkerThreads, "test"));
  }

  void MethodOnDifferentThreadDeathTest();
  void DetachThenCallFromDifferentThreadDeathTest();
  void DifferentSequenceTokensDeathTest();
  void WorkerPoolAndSimpleThreadDeathTest();
  void TwoDifferentWorkerPoolsDeathTest();

 private:
  MessageLoop message_loop_;  // Needed by SequencedWorkerPool to function.
  base::Thread other_thread_;
  scoped_ptr<SequencedWorkerPoolOwner> pool_owner_;
};

TEST_F(SequenceCheckerTest, CallsAllowedOnSameThread) {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  // Verify that DoStuff doesn't assert.
  sequence_checked_object->DoStuff();

  // Verify that the destructor doesn't assert.
  sequence_checked_object.reset();
}

TEST_F(SequenceCheckerTest, DestructorAllowedOnDifferentThread) {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  // Verify the destructor doesn't assert when called on a different thread.
  PostDeleteToOtherThread(sequence_checked_object.Pass());
  other_thread()->Stop();
}

TEST_F(SequenceCheckerTest, DetachFromSequence) {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  // Verify that DoStuff doesn't assert when called on a different thread after
  // a call to DetachFromSequence.
  sequence_checked_object->DetachFromSequence();

  PostDoStuffToOtherThread(sequence_checked_object.get());
  other_thread()->Stop();
}

TEST_F(SequenceCheckerTest, SameSequenceTokenValid) {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  sequence_checked_object->DetachFromSequence();
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  pool()->FlushForTesting();

  PostDeleteToOtherThread(sequence_checked_object.Pass());
  other_thread()->Stop();
}

TEST_F(SequenceCheckerTest, DetachSequenceTokenValid) {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  sequence_checked_object->DetachFromSequence();
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  pool()->FlushForTesting();

  sequence_checked_object->DetachFromSequence();
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "B");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "B");
  pool()->FlushForTesting();

  PostDeleteToOtherThread(sequence_checked_object.Pass());
  other_thread()->Stop();
}

#if GTEST_HAS_DEATH_TEST || !ENABLE_SEQUENCE_CHECKER

void SequenceCheckerTest::MethodOnDifferentThreadDeathTest() {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  // DoStuff should assert in debug builds only when called on a
  // different thread.
  PostDoStuffToOtherThread(sequence_checked_object.get());
  other_thread()->Stop();
}

#if ENABLE_SEQUENCE_CHECKER
TEST_F(SequenceCheckerTest, MethodNotAllowedOnDifferentThreadDeathTestInDebug) {
  // The default style "fast" does not support multi-threaded tests.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH({
    MethodOnDifferentThreadDeathTest();
  }, "");
}
#else
TEST_F(SequenceCheckerTest, MethodAllowedOnDifferentThreadDeathTestInRelease) {
  MethodOnDifferentThreadDeathTest();
}
#endif  // ENABLE_SEQUENCE_CHECKER

void SequenceCheckerTest::DetachThenCallFromDifferentThreadDeathTest() {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  // DoStuff doesn't assert when called on a different thread
  // after a call to DetachFromSequence.
  sequence_checked_object->DetachFromSequence();
  PostDoStuffToOtherThread(sequence_checked_object.get());
  other_thread()->Stop();

  // DoStuff should assert in debug builds only after moving to
  // another thread.
  sequence_checked_object->DoStuff();
}

#if ENABLE_SEQUENCE_CHECKER
TEST_F(SequenceCheckerTest, DetachFromSequenceDeathTestInDebug) {
  // The default style "fast" does not support multi-threaded tests.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH({
    DetachThenCallFromDifferentThreadDeathTest();
  }, "");
}
#else
TEST_F(SequenceCheckerTest, DetachFromThreadDeathTestInRelease) {
  DetachThenCallFromDifferentThreadDeathTest();
}
#endif  // ENABLE_SEQUENCE_CHECKER

void SequenceCheckerTest::DifferentSequenceTokensDeathTest() {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  sequence_checked_object->DetachFromSequence();
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "B");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "B");
  pool()->FlushForTesting();

  PostDeleteToOtherThread(sequence_checked_object.Pass());
  other_thread()->Stop();
}

#if ENABLE_SEQUENCE_CHECKER
TEST_F(SequenceCheckerTest, DifferentSequenceTokensDeathTestInDebug) {
  // The default style "fast" does not support multi-threaded tests.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH({
    DifferentSequenceTokensDeathTest();
  }, "");
}
#else
TEST_F(SequenceCheckerTest, DifferentSequenceTokensDeathTestInRelease) {
  DifferentSequenceTokensDeathTest();
}
#endif  // ENABLE_SEQUENCE_CHECKER

void SequenceCheckerTest::WorkerPoolAndSimpleThreadDeathTest() {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  sequence_checked_object->DetachFromSequence();
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  pool()->FlushForTesting();

  PostDoStuffToOtherThread(sequence_checked_object.get());
  other_thread()->Stop();
}

#if ENABLE_SEQUENCE_CHECKER
TEST_F(SequenceCheckerTest, WorkerPoolAndSimpleThreadDeathTestInDebug) {
  // The default style "fast" does not support multi-threaded tests.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH({
    WorkerPoolAndSimpleThreadDeathTest();
  }, "");
}
#else
TEST_F(SequenceCheckerTest, WorkerPoolAndSimpleThreadDeathTestInRelease) {
  WorkerPoolAndSimpleThreadDeathTest();
}
#endif  // ENABLE_SEQUENCE_CHECKER

void SequenceCheckerTest::TwoDifferentWorkerPoolsDeathTest() {
  scoped_ptr<SequenceCheckedObject> sequence_checked_object(
      new SequenceCheckedObject);

  sequence_checked_object->DetachFromSequence();
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  PostDoStuffToWorkerPool(sequence_checked_object.get(), "A");
  pool()->FlushForTesting();

  SequencedWorkerPoolOwner second_pool_owner(kNumWorkerThreads, "test2");
  second_pool_owner.pool()->PostNamedSequencedWorkerTask(
      "A",
      FROM_HERE,
      base::Bind(&SequenceCheckedObject::DoStuff,
                 base::Unretained(sequence_checked_object.get())));
  second_pool_owner.pool()->FlushForTesting();
  second_pool_owner.pool()->Shutdown();
}

#if ENABLE_SEQUENCE_CHECKER
TEST_F(SequenceCheckerTest, TwoDifferentWorkerPoolsDeathTestInDebug) {
  // The default style "fast" does not support multi-threaded tests.
  ::testing::FLAGS_gtest_death_test_style = "threadsafe";
  ASSERT_DEATH({
    TwoDifferentWorkerPoolsDeathTest();
  }, "");
}
#else
TEST_F(SequenceCheckerTest, TwoDifferentWorkerPoolsDeathTestInRelease) {
  TwoDifferentWorkerPoolsDeathTest();
}
#endif  // ENABLE_SEQUENCE_CHECKER

#endif  // GTEST_HAS_DEATH_TEST || !ENABLE_SEQUENCE_CHECKER

}  // namespace

}  // namespace base

// Just in case we ever get lumped together with other compilation units.
#undef ENABLE_SEQUENCE_CHECKER
