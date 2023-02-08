// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIGestureRecognizerSubclass.h>

#include <list>
#include <map>
#include <memory>
#include <string>

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/flow/rtree.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterOverlayView.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"

static const NSUInteger kFlutterClippingMaskViewPoolCapacity = 5;

@implementation UIView (FirstResponder)
- (BOOL)flt_hasFirstResponderInViewHierarchySubtree {
  if (self.isFirstResponder) {
    return YES;
  }
  for (UIView* subview in self.subviews) {
    if (subview.flt_hasFirstResponderInViewHierarchySubtree) {
      return YES;
    }
  }
  return NO;
}
@end

// Determines if the `clip_rect` from a clipRect mutator contains the
// `platformview_boundingrect`.
//
// `clip_rect` is in its own coordinate space. The rect needs to be transformed by
// `transform_matrix` to be in the coordinate space where the PlatformView is displayed.
//
// `platformview_boundingrect` is the final bounding rect of the PlatformView in the coordinate
// space where the PlatformView is displayed.
static bool ClipRectContainsPlatformViewBoundingRect(const SkRect& clip_rect,
                                                     const SkRect& platformview_boundingrect,
                                                     const SkMatrix& transform_matrix) {
  SkRect transformed_rect = transform_matrix.mapRect(clip_rect);
  return transformed_rect.contains(platformview_boundingrect);
}

// Determines if the `clipRRect` from a clipRRect mutator contains the
// `platformview_boundingrect`.
//
// `clip_rrect` is in its own coordinate space. The rrect needs to be transformed by
// `transform_matrix` to be in the coordinate space where the PlatformView is displayed.
//
// `platformview_boundingrect` is the final bounding rect of the PlatformView in the coordinate
// space where the PlatformView is displayed.
static bool ClipRRectContainsPlatformViewBoundingRect(const SkRRect& clip_rrect,
                                                      const SkRect& platformview_boundingrect,
                                                      const SkMatrix& transform_matrix) {
  SkVector upper_left = clip_rrect.radii(SkRRect::Corner::kUpperLeft_Corner);
  SkVector upper_right = clip_rrect.radii(SkRRect::Corner::kUpperRight_Corner);
  SkVector lower_right = clip_rrect.radii(SkRRect::Corner::kLowerRight_Corner);
  SkVector lower_left = clip_rrect.radii(SkRRect::Corner::kLowerLeft_Corner);
  SkScalar transformed_upper_left_x = transform_matrix.mapRadius(upper_left.x());
  SkScalar transformed_upper_left_y = transform_matrix.mapRadius(upper_left.y());
  SkScalar transformed_upper_right_x = transform_matrix.mapRadius(upper_right.x());
  SkScalar transformed_upper_right_y = transform_matrix.mapRadius(upper_right.y());
  SkScalar transformed_lower_right_x = transform_matrix.mapRadius(lower_right.x());
  SkScalar transformed_lower_right_y = transform_matrix.mapRadius(lower_right.y());
  SkScalar transformed_lower_left_x = transform_matrix.mapRadius(lower_left.x());
  SkScalar transformed_lower_left_y = transform_matrix.mapRadius(lower_left.y());
  SkRect transformed_clip_rect = transform_matrix.mapRect(clip_rrect.rect());
  SkRRect transformed_rrect;
  SkVector corners[] = {{transformed_upper_left_x, transformed_upper_left_y},
                        {transformed_upper_right_x, transformed_upper_right_y},
                        {transformed_lower_right_x, transformed_lower_right_y},
                        {transformed_lower_left_x, transformed_lower_left_y}};
  transformed_rrect.setRectRadii(transformed_clip_rect, corners);
  return transformed_rrect.contains(platformview_boundingrect);
}

