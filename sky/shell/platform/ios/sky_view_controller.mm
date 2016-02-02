// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_view_controller.h"
#import "sky_surface.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#include "sky/shell/shell.h"
#include "sky/shell/shell_view.h"
#include "sky/services/platform/ios/system_chrome_impl.h"

@implementation SkyViewController {
  UIInterfaceOrientationMask _orientation_preferences;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _orientation_preferences = UIInterfaceOrientationMaskAll;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(onOrientationPreferencesUpdated:)
               name:@(flutter::platform::kOrientationUpdateNotificationName)
             object:nil];
  }
  return self;
}

- (void)loadView {
  auto shell_view = new sky::shell::ShellView(sky::shell::Shell::Shared());
  SkySurface* surface = [[SkySurface alloc] initWithShellView:shell_view];

  surface.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  self.view = surface;

  [surface release];
}

- (void)onOrientationPreferencesUpdated:(NSNotification*)notification {
  // Notifications may not be on the iOS UI thread
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDictionary* info = notification.userInfo;

    NSNumber* update =
        info[@(flutter::platform::kOrientationUpdateNotificationKey)];

    if (update == nil) {
      return;
    }

    NSUInteger new_preferences = update.unsignedIntegerValue;

    if (new_preferences != _orientation_preferences) {
      _orientation_preferences = new_preferences;
      [UIViewController attemptRotationToDeviceOrientation];
    }
  });
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return _orientation_preferences;
}

- (SkySurface*)surface {
  DCHECK([self isViewLoaded]);
  return reinterpret_cast<SkySurface*>(self.view);
}

- (void)viewDidAppear:(BOOL)animated {
  [self.surface visibilityDidChange:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self.surface visibilityDidChange:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

@end
