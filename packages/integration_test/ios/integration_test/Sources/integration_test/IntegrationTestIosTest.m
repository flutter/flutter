// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "IntegrationTestIosTest.h"

#import "IntegrationTestPlugin.h"
#import "FLTIntegrationTestRunner.h"

#pragma mark - Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@implementation IntegrationTestIosTest

- (BOOL)testIntegrationTest:(NSString **)testResult {
  NSLog(@"==================== Test Results =====================");
  NSMutableArray<NSString *> *failedTests = [NSMutableArray array];
  NSMutableArray<NSString *> *testNames = [NSMutableArray array];
  [[FLTIntegrationTestRunner new] testIntegrationTestWithResults:^(SEL testSelector, BOOL success, NSString *message) {
    NSString *testName = NSStringFromSelector(testSelector);
    [testNames addObject:testName];
    if (success) {
      NSLog(@"%@ passed.", testName);
    } else {
      NSLog(@"%@ failed: %@", testName, message);
      [failedTests addObject:testName];
    }
  }];
  NSLog(@"================== Test Results End ====================");
  BOOL testPass = failedTests.count == 0;
  if (!testPass && testResult != NULL) {
    *testResult =
        [NSString stringWithFormat:@"Detected failed integration test(s) %@ among %@",
                                   failedTests.description, testNames.description];
  }
  return testPass;
}

@end
#pragma clang diagnostic pop
