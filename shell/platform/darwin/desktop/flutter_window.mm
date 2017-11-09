// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter_window.h"

#include "flutter/common/threads.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/darwin/desktop/platform_view_mac.h"

@interface FlutterWindow ()<NSWindowDelegate>

@property(assign) IBOutlet NSOpenGLView* renderSurface;
@property(getter=isSurfaceSetup) BOOL surfaceSetup;

@end

static inline blink::PointerData::Change PointerChangeFromNSEventPhase(NSEventPhase phase) {
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

@implementation FlutterWindow {
  std::shared_ptr<shell::PlatformViewMac> _platformView;
  bool _mouseIsDown;
}

@synthesize renderSurface = _renderSurface;
@synthesize surfaceSetup = _surfaceSetup;

- (void)awakeFromNib {
  [super awakeFromNib];

  self.delegate = self;

  [self updateWindowSize];
}

- (void)setupPlatformView {
  FXL_DCHECK(_platformView == nullptr) << "The platform view must not already be set.";

  _platformView = std::make_shared<shell::PlatformViewMac>(self.renderSurface);
  _platformView->Attach();
  _platformView->SetupResourceContextOnIOThread();
  _platformView->NotifyCreated(std::make_unique<shell::GPUSurfaceGL>(_platformView.get()));
}

// TODO(eseidel): This does not belong in flutter_window!
// Probably belongs in NSApplicationDelegate didFinishLaunching.
- (void)setupAndLoadDart {
  _platformView->SetupAndLoadDart();
}

- (void)windowDidResize:(NSNotification*)notification {
  [self updateWindowSize];
}

- (void)updateWindowSize {
  [self setupSurfaceIfNecessary];

  blink::ViewportMetrics metrics;
  auto size = self.renderSurface.frame.size;
  metrics.physical_width = size.width;
  metrics.physical_height = size.height;

  blink::Threads::UI()->PostTask([ engine = _platformView->engine().GetWeakPtr(), metrics ] {
    if (engine.get()) {
      engine->SetViewportMetrics(metrics);
    }
  });
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
  NSPoint location = [_renderSurface convertPoint:event.locationInWindow fromView:nil];
  location.y = _renderSurface.frame.size.height - location.y;

  blink::PointerData pointer_data;
  pointer_data.Clear();

  constexpr int kMicrosecondsPerSecond = 1000 * 1000;
  pointer_data.time_stamp = event.timestamp * kMicrosecondsPerSecond;
  pointer_data.change = PointerChangeFromNSEventPhase(phase);
  pointer_data.kind = blink::PointerData::DeviceKind::kMouse;
  pointer_data.physical_x = location.x;
  pointer_data.physical_y = location.y;
  pointer_data.pressure = 1.0;
  pointer_data.pressure_max = 1.0;

  switch (pointer_data.change) {
    case blink::PointerData::Change::kDown:
      _mouseIsDown = true;
      break;
    case blink::PointerData::Change::kCancel:
    case blink::PointerData::Change::kUp:
      _mouseIsDown = false;
      break;
    case blink::PointerData::Change::kMove:
      if (!_mouseIsDown)
        pointer_data.change = blink::PointerData::Change::kHover;
      break;
    case blink::PointerData::Change::kAdd:
    case blink::PointerData::Change::kRemove:
    case blink::PointerData::Change::kHover:
      FXL_DCHECK(!_mouseIsDown);
      break;
  }

  blink::Threads::UI()->PostTask([ engine = _platformView->engine().GetWeakPtr(), pointer_data ] {
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
