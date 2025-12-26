// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDISPLAYLINK_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDISPLAYLINK_H_

#import <AppKit/AppKit.h>

@protocol FlutterDisplayLinkDelegate <NSObject>
/// This will be called on main thread.
- (void)onDisplayLink:(CFTimeInterval)timestamp targetTimestamp:(CFTimeInterval)targetTimestamp;
@end

/// Provides notifications of display refresh.
///
/// Internally FlutterDisplayLink will use at most one CVDisplayLink per
/// screen shared for all views belonging to that screen. This is necessary
/// because each CVDisplayLink comes with its own thread.
///
/// All methods must be called on main thread.
@interface FlutterDisplayLink : NSObject

/// Creates new instance tied to provided NSView. FlutterDisplayLink
/// will track view display changes transparently to synchronize
/// update with display refresh.
+ (instancetype)displayLinkWithView:(NSView*)view;

/// Delegate must be set on main thread.
/// Delegate method will be also called on main thread.
@property(nonatomic, weak) id<FlutterDisplayLinkDelegate> delegate;

/// Pauses and resumes the display link.
@property(readwrite) BOOL paused;

/// Returns the nominal refresh period of the display to which the view
/// currently belongs (in seconds). If view does not belong to any display,
/// returns 0.
@property(readonly) CFTimeInterval nominalOutputRefreshPeriod;

/// Invalidates the display link.
- (void)invalidate;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_FLUTTERDISPLAYLINK_H_
