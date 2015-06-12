// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_view_controller.h"
#import "sky_surface.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#include "sky/shell/shell_view.h"

@implementation SkyViewController

- (void)loadView {

  ShellView* shell_view = new sky::shell::ShellView(sky::shell::Shell::Shared());
  SkySurface* surface = [[SkySurface alloc] initWithShellView: shell_view];

  surface.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  self.view = surface;

  [surface release];
}

@end
