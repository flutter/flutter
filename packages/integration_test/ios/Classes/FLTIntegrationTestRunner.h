// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Foundation;

@class UIImage;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FLTIntegrationTestResults)(SEL nativeTestSelector, BOOL success, NSString *_Nullable failureMessage);

@interface FLTIntegrationTestRunner : NSObject

/**
 * Any screenshots captured by the plugin.
 */
@property (copy, readonly) NSDictionary<NSString *, UIImage *> *capturedScreenshotsByName;

/*!
 Start dart tests and wait for results.

 @param testResult Will be called once per every completed dart test.
 */
- (void)testIntegrationTestWithResults:(NS_NOESCAPE FLTIntegrationTestResults)testResult;

@end

NS_ASSUME_NONNULL_END
