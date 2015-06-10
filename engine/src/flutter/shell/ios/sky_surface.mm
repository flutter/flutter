// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_surface.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#include "sky/shell/ui_delegate.h"
#include "sky/shell/shell.h"
#include "sky/shell/ios/platform_view_ios.h"

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

@implementation SkySurface {
  BOOL _platformViewInitialized;

  sky::ViewportObserverPtr _viewport_observer;
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
  auto view = static_cast<sky::shell::PlatformViewIOS*>(
      sky::shell::Shell::Shared().view());
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
  auto view = sky::shell::Shell::Shared().view();
  auto interface_request = mojo::GetProxy(&_viewport_observer);
  view->ConnectToViewportObserver(interface_request.Pass());

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

    auto timedelta = base::TimeDelta::FromSecondsD(touch.timestamp);
    input->time_stamp = timedelta.InMilliseconds();

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

#pragma mark - Misc.

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)dealloc {
  [self notifySurfaceDestruction];
  [super dealloc];
}

@end
