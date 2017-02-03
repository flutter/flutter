// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

@implementation FlutterAppDelegate

// Returns the key window's rootViewController, if it's a FlutterViewController.
// Otherwise, returns nil.
- (FlutterViewController*)rootFlutterViewController {
  UIViewController *viewController =
      [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([viewController isKindOfClass:[FlutterViewController class]]) {
    return (FlutterViewController*)viewController;
  }
  return nil;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];

  // Pass status bar taps to key window Flutter rootViewController.
  if (self.rootFlutterViewController != nil) {
    [self.rootFlutterViewController handleStatusBarTouches:event];
  }
}

@end
