// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "FlutterEngine.h"
#import "FlutterMacros.h"
#import "FlutterPluginRegistrarMacOS.h"

/**
 * Values for the `mouseTrackingMode` property.
 */
typedef NS_ENUM(NSInteger, FlutterMouseTrackingMode) {
  // Hover events will never be sent to Flutter.
  FlutterMouseTrackingModeNone = 0,
  // Hover events will be sent to Flutter when the view is in the key window.
  FlutterMouseTrackingModeInKeyWindow,
  // Hover events will be sent to Flutter when the view is in the active app.
  FlutterMouseTrackingModeInActiveApp,
  // Hover events will be sent to Flutter regardless of window and app focus.
  FlutterMouseTrackingModeAlways,
};

/**
 * Controls a view that displays Flutter content and manages input.
 */
FLUTTER_EXPORT
@interface FlutterViewController : NSViewController <FlutterPluginRegistry>

/**
 * The Flutter engine associated with this view controller.
 */
@property(nonatomic, nonnull, readonly) FlutterEngine* engine;

/**
 * The style of mouse tracking to use for the view. Defaults to
 * FlutterMouseTrackingModeInKeyWindow.
 */
@property(nonatomic) FlutterMouseTrackingMode mouseTrackingMode;

/**
 * Initializes a controller that will run the given project.
 *
 * @param project The project to run in this view controller. If nil, a default `FlutterDartProject`
 *                will be used.
 */
- (nonnull instancetype)initWithProject:(nullable FlutterDartProject*)project
    NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)initWithNibName:(nullable NSString*)nibNameOrNil
                                 bundle:(nullable NSBundle*)nibBundleOrNil
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)initWithCoder:(nonnull NSCoder*)nibNameOrNil NS_DESIGNATED_INITIALIZER;

@end
