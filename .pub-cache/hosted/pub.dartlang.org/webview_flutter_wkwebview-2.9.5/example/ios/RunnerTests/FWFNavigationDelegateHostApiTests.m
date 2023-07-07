// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFNavigationDelegateHostApiTests : XCTestCase
@end

@implementation FWFNavigationDelegateHostApiTests
/**
 * Creates a partially mocked FWFNavigationDelegate and adds it to instanceManager.
 *
 * @param instanceManager Instance manager to add the delegate to.
 * @param identifier Identifier for the delegate added to the instanceManager.
 *
 * @return A mock FWFNavigationDelegate.
 */
- (id)mockNavigationDelegateWithManager:(FWFInstanceManager *)instanceManager
                             identifier:(long)identifier {
  FWFNavigationDelegate *navigationDelegate = [[FWFNavigationDelegate alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  [instanceManager addDartCreatedInstance:navigationDelegate withIdentifier:0];
  return OCMPartialMock(navigationDelegate);
}

/**
 * Creates a  mock FWFNavigationDelegateFlutterApiImpl with instanceManager.
 *
 * @param instanceManager Instance manager passed to the Flutter API.
 *
 * @return A mock FWFNavigationDelegateFlutterApiImpl.
 */
- (id)mockFlutterApiWithManager:(FWFInstanceManager *)instanceManager {
  FWFNavigationDelegateFlutterApiImpl *flutterAPI = [[FWFNavigationDelegateFlutterApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];
  return OCMPartialMock(flutterAPI);
}

- (void)testCreateWithIdentifier {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFNavigationDelegateHostApiImpl *hostAPI = [[FWFNavigationDelegateHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI createWithIdentifier:@0 error:&error];
  FWFNavigationDelegate *navigationDelegate =
      (FWFNavigationDelegate *)[instanceManager instanceForIdentifier:0];

  XCTAssertTrue([navigationDelegate conformsToProtocol:@protocol(WKNavigationDelegate)]);
  XCTAssertNil(error);
}

- (void)testDidFinishNavigation {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFNavigationDelegate *mockDelegate = [self mockNavigationDelegateWithManager:instanceManager
                                                                     identifier:0];
  FWFNavigationDelegateFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockDelegate navigationDelegateAPI]).andReturn(mockFlutterAPI);

  WKWebView *mockWebView = OCMClassMock([WKWebView class]);
  OCMStub([mockWebView URL]).andReturn([NSURL URLWithString:@"https://flutter.dev/"]);
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:1];

  [mockDelegate webView:mockWebView didFinishNavigation:OCMClassMock([WKNavigation class])];
  OCMVerify([mockFlutterAPI didFinishNavigationForDelegateWithIdentifier:@0
                                                       webViewIdentifier:@1
                                                                     URL:@"https://flutter.dev/"
                                                              completion:OCMOCK_ANY]);
}

- (void)testDidStartProvisionalNavigation {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFNavigationDelegate *mockDelegate = [self mockNavigationDelegateWithManager:instanceManager
                                                                     identifier:0];
  FWFNavigationDelegateFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockDelegate navigationDelegateAPI]).andReturn(mockFlutterAPI);

  WKWebView *mockWebView = OCMClassMock([WKWebView class]);
  OCMStub([mockWebView URL]).andReturn([NSURL URLWithString:@"https://flutter.dev/"]);
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:1];

  [mockDelegate webView:mockWebView
      didStartProvisionalNavigation:OCMClassMock([WKNavigation class])];
  OCMVerify([mockFlutterAPI
      didStartProvisionalNavigationForDelegateWithIdentifier:@0
                                           webViewIdentifier:@1
                                                         URL:@"https://flutter.dev/"
                                                  completion:OCMOCK_ANY]);
}

