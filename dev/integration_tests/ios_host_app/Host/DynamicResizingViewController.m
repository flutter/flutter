// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

#import "DynamicResizingViewController.h"

@interface DynamicResizingViewController ()

@end

@implementation DynamicResizingViewController {}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Dynamic Content Resizing";

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 10;
    [scrollView addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
      [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
      [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [stackView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
      [stackView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
      [stackView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
      [stackView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],

      [stackView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];

    for (int index = 1; index <= 50; index++) {
      if (index == 10) {
        _flutterViewController = [[FlutterViewController alloc] init];
        [_flutterViewController setInitialRoute:@"resize"];
        _flutterViewController.autoResizable = YES;
        [self addChildViewController:_flutterViewController];
        [stackView addArrangedSubview:_flutterViewController.view];
        _flutterViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        _flutterViewController.view.accessibilityIdentifier = @"flutter_view";
        [_flutterViewController didMoveToParentViewController:self];
      } else {
        UILabel *label = [[UILabel alloc] init];
        label.text = [NSString stringWithFormat:@"     Hello from iOS %d     ", index];
        label.backgroundColor = (index % 2 == 0) ? [UIColor systemGray5Color] : [UIColor systemGray3Color];
        label.translatesAutoresizingMaskIntoConstraints = NO;

        [label.heightAnchor constraintEqualToConstant:44].active = YES;

        [stackView addArrangedSubview:label];
      }
    }
}

@end
