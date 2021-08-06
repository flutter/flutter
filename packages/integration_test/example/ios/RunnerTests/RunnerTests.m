// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;
@import integration_test;

INTEGRATION_TEST_IOS_RUNNER(RunnerTests)

@interface RunnerTests (DynamicTests)
@end

@implementation RunnerTests (DynamicTests)

- (void)setUp {
  // Verify tests have been dynamically added from FLUTTER_TARGET=integration_test/extended_test.dart
  XCTAssertTrue([self respondsToSelector:NSSelectorFromString(@"testVerifyScreenshot")]);
  XCTAssertTrue([self respondsToSelector:NSSelectorFromString(@"testVerifyText")]);
  XCTAssertTrue([self respondsToSelector:NSSelectorFromString(@"screenshotPlaceholder")]);
}

@end

@interface DeprecatedIntegrationTestIosTests : XCTestCase
@end

@implementation DeprecatedIntegrationTestIosTests

- (void)testIntegrationTest {
  NSString *testResult;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  BOOL testPass = [[IntegrationTestIosTest new] testIntegrationTest:&testResult];
#pragma clang diagnostic pop
  XCTAssertTrue(testPass, @"%@", testResult);
}

@end