namespace flutter {
// Becomes NO if Apple's API changes and blurred backdrop filters cannot be applied.
BOOL canApplyBlurBackdrop = YES;

std::shared_ptr<FlutterPlatformViewLayer> FlutterPlatformViewLayerPool::GetLayer(
    GrDirectContext* gr_context,
    const std::shared_ptr<IOSContext>& ios_context) {
  if (available_layer_index_ >= layers_.size()) {
    std::shared_ptr<FlutterPlatformViewLayer> layer;
    fml::scoped_nsobject<FlutterOverlayView> overlay_view;
    fml::scoped_nsobject<FlutterOverlayView> overlay_view_wrapper;

    if (!gr_context) {
      overlay_view.reset([[FlutterOverlayView alloc] init]);
      overlay_view_wrapper.reset([[FlutterOverlayView alloc] init]);

      auto ca_layer = fml::scoped_nsobject<CALayer>{[[overlay_view.get() layer] retain]};
      std::unique_ptr<IOSSurface> ios_surface = IOSSurface::Create(ios_context, ca_layer);
      std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface();

      layer = std::make_shared<FlutterPlatformViewLayer>(
          std::move(overlay_view), std::move(overlay_view_wrapper), std::move(ios_surface),
          std::move(surface));
    } else {
      CGFloat screenScale = [UIScreen mainScreen].scale;
      overlay_view.reset([[FlutterOverlayView alloc] initWithContentsScale:screenScale]);
      overlay_view_wrapper.reset([[FlutterOverlayView alloc] initWithContentsScale:screenScale]);

      auto ca_layer = fml::scoped_nsobject<CALayer>{[[overlay_view.get() layer] retain]};
      std::unique_ptr<IOSSurface> ios_surface = IOSSurface::Create(ios_context, ca_layer);
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
    layer->overlay_view_wrapper.get().clipsToBounds = YES;
    [layer->overlay_view_wrapper.get() addSubview:layer->overlay_view];
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

UIViewController* FlutterPlatformViewsController::getFlutterViewController() {
  return flutter_view_controller_.get();
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
  NSDictionary<NSString*, id>* args = [call arguments];

  long viewId = [args[@"id"] longValue];
  NSString* viewTypeString = args[@"viewType"];
  std::string viewType(viewTypeString.UTF8String);

  if (views_.count(viewId) != 0) {
    result([FlutterError errorWithCode:@"recreating_view"
                               message:@"trying to create an already created view"
                               details:[NSString stringWithFormat:@"view id: '%ld'", viewId]]);
  }

  NSObject<FlutterPlatformViewFactory>* factory = factories_[viewType].get();
  if (factory == nil) {
    result([FlutterError
        errorWithCode:@"unregistered_view_type"
              message:[NSString stringWithFormat:@"A UIKitView widget is trying to create a "
                                                 @"PlatformView with an unregistered type: < %@ >",
                                                 viewTypeString]
              details:@"If you are the author of the PlatformView, make sure `registerViewFactory` "
                      @"is invoked.\n"
                      @"See: "
                      @"https://docs.flutter.dev/development/platform-integration/"
                      @"platform-views#on-the-platform-side-1 for more details.\n"
                      @"If you are not the author of the PlatformView, make sure to call "
                      @"`GeneratedPluginRegistrant.register`."]);
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
  UIView* platform_view = [embedded_view view];
  // Set a unique view identifier, so the platform view can be identified in unit tests.
  platform_view.accessibilityIdentifier = [NSString stringWithFormat:@"platform_view[%ld]", viewId];
  views_[viewId] = fml::scoped_nsobject<NSObject<FlutterPlatformView>>([embedded_view retain]);

  FlutterTouchInterceptingView* touch_interceptor = [[[FlutterTouchInterceptingView alloc]
                  initWithEmbeddedView:platform_view
               platformViewsController:GetWeakPtr()
      gestureRecognizersBlockingPolicy:gesture_recognizers_blocking_policies[viewType]]
      autorelease];

  touch_interceptors_[viewId] =
      fml::scoped_nsobject<FlutterTouchInterceptingView>([touch_interceptor retain]);

  ChildClippingView* clipping_view =
      [[[ChildClippingView alloc] initWithFrame:CGRectZero] autorelease];
  [clipping_view addSubview:touch_interceptor];
  root_views_[viewId] = fml::scoped_nsobject<UIView>([clipping_view retain]);

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

void FlutterPlatformViewsController::BeginFrame(SkISize frame_size) {
  ResetFrameState();
  frame_size_ = frame_size;
}

void FlutterPlatformViewsController::CancelFrame() {
  ResetFrameState();
}

// TODO(cyanglaz): https://github.com/flutter/flutter/issues/56474
// Make this method check if there are pending view operations instead.
// Also rename it to `HasPendingViewOperations`.
bool FlutterPlatformViewsController::HasPlatformViewThisOrNextFrame() {
  return !composition_order_.empty() || !active_composition_order_.empty();
}

const int FlutterPlatformViewsController::kDefaultMergedLeaseDuration;

PostPrerollResult FlutterPlatformViewsController::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  // TODO(cyanglaz): https://github.com/flutter/flutter/issues/56474
  // Rename `has_platform_view` to `view_mutated` when the above issue is resolved.
  if (!HasPlatformViewThisOrNextFrame()) {
    return PostPrerollResult::kSuccess;
  }
  if (!raster_thread_merger->IsMerged()) {
    // The raster thread merger may be disabled if the rasterizer is being
    // created or teared down.
    //
    // In such cases, the current frame is dropped, and a new frame is attempted
    // with the same layer tree.
    //
    // Eventually, the frame is submitted once this method returns `kSuccess`.
    // At that point, the raster tasks are handled on the platform thread.
    CancelFrame();
    return PostPrerollResult::kSkipAndRetryFrame;
  }
  // If the post preroll action is successful, we will display platform views in the current frame.
  // In order to sync the rendering of the platform views (quartz) with skia's rendering,
  // We need to begin an explicit CATransaction. This transaction needs to be submitted
  // after the current frame is submitted.
  BeginCATransaction();
  raster_thread_merger->ExtendLeaseTo(kDefaultMergedLeaseDuration);
  return PostPrerollResult::kSuccess;
}

void FlutterPlatformViewsController::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  if (should_resubmit_frame) {
    raster_thread_merger->MergeWithLease(kDefaultMergedLeaseDuration);
  }
}

void FlutterPlatformViewsController::PushFilterToVisitedPlatformViews(
    const std::shared_ptr<const DlImageFilter>& filter,
    const SkRect& filter_rect) {
  for (int64_t id : visited_platform_views_) {
    EmbeddedViewParams params = current_composition_params_[id];
    params.PushImageFilter(filter, filter_rect);
    current_composition_params_[id] = params;
  }
}

void FlutterPlatformViewsController::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  // All the CATransactions should be committed by the end of the last frame,
  // so catransaction_added_ must be false.
  FML_DCHECK(!catransaction_added_);

  SkRect view_bounds = SkRect::Make(frame_size_);
  std::unique_ptr<EmbedderViewSlice> view;
  if (params->display_list_enabled()) {
    view = std::make_unique<DisplayListEmbedderViewSlice>(view_bounds);
  } else {
    view = std::make_unique<SkPictureEmbedderViewSlice>(view_bounds);
  }
  slices_.insert_or_assign(view_id, std::move(view));

  composition_order_.push_back(view_id);

  if (current_composition_params_.count(view_id) == 1 &&
      current_composition_params_[view_id] == *params.get()) {
    // Do nothing if the params didn't change.
    return;
  }
  current_composition_params_[view_id] = EmbeddedViewParams(*params.get());
  views_to_recomposite_.insert(view_id);
}

UIView* FlutterPlatformViewsController::GetPlatformViewByID(int view_id) {
  if (views_.empty()) {
    return nil;
  }
  return [touch_interceptors_[view_id].get() embeddedView];
}

long FlutterPlatformViewsController::FindFirstResponderPlatformViewId() {
  for (auto const& [id, root_view] : root_views_) {
    if ((UIView*)(root_view.get()).flt_hasFirstResponderInViewHierarchySubtree) {
      return id;
    }
  }
  return -1;
}

std::vector<SkCanvas*> FlutterPlatformViewsController::GetCurrentCanvases() {
  std::vector<SkCanvas*> canvases;
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t view_id = composition_order_[i];
    canvases.push_back(slices_[view_id]->canvas());
  }
  return canvases;
}

std::vector<DisplayListBuilder*> FlutterPlatformViewsController::GetCurrentBuilders() {
  std::vector<DisplayListBuilder*> builders;
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t view_id = composition_order_[i];
    builders.push_back(slices_[view_id]->builder());
  }
  return builders;
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

void FlutterPlatformViewsController::ClipViewSetMaskView(UIView* clipView) {
  if (clipView.maskView) {
    return;
  }
  UIView* flutterView = flutter_view_.get();
  CGRect frame =
      CGRectMake(-clipView.frame.origin.x, -clipView.frame.origin.y,
                 CGRectGetWidth(flutterView.bounds), CGRectGetHeight(flutterView.bounds));
  clipView.maskView = [mask_view_pool_.get() getMaskViewWithFrame:frame];
}

void FlutterPlatformViewsController::ApplyMutators(const MutatorsStack& mutators_stack,
                                                   UIView* embedded_view,
                                                   const SkRect& bounding_rect) {
  if (flutter_view_ == nullptr) {
    return;
  }
  FML_DCHECK(CATransform3DEqualToTransform(embedded_view.layer.transform, CATransform3DIdentity));
  ResetAnchor(embedded_view.layer);
  ChildClippingView* clipView = (ChildClippingView*)embedded_view.superview;

  SkMatrix transformMatrix;
  NSMutableArray* blurFilters = [[[NSMutableArray alloc] init] autorelease];
  FML_DCHECK(!clipView.maskView ||
             [clipView.maskView isKindOfClass:[FlutterClippingMaskView class]]);
  if (mask_view_pool_.get() == nil) {
    mask_view_pool_.reset([[FlutterClippingMaskViewPool alloc]
        initWithCapacity:kFlutterClippingMaskViewPoolCapacity]);
  }
  [mask_view_pool_.get() recycleMaskViews];
  clipView.maskView = nil;
  auto iter = mutators_stack.Begin();
  while (iter != mutators_stack.End()) {
    switch ((*iter)->GetType()) {
      case kTransform: {
        transformMatrix.preConcat((*iter)->GetMatrix());
        break;
      }
      case kClipRect: {
        if (ClipRectContainsPlatformViewBoundingRect((*iter)->GetRect(), bounding_rect,
                                                     transformMatrix)) {
          break;
        }
        ClipViewSetMaskView(clipView);
        [(FlutterClippingMaskView*)clipView.maskView clipRect:(*iter)->GetRect()
                                                       matrix:transformMatrix];
        break;
      }
      case kClipRRect: {
        if (ClipRRectContainsPlatformViewBoundingRect((*iter)->GetRRect(), bounding_rect,
                                                      transformMatrix)) {
          break;
        }
        ClipViewSetMaskView(clipView);
        [(FlutterClippingMaskView*)clipView.maskView clipRRect:(*iter)->GetRRect()
                                                        matrix:transformMatrix];
        break;
      }
      case kClipPath: {
        // TODO(cyanglaz): Find a way to pre-determine if path contains the PlatformView boudning
        // rect. See `ClipRRectContainsPlatformViewBoundingRect`.
        // https://github.com/flutter/flutter/issues/118650
        ClipViewSetMaskView(clipView);
        [(FlutterClippingMaskView*)clipView.maskView clipPath:(*iter)->GetPath()
                                                       matrix:transformMatrix];
        break;
      }
      case kOpacity:
        embedded_view.alpha = (*iter)->GetAlphaFloat() * embedded_view.alpha;
        break;
      case kBackdropFilter: {
        // Only support DlBlurImageFilter for BackdropFilter.
        if (!canApplyBlurBackdrop || !(*iter)->GetFilterMutation().GetFilter().asBlur()) {
          break;
        }
        CGRect filterRect =
            flutter::GetCGRectFromSkRect((*iter)->GetFilterMutation().GetFilterRect());
        // `filterRect` reprents the rect that should be filtered inside the `flutter_view_`.
        // The `PlatformViewFilter` needs the frame inside the `clipView` that needs to be
        // filtered.
        if (CGRectIsNull(CGRectIntersection(filterRect, clipView.frame))) {
          break;
        }
        CGRect intersection = CGRectIntersection(filterRect, clipView.frame);
        CGRect frameInClipView = [flutter_view_.get() convertRect:intersection toView:clipView];
        // sigma_x is arbitrarily chosen as the radius value because Quartz sets
        // sigma_x and sigma_y equal to each other. DlBlurImageFilter's Tile Mode
        // is not supported in Quartz's gaussianBlur CAFilter, so it is not used
        // to blur the PlatformView.
        CGFloat blurRadius = (*iter)->GetFilterMutation().GetFilter().asBlur()->sigma_x();
        UIVisualEffectView* visualEffectView = [[[UIVisualEffectView alloc]
            initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]] autorelease];
        PlatformViewFilter* filter =
            [[[PlatformViewFilter alloc] initWithFrame:frameInClipView
                                            blurRadius:blurRadius
                                      visualEffectView:visualEffectView] autorelease];
        if (!filter) {
          canApplyBlurBackdrop = NO;
        } else {
          [blurFilters addObject:filter];
        }
        break;
      }
    }
    ++iter;
  }

  if (canApplyBlurBackdrop) {
    [clipView applyBlurBackdropFilters:blurFilters];
  }

  CGFloat screenScale = [UIScreen mainScreen].scale;
  // The UIKit frame is set based on the logical resolution (points) instead of physical.
  // (https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html).
  // However, flow is based on the physical resolution. For example, 1000 pixels in flow equals
  // 500 points in UIKit for devices that has screenScale of 2. We need to scale the transformMatrix
  // down to the logical resoltion before applying it to the layer of PlatformView.
  transformMatrix.postScale(1 / screenScale, 1 / screenScale);

  // Reverse the offset of the clipView.
  // The clipView's frame includes the final translate of the final transform matrix.
  // Thus, this translate needs to be reversed so the platform view can layout at the correct
  // offset.
  //
  // Note that the transforms are not applied to the clipping paths because clipping paths happen on
  // the mask view, whose origin is always (0,0) to the flutter_view.
  transformMatrix.postTranslate(-clipView.frame.origin.x, -clipView.frame.origin.y);

  embedded_view.layer.transform = flutter::GetCATransform3DFromSkMatrix(transformMatrix);
}

void FlutterPlatformViewsController::CompositeWithParams(int view_id,
                                                         const EmbeddedViewParams& params) {
  CGRect frame = CGRectMake(0, 0, params.sizePoints().width(), params.sizePoints().height());
  FlutterTouchInterceptingView* touchInterceptor = touch_interceptors_[view_id].get();
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
  FML_DCHECK(CGPointEqualToPoint([touchInterceptor embeddedView].frame.origin, CGPointZero));
  if (non_zero_origin_views_.find(view_id) == non_zero_origin_views_.end() &&
      !CGPointEqualToPoint([touchInterceptor embeddedView].frame.origin, CGPointZero)) {
    non_zero_origin_views_.insert(view_id);
    NSLog(
        @"A Embedded PlatformView's origin is not CGPointZero.\n"
         "  View id: %@\n"
         "  View info: \n %@ \n"
         "A non-zero origin might cause undefined behavior.\n"
         "See https://github.com/flutter/flutter/issues/109700 for more details.\n"
         "If you are the author of the PlatformView, please update the implementation of the "
         "PlatformView to have a (0, 0) origin.\n"
         "If you have a valid case of using a non-zero origin, "
         "please leave a comment at https://github.com/flutter/flutter/issues/109700 with details.",
        @(view_id), [touchInterceptor embeddedView]);
  }
#endif
  touchInterceptor.layer.transform = CATransform3DIdentity;
  touchInterceptor.frame = frame;
  touchInterceptor.alpha = 1;

  const MutatorsStack& mutatorStack = params.mutatorsStack();
  UIView* clippingView = root_views_[view_id].get();
  // The frame of the clipping view should be the final bounding rect.
  // Because the translate matrix in the Mutator Stack also includes the offset,
  // when we apply the transforms matrix in |ApplyMutators|, we need
  // to remember to do a reverse translate.
  const SkRect& rect = params.finalBoundingRect();
  CGFloat screenScale = [UIScreen mainScreen].scale;
  clippingView.frame = CGRectMake(rect.x() / screenScale, rect.y() / screenScale,
                                  rect.width() / screenScale, rect.height() / screenScale);
  ApplyMutators(mutatorStack, touchInterceptor, rect);
}

EmbedderPaintContext FlutterPlatformViewsController::CompositeEmbeddedView(int view_id) {
  // Any UIKit related code has to run on main thread.
  FML_DCHECK([[NSThread currentThread] isMainThread]);
  // Do nothing if the view doesn't need to be composited.
  if (views_to_recomposite_.count(view_id) == 0) {
    return {slices_[view_id]->canvas(), slices_[view_id]->builder()};
  }
  CompositeWithParams(view_id, current_composition_params_[view_id]);
  views_to_recomposite_.erase(view_id);
  return {slices_[view_id]->canvas(), slices_[view_id]->builder()};
}

void FlutterPlatformViewsController::Reset() {
  UIView* flutter_view = flutter_view_.get();
  for (UIView* sub_view in [flutter_view subviews]) {
    [sub_view removeFromSuperview];
  }
  root_views_.clear();
  touch_interceptors_.clear();
  views_.clear();
  composition_order_.clear();
  active_composition_order_.clear();
  slices_.clear();
  current_composition_params_.clear();
  clip_count_.clear();
  views_to_recomposite_.clear();
  layer_pool_->RecycleLayers();
  visited_platform_views_.clear();
}

SkRect FlutterPlatformViewsController::GetPlatformViewRect(int view_id) {
  UIView* platform_view = GetPlatformViewByID(view_id);
  UIScreen* screen = [UIScreen mainScreen];
  CGRect platform_view_cgrect = [platform_view convertRect:platform_view.bounds
                                                    toView:flutter_view_];
  return SkRect::MakeXYWH(platform_view_cgrect.origin.x * screen.scale,    //
                          platform_view_cgrect.origin.y * screen.scale,    //
                          platform_view_cgrect.size.width * screen.scale,  //
                          platform_view_cgrect.size.height * screen.scale  //
  );
}

bool FlutterPlatformViewsController::SubmitFrame(GrDirectContext* gr_context,
                                                 const std::shared_ptr<IOSContext>& ios_context,
                                                 std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "FlutterPlatformViewsController::SubmitFrame");

