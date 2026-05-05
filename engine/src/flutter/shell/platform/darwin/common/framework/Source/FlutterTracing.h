// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERTRACING_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERTRACING_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Provides utility methods to record tracing events to the Flutter timeline.
 *
 * This class wraps the C++ `fml/trace_event.h` macros, exposing them as Objective-C
 * methods. It is used to instrument Objective-C and Swift code with duration
 * events, asynchronous events, and custom flow events.
 *
 * Events recorded are sent to the Dart VM timeline and can be visualized using
 * Flutter DevTools.
 *
 * In Swift, this class is available as `Tracing`.
 */
NS_SWIFT_NAME(Tracing)
@interface FlutterTracing : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * Traces a platform vsync event with the given start and target times.
 *
 * This method is used to instrument platform-specific vsync signals. It records the
 * frame start time and target time to the timeline, converted to microseconds.
 *
 * @param startTime The start time of the vsync tick.
 * @param targetTime The target time of the next vsync tick.
 */
+ (void)tracePlatformVsyncWithStartTime:(NSTimeInterval)startTime
                             targetTime:(NSTimeInterval)targetTime;

/**
 * Traces the beginning of an asynchronous event.
 *
 * Asynchronous events are used to trace operations that span multiple threads or
 * are not bound to a single scope. Corresponding begin and end events must have
 * matching names and event IDs.
 *
 * @param name The name of the event.
 * @param eventID A unique identifier used to associate this begin event with its corresponding end
 * event.
 */
+ (void)traceAsyncBegin:(NSString*)name eventID:(int64_t)eventID;

/**
 * Traces the end of an asynchronous event.
 *
 * Asynchronous events are used to trace operations that span multiple threads or
 * are not bound to a single scope. Corresponding begin and end events must have
 * matching names and event IDs.
 *
 * @param name The name of the event.
 * @param eventID A unique identifier used to associate this end event with its corresponding begin
 * event.
 */
+ (void)traceAsyncEnd:(NSString*)name eventID:(int64_t)eventID;

/**
 * Starts a thread-local manual tracing section.
 *
 * This is a low-level API. In Swift code, consider using `Tracing.withTrace` or
 * `Tracing.beginScope` which are safer and more idiomatic.
 *
 * Every call to `beginSection:` must be paired with a corresponding call to
 * `endSection:` with the matching name on the same thread.
 *
 * @param name The name of the tracing section.
 */
+ (void)beginSection:(NSString*)name;

/**
 * Ends a thread-local manual tracing section.
 *
 * This must be called to end a section started by `beginSection:` with the matching name.
 *
 * @param name The name of the tracing section.
 */
+ (void)endSection:(NSString*)name;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_SOURCE_FLUTTERTRACING_H_
