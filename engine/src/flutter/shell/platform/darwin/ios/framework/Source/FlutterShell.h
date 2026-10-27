// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHELL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHELL_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The shell-backed implementation of the engine backend.
@interface FlutterShell : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// The label used for this backend's threads and task runners, or nil before a thread host
/// exists.
@property(nonatomic, readonly, copy, nullable) NSString* threadLabel;

/// Creates the raster, IO, and (in debug and profile modes) profiler threads, and adopts the
/// calling thread as the platform and UI thread.
- (void)createThreadHostWithLabelPrefix:(NSString*)labelPrefix;

/// Shares `shell`'s thread host and profiler with this backend. Used by spawned engines.
- (void)inheritThreadHostFromShell:(FlutterShell*)shell;

/// Starts the sampling profiler if the runtime mode supports it.
- (void)startProfilerIfEnabled;

/// Releases the profiler, then the thread host.
- (void)destroyThreadHost;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHELL_H_
