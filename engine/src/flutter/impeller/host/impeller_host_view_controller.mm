// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "impeller_host_view_controller.h"

#import "impeller_renderer.h"

@implementation ImpellerHostViewController {
  MTKView* view_;
  ImpellerRenderer* renderer_;
}

- (void)loadView {
  view_ = [[MTKView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
  view_.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.view = view_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  view_.device = MTLCreateSystemDefaultDevice();

  if (!view_.device) {
    NSLog(@"Metal is not supported on this device");
    self.view = [[NSView alloc] initWithFrame:self.view.frame];
    return;
  }

  renderer_ = [[ImpellerRenderer alloc] initWithMetalKitView:view_];
  [renderer_ mtkView:view_ drawableSizeWillChange:view_.bounds.size];
  view_.delegate = renderer_;
}

@end
