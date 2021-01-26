// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERDARTPROJECT_H_
#define FLUTTER_FLUTTERDARTPROJECT_H_

#import <Foundation/Foundation.h>

#import "FlutterMacros.h"

/**
 * A set of Flutter and Dart assets used by a `FlutterEngine` to initialize execution.
 *
 * TODO(stuartmorgan): Align API with FlutterDartProject, and combine.
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterDartProject : NSObject

/**
 * Initializes a Flutter Dart project from a bundle.
 *
 * The bundle must either contain a flutter_assets resource directory, or set the Info.plist key
 * FLTAssetsPath to override that name (if you are doing a custom build using a different name).
 *
 * @param bundle The bundle containing the Flutter assets directory. If nil, the App framework
 *               created by Flutter will be used.
 */
- (nonnull instancetype)initWithPrecompiledDartBundle:(nullable NSBundle*)bundle
    NS_DESIGNATED_INITIALIZER;

/**
 * If set, allows the Flutter project to use the dart:mirrors library.
 *
 * Deprecated: This function is temporary and will be removed in a future release.
 */
@property(nonatomic) bool enableMirrors;

/**
 * An NSArray of NSStrings to be passed as command line arguments to the Dart entrypoint.
 *
 * If this is not explicitly set, this will default to the contents of
 * [NSProcessInfo arguments], without the binary name.
 *
 * Set this to nil to pass no arguments to the Dart entrypoint.
 */
@property(nonatomic, nullable) NSArray<NSString*>* dartEntrypointArguments;

@end

#endif  // FLUTTER_FLUTTERDARTPROJECT_H_
