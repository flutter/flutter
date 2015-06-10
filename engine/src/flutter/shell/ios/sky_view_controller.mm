// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_view_controller.h"
#import "sky_surface.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@implementation SkyViewController

- (void)loadView {
  SkySurface* surface = [[SkySurface alloc] init];

  surface.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  self.view = surface;

  [surface release];
}

@end
