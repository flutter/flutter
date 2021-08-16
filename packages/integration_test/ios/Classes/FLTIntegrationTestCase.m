// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// XCTest is weakly linked.
#if __has_include(<XCTest/XCTest.h>)

#import "FLTIntegrationTestCase.h"

#import "FLTIntegrationTestRunner.h"
#import "IntegrationTestPlugin.h"

@import ObjectiveC.runtime;
@import XCTest;

@implementation FLTIntegrationTestCase

+ (NSArray<NSInvocation *> *)testInvocations {
  if (self == [FLTIntegrationTestCase class]) {
    // Do not add any tests for this base class.
    return @[];
  }
  FLTIntegrationTestRunner *integrationTestRunner = [FLTIntegrationTestRunner new];
  NSMutableArray<NSInvocation *> *testInvocations = [NSMutableArray new];
  [integrationTestRunner testIntegrationTestWithResults:^(NSString *testName, BOOL success, NSString *failureMessage) {
    // For every Flutter dart test, dynamically generate an Objective-C method mirroring the test results
    // so it is reported as a native XCTest run result.
    IMP assertImplementation = imp_implementationWithBlock(^(id _self) {
      XCTAssertTrue(success, @"%@", failureMessage);
    });

    // Create an appropriate XCTest method name based on the dart test name.
    // Example: dart test "verify widget" becomes "testVerifyWidget"
    NSString *upperCamelTestName = [testName.localizedCapitalizedString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *testSelectorName = [NSString stringWithFormat:@"test%@", upperCamelTestName];
    SEL testSelector = NSSelectorFromString(testSelectorName);
    class_addMethod(self, testSelector, assertImplementation, "v@:");

    // Add the new class method as a test invocation to the XCTestCase.
    NSMethodSignature *signature = [self instanceMethodSignatureForSelector:testSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.selector = testSelector;

    [testInvocations addObject:invocation];
  }];

  NSDictionary<NSString *, UIImage *> *capturedScreenshotsByName = integrationTestRunner.capturedScreenshotsByName;
  if (capturedScreenshotsByName.count > 0) {
    // If the Flutter dart tests have captured screenshots, add them to the XCTest bundle.
    IMP screenshotImplementation = imp_implementationWithBlock(^(id _self) {
      [capturedScreenshotsByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, UIImage *screenshot, BOOL *stop) {
        XCTAttachment *attachment = [XCTAttachment attachmentWithImage:screenshot];
        attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
        if (name != nil) {
          attachment.name = name;
        }
        [_self addAttachment:attachment];
      }];
    });

    SEL attachmentSelector = NSSelectorFromString(@"screenshotPlaceholder");
    class_addMethod(self, attachmentSelector, screenshotImplementation, "v@:");

    NSMethodSignature *attachmentSignature = [self instanceMethodSignatureForSelector:attachmentSelector];
    NSInvocation *attachmentInvocation = [NSInvocation invocationWithMethodSignature:attachmentSignature];
    attachmentInvocation.selector = attachmentSelector;

    [testInvocations addObject:attachmentInvocation];
  }
  return testInvocations;
}

@end

#endif
