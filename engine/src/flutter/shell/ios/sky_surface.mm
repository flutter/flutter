// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_surface.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#include "sky/shell/ios/platform_view_ios.h"
#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"
#include "sky/shell/ui_delegate.h"

#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/services/viewport/input_event.mojom.h"
#include "base/time/time.h"

static inline sky::EventType EventTypeFromUITouchPhase(UITouchPhase phase) {
  switch (phase) {
    case UITouchPhaseBegan:
      return sky::EVENT_TYPE_POINTER_DOWN;
    case UITouchPhaseMoved:
    case UITouchPhaseStationary:
      // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
      // with the same coordinates
      return sky::EVENT_TYPE_POINTER_MOVE;
    case UITouchPhaseEnded:
      return sky::EVENT_TYPE_POINTER_UP;
    case UITouchPhaseCancelled:
      return sky::EVENT_TYPE_POINTER_CANCEL;
  }

  return sky::EVENT_TYPE_UNKNOWN;
}

static inline int64 InputEventTimestampFromNSTimeInterval(
    NSTimeInterval interval) {
  return base::TimeDelta::FromSecondsD(interval).InMilliseconds();
}

static sky::InputEventPtr BasicInputEventFromRecognizer(
    sky::EventType type,
    UIGestureRecognizer* recognizer) {
  auto input = sky::InputEvent::New();
  input->type = type;
  input->time_stamp = InputEventTimestampFromNSTimeInterval(
      CACurrentMediaTime());

  input->gesture_data = sky::GestureData::New();

  CGPoint windowCoordinates = [recognizer locationInView:recognizer.view];
  const CGFloat scale = [UIScreen mainScreen].scale;
  input->gesture_data->x = windowCoordinates.x * scale;
  input->gesture_data->y = windowCoordinates.y * scale;
  return input.Pass();
}

@implementation SkySurface {
  BOOL _platformViewInitialized;

  sky::ViewportObserverPtr _viewport_observer;
  scoped_ptr<sky::shell::ShellView> _shell_view;
}

-(instancetype) initWithShellView:(sky::shell::ShellView *) shellView {
  self = [super init];
  if (self) {
    _shell_view.reset(shellView);
    [self installGestureRecognizers];
  }
  return self;
}

- (gfx::AcceleratedWidget)acceleratedWidget {
  return (gfx::AcceleratedWidget)self.layer;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  [self configureLayerDefaults];

  [self setupPlatformViewIfNecessary];

  CGSize size = self.bounds.size;
  CGFloat scale = [UIScreen mainScreen].scale;

  _viewport_observer->OnViewportMetricsChanged(size.width * scale,
                                               size.height * scale, scale);
}

- (void)configureLayerDefaults {
  CAEAGLLayer* layer = reinterpret_cast<CAEAGLLayer*>(self.layer);
  layer.allowsGroupOpacity = YES;
  layer.opaque = YES;
  CGFloat screenScale = [UIScreen mainScreen].scale;
  layer.contentsScale = screenScale;
  // Note: shouldRasterize is still NO. This is just a defensive measure
  layer.rasterizationScale = screenScale;
}

- (void)setupPlatformViewIfNecessary {
  if (_platformViewInitialized) {
    return;
  }

  _platformViewInitialized = YES;

  [self notifySurfaceCreation];
  [self connectToViewportObserverAndLoad];
}

- (sky::shell::PlatformViewIOS*)platformView {
  auto view = static_cast<sky::shell::PlatformViewIOS*>(_shell_view->view());
  DCHECK(view);
  return view;
}

- (void)notifySurfaceCreation {
  self.platformView->SurfaceCreated(self.acceleratedWidget);
}

- (NSString*)skyInitialLoadURL {
  return [NSBundle mainBundle].infoDictionary[@"com.google.sky.load_url"];
}

- (void)connectToViewportObserverAndLoad {
  auto interface_request = mojo::GetProxy(&_viewport_observer);
  self.platformView->ConnectToViewportObserver(interface_request.Pass());

  mojo::String string(self.skyInitialLoadURL.UTF8String);
  _viewport_observer->LoadURL(string);
}

