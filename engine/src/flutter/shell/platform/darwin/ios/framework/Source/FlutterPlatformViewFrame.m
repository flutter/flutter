// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewFrame.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@implementation FlutterPlatformViewOverlay

- (instancetype)initWithView:(UIView*)view clippingView:(UIView*)clippingView rect:(CGRect)rect {
  if (self = [super init]) {
    _view = view;
    _clippingView = clippingView;
    _rect = rect;
  }
  return self;
}

@end

@implementation FlutterPlatformViewFrame

- (instancetype)initWithLayers:(NSArray<FlutterPlatformViewLayer*>*)layers
                      overlays:(NSDictionary<NSNumber*, FlutterPlatformViewOverlay*>*)overlays
            unusedOverlayViews:(NSArray<UIView*>*)unusedOverlayViews
              devicePixelRatio:(CGFloat)devicePixelRatio
                       present:(void (^)(void))present {
  if (self = [super init]) {
    _layers = [layers copy];
    _overlays = [overlays copy];
    _unusedOverlayViews = [unusedOverlayViews copy];
    _devicePixelRatio = devicePixelRatio;
    _present = [present copy];
  }
  return self;
}

@end
