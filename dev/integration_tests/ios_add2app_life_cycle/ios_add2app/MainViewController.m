// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "MainViewController.h"

#import "AppDelegate.h"
#import "FullScreenViewController.h"

@interface MainViewController ()

@property(nonatomic, strong) UIStackView* stackView;

@end


@implementation MainViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.view setFrame:self.view.window.bounds];
  self.title = @"Flutter iOS Demos";
  self.view.backgroundColor = UIColor.whiteColor;

  self.stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  self.stackView.axis = UILayoutConstraintAxisVertical;
  self.stackView.distribution = UIStackViewDistributionEqualSpacing;
  self.stackView.alignment = UIStackViewAlignmentCenter;
  self.stackView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 50, 0);
  self.stackView.layoutMarginsRelativeArrangement = YES;
  [self.view addSubview:_stackView];

  [self addButton:@"Full Screen (Cold)" action:@selector(showFullScreenCold)];
}

- (void)showFullScreenCold {
  FlutterEngine *engine =
      [(AppDelegate *)[[UIApplication sharedApplication] delegate] engine];

  FullScreenViewController *flutterViewController =
      [[FullScreenViewController alloc] initWithEngine:engine
                                               nibName:nil
                                                bundle:nil];
  [self.navigationController
      pushViewController:flutterViewController
                animated:NO]; // Animating this is janky because of
                              // transitions with header on the native side.
                              // It's especially bad with a cold engine.
}

- (void)addButton:(NSString *)title action:(SEL)action {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self
                action:action
      forControlEvents:UIControlEventTouchUpInside];
  [self.stackView addArrangedSubview:button];
}

@end
