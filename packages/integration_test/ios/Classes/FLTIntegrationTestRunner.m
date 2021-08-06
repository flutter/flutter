// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTIntegrationTestRunner.h"

#import "IntegrationTestPlugin.h"

@import ObjectiveC.runtime;
@import UIKit;

@interface FLTIntegrationTestRunner ()

@property IntegrationTestPlugin *integrationTestPlugin;

@end

@implementation FLTIntegrationTestRunner

- (instancetype)init {
  self = [super init];
  _integrationTestPlugin = [IntegrationTestPlugin instance];

  return self;
}

- (void)testIntegrationTestWithResults:(NS_NOESCAPE FLTIntegrationTestResults)testResult {
  IntegrationTestPlugin *integrationTestPlugin = self.integrationTestPlugin;
  UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
  if (![rootViewController isKindOfClass:[FlutterViewController class]]) {
    testResult(NSSelectorFromString(@"testSetup"), NO, @"rootViewController was not expected FlutterViewController");
  }
  FlutterViewController *flutterViewController = (FlutterViewController *)rootViewController;
  [integrationTestPlugin setupChannels:flutterViewController.engine.binaryMessenger];

  // Spin the runloop.
  while (!integrationTestPlugin.testResults) {
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  }

  [integrationTestPlugin.testResults enumerateKeysAndObjectsUsingBlock:^(NSString *test, NSString *result, BOOL *stop) {
    // Create an appropriate XCTest method name based on the dart test name.
    // Example: dart test "verify widget" becomes "testVerifyWidget"
    NSString *upperCamelTestName = [test.localizedCapitalizedString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *testSelectorName = [NSString stringWithFormat:@"test%@", upperCamelTestName];
    SEL testSelector = NSSelectorFromString(testSelectorName);

    if ([result isEqualToString:@"success"]) {
      testResult(testSelector, YES, nil);
    } else {
      testResult(testSelector, NO, result);
    }
  }];
}

- (NSDictionary<NSString *,UIImage *> *)capturedScreenshotsByName {
  return self.integrationTestPlugin.capturedScreenshotsByName;
}

@end
