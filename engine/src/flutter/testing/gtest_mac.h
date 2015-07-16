// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TESTING_GTEST_MAC_H_
#define TESTING_GTEST_MAC_H_

#include <gtest/internal/gtest-port.h>
#include <gtest/gtest.h>

#ifdef GTEST_OS_MAC

#import <Foundation/Foundation.h>

namespace testing {
namespace internal {

// This overloaded version allows comparison between ObjC objects that conform
// to the NSObject protocol. Used to implement {ASSERT|EXPECT}_EQ().
GTEST_API_ AssertionResult CmpHelperNSEQ(const char* expected_expression,
                                         const char* actual_expression,
                                         id<NSObject> expected,
                                         id<NSObject> actual);

// This overloaded version allows comparison between ObjC objects that conform
// to the NSObject protocol. Used to implement {ASSERT|EXPECT}_NE().
GTEST_API_ AssertionResult CmpHelperNSNE(const char* expected_expression,
                                         const char* actual_expression,
                                         id<NSObject> expected,
                                         id<NSObject> actual);

}  // namespace internal
}  // namespace testing

// Tests that [expected isEqual:actual].
#define EXPECT_NSEQ(expected, actual) \
  EXPECT_PRED_FORMAT2(::testing::internal::CmpHelperNSEQ, expected, actual)
#define EXPECT_NSNE(val1, val2) \
  EXPECT_PRED_FORMAT2(::testing::internal::CmpHelperNSNE, val1, val2)

#define ASSERT_NSEQ(expected, actual) \
  ASSERT_PRED_FORMAT2(::testing::internal::CmpHelperNSEQ, expected, actual)
#define ASSERT_NSNE(val1, val2) \
  ASSERT_PRED_FORMAT2(::testing::internal::CmpHelperNSNE, val1, val2)

#endif  // GTEST_OS_MAC

#endif  // TESTING_GTEST_MAC_H_