  // Any UIKit related code has to run on main thread.
  FML_DCHECK([[NSThread currentThread] isMainThread]);
  if (flutter_view_ == nullptr) {
    return frame->Submit();
  }

  DisposeViews();

  SkCanvas* background_canvas = frame->SkiaCanvas();
  DisplayListBuilder* background_builder = frame->GetDisplayListBuilder().get();

  // Resolve all pending GPU operations before allocating a new surface.
  background_canvas->flush();

  // Clipping the background canvas before drawing the picture recorders requires
  // saving and restoring the clip context.
  SkAutoCanvasRestore save(background_canvas, /*doSave=*/true);

  // Maps a platform view id to a vector of `FlutterPlatformViewLayer`.
  LayersMap platform_view_layers;

  auto did_submit = true;
  auto num_platform_views = composition_order_.size();

  for (size_t i = 0; i < num_platform_views; i++) {
    int64_t platform_view_id = composition_order_[i];
    EmbedderViewSlice* slice = slices_[platform_view_id].get();
    slice->end_recording();

    // Check if the current picture contains overlays that intersect with the
    // current platform view or any of the previous platform views.
    for (size_t j = i + 1; j > 0; j--) {
      int64_t current_platform_view_id = composition_order_[j - 1];
      SkRect platform_view_rect = GetPlatformViewRect(current_platform_view_id);
      std::list<SkRect> intersection_rects =
          slice->searchNonOverlappingDrawnRects(platform_view_rect);
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
        // To workaround it, round the floating point bounds and make the rect slightly larger.
        // For example, {0.3, 0.5, 3.1, 4.7} becomes {0, 0, 4, 5}.
        joined_rect.setLTRB(std::floor(joined_rect.left()), std::floor(joined_rect.top()),
                            std::ceil(joined_rect.right()), std::ceil(joined_rect.bottom()));
        // Clip the background canvas, so it doesn't contain any of the pixels drawn
        // on the overlay layer.
        background_canvas->clipRect(joined_rect, SkClipOp::kDifference);
        // Get a new host layer.
        std::shared_ptr<FlutterPlatformViewLayer> layer = GetLayer(gr_context,                //
                                                                   ios_context,               //
                                                                   slice,                     //
                                                                   joined_rect,               //
                                                                   current_platform_view_id,  //
                                                                   overlay_id                 //
        );
        did_submit &= layer->did_submit_last_frame;
        platform_view_layers[current_platform_view_id].push_back(layer);
        overlay_id++;
      }
    }
    if (background_builder) {
      slice->render_into(background_builder);
    } else {
      slice->render_into(background_canvas);
    }
  }

  // Manually trigger the SkAutoCanvasRestore before we submit the frame
  save.restore();

  // If a layer was allocated in the previous frame, but it's not used in the current frame,
  // then it can be removed from the scene.
  RemoveUnusedLayers();
  // Organize the layers by their z indexes.
  BringLayersIntoView(platform_view_layers);
  // Mark all layers as available, so they can be used in the next frame.
  layer_pool_->RecycleLayers();

  did_submit &= frame->Submit();

  // If the frame is submitted with embedded platform views,
  // there should be a |[CATransaction begin]| call in this frame prior to all the drawing.
  // If that case, we need to commit the transaction.
  CommitCATransactionIfNeeded();
  return did_submit;
}

