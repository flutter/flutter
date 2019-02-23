// Copyright 2018 The Flutter Authors. All rights reserved.
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

  UIStackView* stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.distribution = UIStackViewDistributionFillEqually;
  stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 50, 0);
  stackView.layoutMarginsRelativeArrangement = YES;
  [self.view addSubview:stackView];


  FlutterViewController* topFlutterViewController = [[FlutterViewController alloc] init];
  FlutterViewController* bottomFlutterViewController= [[FlutterViewController alloc] init];

  [topFlutterViewController setInitialRoute:@"marquee_green"];
  [self addChildViewController:topFlutterViewController];
  [stackView addArrangedSubview:topFlutterViewController.view];
  [topFlutterViewController didMoveToParentViewController:self];

  [bottomFlutterViewController setInitialRoute:@"marquee_purple"];
  [self addChildViewController:bottomFlutterViewController];
  [stackView addArrangedSubview:bottomFlutterViewController.view];
  [topFlutterViewController didMoveToParentViewController:self];
}

@end
