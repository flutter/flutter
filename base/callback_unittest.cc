// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/callback.h"
#include "base/callback_helpers.h"
#include "base/callback_internal.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

struct FakeInvoker {
  typedef void(RunType)(internal::BindStateBase*);
  static void Run(internal::BindStateBase*) {
  }
};

}  // namespace

namespace internal {
template <typename Runnable, typename RunType, typename BoundArgsType>
struct BindState;

// White-box testpoints to inject into a Callback<> object for checking
// comparators and emptiness APIs.  Use a BindState that is specialized
// based on a type we declared in the anonymous namespace above to remove any
// chance of colliding with another instantiation and breaking the
// one-definition-rule.
template <>
struct BindState<void(void), void(void), void(FakeInvoker)>
    : public BindStateBase {
 public:
  BindState() : BindStateBase(&Destroy) {}
  typedef FakeInvoker InvokerType;
 private:
  ~BindState() {}
  static void Destroy(BindStateBase* self) {
    delete static_cast<BindState*>(self);
  }
};

template <>
struct BindState<void(void), void(void),
                           void(FakeInvoker, FakeInvoker)>
    : public BindStateBase {
 public:
  BindState() : BindStateBase(&Destroy) {}
  typedef FakeInvoker InvokerType;
 private:
  ~BindState() {}
  static void Destroy(BindStateBase* self) {
    delete static_cast<BindState*>(self);
  }
};
}  // namespace internal

namespace {

typedef internal::BindState<void(void), void(void), void(FakeInvoker)>
    FakeBindState1;
typedef internal::BindState<void(void), void(void),
                            void(FakeInvoker, FakeInvoker)>
   FakeBindState2;

class CallbackTest : public ::testing::Test {
 public:
  CallbackTest()
      : callback_a_(new FakeBindState1()),
        callback_b_(new FakeBindState2()) {
  }

  ~CallbackTest() override {}

 protected:
  Callback<void(void)> callback_a_;
  const Callback<void(void)> callback_b_;  // Ensure APIs work with const.
  Callback<void(void)> null_callback_;
};

// Ensure we can create unbound callbacks. We need this to be able to store
// them in class members that can be initialized later.
TEST_F(CallbackTest, DefaultConstruction) {
  Callback<void(void)> c0;
  Callback<void(int)> c1;
  Callback<void(int,int)> c2;
  Callback<void(int,int,int)> c3;
  Callback<void(int,int,int,int)> c4;
  Callback<void(int,int,int,int,int)> c5;
  Callback<void(int,int,int,int,int,int)> c6;

  EXPECT_TRUE(c0.is_null());
  EXPECT_TRUE(c1.is_null());
  EXPECT_TRUE(c2.is_null());
  EXPECT_TRUE(c3.is_null());
  EXPECT_TRUE(c4.is_null());
  EXPECT_TRUE(c5.is_null());
  EXPECT_TRUE(c6.is_null());
}

TEST_F(CallbackTest, IsNull) {
  EXPECT_TRUE(null_callback_.is_null());
  EXPECT_FALSE(callback_a_.is_null());
  EXPECT_FALSE(callback_b_.is_null());
}

TEST_F(CallbackTest, Equals) {
  EXPECT_TRUE(callback_a_.Equals(callback_a_));
  EXPECT_FALSE(callback_a_.Equals(callback_b_));
  EXPECT_FALSE(callback_b_.Equals(callback_a_));

  // We should compare based on instance, not type.
  Callback<void(void)> callback_c(new FakeBindState1());
  Callback<void(void)> callback_a2 = callback_a_;
  EXPECT_TRUE(callback_a_.Equals(callback_a2));
  EXPECT_FALSE(callback_a_.Equals(callback_c));

  // Empty, however, is always equal to empty.
  Callback<void(void)> empty2;
  EXPECT_TRUE(null_callback_.Equals(empty2));
}

TEST_F(CallbackTest, Reset) {
  // Resetting should bring us back to empty.
  ASSERT_FALSE(callback_a_.is_null());
  ASSERT_FALSE(callback_a_.Equals(null_callback_));

  callback_a_.Reset();

  EXPECT_TRUE(callback_a_.is_null());
  EXPECT_TRUE(callback_a_.Equals(null_callback_));
}

struct TestForReentrancy {
  TestForReentrancy()
      : cb_already_run(false),
        cb(Bind(&TestForReentrancy::AssertCBIsNull, Unretained(this))) {
  }
  void AssertCBIsNull() {
    ASSERT_TRUE(cb.is_null());
    cb_already_run = true;
  }
  bool cb_already_run;
  Closure cb;
};

TEST_F(CallbackTest, ResetAndReturn) {
  TestForReentrancy tfr;
  ASSERT_FALSE(tfr.cb.is_null());
  ASSERT_FALSE(tfr.cb_already_run);
  ResetAndReturn(&tfr.cb).Run();
  ASSERT_TRUE(tfr.cb.is_null());
  ASSERT_TRUE(tfr.cb_already_run);
}

class CallbackOwner : public base::RefCounted<CallbackOwner> {
 public:
  explicit CallbackOwner(bool* deleted) {
    callback_ = Bind(&CallbackOwner::Unused, this);
    deleted_ = deleted;
  }
  void Reset() {
    callback_.Reset();
    // We are deleted here if no-one else had a ref to us.
  }

 private:
  friend class base::RefCounted<CallbackOwner>;
  virtual ~CallbackOwner() {
    *deleted_ = true;
  }
  void Unused() {
    FAIL() << "Should never be called";
  }

  Closure callback_;
  bool* deleted_;
};

TEST_F(CallbackTest, CallbackHasLastRefOnContainingObject) {
  bool deleted = false;
  CallbackOwner* owner = new CallbackOwner(&deleted);
  owner->Reset();
  ASSERT_TRUE(deleted);
}

}  // namespace
}  // namespace base
