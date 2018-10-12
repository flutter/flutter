// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERVIEWCONTROLLER_H_
#define FLUTTER_FLUTTERVIEWCONTROLLER_H_

#import <UIKit/UIKit.h>
#include <sys/cdefs.h>

#include "FlutterBinaryMessenger.h"
#include "FlutterDartProject.h"
#include "FlutterMacros.h"
#include "FlutterPlugin.h"
#include "FlutterTexture.h"

FLUTTER_EXPORT
@interface FlutterViewController
    : UIViewController <FlutterBinaryMessenger, FlutterTextureRegistry, FlutterPluginRegistry>

- (instancetype)initWithProject:(FlutterDartProject*)projectOrNil
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (void)handleStatusBarTouches:(UIEvent*)event;

/**
 Registers a callback that will be invoked when the Flutter view has been rendered.
 The callback will be fired only once.

 Replaces an existing callback. Use a `nil` callback to unregister the existing one.
 */
- (void)setFlutterViewDidRenderCallback:(void (^)(void))callback;

/**
 Returns the file name for the given asset.
 The returned file name can be used to access the asset in the application's main bundle.

 - Parameter asset: The name of the asset. The name can be hierarchical.
 - Returns: the file name to be used for lookup in the main bundle.
 */
- (NSString*)lookupKeyForAsset:(NSString*)asset;

/**
 Returns the file name for the given asset which originates from the specified package.
 The returned file name can be used to access the asset in the application's main bundle.

 - Parameters:
   - asset: The name of the asset. The name can be hierarchical.
   - package: The name of the package from which the asset originates.
 - Returns: the file name to be used for lookup in the main bundle.
 */
- (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package;

/**
 Sets the first route that the Flutter app shows. The default is "/".
 This method will guarnatee that the initial route is delivered, even if the
 Flutter window hasn't been created yet when called. It cannot be used to update
 the current route being shown in a visible FlutterViewController (see pushRoute
 and popRoute).

 - Parameter route: The name of the first route to show.
 */
- (void)setInitialRoute:(NSString*)route;

/**
 Instructs the Flutter Navigator (if any) to go back.
 */
- (void)popRoute;

/**
 Instructs the Flutter Navigator (if any) to push a route on to the navigation
 stack.  The setInitialRoute method should be prefered if this is called before the
 FlutterViewController has come into view.

 - Parameter route: The name of the route to push to the navigation stack.
 */
- (void)pushRoute:(NSString*)route;

- (id<FlutterPluginRegistry>)pluginRegistry;

/**
 Specifies the view to use as a splash screen. Flutter's rendering is asynchronous, so the first
 frame rendered by the Flutter application might not immediately appear when the Flutter view is
 initially placed in the view hierarchy. The splash screen view will be used as a replacement
 until the first frame is rendered.

 The view used should be appropriate for multiple sizes; an autoresizing mask to have a flexible
 width and height will be applied automatically.

 If not specified, uses a view generated from `UILaunchStoryboardName` from the main bundle's
 `Info.plist` file.
 */
@property(strong, nonatomic) UIView* splashScreenView;

@end

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
