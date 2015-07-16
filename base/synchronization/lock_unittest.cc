// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/synchronization/lock.h"

#include <stdlib.h>

#include "base/compiler_specific.h"
#include "base/threading/platform_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

// Basic test to make sure that Acquire()/Release()/Try() don't crash ----------

class BasicLockTestThread : public PlatformThread::Delegate {
 public:
  explicit BasicLockTestThread(Lock* lock) : lock_(lock), acquired_(0) {}

  void ThreadMain() override {
    for (int i = 0; i < 10; i++) {
      lock_->Acquire();
      acquired_++;
      lock_->Release();
    }
    for (int i = 0; i < 10; i++) {
      lock_->Acquire();
      acquired_++;
      PlatformThread::Sleep(TimeDelta::FromMilliseconds(rand() % 20));
      lock_->Release();
    }
    for (int i = 0; i < 10; i++) {
      if (lock_->Try()) {
        acquired_++;
        PlatformThread::Sleep(TimeDelta::FromMilliseconds(rand() % 20));
        lock_->Release();
      }
    }
  }

  int acquired() const { return acquired_; }

 private:
  Lock* lock_;
  int acquired_;

  DISALLOW_COPY_AND_ASSIGN(BasicLockTestThread);
};

TEST(LockTest, Basic) {
  Lock lock;
  BasicLockTestThread thread(&lock);
  PlatformThreadHandle handle;

  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));

  int acquired = 0;
  for (int i = 0; i < 5; i++) {
    lock.Acquire();
    acquired++;
    lock.Release();
  }
  for (int i = 0; i < 10; i++) {
    lock.Acquire();
    acquired++;
    PlatformThread::Sleep(TimeDelta::FromMilliseconds(rand() % 20));
    lock.Release();
  }
  for (int i = 0; i < 10; i++) {
    if (lock.Try()) {
      acquired++;
      PlatformThread::Sleep(TimeDelta::FromMilliseconds(rand() % 20));
      lock.Release();
    }
  }
  for (int i = 0; i < 5; i++) {
    lock.Acquire();
    acquired++;
    PlatformThread::Sleep(TimeDelta::FromMilliseconds(rand() % 20));
    lock.Release();
  }

  PlatformThread::Join(handle);

  EXPECT_GE(acquired, 20);
  EXPECT_GE(thread.acquired(), 20);
}

// Test that Try() works as expected -------------------------------------------

class TryLockTestThread : public PlatformThread::Delegate {
 public:
  explicit TryLockTestThread(Lock* lock) : lock_(lock), got_lock_(false) {}

  void ThreadMain() override {
    got_lock_ = lock_->Try();
    if (got_lock_)
      lock_->Release();
  }

  bool got_lock() const { return got_lock_; }

 private:
  Lock* lock_;
  bool got_lock_;

  DISALLOW_COPY_AND_ASSIGN(TryLockTestThread);
};

TEST(LockTest, TryLock) {
  Lock lock;

  ASSERT_TRUE(lock.Try());
  // We now have the lock....

  // This thread will not be able to get the lock.
  {
    TryLockTestThread thread(&lock);
    PlatformThreadHandle handle;

    ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));

    PlatformThread::Join(handle);

    ASSERT_FALSE(thread.got_lock());
  }

  lock.Release();

  // This thread will....
  {
    TryLockTestThread thread(&lock);
    PlatformThreadHandle handle;

    ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));

    PlatformThread::Join(handle);

    ASSERT_TRUE(thread.got_lock());
    // But it released it....
    ASSERT_TRUE(lock.Try());
  }

  lock.Release();
}

// Tests that locks actually exclude -------------------------------------------

class MutexLockTestThread : public PlatformThread::Delegate {
 public:
  MutexLockTestThread(Lock* lock, int* value) : lock_(lock), value_(value) {}

  // Static helper which can also be called from the main thread.
  static void DoStuff(Lock* lock, int* value) {
    for (int i = 0; i < 40; i++) {
      lock->Acquire();
      int v = *value;
      PlatformThread::Sleep(TimeDelta::FromMilliseconds(rand() % 10));
      *value = v + 1;
      lock->Release();
    }
  }

  void ThreadMain() override { DoStuff(lock_, value_); }

 private:
  Lock* lock_;
  int* value_;

  DISALLOW_COPY_AND_ASSIGN(MutexLockTestThread);
};

TEST(LockTest, MutexTwoThreads) {
  Lock lock;
  int value = 0;

  MutexLockTestThread thread(&lock, &value);
  PlatformThreadHandle handle;

  ASSERT_TRUE(PlatformThread::Create(0, &thread, &handle));

  MutexLockTestThread::DoStuff(&lock, &value);

  PlatformThread::Join(handle);

  EXPECT_EQ(2 * 40, value);
}

TEST(LockTest, MutexFourThreads) {
  Lock lock;
  int value = 0;

  MutexLockTestThread thread1(&lock, &value);
  MutexLockTestThread thread2(&lock, &value);
  MutexLockTestThread thread3(&lock, &value);
  PlatformThreadHandle handle1;
  PlatformThreadHandle handle2;
  PlatformThreadHandle handle3;

  ASSERT_TRUE(PlatformThread::Create(0, &thread1, &handle1));
  ASSERT_TRUE(PlatformThread::Create(0, &thread2, &handle2));
  ASSERT_TRUE(PlatformThread::Create(0, &thread3, &handle3));

  MutexLockTestThread::DoStuff(&lock, &value);

  PlatformThread::Join(handle1);
  PlatformThread::Join(handle2);
  PlatformThread::Join(handle3);

  EXPECT_EQ(4 * 40, value);
}

}  // namespace base
