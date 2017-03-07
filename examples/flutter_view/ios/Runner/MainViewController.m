// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.Copyright © 2017 The Chromium Authors. All rights reserved.


#import <Foundation/Foundation.h>

#import "MainViewController.h"
#import "NativeViewController.h"

@interface MainViewController ()

@property (strong, nonatomic) NativeViewController* nativeViewController;
@property (strong, nonatomic) FlutterViewController* flutterViewController;
@end

static NSString* const emptyString = @"";
static NSString* const channel = @"increment";

@implementation MainViewController

- (NSString*) messageName {
  return channel;
}

- (NSString*)didReceiveString:(NSString*)message {
  [self.nativeViewController didReceiveIncrement];
  return emptyString;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {

  if ([segue.identifier isEqualToString: @"NativeViewControllerSegue"]) {
    self.nativeViewController = segue.destinationViewController;
    self.nativeViewController.delegate = self;
  }

  if ([segue.identifier isEqualToString:@"FlutterViewControllerSegue"]) {
     self.flutterViewController = segue.destinationViewController;
    [self.flutterViewController addMessageListener:self];
  }
}

- (void)didTapIncrementButton {
  [self.flutterViewController sendString:emptyString withMessageName:self.messageName];
}

@end
