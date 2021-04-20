// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "impeller_host_view_controller.h"
#import "Renderer.h"

@implementation ImpellerHostViewController {
  MTKView* view_;

  Renderer* renderer_;
}

- (void)loadView {
  view_ = [[MTKView alloc] init];
  view_.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [self setView:view_];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  view_.device = MTLCreateSystemDefaultDevice();

  if (!view_.device) {
    NSLog(@"Metal is not supported on this device");
    self.view = [[NSView alloc] initWithFrame:self.view.frame];
    return;
  }

  renderer_ = [[Renderer alloc] initWithMetalKitView:view_];

  [renderer_ mtkView:view_ drawableSizeWillChange:view_.bounds.size];

  view_.delegate = renderer_;
}

@end
