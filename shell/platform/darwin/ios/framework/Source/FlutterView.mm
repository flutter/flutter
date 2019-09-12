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

#if FLUTTER_SHELL_ENABLE_METAL
#include "flutter/shell/platform/darwin/ios/ios_surface_metal.h"
#endif  //  FLUTTER_SHELL_ENABLE_METAL

@implementation FlutterView

id<FlutterViewEngineDelegate> _delegate;

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
  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);
    layer.allowsGroupOpacity = YES;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    layer.contentsScale = screenScale;
    layer.rasterizationScale = screenScale;
  }

#if FLUTTER_SHELL_ENABLE_METAL
  if ([self.layer isKindOfClass:[CAMetalLayer class]]) {
    const CGFloat screenScale = [UIScreen mainScreen].scale;

    auto metal_layer = reinterpret_cast<CAMetalLayer*>(self.layer);
    metal_layer.contentsScale = screenScale;
    metal_layer.rasterizationScale = screenScale;

    const auto layer_size = self.bounds.size;
    metal_layer.drawableSize =
        CGSizeMake(layer_size.width * screenScale, layer_size.height * screenScale);
  }

#endif  //  FLUTTER_SHELL_ENABLE_METAL
  [super layoutSubviews];
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
    (std::shared_ptr<flutter::IOSGLContext>)context {
  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    fml::scoped_nsobject<CAEAGLLayer> eagl_layer(
        reinterpret_cast<CAEAGLLayer*>([self.layer retain]));
    if (flutter::IsIosEmbeddedViewsPreviewEnabled()) {
      if (@available(iOS 9.0, *)) {
        // TODO(amirh): only do this if there's an embedded view.
        // https://github.com/flutter/flutter/issues/24133
        eagl_layer.get().presentsWithTransaction = YES;
      }
    }
    return std::make_unique<flutter::IOSSurfaceGL>(context, std::move(eagl_layer),
                                                   [_delegate platformViewsController]);
#if FLUTTER_SHELL_ENABLE_METAL
  } else if ([self.layer isKindOfClass:[CAMetalLayer class]]) {
    fml::scoped_nsobject<CAMetalLayer> metalLayer(
        reinterpret_cast<CAMetalLayer*>([self.layer retain]));
    if (flutter::IsIosEmbeddedViewsPreviewEnabled()) {
      if (@available(iOS 8.0, *)) {
        // TODO(amirh): only do this if there's an embedded view.
        // https://github.com/flutter/flutter/issues/24133
        metalLayer.get().presentsWithTransaction = YES;
      }
    }
    return std::make_unique<flutter::IOSSurfaceMetal>(std::move(metalLayer),
                                                      [_delegate platformViewsController]);
#endif  //  FLUTTER_SHELL_ENABLE_METAL
  } else {
    fml::scoped_nsobject<CALayer> layer(reinterpret_cast<CALayer*>([self.layer retain]));
    return std::make_unique<flutter::IOSSurfaceSoftware>(std::move(layer),
                                                         [_delegate platformViewsController]);
  }
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
