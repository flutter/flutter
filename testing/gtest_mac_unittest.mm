// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note that while this file is in testing/ and tests GTest macros, it is built
// as part of Chromium's unit_tests target because the project does not build
// or run GTest's internal test suite.

#import "testing/gtest_mac.h"

#import <Foundation/Foundation.h>

#include "base/mac/scoped_nsautorelease_pool.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/gtest/include/gtest/internal/gtest-port.h"

TEST(GTestMac, ExpectNSEQ) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSEQ(@"a", @"a");

  NSString* s1 = [NSString stringWithUTF8String:"a"];
  NSString* s2 = @"a";
  EXPECT_NE(s1, s2);
  EXPECT_NSEQ(s1, s2);
}

TEST(GTestMac, AssertNSEQ) {
  base::mac::ScopedNSAutoreleasePool pool;

  NSString* s1 = [NSString stringWithUTF8String:"a"];
  NSString* s2 = @"a";
  EXPECT_NE(s1, s2);
  ASSERT_NSEQ(s1, s2);
}

TEST(GTestMac, ExpectNSNE) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSNE([NSNumber numberWithInt:2], [NSNumber numberWithInt:42]);
}

TEST(GTestMac, AssertNSNE) {
  base::mac::ScopedNSAutoreleasePool pool;

  ASSERT_NSNE(@"a", @"b");
}

TEST(GTestMac, ExpectNSNil) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSEQ(nil, nil);
  EXPECT_NSNE(nil, @"a");
  EXPECT_NSNE(@"a", nil);

  // TODO(shess): Test that EXPECT_NSNE(nil, nil) fails.
}

#if !defined(GTEST_OS_IOS)

TEST(GTestMac, ExpectNSEQRect) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSEQ(NSMakeRect(1, 2, 3, 4), NSMakeRect(1, 2, 3, 4));
}

TEST(GTestMac, AssertNSEQRect) {
  base::mac::ScopedNSAutoreleasePool pool;

  ASSERT_NSEQ(NSMakeRect(1, 2, 3, 4), NSMakeRect(1, 2, 3, 4));
}

TEST(GTestMac, ExpectNSNERect) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSNE(NSMakeRect(1, 2, 3, 4), NSMakeRect(5, 6, 7, 8));
}

TEST(GTestMac, AssertNSNERect) {
  base::mac::ScopedNSAutoreleasePool pool;

  ASSERT_NSNE(NSMakeRect(1, 2, 3, 4), NSMakeRect(5, 6, 7, 8));
}

TEST(GTestMac, ExpectNSEQPoint) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSEQ(NSMakePoint(1, 2), NSMakePoint(1, 2));
}

TEST(GTestMac, AssertNSEQPoint) {
  base::mac::ScopedNSAutoreleasePool pool;

  ASSERT_NSEQ(NSMakePoint(1, 2), NSMakePoint(1, 2));
}

TEST(GTestMac, ExpectNSNEPoint) {
  base::mac::ScopedNSAutoreleasePool pool;

  EXPECT_NSNE(NSMakePoint(1, 2), NSMakePoint(3, 4));
}

TEST(GTestMac, AssertNSNEPoint) {
  base::mac::ScopedNSAutoreleasePool pool;

  ASSERT_NSNE(NSMakePoint(1, 2), NSMakePoint(3, 4));
}

#endif  // !GTEST_OS_IOS
