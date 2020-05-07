// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

#import "DualFlutterViewController.h"

@interface DualFlutterViewController ()

@end

@implementation DualFlutterViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Dual Flutter Views";
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Back"
                                                      style:UIBarButtonItemStylePlain
                                                     target:nil
                                                     action:nil];

  UIStackView* stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.distribution = UIStackViewDistributionFillEqually;
  stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 50, 0);
  stackView.layoutMarginsRelativeArrangement = YES;
  [self.view addSubview:stackView];

  _topFlutterViewController = [[FlutterViewController alloc] init];
  _bottomFlutterViewController= [[FlutterViewController alloc] init];

  [_topFlutterViewController setInitialRoute:@"marquee_green"];
  [self addChildViewController:_topFlutterViewController];
  [stackView addArrangedSubview:_topFlutterViewController.view];
  [_topFlutterViewController didMoveToParentViewController:self];

  [_bottomFlutterViewController setInitialRoute:@"marquee_purple"];
  [self addChildViewController:_bottomFlutterViewController];
  [stackView addArrangedSubview:_bottomFlutterViewController.view];
  [_bottomFlutterViewController didMoveToParentViewController:self];
}

@end