- (void)testDecidePolicyForNavigationAction {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFNavigationDelegate *mockDelegate = [self mockNavigationDelegateWithManager:instanceManager
                                                                     identifier:0];
  FWFNavigationDelegateFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockDelegate navigationDelegateAPI]).andReturn(mockFlutterAPI);

  WKWebView *mockWebView = OCMClassMock([WKWebView class]);
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:1];

  WKNavigationAction *mockNavigationAction = OCMClassMock([WKNavigationAction class]);
  OCMStub([mockNavigationAction request])
      .andReturn([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.flutter.dev"]]);

  WKFrameInfo *mockFrameInfo = OCMClassMock([WKFrameInfo class]);
  OCMStub([mockFrameInfo isMainFrame]).andReturn(YES);
  OCMStub([mockNavigationAction targetFrame]).andReturn(mockFrameInfo);

  OCMStub([mockFlutterAPI
      decidePolicyForNavigationActionForDelegateWithIdentifier:@0
                                             webViewIdentifier:@1
                                              navigationAction:
                                                  [OCMArg isKindOfClass:[FWFWKNavigationActionData
                                                                            class]]
                                                    completion:
                                                        ([OCMArg
                                                            invokeBlockWithArgs:
                                                                [FWFWKNavigationActionPolicyEnumData
                                                                    makeWithValue:
                                                                        FWFWKNavigationActionPolicyEnumCancel],
                                                                [NSNull null], nil])]);

  WKNavigationActionPolicy __block callbackPolicy = -1;
  [mockDelegate webView:mockWebView
      decidePolicyForNavigationAction:mockNavigationAction
                      decisionHandler:^(WKNavigationActionPolicy policy) {
                        callbackPolicy = policy;
                      }];
  XCTAssertEqual(callbackPolicy, WKNavigationActionPolicyCancel);
}

- (void)testDidFailNavigation {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFNavigationDelegate *mockDelegate = [self mockNavigationDelegateWithManager:instanceManager
                                                                     identifier:0];
  FWFNavigationDelegateFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockDelegate navigationDelegateAPI]).andReturn(mockFlutterAPI);

  WKWebView *mockWebView = OCMClassMock([WKWebView class]);
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:1];

  [mockDelegate webView:mockWebView
      didFailNavigation:OCMClassMock([WKNavigation class])
              withError:[NSError errorWithDomain:@"domain" code:0 userInfo:nil]];
  OCMVerify([mockFlutterAPI
      didFailNavigationForDelegateWithIdentifier:@0
                               webViewIdentifier:@1
                                           error:[OCMArg isKindOfClass:[FWFNSErrorData class]]
                                      completion:OCMOCK_ANY]);
}

- (void)testDidFailProvisionalNavigation {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFNavigationDelegate *mockDelegate = [self mockNavigationDelegateWithManager:instanceManager
                                                                     identifier:0];
  FWFNavigationDelegateFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockDelegate navigationDelegateAPI]).andReturn(mockFlutterAPI);

  WKWebView *mockWebView = OCMClassMock([WKWebView class]);
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:1];

  [mockDelegate webView:mockWebView
      didFailProvisionalNavigation:OCMClassMock([WKNavigation class])
                         withError:[NSError errorWithDomain:@"domain" code:0 userInfo:nil]];
  OCMVerify([mockFlutterAPI
      didFailProvisionalNavigationForDelegateWithIdentifier:@0
                                          webViewIdentifier:@1
                                                      error:[OCMArg isKindOfClass:[FWFNSErrorData
                                                                                      class]]
                                                 completion:OCMOCK_ANY]);
}

- (void)testWebViewWebContentProcessDidTerminate {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFNavigationDelegate *mockDelegate = [self mockNavigationDelegateWithManager:instanceManager
                                                                     identifier:0];
  FWFNavigationDelegateFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockDelegate navigationDelegateAPI]).andReturn(mockFlutterAPI);

  WKWebView *mockWebView = OCMClassMock([WKWebView class]);
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:1];

  [mockDelegate webViewWebContentProcessDidTerminate:mockWebView];
  OCMVerify([mockFlutterAPI
      webViewWebContentProcessDidTerminateForDelegateWithIdentifier:@0
                                                  webViewIdentifier:@1
                                                         completion:OCMOCK_ANY]);
}
@end
