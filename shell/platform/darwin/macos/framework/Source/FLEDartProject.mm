// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FLEDartProject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FLEDartProject_Internal.h"

#include <vector>

static NSString* const kICUBundlePath = @"icudtl.dat";

@implementation FLEDartProject {
  NSBundle* _bundle;
}

- (instancetype)init {
  return [self initWithBundle:nil];
}

- (instancetype)initWithBundle:(NSBundle*)bundle {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");

  _bundle = bundle ?: [NSBundle mainBundle];
  return self;
}

- (NSString*)assetsPath {
  NSString* flutterAssetsName = [_bundle objectForInfoDictionaryKey:@"FLTAssetsPath"];
  if (flutterAssetsName == nil) {
    flutterAssetsName = @"flutter_assets";
  }
  NSString* path = [_bundle pathForResource:flutterAssetsName ofType:@""];
  if (!path) {
    NSLog(@"Failed to find path for \"%@\"", flutterAssetsName);
  }
  return path;
}

- (NSString*)ICUDataPath {
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
