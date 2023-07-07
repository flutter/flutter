// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import XCTest;
@import webview_flutter_wkwebview;

#import <OCMock/OCMock.h>

@interface FWFDataConvertersTests : XCTestCase
@end

@implementation FWFDataConvertersTests
- (void)testFWFNSURLRequestFromRequestData {
  NSURLRequest *request = FWFNativeNSURLRequestFromRequestData([FWFNSUrlRequestData
              makeWithUrl:@"https://flutter.dev"
               httpMethod:@"post"
                 httpBody:[FlutterStandardTypedData typedDataWithBytes:[NSData data]]
      allHttpHeaderFields:@{@"a" : @"header"}]);

  XCTAssertEqualObjects(request.URL, [NSURL URLWithString:@"https://flutter.dev"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"POST");
  XCTAssertEqualObjects(request.HTTPBody, [NSData data]);
  XCTAssertEqualObjects(request.allHTTPHeaderFields, @{@"a" : @"header"});
}

- (void)testFWFNSURLRequestFromRequestDataDoesNotOverrideDefaultValuesWithNull {
  NSURLRequest *request =
      FWFNativeNSURLRequestFromRequestData([FWFNSUrlRequestData makeWithUrl:@"https://flutter.dev"
                                                                 httpMethod:nil
                                                                   httpBody:nil
                                                        allHttpHeaderFields:@{}]);

  XCTAssertEqualObjects(request.HTTPMethod, @"GET");
}

- (void)testFWFNSHTTPCookieFromCookieData {
  NSHTTPCookie *cookie = FWFNativeNSHTTPCookieFromCookieData([FWFNSHttpCookieData
      makeWithPropertyKeys:@[ [FWFNSHttpCookiePropertyKeyEnumData
                               makeWithValue:FWFNSHttpCookiePropertyKeyEnumName] ]
            propertyValues:@[ @"cookieName" ]]);
  XCTAssertEqualObjects(cookie,
                        [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName : @"cookieName"}]);
}

- (void)testFWFWKUserScriptFromScriptData {
  WKUserScript *userScript = FWFNativeWKUserScriptFromScriptData([FWFWKUserScriptData
       makeWithSource:@"mySource"
        injectionTime:[FWFWKUserScriptInjectionTimeEnumData
                          makeWithValue:FWFWKUserScriptInjectionTimeEnumAtDocumentStart]
      isMainFrameOnly:@NO]);

  XCTAssertEqualObjects(userScript.source, @"mySource");
  XCTAssertEqual(userScript.injectionTime, WKUserScriptInjectionTimeAtDocumentStart);
  XCTAssertEqual(userScript.isForMainFrameOnly, NO);
}

