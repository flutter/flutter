// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/ios/framework/Source/FlutterView.h"

@interface FlutterView ()<UIInputViewAudioFeedback>

@end

@implementation FlutterView

- (void)layoutSubviews {
  CGFloat screenScale = [UIScreen mainScreen].scale;
  CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);

  layer.allowsGroupOpacity = YES;
  layer.opaque = YES;
  layer.contentsScale = screenScale;
  layer.rasterizationScale = screenScale;

  [super layoutSubviews];
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (BOOL)enableInputClicksWhenVisible {
  return YES;
}

@end
