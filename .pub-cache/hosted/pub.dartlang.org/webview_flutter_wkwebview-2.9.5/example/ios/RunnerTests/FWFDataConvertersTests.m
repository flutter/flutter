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
  NSURLRequest *request = FWFNSURLRequestFromRequestData([FWFNSUrlRequestData
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
      FWFNSURLRequestFromRequestData([FWFNSUrlRequestData makeWithUrl:@"https://flutter.dev"
                                                           httpMethod:nil
                                                             httpBody:nil
                                                  allHttpHeaderFields:@{}]);

  XCTAssertEqualObjects(request.HTTPMethod, @"GET");
}

- (void)testFWFNSHTTPCookieFromCookieData {
  NSHTTPCookie *cookie = FWFNSHTTPCookieFromCookieData([FWFNSHttpCookieData
      makeWithPropertyKeys:@[ [FWFNSHttpCookiePropertyKeyEnumData
                               makeWithValue:FWFNSHttpCookiePropertyKeyEnumName] ]
            propertyValues:@[ @"cookieName" ]]);
  XCTAssertEqualObjects(cookie,
                        [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieName : @"cookieName"}]);
}

- (void)testFWFWKUserScriptFromScriptData {
  WKUserScript *userScript = FWFWKUserScriptFromScriptData([FWFWKUserScriptData
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

  NSURLRequest *request =
      [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.flutter.dev/"]];
  OCMStub([mockNavigationAction request]).andReturn(request);

  WKFrameInfo *mockFrameInfo = OCMClassMock([WKFrameInfo class]);
  OCMStub([mockFrameInfo isMainFrame]).andReturn(YES);
  OCMStub([mockNavigationAction targetFrame]).andReturn(mockFrameInfo);

  FWFWKNavigationActionData *data =
      FWFWKNavigationActionDataFromNavigationAction(mockNavigationAction);
  XCTAssertNotNil(data);
}

- (void)testFWFNSUrlRequestDataFromNSURLRequest {
  NSMutableURLRequest *request =
      [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.flutter.dev/"]];
  request.HTTPMethod = @"POST";
  request.HTTPBody = [@"aString" dataUsingEncoding:NSUTF8StringEncoding];
  request.allHTTPHeaderFields = @{@"a" : @"field"};

  FWFNSUrlRequestData *data = FWFNSUrlRequestDataFromNSURLRequest(request);
  XCTAssertEqualObjects(data.url, @"https://www.flutter.dev/");
  XCTAssertEqualObjects(data.httpMethod, @"POST");
  XCTAssertEqualObjects(data.httpBody.data, [@"aString" dataUsingEncoding:NSUTF8StringEncoding]);
  XCTAssertEqualObjects(data.allHttpHeaderFields, @{@"a" : @"field"});
}

- (void)testFWFWKFrameInfoDataFromWKFrameInfo {
  WKFrameInfo *mockFrameInfo = OCMClassMock([WKFrameInfo class]);
  OCMStub([mockFrameInfo isMainFrame]).andReturn(YES);

  FWFWKFrameInfoData *targetFrameData = FWFWKFrameInfoDataFromWKFrameInfo(mockFrameInfo);
  XCTAssertEqualObjects(targetFrameData.isMainFrame, @YES);
}

- (void)testFWFNSErrorDataFromNSError {
  NSError *error = [NSError errorWithDomain:@"domain"
                                       code:23
                                   userInfo:@{NSLocalizedDescriptionKey : @"description"}];

  FWFNSErrorData *data = FWFNSErrorDataFromNSError(error);
  XCTAssertEqualObjects(data.code, @23);
  XCTAssertEqualObjects(data.domain, @"domain");
  XCTAssertEqualObjects(data.localizedDescription, @"description");
}

- (void)testFWFWKScriptMessageDataFromWKScriptMessage {
  WKScriptMessage *mockScriptMessage = OCMClassMock([WKScriptMessage class]);
  OCMStub([mockScriptMessage name]).andReturn(@"name");
  OCMStub([mockScriptMessage body]).andReturn(@"message");

  FWFWKScriptMessageData *data = FWFWKScriptMessageDataFromWKScriptMessage(mockScriptMessage);
  XCTAssertEqualObjects(data.name, @"name");
  XCTAssertEqualObjects(data.body, @"message");
}
@end
