// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "TestNavigationController.h"
#import <Flutter/Flutter.h>

@implementation TestNavigationController

- (void) viewWillAppear:(BOOL)animated {
  [self setNavigationBarHidden:YES animated:NO];
  [super viewWillAppear:animated];
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated {
  FlutterViewController* root = (FlutterViewController*)[self.viewControllers objectAtIndex:0];

  FlutterBasicMessageChannel* messageChannel =
      [FlutterBasicMessageChannel messageChannelWithName:@"navigation-test"
                                         binaryMessenger:root
                                                   codec:[FlutterStringCodec sharedInstance]];
  [messageChannel sendMessage:@"ping"];
  return root;
}

@end
