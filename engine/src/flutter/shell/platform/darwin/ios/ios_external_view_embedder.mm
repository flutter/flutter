// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"
#include "fml/task_runner.h"

#include "flutter/common/constants.h"
#include "flutter/flow/surface_frame.h"
#include "flutter/flow/view_slicer.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewFrame.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/overlay_layer_pool.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"
#import "flutter/shell/platform/darwin/ios/platform_view_layer_conversion.h"

FLUTTER_ASSERT_ARC

namespace flutter {

IOSExternalViewEmbedder::IOSExternalViewEmbedder(
    __weak FlutterPlatformViewsController* platform_views_controller,
    const std::shared_ptr<IOSContext>& context)
    : platform_views_controller_(platform_views_controller),
      ios_context_(context),
      layer_pool_(std::make_shared<OverlayLayerPool>()) {
  FML_CHECK(ios_context_);
}

IOSExternalViewEmbedder::~IOSExternalViewEmbedder() {
  // The rasterizer destroys the embedder on the raster thread, but the overlay layers hold UIViews,
  // which must be released on the platform thread.
  // Post the layer pool to the platform thread so that the layers are destroyed there.
  __block std::shared_ptr<OverlayLayerPool> layer_pool = std::move(layer_pool_);
  [platform_task_runner_ runNowOrPostTask:^{
    layer_pool.reset();
  }];
}

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::GetRootCanvas() {
  // On iOS, the root surface is created from the on-screen render target. Only the surfaces for the
  // various overlays are controlled by this class.
  return nullptr;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::CancelFrame() {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CancelFrame");
  ResetFrameState();
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrepareFlutterView(DlISize frame_size, double device_pixel_ratio) {
  FML_DCHECK(device_pixel_ratio > 0);
  ResetFrameState();
  frame_size_ = frame_size;
  device_pixel_ratio_ = device_pixel_ratio;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PrerollCompositeEmbeddedView");
  DlRect view_bounds = DlRect::MakeSize(frame_size_);
  slices_.insert_or_assign(view_id, std::make_unique<DisplayListEmbedderViewSlice>(view_bounds));

  composition_order_.push_back(view_id);
  composition_params_[view_id] = std::move(*params);
}

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CompositeEmbeddedView");
  FML_DCHECK(slices_.find(view_id) != slices_.end());
  return slices_[view_id]->canvas();
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::SubmitFlutterView");

  // TODO(dkwingsmt): This class only supports rendering into the implicit view.
  // Properly support multi-view in the future.
  FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);
  FML_CHECK(platform_views_controller_);
  SubmitFrame(std::move(frame));
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::DidSubmitFrame");
}

// |ExternalViewEmbedder|
bool IOSExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushFilterToVisitedPlatformViews(
    const std::shared_ptr<DlImageFilter>& filter,
    const DlRect& filter_rect) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushImageFilter(filter, filter_rect);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushVisitedPlatformView(int64_t view_id) {
  visited_platform_views_.push_back(view_id);
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRectToVisitedPlatformViews(const DlRect& clip_rect) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipRect(clip_rect);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRRectToVisitedPlatformViews(const DlRoundRect& clip_rrect) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipRRect(clip_rrect);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipRSuperellipseToVisitedPlatformViews(
    const DlRoundSuperellipse& clip_rse) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipRSuperellipse(clip_rse);
  }
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushClipPathToVisitedPlatformViews(const DlPath& clip_path) {
  for (int64_t id : visited_platform_views_) {
    composition_params_[id].PushPlatformViewClipPath(clip_path);
  }
}

void IOSExternalViewEmbedder::SubmitFrame(std::unique_ptr<SurfaceFrame> background_frame) {
  TRACE_EVENT0("flutter", "PlatformViewsController::SubmitFrame");
  FlutterPlatformViewsController* controller = platform_views_controller_;

  // No platform views to render.
  if (controller.flutterView == nil || (composition_order_.empty() && !had_platform_views_)) {
    // No platform views to render but the FlutterView may need to be resized.
    if (controller.flutterView != nil) {
      __weak FlutterPlatformViewsController* weak_controller = controller;
      CGSize frame_size = CGSizeMake(frame_size_.width, frame_size_.height);
      [controller.taskRunner runNowOrPostTask:^{
        [weak_controller performResize:frame_size];
      }];
    }

    had_platform_views_ = false;
    background_frame->Submit();
    return;
  }
  had_platform_views_ = !composition_order_.empty();

  NSMutableArray<FlutterPlatformViewLayer*>* layers =
      [NSMutableArray arrayWithCapacity:composition_order_.size()];
  NSMutableDictionary<NSNumber*, FlutterPlatformViewOverlay*>* overlays =
      [NSMutableDictionary dictionary];
  std::vector<std::shared_ptr<OverlayLayer>> used_layers;
  std::vector<std::unique_ptr<SurfaceFrame>> surface_frames;
  surface_frames.reserve(composition_order_.size());
  std::unordered_map<int64_t, DlRect> view_rects;

  for (int64_t view_id : composition_order_) {
    const EmbeddedViewParams& params = composition_params_.at(view_id);
    view_rects[view_id] = params.finalBoundingRect();
    [layers
        addObject:GetPlatformViewLayerFromEmbeddedViewParams(view_id, params, device_pixel_ratio_)];
  }

  std::unordered_map<int64_t, DlRect> overlay_layers =
      SliceViews(background_frame->Canvas(), composition_order_, slices_, view_rects);

  size_t required_overlay_layers = 0;
  for (int64_t view_id : composition_order_) {
    std::unordered_map<int64_t, DlRect>::const_iterator overlay = overlay_layers.find(view_id);
    if (overlay == overlay_layers.end()) {
      continue;
    }
    required_overlay_layers++;
  }

  // If there are not sufficient overlay layers, we must construct them on the platform
  // thread, at least until we've refactored iOS surface creation to use IOSurfaces
  // instead of CALayers.
  CreateMissingOverlays(required_overlay_layers);

  for (int64_t view_id : composition_order_) {
    std::unordered_map<int64_t, DlRect>::const_iterator overlay = overlay_layers.find(view_id);
    if (overlay == overlay_layers.end()) {
      continue;
    }
    std::shared_ptr<OverlayLayer> layer = layer_pool_->GetNextLayer();
    if (!layer) {
      continue;
    }

    std::unique_ptr<SurfaceFrame> frame = layer->surface->AcquireFrame(frame_size_);
    // If frame is null, AcquireFrame already printed out an error message.
    if (!frame) {
      continue;
    }
    DlCanvas* overlay_canvas = frame->Canvas();
    int restore_count = overlay_canvas->GetSaveCount();
    overlay_canvas->Save();
    overlay_canvas->ClipRect(overlay->second);
    overlay_canvas->Clear(DlColor::kTransparent());
    slices_[view_id]->render_into(overlay_canvas);
    overlay_canvas->RestoreToCount(restore_count);

    // This flutter view is never the last in a frame, since we always submit the
    // underlay view last.
    frame->set_submit_info({.frame_boundary = false, .present_with_transaction = true});
    frame->Encode();
    const DlRect& rect = overlay->second;
    overlays[@(view_id)] = [[FlutterPlatformViewOverlay alloc]
        initWithView:layer->overlay_view
        clippingView:layer->overlay_view_wrapper
                rect:CGRectMake(rect.GetX(), rect.GetY(), rect.GetWidth(), rect.GetHeight())];
    used_layers.push_back(layer);
    surface_frames.push_back(std::move(frame));
  }

  auto previous_submit_info = background_frame->submit_info();
  background_frame->set_submit_info({
      .frame_damage = previous_submit_info.frame_damage,
      .buffer_damage = previous_submit_info.buffer_damage,
      .present_with_transaction = true,
  });
  background_frame->Encode();
  surface_frames.push_back(std::move(background_frame));

  // Mark all layers as available, so they can be used in the next frame.
  std::vector<std::shared_ptr<OverlayLayer>> unused_layers = layer_pool_->RemoveUnusedLayers();
  layer_pool_->RecycleLayers();

  NSMutableArray<UIView*>* unused_overlay_views =
      [NSMutableArray arrayWithCapacity:unused_layers.size()];
  for (const std::shared_ptr<OverlayLayer>& layer : unused_layers) {
    [unused_overlay_views addObject:layer->overlay_view_wrapper];
  }

  // The block holds the overlay layers so that their surfaces are not destroyed before the frame
  // has been presented.
  auto submit_surface_frames = fml::MakeCopyable([surface_frames = std::move(surface_frames),  //
                                                  used_layers = std::move(used_layers),        //
                                                  unused_layers = std::move(unused_layers)]() {
    for (const auto& frame : surface_frames) {
      frame->Submit();
    }
  });
  FlutterPlatformViewFrame* frame =
      [[FlutterPlatformViewFrame alloc] initWithLayers:layers
                                              overlays:overlays
                                    unusedOverlayViews:unused_overlay_views
                                      devicePixelRatio:device_pixel_ratio_
                                               present:^{
                                                 submit_surface_frames();
                                               }];

  [controller.taskRunner runNowOrPostTask:^{
    [controller presentFrame:frame];
  }];
}

void IOSExternalViewEmbedder::CreateMissingOverlays(size_t required_overlay_layers) {
  TRACE_EVENT0("flutter", "PlatformViewsController::CreateMissingLayers");

  if (required_overlay_layers <= layer_pool_->size()) {
    return;
  }
  auto missing_layer_count = required_overlay_layers - layer_pool_->size();

  // If the raster thread isn't merged, create layers on the platform thread and block until
  // complete. Capturing `this` here is fine since this is effectively synchronous (we block on the
  // latch right below).
  FlutterPlatformViewsController* controller = platform_views_controller_;
  platform_task_runner_ = controller.taskRunner;
  auto latch = std::make_shared<fml::CountDownLatch>(1u);
  [platform_task_runner_ runNowOrPostTask:^{
    MTLPixelFormat pixel_format = ((FlutterView*)controller.flutterView).pixelFormat;
    for (auto i = 0u; i < missing_layer_count; i++) {
      layer_pool_->CreateLayer(ios_context_, pixel_format);
    }
    latch->CountDown();
  }];
  if (![[NSThread currentThread] isMainThread]) {
    latch->Wait();
  }
}

void IOSExternalViewEmbedder::ResetFrameState() {
  slices_.clear();
  composition_order_.clear();
  composition_params_.clear();
  visited_platform_views_.clear();
}

}  // namespace flutter
