// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERVIEWCONTROLLER_H_
#define FLUTTER_FLUTTERVIEWCONTROLLER_H_

#import <UIKit/UIKit.h>
#include <sys/cdefs.h>

#include "FlutterBinaryMessenger.h"
#include "FlutterDartProject.h"
#include "FlutterEngine.h"
#include "FlutterMacros.h"
#include "FlutterPlugin.h"
#include "FlutterTexture.h"

@class FlutterEngine;

/**
 * A `UIViewController` implementation for Flutter views.
 *
 * Dart execution, channel communication, texture registration, and plugin registration
 * are all handled by `FlutterEngine`.  Calls on this class to those members all proxy
 * through to the `FlutterEngine` attached FlutterViewController.
 *
 * A FlutterViewController can be initialized either with an already-running `FlutterEngine`,
 * or it can be initialized with a `FlutterDartProject` that will be used to spin up
 * a new `FlutterEngine`.  Developers looking to present and hide FlutterViewControllers
 * in native iOS applications will usually want to maintain the `FlutterEngine` instance
 * so as not to lose Dart-related state and asynchronous tasks when navigating back and
 * forth between a FlutterViewController and other `UIViewController`s.
 */
FLUTTER_EXPORT
@interface FlutterViewController
    : UIViewController <FlutterBinaryMessenger, FlutterTextureRegistry, FlutterPluginRegistry>

/**
 * Initializes this FlutterViewController with the specified `FlutterEngine`.
 *
 * The initialized viewcontroller will attach itself to the engine as part of this process.
 *
 * @param engine The `FlutterEngine` instance to attach to.
 * @param nibNameOrNil The NIB name to initialize this UIViewController with.
 * @param nibBundleOrNil The NIB bundle.
 */
- (instancetype)initWithEngine:(FlutterEngine*)engine
                       nibName:(NSString*)nibNameOrNil
                        bundle:(NSBundle*)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

/**
 * Initializes a new FlutterViewController and `FlutterEngine` with the specified
 * `FlutterDartProject`.
 *
 * @param projectOrNil The `FlutterDartProject` to initialize the `FlutterEngine` with.
 * @param nibNameOrNil The NIB name to initialize this UIViewController with.
 * @param nibBundleOrNil The NIB bundle.
 */
- (instancetype)initWithProject:(FlutterDartProject*)projectOrNil
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (void)handleStatusBarTouches:(UIEvent*)event;

/**
 * Registers a callback that will be invoked when the Flutter view has been rendered.
 * The callback will be fired only once.
 *
 * Replaces an existing callback. Use a `nil` callback to unregister the existing one.
 */
- (void)setFlutterViewDidRenderCallback:(void (^)(void))callback;

/**
 * Returns the file name for the given asset.
 * The returned file name can be used to access the asset in the application's
 * main bundle.
 *
 * @param asset The name of the asset. The name can be hierarchical.
 * @return The file name to be used for lookup in the main bundle.
 */
- (NSString*)lookupKeyForAsset:(NSString*)asset;

/**
 * Returns the file name for the given asset which originates from the specified
 * package.
 * The returned file name can be used to access the asset in the application's
 * main bundle.
 *
 * @param asset The name of the asset. The name can be hierarchical.
 * @param package The name of the package from which the asset originates.
 * @return The file name to be used for lookup in the main bundle.
 */
- (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package;

/**
 * Sets the first route that the Flutter app shows. The default is "/".
 * This method will guarnatee that the initial route is delivered, even if the
 * Flutter window hasn't been created yet when called. It cannot be used to update
 * the current route being shown in a visible FlutterViewController (see pushRoute
 * and popRoute).
 *
 * @param route The name of the first route to show.
 */
- (void)setInitialRoute:(NSString*)route;

/**
 * Instructs the Flutter Navigator (if any) to go back.
 */
- (void)popRoute;

/**
 * Instructs the Flutter Navigator (if any) to push a route on to the navigation
 * stack.  The setInitialRoute method should be prefered if this is called before the
 * FlutterViewController has come into view.
 *
 * @param route The name of the route to push to the navigation stack.
 */
- (void)pushRoute:(NSString*)route;

/**
 * The `FlutterPluginRegistry` used by this FlutterViewController.
 */
- (id<FlutterPluginRegistry>)pluginRegistry;

/**
 * Specifies the view to use as a splash screen. Flutter's rendering is asynchronous, so the first
 * frame rendered by the Flutter application might not immediately appear when theFlutter view is
 * initially placed in the view hierarchy. The splash screen view will be used as
 * a replacement until the first frame is rendered.
 *
 * The view used should be appropriate for multiple sizes; an autoresizing mask to
 * have a flexible width and height will be applied automatically.
 */
@property(strong, nonatomic) UIView* splashScreenView;

/**
 * Attempts to set the `splashScreenView` property from the `UILaunchStoryboardName` from the
 * main bundle's `Info.plist` file.  This method will not change the value of `splashScreenView`
 * if it cannot find a default one from a storyboard or nib.
 *
 * @return `YES` if successful, `NO` otherwise.
 */
- (BOOL)loadDefaultSplashScreenView;

/**
 * Controls whether the created view will be opaque or not.
 *
 * Default is `YES`.  Note that setting this to `NO` may negatively impact performance
 * when using hardware acceleration, and toggling this will trigger a re-layout of the
 * view.
 */
@property(nonatomic, getter=isViewOpaque) BOOL viewOpaque;

@end

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
