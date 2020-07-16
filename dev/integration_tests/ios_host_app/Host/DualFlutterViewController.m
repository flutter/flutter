// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;

#import "DualFlutterViewController.h"

@interface DualFlutterViewController ()
@property (readwrite) FlutterViewController* topFlutterViewController;
@property (readwrite) FlutterViewController* bottomFlutterViewController;
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

  self.topFlutterViewController = [[FlutterViewController alloc] init];
  self.bottomFlutterViewController= [[FlutterViewController alloc] init];

  [self.topFlutterViewController setInitialRoute:@"marquee_green"];
  [self addChildViewController:_topFlutterViewController];
  [stackView addArrangedSubview:_topFlutterViewController.view];
  [self.topFlutterViewController didMoveToParentViewController:self];

  [self.bottomFlutterViewController setInitialRoute:@"marquee_purple"];
  [self addChildViewController:_bottomFlutterViewController];
  [stackView addArrangedSubview:_bottomFlutterViewController.view];
  [self.bottomFlutterViewController didMoveToParentViewController:self];
}

@end
