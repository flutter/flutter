// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "MainViewController.h"

#import "AppDelegate.h"
#import "DualFlutterViewController.h"
#import "FullScreenViewController.h"
#import "HybridViewController.h"
#import "NativeViewController.h"

@interface MainViewController ()
@property UIStackView *stackView;
@property(readonly) FlutterEngine *engine;
@property(readonly) FlutterBasicMessageChannel *reloadMessageChannel;
@end

@implementation MainViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.view setFrame:self.view.window.bounds];
  self.title = @"Flutter iOS Demos Home";
  self.view.backgroundColor = UIColor.whiteColor;

  UIStackView *stackView = [[UIStackView alloc] initWithFrame:self.view.frame];
  self.stackView = stackView;
  stackView.axis = UILayoutConstraintAxisVertical;
  stackView.distribution = UIStackViewDistributionEqualSpacing;
  stackView.alignment = UIStackViewAlignmentCenter;
  stackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  stackView.layoutMargins = UIEdgeInsetsMake(0, 0, 50, 0);
  stackView.layoutMarginsRelativeArrangement = YES;
  [self.view addSubview:self.stackView];

  [self addButton:@"Native iOS View" action:@selector(showNative)];
  [self addButton:@"Full Screen (Cold)" action:@selector(showFullScreenCold)];
  [self addButton:@"Full Screen (Warm)" action:@selector(showFullScreenWarm)];
  [self addButton:@"Flutter View (Warm)" action:@selector(showFlutterViewWarm)];
  [self addButton:@"Hybrid View (Warm)" action:@selector(showHybridView)];
  [self addButton:@"Dual Flutter View (Cold)" action:@selector(showDualView)];
}

- (FlutterEngine *)engine {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate] engine];
}

- (FlutterBasicMessageChannel*)reloadMessageChannel {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate] reloadMessageChannel];
}

- (void)showDualView {
  DualFlutterViewController *dualViewController = [[DualFlutterViewController alloc] init];
  [self.navigationController pushViewController:dualViewController
                                       animated:YES];
}

- (void)showHybridView {
  HybridViewController *hybridViewController = [[HybridViewController alloc] init];
  [self.navigationController pushViewController:hybridViewController
                                       animated:YES];
}
- (void)showNative {
  NativeViewController *nativeViewController = [[NativeViewController alloc] init];
  [self.navigationController pushViewController:nativeViewController
                                       animated:YES];
}

- (void)showFullScreenCold {
  FullScreenViewController *flutterViewController = [[FullScreenViewController alloc] init];
  [flutterViewController setInitialRoute:@"full"];
  [self.reloadMessageChannel sendMessage:@"full"];

  // Animating this is janky because of transitions with header on the native side.
  // It's especially bad with a cold engine.
  [self.navigationController pushViewController:flutterViewController animated:NO];
}

- (void)showFullScreenWarm {
  [self.engine.navigationChannel invokeMethod:@"setInitialRoute"
                                    arguments:@"full"];
  [self.reloadMessageChannel sendMessage:@"full"];

  FullScreenViewController *flutterViewController =
  [[FullScreenViewController alloc] initWithEngine:self.engine
                                           nibName:nil
                                            bundle:nil];
  // Animating this is problematic.
  [self.navigationController pushViewController:flutterViewController animated:NO];
}

- (void)showFlutterViewWarm {
  [self.engine.navigationChannel invokeMethod:@"setInitialRoute"
                                    arguments:@"/"];
  [self.reloadMessageChannel sendMessage:@"/"];

  FlutterViewController *flutterViewController =
  [[FlutterViewController alloc] initWithEngine:self.engine
                                        nibName:nil
                                         bundle:nil];
  [self.navigationController pushViewController:flutterViewController
                                       animated:YES];
}

- (void)addButton:(NSString *)title action:(SEL)action {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  [self.stackView addArrangedSubview:button];
}

@end
