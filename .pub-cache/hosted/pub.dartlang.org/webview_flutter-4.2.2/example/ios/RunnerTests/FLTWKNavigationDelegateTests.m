// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter;

// OCMock library doesn't generate a valid modulemap.
#import <OCMock/OCMock.h>

@interface FLTWKNavigationDelegateTests : XCTestCase

@property(strong, nonatomic) FlutterMethodChannel *mockMethodChannel;
@property(strong, nonatomic) FLTWKNavigationDelegate *navigationDelegate;

@end

@implementation FLTWKNavigationDelegateTests

- (void)setUp {
  self.mockMethodChannel = OCMClassMock(FlutterMethodChannel.class);
  self.navigationDelegate =
      [[FLTWKNavigationDelegate alloc] initWithChannel:self.mockMethodChannel];
}

- (void)testWebViewWebContentProcessDidTerminateCallsRecourseErrorChannel {
  WKWebView *webview = OCMClassMock(WKWebView.class);
  [self.navigationDelegate webViewWebContentProcessDidTerminate:webview];
  OCMVerify([self.mockMethodChannel invokeMethod:@"onWebResourceError"
                                       arguments:[OCMArg checkWithBlock:^BOOL(NSDictionary *args) {
                                         XCTAssertEqualObjects(args[@"errorType"],
                                                               @"webContentProcessTerminated");
                                         return true;
                                       }]]);
}

@end
