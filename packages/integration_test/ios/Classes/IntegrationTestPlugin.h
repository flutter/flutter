// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FLTIntegrationTestScreenshotDelegate

/** This will be called when a dart integration test triggers a window screenshot with  @c takeScreenshot. */
- (void)didTakeScreenshot:(UIImage *)screenshot attachmentName:(nullable NSString *)name;

@end

/** A Flutter plugin that's responsible for communicating the test results back
 * to iOS XCTest. */
@interface IntegrationTestPlugin : NSObject <FlutterPlugin>

/**
 * Test results that are sent from Dart when integration test completes. Before the
 * completion, it is @c nil.
 */
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *testResults;

/** Fetches the singleton instance of the plugin. */
+ (IntegrationTestPlugin *)instance;

- (void)setupChannels:(id<FlutterBinaryMessenger>)binaryMessenger;

- (instancetype)init NS_UNAVAILABLE;

@property(weak, nonatomic) id<FLTIntegrationTestScreenshotDelegate> screenshotDelegate;

@end

NS_ASSUME_NONNULL_END
