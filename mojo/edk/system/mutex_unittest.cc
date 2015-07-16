// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/mutex.h"

#include <stdlib.h>

#include "base/threading/platform_thread.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

// Sleeps for a "very small" amount of time.
void EpsilonRandomSleep() {
  test::Sleep(test::DeadlineFromMilliseconds(rand() % 20));
}

// Basic test to make sure that Lock()/Unlock()/TryLock() don't crash ----------

class BasicMutexTestThread : public base::PlatformThread::Delegate {
 public:
  explicit BasicMutexTestThread(Mutex* mutex) : mutex_(mutex), acquired_(0) {}

  void ThreadMain() override {
    for (int i = 0; i < 10; i++) {
      mutex_->Lock();
      mutex_->AssertHeld();
      acquired_++;
      mutex_->Unlock();
    }
    for (int i = 0; i < 10; i++) {
      mutex_->Lock();
      mutex_->AssertHeld();
      acquired_++;
      EpsilonRandomSleep();
      mutex_->Unlock();
    }
    for (int i = 0; i < 10; i++) {
      if (mutex_->TryLock()) {
        mutex_->AssertHeld();
        acquired_++;
        EpsilonRandomSleep();
        mutex_->Unlock();
      }
    }
  }

  int acquired() const { return acquired_; }

 private:
  Mutex* mutex_;
  int acquired_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(BasicMutexTestThread);
};

TEST(MutexTest, Basic) {
  Mutex mutex;
  BasicMutexTestThread thread(&mutex);
  base::PlatformThreadHandle handle;

  ASSERT_TRUE(base::PlatformThread::Create(0, &thread, &handle));

  int acquired = 0;
  for (int i = 0; i < 5; i++) {
    mutex.Lock();
    mutex.AssertHeld();
    acquired++;
    mutex.Unlock();
  }
  for (int i = 0; i < 10; i++) {
    mutex.Lock();
    mutex.AssertHeld();
    acquired++;
    EpsilonRandomSleep();
    mutex.Unlock();
  }
  for (int i = 0; i < 10; i++) {
    if (mutex.TryLock()) {
      mutex.AssertHeld();
      acquired++;
      EpsilonRandomSleep();
      mutex.Unlock();
    }
  }
  for (int i = 0; i < 5; i++) {
    mutex.Lock();
    mutex.AssertHeld();
    acquired++;
    EpsilonRandomSleep();
    mutex.Unlock();
  }

  base::PlatformThread::Join(handle);

  EXPECT_GE(acquired, 20);
  EXPECT_GE(thread.acquired(), 20);
}

// Test that TryLock() works as expected ---------------------------------------

class TryLockTestThread : public base::PlatformThread::Delegate {
 public:
  explicit TryLockTestThread(Mutex* mutex) : mutex_(mutex), got_lock_(false) {}

  void ThreadMain() override MOJO_NO_THREAD_SAFETY_ANALYSIS {
    got_lock_ = mutex_->TryLock();
    if (got_lock_) {
      mutex_->AssertHeld();
      mutex_->Unlock();
    }
  }

  bool got_lock() const { return got_lock_; }

 private:
  Mutex* mutex_;
  bool got_lock_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TryLockTestThread);
};

TEST(MutexTest, TryLock) MOJO_NO_THREAD_SAFETY_ANALYSIS {
  Mutex mutex;

  ASSERT_TRUE(mutex.TryLock());
  // We now have the mutex....

  // This thread will not be able to get the mutex.
  {
    TryLockTestThread thread(&mutex);
    base::PlatformThreadHandle handle;

    ASSERT_TRUE(base::PlatformThread::Create(0, &thread, &handle));

    base::PlatformThread::Join(handle);

    ASSERT_FALSE(thread.got_lock());
  }

  mutex.Unlock();

  // This thread will....
  {
    TryLockTestThread thread(&mutex);
    base::PlatformThreadHandle handle;

    ASSERT_TRUE(base::PlatformThread::Create(0, &thread, &handle));

    base::PlatformThread::Join(handle);

    ASSERT_TRUE(thread.got_lock());
    // But it released it....
    ASSERT_TRUE(mutex.TryLock());
  }

  mutex.Unlock();
}

// Tests that mutexes actually exclude -----------------------------------------

class MutexLockTestThread : public base::PlatformThread::Delegate {
 public:
  MutexLockTestThread(Mutex* mutex, int* value)
      : mutex_(mutex), value_(value) {}

  // Static helper which can also be called from the main thread.
  static void DoStuff(Mutex* mutex, int* value) {
    for (int i = 0; i < 40; i++) {
      mutex->Lock();
      int v = *value;
      EpsilonRandomSleep();
      *value = v + 1;
      mutex->Unlock();
    }
  }

  void ThreadMain() override { DoStuff(mutex_, value_); }

 private:
  Mutex* mutex_;
  int* value_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MutexLockTestThread);
};

TEST(MutexTest, MutexTwoThreads) {
  Mutex mutex;
  int value = 0;

  MutexLockTestThread thread(&mutex, &value);
  base::PlatformThreadHandle handle;

  ASSERT_TRUE(base::PlatformThread::Create(0, &thread, &handle));

  MutexLockTestThread::DoStuff(&mutex, &value);

  base::PlatformThread::Join(handle);

  EXPECT_EQ(2 * 40, value);
}

TEST(MutexTest, MutexFourThreads) {
  Mutex mutex;
  int value = 0;

  MutexLockTestThread thread1(&mutex, &value);
  MutexLockTestThread thread2(&mutex, &value);
  MutexLockTestThread thread3(&mutex, &value);
  base::PlatformThreadHandle handle1;
  base::PlatformThreadHandle handle2;
  base::PlatformThreadHandle handle3;

  ASSERT_TRUE(base::PlatformThread::Create(0, &thread1, &handle1));
  ASSERT_TRUE(base::PlatformThread::Create(0, &thread2, &handle2));
  ASSERT_TRUE(base::PlatformThread::Create(0, &thread3, &handle3));

  MutexLockTestThread::DoStuff(&mutex, &value);

  base::PlatformThread::Join(handle1);
  base::PlatformThread::Join(handle2);
  base::PlatformThread::Join(handle3);

  EXPECT_EQ(4 * 40, value);
}

// MutexLocker -----------------------------------------------------------------

TEST(MutexTest, MutexLocker) {
  Mutex mutex;

  {
    MutexLocker locker(&mutex);
    mutex.AssertHeld();
  }

  // The destruction of |locker| should unlock |mutex|.
  ASSERT_TRUE(mutex.TryLock());
  mutex.AssertHeld();
  mutex.Unlock();
}

}  // namespace
}  // namespace system
}  // namespace mojo
