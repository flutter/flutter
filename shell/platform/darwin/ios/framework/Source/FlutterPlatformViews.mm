// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIGestureRecognizerSubclass.h>

#import "FlutterOverlayView.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_gl.h"

#include <map>
#include <memory>
#include <string>

#include "FlutterPlatformViews_Internal.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"

namespace flutter {

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
  views_[viewId] = fml::scoped_nsobject<NSObject<FlutterPlatformView>>([embedded_view retain]);

  FlutterTouchInterceptingView* touch_interceptor = [[[FlutterTouchInterceptingView alloc]
       initWithEmbeddedView:embedded_view.view
      flutterViewController:flutter_view_controller_.get()] autorelease];

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
    NSString* factoryId) {
  std::string idString([factoryId UTF8String]);
  FML_CHECK(factories_.count(idString) == 0);
  factories_[idString] =
      fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>([factory retain]);
}

void FlutterPlatformViewsController::SetFrameSize(SkISize frame_size) {
  frame_size_ = frame_size;
}

void FlutterPlatformViewsController::CancelFrame() {
  composition_order_.clear();
}

bool FlutterPlatformViewsController::HasPendingViewOperations() {
  if (!views_to_recomposite_.empty()) {
    return true;
  }
  return active_composition_order_ != composition_order_;
}

const int FlutterPlatformViewsController::kDefaultMergedLeaseDuration;

PostPrerollResult FlutterPlatformViewsController::PostPrerollAction(
    fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger) {
  const bool uiviews_mutated = HasPendingViewOperations();
  if (uiviews_mutated) {
    if (gpu_thread_merger->IsMerged()) {
      gpu_thread_merger->ExtendLeaseTo(kDefaultMergedLeaseDuration);
    } else {
      CancelFrame();
      gpu_thread_merger->MergeWithLease(kDefaultMergedLeaseDuration);
      return PostPrerollResult::kResubmitFrame;
    }
  }
  return PostPrerollResult::kSuccess;
}

void FlutterPlatformViewsController::PrerollCompositeEmbeddedView(
    int view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  picture_recorders_[view_id] = std::make_unique<SkPictureRecorder>();
  picture_recorders_[view_id]->beginRecording(SkRect::Make(frame_size_));
  picture_recorders_[view_id]->getRecordingCanvas()->clear(SK_ColorTRANSPARENT);
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
    ChildClippingView* clippingView = [ChildClippingView new];
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
  // However, flow is based on the physical resolution. For eaxmple, 1000 pixels in flow equals
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
  overlays_.clear();
  composition_order_.clear();
  active_composition_order_.clear();
  picture_recorders_.clear();
  current_composition_params_.clear();
  clip_count_.clear();
  views_to_recomposite_.clear();
}

bool FlutterPlatformViewsController::SubmitFrame(GrContext* gr_context,
                                                 std::shared_ptr<IOSGLContext> gl_context) {
  DisposeViews();

  bool did_submit = true;
  for (int64_t view_id : composition_order_) {
    EnsureOverlayInitialized(view_id, std::move(gl_context), gr_context);
    auto frame = overlays_[view_id]->surface->AcquireFrame(frame_size_);
    SkCanvas* canvas = frame->SkiaCanvas();
    canvas->drawPicture(picture_recorders_[view_id]->finishRecordingAsPicture());
    canvas->flush();
    did_submit &= frame->Submit();
  }
  picture_recorders_.clear();
  if (composition_order_ == active_composition_order_) {
    composition_order_.clear();
    return did_submit;
  }
  DetachUnusedLayers();
  active_composition_order_.clear();
  UIView* flutter_view = flutter_view_.get();

  for (size_t i = 0; i < composition_order_.size(); i++) {
    int view_id = composition_order_[i];
    // We added a chain of super views to the platform view to handle clipping.
    // The `platform_view_root` is the view at the top of the chain which is a direct subview of the
    // `FlutterView`.
    UIView* platform_view_root = root_views_[view_id].get();
    UIView* overlay = overlays_[view_id]->overlay_view;
    FML_CHECK(platform_view_root.superview == overlay.superview);
    if (platform_view_root.superview == flutter_view) {
      [flutter_view bringSubviewToFront:platform_view_root];
      [flutter_view bringSubviewToFront:overlay];
    } else {
      [flutter_view addSubview:platform_view_root];
      [flutter_view addSubview:overlay];
    }

    active_composition_order_.push_back(view_id);
  }
  composition_order_.clear();
  return did_submit;
}

