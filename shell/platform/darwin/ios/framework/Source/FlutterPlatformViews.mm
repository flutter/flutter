// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIGestureRecognizerSubclass.h>

#import "FlutterOverlayView.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_gl.h"

#include <list>
#include <map>
#include <memory>
#include <string>

#include "FlutterPlatformViews_Internal.h"
#include "flutter/flow/rtree.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/persistent_cache.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"

namespace flutter {

std::shared_ptr<FlutterPlatformViewLayer> FlutterPlatformViewLayerPool::GetLayer(
    GrContext* gr_context,
    std::shared_ptr<IOSContext> ios_context) {
  if (available_layer_index_ >= layers_.size()) {
    std::shared_ptr<FlutterPlatformViewLayer> layer;
    fml::scoped_nsobject<FlutterOverlayView> overlay_view;
    fml::scoped_nsobject<FlutterOverlayView> overlay_view_wrapper;

    if (!gr_context) {
      overlay_view.reset([[FlutterOverlayView alloc] init]);
      overlay_view_wrapper.reset([[FlutterOverlayView alloc] init]);

      std::unique_ptr<IOSSurface> ios_surface =
          [overlay_view.get() createSurface:std::move(ios_context)];
      std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface();

      layer = std::make_shared<FlutterPlatformViewLayer>(
          std::move(overlay_view), std::move(overlay_view_wrapper), std::move(ios_surface),
          std::move(surface));
    } else {
      CGFloat screenScale = [UIScreen mainScreen].scale;
      overlay_view.reset([[FlutterOverlayView alloc] initWithContentsScale:screenScale]);
      overlay_view_wrapper.reset([[FlutterOverlayView alloc] initWithContentsScale:screenScale]);

      std::unique_ptr<IOSSurface> ios_surface =
          [overlay_view.get() createSurface:std::move(ios_context)];
      std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface(gr_context);

      layer = std::make_shared<FlutterPlatformViewLayer>(
          std::move(overlay_view), std::move(overlay_view_wrapper), std::move(ios_surface),
          std::move(surface));
      layer->gr_context = gr_context;
    }
    // The overlay view wrapper masks the overlay view.
    // This is required to keep the backing surface size unchanged between frames.
    //
    // Otherwise, changing the size of the overlay would require a new surface,
    // which can be very expensive.
    //
    // This is the case of an animation in which the overlay size is changing in every frame.
    //
    // +------------------------+
    // |   overlay_view         |
    // |    +--------------+    |              +--------------+
    // |    |    wrapper   |    |  == mask =>  | overlay_view |
    // |    +--------------+    |              +--------------+
    // +------------------------+
    overlay_view_wrapper.get().clipsToBounds = YES;
    [overlay_view_wrapper.get() addSubview:overlay_view];
    layers_.push_back(layer);
  }
  std::shared_ptr<FlutterPlatformViewLayer> layer = layers_[available_layer_index_];
  if (gr_context != layer->gr_context) {
    layer->gr_context = gr_context;
    // The overlay already exists, but the GrContext was changed so we need to recreate
    // the rendering surface with the new GrContext.
    IOSSurface* ios_surface = layer->ios_surface.get();
    std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface(gr_context);
    layer->surface = std::move(surface);
  }
  available_layer_index_++;
  return layer;
}

void FlutterPlatformViewLayerPool::RecycleLayers() {
  available_layer_index_ = 0;
}

std::vector<std::shared_ptr<FlutterPlatformViewLayer>>
FlutterPlatformViewLayerPool::GetUnusedLayers() {
  std::vector<std::shared_ptr<FlutterPlatformViewLayer>> results;
  for (size_t i = available_layer_index_; i < layers_.size(); i++) {
    results.push_back(layers_[i]);
  }
  return results;
}

void FlutterPlatformViewsController::SetFlutterView(UIView* flutter_view) {
  flutter_view_.reset([flutter_view retain]);
}

void FlutterPlatformViewsController::SetFlutterViewController(
    UIViewController* flutter_view_controller) {
  flutter_view_controller_.reset([flutter_view_controller retain]);
}

void FlutterPlatformViewsController::OnMethodCall(FlutterMethodCall* call, FlutterResult& result) {
  if ([[call method] isEqualToString:@"create"]) {
    OnCreate(call, result);
  } else if ([[call method] isEqualToString:@"dispose"]) {
    OnDispose(call, result);
  } else if ([[call method] isEqualToString:@"acceptGesture"]) {
    OnAcceptGesture(call, result);
  } else if ([[call method] isEqualToString:@"rejectGesture"]) {
    OnRejectGesture(call, result);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

void FlutterPlatformViewsController::OnCreate(FlutterMethodCall* call, FlutterResult& result) {
  if (!flutter_view_.get()) {
    // Right now we assume we have a reference to FlutterView when creating a new view.
    // TODO(amirh): support this by setting the reference to FlutterView when it becomes available.
    // https://github.com/flutter/flutter/issues/23787
    result([FlutterError errorWithCode:@"create_failed"
                               message:@"can't create a view on a headless engine"
                               details:nil]);
    return;
  }
  NSDictionary<NSString*, id>* args = [call arguments];

  long viewId = [args[@"id"] longValue];
  std::string viewType([args[@"viewType"] UTF8String]);

  if (views_.count(viewId) != 0) {
    result([FlutterError errorWithCode:@"recreating_view"
                               message:@"trying to create an already created view"
                               details:[NSString stringWithFormat:@"view id: '%ld'", viewId]]);
  }

  NSObject<FlutterPlatformViewFactory>* factory = factories_[viewType].get();
  if (factory == nil) {
    result([FlutterError errorWithCode:@"unregistered_view_type"
                               message:@"trying to create a view with an unregistered type"
                               details:[NSString stringWithFormat:@"unregistered view type: '%@'",
                                                                  args[@"viewType"]]]);
    return;
  }

  id params = nil;
  if ([factory respondsToSelector:@selector(createArgsCodec)]) {
    NSObject<FlutterMessageCodec>* codec = [factory createArgsCodec];
    if (codec != nil && args[@"params"] != nil) {
      FlutterStandardTypedData* paramsData = args[@"params"];
      params = [codec decode:paramsData.data];
    }
  }

  NSObject<FlutterPlatformView>* embedded_view = [factory createWithFrame:CGRectZero
                                                           viewIdentifier:viewId
                                                                arguments:params];
  // Set a unique view identifier, so the platform view can be identified in unit tests.
  [embedded_view view].accessibilityIdentifier =
      [NSString stringWithFormat:@"platform_view[%ld]", viewId];
  views_[viewId] = fml::scoped_nsobject<NSObject<FlutterPlatformView>>([embedded_view retain]);

  FlutterTouchInterceptingView* touch_interceptor = [[[FlutterTouchInterceptingView alloc]
                  initWithEmbeddedView:embedded_view.view
                 flutterViewController:flutter_view_controller_.get()
      gestureRecognizersBlockingPolicy:gesture_recognizers_blocking_policies[viewType]]
      autorelease];

  touch_interceptors_[viewId] =
      fml::scoped_nsobject<FlutterTouchInterceptingView>([touch_interceptor retain]);
  root_views_[viewId] = fml::scoped_nsobject<UIView>([touch_interceptor retain]);

  result(nil);
}

void FlutterPlatformViewsController::OnDispose(FlutterMethodCall* call, FlutterResult& result) {
  NSNumber* arg = [call arguments];
  int64_t viewId = [arg longLongValue];

  if (views_.count(viewId) == 0) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to dispose an unknown"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }
  // We wait for next submitFrame to dispose views.
  views_to_dispose_.insert(viewId);
  result(nil);
}

void FlutterPlatformViewsController::OnAcceptGesture(FlutterMethodCall* call,
                                                     FlutterResult& result) {
  NSDictionary<NSString*, id>* args = [call arguments];
  int64_t viewId = [args[@"id"] longLongValue];

  if (views_.count(viewId) == 0) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to set gesture state for an unknown view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  FlutterTouchInterceptingView* view = touch_interceptors_[viewId].get();
  [view releaseGesture];

  result(nil);
}

void FlutterPlatformViewsController::OnRejectGesture(FlutterMethodCall* call,
                                                     FlutterResult& result) {
  NSDictionary<NSString*, id>* args = [call arguments];
  int64_t viewId = [args[@"id"] longLongValue];

  if (views_.count(viewId) == 0) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to set gesture state for an unknown view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  FlutterTouchInterceptingView* view = touch_interceptors_[viewId].get();
  [view blockGesture];

  result(nil);
}

void FlutterPlatformViewsController::RegisterViewFactory(
    NSObject<FlutterPlatformViewFactory>* factory,
    NSString* factoryId,
    FlutterPlatformViewGestureRecognizersBlockingPolicy gestureRecognizerBlockingPolicy) {
  std::string idString([factoryId UTF8String]);
  FML_CHECK(factories_.count(idString) == 0);
  factories_[idString] =
      fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>([factory retain]);
  gesture_recognizers_blocking_policies[idString] = gestureRecognizerBlockingPolicy;
}

void FlutterPlatformViewsController::SetFrameSize(SkISize frame_size) {
  frame_size_ = frame_size;
}

void FlutterPlatformViewsController::CancelFrame() {
  composition_order_ = active_composition_order_;
}

bool FlutterPlatformViewsController::HasPendingViewOperations() {
  if (!views_to_dispose_.empty()) {
    return true;
  }
  if (!views_to_recomposite_.empty()) {
    return true;
  }
  return active_composition_order_ != composition_order_;
}

const int FlutterPlatformViewsController::kDefaultMergedLeaseDuration;

PostPrerollResult FlutterPlatformViewsController::PostPrerollAction(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  const bool uiviews_mutated = HasPendingViewOperations();
  if (uiviews_mutated) {
    if (raster_thread_merger->IsMerged()) {
      raster_thread_merger->ExtendLeaseTo(kDefaultMergedLeaseDuration);
    } else {
      // Wait until |EndFrame| to merge the threads.
      merge_threads_ = true;
      CancelFrame();
      return PostPrerollResult::kResubmitFrame;
    }
  }
  return PostPrerollResult::kSuccess;
}

void FlutterPlatformViewsController::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  picture_recorders_[view_id] = std::make_unique<SkPictureRecorder>();

  auto rtree_factory = RTreeFactory();
  platform_view_rtrees_[view_id] = rtree_factory.getInstance();
  picture_recorders_[view_id]->beginRecording(SkRect::Make(frame_size_), &rtree_factory);

  composition_order_.push_back(view_id);

  if (current_composition_params_.count(view_id) == 1 &&
      current_composition_params_[view_id] == *params.get()) {
    // Do nothing if the params didn't change.
    return;
  }
  current_composition_params_[view_id] = EmbeddedViewParams(*params.get());
  views_to_recomposite_.insert(view_id);
}

NSObject<FlutterPlatformView>* FlutterPlatformViewsController::GetPlatformViewByID(int view_id) {
  if (views_.empty()) {
    return nil;
  }
  return views_[view_id].get();
}

std::vector<SkCanvas*> FlutterPlatformViewsController::GetCurrentCanvases() {
  std::vector<SkCanvas*> canvases;
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t view_id = composition_order_[i];
    canvases.push_back(picture_recorders_[view_id]->getRecordingCanvas());
  }
  return canvases;
}

int FlutterPlatformViewsController::CountClips(const MutatorsStack& mutators_stack) {
  std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator iter = mutators_stack.Bottom();
  int clipCount = 0;
  while (iter != mutators_stack.Top()) {
    if ((*iter)->IsClipType()) {
      clipCount++;
    }
    ++iter;
  }
  return clipCount;
}

UIView* FlutterPlatformViewsController::ReconstructClipViewsChain(int number_of_clips,
                                                                  UIView* platform_view,
                                                                  UIView* head_clip_view) {
  NSInteger indexInFlutterView = -1;
  if (head_clip_view.superview) {
    // TODO(cyanglaz): potentially cache the index of oldPlatformViewRoot to make this a O(1).
    // https://github.com/flutter/flutter/issues/35023
    indexInFlutterView = [flutter_view_.get().subviews indexOfObject:head_clip_view];
    [head_clip_view removeFromSuperview];
  }
  UIView* head = platform_view;
  int clipIndex = 0;
  // Re-use as much existing clip views as needed.
  while (head != head_clip_view && clipIndex < number_of_clips) {
    head = head.superview;
    clipIndex++;
  }
  // If there were not enough existing clip views, add more.
  while (clipIndex < number_of_clips) {
    ChildClippingView* clippingView =
        [[[ChildClippingView alloc] initWithFrame:flutter_view_.get().bounds] autorelease];
    [clippingView addSubview:head];
    head = clippingView;
    clipIndex++;
  }
  [head removeFromSuperview];

  if (indexInFlutterView > -1) {
    // The chain was previously attached; attach it to the same position.
    [flutter_view_.get() insertSubview:head atIndex:indexInFlutterView];
  }
  return head;
}

void FlutterPlatformViewsController::ApplyMutators(const MutatorsStack& mutators_stack,
                                                   UIView* embedded_view) {
  FML_DCHECK(CATransform3DEqualToTransform(embedded_view.layer.transform, CATransform3DIdentity));
  UIView* head = embedded_view;
  ResetAnchor(head.layer);

  std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator iter = mutators_stack.Bottom();
  while (iter != mutators_stack.Top()) {
    switch ((*iter)->GetType()) {
      case transform: {
        CATransform3D transform = GetCATransform3DFromSkMatrix((*iter)->GetMatrix());
        head.layer.transform = CATransform3DConcat(head.layer.transform, transform);
        break;
      }
      case clip_rect:
      case clip_rrect:
      case clip_path: {
        ChildClippingView* clipView = (ChildClippingView*)head.superview;
        clipView.layer.transform = CATransform3DIdentity;
        [clipView setClip:(*iter)->GetType()
                     rect:(*iter)->GetRect()
                    rrect:(*iter)->GetRRect()
                     path:(*iter)->GetPath()];
        ResetAnchor(clipView.layer);
        head = clipView;
        break;
      }
      case opacity:
        embedded_view.alpha = (*iter)->GetAlphaFloat() * embedded_view.alpha;
        break;
    }
    ++iter;
  }
  // Reverse scale based on screen scale.
  //
  // The UIKit frame is set based on the logical resolution instead of physical.
  // (https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html).
  // However, flow is based on the physical resolution. For example, 1000 pixels in flow equals
  // 500 points in UIKit. And until this point, we did all the calculation based on the flow
  // resolution. So we need to scale down to match UIKit's logical resolution.
  CGFloat screenScale = [UIScreen mainScreen].scale;
  head.layer.transform = CATransform3DConcat(
      head.layer.transform, CATransform3DMakeScale(1 / screenScale, 1 / screenScale, 1));
}

void FlutterPlatformViewsController::CompositeWithParams(int view_id,
                                                         const EmbeddedViewParams& params) {
  CGRect frame = CGRectMake(0, 0, params.sizePoints.width(), params.sizePoints.height());
  UIView* touchInterceptor = touch_interceptors_[view_id].get();
  touchInterceptor.layer.transform = CATransform3DIdentity;
  touchInterceptor.frame = frame;
  touchInterceptor.alpha = 1;

  int currentClippingCount = CountClips(params.mutatorsStack);
  int previousClippingCount = clip_count_[view_id];
  if (currentClippingCount != previousClippingCount) {
    clip_count_[view_id] = currentClippingCount;
    // If we have a different clipping count in this frame, we need to reconstruct the
    // ClippingChildView chain to prepare for `ApplyMutators`.
    UIView* oldPlatformViewRoot = root_views_[view_id].get();
    UIView* newPlatformViewRoot =
        ReconstructClipViewsChain(currentClippingCount, touchInterceptor, oldPlatformViewRoot);
    root_views_[view_id] = fml::scoped_nsobject<UIView>([newPlatformViewRoot retain]);
  }
  ApplyMutators(params.mutatorsStack, touchInterceptor);
}

SkCanvas* FlutterPlatformViewsController::CompositeEmbeddedView(int view_id) {
  // TODO(amirh): assert that this is running on the platform thread once we support the iOS
  // embedded views thread configuration.

  // Do nothing if the view doesn't need to be composited.
  if (views_to_recomposite_.count(view_id) == 0) {
    return picture_recorders_[view_id]->getRecordingCanvas();
  }
  CompositeWithParams(view_id, current_composition_params_[view_id]);
  views_to_recomposite_.erase(view_id);
  return picture_recorders_[view_id]->getRecordingCanvas();
}

void FlutterPlatformViewsController::Reset() {
  UIView* flutter_view = flutter_view_.get();
  for (UIView* sub_view in [flutter_view subviews]) {
    [sub_view removeFromSuperview];
  }
  views_.clear();
  composition_order_.clear();
  active_composition_order_.clear();
  picture_recorders_.clear();
  platform_view_rtrees_.clear();
  current_composition_params_.clear();
  clip_count_.clear();
  views_to_recomposite_.clear();
  layer_pool_->RecycleLayers();
}

SkRect FlutterPlatformViewsController::GetPlatformViewRect(int view_id) {
  UIView* platform_view = [views_[view_id].get() view];
  UIScreen* screen = [UIScreen mainScreen];
  CGRect platform_view_cgrect = [platform_view convertRect:platform_view.bounds
                                                    toView:flutter_view_];
  return SkRect::MakeXYWH(platform_view_cgrect.origin.x * screen.scale,    //
                          platform_view_cgrect.origin.y * screen.scale,    //
                          platform_view_cgrect.size.width * screen.scale,  //
                          platform_view_cgrect.size.height * screen.scale  //
  );
}

bool FlutterPlatformViewsController::SubmitFrame(GrContext* gr_context,
                                                 std::shared_ptr<IOSContext> ios_context,
                                                 SkCanvas* background_canvas) {
  if (merge_threads_) {
    // Threads are about to be merged, we drop everything from this frame
    // and possibly resubmit the same layer tree in the next frame.
    // Before merging thread, we know the code is not running on the main thread. Assert that
    FML_DCHECK(![[NSThread currentThread] isMainThread]);
    picture_recorders_.clear();
    composition_order_.clear();
    return true;
  }

  // Any UIKit related code has to run on main thread.
  // When on a non-main thread, we only allow the rest of the method to run if there is no
  // Pending UIView operations.
  FML_DCHECK([[NSThread currentThread] isMainThread] || !HasPendingViewOperations());

  DisposeViews();

  // Resolve all pending GPU operations before allocating a new surface.
  background_canvas->flush();
  // Clipping the background canvas before drawing the picture recorders requires to
  // save and restore the clip context.
  SkAutoCanvasRestore save(background_canvas, /*doSave=*/true);
  // Maps a platform view id to a vector of `FlutterPlatformViewLayer`.
  LayersMap platform_view_layers;

  auto did_submit = true;
  auto num_platform_views = composition_order_.size();

  for (size_t i = 0; i < num_platform_views; i++) {
    int64_t platform_view_id = composition_order_[i];
    sk_sp<RTree> rtree = platform_view_rtrees_[platform_view_id];
    sk_sp<SkPicture> picture = picture_recorders_[platform_view_id]->finishRecordingAsPicture();

    // Check if the current picture contains overlays that intersect with the
    // current platform view or any of the previous platform views.
    for (size_t j = i + 1; j > 0; j--) {
      int64_t current_platform_view_id = composition_order_[j - 1];
      SkRect platform_view_rect = GetPlatformViewRect(current_platform_view_id);
      std::list<SkRect> intersection_rects =
          rtree->searchNonOverlappingDrawnRects(platform_view_rect);
      auto allocation_size = intersection_rects.size();

      // For testing purposes, the overlay id is used to find the overlay view.
      // This is the index of the layer for the current platform view.
      auto overlay_id = platform_view_layers[current_platform_view_id].size();

      // If the max number of allocations per platform view is exceeded,
      // then join all the rects into a single one.
      //
      // TODO(egarciad): Consider making this configurable.
      // https://github.com/flutter/flutter/issues/52510
      if (allocation_size > kMaxLayerAllocations) {
        SkRect joined_rect;
        for (const SkRect& rect : intersection_rects) {
          joined_rect.join(rect);
        }
        // Replace the rects in the intersection rects list for a single rect that is
        // the union of all the rects in the list.
        intersection_rects.clear();
        intersection_rects.push_back(joined_rect);
      }
      for (SkRect& joined_rect : intersection_rects) {
        // Get the intersection rect between the current rect
        // and the platform view rect.
        joined_rect.intersect(platform_view_rect);
        // Subpixels in the platform may not align with the canvas subpixels.
        // To workaround it, round the floating point bounds and make the rect slighly larger.
        // For example, {0.3, 0.5, 3.1, 4.7} becomes {0, 0, 4, 5}.
        joined_rect.setLTRB(std::floor(joined_rect.left()), std::floor(joined_rect.top()),
                            std::ceil(joined_rect.right()), std::ceil(joined_rect.bottom()));
        // Clip the background canvas, so it doesn't contain any of the pixels drawn
        // on the overlay layer.
        background_canvas->clipRect(joined_rect, SkClipOp::kDifference);
        // Get a new host layer.
        std::shared_ptr<FlutterPlatformViewLayer> layer = GetLayer(gr_context,                //
                                                                   ios_context,               //
                                                                   picture,                   //
                                                                   joined_rect,               //
                                                                   current_platform_view_id,  //
                                                                   overlay_id                 //
        );
        did_submit &= layer->did_submit_last_frame;
        platform_view_layers[current_platform_view_id].push_back(layer);
        overlay_id++;
      }
    }
    background_canvas->drawPicture(picture);
  }
  // If a layer was allocated in the previous frame, but it's not used in the current frame,
  // then it can be removed from the scene.
  RemoveUnusedLayers();
  // Organize the layers by their z indexes.
  BringLayersIntoView(platform_view_layers);
  // Mark all layers as available, so they can be used in the next frame.
  layer_pool_->RecycleLayers();
  // Reset the composition order, so next frame starts empty.
  composition_order_.clear();

  return did_submit;
}

void FlutterPlatformViewsController::BringLayersIntoView(LayersMap layer_map) {
  UIView* flutter_view = flutter_view_.get();
  auto zIndex = 0;
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t platform_view_id = composition_order_[i];
    std::vector<std::shared_ptr<FlutterPlatformViewLayer>> layers = layer_map[platform_view_id];
    UIView* platform_view_root = root_views_[platform_view_id].get();

    if (platform_view_root.superview != flutter_view) {
      [flutter_view addSubview:platform_view_root];
    } else {
      platform_view_root.layer.zPosition = zIndex++;
    }
    for (const std::shared_ptr<FlutterPlatformViewLayer>& layer : layers) {
      if ([layer->overlay_view_wrapper superview] != flutter_view) {
        [flutter_view addSubview:layer->overlay_view_wrapper];
      } else {
        layer->overlay_view_wrapper.get().layer.zPosition = zIndex++;
      }
    }
    active_composition_order_.push_back(platform_view_id);
  }
}

