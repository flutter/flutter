// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
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

}  // namespace testing
}  // namespace impeller
