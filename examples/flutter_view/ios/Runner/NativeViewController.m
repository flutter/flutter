// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "NativeViewController.h"
#import "MDButton.h"

@interface NativeViewController ()
@property int counter;
@property (weak, nonatomic) IBOutlet UILabel* incrementLabel;
@end

@implementation NativeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.counter = 0;
}

- (IBAction)handleIncrement:(MDButton*)sender {
  [self.delegate didTapIncrementButton];
}

- (void)didReceiveIncrement {
  self.counter++;

  NSString* text = [NSString stringWithFormat:@"Flutter button tapped %d %@.",
                                              self.counter,
                                              (self.counter == 1)? @"time" : @"times"];
  self.incrementLabel.text = text;
}

@end
