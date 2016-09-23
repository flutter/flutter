// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_window.h"

#include "base/time/time.h"
#include "flutter/services/pointer/pointer.mojom.h"
#include "flutter/shell/platform/darwin/desktop/platform_view_mac.h"

@interface SkyWindow ()<NSWindowDelegate>

@property(assign) IBOutlet NSOpenGLView* renderSurface;
@property(getter=isSurfaceSetup) BOOL surfaceSetup;

@end

static inline pointer::PointerType EventTypeFromNSEventPhase(
    NSEventPhase phase) {
  switch (phase) {
    case NSEventPhaseNone:
      return pointer::PointerType::CANCEL;
    case NSEventPhaseBegan:
      return pointer::PointerType::DOWN;
    case NSEventPhaseStationary:
    // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
    // with the same coordinates
    case NSEventPhaseChanged:
      return pointer::PointerType::MOVE;
    case NSEventPhaseEnded:
      return pointer::PointerType::UP;
    case NSEventPhaseCancelled:
      return pointer::PointerType::CANCEL;
    case NSEventPhaseMayBegin:
      return pointer::PointerType::CANCEL;
  }
  return pointer::PointerType::CANCEL;
}

@implementation SkyWindow {
  std::unique_ptr<shell::PlatformViewMac> _platform_view;
}

@synthesize renderSurface = _renderSurface;
@synthesize surfaceSetup = _surfaceSetup;

- (void)awakeFromNib {
  [super awakeFromNib];

  self.delegate = self;

  [self updateWindowSize];
}

- (void)setupPlatformView {
  DCHECK(_platform_view == nullptr)
      << "The platform view must not already be set.";

  _platform_view.reset(new shell::PlatformViewMac(self.renderSurface));
  _platform_view->SetupResourceContextOnIOThread();
  _platform_view->NotifyCreated();
}

// TODO(eseidel): This does not belong in sky_window!
// Probably belongs in NSApplicationDelegate didFinishLaunching.
- (void)setupAndLoadDart {
  _platform_view->SetupAndLoadDart();
}

- (void)windowDidResize:(NSNotification*)notification {
  [self updateWindowSize];
}

- (void)updateWindowSize {
  [self setupSurfaceIfNecessary];

  auto metrics = sky::ViewportMetrics::New();
  auto size = self.renderSurface.frame.size;
  metrics->physical_width = size.width;
  metrics->physical_height = size.height;
  metrics->device_pixel_ratio = 1.0;

  _platform_view->engineProxy()->OnViewportMetricsChanged(metrics.Pass());
}

- (void)setupSurfaceIfNecessary {
  if (self.isSurfaceSetup) {
    return;
  }

  self.surfaceSetup = YES;

  [self setupPlatformView];
  [self setupAndLoadDart];
}

#pragma mark - Responder overrides

- (void)dispatchEvent:(NSEvent*)event phase:(NSEventPhase)phase {
  NSPoint location =
      [_renderSurface convertPoint:event.locationInWindow fromView:nil];
  location.y = _renderSurface.frame.size.height - location.y;

  auto pointer_data = pointer::Pointer::New();

  pointer_data->time_stamp =
      base::TimeDelta::FromSecondsD(event.timestamp).InMicroseconds();
  pointer_data->type = EventTypeFromNSEventPhase(phase);
  pointer_data->kind = pointer::PointerKind::TOUCH;
  pointer_data->pointer = 0;
  pointer_data->x = location.x;
  pointer_data->y = location.y;
  pointer_data->buttons = 0;
  pointer_data->down = false;
  pointer_data->primary = false;
  pointer_data->obscured = false;
  pointer_data->pressure = 1.0;
  pointer_data->pressure_min = 0.0;
  pointer_data->pressure_max = 1.0;
  pointer_data->distance = 0.0;
  pointer_data->distance_min = 0.0;
  pointer_data->distance_max = 0.0;
  pointer_data->radius_major = 0.0;
  pointer_data->radius_minor = 0.0;
  pointer_data->radius_min = 0.0;
  pointer_data->radius_max = 0.0;
  pointer_data->orientation = 0.0;
  pointer_data->tilt = 0.0;

  auto pointer_packet = pointer::PointerPacket::New();
  pointer_packet->pointers.push_back(pointer_data.Pass());
  _platform_view->engineProxy()->OnPointerPacket(pointer_packet.Pass());
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
  if (_platform_view) {
    _platform_view->NotifyDestroyed();
  }

  [super dealloc];
}

@end
