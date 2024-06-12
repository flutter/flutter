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
  // Spin the runloop.
  while (!integrationTestPlugin.testResults) {
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
  }

  NSMutableSet<NSString *> *testCaseNames = [[NSMutableSet alloc] init];

  [integrationTestPlugin.testResults enumerateKeysAndObjectsUsingBlock:^(NSString *test, NSString *result, BOOL *stop) {
    NSString *testSelectorName = [[self class] testCaseNameFromDartTestName:test];

    // Validate Objective-C test names are unique after sanitization.
    if ([testCaseNames containsObject:testSelectorName]) {
      NSString *reason = [NSString stringWithFormat:@"Cannot test \"%@\", duplicate XCTestCase tests named %@", test, testSelectorName];
      testResult(NSSelectorFromString(@"testDuplicateTestNames"), NO, reason);
      *stop = YES;
      return;
    }
    [testCaseNames addObject:testSelectorName];
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

+ (NSString *)testCaseNameFromDartTestName:(NSString *)dartTestName {
  NSString *capitalizedString = dartTestName.localizedCapitalizedString;
  // Objective-C method names must be alphanumeric.
  NSCharacterSet *disallowedCharacters = NSCharacterSet.alphanumericCharacterSet.invertedSet;
  // Remove disallowed characters.
  NSString *upperCamelTestName = [[capitalizedString componentsSeparatedByCharactersInSet:disallowedCharacters] componentsJoinedByString:@""];
  return [NSString stringWithFormat:@"test%@", upperCamelTestName];
}

@end
