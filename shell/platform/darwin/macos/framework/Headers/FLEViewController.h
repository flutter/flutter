// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

#import "FLEEngine.h"
#import "FlutterMacros.h"
#import "FlutterPluginRegistrarMacOS.h"

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
 * Controls embedder plugins and communication with the underlying Flutter engine, managing a view
 * intended to handle key inputs and drawing protocols (see |view|).
 *
 * Can be launched headless (no managed view), at which point a Dart executable will be run on the
 * Flutter engine in non-interactive mode, or with a drawable Flutter canvas.
 */
FLUTTER_EXPORT
@interface FLEViewController : NSViewController <FlutterPluginRegistry>

/**
 * The Flutter engine associated with this view controller.
 */
@property(nonatomic, nonnull, readonly) FLEEngine* engine;

/**
 * The style of mouse tracking to use for the view. Defaults to
 * FlutterMouseTrackingModeInKeyWindow.
 */
@property(nonatomic) FlutterMouseTrackingMode mouseTrackingMode;

/**
 * Initializes a controller that will run the given project.
 *
 * @param project The project to run in this view controller. If nil, a default `FLEDartProject`
 *                will be used.
 */
- (nonnull instancetype)initWithProject:(nullable FLEDartProject*)project NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)initWithNibName:(nullable NSString*)nibNameOrNil
                                 bundle:(nullable NSBundle*)nibBundleOrNil
    NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)initWithCoder:(nonnull NSCoder*)nibNameOrNil NS_DESIGNATED_INITIALIZER;

@end
