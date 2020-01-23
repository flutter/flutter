// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

#import "AppDelegate.h"
#import "HybridViewController.h"

@interface HybridViewController ()

@end

static NSString *_kChannel = @"increment";
static NSString *_kPing = @"ping";

@implementation HybridViewController {
  FlutterBasicMessageChannel *_messageChannel;
}

- (FlutterEngine *)engine {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate] engine];
}

- (FlutterBasicMessageChannel *)reloadMessageChannel {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate]
      reloadMessageChannel];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Hybrid Flutter/Native";
  UIStackView *stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.distribution = UIStackViewDistributionFillEqually;
  stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 50, 0);
  stackView.layoutMarginsRelativeArrangement = YES;
  [self.view addSubview:stackView];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Back"
                                                      style:UIBarButtonItemStylePlain
                                                     target:nil
                                                     action:nil];

  NativeViewController *nativeViewController =
      [[NativeViewController alloc] initWithDelegate:self];
  [self addChildViewController:nativeViewController];
  [stackView addArrangedSubview:nativeViewController.view];
  [nativeViewController didMoveToParentViewController:self];

  _flutterViewController =
      [[FlutterViewController alloc] initWithEngine:[self engine]
                                            nibName:nil
                                             bundle:nil];
  [[self reloadMessageChannel] sendMessage:@"hybrid"];

  _messageChannel = [[FlutterBasicMessageChannel alloc]
         initWithName:_kChannel
      binaryMessenger:_flutterViewController.binaryMessenger
                codec:[FlutterStringCodec sharedInstance]];
  [self addChildViewController:_flutterViewController];
  [stackView addArrangedSubview:_flutterViewController.view];
  [_flutterViewController didMoveToParentViewController:self];

  __weak NativeViewController *weakNativeViewController = nativeViewController;
  [_messageChannel setMessageHandler:^(id message, FlutterReply reply) {
    [weakNativeViewController didReceiveIncrement];
    reply(@"");
  }];
}

- (void)didTapIncrementButton {
  [_messageChannel sendMessage:_kPing];
}

@end
