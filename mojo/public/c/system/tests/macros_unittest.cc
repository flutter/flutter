// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file tests the C Mojo system macros and consists of "positive" tests,
// i.e., those verifying that things work (without compile errors, or even
// warnings if warnings are treated as errors).
// TODO(vtl): Fix no-compile tests (which are all disabled; crbug.com/105388)
// and write some "negative" tests.

#include "mojo/public/c/system/macros.h"

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

TEST(MacrosTest, AllowUnused) {
  // Test that no warning/error is issued even though |x| is unused.
  int x = 123;
  MOJO_ALLOW_UNUSED_LOCAL(x);
}

int MustUseReturnedResult() MOJO_WARN_UNUSED_RESULT;
int MustUseReturnedResult() {
  return 456;
}

TEST(MacrosTest, WarnUnusedResult) {
  if (!MustUseReturnedResult())
    abort();
}

// First test |MOJO_STATIC_ASSERT()| in a global scope.
MOJO_STATIC_ASSERT(sizeof(int64_t) == 2 * sizeof(int32_t),
                   "Bad static_assert() failure in global scope");

TEST(MacrosTest, CompileAssert) {
  // Then in a local scope.
  MOJO_STATIC_ASSERT(sizeof(int32_t) == 2 * sizeof(int16_t),
                     "Bad static_assert() failure");
}

TEST(MacrosTest, Alignof) {
  // Strictly speaking, this isn't a portable test, but I think it'll pass on
  // all the platforms we currently support.
  EXPECT_EQ(1u, MOJO_ALIGNOF(char));
  EXPECT_EQ(4u, MOJO_ALIGNOF(int32_t));
  EXPECT_EQ(8u, MOJO_ALIGNOF(int64_t));
  EXPECT_EQ(8u, MOJO_ALIGNOF(double));
}

// These structs are used in the Alignas test. Define them globally to avoid
// MSVS warnings/errors.
#if defined(_MSC_VER)
#pragma warning(push)
// Disable the warning "structure was padded due to __declspec(align())".
#pragma warning(disable : 4324)
#endif
struct MOJO_ALIGNAS(1) StructAlignas1 {
  char x;
};
struct MOJO_ALIGNAS(4) StructAlignas4 {
  char x;
};
struct MOJO_ALIGNAS(8) StructAlignas8 {
  char x;
};
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

TEST(MacrosTest, Alignas) {
  EXPECT_EQ(1u, MOJO_ALIGNOF(StructAlignas1));
  EXPECT_EQ(4u, MOJO_ALIGNOF(StructAlignas4));
  EXPECT_EQ(8u, MOJO_ALIGNOF(StructAlignas8));
}

}  // namespace
}  // namespace mojo
