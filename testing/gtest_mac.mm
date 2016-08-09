// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "gtest_mac.h"

#include <string>

#include <gtest/gtest.h>
#include <gtest/internal/gtest-port.h>
#include <gtest/internal/gtest-string.h>

#ifdef GTEST_OS_MAC

#import <Foundation/Foundation.h>

namespace testing {
namespace internal {

// Handles nil values for |obj| properly by using safe printing of %@ in
// -stringWithFormat:.
static inline const char* StringDescription(id<NSObject> obj) {
  return [[NSString stringWithFormat:@"%@", obj] UTF8String];
}

// This overloaded version allows comparison between ObjC objects that conform
// to the NSObject protocol. Used to implement {ASSERT|EXPECT}_EQ().
GTEST_API_ AssertionResult CmpHelperNSEQ(const char* expected_expression,
                                         const char* actual_expression,
                                         id<NSObject> expected,
                                         id<NSObject> actual) {
  if (expected == actual || [expected isEqual:actual]) {
    return AssertionSuccess();
  }
  return EqFailure(expected_expression,
                   actual_expression,
                   std::string(StringDescription(expected)),
                   std::string(StringDescription(actual)),
                   false);
}

// This overloaded version allows comparison between ObjC objects that conform
// to the NSObject protocol. Used to implement {ASSERT|EXPECT}_NE().
GTEST_API_ AssertionResult CmpHelperNSNE(const char* expected_expression,
                                         const char* actual_expression,
                                         id<NSObject> expected,
                                         id<NSObject> actual) {
  if (expected != actual && ![expected isEqual:actual]) {
    return AssertionSuccess();
  }
  Message msg;
  msg << "Expected: (" << expected_expression << ") != (" << actual_expression
      << "), actual: " << StringDescription(expected)
      << " vs " << StringDescription(actual);
  return AssertionFailure(msg);
}

#if !defined(GTEST_OS_IOS)

GTEST_API_ AssertionResult CmpHelperNSEQ(const char* expected_expression,
                                         const char* actual_expression,
                                         const NSRect& expected,
                                         const NSRect& actual) {
  if (NSEqualRects(expected, actual)) {
    return AssertionSuccess();
  }
  return EqFailure(expected_expression,
                   actual_expression,
                   [NSStringFromRect(expected) UTF8String],
                   [NSStringFromRect(actual) UTF8String],
                   false);

}

GTEST_API_ AssertionResult CmpHelperNSNE(const char* expected_expression,
                                         const char* actual_expression,
                                         const NSRect& expected,
                                         const NSRect& actual) {
  if (!NSEqualRects(expected, actual)) {
    return AssertionSuccess();
  }
  Message msg;
  msg << "Expected: (" << expected_expression << ") != (" << actual_expression
      << "), actual: " << [NSStringFromRect(expected) UTF8String]
      << " vs " << [NSStringFromRect(actual) UTF8String];
  return AssertionFailure(msg);

}

GTEST_API_ AssertionResult CmpHelperNSEQ(const char* expected_expression,
                                         const char* actual_expression,
                                         const NSPoint& expected,
                                         const NSPoint& actual) {
  if (NSEqualPoints(expected, actual)) {
    return AssertionSuccess();
  }
  return EqFailure(expected_expression,
                   actual_expression,
                   [NSStringFromPoint(expected) UTF8String],
                   [NSStringFromPoint(actual) UTF8String],
                   false);

}

GTEST_API_ AssertionResult CmpHelperNSNE(const char* expected_expression,
                                         const char* actual_expression,
                                         const NSPoint& expected,
                                         const NSPoint& actual) {
  if (!NSEqualPoints(expected, actual)) {
    return AssertionSuccess();
  }
  Message msg;
  msg << "Expected: (" << expected_expression << ") != (" << actual_expression
      << "), actual: " << [NSStringFromPoint(expected) UTF8String]
      << " vs " << [NSStringFromPoint(actual) UTF8String];
  return AssertionFailure(msg);

}

#endif  // !GTEST_OS_IOS

}  // namespace internal
}  // namespace testing

#endif  // GTEST_OS_MAC
