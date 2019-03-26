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
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"

namespace shell {

void FlutterPlatformViewsController::SetFlutterView(UIView* flutter_view) {
  flutter_view_.reset([flutter_view retain]);
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
    // TODO(amirh): support this by setting the refernce to FlutterView when it becomes available.
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

  FlutterTouchInterceptingView* touch_interceptor =
      [[[FlutterTouchInterceptingView alloc] initWithEmbeddedView:embedded_view.view
                                                      flutterView:flutter_view_] autorelease];

  touch_interceptors_[viewId] =
      fml::scoped_nsobject<FlutterTouchInterceptingView>([touch_interceptor retain]);

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

  UIView* touch_interceptor = touch_interceptors_[viewId].get();
  [touch_interceptor removeFromSuperview];
  views_.erase(viewId);
  touch_interceptors_.erase(viewId);
  overlays_.erase(viewId);
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

void FlutterPlatformViewsController::PrerollCompositeEmbeddedView(int view_id) {
  picture_recorders_[view_id] = std::make_unique<SkPictureRecorder>();
  picture_recorders_[view_id]->beginRecording(SkRect::Make(frame_size_));
  picture_recorders_[view_id]->getRecordingCanvas()->clear(SK_ColorTRANSPARENT);
  composition_order_.push_back(view_id);
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

SkCanvas* FlutterPlatformViewsController::CompositeEmbeddedView(
    int view_id,
    const flow::EmbeddedViewParams& params) {
  // TODO(amirh): assert that this is running on the platform thread once we support the iOS
  // embedded views thread configuration.
  // TODO(amirh): do nothing if the params didn't change.
  CGFloat screenScale = [[UIScreen mainScreen] scale];
  CGRect rect =
      CGRectMake(params.offsetPixels.x() / screenScale, params.offsetPixels.y() / screenScale,
                 params.sizePoints.width(), params.sizePoints.height());

  UIView* touch_interceptor = touch_interceptors_[view_id].get();
  [touch_interceptor setFrame:rect];

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
}

bool FlutterPlatformViewsController::SubmitFrame(bool gl_rendering,
                                                 GrContext* gr_context,
                                                 std::shared_ptr<IOSGLContext> gl_context) {
  bool did_submit = true;
  for (size_t i = 0; i < composition_order_.size(); i++) {
    int64_t view_id = composition_order_[i];
    if (gl_rendering) {
      EnsureGLOverlayInitialized(view_id, gl_context, gr_context);
    } else {
      EnsureOverlayInitialized(view_id);
    }
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
    UIView* intercepter = touch_interceptors_[view_id].get();
    UIView* overlay = overlays_[view_id]->overlay_view;
    FML_CHECK(intercepter.superview == overlay.superview);

    if (intercepter.superview == flutter_view) {
      [flutter_view bringSubviewToFront:intercepter];
      [flutter_view bringSubviewToFront:overlay];
    } else {
      [flutter_view addSubview:intercepter];
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
      [touch_interceptors_[view_id].get() removeFromSuperview];
      [overlays_[view_id]->overlay_view.get() removeFromSuperview];
    }
  }
}

void FlutterPlatformViewsController::EnsureOverlayInitialized(int64_t overlay_id) {
  if (overlays_.count(overlay_id) != 0) {
    return;
  }
  FlutterOverlayView* overlay_view = [[FlutterOverlayView alloc] init];
  overlay_view.frame = flutter_view_.get().bounds;
  overlay_view.autoresizingMask =
      (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  std::unique_ptr<IOSSurface> ios_surface = overlay_view.createSoftwareSurface;
  std::unique_ptr<Surface> surface = ios_surface->CreateGPUSurface();
  overlays_[overlay_id] = std::make_unique<FlutterPlatformViewLayer>(
      fml::scoped_nsobject<UIView>(overlay_view), std::move(ios_surface), std::move(surface));
}

void FlutterPlatformViewsController::EnsureGLOverlayInitialized(
    int64_t overlay_id,
    std::shared_ptr<IOSGLContext> gl_context,
    GrContext* gr_context) {
  if (overlays_.count(overlay_id) != 0) {
    if (gr_context != overlays_gr_context_) {
      overlays_gr_context_ = gr_context;
      // The overlay already exists, but the GrContext was changed so we need to recreate
      // the rendering surface with the new GrContext.
      IOSSurfaceGL* ios_surface_gl = (IOSSurfaceGL*)overlays_[overlay_id]->ios_surface.get();
      std::unique_ptr<Surface> surface = ios_surface_gl->CreateSecondaryGPUSurface(gr_context);
      overlays_[overlay_id]->surface = std::move(surface);
    }
    return;
  }
  auto contentsScale = flutter_view_.get().layer.contentsScale;
  FlutterOverlayView* overlay_view =
      [[FlutterOverlayView alloc] initWithContentsScale:contentsScale];
  overlay_view.frame = flutter_view_.get().bounds;
  overlay_view.autoresizingMask =
      (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  std::unique_ptr<IOSSurfaceGL> ios_surface =
      [overlay_view createGLSurfaceWithContext:std::move(gl_context)];
  std::unique_ptr<Surface> surface = ios_surface->CreateSecondaryGPUSurface(gr_context);
  overlays_[overlay_id] = std::make_unique<FlutterPlatformViewLayer>(
      fml::scoped_nsobject<UIView>(overlay_view), std::move(ios_surface), std::move(surface));
  overlays_gr_context_ = gr_context;
}

}  // namespace shell

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
- (instancetype)initWithTarget:(id)target flutterView:(UIView*)flutterView;
@end

@implementation FlutterTouchInterceptingView {
  fml::scoped_nsobject<DelayingGestureRecognizer> _delayingRecognizer;
}
- (instancetype)initWithEmbeddedView:(UIView*)embeddedView flutterView:(UIView*)flutterView {
  self = [super initWithFrame:embeddedView.frame];
  if (self) {
    self.multipleTouchEnabled = YES;
    embeddedView.autoresizingMask =
        (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    [self addSubview:embeddedView];

    ForwardingGestureRecognizer* forwardingRecognizer =
        [[[ForwardingGestureRecognizer alloc] initWithTarget:self
                                                 flutterView:flutterView] autorelease];

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
  // FlutterTouchInterceptingView which is strong referenced only by the FlutterView.
  // So this is safe as when FlutterView is deallocated the reference to ForwardingGestureRecognizer
  // will go away.
  UIView* _flutterView;
  // Counting the pointers that has started in one touch sequence.
  NSInteger _currentTouchPointersCount;
}

- (instancetype)initWithTarget:(id)target flutterView:(UIView*)flutterView {
  self = [super initWithTarget:target action:nil];
  if (self) {
    self.delegate = self;
    _flutterView = flutterView;
    _currentTouchPointersCount = 0;
  }
  return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterView touchesBegan:touches withEvent:event];
  _currentTouchPointersCount += touches.count;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterView touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [_flutterView touchesEnded:touches withEvent:event];
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
  [_flutterView touchesCancelled:touches withEvent:event];
  _currentTouchPointersCount = 0;
  self.state = UIGestureRecognizerStateFailed;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer*)otherGestureRecognizer {
  return YES;
}
@end
