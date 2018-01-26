// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/flutter_main_ios.h"
#include "flutter/shell/platform/darwin/common/platform_mac.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

namespace shell {

void FlutterMain() {
  NSBundle* bundle = [NSBundle bundleForClass:[FlutterViewController class]];
  NSString* icuDataPath = [bundle pathForResource:@"icudtl" ofType:@"dat"];
  NSString* libraryName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTLibraryPath"];

  NSBundle* mainBundle = [NSBundle mainBundle];

  NSString* flutterAssetsName = [mainBundle objectForInfoDictionaryKey:@"FLTAssetsPath"];
  if (flutterAssetsName == nil) {
    // Default to "flutter_assets"
    flutterAssetsName = @"flutter_assets";
  }
  NSString* flutterAssetsPath = [mainBundle pathForResource:flutterAssetsName ofType:nil];

  shell::PlatformMacMain(icuDataPath.UTF8String, libraryName != nil ? libraryName.UTF8String : "",
                         flutterAssetsPath.UTF8String);
}

}  // namespace shell
