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

@interface SkyWindow () <NSWindowDelegate>

@property (assign) IBOutlet NSOpenGLView *renderSurface;
@property (getter=isSurfaceSetup) BOOL surfaceSetup;

@end

@implementation SkyWindow {
  sky::SkyEnginePtr _sky_engine;
  scoped_ptr<sky::shell::ShellView> _shell_view;
}

@synthesize renderSurface=_renderSurface;
@synthesize surfaceSetup=_surfaceSetup;

-(void) awakeFromNib {
  [super awakeFromNib];

  self.delegate = self;

  [self windowDidResize:nil];
}

-(void) setupShell {
  NSAssert(_shell_view == nullptr, @"The shell view must not already be set");
  auto shell_view = new sky::shell::ShellView(sky::shell::Shell::Shared());
  _shell_view.reset(shell_view);

  auto widget = reinterpret_cast<gfx::AcceleratedWidget>(self.renderSurface);
  self.platformView->SurfaceCreated(widget);
}

-(NSString *) skyInitialLoadURL {
  return @"http://localhost:8080/sky/sdk/example/rendering/simple_autolayout.dart";
}

-(void) setupAndLoadDart {
  auto interface_request = mojo::GetProxy(&_sky_engine);
  self.platformView->ConnectToEngine(interface_request.Pass());

  mojo::String string(self.skyInitialLoadURL.UTF8String);
  _sky_engine->RunFromNetwork(string);
}

-(void) windowDidResize:(NSNotification *)notification {
  [self setupSurfaceIfNecessary];

  // Resize

  // sky::ViewportMetricsPtr metrics = sky::ViewportMetrics::New();
  // metrics->physical_width = size.width * scale;
  // metrics->physical_height = size.height * scale;
  // metrics->device_pixel_ratio = scale;
  // _sky_engine->OnViewportMetricsChanged(metrics.Pass());
}

-(void) setupSurfaceIfNecessary {
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

- (void)dispatchEvent:(NSEvent *)event phase:(NSEventPhase) phase {
  NSPoint location = [_renderSurface convertPoint:event.locationInWindow
                                         fromView:nil];

  location.y = _renderSurface.frame.size.height - location.y;
}

- (void)mouseDown:(NSEvent *)event {
  [self dispatchEvent:event phase:NSEventPhaseBegan];
}

- (void)mouseDragged:(NSEvent *)event {
  [self dispatchEvent:event phase:NSEventPhaseChanged];
}

- (void)mouseUp:(NSEvent *)event {
  [self dispatchEvent:event phase:NSEventPhaseEnded];
}

- (void) dealloc {
  self.platformView->SurfaceDestroyed();
  [super dealloc];
}

@end
