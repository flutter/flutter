// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>

#include "base/test/perf_log.h"
#include "mojo/edk/system/ref_counted.h"
#include "mojo/edk/system/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

class MyClass : public RefCountedThreadSafe<MyClass> {
 public:
  static RefPtr<MyClass> Create() {
    return RefPtr<MyClass>(AdoptRef(new MyClass()));
  }

 private:
  friend class RefCountedThreadSafe<MyClass>;

  MyClass() {}
  ~MyClass() {}
};

TEST(RefCountedPerfTest, OneThreadCreateAdoptDestroy) {
  uint64_t iterations = 0;
  test::Stopwatch stopwatch;
  stopwatch.Start();
  do {
    for (size_t i = 0; i < 1000; i++, iterations++) {
      RefPtr<MyClass> x = MyClass::Create();
      x = nullptr;
    }
    iterations++;
  } while (stopwatch.Elapsed() < test::DeadlineFromMilliseconds(1000));
  double elapsed = stopwatch.Elapsed() / 1000000.0;

  base::LogPerfResult("OneThreadCreateAdoptDestroy", iterations / elapsed,
                      "iterations/s");
}

TEST(RefCountedPerfTest, OneThreadAssignRefPtr) {
  RefPtr<MyClass> x = MyClass::Create();
  uint64_t iterations = 0;
  test::Stopwatch stopwatch;
  stopwatch.Start();
  do {
    for (size_t i = 0; i < 1000; i++, iterations++) {
      RefPtr<MyClass> y = x;
    }
    iterations++;
  } while (stopwatch.Elapsed() < test::DeadlineFromMilliseconds(1000));
  double elapsed = stopwatch.Elapsed() / 1000000.0;

  base::LogPerfResult("OneThreadAssignRefPtr", iterations / elapsed,
                      "iterations/s");
}

// TODO(vtl): Add threaded perf tests.

}  // namespace
}  // namespace system
}  // namespace mojo
