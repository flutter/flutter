// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

#import "AppDelegate.h"
#import "DynamicResizingViewController.h"

@interface DynamicResizingViewController ()

@end

static NSString *_kChannel = @"increment";
static NSString *_kPing = @"ping";

@implementation DynamicResizingViewController {
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
  self.title = @"Dynamically Resizable Flutter";

  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.userInteractionEnabled = YES;
  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.distribution = UIStackViewDistributionFill;
  stackView.translatesAutoresizingMaskIntoConstraints = NO;

  for (int index = 1; index <= 50; index++) {
      if (index == 10) {
        _flutterViewController = [[FlutterViewController alloc] init];
        _flutterViewController.autoResizable = true;
        [self addChildViewController:_flutterViewController];
        [stackView addArrangedSubview:_flutterViewController.view];
        [_flutterViewController didMoveToParentViewController:self];
      } else {
          UILabel *label = [[UILabel alloc] init];
          label.text = [NSString stringWithFormat:@"Hello from iOS %d", index];
          [stackView addArrangedSubview:label];
      }
  }
  [scrollView addSubview:stackView];
  [[self reloadMessageChannel] sendMessage:@"resize"];
  [scrollView layoutIfNeeded];
  [self.view addSubview:scrollView];

  [self.view addSubview:stackView];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Back"
                                                      style:UIBarButtonItemStylePlain
                                                     target:nil
                                           action:nil];
}

- (void)didTapIncrementButton {
  [_messageChannel sendMessage:_kPing];
}

@end
