// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderingBackend.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

@implementation FlutterRenderingBackend

+ (BOOL)renderUsingMetal {
#ifdef SHELL_ENABLE_METAL
  if (@available(macOS 10.14, *)) {
    BOOL systemSupportsMetal = MTLCreateSystemDefaultDevice() != nil;
    return systemSupportsMetal;
  }
#endif
  return NO;
}

@end