void FlutterPlatformViewsController::BringLayersIntoView(LayersMap layer_map) {
  FML_DCHECK(flutter_view_);
  UIView* flutter_view = flutter_view_.get();
  auto zIndex = 0;
  // Clear the `active_composition_order_`, which will be populated down below.
  active_composition_order_.clear();
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t platform_view_id = composition_order_[i];
    std::vector<std::shared_ptr<FlutterPlatformViewLayer>> layers = layer_map[platform_view_id];
    UIView* platform_view_root = root_views_[platform_view_id].get();

    if (platform_view_root.superview != flutter_view) {
      [flutter_view addSubview:platform_view_root];
    }
    // Make sure the platform_view_root is higher than the last platform_view_root in
    // composition_order_.
    platform_view_root.layer.zPosition = zIndex++;

    for (const std::shared_ptr<FlutterPlatformViewLayer>& layer : layers) {
      if ([layer->overlay_view_wrapper.get() superview] != flutter_view) {
        [flutter_view addSubview:layer->overlay_view_wrapper];
      }
      // Make sure all the overlays are higher than the platform view.
      layer->overlay_view_wrapper.get().layer.zPosition = zIndex++;
      FML_DCHECK(layer->overlay_view_wrapper.get().layer.zPosition >
                 platform_view_root.layer.zPosition);
    }
    active_composition_order_.push_back(platform_view_id);
  }
}

