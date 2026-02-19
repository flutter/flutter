// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "WebViewFactory.h"
#import <WebKit/WebKit.h>

@interface WebViewPlatformView: NSObject<FlutterPlatformView, WKNavigationDelegate>
@property (strong, nonatomic) WKWebView *platformView;
@end

@implementation WebViewPlatformView

- (instancetype)init
{
  self = [super init];
  if (self) {
    _platformView = [[WKWebView alloc] init];
    // Event listener is required to reproduce the non-tappable web view link issue (https://github.com/flutter/flutter/issues/175099).
    NSString *html = @"<html>"
      "  <head>"
      "    <title>Initial</title>"
      "    <script>"
      "      document.addEventListener('touchstart', () => console.log('touchstart on document'));"
      "    </script>"
      "  </head>"
      "  <body>"
      "    <a style='font-size: 50px;' href='custom://page2'>Target Link</a>"
      "  </body>"
      "</html>";
    [_platformView loadHTMLString:html baseURL:nil];
    _platformView.navigationDelegate = self;
  }
  return self;
}

- (UIView *)view {
  return self.platformView;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  if ([navigationAction.request.URL.scheme isEqualToString:@"custom"]) {
    NSString *html = @"<html>"
      "  <head>"
      "    <title>Page 2</title>"
      "  </head>"
      "  <body>"
      "    <h1 style='font-size: 50px;'>Navigation Successful</h1>"
      "  </body>"
      "</html>";
    [webView loadHTMLString:html baseURL:nil];
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  decisionHandler(WKNavigationActionPolicyAllow);
}

@end


@implementation WebViewFactory

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args {
  return [[WebViewPlatformView alloc] init];
}

@end
