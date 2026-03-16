// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "WebViewFactory.h"
#import "LinkNavigationWebView.h"

@interface WebViewPlatformView: NSObject<FlutterPlatformView>
@property (strong, nonatomic) LinkNavigationWebView *platformView;
@end

@implementation WebViewPlatformView

- (instancetype)init
{
  self = [super init];
  if (self) {
    _platformView = [[LinkNavigationWebView alloc] init];
  }
  return self;
}

- (UIView *)view {
  return self.platformView;
}

@end

@implementation WebViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[WebViewPlatformView alloc] init];
}

@end
