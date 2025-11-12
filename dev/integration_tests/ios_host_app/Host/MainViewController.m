// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "MainViewController.h"

#import "AppDelegate.h"
#import "DualFlutterViewController.h"
#import "FullScreenViewController.h"
#import "HybridViewController.h"
#import "NativeViewController.h"
#import "DynamicResizingViewController.h"

@interface MainViewController ()

@property (weak, nonatomic) UIButton* flutterViewWarmButton;

@end


@implementation MainViewController {
  UIStackView *_stackView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.view setFrame:self.view.window.bounds];
  self.title = @"Flutter iOS Demos Home";
  self.view.backgroundColor = UIColor.whiteColor;

  _stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  _stackView.axis = UILayoutConstraintAxisVertical;
  _stackView.distribution = UIStackViewDistributionEqualSpacing;
  _stackView.alignment = UIStackViewAlignmentCenter;
  _stackView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 50, 0);
  _stackView.layoutMarginsRelativeArrangement = YES;
  [self.view addSubview:_stackView];

  [self addButton:@"Native iOS View" action:@selector(showNative)];
  [self addButton:@"Full Screen (Cold)" action:@selector(showFullScreenCold)];
  [self addButton:@"Full Screen (Warm)" action:@selector(showFullScreenWarm)];
  self.flutterViewWarmButton = [self addButton:@"Flutter View (Warm)" action:@selector(showFlutterViewWarm)];
  [self addButton:@"Hybrid View (Warm)" action:@selector(showHybridView)];
  [self addButton:@"Dual Flutter View (Cold)" action:@selector(showDualView)];
  [self addButton:@"Dynamic Content Resizing" action:@selector(showContentResizingView)];
}

- (FlutterEngine *)engine {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate] engine];
}

- (FlutterBasicMessageChannel*)reloadMessageChannel {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate] reloadMessageChannel];
}

- (void)showDualView {
  DualFlutterViewController *dualViewController =
      [[DualFlutterViewController alloc] init];
  [self.navigationController pushViewController:dualViewController
                                       animated:YES];
}

- (void)showHybridView {
  HybridViewController *hybridViewController =
      [[HybridViewController alloc] init];
  [self.navigationController pushViewController:hybridViewController
                                       animated:YES];
}
- (void)showNative {
  NativeViewController *nativeViewController =
      [[NativeViewController alloc] init];
  [self.navigationController pushViewController:nativeViewController
                                       animated:YES];
}

- (void)showContentResizingView {
  DynamicResizingViewController *resizingViewController =
      [[DynamicResizingViewController alloc] init];
  [self.navigationController pushViewController:resizingViewController
                                       animated:NO];
}

- (void)showFullScreenCold {
  FullScreenViewController *flutterViewController =
      [[FullScreenViewController alloc] init];
  [flutterViewController setInitialRoute:@"full"];
  [[self reloadMessageChannel] sendMessage:@"full"];
  [self.navigationController
      pushViewController:flutterViewController
                animated:NO]; // Animating this is janky because of
                              // transitions with header on the native side.
                              // It's especially bad with a cold engine.
}

- (void)showFullScreenWarm {
  [[self engine].navigationChannel invokeMethod:@"setInitialRoute"
                                      arguments:@"full"];
  [[self reloadMessageChannel] sendMessage:@"full"];

  FullScreenViewController *flutterViewController =
      [[FullScreenViewController alloc] initWithEngine:[self engine]
                                               nibName:nil
                                                bundle:nil];
  [self.navigationController
      pushViewController:flutterViewController
                animated:NO]; // Animating this is problematic.
}

- (void)showFlutterViewWarm {
  self.flutterViewWarmButton.backgroundColor = UIColor.redColor;
  FlutterEngine *engine = [self engine];
  FlutterBasicMessageChannel* messageChannel = [self reloadMessageChannel];
  NSAssert(engine != nil, @"Engine is not nil.");
  NSAssert(engine.navigationChannel != nil, @"Engine.navigationChannel is not nil.");
  NSAssert(messageChannel != nil, @"messageChannel is not nil.");

  [engine.navigationChannel invokeMethod:@"setInitialRoute"
                                      arguments:@"/"];
  [messageChannel sendMessage:@"/"];


  FlutterViewController *flutterViewController =
      [[FlutterViewController alloc] initWithEngine:[self engine]
                                            nibName:nil
                                             bundle:nil];
  flutterViewController.view.accessibilityLabel = @"flutter view";
  NSAssert(self.navigationController != nil, @"self.navigationController is not nil.");
  [self.navigationController pushViewController:flutterViewController
                                       animated:NO];

  if (self.navigationController.topViewController != flutterViewController) {
    // For debugging:
    // Some unknown issue happened caused `flutterViewController` not being pushed.
    // We try to push an basic UIViewController to see if it would work.
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view.backgroundColor = UIColor.blueColor;
    [self.navigationController pushViewController:viewController
                                         animated:NO];
    NSAssert(self.navigationController.topViewController == viewController, @"self.navigationController.topViewController should be the basic view controller");
  }
}

- (UIButton *)addButton:(NSString *)title action:(SEL)action {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self
                action:action
      forControlEvents:UIControlEventTouchUpInside];
  [_stackView addArrangedSubview:button];
  return button;
}

@end
