// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "PlatformViewController.h"

@interface PlatformViewController ()
@property (weak, nonatomic) IBOutlet UILabel *incrementLabel;
@end

@implementation PlatformViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setIncrementLabelText];
}

- (IBAction)handleIncrement:(id)sender {
  self.counter++;
  [self setIncrementLabelText];
}

- (IBAction)switchToFlutterView:(id)sender {
  [self.delegate didUpdateCounter:self.counter];
  [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)setIncrementLabelText {
  NSString* text = [NSString stringWithFormat:@"Button tapped %d %@.",
                    self.counter,
                    (self.counter == 1) ? @"time" : @"times"];
  self.incrementLabel.text = text;
}

@end
