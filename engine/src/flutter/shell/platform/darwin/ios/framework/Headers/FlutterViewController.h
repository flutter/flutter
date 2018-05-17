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
#include "FlutterTexture.h"

FLUTTER_EXPORT
@interface FlutterViewController : UIViewController<FlutterBinaryMessenger, FlutterTextureRegistry>

- (instancetype)initWithProject:(FlutterDartProject*)project
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (void)handleStatusBarTouches:(UIEvent*)event;

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

 - Parameter route: The name of the first route to show.
 */
- (void)setInitialRoute:(NSString*)route;

@end

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
