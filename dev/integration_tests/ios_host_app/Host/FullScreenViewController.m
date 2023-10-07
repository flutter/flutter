// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FullScreenViewController.h"

@interface FullScreenViewController ()

@end

@implementation FullScreenViewController

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.title = @"Full Screen Flutter";
  self.navigationController.navigationBarHidden = YES;
  self.navigationController.hidesBarsOnSwipe = YES;
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  self.navigationController.navigationBarHidden = NO;
  self.navigationController.hidesBarsOnSwipe = NO;
  if (self.isMovingFromParentViewController) {
    // If we were doing things that might cause the VC
    // to disappear (like using the image_picker plugin)
    // we shouldn't do this, but in this case we know we're
    // just going back to the navigation controller.
    // If we needed Flutter to tell us when we could actually go away,
    // we'd need to communicate over a method channel with it.
    [self.engine setViewController:nil];
  }
}

-(BOOL)prefersStatusBarHidden {
  return true;
}

@end
