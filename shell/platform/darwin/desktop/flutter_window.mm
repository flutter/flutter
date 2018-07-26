// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import "flutter_window.h"

#include <sstream>

#include "flutter/common/task_runners.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/darwin/common/command_line.h"
#include "flutter/shell/platform/darwin/desktop/platform_view_mac.h"

@interface FlutterWindow () <NSWindowDelegate>

@property(strong) NSOpenGLView* renderSurface;

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
  shell::ThreadHost _thread_host;
  std::unique_ptr<shell::Shell> _shell;
  bool _mouseIsDown;
}

- (instancetype)init {
  self = [super initWithContentRect:NSMakeRect(10.0, 10.0, 800.0, 600.0)
                          styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                    NSWindowStyleMaskResizable
                            backing:NSBackingStoreBuffered
                              defer:YES];
  if (self) {
    self.delegate = self;
    [self setupRenderSurface];
    [self setupShell];
    [self updateWindowSize];
  }

  return self;
}

- (void)setupRenderSurface {
  NSOpenGLView* renderSurface = [[[NSOpenGLView alloc] init] autorelease];
  const NSOpenGLPixelFormatAttribute attrs[] = {
      NSOpenGLPFADoubleBuffer,           //
      NSOpenGLPFAAllowOfflineRenderers,  //
      0                                  //
  };
  renderSurface.pixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
  renderSurface.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  renderSurface.frame =
      NSMakeRect(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
  [self.contentView addSubview:renderSurface];
  self.renderSurface = renderSurface;
}

static std::string CreateThreadLabel() {
  std::stringstream stream;
  static int index = 1;
  stream << "io.flutter." << index++;
  return stream.str();
}

- (void)setupShell {
  FML_DCHECK(!_shell) << "The shell must not already be set.";

  auto thread_label = CreateThreadLabel();

  // Create the threads on which to run the shell.
  _thread_host = {thread_label, shell::ThreadHost::Type::GPU | shell::ThreadHost::Type::UI |
                                    shell::ThreadHost::Type::IO};

  // Grab the task runners for the newly created threads.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  blink::TaskRunners task_runners(thread_label,                                    // label
                                  fml::MessageLoop::GetCurrent().GetTaskRunner(),  // platform
                                  _thread_host.gpu_thread->GetTaskRunner(),        // GPU
                                  _thread_host.ui_thread->GetTaskRunner(),         // UI
                                  _thread_host.io_thread->GetTaskRunner()          // IO
  );

  // Figure out the settings from the command line arguments.
  auto settings = shell::SettingsFromCommandLine(shell::CommandLineFromNSProcessInfo());

  if (settings.icu_data_path.size() == 0) {
    settings.icu_data_path =
        [[NSBundle mainBundle] pathForResource:@"icudtl.dat" ofType:@""].UTF8String;
  }

  settings.task_observer_add = [](intptr_t key, fml::closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };

  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };

  // Setup the callback that will be run on the appropriate threads.
  shell::Shell::CreateCallback<shell::PlatformView> on_create_platform_view =
      [render_surface = self.renderSurface](shell::Shell& shell) {
        return std::make_unique<shell::PlatformViewMac>(shell, render_surface);
      };

  shell::Shell::CreateCallback<shell::Rasterizer> on_create_rasterizer = [](shell::Shell& shell) {
    return std::make_unique<shell::Rasterizer>(shell.GetTaskRunners());
  };

  // Finally, create the shell.
  _shell = shell::Shell::Create(std::move(task_runners), settings, on_create_platform_view,
                                on_create_rasterizer);

  // Launch the engine with the inferred run configuration.
  _shell->GetTaskRunners().GetUITaskRunner()->PostTask(fml::MakeCopyable(
      [engine = _shell->GetEngine(),
       config = shell::RunConfiguration::InferFromSettings(_shell->GetSettings())]() mutable {
        if (engine) {
          auto result = engine->Run(std::move(config));
          if (!result) {
            FML_LOG(ERROR) << "Could not launch the engine with configuration.";
          }
        }
      }));

  [self notifySurfaceCreated];
}

- (void)notifySurfaceCreated {
  if (!_shell || !_shell->IsSetup()) {
    return;
  }

  // Tell the platform view that it has a GL surface.
  _shell->GetPlatformView()->NotifyCreated();
}

- (void)notifySurfaceDestroyed {
  if (!_shell || !_shell->IsSetup()) {
    return;
  }

  // Tell the platform view that its surface is about to be lost.
  _shell->GetPlatformView()->NotifyDestroyed();
}

- (void)windowDidResize:(NSNotification*)notification {
  [self updateWindowSize];
}

- (void)updateWindowSize {
  if (!_shell) {
    return;
  }

  blink::ViewportMetrics metrics;
  auto size = self.renderSurface.frame.size;
  metrics.physical_width = size.width;
  metrics.physical_height = size.height;
  _shell->GetTaskRunners().GetUITaskRunner()->PostTask([engine = _shell->GetEngine(), metrics]() {
    if (engine) {
      engine->SetViewportMetrics(metrics);
    }
  });
}

#pragma mark - Responder overrides

- (void)dispatchEvent:(NSEvent*)event phase:(NSEventPhase)phase {
  if (!_shell) {
    return;
  }

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
      FML_DCHECK(!_mouseIsDown);
      break;
  }

  _shell->GetTaskRunners().GetUITaskRunner()->PostTask(
      [engine = _shell->GetEngine(), pointer_data] {
        if (engine) {
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

- (void)reset {
  [self notifySurfaceDestroyed];
  _shell.reset();
  _thread_host.Reset();
}

- (void)windowWillClose:(NSNotification*)notification {
  [self reset];
}

- (void)dealloc {
  [self reset];
  [super dealloc];
}

@end
