// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/** A Flutter plugin that's responsible for communicating the test results back
 * to iOS XCTest. */
@interface IntegrationTestPlugin : NSObject <FlutterPlugin>

/**
 * Test results that are sent from Dart when integration test completes. Before the
 * completion, it is @c nil.
 */
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *testResults;

/**
 * Mapping of screenshot images by suggested names, captured by the dart tests.
 */
@property (copy, readonly) NSDictionary<NSString *, UIImage *> *capturedScreenshotsByName;

/** Fetches the singleton instance of the plugin. */
+ (instancetype)instance;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
