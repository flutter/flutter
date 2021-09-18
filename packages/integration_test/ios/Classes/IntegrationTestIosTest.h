// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FLTIntegrationTestScreenshotDelegate;

@interface IntegrationTestIosTest : NSObject

- (instancetype)initWithScreenshotDelegate:(nullable id<FLTIntegrationTestScreenshotDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/**
 * Initiate dart tests and wait for results.  @c testResult will be set to a string describing the results.
 *
 * @return @c YES if all tests succeeded.
 */
- (BOOL)testIntegrationTest:(NSString *_Nullable *_Nullable)testResult;

@end

#define INTEGRATION_TEST_IOS_RUNNER(__test_class)                                           \
  @interface __test_class : XCTestCase<FLTIntegrationTestScreenshotDelegate>                \
  @end                                                                                      \
                                                                                            \
  @implementation __test_class                                                              \
                                                                                            \
  - (void)testIntegrationTest {                                                             \
    NSString *testResult;                                                                   \
    IntegrationTestIosTest *integrationTestIosTest = integrationTestIosTest = [[IntegrationTestIosTest alloc] initWithScreenshotDelegate:self]; \
    BOOL testPass = [integrationTestIosTest testIntegrationTest:&testResult];               \
    XCTAssertTrue(testPass, @"%@", testResult);                                             \
  }                                                                                         \
                                                                                            \
  - (void)didTakeScreenshot:(UIImage *)screenshot attachmentName:(NSString *)name {         \
    XCTAttachment *attachment = [XCTAttachment attachmentWithImage:screenshot];             \
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;                                  \
    if (name != nil) {                                                                      \
      attachment.name = name;                                                               \
    }                                                                                       \
    [self addAttachment:attachment];                                                        \
  }                                                                                         \
                                                                                            \
  @end

NS_ASSUME_NONNULL_END
