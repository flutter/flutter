// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterDartProject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"

#include <vector>

static NSString* const kICUBundlePath = @"icudtl.dat";
static NSString* const kAppBundleIdentifier = @"io.flutter.flutter.app";

@implementation FlutterDartProject {
  NSBundle* _dartBundle;
  NSString* _assetsPath;
  NSString* _ICUDataPath;
}

- (instancetype)init {
  return [self initWithPrecompiledDartBundle:nil];
}

- (instancetype)initWithPrecompiledDartBundle:(NSBundle*)bundle {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");

  _dartBundle = bundle ?: [NSBundle bundleWithIdentifier:kAppBundleIdentifier];
  return self;
}

- (instancetype)initWithAssetsPath:(NSString*)assets ICUDataPath:(NSString*)icuPath {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _assetsPath = assets;
  _ICUDataPath = icuPath;
  return self;
}

- (NSString*)assetsPath {
  if (_assetsPath) {
    return _assetsPath;
  }

  // If there's no App.framework, fall back to checking the main bundle for assets.
  NSBundle* assetBundle = _dartBundle ?: [NSBundle mainBundle];
  NSString* flutterAssetsName = [assetBundle objectForInfoDictionaryKey:@"FLTAssetsPath"];
  if (flutterAssetsName == nil) {
    flutterAssetsName = @"flutter_assets";
  }
  NSString* path = [_dartBundle pathForResource:flutterAssetsName ofType:@""];
  if (!path) {
    NSLog(@"Failed to find path for \"%@\"", flutterAssetsName);
  }
  return path;
}

- (NSString*)ICUDataPath {
  if (_ICUDataPath) {
    return _ICUDataPath;
  }

  NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:kICUBundlePath
                                                                    ofType:nil];
  if (!path) {
    NSLog(@"Failed to find path for \"%@\"", kICUBundlePath);
  }
  return path;
}

- (std::vector<const char*>)argv {
  // FlutterProjectArgs expects a full argv, so when processing it for flags the first item is
  // treated as the executable and ignored. Add a dummy value so that all provided arguments
  // are used.
  std::vector<const char*> arguments = {"placeholder"};
  for (NSUInteger i = 0; i < _engineSwitches.count; ++i) {
    arguments.push_back([_engineSwitches[i] UTF8String]);
  }
  return arguments;
}

@end
