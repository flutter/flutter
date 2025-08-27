// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVSYNCWAITER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVSYNCWAITER_H_

#import <AppKit/AppKit.h>

@class FlutterDisplayLink;

@interface FlutterVSyncWaiter : NSObject

/// Creates new waiter instance tied to provided NSView.
/// This function must be called on the main thread.
///
/// Provided |block| will be invoked on main thread.
- (instancetype)initWithDisplayLink:(FlutterDisplayLink*)displayLink
                              block:(void (^)(CFTimeInterval timestamp,
                                              CFTimeInterval targetTimestamp,
                                              uintptr_t baton))block;

/// Schedules |baton| to be signaled on next display refresh.
/// This function must be called on the main thread.
- (void)waitForVSync:(uintptr_t)baton;

/// Invalidates the waiter. This must be called on the main thread
/// before the instance is deallocated.
- (void)invalidate;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERVSYNCWAITER_H_
