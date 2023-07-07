// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFHTTPCookieStoreHostApiTests : XCTestCase
@end

@implementation FWFHTTPCookieStoreHostApiTests
- (void)testCreateFromWebsiteDataStoreWithIdentifier API_AVAILABLE(ios(11.0)) {
  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  FWFHTTPCookieStoreHostApiImpl *hostAPI =
      [[FWFHTTPCookieStoreHostApiImpl alloc] initWithInstanceManager:instanceManager];

  WKWebsiteDataStore *mockDataStore = OCMClassMock([WKWebsiteDataStore class]);
  OCMStub([mockDataStore httpCookieStore]).andReturn(OCMClassMock([WKHTTPCookieStore class]));
  [instanceManager addDartCreatedInstance:mockDataStore withIdentifier:0];

  FlutterError *error;
  [hostAPI createFromWebsiteDataStoreWithIdentifier:@1 dataStoreIdentifier:@0 error:&error];
  WKHTTPCookieStore *cookieStore = (WKHTTPCookieStore *)[instanceManager instanceForIdentifier:1];
  XCTAssertTrue([cookieStore isKindOfClass:[WKHTTPCookieStore class]]);
  XCTAssertNil(error);
}

- (void)testSetCookie API_AVAILABLE(ios(11.0)) {
  WKHTTPCookieStore *mockHttpCookieStore = OCMClassMock([WKHTTPCookieStore class]);

  FWFInstanceManager *instanceManager = [[FWFInstanceManager alloc] init];
  [instanceManager addDartCreatedInstance:mockHttpCookieStore withIdentifier:0];

  FWFHTTPCookieStoreHostApiImpl *hostAPI =
      [[FWFHTTPCookieStoreHostApiImpl alloc] initWithInstanceManager:instanceManager];

  FWFNSHttpCookieData *cookieData = [FWFNSHttpCookieData
      makeWithPropertyKeys:@[ [FWFNSHttpCookiePropertyKeyEnumData
                               makeWithValue:FWFNSHttpCookiePropertyKeyEnumName] ]
            propertyValues:@[ @"hello" ]];
  FlutterError *__block blockError;
  [hostAPI setCookieForStoreWithIdentifier:@0
                                    cookie:cookieData
                                completion:^(FlutterError *error) {
                                  blockError = error;
                                }];
  OCMVerify([mockHttpCookieStore
              setCookie:[NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName : @"hello"}]
      completionHandler:OCMOCK_ANY]);
  XCTAssertNil(blockError);
}
@end
