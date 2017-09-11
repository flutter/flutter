// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/shell.h"
#include "lib/fxl/synchronization/waitable_event.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

@interface FlutterView ()<UIInputViewAudioFeedback>

@end

@implementation FlutterView

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

- (BOOL)enableInputClicksWhenVisible {
  return YES;
}

void SnapshotRasterizer(fxl::WeakPtr<shell::Rasterizer> rasterizer,
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

  {
    flow::CompositorContext compositor_context(nullptr);
    auto frame = compositor_context.AcquireFrame(nullptr, &canvas, false /* instrumentation */);
    layer_tree->Raster(frame, false /* ignore raster cache. */);
  }

  canvas.flush();

  // Draw the bitmap to the system provided snapshotting context.
  SkCGDrawBitmap(context, bitmap, 0, 0);
}

void SnapshotContents(CGContextRef context, bool is_opaque) {
  // TODO(chinmaygarde): Currently, there is no way to get the rasterizer for
  // a particular platform view from the shell. But, for now, we only have one
  // platform view. So use that. Once we support multiple platform views, the
  // shell will need to provide a way to get the rasterizer for a specific
  // platform view.
  std::vector<fxl::WeakPtr<shell::Rasterizer>> registered_rasterizers;
  shell::Shell::Shared().GetRasterizers(&registered_rasterizers);
  for (auto& rasterizer : registered_rasterizers) {
    SnapshotRasterizer(rasterizer, context, is_opaque);
  }
}

void SnapshotContentsSync(CGContextRef context, UIView* view) {
  auto gpu_thread = blink::Threads::Gpu();

  if (!gpu_thread) {
    return;
  }

  fxl::AutoResetWaitableEvent latch;
  gpu_thread->PostTask([&latch, context, view]() {
    SnapshotContents(context, [view isOpaque]);
    latch.Signal();
  });
  latch.Wait();
}

// Override the default CALayerDelegate method so that APIs that attempt to
// screenshot the view display contents correctly. We cannot depend on
// reading
// GPU pixels directly because:
// 1: We dont use retained backing on the CAEAGLLayer.
// 2: The call is made of the platform thread and not the GPU thread.
// 3: There may be a software rasterizer.
- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
  SnapshotContentsSync(context, self);
}

@end
