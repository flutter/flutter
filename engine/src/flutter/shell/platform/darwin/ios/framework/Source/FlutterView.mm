// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_software.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

@implementation FlutterView {
  id<FlutterViewEngineDelegate> _delegate;
  BOOL _isWideGamutEnabled;
}

- (instancetype)init {
  NSAssert(NO, @"FlutterView must initWithDelegate");
  return nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
  NSAssert(NO, @"FlutterView must initWithDelegate");
  return nil;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
  NSAssert(NO, @"FlutterView must initWithDelegate");
  return nil;
}

- (UIScreen*)screen {
  if (@available(iOS 13.0, *)) {
    return self.window.windowScene.screen;
  }
  return UIScreen.mainScreen;
}

- (BOOL)isWideGamutSupported {
#if TARGET_OS_SIMULATOR
  // As of Xcode 14.1, the wide gamut surface pixel formats are not supported by
  // the simulator.
  return NO;
#endif

  if (![_delegate isUsingImpeller]) {
    return NO;
  }

  // This predicates the decision on the capabilities of the iOS device's
  // display.  This means external displays will not support wide gamut if the
  // device's display doesn't support it.  It practice that should be never.
  return self.screen.traitCollection.displayGamut != UIDisplayGamutSRGB;
}

- (instancetype)initWithDelegate:(id<FlutterViewEngineDelegate>)delegate
                          opaque:(BOOL)opaque
                 enableWideGamut:(BOOL)isWideGamutEnabled {
  if (delegate == nil) {
    NSLog(@"FlutterView delegate was nil.");
    [self release];
    return nil;
  }

  self = [super initWithFrame:CGRectNull];

  if (self) {
    _delegate = delegate;
    _isWideGamutEnabled = isWideGamutEnabled;
    if (_isWideGamutEnabled && self.isWideGamutSupported) {
      FML_DLOG(WARNING) << "Rendering wide gamut colors is turned on but isn't "
                           "supported, downgrading the color gamut to sRGB.";
    }
    self.layer.opaque = opaque;

    // This line is necessary. CoreAnimation(or UIKit) may take this to do
    // something to compute the final frame presented on screen, if we don't set this,
    // it will make it take long time for us to take next CAMetalDrawable and will
    // cause constant junk during rendering.
    self.backgroundColor = UIColor.clearColor;
  }

  return self;
}

- (void)layoutSubviews {
  if ([self.layer isKindOfClass:NSClassFromString(@"CAMetalLayer")]) {
// It is a known Apple bug that CAMetalLayer incorrectly reports its supported
// SDKs. It is, in fact, available since iOS 8.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
    CAMetalLayer* layer = (CAMetalLayer*)self.layer;
#pragma clang diagnostic pop
    CGFloat screenScale = [UIScreen mainScreen].scale;
    layer.allowsGroupOpacity = YES;
    layer.contentsScale = screenScale;
    layer.rasterizationScale = screenScale;
    layer.framebufferOnly = flutter::Settings::kSurfaceDataAccessible ? NO : YES;
    if (_isWideGamutEnabled && self.isWideGamutSupported) {
      CGColorSpaceRef srgb = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
      layer.colorspace = srgb;
      CFRelease(srgb);
      layer.pixelFormat = MTLPixelFormatBGRA10_XR;
    }
  }

  [super layoutSubviews];
}

static BOOL _forceSoftwareRendering;

+ (BOOL)forceSoftwareRendering {
  return _forceSoftwareRendering;
}

+ (void)setForceSoftwareRendering:(BOOL)forceSoftwareRendering {
  _forceSoftwareRendering = forceSoftwareRendering;
}

+ (Class)layerClass {
  return flutter::GetCoreAnimationLayerClassForRenderingAPI(
      flutter::GetRenderingAPIForProcess(FlutterView.forceSoftwareRendering));
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

- (BOOL)isAccessibilityElement {
  // iOS does not provide an API to query whether the voice control
  // is turned on or off. It is likely at least one of the assitive
  // technologies is turned on if this method is called. If we do
  // not catch it in notification center, we will catch it here.
  //
  // TODO(chunhtai): Remove this workaround once iOS provides an
  // API to query whether voice control is enabled.
  // https://github.com/flutter/flutter/issues/76808.
  [_delegate flutterViewAccessibilityDidCall];
  return NO;
}

@end
