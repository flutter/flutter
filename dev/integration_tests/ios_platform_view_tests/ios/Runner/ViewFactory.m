// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ViewFactory.h"

@interface PlatformView: NSObject<FlutterPlatformView>

@property (strong, nonatomic) UIView *platformView;

@end

@implementation PlatformView

- (instancetype)init
{
  self = [super init];
  if (self) {
    _platformView = [[UIView alloc] init];
    _platformView.backgroundColor = [UIColor blueColor];
  }
  return self;
}

- (UIView *)view {
  return self.platformView;
}

@end


@implementation ViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[PlatformView alloc] init];
}

@end
