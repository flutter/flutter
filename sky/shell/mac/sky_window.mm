// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_window.h"
#include "base/time/time.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/services/engine/input_event.mojom.h"
#include "sky/shell/mac/platform_view_mac.h"
#include "sky/shell/shell_view.h"
#include "sky/shell/shell.h"
#include "sky/shell/ui_delegate.h"

@interface SkyWindow ()<NSWindowDelegate>

@property(assign) IBOutlet NSOpenGLView* renderSurface;
@property(getter=isSurfaceSetup) BOOL surfaceSetup;

@end

static inline sky::EventType EventTypeFromNSEventPhase(NSEventPhase phase) {
  switch (phase) {
    case NSEventPhaseNone:
      return sky::EVENT_TYPE_UNKNOWN;
    case NSEventPhaseBegan:
      return sky::EVENT_TYPE_POINTER_DOWN;
    case NSEventPhaseStationary:
    // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
    // with the same coordinates
    case NSEventPhaseChanged:
      return sky::EVENT_TYPE_POINTER_MOVE;
    case NSEventPhaseEnded:
      return sky::EVENT_TYPE_POINTER_UP;
    case NSEventPhaseCancelled:
      return sky::EVENT_TYPE_POINTER_CANCEL;
    case NSEventPhaseMayBegin:
      return sky::EVENT_TYPE_UNKNOWN;
  }
  return sky::EVENT_TYPE_UNKNOWN;
}

@implementation SkyWindow {
  sky::SkyEnginePtr _sky_engine;
  scoped_ptr<sky::shell::ShellView> _shell_view;
}

@synthesize renderSurface = _renderSurface;
@synthesize surfaceSetup = _surfaceSetup;

- (void)awakeFromNib {
  [super awakeFromNib];

  self.delegate = self;

  [self windowDidResize:nil];
}

- (void)setupShell {
  NSAssert(_shell_view == nullptr, @"The shell view must not already be set");
  auto shell_view = new sky::shell::ShellView(sky::shell::Shell::Shared());
  _shell_view.reset(shell_view);

  auto widget = reinterpret_cast<gfx::AcceleratedWidget>(self.renderSurface);
  self.platformView->SurfaceCreated(widget);
}

- (NSString*)skyInitialLoadURL {
  // TODO(csg): There should be a way to specify this in the UI
  return [[NSBundle mainBundle]
              .infoDictionary objectForKey:@"org.domokit.sky.load_url"];
}

- (void)setupAndLoadDart {
  auto interface_request = mojo::GetProxy(&_sky_engine);
  self.platformView->ConnectToEngine(interface_request.Pass());

  mojo::String string(self.skyInitialLoadURL.UTF8String);
  _sky_engine->RunFromNetwork(string);
}

- (void)windowDidResize:(NSNotification*)notification {
  [self setupSurfaceIfNecessary];

  // Resize

  auto metrics = sky::ViewportMetrics::New();
  auto size = self.renderSurface.frame.size;
  metrics->physical_width = size.width;
  metrics->physical_height = size.height;
  metrics->device_pixel_ratio = 1.0;
  _sky_engine->OnViewportMetricsChanged(metrics.Pass());
}

- (void)setupSurfaceIfNecessary {
  if (self.isSurfaceSetup) {
    return;
  }

  self.surfaceSetup = YES;

  [self setupShell];
  [self setupAndLoadDart];
}

- (sky::shell::PlatformViewMac*)platformView {
  auto view = static_cast<sky::shell::PlatformViewMac*>(_shell_view->view());
  DCHECK(view);
  return view;
}

#pragma mark - Responder overrides

- (void)dispatchEvent:(NSEvent*)event phase:(NSEventPhase)phase {
  NSPoint location =
      [_renderSurface convertPoint:event.locationInWindow fromView:nil];

  location.y = _renderSurface.frame.size.height - location.y;

  auto input = sky::InputEvent::New();
  input->type = EventTypeFromNSEventPhase(phase);
  input->time_stamp =
      base::TimeDelta::FromSecondsD(event.timestamp).InMilliseconds();

  input->pointer_data = sky::PointerData::New();
  input->pointer_data->kind = sky::POINTER_KIND_TOUCH;

  input->pointer_data->x = location.x;
  input->pointer_data->y = location.y;

  _sky_engine->OnInputEvent(input.Pass());
}

- (void)mouseDown:(NSEvent*)event {
  [self dispatchEvent:event phase:NSEventPhaseBegan];
}

- (void)mouseDragged:(NSEvent*)event {
  [self dispatchEvent:event phase:NSEventPhaseChanged];
}

- (void)mouseUp:(NSEvent*)event {
  [self dispatchEvent:event phase:NSEventPhaseEnded];
}

- (void)dealloc {
  self.platformView->SurfaceDestroyed();
  [super dealloc];
}

@end
