// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

static bool feq(CGFloat a, CGFloat b) { return fabs(b - a) < FLT_EPSILON; }

@interface FWFWebViewHostApiTests : XCTestCase
@end

@implementation FWFWebViewHostApiTests
- (void)testCreateWithIdentifier {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  [instanceManager addDartCreatedInstance:[[WKWebViewConfiguration alloc] init] withIdentifier:0];

  FlutterError *error;
  [hostAPI createWithIdentifier:@1 configurationIdentifier:@0 error:&error];
  WKWebView *webView = (WKWebView *)[instanceManager instanceForIdentifier:1];
  XCTAssertTrue([webView isKindOfClass:[WKWebView class]]);
  XCTAssertNil(error);
}

- (void)testLoadRequest {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  FWFNSUrlRequestData *requestData = [FWFNSUrlRequestData makeWithUrl:@"https://www.flutter.dev"
                                                           httpMethod:@"get"
                                                             httpBody:nil
                                                  allHttpHeaderFields:@{@"a" : @"header"}];
  [hostAPI loadRequestForWebViewWithIdentifier:@0 request:requestData error:&error];

  NSURL *url = [NSURL URLWithString:@"https://www.flutter.dev"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  request.HTTPMethod = @"get";
  request.allHTTPHeaderFields = @{@"a" : @"header"};
  OCMVerify([mockWebView loadRequest:request]);
  XCTAssertNil(error);
}

- (void)testLoadRequestWithInvalidUrl {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);
  OCMReject([mockWebView loadRequest:OCMOCK_ANY]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  FWFNSUrlRequestData *requestData = [FWFNSUrlRequestData makeWithUrl:@"%invalidUrl%"
                                                           httpMethod:nil
                                                             httpBody:nil
                                                  allHttpHeaderFields:@{}];
  [hostAPI loadRequestForWebViewWithIdentifier:@0 request:requestData error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.code, @"FWFURLRequestParsingError");
  XCTAssertEqualObjects(error.message, @"Failed instantiating an NSURLRequest.");
  XCTAssertEqualObjects(error.details, @"URL was: '%invalidUrl%'");
}

- (void)testSetCustomUserAgent {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI setUserAgentForWebViewWithIdentifier:@0 userAgent:@"userA" error:&error];
  OCMVerify([mockWebView setCustomUserAgent:@"userA"]);
  XCTAssertNil(error);
}

- (void)testURL {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);
  OCMStub([mockWebView URL]).andReturn([NSURL URLWithString:@"https://www.flutter.dev/"]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  XCTAssertEqualObjects([hostAPI URLForWebViewWithIdentifier:@0 error:&error],
                        @"https://www.flutter.dev/");
  XCTAssertNil(error);
}

- (void)testCanGoBack {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);
  OCMStub([mockWebView canGoBack]).andReturn(YES);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  XCTAssertEqualObjects([hostAPI canGoBackForWebViewWithIdentifier:@0 error:&error], @YES);
  XCTAssertNil(error);
}

- (void)testSetUIDelegate {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  id<WKUIDelegate> mockDelegate = OCMProtocolMock(@protocol(WKUIDelegate));
  [instanceManager addDartCreatedInstance:mockDelegate withIdentifier:1];

  FlutterError *error;
  [hostAPI setUIDelegateForWebViewWithIdentifier:@0 delegateIdentifier:@1 error:&error];
  OCMVerify([mockWebView setUIDelegate:mockDelegate]);
  XCTAssertNil(error);
}

- (void)testSetNavigationDelegate {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  id<WKNavigationDelegate> mockDelegate = OCMProtocolMock(@protocol(WKNavigationDelegate));
  [instanceManager addDartCreatedInstance:mockDelegate withIdentifier:1];
  FlutterError *error;

  [hostAPI setNavigationDelegateForWebViewWithIdentifier:@0 delegateIdentifier:@1 error:&error];
  OCMVerify([mockWebView setNavigationDelegate:mockDelegate]);
  XCTAssertNil(error);
}

- (void)testEstimatedProgress {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);
  OCMStub([mockWebView estimatedProgress]).andReturn(34.0);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  XCTAssertEqualObjects([hostAPI estimatedProgressForWebViewWithIdentifier:@0 error:&error], @34.0);
  XCTAssertNil(error);
}

- (void)testloadHTMLString {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI loadHTMLForWebViewWithIdentifier:@0
                                 HTMLString:@"myString"
                                    baseURL:@"myBaseUrl"
                                      error:&error];
  OCMVerify([mockWebView loadHTMLString:@"myString" baseURL:[NSURL URLWithString:@"myBaseUrl"]]);
  XCTAssertNil(error);
}

- (void)testLoadFileURL {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI loadFileForWebViewWithIdentifier:@0
                                    fileURL:@"myFolder/apple.txt"
                              readAccessURL:@"myFolder"
                                      error:&error];
  XCTAssertNil(error);
  OCMVerify([mockWebView loadFileURL:[NSURL fileURLWithPath:@"myFolder/apple.txt" isDirectory:NO]
             allowingReadAccessToURL:[NSURL fileURLWithPath:@"myFolder/" isDirectory:YES]

  ]);
}

