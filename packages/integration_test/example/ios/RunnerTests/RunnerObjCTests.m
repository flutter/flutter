// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import integration_test;
@import XCTest;

// Test without macro.
@interface RunnerObjCTests : FLTIntegrationTestCase
@end

@implementation RunnerObjCTests

+ (NSArray<NSInvocation *> *)testInvocations {
  // Add a test to verify the Flutter dart tests have been dynamically added to this test case.
  SEL selector = @selector(testDynamicTestMethods);
  NSMethodSignature *signature = [self instanceMethodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.selector = selector;

  return [super.testInvocations arrayByAddingObject:invocation];
}

- (void)testDynamicTestMethods {
  XCTAssertTrue([self respondsToSelector:NSSelectorFromString(@"testVerifyScreenshot")]);
  XCTAssertTrue([self respondsToSelector:NSSelectorFromString(@"testVerifyText")]);
  XCTAssertTrue([self respondsToSelector:NSSelectorFromString(@"screenshotPlaceholder")]);
}

@end

// Test deprecated macro. Do not use.
INTEGRATION_TEST_IOS_RUNNER(RunnerObjCMacroTests)

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
