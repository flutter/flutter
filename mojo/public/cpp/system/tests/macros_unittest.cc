// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file tests the C++ Mojo system macros and consists of "positive" tests,
// i.e., those verifying that things work (without compile errors, or even
// warnings if warnings are treated as errors).
// TODO(vtl): Maybe rename "MacrosCppTest" -> "MacrosTest" if/when this gets
// compiled into a different binary from the C API tests.
// TODO(vtl): Fix no-compile tests (which are all disabled; crbug.com/105388)
// and write some "negative" tests.

#include "mojo/public/cpp/system/macros.h"

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {

// The test for |MOJO_STATIC_CONST_MEMBER_DEFINITION| is really a compile/link
// test. To test it fully would really require a header file and multiple .cc
// files, but we'll just cursorily verify it.
//
// This is defined outside of an anonymous namespace because
// MOJO_STATIC_CONST_MEMBER_DEFINITION may not be used on internal symbols.
struct StructWithStaticConstMember {
  static const int kStaticConstMember = 123;
};
MOJO_STATIC_CONST_MEMBER_DEFINITION
const int StructWithStaticConstMember::kStaticConstMember;

namespace {

// Note: MSVS is very strict (and arguably buggy) about warnings for classes
// defined in a local scope, so define these globally.
struct TestOverrideBaseClass {
  virtual ~TestOverrideBaseClass() {}
  virtual void ToBeOverridden() {}
  virtual void AlsoToBeOverridden() = 0;
};

struct TestOverrideSubclass : public TestOverrideBaseClass {
  ~TestOverrideSubclass() override {}
  void ToBeOverridden() override {}
  void AlsoToBeOverridden() override {}
};

TEST(MacrosCppTest, Override) {
  TestOverrideSubclass x;
  x.ToBeOverridden();
  x.AlsoToBeOverridden();
}

// Note: MSVS is very strict (and arguably buggy) about warnings for classes
// defined in a local scope, so define these globally.
class TestDisallowCopyAndAssignClass {
 public:
  TestDisallowCopyAndAssignClass() {}
  explicit TestDisallowCopyAndAssignClass(int) {}
  void NoOp() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(TestDisallowCopyAndAssignClass);
};

TEST(MacrosCppTest, DisallowCopyAndAssign) {
  TestDisallowCopyAndAssignClass x;
  x.NoOp();
  TestDisallowCopyAndAssignClass y(789);
  y.NoOp();
}

// Test that |MOJO_ARRAYSIZE()| works in a |static_assert()|.
const int kGlobalArray[5] = {1, 2, 3, 4, 5};
static_assert(MOJO_ARRAYSIZE(kGlobalArray) == 5u,
              "MOJO_ARRAY_SIZE() failed in static_assert()");

TEST(MacrosCppTest, ArraySize) {
  double local_array[4] = {6.7, 7.8, 8.9, 9.0};
  // MSVS considers this local variable unused since MOJO_ARRAYSIZE only takes
  // the size of the type of the local and not the values itself.
  MOJO_ALLOW_UNUSED_LOCAL(local_array);
  EXPECT_EQ(4u, MOJO_ARRAYSIZE(local_array));
}

// Note: MSVS is very strict (and arguably buggy) about warnings for classes
// defined in a local scope, so define these globally.
class MoveOnlyInt {
  MOJO_MOVE_ONLY_TYPE(MoveOnlyInt)

 public:
  MoveOnlyInt() : is_set_(false), value_() {}
  explicit MoveOnlyInt(int value) : is_set_(true), value_(value) {}
  ~MoveOnlyInt() {}

  // Move-only constructor and operator=.
  MoveOnlyInt(MoveOnlyInt&& other) { *this = other.Pass(); }
  MoveOnlyInt& operator=(MoveOnlyInt&& other) {
    if (&other != this) {
      is_set_ = other.is_set_;
      value_ = other.value_;
      other.is_set_ = false;
    }
    return *this;
  }

  int value() const {
    assert(is_set());
    return value_;
  }
  bool is_set() const { return is_set_; }

 private:
  bool is_set_;
  int value_;
};

TEST(MacrosCppTest, MoveOnlyType) {
  MoveOnlyInt x(123);
  EXPECT_TRUE(x.is_set());
  EXPECT_EQ(123, x.value());
  MoveOnlyInt y;
  EXPECT_FALSE(y.is_set());
  y = x.Pass();
  EXPECT_FALSE(x.is_set());
  EXPECT_TRUE(y.is_set());
  EXPECT_EQ(123, y.value());
  MoveOnlyInt z(y.Pass());
  EXPECT_FALSE(y.is_set());
  EXPECT_TRUE(z.is_set());
  EXPECT_EQ(123, z.value());
  z = z.Pass();
  EXPECT_TRUE(z.is_set());
  EXPECT_EQ(123, z.value());
}

// Use it, to make sure things get linked in and to avoid any warnings about
// unused things.
TEST(MacrosCppTest, StaticConstMemberDefinition) {
  EXPECT_EQ(123, StructWithStaticConstMember::kStaticConstMember);
}

// The test for |ignore_result()| is also just a compilation test. (Note that
// |MOJO_WARN_UNUSED_RESULT| can only be used in the prototype.
int ReturnsIntYouMustUse() MOJO_WARN_UNUSED_RESULT;

int ReturnsIntYouMustUse() {
  return 123;
}

TEST(MacrosCppTest, IgnoreResult) {
  ignore_result(ReturnsIntYouMustUse());
}

}  // namespace
}  // namespace mojo
