// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "DrawingWebViewFactory.h"
#import <WebKit/WebKit.h>

@interface DrawingWebViewPlatformView: NSObject<FlutterPlatformView>
@property (strong, nonatomic) WKWebView *platformView;
@end

@implementation DrawingWebViewPlatformView

- (instancetype)init
{
  self = [super init];
  if (self) {
    _platformView = [[WKWebView alloc] init];
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"drawing_website" ofType:@"html"];
    NSURL *htmlURL = [NSURL fileURLWithPath:htmlPath];
    [self.platformView loadFileURL:htmlURL allowingReadAccessToURL:[htmlURL URLByDeletingLastPathComponent]];
  }
  return self;
}

- (UIView *)view {
  return self.platformView;
}

@end

@implementation DrawingWebViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[DrawingWebViewPlatformView alloc] init];
}

@end