std::shared_ptr<FlutterPlatformViewLayer> FlutterPlatformViewsController::GetLayer(
    GrDirectContext* gr_context,
    const std::shared_ptr<IOSContext>& ios_context,
    EmbedderViewSlice* slice,
    SkRect rect,
    int64_t view_id,
    int64_t overlay_id) {
  FML_DCHECK(flutter_view_);
  std::shared_ptr<FlutterPlatformViewLayer> layer = layer_pool_->GetLayer(gr_context, ios_context);

  UIView* overlay_view_wrapper = layer->overlay_view_wrapper.get();
  auto screenScale = [UIScreen mainScreen].scale;
  // Set the size of the overlay view wrapper.
  // This wrapper view masks the overlay view.
  overlay_view_wrapper.frame = CGRectMake(rect.x() / screenScale, rect.y() / screenScale,
                                          rect.width() / screenScale, rect.height() / screenScale);
  // Set a unique view identifier, so the overlay_view_wrapper can be identified in XCUITests.
  overlay_view_wrapper.accessibilityIdentifier =
      [NSString stringWithFormat:@"platform_view[%lld].overlay[%lld]", view_id, overlay_id];

  UIView* overlay_view = layer->overlay_view.get();
  // Set the size of the overlay view.
  // This size is equal to the device screen size.
  overlay_view.frame = [flutter_view_.get() convertRect:flutter_view_.get().bounds
                                                 toView:overlay_view_wrapper];
  // Set a unique view identifier, so the overlay_view can be identified in XCUITests.
  overlay_view.accessibilityIdentifier =
      [NSString stringWithFormat:@"platform_view[%lld].overlay_view[%lld]", view_id, overlay_id];

  std::unique_ptr<SurfaceFrame> frame = layer->surface->AcquireFrame(frame_size_);
  // If frame is null, AcquireFrame already printed out an error message.
  if (!frame) {
    return layer;
  }
  SkCanvas* overlay_canvas = frame->SkiaCanvas();
  overlay_canvas->clipRect(rect);
  overlay_canvas->clear(SK_ColorTRANSPARENT);
  if (frame->GetDisplayListBuilder()) {
    slice->render_into(frame->GetDisplayListBuilder().get());
  } else {
    slice->render_into(overlay_canvas);
  }

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

void FlutterPlatformViewsController::BeginCATransaction() {
  FML_DCHECK([[NSThread currentThread] isMainThread]);
  FML_DCHECK(!catransaction_added_);
  [CATransaction begin];
  catransaction_added_ = true;
}

void FlutterPlatformViewsController::CommitCATransactionIfNeeded() {
  if (catransaction_added_) {
    FML_DCHECK([[NSThread currentThread] isMainThread]);
    [CATransaction commit];
    catransaction_added_ = false;
  }
}

void FlutterPlatformViewsController::ResetFrameState() {
  slices_.clear();
  composition_order_.clear();
  visited_platform_views_.clear();
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
       platformViewsController:
           (fml::WeakPtr<flutter::FlutterPlatformViewsController>)platformViewsController;
@end

@implementation FlutterTouchInterceptingView {
  fml::scoped_nsobject<DelayingGestureRecognizer> _delayingRecognizer;
  FlutterPlatformViewGestureRecognizersBlockingPolicy _blockingPolicy;
  UIView* _embeddedView;
}
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
             platformViewsController:
                 (fml::WeakPtr<flutter::FlutterPlatformViewsController>)platformViewsController
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)blockingPolicy {
  self = [super initWithFrame:embeddedView.frame];
  if (self) {
    self.multipleTouchEnabled = YES;
    _embeddedView = embeddedView;
    embeddedView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    [self addSubview:embeddedView];

    ForwardingGestureRecognizer* forwardingRecognizer = [[[ForwardingGestureRecognizer alloc]
                 initWithTarget:self
        platformViewsController:std::move(platformViewsController)] autorelease];

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

- (UIView*)embeddedView {
  return [[_embeddedView retain] autorelease];
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
  // Weak reference to FlutterPlatformViewsController. The FlutterPlatformViewsController has
  // a reference to the FlutterViewController, where we can dispatch pointer events to.
  //
  // The lifecycle of FlutterPlatformViewsController is bind to FlutterEngine, which should always
  // outlives the FlutterViewController. And ForwardingGestureRecognizer is owned by a subview of
  // FlutterView, so the ForwardingGestureRecognizer never out lives FlutterViewController.
  // Therefore, `_platformViewsController` should never be nullptr.
  fml::WeakPtr<flutter::FlutterPlatformViewsController> _platformViewsController;
  // Counting the pointers that has started in one touch sequence.
  NSInteger _currentTouchPointersCount;
  // We can't dispatch events to the framework without this back pointer.
  // This gesture recognizer retains the `FlutterViewController` until the
  // end of a gesture sequence, that is all the touches in touchesBegan are concluded
  // with |touchesCancelled| or |touchesEnded|.
  fml::scoped_nsobject<UIViewController> _flutterViewController;
}

- (instancetype)initWithTarget:(id)target
       platformViewsController:
           (fml::WeakPtr<flutter::FlutterPlatformViewsController>)platformViewsController {
  self = [super initWithTarget:target action:nil];
  if (self) {
    self.delegate = self;
    FML_DCHECK(platformViewsController.get() != nullptr);
    _platformViewsController = std::move(platformViewsController);
    _currentTouchPointersCount = 0;
  }
  return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  FML_DCHECK(_currentTouchPointersCount >= 0);
  if (_currentTouchPointersCount == 0) {
    // At the start of each gesture sequence, we reset the `_flutterViewController`,
    // so that all the touch events in the same sequence are forwarded to the same
    // `_flutterViewController`.
    _flutterViewController.reset([_platformViewsController->getFlutterViewController() retain]);
  }
  [_flutterViewController.get() touchesBegan:touches withEvent:event];
  _currentTouchPointersCount += touches.count;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController.get() touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterViewController.get() touchesEnded:touches withEvent:event];
  _currentTouchPointersCount -= touches.count;
  // Touches in one touch sequence are sent to the touchesEnded method separately if different
  // fingers stop touching the screen at different time. So one touchesEnded method triggering does
  // not necessarially mean the touch sequence has ended. We Only set the state to
  // UIGestureRecognizerStateFailed when all the touches in the current touch sequence is ended.
  if (_currentTouchPointersCount == 0) {
    self.state = UIGestureRecognizerStateFailed;
    _flutterViewController.reset(nil);
  }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  // In the event of platform view is removed, iOS generates a "stationary" change type instead of
  // "cancelled" change type.
  // Flutter needs all the cancelled touches to be "cancelled" change types in order to correctly
  // handle gesture sequence.
  // We always override the change type to "cancelled".
  [((FlutterViewController*)_flutterViewController.get()) forceTouchesCancelled:touches];
  _currentTouchPointersCount -= touches.count;
  if (_currentTouchPointersCount == 0) {
    self.state = UIGestureRecognizerStateFailed;
    _flutterViewController.reset(nil);
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  return YES;
}
@end
