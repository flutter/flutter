// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

@implementation FlutterView {
  id<FlutterViewEngineDelegate> _delegate;
}

- (instancetype)init {
  @throw([NSException exceptionWithName:@"FlutterView must initWithDelegate"
                                 reason:nil
                               userInfo:nil]);
}

- (instancetype)initWithFrame:(CGRect)frame {
  @throw([NSException exceptionWithName:@"FlutterView must initWithDelegate"
                                 reason:nil
                               userInfo:nil]);
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  @throw([NSException exceptionWithName:@"FlutterView must initWithDelegate"
                                 reason:nil
                               userInfo:nil]);
}

- (instancetype)initWithDelegate:(id<FlutterViewEngineDelegate>)delegate opaque:(BOOL)opaque {
  FML_DCHECK(delegate) << "Delegate must not be nil.";
  self = [super initWithFrame:CGRectNull];

  if (self) {
    _delegate = delegate;
    self.layer.opaque = opaque;
  }

  return self;
}

- (void)layoutSubviews {
  if ([self.layer isKindOfClass:NSClassFromString(@"CAEAGLLayer")] ||
      [self.layer isKindOfClass:NSClassFromString(@"CAMetalLayer")]) {
    CGFloat screenScale = [UIScreen mainScreen].scale;
    self.layer.allowsGroupOpacity = YES;
    self.layer.contentsScale = screenScale;
    self.layer.rasterizationScale = screenScale;
  }

  [super layoutSubviews];
}

+ (Class)layerClass {
  return flutter::GetCoreAnimationLayerClassForRenderingAPI();
}

- (std::unique_ptr<flutter::IOSSurface>)createSurface:
    (std::shared_ptr<flutter::IOSContext>)ios_context {
  return flutter::IOSSurface::Create(
      std::move(ios_context),                              // context
      fml::scoped_nsobject<CALayer>{[self.layer retain]},  // layer
      [_delegate platformViewsController]                  // platform views controller
  );
}

- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
  TRACE_EVENT0("flutter", "SnapshotFlutterView");

  if (layer != self.layer || context == nullptr) {
    return;
  }

  auto screenshot = [_delegate takeScreenshot:flutter::Rasterizer::ScreenshotType::UncompressedImage
                              asBase64Encoded:NO];

  if (!screenshot.data || screenshot.data->isEmpty() || screenshot.frame_size.isEmpty()) {
    return;
  }

  NSData* data = [NSData dataWithBytes:const_cast<void*>(screenshot.data->data())
                                length:screenshot.data->size()];

  fml::CFRef<CGDataProviderRef> image_data_provider(
      CGDataProviderCreateWithCFData(reinterpret_cast<CFDataRef>(data)));

  fml::CFRef<CGColorSpaceRef> colorspace(CGColorSpaceCreateDeviceRGB());

  fml::CFRef<CGImageRef> image(CGImageCreate(
      screenshot.frame_size.width(),      // size_t width
      screenshot.frame_size.height(),     // size_t height
      8,                                  // size_t bitsPerComponent
      32,                                 // size_t bitsPerPixel,
      4 * screenshot.frame_size.width(),  // size_t bytesPerRow
      colorspace,                         // CGColorSpaceRef space
      static_cast<CGBitmapInfo>(kCGImageAlphaPremultipliedLast |
                                kCGBitmapByteOrder32Big),  // CGBitmapInfo bitmapInfo
      image_data_provider,                                 // CGDataProviderRef provider
      nullptr,                                             // const CGFloat* decode
      false,                                               // bool shouldInterpolate
      kCGRenderingIntentDefault                            // CGColorRenderingIntent intent
      ));

  const CGRect frame_rect =
      CGRectMake(0.0, 0.0, screenshot.frame_size.width(), screenshot.frame_size.height());

  CGContextSaveGState(context);
  CGContextTranslateCTM(context, 0.0, CGBitmapContextGetHeight(context));
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextDrawImage(context, frame_rect, image);
  CGContextRestoreGState(context);
}

@end
