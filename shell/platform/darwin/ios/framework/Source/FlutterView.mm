// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

@interface FlutterView () <UIInputViewAudioFeedback>

@end

@implementation FlutterView

- (FlutterViewController*)flutterViewController {
  // Find the first view controller in the responder chain and see if it is a FlutterViewController.
  for (UIResponder* responder = self.nextResponder; responder != nil;
       responder = responder.nextResponder) {
    if ([responder isKindOfClass:[UIViewController class]]) {
      if ([responder isKindOfClass:[FlutterViewController class]]) {
        return reinterpret_cast<FlutterViewController*>(responder);
      } else {
        // Should only happen if a non-FlutterViewController tries to somehow (via dynamic class
        // resolution or reparenting) set a FlutterView as its view.
        return nil;
      }
    }
  }
  return nil;
}

- (void)layoutSubviews {
  if ([self.layer isKindOfClass:[CAEAGLLayer class]]) {
    CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);
    layer.allowsGroupOpacity = YES;
    layer.opaque = YES;
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
    fml::scoped_nsobject<CAEAGLLayer> eagl_layer(
        reinterpret_cast<CAEAGLLayer*>([self.layer retain]));
    return std::make_unique<shell::IOSSurfaceGL>(std::move(eagl_layer));
  } else {
    fml::scoped_nsobject<CALayer> layer(reinterpret_cast<CALayer*>([self.layer retain]));
    return std::make_unique<shell::IOSSurfaceSoftware>(std::move(layer));
  }
}

- (BOOL)enableInputClicksWhenVisible {
  return YES;
}

static void SnapshotRasterizer(fml::WeakPtr<shell::Rasterizer> rasterizer,
                               CGContextRef context,
                               bool is_opaque) {
  if (!rasterizer) {
    return;
  }

  // Access the layer tree and assess the description of the backing store to
  // create for this snapshot.
  flow::LayerTree* layer_tree = rasterizer->GetLastLayerTree();
  if (layer_tree == nullptr) {
    return;
  }
  auto size = layer_tree->frame_size();
  if (size.isEmpty()) {
    return;
  }
  auto info = SkImageInfo::MakeN32(
      size.width(), size.height(),
      is_opaque ? SkAlphaType::kOpaque_SkAlphaType : SkAlphaType::kPremul_SkAlphaType);

  // Create the backing store and prepare for use.
  SkBitmap bitmap;
  bitmap.setInfo(info);
  if (!bitmap.tryAllocPixels()) {
    return;
  }

  // Create a canvas from the backing store and a single use compositor context
  // to draw into the canvas.

  SkCanvas canvas(bitmap);

  flow::CompositorContext compositor_context;

  if (auto frame = compositor_context.AcquireFrame(nullptr, &canvas, false /* instrumentation */)) {
    layer_tree->Preroll(*frame, true /* ignore raster cache */);
    layer_tree->Paint(*frame);
  }

  canvas.flush();

  // Draw the bitmap to the system provided snapshotting context.
  SkCGDrawBitmap(context, bitmap, 0, 0);
}

// Override the default CALayerDelegate method so that APIs that attempt to
// screenshot the view display contents correctly. We cannot depend on
// reading
// GPU pixels directly because:
// 1: We dont use retained backing on the CAEAGLLayer.
// 2: The call is made of the platform thread and not the GPU thread.
// 3: There may be a software rasterizer.
- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
  TRACE_EVENT0("flutter", "SnapshotFlutterView");
  FlutterViewController* controller = [self flutterViewController];

  if (controller == nil) {
    return;
  }

  auto& shell = [controller shell];

  fxl::AutoResetWaitableEvent latch;
  shell.GetTaskRunners().GetGPUTaskRunner()->PostTask(
      [&latch, rasterizer = shell.GetRasterizer(), context, opaque = layer.opaque]() {
        SnapshotRasterizer(std::move(rasterizer), context, opaque);
        latch.Signal();
      });
  latch.Wait();
}

@end