void FlutterPlatformViewsController::DetachUnusedLayers() {
  std::unordered_set<int64_t> composition_order_set;

  for (int64_t view_id : composition_order_) {
    composition_order_set.insert(view_id);
  }

  for (int64_t view_id : active_composition_order_) {
    if (composition_order_set.find(view_id) == composition_order_set.end()) {
      if (root_views_.find(view_id) == root_views_.end()) {
        continue;
      }
      // We added a chain of super views to the platform view to handle clipping.
      // The `platform_view_root` is the view at the top of the chain which is a direct subview of
      // the `FlutterView`.
      UIView* platform_view_root = root_views_[view_id].get();
      [platform_view_root removeFromSuperview];
      [overlays_[view_id]->overlay_view.get() removeFromSuperview];
    }
  }
}

void FlutterPlatformViewsController::DisposeViews() {
  if (views_to_dispose_.empty()) {
    return;
  }

  for (int64_t viewId : views_to_dispose_) {
    UIView* root_view = root_views_[viewId].get();
    [root_view removeFromSuperview];
    views_.erase(viewId);
    touch_interceptors_.erase(viewId);
    root_views_.erase(viewId);
    if (overlays_.find(viewId) != overlays_.end()) {
      [overlays_[viewId]->overlay_view.get() removeFromSuperview];
    }
    overlays_.erase(viewId);
    current_composition_params_.erase(viewId);
    clip_count_.erase(viewId);
    views_to_recomposite_.erase(viewId);
  }
  views_to_dispose_.clear();
}

void FlutterPlatformViewsController::EnsureOverlayInitialized(
    int64_t overlay_id,
    std::shared_ptr<IOSGLContext> gl_context,
    GrContext* gr_context) {
  FML_DCHECK(flutter_view_);

  auto overlay_it = overlays_.find(overlay_id);

  if (!gr_context) {
    FML_DLOG(ERROR) << "No GrContext";
    if (overlays_.count(overlay_id) != 0) {
      return;
    }
    fml::scoped_nsobject<FlutterOverlayView> overlay_view(
        [[[FlutterOverlayView alloc] init] retain]);
    overlay_view.get().frame = flutter_view_.get().bounds;
    overlay_view.get().autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    std::unique_ptr<IOSSurface> ios_surface = [overlay_view.get() createSurface:nil];
    std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface();
    overlays_[overlay_id] = std::make_unique<FlutterPlatformViewLayer>(
        std::move(overlay_view), std::move(ios_surface), std::move(surface));
    return;
  }

  if (overlay_it != overlays_.end()) {
    if (gr_context != overlays_gr_context_) {
      overlays_gr_context_ = gr_context;
      // The overlay already exists, but the GrContext was changed so we need to recreate
      // the rendering surface with the new GrContext.
      IOSSurface* ios_surface = overlay_it->second->ios_surface.get();
      std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface(gr_context);
      overlay_it->second->surface = std::move(surface);
    }
    return;
  }
  auto contentsScale = flutter_view_.get().layer.contentsScale;
  fml::scoped_nsobject<FlutterOverlayView> overlay_view(
      [[[FlutterOverlayView alloc] initWithContentsScale:contentsScale] retain]);
  overlay_view.get().frame = flutter_view_.get().bounds;
  overlay_view.get().autoresizingMask =
      (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  std::unique_ptr<IOSSurface> ios_surface =
      [overlay_view.get() createSurface:std::move(gl_context)];
  std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface(gr_context);
  overlays_[overlay_id] = std::make_unique<FlutterPlatformViewLayer>(
      std::move(overlay_view), std::move(ios_surface), std::move(surface));
  overlays_gr_context_ = gr_context;
}

}  // namespace flutter

// This recognizers delays touch events from being dispatched to the responder chain until it failed
// recognizing a gesture.
//
// We only fail this recognizer when asked to do so by the Flutter framework (which does so by
// invoking an acceptGesture method on the platform_views channel). And this is how we allow the
// Flutter framework to delay or prevent the embedded view from getting a touch sequence.
@interface DelayingGestureRecognizer : UIGestureRecognizer <UIGestureRecognizerDelegate>
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
}
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView
               flutterViewController:(UIViewController*)flutterViewController {
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

    [self addGestureRecognizer:_delayingRecognizer.get()];
    [self addGestureRecognizer:forwardingRecognizer];
  }
  return self;
}

- (void)releaseGesture {
  _delayingRecognizer.get().state = UIGestureRecognizerStateFailed;
}

- (void)blockGesture {
  _delayingRecognizer.get().state = UIGestureRecognizerStateEnded;
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
    self.delegate = self;
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
