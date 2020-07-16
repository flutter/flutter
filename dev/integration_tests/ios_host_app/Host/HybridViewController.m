// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;

#import "AppDelegate.h"
#import "HybridViewController.h"

@interface HybridViewController ()
@property FlutterBasicMessageChannel* messageChannel;
@property(readonly) FlutterEngine *engine;
@property(readonly) FlutterBasicMessageChannel *reloadMessageChannel;
@property FlutterViewController* flutterViewController;
@end

@implementation HybridViewController

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

  self.flutterViewController =
  [[FlutterViewController alloc] initWithEngine:self.engine
                                        nibName:nil
                                         bundle:nil];
  [self.reloadMessageChannel sendMessage:@"hybrid"];

  self.messageChannel = [[FlutterBasicMessageChannel alloc]
                         initWithName:@"increment"
                         binaryMessenger:self.flutterViewController.binaryMessenger
                         codec:[FlutterStringCodec sharedInstance]];
  [self addChildViewController:self.flutterViewController];
  [stackView addArrangedSubview:self.flutterViewController.view];
  [self.flutterViewController didMoveToParentViewController:self];
  
  __weak NativeViewController *weakNativeViewController = nativeViewController;
  [self.messageChannel setMessageHandler:^(id message, FlutterReply reply) {
    [weakNativeViewController didReceiveIncrement];
    reply(@"");
  }];
}

- (void)didTapIncrementButton {
  [self.messageChannel sendMessage:@"ping"];
}

@end
