// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFURLTests : XCTestCase
@end

@implementation FWFURLTests
- (void)testAbsoluteString {
  NSURL *mockUrl = OCMClassMock([NSURL class]);
  OCMStub([mockUrl absoluteString]).andReturn(@"https://www.google.com");

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockUrl withIdentifier:0];

  FWFURLHostApiImpl *hostApi = [[FWFURLHostApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  FlutterError *error;
  XCTAssertEqualObjects([hostApi absoluteStringForNSURLWithIdentifier:@(0) error:&error],
                        @"https://www.google.com");
  XCTAssertNil(error);
}

- (void)testFlutterApiCreate {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFURLFlutterApiImpl *flutterApi = [[FWFURLFlutterApiImpl alloc]
      initWithBinaryMessenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))
              instanceManager:instanceManager];

  flutterApi.api = OCMClassMock([FWFNSUrlFlutterApi class]);

  NSURL *url = [[NSURL alloc] initWithString:@"https://www.google.com"];
  [flutterApi create:url
          completion:^(FlutterError *error){
          }];

  long identifier = [instanceManager identifierWithStrongReferenceForInstance:url];
  OCMVerify([flutterApi.api createWithIdentifier:@(identifier) completion:OCMOCK_ANY]);
}
@end
