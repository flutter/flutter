// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Foundation;
@import ObjectiveC.runtime;

NS_ASSUME_NONNULL_BEGIN

DEPRECATED_MSG_ATTRIBUTE("Use FLTIntegrationTestRunner instead.")
@interface IntegrationTestIosTest : NSObject

/**
 * Initiate dart tests and wait for results.  @c testResult will be set to a string describing the results.
 *
 * @return @c YES if all tests succeeded.
 */
- (BOOL)testIntegrationTest:(NSString *_Nullable *_Nullable)testResult;

@end

// For every Flutter dart test, dynamically generate an Objective-C method mirroring the test results
// so it is reported as a native XCTest run result.
// If the Flutter dart tests have captured screenshots, add them to the XCTest bundle.
#define INTEGRATION_TEST_IOS_RUNNER(__test_class)                                           \
  @interface __test_class : XCTestCase                                                      \
  @end                                                                                      \
                                                                                            \
  @implementation __test_class                                                              \
                                                                                            \
  + (NSArray<NSInvocation *> *)testInvocations {                                            \
    FLTIntegrationTestRunner *integrationTestRunner = [[FLTIntegrationTestRunner alloc] init]; \
    NSMutableArray<NSInvocation *> *testInvocations = [[NSMutableArray alloc] init];        \
    [integrationTestRunner testIntegrationTestWithResults:^(SEL testSelector, BOOL success, NSString *failureMessage) { \
      IMP assertImplementation = imp_implementationWithBlock(^(id _self) {                  \
        XCTAssertTrue(success, @"%@", failureMessage);                                      \
      });                                                                                   \
      class_addMethod(self, testSelector, assertImplementation, "v@:");                     \
      NSMethodSignature *signature = [self instanceMethodSignatureForSelector:testSelector]; \
      NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];    \
      invocation.selector = testSelector;                                                   \
      [testInvocations addObject:invocation];                                               \
    }];                                                                                     \
    NSDictionary<NSString *, UIImage *> *capturedScreenshotsByName = integrationTestRunner.capturedScreenshotsByName; \
    if (capturedScreenshotsByName.count > 0) {                                              \
      IMP screenshotImplementation = imp_implementationWithBlock(^(id _self) {              \
        [capturedScreenshotsByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, UIImage *screenshot, BOOL *stop) { \
          XCTAttachment *attachment = [XCTAttachment attachmentWithImage:screenshot];       \
          attachment.lifetime = XCTAttachmentLifetimeKeepAlways;                            \
          if (name != nil) {                                                                \
            attachment.name = name;                                                         \
          }                                                                                 \
          [_self addAttachment:attachment];                                                 \
        }];                                                                                 \
      });                                                                                   \
      SEL attachmentSelector = NSSelectorFromString(@"screenshotPlaceholder");              \
      class_addMethod(self, attachmentSelector, screenshotImplementation, "v@:");           \
      NSMethodSignature *attachmentSignature = [self instanceMethodSignatureForSelector:attachmentSelector]; \
      NSInvocation *attachmentInvocation = [NSInvocation invocationWithMethodSignature:attachmentSignature]; \
      attachmentInvocation.selector = attachmentSelector;                                   \
      [testInvocations addObject:attachmentInvocation];                                     \
    }                                                                                       \
    return testInvocations;                                                                 \
  }                                                                                         \
                                                                                            \
  @end

NS_ASSUME_NONNULL_END