void FlutterPlatformViewsController::EndFrame(
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) {
  if (merge_threads_) {
    raster_thread_merger->MergeWithLease(kDefaultMergedLeaseDuration);
    merge_threads_ = false;
  }
}

std::shared_ptr<FlutterPlatformViewLayer> FlutterPlatformViewsController::GetLayer(
    GrContext* gr_context,
    std::shared_ptr<IOSContext> ios_context,
    sk_sp<SkPicture> picture,
    SkRect rect,
    int64_t view_id,
    int64_t overlay_id) {
  std::shared_ptr<FlutterPlatformViewLayer> layer = layer_pool_->GetLayer(gr_context, ios_context);

  UIView* overlay_view_wrapper = layer->overlay_view_wrapper.get();
  auto screenScale = [UIScreen mainScreen].scale;
  // Set the size of the overlay view wrapper.
  // This wrapper view masks the overlay view.
  overlay_view_wrapper.frame = CGRectMake(rect.x() / screenScale, rect.y() / screenScale,
                                          rect.width() / screenScale, rect.height() / screenScale);
  // Set a unique view identifier, so the overlay wrapper can be identified in unit tests.
  overlay_view_wrapper.accessibilityIdentifier =
      [NSString stringWithFormat:@"platform_view[%lld].overlay[%lld]", view_id, overlay_id];

  UIView* overlay_view = layer->overlay_view.get();
  // Set the size of the overlay view.
  // This size is equal to the the device screen size.
  overlay_view.frame = flutter_view_.get().bounds;

  std::unique_ptr<SurfaceFrame> frame = layer->surface->AcquireFrame(frame_size_);
  // If frame is null, AcquireFrame already printed out an error message.
  if (!frame) {
    return layer;
  }
  SkCanvas* overlay_canvas = frame->SkiaCanvas();
  overlay_canvas->clear(SK_ColorTRANSPARENT);
  // Offset the picture since its absolute position on the scene is determined
  // by the position of the overlay view.
  overlay_canvas->translate(-rect.x(), -rect.y());
  overlay_canvas->drawPicture(picture);

  layer->did_submit_last_frame = frame->Submit();
  return layer;
}

