// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_window.h"

#include "flutter/common/threads.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/darwin/desktop/platform_view_mac.h"

@interface SkyWindow ()<NSWindowDelegate>

@property(assign) IBOutlet NSOpenGLView* renderSurface;
@property(getter=isSurfaceSetup) BOOL surfaceSetup;

@end

static inline blink::PointerData::Change PointerChangeFromNSEventPhase(
    NSEventPhase phase) {
  switch (phase) {
    case NSEventPhaseNone:
      return blink::PointerData::Change::kCancel;
    case NSEventPhaseBegan:
      return blink::PointerData::Change::kDown;
    case NSEventPhaseStationary:
    // There is no EVENT_TYPE_POINTER_STATIONARY. So we just pass a move type
    // with the same coordinates
    case NSEventPhaseChanged:
      return blink::PointerData::Change::kMove;
    case NSEventPhaseEnded:
      return blink::PointerData::Change::kUp;
    case NSEventPhaseCancelled:
      return blink::PointerData::Change::kCancel;
    case NSEventPhaseMayBegin:
      return blink::PointerData::Change::kCancel;
  }
  return blink::PointerData::Change::kCancel;
}

@implementation SkyWindow {
  std::unique_ptr<shell::PlatformViewMac> _platformView;
}

@synthesize renderSurface = _renderSurface;
@synthesize surfaceSetup = _surfaceSetup;

- (void)awakeFromNib {
  [super awakeFromNib];

  self.delegate = self;

  [self updateWindowSize];
}

- (void)setupPlatformView {
  DCHECK(_platformView == nullptr)
      << "The platform view must not already be set.";

  _platformView.reset(new shell::PlatformViewMac(self.renderSurface));
  _platformView->SetupResourceContextOnIOThread();
  _platformView->NotifyCreated(
      std::make_unique<shell::GPUSurfaceGL>(_platformView.get()));
}

// TODO(eseidel): This does not belong in sky_window!
// Probably belongs in NSApplicationDelegate didFinishLaunching.
- (void)setupAndLoadDart {
  _platformView->SetupAndLoadDart();
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

  _platformView->engineProxy()->OnViewportMetricsChanged(metrics.Pass());
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

  blink::PointerData pointer_data;
  pointer_data.Clear();
  pointer_data.time_stamp =
      ftl::TimeDelta::FromSeconds(event.timestamp).ToMicroseconds();
  pointer_data.change = PointerChangeFromNSEventPhase(phase);
  pointer_data.kind = blink::PointerData::DeviceKind::kMouse;
  pointer_data.physical_x = location.x;
  pointer_data.physical_y = location.y;
  pointer_data.pressure = 1.0;
  pointer_data.pressure_max = 1.0;

  blink::Threads::UI()->PostTask(
      [ engine = _platformView->engine().GetWeakPtr(), pointer_data ] {
        if (engine.get()) {
          blink::PointerDataPacket packet(1);
          packet.SetPointerData(0, pointer_data);
          engine->DispatchPointerDataPacket(packet);
        }
      });
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
  if (_platformView) {
    _platformView->NotifyDestroyed();
  }

  [super dealloc];
}

@end
