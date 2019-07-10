// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FLEViewController.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@interface FLEViewController ()

// The FlutterView for this view controller.
@property(nonatomic, readonly, nullable) FlutterView* flutterView;

/**
 * Adds a responder for keyboard events. Key up and key down events are forwarded to all added
 * responders.
 */
- (void)addKeyResponder:(nonnull NSResponder*)responder;

/**
 * Removes a responder for keyboard events.
 */
- (void)removeKeyResponder:(nonnull NSResponder*)responder;

/**
 * Called when the engine wants to make the resource context current. This must be a context
 * that is in the same share group as this controller's view.
 */
- (void)makeResourceContextCurrent;

@end