void FlutterPlatformViewsController::RemoveUnusedLayers() {
  std::vector<std::shared_ptr<FlutterPlatformViewLayer>> layers = layer_pool_->GetUnusedLayers();
  for (const std::shared_ptr<FlutterPlatformViewLayer>& layer : layers) {
    [layer->overlay_view_wrapper removeFromSuperview];
  }

  std::unordered_set<int64_t> composition_order_set;
  for (int64_t view_id : composition_order_) {
    composition_order_set.insert(view_id);
  }
  // Remove unused platform views.
  for (int64_t view_id : active_composition_order_) {
    if (composition_order_set.find(view_id) == composition_order_set.end()) {
      UIView* platform_view_root = root_views_[view_id].get();
      [platform_view_root removeFromSuperview];
    }
  }
}

void FlutterPlatformViewsController::DisposeViews() {
  if (views_to_dispose_.empty()) {
    return;
  }

  FML_DCHECK([[NSThread currentThread] isMainThread]);

  for (int64_t viewId : views_to_dispose_) {
    UIView* root_view = root_views_[viewId].get();
    [root_view removeFromSuperview];
    views_.erase(viewId);
    touch_interceptors_.erase(viewId);
    root_views_.erase(viewId);
    current_composition_params_.erase(viewId);
    clip_count_.erase(viewId);
    views_to_recomposite_.erase(viewId);
  }
  views_to_dispose_.clear();
}

}  // namespace flutter

