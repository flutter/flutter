// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_TESTING_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_TESTING_H_

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterVSyncClient.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal methods of FlutterVSyncClient for use in unit tests.
 */
@interface FlutterVSyncClient (Testing)

/**
 * The underlying CADisplayLink instance.
 */
@property(nonatomic, readonly) CADisplayLink* displayLink;

/**
 * Manually triggers the display link callback for testing without waiting for actual vsyncs.
 */
- (void)onDisplayLink:(CADisplayLink*)link;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVSYNCCLIENT_TESTING_H_
