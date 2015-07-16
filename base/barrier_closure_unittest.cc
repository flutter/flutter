// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/barrier_closure.h"

#include "base/bind.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

void Increment(int* count) { (*count)++; }

TEST(BarrierClosureTest, RunImmediatelyForZeroClosures) {
  int count = 0;
  base::Closure done_closure(base::Bind(&Increment, base::Unretained(&count)));

  base::Closure barrier_closure = base::BarrierClosure(0, done_closure);
  EXPECT_EQ(1, count);
}

TEST(BarrierClosureTest, RunAfterNumClosures) {
  int count = 0;
  base::Closure done_closure(base::Bind(&Increment, base::Unretained(&count)));

  base::Closure barrier_closure = base::BarrierClosure(2, done_closure);
  EXPECT_EQ(0, count);

  barrier_closure.Run();
  EXPECT_EQ(0, count);

  barrier_closure.Run();
  EXPECT_EQ(1, count);
}

class DestructionIndicator {
 public:
  // Sets |*destructed| to true in destructor.
  DestructionIndicator(bool* destructed) : destructed_(destructed) {
    *destructed_ = false;
  }

  ~DestructionIndicator() { *destructed_ = true; }

  void DoNothing() {}

 private:
  bool* destructed_;
};

TEST(BarrierClosureTest, ReleasesDoneClosureWhenDone) {
  bool done_destructed = false;
  base::Closure barrier_closure = base::BarrierClosure(
      1, base::Bind(&DestructionIndicator::DoNothing,
                    base::Owned(new DestructionIndicator(&done_destructed))));
  EXPECT_FALSE(done_destructed);
  barrier_closure.Run();
  EXPECT_TRUE(done_destructed);
}

void ResetBarrierClosure(base::Closure* closure) {
  *closure = base::Closure();
}

// Tests a case when |done_closure| resets a |barrier_closure|.
// |barrier_closure| is a Closure holding the |done_closure|. |done_closure|
// holds a pointer back to the |barrier_closure|. When |barrier_closure| is
// Run() it calls ResetBarrierClosure() which erases the |barrier_closure| while
// still inside of its Run(). The Run() implementation (in base::BarrierClosure)
// must not try use itself after executing ResetBarrierClosure() or this test
// would crash inside Run().
TEST(BarrierClosureTest, KeepingClosureAliveUntilDone) {
  base::Closure barrier_closure;
  base::Closure done_closure =
      base::Bind(ResetBarrierClosure, &barrier_closure);
  barrier_closure = base::BarrierClosure(1, done_closure);
  barrier_closure.Run();
}

}  // namespace
