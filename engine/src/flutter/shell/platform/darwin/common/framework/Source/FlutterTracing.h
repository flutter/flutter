// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERTRACING_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERTRACING_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Tracing)
@interface FlutterTracing : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * Traces the duration of the provided work block.
 *
 * In Swift, this supports trailing closure syntax:
 * Tracing.traceScope("MyScope") { ... }
 */
+ (void)traceScope:(NSString*)name work:(void(NS_NOESCAPE ^)(void))work;

/**
 * Traces a point-in-time event with specific arguments.
 *
 * Specific high-frequency events (like vsync) get dedicated methods
 * to avoid the overhead of passing dictionaries for primitive types.
 */
+ (void)tracePlatformVsyncWithStartTime:(int64_t)startTimeMicroseconds
                             targetTime:(int64_t)targetTimeMicroseconds;

/**
 * Traces the beginning of an asynchronous event.
 */
+ (void)traceAsyncBegin:(NSString*)name eventId:(int64_t)eventId;

/**
 * Traces the end of an asynchronous event.
 */
+ (void)traceAsyncEnd:(NSString*)name eventId:(int64_t)eventId;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERTRACING_H_
