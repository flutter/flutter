// Copyright 2013 The Flutter Authors. All rights reserved.
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
#if FLUTTER_SHELL_ENABLE_METAL
#include "flutter/shell/platform/darwin/ios/ios_surface_metal.h"
#endif
#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

// This is mostly a duplication of FlutterView.
// TODO(amirh): once GL support is in evaluate if we can merge this with FlutterView.
@implementation FlutterOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
  @throw([NSException exceptionWithName:@"FlutterOverlayView must init or initWithContentsScale"
                                 reason:nil
                               userInfo:nil]);
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  @throw([NSException exceptionWithName:@"FlutterOverlayView must init or initWithContentsScale"
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

- (instancetype)initWithContentsScale:(CGFloat)contentsScale {
  self = [self init];

  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);
    layer.allowsGroupOpacity = NO;
    layer.contentsScale = contentsScale;
    layer.rasterizationScale = contentsScale;
#if FLUTTER_SHELL_ENABLE_METAL
  } else if ([self.layer isKindOfClass:[CAMetalLayer class]]) {
    CAMetalLayer* layer = reinterpret_cast<CAMetalLayer*>(self.layer);
    layer.allowsGroupOpacity = NO;
    layer.contentsScale = contentsScale;
    layer.rasterizationScale = contentsScale;
#endif  // FLUTTER_SHELL_ENABLE_METAL
  }

  return self;
}

+ (Class)layerClass {
#if TARGET_IPHONE_SIMULATOR
  return [CALayer class];
#else  // TARGET_IPHONE_SIMULATOR
#if FLUTTER_SHELL_ENABLE_METAL
  return [CAMetalLayer class];
#else   // FLUTTER_SHELL_ENABLE_METAL
  return [CAEAGLLayer class];
#endif  //  FLUTTER_SHELL_ENABLE_METAL
#endif  // TARGET_IPHONE_SIMULATOR
}

- (std::unique_ptr<flutter::IOSSurface>)createSurface:
    (std::shared_ptr<flutter::IOSGLContext>)gl_context {
  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    fml::scoped_nsobject<CAEAGLLayer> eagl_layer(
        reinterpret_cast<CAEAGLLayer*>([self.layer retain]));
    if (@available(iOS 9.0, *)) {
      eagl_layer.get().presentsWithTransaction = YES;
    }
    return std::make_unique<flutter::IOSSurfaceGL>(std::move(eagl_layer), gl_context);
#if FLUTTER_SHELL_ENABLE_METAL
  } else if ([self.layer isKindOfClass:[CAMetalLayer class]]) {
    fml::scoped_nsobject<CAMetalLayer> metalLayer(
        reinterpret_cast<CAMetalLayer*>([self.layer retain]));
    if (@available(iOS 8.0, *)) {
      metalLayer.get().presentsWithTransaction = YES;
    }
    return std::make_unique<flutter::IOSSurfaceMetal>(std::move(metalLayer));
#endif  //  FLUTTER_SHELL_ENABLE_METAL
  } else {
    fml::scoped_nsobject<CALayer> layer(reinterpret_cast<CALayer*>([self.layer retain]));
    return std::make_unique<flutter::IOSSurfaceSoftware>(std::move(layer), nullptr);
  }
}

// TODO(amirh): implement drawLayer to support snapshotting.

@end
