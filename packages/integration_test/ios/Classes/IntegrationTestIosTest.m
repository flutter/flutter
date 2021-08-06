// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "IntegrationTestIosTest.h"

#import "IntegrationTestPlugin.h"

@import UIKit;

@interface IntegrationTestIosTest ()

@property IntegrationTestPlugin *integrationTestPlugin;

@end

@implementation IntegrationTestIosTest

- (instancetype)init {
  self = [super init];
  _integrationTestPlugin = [IntegrationTestPlugin instance];

  return self;
}

- (void)testIntegrationTestWithResults:(FLTIntegrationTestResults)testResult {
  IntegrationTestPlugin *integrationTestPlugin = self.integrationTestPlugin;
  UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
  if (![rootViewController isKindOfClass:[FlutterViewController class]]) {
    testResult(@"setup", NO, @"rootViewController was not expected FlutterViewController");
  }
  FlutterViewController *flutterViewController = (FlutterViewController *)rootViewController;
  [integrationTestPlugin setupChannels:flutterViewController.engine.binaryMessenger];

  // Spin the runloop.
  while (!integrationTestPlugin.testResults) {
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  }

  [integrationTestPlugin.testResults enumerateKeysAndObjectsUsingBlock:^(NSString *test, NSString *result, BOOL *stop) {
    if ([result isEqualToString:@"success"]) {
      testResult(test, YES, nil);
    } else {
      testResult(test, NO, result);
    }
  }];
}

- (NSDictionary<NSString *,UIImage *> *)capturedScreenshotsByName {
  return self.integrationTestPlugin.capturedScreenshotsByName;
}

#pragma mark - Deprecated

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)testIntegrationTest:(NSString **)testResult {
  NSLog(@"==================== Test Results =====================");
  NSMutableArray<NSString *> *failedTests = [NSMutableArray array];
  NSMutableArray<NSString *> *testNames = [NSMutableArray array];
  [self testIntegrationTestWithResults:^(NSString *testName, BOOL success, NSString *message) {
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
#pragma clang diagnostic pop

@end
