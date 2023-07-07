// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter;

// OCMock library doesn't generate a valid modulemap.
#import <OCMock/OCMock.h>

static bool feq(CGFloat a, CGFloat b) { return fabs(b - a) < FLT_EPSILON; }

@interface FLTWebViewTests : XCTestCase

@property(strong, nonatomic) NSObject<FlutterBinaryMessenger> *mockBinaryMessenger;

@end

@implementation FLTWebViewTests

- (void)setUp {
  [super setUp];
  self.mockBinaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
}

- (void)testCanInitFLTWebViewController {
  FLTWebViewController *controller =
      [[FLTWebViewController alloc] initWithFrame:CGRectMake(0, 0, 300, 400)
                                   viewIdentifier:1
                                        arguments:nil
                                  binaryMessenger:self.mockBinaryMessenger];
  XCTAssertNotNil(controller);
}

- (void)testCanInitFLTWebViewFactory {
  FLTWebViewFactory *factory =
      [[FLTWebViewFactory alloc] initWithMessenger:self.mockBinaryMessenger];
  XCTAssertNotNil(factory);
}

- (void)webViewContentInsetBehaviorShouldBeNeverOnIOS11 {
  if (@available(iOS 11, *)) {
    FLTWebViewController *controller =
        [[FLTWebViewController alloc] initWithFrame:CGRectMake(0, 0, 300, 400)
                                     viewIdentifier:1
                                          arguments:nil
                                    binaryMessenger:self.mockBinaryMessenger];
    UIView *view = controller.view;
    XCTAssertTrue([view isKindOfClass:WKWebView.class]);
    WKWebView *webView = (WKWebView *)view;
    XCTAssertEqual(webView.scrollView.contentInsetAdjustmentBehavior,
                   UIScrollViewContentInsetAdjustmentNever);
  }
}

- (void)testWebViewScrollIndicatorAticautomaticallyAdjustsScrollIndicatorInsetsShouldbeNoOnIOS13 {
  if (@available(iOS 13, *)) {
    FLTWebViewController *controller =
        [[FLTWebViewController alloc] initWithFrame:CGRectMake(0, 0, 300, 400)
                                     viewIdentifier:1
                                          arguments:nil
                                    binaryMessenger:self.mockBinaryMessenger];
    UIView *view = controller.view;
    XCTAssertTrue([view isKindOfClass:WKWebView.class]);
    WKWebView *webView = (WKWebView *)view;
    XCTAssertFalse(webView.scrollView.automaticallyAdjustsScrollIndicatorInsets);
  }
}

- (void)testContentInsetsSumAlwaysZeroAfterSetFrame {
  FLTWKWebView *webView = [[FLTWKWebView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
  webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 300, 0);
  XCTAssertFalse(UIEdgeInsetsEqualToEdgeInsets(webView.scrollView.contentInset, UIEdgeInsetsZero));
  webView.frame = CGRectMake(0, 0, 300, 200);
  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(webView.scrollView.contentInset, UIEdgeInsetsZero));
  XCTAssertTrue(CGRectEqualToRect(webView.frame, CGRectMake(0, 0, 300, 200)));

  if (@available(iOS 11, *)) {
    // After iOS 11, we need to make sure the contentInset compensates the adjustedContentInset.
    UIScrollView *partialMockScrollView = OCMPartialMock(webView.scrollView);
    UIEdgeInsets insetToAdjust = UIEdgeInsetsMake(0, 0, 300, 0);
    OCMStub(partialMockScrollView.adjustedContentInset).andReturn(insetToAdjust);
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(webView.scrollView.contentInset, UIEdgeInsetsZero));
    webView.frame = CGRectMake(0, 0, 300, 100);
    XCTAssertTrue(feq(webView.scrollView.contentInset.bottom, -insetToAdjust.bottom));
    XCTAssertTrue(CGRectEqualToRect(webView.frame, CGRectMake(0, 0, 300, 100)));
  }
}

@end
