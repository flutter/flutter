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
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
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
    self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  }

  return self;
}

- (instancetype)initWithContentsScale:(CGFloat)contentsScale {
  self = [self init];

  if ([self.layer isKindOfClass:NSClassFromString(@"CAEAGLLayer")] ||
      [self.layer isKindOfClass:NSClassFromString(@"CAMetalLayer")]) {
    self.layer.allowsGroupOpacity = NO;
    self.layer.contentsScale = contentsScale;
    self.layer.rasterizationScale = contentsScale;
  }

  return self;
}

+ (Class)layerClass {
  return [FlutterView layerClass];
}

- (std::unique_ptr<flutter::IOSSurface>)createSurface:
    (std::shared_ptr<flutter::IOSContext>)ios_context {
  return flutter::IOSSurface::Create(std::move(ios_context),                              // context
                                     fml::scoped_nsobject<CALayer>{[self.layer retain]},  // layer
                                     nullptr  // platform views controller
  );
}

// TODO(amirh): implement drawLayer to support snapshotting.

@end
