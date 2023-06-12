// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <OCMock/OCMock.h>
#include <UserMessagingPlatform/UserMessagingPlatform.h>
#import <XCTest/XCTest.h>

#import "../../Classes/UserMessagingPlatform/FLTUserMessagingPlatformReaderWriter.h"

@interface FLTUserMessagingPlatformReaderWriterTest : XCTestCase
@end

@implementation FLTUserMessagingPlatformReaderWriterTest {
  FlutterStandardMessageCodec *messageCodec;
  FLTUserMessagingPlatformReaderWriter *readerWriter;
}

- (void)setUp {
  readerWriter = [[FLTUserMessagingPlatformReaderWriter alloc] init];
  messageCodec =
      [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
}

- (void)testRequestParams_default {
  UMPRequestParameters *requestParameters = [[UMPRequestParameters alloc] init];
  NSData *encodedMessage = [messageCodec encode:requestParameters];

  UMPRequestParameters *decoded = [messageCodec decode:encodedMessage];
  XCTAssertEqual(decoded.tagForUnderAgeOfConsent,
                 requestParameters.tagForUnderAgeOfConsent);
  XCTAssertEqual(decoded.debugSettings, requestParameters.debugSettings);
}

- (void)testRequestParams_withDebugSettingsTfuac {
  UMPRequestParameters *requestParameters = [[UMPRequestParameters alloc] init];
  requestParameters.tagForUnderAgeOfConsent = YES;
  requestParameters.debugSettings = [[UMPDebugSettings alloc] init];
  NSData *encodedMessage = [messageCodec encode:requestParameters];

  UMPRequestParameters *decoded = [messageCodec decode:encodedMessage];
  XCTAssertEqual(decoded.tagForUnderAgeOfConsent,
                 requestParameters.tagForUnderAgeOfConsent);
  XCTAssertEqual(decoded.debugSettings.geography,
                 requestParameters.debugSettings.geography);
  XCTAssertEqual(decoded.debugSettings.testDeviceIdentifiers,
                 requestParameters.debugSettings.testDeviceIdentifiers);
}

- (void)testConsentDebugSettings_default {
  UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
  NSData *encodedMessage = [messageCodec encode:debugSettings];

  UMPDebugSettings *decoded = [messageCodec decode:encodedMessage];
  XCTAssertEqual(decoded.geography, debugSettings.geography);
  XCTAssertEqual(decoded.testDeviceIdentifiers,
                 debugSettings.testDeviceIdentifiers);
}

- (void)testConsentDebugSettings_geographyTestDeviceIdentifiers {
  UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
  debugSettings.geography = UMPDebugGeographyNotEEA;
  debugSettings.testDeviceIdentifiers = @[ @"id-1", @"id-2" ];
  NSData *encodedMessage = [messageCodec encode:debugSettings];

  UMPDebugSettings *decoded = [messageCodec decode:encodedMessage];
  XCTAssertEqual(decoded.geography, debugSettings.geography);
  XCTAssertEqualObjects(decoded.testDeviceIdentifiers,
                        debugSettings.testDeviceIdentifiers);
}

- (void)testConsentFormTrackAndDispose {
  UMPConsentForm *form1 = OCMClassMock([UMPConsentForm class]);
  UMPConsentForm *form2 = OCMClassMock([UMPConsentForm class]);
  UMPConsentForm *form3 = OCMClassMock([UMPConsentForm class]);

  [readerWriter trackConsentForm:form1];
  [readerWriter trackConsentForm:form2];
  [readerWriter trackConsentForm:form3];

  NSData *encodedMessage1 = [messageCodec encode:form1];
  NSData *encodedMessage2 = [messageCodec encode:form2];
  NSData *encodedMessage3 = [messageCodec encode:form3];

  UMPConsentForm *decoded1 = [messageCodec decode:encodedMessage1];
  UMPConsentForm *decoded2 = [messageCodec decode:encodedMessage2];
  UMPConsentForm *decoded3 = [messageCodec decode:encodedMessage3];

  XCTAssertEqual(form1, decoded1);
  XCTAssertEqual(form2, decoded2);
  XCTAssertEqual(form3, decoded3);

  [readerWriter disposeConsentForm:form1];
  [readerWriter disposeConsentForm:form2];
  [readerWriter disposeConsentForm:form3];

  decoded1 = [messageCodec decode:encodedMessage1];
  decoded2 = [messageCodec decode:encodedMessage2];
  decoded3 = [messageCodec decode:encodedMessage3];
  XCTAssertNil(decoded1);
  XCTAssertNil(decoded2);
  XCTAssertNil(decoded3);
}

@end
