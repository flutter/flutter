// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERDARTPROJECT_H_
#define FLUTTER_FLUTTERDARTPROJECT_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

FLUTTER_EXPORT
@interface FlutterDartProject : NSObject

- (instancetype)initWithPrecompiledDartBundle:(NSBundle*)bundle NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFlutterAssets:(NSURL*)flutterAssetsURL
                             dartMain:(NSURL*)dartMainURL
                             packages:(NSURL*)dartPackages NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFlutterAssetsWithScriptSnapshot:(NSURL*)flutterAssetsURL
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initFromDefaultSourceForConfiguration FLUTTER_UNAVAILABLE("Use -init instead.");

/**
 Returns the file name for the given asset.
 The returned file name can be used to access the asset in the application's main bundle.

 - Parameter asset: The name of the asset. The name can be hierarchical.
 - Returns: the file name to be used for lookup in the main bundle.
 */
+ (NSString*)lookupKeyForAsset:(NSString*)asset;

/**
 Returns the file name for the given asset which originates from the specified package.
 The returned file name can be used to access the asset in the application's main bundle.

 - Parameters:
   - asset: The name of the asset. The name can be hierarchical.
   - package: The name of the package from which the asset originates.
 - Returns: the file name to be used for lookup in the main bundle.
 */
+ (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package;

/**
 Returns the default identifier for the bundle where we expect to find the Flutter Dart
 application.
 */
+ (NSString*)defaultBundleIdentifier;

@end

#endif  // FLUTTER_FLUTTERDARTPROJECT_H_
