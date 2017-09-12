// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterNavigationController.h"

@implementation FlutterNavigationController

- (void)viewWillAppear:(BOOL)animated {
  [self setNavigationBarHidden:YES];
  [super viewWillAppear:animated];
}

@end
