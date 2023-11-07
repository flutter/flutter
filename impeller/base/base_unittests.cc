// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/base/strings.h"
#include "impeller/base/thread.h"

namespace impeller {
namespace testing {

struct Foo {
  Mutex mtx;
  int a IPLR_GUARDED_BY(mtx);
};

struct RWFoo {
  RWMutex mtx;
  int a IPLR_GUARDED_BY(mtx);
};

TEST(ThreadTest, CanCreateMutex) {
  Foo f = {};

  // f.a = 100; <--- Static analysis error.
  f.mtx.Lock();
  f.a = 100;
  f.mtx.Unlock();
}

TEST(ThreadTest, CanCreateMutexLock) {
  Foo f = {};

  // f.a = 100; <--- Static analysis error.
  auto a = Lock(f.mtx);
  f.a = 100;
}

TEST(ThreadTest, CanCreateRWMutex) {
  RWFoo f = {};

  // f.a = 100; <--- Static analysis error.
  f.mtx.LockWriter();
  f.a = 100;
  f.mtx.UnlockWriter();
  // int b = f.a; <--- Static analysis error.
  f.mtx.LockReader();
  int b = f.a;  // NOLINT(clang-analyzer-deadcode.DeadStores)
  FML_ALLOW_UNUSED_LOCAL(b);
  f.mtx.UnlockReader();
}

TEST(ThreadTest, CanCreateRWMutexLock) {
  RWFoo f = {};

  // f.a = 100; <--- Static analysis error.
  {
    auto write_lock = WriterLock{f.mtx};
    f.a = 100;
  }

  // int b = f.a; <--- Static analysis error.
  {
    auto read_lock = ReaderLock(f.mtx);
    int b = f.a;  // NOLINT(clang-analyzer-deadcode.DeadStores)
    FML_ALLOW_UNUSED_LOCAL(b);
  }

  // f.mtx.UnlockReader(); <--- Static analysis error.
}

TEST(StringsTest, CanSPrintF) {
  ASSERT_EQ(SPrintF("%sx%d", "Hello", 12), "Hellox12");
  ASSERT_EQ(SPrintF(""), "");
  ASSERT_EQ(SPrintF("Hello"), "Hello");
  ASSERT_EQ(SPrintF("%sx%.2f", "Hello", 12.122222), "Hellox12.12");
}

struct CVTest {
  Mutex mutex;
  ConditionVariable cv;
  uint32_t rando_ivar IPLR_GUARDED_BY(mutex) = 0;
};

TEST(ConditionVariableTest, WaitUntil) {
  CVTest test;
  // test.rando_ivar = 12; // <--- Static analysis error
  for (size_t i = 0; i < 2; ++i) {
    test.mutex.Lock();  // <--- Static analysis error without this.
    auto result = test.cv.WaitUntil(
        test.mutex,
        std::chrono::high_resolution_clock::now() +
            std::chrono::milliseconds{10},
        [&]() IPLR_REQUIRES(test.mutex) {
          test.rando_ivar = 12;  // <-- Static analysics error without the
                                 // IPLR_REQUIRES on the pred.
          return false;
        });
    test.mutex.Unlock();
    ASSERT_FALSE(result);
  }
  Lock lock(test.mutex);  // <--- Static analysis error without this.
  // The predicate never returns true. So return has to be due to a non-spurious
  // wake.
  ASSERT_EQ(test.rando_ivar, 12u);
}

TEST(ConditionVariableTest, WaitFor) {
  CVTest test;
  // test.rando_ivar = 12; // <--- Static analysis error
  for (size_t i = 0; i < 2; ++i) {
    test.mutex.Lock();  // <--- Static analysis error without this.
    auto result = test.cv.WaitFor(
        test.mutex, std::chrono::milliseconds{10},
        [&]() IPLR_REQUIRES(test.mutex) {
          test.rando_ivar = 12;  // <-- Static analysics error without the
                                 // IPLR_REQUIRES on the pred.
          return false;
        });
    test.mutex.Unlock();
    ASSERT_FALSE(result);
  }
  Lock lock(test.mutex);  // <--- Static analysis error without this.
  // The predicate never returns true. So return has to be due to a non-spurious
  // wake.
  ASSERT_EQ(test.rando_ivar, 12u);
}

TEST(ConditionVariableTest, WaitForever) {
  CVTest test;
  // test.rando_ivar = 12; // <--- Static analysis error
  for (size_t i = 0; i < 2; ++i) {
    test.mutex.Lock();  // <--- Static analysis error without this.
    test.cv.Wait(test.mutex, [&]() IPLR_REQUIRES(test.mutex) {
      test.rando_ivar = 12;  // <-- Static analysics error without
                             // the IPLR_REQUIRES on the pred.
      return true;
    });
    test.mutex.Unlock();
  }
  Lock lock(test.mutex);  // <--- Static analysis error without this.
  // The wake only happens when the predicate returns true.
  ASSERT_EQ(test.rando_ivar, 12u);
}

}  // namespace testing
}  // namespace impeller
