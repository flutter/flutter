// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// XCTest is weakly linked.
#if __has_include(<XCTest/XCTest.h>)

@import XCTest;

NS_ASSUME_NONNULL_BEGIN

@interface FLTIntegrationTestCase : XCTestCase
@end

/*!
 Deprecated. Prefer directly inheriting from @c FLTIntegrationTestCase
 */
#define INTEGRATION_TEST_IOS_RUNNER(__test_class)                                           \
  @interface __test_class : FLTIntegrationTestCase                                          \
  @end                                                                                      \
                                                                                            \
  @implementation __test_class                                                              \
  @end

NS_ASSUME_NONNULL_END

#endif