// This recognizers delays touch events from being dispatched to the responder chain until it failed
// recognizing a gesture.
//
// We only fail this recognizer when asked to do so by the Flutter framework (which does so by
// invoking an acceptGesture method on the platform_views channel). And this is how we allow the
// Flutter framework to delay or prevent the embedded view from getting a touch sequence.
@interface DelayingGestureRecognizer : UIGestureRecognizer <UIGestureRecognizerDelegate>

// Indicates that if the `DelayingGestureRecognizer`'s state should be set to
// `UIGestureRecognizerStateEnded` during next `touchesEnded` call.
@property(nonatomic) bool shouldEndInNextTouchesEnded;

// Indicates that the `DelayingGestureRecognizer`'s `touchesEnded` has been invoked without
// setting the state to `UIGestureRecognizerStateEnded`.
@property(nonatomic) bool touchedEndedWithoutBlocking;

- (instancetype)initWithTarget:(id)target
                        action:(SEL)action
          forwardingRecognizer:(UIGestureRecognizer*)forwardingRecognizer;
@end

// While the DelayingGestureRecognizer is preventing touches from hitting the responder chain
// the touch events are not arriving to the FlutterView (and thus not arriving to the Flutter
// framework). We use this gesture recognizer to dispatch the events directly to the FlutterView
// while during this phase.
//
// If the Flutter framework decides to dispatch events to the embedded view, we fail the
// DelayingGestureRecognizer which sends the events up the responder chain. But since the events
// are handled by the embedded view they are not delivered to the Flutter framework in this phase
// as well. So during this phase as well the ForwardingGestureRecognizer dispatched the events
// directly to the FlutterView.
@interface ForwardingGestureRecognizer : UIGestureRecognizer <UIGestureRecognizerDelegate>
- (instancetype)initWithTarget:(id)target
         flutterViewController:(UIViewController*)flutterViewController;