- (void)testLoadFlutterAsset {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFAssetManager *mockAssetManager = OCMClassMock([FWFAssetManager class]);
  OCMStub([mockAssetManager lookupKeyForAsset:@"assets/index.html"])
      .andReturn(@"myFolder/assets/index.html");

  NSBundle *mockBundle = OCMClassMock([NSBundle class]);
  OCMStub([mockBundle URLForResource:@"myFolder/assets/index" withExtension:@"html"])
      .andReturn([NSURL URLWithString:@"webview_flutter/myFolder/assets/index.html"]);

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager
                       bundle:mockBundle
                 assetManager:mockAssetManager];

  FlutterError *error;
  [hostAPI loadAssetForWebViewWithIdentifier:@0 assetKey:@"assets/index.html" error:&error];

  XCTAssertNil(error);
  OCMVerify([mockWebView
                  loadFileURL:[NSURL URLWithString:@"webview_flutter/myFolder/assets/index.html"]
      allowingReadAccessToURL:[NSURL URLWithString:@"webview_flutter/myFolder/assets/"]]);
}

- (void)testCanGoForward {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);
  OCMStub([mockWebView canGoForward]).andReturn(NO);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  XCTAssertEqualObjects([hostAPI canGoForwardForWebViewWithIdentifier:@0 error:&error], @NO);
  XCTAssertNil(error);
}

- (void)testGoBack {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI goBackForWebViewWithIdentifier:@0 error:&error];
  OCMVerify([mockWebView goBack]);
  XCTAssertNil(error);
}

- (void)testGoForward {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI goForwardForWebViewWithIdentifier:@0 error:&error];
  OCMVerify([mockWebView goForward]);
  XCTAssertNil(error);
}

- (void)testReload {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI reloadWebViewWithIdentifier:@0 error:&error];
  OCMVerify([mockWebView reload]);
  XCTAssertNil(error);
}

- (void)testTitle {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);
  OCMStub([mockWebView title]).andReturn(@"myTitle");

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  XCTAssertEqualObjects([hostAPI titleForWebViewWithIdentifier:@0 error:&error], @"myTitle");
  XCTAssertNil(error);
}

- (void)testSetAllowsBackForwardNavigationGestures {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI setAllowsBackForwardForWebViewWithIdentifier:@0 isAllowed:@YES error:&error];
  OCMVerify([mockWebView setAllowsBackForwardNavigationGestures:YES]);
  XCTAssertNil(error);
}

- (void)testEvaluateJavaScript {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  OCMStub([mockWebView
      evaluateJavaScript:@"runJavaScript"
       completionHandler:([OCMArg invokeBlockWithArgs:@"result", [NSNull null], nil])]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  NSString __block *returnValue;
  FlutterError __block *returnError;
  [hostAPI evaluateJavaScriptForWebViewWithIdentifier:@0
                                     javaScriptString:@"runJavaScript"
                                           completion:^(id result, FlutterError *error) {
                                             returnValue = result;
                                             returnError = error;
                                           }];

  XCTAssertEqualObjects(returnValue, @"result");
  XCTAssertNil(returnError);
}

- (void)testEvaluateJavaScriptReturnsNSErrorData {
  FWFWebView *mockWebView = OCMClassMock([FWFWebView class]);

  OCMStub([mockWebView
      evaluateJavaScript:@"runJavaScript"
       completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null],
                                                      [NSError errorWithDomain:@"errorDomain"
                                                                          code:0
                                                                      userInfo:@{
                                                                        NSLocalizedDescriptionKey :
                                                                            @"description"
                                                                      }],
                                                      nil])]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockWebView withIdentifier:0];

  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  NSString __block *returnValue;
  FlutterError __block *returnError;
  [hostAPI evaluateJavaScriptForWebViewWithIdentifier:@0
                                     javaScriptString:@"runJavaScript"
                                           completion:^(id result, FlutterError *error) {
                                             returnValue = result;
                                             returnError = error;
                                           }];

  XCTAssertNil(returnValue);
  FWFNSErrorData *errorData = returnError.details;
  XCTAssertTrue([errorData isKindOfClass:[FWFNSErrorData class]]);
  XCTAssertEqualObjects(errorData.code, @0);
  XCTAssertEqualObjects(errorData.domain, @"errorDomain");
  XCTAssertEqualObjects(errorData.localizedDescription, @"description");
}

- (void)testWebViewContentInsetBehaviorShouldBeNeverOnIOS11 API_AVAILABLE(ios(11.0)) {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  [instanceManager addDartCreatedInstance:[[WKWebViewConfiguration alloc] init] withIdentifier:0];

  FlutterError *error;
  [hostAPI createWithIdentifier:@1 configurationIdentifier:@0 error:&error];
  FWFWebView *webView = (FWFWebView *)[instanceManager instanceForIdentifier:1];

  XCTAssertEqual(webView.scrollView.contentInsetAdjustmentBehavior,
                 UIScrollViewContentInsetAdjustmentNever);
}

- (void)testScrollViewsAutomaticallyAdjustsScrollIndicatorInsetsShouldbeNoOnIOS13 API_AVAILABLE(
    ios(13.0)) {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFWebViewHostApiImpl *hostAPI = [[FWFWebViewHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  [instanceManager addDartCreatedInstance:[[WKWebViewConfiguration alloc] init] withIdentifier:0];

  FlutterError *error;
  [hostAPI createWithIdentifier:@1 configurationIdentifier:@0 error:&error];
  FWFWebView *webView = (FWFWebView *)[instanceManager instanceForIdentifier:1];

  XCTAssertFalse(webView.scrollView.automaticallyAdjustsScrollIndicatorInsets);
}

- (void)testContentInsetsSumAlwaysZeroAfterSetFrame {
  FWFWebView *webView = [[FWFWebView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)
                                            configuration:[[WKWebViewConfiguration alloc] init]];

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
