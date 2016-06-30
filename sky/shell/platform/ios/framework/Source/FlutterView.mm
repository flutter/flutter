// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/framework/Source/FlutterView.h"

#include "base/memory/weak_ptr.h"
#include "sky/shell/platform/ios/framework/Source/accessibility_bridge.h"

@interface FlutterView ()<UIInputViewAudioFeedback>

@end

@implementation FlutterView {
  std::unique_ptr<sky::shell::AccessibilityBridge> _accessibilityBridge;
}

- (void)withAccessibility:(mojo::ServiceProvider*)serviceProvider {
  _accessibilityBridge.reset(new sky::shell::AccessibilityBridge(self, serviceProvider));
}

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
