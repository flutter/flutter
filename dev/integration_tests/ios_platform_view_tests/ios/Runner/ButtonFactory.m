// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ButtonFactory.h"

@interface PlatformButton: NSObject<FlutterPlatformView>

@property (strong, nonatomic) UIButton *button;
@property (assign, nonatomic) int counter;

@end

@implementation PlatformButton

- (instancetype)init
{
  self = [super init];
  if (self) {
    _counter = 0;
    _button = [[UIButton alloc] init];
    [_button setTitle:@"Initial Button Title" forState:UIControlStateNormal];
    [_button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
  }
  return self;
}

- (UIView *)view {
  return self.button;
}

- (void)buttonTapped {
  self.counter += 1;
  NSString *title = [NSString stringWithFormat:@"Button Tapped %d", self.counter];
  [self.button setTitle:title forState:UIControlStateNormal];
}

@end

@implementation ButtonFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[PlatformButton alloc] init];
}

@end
