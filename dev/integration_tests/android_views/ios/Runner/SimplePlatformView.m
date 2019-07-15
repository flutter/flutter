// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SimplePlatformView.h"

@implementation SimplePlatformView

- (UIView *)view {
  UIView *blueView = [UIView new];
  blueView.backgroundColor = [UIColor blueColor];
  return blueView;
}

@end
