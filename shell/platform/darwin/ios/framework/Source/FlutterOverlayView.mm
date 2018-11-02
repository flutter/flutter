// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterOverlayView.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

// This is mostly a duplication of FlutterView.
// TODO(amirh): once GL support is in evaluate if we can merge this with FlutterView.
@implementation FlutterOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
  @throw([NSException exceptionWithName:@"FlutterOverlayView must initWithDelegate"
                                 reason:nil
                               userInfo:nil]);
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  @throw([NSException exceptionWithName:@"FlutterOverlayView must initWithDelegate"
                                 reason:nil
                               userInfo:nil]);
}

- (instancetype)init {
  self = [super initWithFrame:CGRectZero];

  if (self) {
    self.layer.opaque = NO;
    self.userInteractionEnabled = NO;
  }

  return self;
}

- (void)layoutSubviews {
  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);
    layer.allowsGroupOpacity = NO;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    layer.contentsScale = screenScale;
    layer.rasterizationScale = screenScale;
  }

  [super layoutSubviews];
}

+ (Class)layerClass {
#if TARGET_IPHONE_SIMULATOR
  return [CALayer class];
#else   // TARGET_IPHONE_SIMULATOR
  return [CAEAGLLayer class];
#endif  // TARGET_IPHONE_SIMULATOR
}

- (std::unique_ptr<shell::IOSSurface>)createSurface {
  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    // TODO(amirh): create a GL surface.
    return nullptr;
  } else {
    fml::scoped_nsobject<CALayer> layer(reinterpret_cast<CALayer*>([self.layer retain]));
    return std::make_unique<shell::IOSSurfaceSoftware>(std::move(layer), nullptr);
  }
}

// TODO(amirh): implement drawLayer to suppoer snapshotting.

@end
