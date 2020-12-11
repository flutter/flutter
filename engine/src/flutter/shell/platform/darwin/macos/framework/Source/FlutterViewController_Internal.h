// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIntermediateKeyResponder.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@interface FlutterViewController ()

// The FlutterView for this view controller.
@property(nonatomic, readonly, nullable) FlutterView* flutterView;

/**
 * This just returns the NSPasteboard so that it can be mocked in the tests.
 */
@property(nonatomic, readonly, nonnull) NSPasteboard* pasteboard;

/**
 * Adds an intermediate responder for keyboard events. Key up and key down events are forwarded to
 * all added responders, and they either handle the keys or not.
 */
- (void)addKeyResponder:(nonnull FlutterIntermediateKeyResponder*)responder;

/**
 * Removes an intermediate responder for keyboard events.
 */
- (void)removeKeyResponder:(nonnull FlutterIntermediateKeyResponder*)responder;

/**
 * Initializes this FlutterViewController with the specified `FlutterEngine`.
 *
 * The initialized viewcontroller will attach itself to the engine as part of this process.
 *
 * @param engine The `FlutterEngine` instance to attach to. Cannot be nil.
 * @param nibName The NIB name to initialize this controller with.
 * @param nibBundle The NIB bundle.
 */
- (nonnull instancetype)initWithEngine:(nonnull FlutterEngine*)engine
                               nibName:(nullable NSString*)nibName
                                bundle:(nullable NSBundle*)nibBundle NS_DESIGNATED_INITIALIZER;
@end
