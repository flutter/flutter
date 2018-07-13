// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCallbackCache.h"

#include "flutter/lib/ui/plugins/callback_cache.h"

@implementation FlutterCallbackInformation
@end

@implementation FlutterCallbackCache

+ (FlutterCallbackInformation*)lookupCallbackInformation:(int64_t)handle {
  auto info = blink::DartCallbackCache::GetCallbackInformation(handle);
  if (info == nullptr) {
    return nil;
  }
  FlutterCallbackInformation* new_info = [[FlutterCallbackInformation alloc] init];
  new_info.callbackName = [NSString stringWithUTF8String:info->name.c_str()];
  new_info.callbackClassName = [NSString stringWithUTF8String:info->class_name.c_str()];
  new_info.callbackLibraryPath = [NSString stringWithUTF8String:info->library_path.c_str()];
  return new_info;
}

@end