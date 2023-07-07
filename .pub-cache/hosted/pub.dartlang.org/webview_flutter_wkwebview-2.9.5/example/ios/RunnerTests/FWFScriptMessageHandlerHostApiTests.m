// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFScriptMessageHandlerHostApiTests : XCTestCase
@end

@implementation FWFScriptMessageHandlerHostApiTests
/**
 * Creates a partially mocked FWFScriptMessageHandler and adds it to instanceManager.
 *
 * @param instanceManager Instance manager to add the delegate to.
 * @param identifier Identifier for the delegate added to the instanceManager.
 *
 * @return A mock FWFScriptMessageHandler.
 */
- (id)mockHandlerWithManager:(FWFInstanceManager *)instanceManager identifier:(long)identifier {
  FWFScriptMessageHandler *handler = [[FWFScriptMessageHandler alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  [instanceManager addDartCreatedInstance:handler withIdentifier:0];
  return OCMPartialMock(handler);
}

/**
 * Creates a  mock FWFScriptMessageHandlerFlutterApiImpl with instanceManager.
 *
 * @param instanceManager Instance manager passed to the Flutter API.
 *
 * @return A mock FWFScriptMessageHandlerFlutterApiImpl.
 */
- (id)mockFlutterApiWithManager:(FWFInstanceManager *)instanceManager {
  FWFScriptMessageHandlerFlutterApiImpl *flutterAPI = [[FWFScriptMessageHandlerFlutterApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];
  return OCMPartialMock(flutterAPI);
}

- (void)testCreateWithIdentifier {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFScriptMessageHandlerHostApiImpl *hostAPI = [[FWFScriptMessageHandlerHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  [hostAPI createWithIdentifier:@0 error:&error];

  FWFScriptMessageHandler *scriptMessageHandler =
      (FWFScriptMessageHandler *)[instanceManager instanceForIdentifier:0];

  XCTAssertTrue([scriptMessageHandler conformsToProtocol:@protocol(WKScriptMessageHandler)]);
  XCTAssertNil(error);
}

- (void)testDidReceiveScriptMessageForHandler {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];

  FWFScriptMessageHandler *mockHandler = [self mockHandlerWithManager:instanceManager identifier:0];
  FWFScriptMessageHandlerFlutterApiImpl *mockFlutterAPI =
      [self mockFlutterApiWithManager:instanceManager];

  OCMStub([mockHandler scriptMessageHandlerAPI]).andReturn(mockFlutterAPI);

  WKUserContentController *userContentController = [[WKUserContentController alloc] init];
  [instanceManager addDartCreatedInstance:userContentController withIdentifier:1];

  WKScriptMessage *mockScriptMessage = OCMClassMock([WKScriptMessage class]);
  OCMStub([mockScriptMessage name]).andReturn(@"name");
  OCMStub([mockScriptMessage body]).andReturn(@"message");

  [mockHandler userContentController:userContentController
             didReceiveScriptMessage:mockScriptMessage];
  OCMVerify([mockFlutterAPI
      didReceiveScriptMessageForHandlerWithIdentifier:@0
                      userContentControllerIdentifier:@1
                                              message:[OCMArg isKindOfClass:[FWFWKScriptMessageData
                                                                                class]]
                                           completion:OCMOCK_ANY]);
}
@end
