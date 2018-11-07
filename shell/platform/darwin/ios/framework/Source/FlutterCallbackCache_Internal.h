// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERCALLBACKCACHE_INTERNAL_H_
#define FLUTTER_FLUTTERCALLBACKCACHE_INTERNAL_H_

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCallbackCache.h"

@interface FlutterCallbackCache ()

+ (void)setCachePath:(NSString*)path;

@end

#endif  // FLUTTER_FLUTTERCALLBACKCACHE_INTERNAL_H_
