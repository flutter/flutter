// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/atomic_sequence_num.h"
#include "base/lazy_instance.h"
#include "base/memory/aligned_memory.h"
#include "base/threading/simple_thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

base::StaticAtomicSequenceNumber constructed_seq_;
base::StaticAtomicSequenceNumber destructed_seq_;

class ConstructAndDestructLogger {
 public:
  ConstructAndDestructLogger() {
    constructed_seq_.GetNext();
  }
  ~ConstructAndDestructLogger() {
    destructed_seq_.GetNext();
  }
};

class SlowConstructor {
 public:
  SlowConstructor() : some_int_(0) {
    // Sleep for 1 second to try to cause a race.
    base::PlatformThread::Sleep(base::TimeDelta::FromSeconds(1));
    ++constructed;
    some_int_ = 12;
  }
  int some_int() const { return some_int_; }

  static int constructed;
 private:
  int some_int_;
};

int SlowConstructor::constructed = 0;

class SlowDelegate : public base::DelegateSimpleThread::Delegate {
 public:
  explicit SlowDelegate(base::LazyInstance<SlowConstructor>* lazy)
      : lazy_(lazy) {}

  void Run() override {
    EXPECT_EQ(12, lazy_->Get().some_int());
    EXPECT_EQ(12, lazy_->Pointer()->some_int());
  }

 private:
  base::LazyInstance<SlowConstructor>* lazy_;
};

}  // namespace

static base::LazyInstance<ConstructAndDestructLogger> lazy_logger =
    LAZY_INSTANCE_INITIALIZER;

TEST(LazyInstanceTest, Basic) {
  {
    base::ShadowingAtExitManager shadow;

    EXPECT_EQ(0, constructed_seq_.GetNext());
    EXPECT_EQ(0, destructed_seq_.GetNext());

    lazy_logger.Get();
    EXPECT_EQ(2, constructed_seq_.GetNext());
    EXPECT_EQ(1, destructed_seq_.GetNext());

    lazy_logger.Pointer();
    EXPECT_EQ(3, constructed_seq_.GetNext());
    EXPECT_EQ(2, destructed_seq_.GetNext());
  }
  EXPECT_EQ(4, constructed_seq_.GetNext());
  EXPECT_EQ(4, destructed_seq_.GetNext());
}

static base::LazyInstance<SlowConstructor> lazy_slow =
    LAZY_INSTANCE_INITIALIZER;

TEST(LazyInstanceTest, ConstructorThreadSafety) {
  {
    base::ShadowingAtExitManager shadow;

    SlowDelegate delegate(&lazy_slow);
    EXPECT_EQ(0, SlowConstructor::constructed);

    base::DelegateSimpleThreadPool pool("lazy_instance_cons", 5);
    pool.AddWork(&delegate, 20);
    EXPECT_EQ(0, SlowConstructor::constructed);

    pool.Start();
    pool.JoinAll();
    EXPECT_EQ(1, SlowConstructor::constructed);
  }
}

namespace {

// DeleteLogger is an object which sets a flag when it's destroyed.
// It accepts a bool* and sets the bool to true when the dtor runs.
class DeleteLogger {
 public:
  DeleteLogger() : deleted_(NULL) {}
  ~DeleteLogger() { *deleted_ = true; }

  void SetDeletedPtr(bool* deleted) {
    deleted_ = deleted;
  }

 private:
  bool* deleted_;
};

}  // anonymous namespace

TEST(LazyInstanceTest, LeakyLazyInstance) {
  // Check that using a plain LazyInstance causes the dtor to run
  // when the AtExitManager finishes.
  bool deleted1 = false;
  {
    base::ShadowingAtExitManager shadow;
    static base::LazyInstance<DeleteLogger> test = LAZY_INSTANCE_INITIALIZER;
    test.Get().SetDeletedPtr(&deleted1);
  }
  EXPECT_TRUE(deleted1);

  // Check that using a *leaky* LazyInstance makes the dtor not run
  // when the AtExitManager finishes.
  bool deleted2 = false;
  {
    base::ShadowingAtExitManager shadow;
    static base::LazyInstance<DeleteLogger>::Leaky
        test = LAZY_INSTANCE_INITIALIZER;
    test.Get().SetDeletedPtr(&deleted2);
  }
  EXPECT_FALSE(deleted2);
}

namespace {

template <size_t alignment>
class AlignedData {
 public:
  AlignedData() {}
  ~AlignedData() {}
  base::AlignedMemory<alignment, alignment> data_;
};

}  // anonymous namespace

#define EXPECT_ALIGNED(ptr, align) \
    EXPECT_EQ(0u, reinterpret_cast<uintptr_t>(ptr) & (align - 1))

TEST(LazyInstanceTest, Alignment) {
  using base::LazyInstance;

  // Create some static instances with increasing sizes and alignment
  // requirements. By ordering this way, the linker will need to do some work to
  // ensure proper alignment of the static data.
  static LazyInstance<AlignedData<4> > align4 = LAZY_INSTANCE_INITIALIZER;
  static LazyInstance<AlignedData<32> > align32 = LAZY_INSTANCE_INITIALIZER;
  static LazyInstance<AlignedData<4096> > align4096 = LAZY_INSTANCE_INITIALIZER;

  EXPECT_ALIGNED(align4.Pointer(), 4);
  EXPECT_ALIGNED(align32.Pointer(), 32);
  EXPECT_ALIGNED(align4096.Pointer(), 4096);
}