@end

@implementation FlutterTouchInterceptingView {
  fml::scoped_nsobject<DelayingGestureRecognizer> _delayingRecognizer;
  FlutterPlatformViewGestureRecognizersBlockingPolicy _blockingPolicy;
}
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
               flutterViewController:(UIViewController*)flutterViewController
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)blockingPolicy {
  self = [super initWithFrame:embeddedView.frame];
  if (self) {
    self.multipleTouchEnabled = YES;
    embeddedView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    [self addSubview:embeddedView];

    ForwardingGestureRecognizer* forwardingRecognizer =
        [[[ForwardingGestureRecognizer alloc] initWithTarget:self
                                       flutterViewController:flutterViewController] autorelease];

    _delayingRecognizer.reset([[DelayingGestureRecognizer alloc]
              initWithTarget:self
                      action:nil
        forwardingRecognizer:forwardingRecognizer]);
    _blockingPolicy = blockingPolicy;

    [self addGestureRecognizer:_delayingRecognizer.get()];
    [self addGestureRecognizer:forwardingRecognizer];
  }
  return self;
}

- (void)releaseGesture {
  _delayingRecognizer.get().state = UIGestureRecognizerStateFailed;
}

- (void)blockGesture {
  switch (_blockingPolicy) {
    case FlutterPlatformViewGestureRecognizersBlockingPolicyEager:
      // We block all other gesture recognizers immediately in this policy.
      _delayingRecognizer.get().state = UIGestureRecognizerStateEnded;
      break;
    case FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded:
      if (_delayingRecognizer.get().touchedEndedWithoutBlocking) {
        // If touchesEnded of the `DelayingGesureRecognizer` has been already invoked,
        // we want to set the state of the `DelayingGesureRecognizer` to
        // `UIGestureRecognizerStateEnded` as soon as possible.
        _delayingRecognizer.get().state = UIGestureRecognizerStateEnded;
      } else {
        // If touchesEnded of the `DelayingGesureRecognizer` has not been invoked,
        // We will set a flag to notify the `DelayingGesureRecognizer` to set the state to
        // `UIGestureRecognizerStateEnded` when touchesEnded is called.
        _delayingRecognizer.get().shouldEndInNextTouchesEnded = YES;
      }
      break;
    default:
      break;
  }
}

