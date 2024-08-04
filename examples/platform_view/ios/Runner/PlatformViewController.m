// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "PlatformViewController.h"

#import <Foundation/Foundation.h>

@interface PlatformViewController ()
@property(weak, nonatomic) IBOutlet UILabel* countLabel;
@end

@implementation PlatformViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self updateCountLabelText];
}

- (IBAction)handleIncrement:(id)sender {
  self.counter++;
  [self updateCountLabelText];
}

- (IBAction)switchToFlutterView:(id)sender {
  [self.delegate didUpdateCounter:self.counter];
  [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)updateCountLabelText {
  NSString* text = [NSString stringWithFormat:@"Button tapped %d %@.", self.counter,
                                              (self.counter == 1) ? @"time" : @"times"];
  self.countLabel.text = text;
}

@end
