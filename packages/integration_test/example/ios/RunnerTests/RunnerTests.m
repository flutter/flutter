// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;
@import integration_test;

#pragma mark - Dynamic tests

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

#pragma mark - Fake test results

@interface IntegrationTestPlugin ()
- (instancetype)initForRegistration;
@end

@interface FLTIntegrationTestRunner ()
@property IntegrationTestPlugin *integrationTestPlugin;
@end

@interface FakeIntegrationTestPlugin : IntegrationTestPlugin
@property(nonatomic, nullable) NSDictionary<NSString *, NSString *> *testResults;
@end

@implementation FakeIntegrationTestPlugin
@synthesize testResults;

- (void)setupChannels:(id<FlutterBinaryMessenger>)binaryMessenger {
}

@end

#pragma mark - Behavior tests

@interface IntegrationTestTests : XCTestCase
@end

@implementation IntegrationTestTests

- (void)testDeprecatedIntegrationTest {
  NSString *testResult;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  BOOL testPass = [[IntegrationTestIosTest new] testIntegrationTest:&testResult];
#pragma clang diagnostic pop
  XCTAssertTrue(testPass, @"%@", testResult);
}

- (void)testMethodNamesFromDartTests {
  XCTAssertEqualObjects([FLTIntegrationTestRunner
                         testCaseNameFromDartTestName:@"this is a test"], @"testThisIsATest");
  XCTAssertEqualObjects([FLTIntegrationTestRunner
                         testCaseNameFromDartTestName:@"VALIDATE multi-point 🚀 UNICODE123: 😁"], @"testValidateMultiPointUnicode123");
  XCTAssertEqualObjects([FLTIntegrationTestRunner
                         testCaseNameFromDartTestName:@"!UPPERCASE:\\ lower_separate?"], @"testUppercaseLowerSeparate");
}

- (void)testDuplicatedDartTests {
  FakeIntegrationTestPlugin *fakePlugin = [[FakeIntegrationTestPlugin alloc] initForRegistration];
  // These are unique test names in dart, but would result in duplicate
  // XCTestCase names when the emojis are stripped.
  fakePlugin.testResults = @{@"unique": @"dart test failure", @"emoji 🐢": @"success", @"emoji 🐇": @"failure"};

  FLTIntegrationTestRunner *runner = [[FLTIntegrationTestRunner alloc] init];
  runner.integrationTestPlugin = fakePlugin;

  NSMutableDictionary<NSString *, NSString *> *failuresByTestName = [[NSMutableDictionary alloc] init];
  [runner testIntegrationTestWithResults:^(SEL nativeTestSelector, BOOL success, NSString *failureMessage) {
    NSString *testName = NSStringFromSelector(nativeTestSelector);
    XCTAssertFalse([failuresByTestName.allKeys containsObject:testName]);
    failuresByTestName[testName] = failureMessage;
  }];
  XCTAssertEqualObjects(failuresByTestName,
                        (@{@"testUnique": @"dart test failure",
                           @"testDuplicateTestNames": @"Cannot test \"emoji 🐇\", duplicate XCTestCase tests named testEmoji"}));
}

@end
