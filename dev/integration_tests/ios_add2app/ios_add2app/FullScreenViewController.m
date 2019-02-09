// Copyright 2018 The Flutter Authors. All rights reserved.
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
}
  
-(BOOL)prefersStatusBarHidden {
  return true;
}

@end
