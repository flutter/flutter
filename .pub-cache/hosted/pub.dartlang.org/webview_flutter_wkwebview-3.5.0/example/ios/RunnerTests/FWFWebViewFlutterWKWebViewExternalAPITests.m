// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@import webview_flutter_wkwebview;

@interface FWFWebViewFlutterWKWebViewExternalAPITests : XCTestCase
@end

@implementation FWFWebViewFlutterWKWebViewExternalAPITests
- (void)testWebViewForIdentifier {
  WKWebView *webView = [[WKWebView alloc] init];
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:webView withIdentifier:0];

  id<FlutterPluginRegistry> mockPluginRegistry = OCMProtocolMock(@protocol(FlutterPluginRegistry));
  OCMStub([mockPluginRegistry valuePublishedByPlugin:@"FLTWebViewFlutterPlugin"])
      .andReturn(instanceManager);

  XCTAssertEqualObjects(
      [FWFWebViewFlutterWKWebViewExternalAPI webViewForIdentifier:0
                                               withPluginRegistry:mockPluginRegistry],
      webView);
}
@end