- (void)testFWFWKNavigationActionDataFromNavigationAction {
  WKNavigationAction *mockNavigationAction = OCMClassMock([WKNavigationAction class]);

  OCMStub([mockNavigationAction navigationType]).andReturn(WKNavigationTypeReload);

  NSURLRequest *request =
      [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.flutter.dev/"]];
  OCMStub([mockNavigationAction request]).andReturn(request);

  WKFrameInfo *mockFrameInfo = OCMClassMock([WKFrameInfo class]);
  OCMStub([mockFrameInfo isMainFrame]).andReturn(YES);
  OCMStub([mockNavigationAction targetFrame]).andReturn(mockFrameInfo);

  FWFWKNavigationActionData *data =
      FWFWKNavigationActionDataFromNativeWKNavigationAction(mockNavigationAction);
  XCTAssertNotNil(data);
  XCTAssertEqual(data.navigationType, FWFWKNavigationTypeReload);
}

- (void)testFWFNSUrlRequestDataFromNSURLRequest {
  NSMutableURLRequest *request =
      [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.flutter.dev/"]];
  request.HTTPMethod = @"POST";
  request.HTTPBody = [@"aString" dataUsingEncoding:NSUTF8StringEncoding];
  request.allHTTPHeaderFields = @{@"a" : @"field"};

  FWFNSUrlRequestData *data = FWFNSUrlRequestDataFromNativeNSURLRequest(request);
  XCTAssertEqualObjects(data.url, @"https://www.flutter.dev/");
  XCTAssertEqualObjects(data.httpMethod, @"POST");
  XCTAssertEqualObjects(data.httpBody.data, [@"aString" dataUsingEncoding:NSUTF8StringEncoding]);
  XCTAssertEqualObjects(data.allHttpHeaderFields, @{@"a" : @"field"});
}

- (void)testFWFWKFrameInfoDataFromWKFrameInfo {
  WKFrameInfo *mockFrameInfo = OCMClassMock([WKFrameInfo class]);
  OCMStub([mockFrameInfo isMainFrame]).andReturn(YES);

  FWFWKFrameInfoData *targetFrameData = FWFWKFrameInfoDataFromNativeWKFrameInfo(mockFrameInfo);
  XCTAssertEqualObjects(targetFrameData.isMainFrame, @YES);
}

- (void)testFWFNSErrorDataFromNSError {
  NSError *error = [NSError errorWithDomain:@"domain"
                                       code:23
                                   userInfo:@{NSLocalizedDescriptionKey : @"description"}];

  FWFNSErrorData *data = FWFNSErrorDataFromNativeNSError(error);
  XCTAssertEqualObjects(data.code, @23);
  XCTAssertEqualObjects(data.domain, @"domain");
  XCTAssertEqualObjects(data.localizedDescription, @"description");
}

- (void)testFWFWKScriptMessageDataFromWKScriptMessage {
  WKScriptMessage *mockScriptMessage = OCMClassMock([WKScriptMessage class]);
  OCMStub([mockScriptMessage name]).andReturn(@"name");
  OCMStub([mockScriptMessage body]).andReturn(@"message");

  FWFWKScriptMessageData *data = FWFWKScriptMessageDataFromNativeWKScriptMessage(mockScriptMessage);
  XCTAssertEqualObjects(data.name, @"name");
  XCTAssertEqualObjects(data.body, @"message");
}

- (void)testFWFWKSecurityOriginDataFromWKSecurityOrigin {
  WKSecurityOrigin *mockSecurityOrigin = OCMClassMock([WKSecurityOrigin class]);
  OCMStub([mockSecurityOrigin host]).andReturn(@"host");
  OCMStub([mockSecurityOrigin port]).andReturn(2);
  OCMStub([mockSecurityOrigin protocol]).andReturn(@"protocol");

  FWFWKSecurityOriginData *data =
      FWFWKSecurityOriginDataFromNativeWKSecurityOrigin(mockSecurityOrigin);
  XCTAssertEqualObjects(data.host, @"host");
  XCTAssertEqualObjects(data.port, @(2));
  XCTAssertEqualObjects(data.protocol, @"protocol");
}

- (void)testFWFWKPermissionDecisionFromData API_AVAILABLE(ios(15.0)) {
  XCTAssertEqual(FWFNativeWKPermissionDecisionFromData(
                     [FWFWKPermissionDecisionData makeWithValue:FWFWKPermissionDecisionDeny]),
                 WKPermissionDecisionDeny);
  XCTAssertEqual(FWFNativeWKPermissionDecisionFromData(
                     [FWFWKPermissionDecisionData makeWithValue:FWFWKPermissionDecisionGrant]),
                 WKPermissionDecisionGrant);
  XCTAssertEqual(FWFNativeWKPermissionDecisionFromData(
                     [FWFWKPermissionDecisionData makeWithValue:FWFWKPermissionDecisionPrompt]),
                 WKPermissionDecisionPrompt);
}

- (void)testFWFWKMediaCaptureTypeDataFromWKMediaCaptureType API_AVAILABLE(ios(15.0)) {
  XCTAssertEqual(
      FWFWKMediaCaptureTypeDataFromNativeWKMediaCaptureType(WKMediaCaptureTypeCamera).value,
      FWFWKMediaCaptureTypeCamera);
  XCTAssertEqual(
      FWFWKMediaCaptureTypeDataFromNativeWKMediaCaptureType(WKMediaCaptureTypeMicrophone).value,
      FWFWKMediaCaptureTypeMicrophone);
  XCTAssertEqual(
      FWFWKMediaCaptureTypeDataFromNativeWKMediaCaptureType(WKMediaCaptureTypeCameraAndMicrophone)
          .value,
      FWFWKMediaCaptureTypeCameraAndMicrophone);
}

- (void)testNSKeyValueChangeKeyConversionReturnsUnknownIfUnrecognized {
  XCTAssertEqual(
      FWFNSKeyValueChangeKeyEnumDataFromNativeNSKeyValueChangeKey(@"SomeUnknownValue").value,
      FWFNSKeyValueChangeKeyEnumUnknown);
}

- (void)testWKNavigationTypeConversionReturnsUnknownIfUnrecognized {
  XCTAssertEqual(FWFWKNavigationTypeFromNativeWKNavigationType(-15), FWFWKNavigationTypeUnknown);
}
@end