- (void)notifySurfaceDestruction {
  self.platformView->SurfaceDestroyed();
}

#pragma mark - UIResponder overrides for raw touches

- (void)dispatchTouches:(NSSet*)touches phase:(UITouchPhase)phase {
  auto eventType = EventTypeFromUITouchPhase(phase);
  const CGFloat scale = [UIScreen mainScreen].scale;

  for (UITouch* touch in touches) {
    auto input = sky::InputEvent::New();
    input->type = eventType;
    input->time_stamp = InputEventTimestampFromNSTimeInterval(touch.timestamp);

    input->pointer_data = sky::PointerData::New();
    input->pointer_data->kind = sky::POINTER_KIND_TOUCH;

    CGPoint windowCoordinates = [touch locationInView:nil];

    input->pointer_data->x = windowCoordinates.x * scale;
    input->pointer_data->y = windowCoordinates.y * scale;

    _viewport_observer->OnInputEvent(input.Pass());
  }
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseBegan];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseMoved];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseEnded];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  [self dispatchTouches:touches phase:UITouchPhaseCancelled];
}

#pragma mark - Gesture Recognizers

-(void) installGestureRecognizers {
  // For:
  //   GESTURE_FLING_CANCEL
  //   GESTURE_FLING_START
  UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
    initWithTarget:self action:@selector(onFling:)];
  [self addGestureRecognizer: swipe];
  [swipe release];

  // For:
  //   GESTURE_LONG_PRESS
  //   GESTURE_SHOW_PRESS
  UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc]
      initWithTarget:self action:@selector(onLongPress:)];
  [self addGestureRecognizer: longPress];
  [longPress release];

  // For:
  //   GESTURE_SCROLL_BEGIN
  //   GESTURE_SCROLL_END
  //   GESTURE_SCROLL_UPDATE
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
    initWithTarget:self action:@selector(onScroll:)];
  [self addGestureRecognizer: pan];
  [pan release];

  // For:
  //   GESTURE_TAP
  //   GESTURE_TAP_DOWN
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
    initWithTarget:self action:@selector(onTap:)];
  [self addGestureRecognizer: tap];
  [tap release];
}

-(void) onFling:(UISwipeGestureRecognizer *) recognizer {
  // Swipes are discrete gestures already. So there is no equivalent to a cancel
  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(
    sky::EVENT_TYPE_GESTURE_FLING_START, recognizer);
  _viewport_observer->OnInputEvent(input.Pass());
}

-(void) onLongPress:(UILongPressGestureRecognizer *) recognizer {
  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(sky::EVENT_TYPE_GESTURE_LONG_PRESS,
                                             recognizer);
  _viewport_observer->OnInputEvent(input.Pass());
}

-(void) onScroll:(UIPanGestureRecognizer *) recognizer {
  sky::EventType type = sky::EVENT_TYPE_UNKNOWN;
  switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
      type = sky::EVENT_TYPE_GESTURE_SCROLL_BEGIN;
      break;
    case UIGestureRecognizerStateChanged:
      type = sky::EVENT_TYPE_GESTURE_SCROLL_UPDATE;
      break;
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
      type = sky::EVENT_TYPE_GESTURE_SCROLL_END;
      break;
    default:
      break;
  }

  if (type == sky::EVENT_TYPE_UNKNOWN) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(type, recognizer);
  auto scale = [UIScreen mainScreen].scale;
  auto translation = [recognizer translationInView: self];
  auto velocity = [recognizer velocityInView: self];

  input->gesture_data->dx = translation.x * scale;
  input->gesture_data->dy =  translation.y * scale;
  input->gesture_data->velocityX = velocity.x * scale;
  input->gesture_data->velocityY =  velocity.y * scale;

  _viewport_observer->OnInputEvent(input.Pass());
}

-(void) onTap:(UITapGestureRecognizer *) recognizer {

  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }

  auto input = BasicInputEventFromRecognizer(sky::EVENT_TYPE_GESTURE_TAP,
                                             recognizer);
  _viewport_observer->OnInputEvent(input.Pass());
}

#pragma mark - Misc.

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)dealloc {
  [self notifySurfaceDestruction];
  [super dealloc];
}

@end
