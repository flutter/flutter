// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/utility/mutex.h"

#include <stdlib.h>  // For |rand()|.
#include <time.h>  // For |nanosleep()| (defined by POSIX).

#include <vector>

#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

TEST(MutexTest, TrivialSingleThreaded) {
  Mutex mutex;

  mutex.Lock();
  mutex.AssertHeld();
  mutex.Unlock();

  EXPECT_TRUE(mutex.TryLock());
  mutex.AssertHeld();
  mutex.Unlock();

  {
    MutexLock lock(&mutex);
    mutex.AssertHeld();
  }

  EXPECT_TRUE(mutex.TryLock());
  mutex.Unlock();
}

class Fiddler {
 public:
  enum Type { kTypeLock, kTypeTry };
  Fiddler(size_t times_to_lock,
          Type type,
          bool should_sleep,
          Mutex* mutex,
          int* shared_value)
      : times_to_lock_(times_to_lock),
        type_(type),
        should_sleep_(should_sleep),
        mutex_(mutex),
        shared_value_(shared_value) {
  }

  ~Fiddler() {
  }

  void Fiddle() {
    for (size_t i = 0; i < times_to_lock_;) {
      switch (type_) {
        case kTypeLock: {
          mutex_->Lock();
          int old_shared_value = *shared_value_;
          if (should_sleep_)
            SleepALittle();
          *shared_value_ = old_shared_value + 1;
          mutex_->Unlock();
          i++;
          break;
        }
        case kTypeTry:
          if (mutex_->TryLock()) {
            int old_shared_value = *shared_value_;
            if (should_sleep_)
              SleepALittle();
            *shared_value_ = old_shared_value + 1;
            mutex_->Unlock();
            i++;
          } else {
            SleepALittle();  // Don't spin.
          }
          break;
      }
    }
  }

 private:
  static void SleepALittle() {
    static const long kNanosPerMilli = 1000000;
    struct timespec req = {
      0,  // Seconds.
      (rand() % 10) * kNanosPerMilli // Nanoseconds.
    };
    int rv = nanosleep(&req, nullptr);
    MOJO_ALLOW_UNUSED_LOCAL(rv);
    assert(rv == 0);
  }

  const size_t times_to_lock_;
  const Type type_;
  const bool should_sleep_;
  Mutex* const mutex_;
  int* const shared_value_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Fiddler);
};

class FiddlerThread : public Thread {
 public:
  // Takes ownership of |fiddler|.
  FiddlerThread(Fiddler* fiddler)
      : fiddler_(fiddler) {
  }

  ~FiddlerThread() override { delete fiddler_; }

  void Run() override { fiddler_->Fiddle(); }

 private:
  Fiddler* const fiddler_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(FiddlerThread);
};

// This does a stress test (that also checks exclusion).
TEST(MutexTest, ThreadedStress) {
  static const size_t kNumThreads = 20;
  static const int kTimesToLockEach = 20;
  assert(kNumThreads % 4 == 0);

  Mutex mutex;
  int shared_value = 0;

  std::vector<FiddlerThread*> fiddler_threads;

  for (size_t i = 0; i < kNumThreads; i += 4) {
    fiddler_threads.push_back(new FiddlerThread(new Fiddler(
        kTimesToLockEach, Fiddler::kTypeLock, false, &mutex, &shared_value)));
    fiddler_threads.push_back(new FiddlerThread(new Fiddler(
        kTimesToLockEach, Fiddler::kTypeTry, false, &mutex, &shared_value)));
    fiddler_threads.push_back(new FiddlerThread(new Fiddler(
        kTimesToLockEach, Fiddler::kTypeLock, true, &mutex, &shared_value)));
    fiddler_threads.push_back(new FiddlerThread(new Fiddler(
        kTimesToLockEach, Fiddler::kTypeTry, true, &mutex, &shared_value)));
  }

  for (size_t i = 0; i < kNumThreads; i++)
    fiddler_threads[i]->Start();

  // Do some fiddling ourselves.
  Fiddler(kTimesToLockEach, Fiddler::kTypeLock, true, &mutex, &shared_value)
      .Fiddle();

  // Join.
  for (size_t i = 0; i < kNumThreads; i++)
    fiddler_threads[i]->Join();

  EXPECT_EQ(static_cast<int>(kNumThreads + 1) * kTimesToLockEach, shared_value);

  // Delete.
  for (size_t i = 0; i < kNumThreads; i++)
    delete fiddler_threads[i];
  fiddler_threads.clear();
}

class TryThread : public Thread {
 public:
  explicit TryThread(Mutex* mutex) : mutex_(mutex), try_lock_succeeded_() {}
  ~TryThread() override {}

  void Run() override {
    try_lock_succeeded_ = mutex_->TryLock();
    if (try_lock_succeeded_)
      mutex_->Unlock();
  }

  bool try_lock_succeeded() const { return try_lock_succeeded_; }

 private:
  Mutex* const mutex_;
  bool try_lock_succeeded_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TryThread);
};

TEST(MutexTest, TryLock) {
  Mutex mutex;

  // |TryLock()| should succeed -- we don't have the lock.
  {
    TryThread thread(&mutex);
    thread.Start();
    thread.Join();
    EXPECT_TRUE(thread.try_lock_succeeded());
  }

  // Take the lock.
  ASSERT_TRUE(mutex.TryLock());

  // Now it should fail.
  {
    TryThread thread(&mutex);
    thread.Start();
    thread.Join();
    EXPECT_FALSE(thread.try_lock_succeeded());
  }

  // Release the lock.
  mutex.Unlock();

  // It should succeed again.
  {
    TryThread thread(&mutex);
    thread.Start();
    thread.Join();
    EXPECT_TRUE(thread.try_lock_succeeded());
  }
}


// Tests of assertions for Debug builds.
#if !defined(NDEBUG)
// Test |AssertHeld()| (which is an actual user API).
TEST(MutexTest, DebugAssertHeldFailure) {
  Mutex mutex;
  EXPECT_DEATH_IF_SUPPORTED(mutex.AssertHeld(), "");
}

// Test other consistency checks.
TEST(MutexTest, DebugAssertionFailures) {
  // Unlock without lock held.
  EXPECT_DEATH_IF_SUPPORTED({
    Mutex mutex;
    mutex.Unlock();
  }, "");

  // Lock with lock held (on same thread).
  EXPECT_DEATH_IF_SUPPORTED({
    Mutex mutex;
    mutex.Lock();
    mutex.Lock();
  }, "");

  // Try lock with lock held.
  EXPECT_DEATH_IF_SUPPORTED({
    Mutex mutex;
    mutex.Lock();
    mutex.TryLock();
  }, "");

  // Destroy lock with lock held.
  EXPECT_DEATH_IF_SUPPORTED({
    Mutex mutex;
    mutex.Lock();
  }, "");
}
#endif  // !defined(NDEBUG)

}  // namespace
}  // namespace mojo