// We want the intercepting view to consume the touches and not pass the touches up to the parent
// view. Make the touch event method not call super will not pass the touches up to the parent view.
// Hence we overide the touch event methods and do nothing.
- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
}

- (void)touchesMoved:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
}

@end

@implementation DelayingGestureRecognizer {
  fml::scoped_nsobject<UIGestureRecognizer> _forwardingRecognizer;
}

- (instancetype)initWithTarget:(id)target
                        action:(SEL)action
          forwardingRecognizer:(UIGestureRecognizer*)forwardingRecognizer {
  self = [super initWithTarget:target action:action];
  if (self) {
    self.delaysTouchesBegan = YES;
    self.delaysTouchesEnded = YES;
    self.delegate = self;
    self.shouldEndInNextTouchesEnded = NO;
    self.touchedEndedWithoutBlocking = NO;
    _forwardingRecognizer.reset([forwardingRecognizer retain]);
  }
  return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  // The forwarding gesture recognizer should always get all touch events, so it should not be
  // required to fail by any other gesture recognizer.
  return otherGestureRecognizer != _forwardingRecognizer.get() && otherGestureRecognizer != self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
  return otherGestureRecognizer == self;
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  self.touchedEndedWithoutBlocking = NO;
  [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
  if (self.shouldEndInNextTouchesEnded) {
    self.state = UIGestureRecognizerStateEnded;
    self.shouldEndInNextTouchesEnded = NO;
  } else {
    self.touchedEndedWithoutBlocking = YES;
  }
  [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  self.state = UIGestureRecognizerStateFailed;
}
@end

@implementation ForwardingGestureRecognizer {
  // We can't dispatch events to the framework without this back pointer.
  // This is a weak reference, the ForwardingGestureRecognizer is owned by the
  // FlutterTouchInterceptingView which is strong referenced only by the FlutterView,
  // which is strongly referenced by the FlutterViewController.
  // So this is safe as when FlutterView is deallocated the reference to ForwardingGestureRecognizer
  // will go away.
  UIViewController* _flutterViewController;
  // Counting the pointers that has started in one touch sequence.
  NSInteger _currentTouchPointersCount;
}

- (instancetype)initWithTarget:(id)target
         flutterViewController:(UIViewController*)flutterViewController {
  self = [super initWithTarget:target action:nil];
  if (self) {
    self.delegate = self;
    _flutterViewController = flutterViewController;
    _currentTouchPointersCount = 0;
  }
  return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController touchesBegan:touches withEvent:event];
  _currentTouchPointersCount += touches.count;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController touchesEnded:touches withEvent:event];
  _currentTouchPointersCount -= touches.count;
  // Touches in one touch sequence are sent to the touchesEnded method separately if different
  // fingers stop touching the screen at different time. So one touchesEnded method triggering does
  // not necessarially mean the touch sequence has ended. We Only set the state to
  // UIGestureRecognizerStateFailed when all the touches in the current touch sequence is ended.
  if (_currentTouchPointersCount == 0) {
    self.state = UIGestureRecognizerStateFailed;
  }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController touchesCancelled:touches withEvent:event];
  _currentTouchPointersCount = 0;
  self.state = UIGestureRecognizerStateFailed;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  return YES;
}
@end
