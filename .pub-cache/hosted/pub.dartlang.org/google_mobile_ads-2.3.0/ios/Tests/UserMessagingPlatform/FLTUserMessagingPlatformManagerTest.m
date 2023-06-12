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

#import "../../Classes/UserMessagingPlatform/FLTUserMessagingPlatformManager.h"
#import "../../Classes/UserMessagingPlatform/FLTUserMessagingPlatformReaderWriter.h"

@interface FLTUserMessagingPlatformManagerTest : XCTestCase
@end

@interface FLTUserMessagingPlatformManager ()
@property UIViewController *rootController;
@end

@implementation FLTUserMessagingPlatformManagerTest {
  FLTUserMessagingPlatformManager *umpManager;
  NSObject<FlutterBinaryMessenger> *binaryMessenger;
  UMPConsentInformation *mockUmpConsentInformation;
  FlutterResult flutterResult;
  bool resultInvoked;
  id _Nullable returnedResult;
}

- (void)setUp {
  binaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  umpManager = [[FLTUserMessagingPlatformManager alloc]
      initWithBinaryMessenger:binaryMessenger];
  id umpInfoClassMock = OCMClassMock([UMPConsentInformation class]);
  OCMStub(ClassMethod([umpInfoClassMock sharedInstance]))
      .andReturn(umpInfoClassMock);
  mockUmpConsentInformation = umpInfoClassMock;

  resultInvoked = false;
  returnedResult = nil;
  flutterResult = ^(id _Nullable result) {
    self->resultInvoked = true;
    self->returnedResult = result;
  };
}

- (void)testReset {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"ConsentInformation#reset"
                                        arguments:@{}];

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, nil);
  OCMVerify([mockUmpConsentInformation reset]);
}

- (void)testGetConsentStatus {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"ConsentInformation#getConsentStatus"
                     arguments:@{}];

  OCMStub([mockUmpConsentInformation consentStatus])
      .andReturn(UMPConsentStatusRequired);

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  NSNumber *expected =
      [[NSNumber alloc] initWithInteger:UMPConsentStatusRequired];
  XCTAssertEqual(returnedResult, expected);
  OCMVerify([mockUmpConsentInformation consentStatus]);
}

- (void)testRequestConsentInfoUpdate_success {
  UMPRequestParameters *params = OCMClassMock([UMPRequestParameters class]);

  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"ConsentInformation#requestConsentInfoUpdate"
                     arguments:@{@"params" : params}];

  OCMStub([mockUmpConsentInformation
              requestConsentInfoUpdateWithParameters:[OCMArg isEqual:params]
                                   completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil);
      });

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([mockUmpConsentInformation
      requestConsentInfoUpdateWithParameters:[OCMArg any]
                           completionHandler:[OCMArg any]]);
}

- (void)testRequestConsentInfoUpdate_error {
  UMPRequestParameters *params = OCMClassMock([UMPRequestParameters class]);
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"ConsentInformation#requestConsentInfoUpdate"
                     arguments:@{@"params" : params}];

  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"description"};
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];
  OCMStub([mockUmpConsentInformation
              requestConsentInfoUpdateWithParameters:[OCMArg isEqual:params]
                                   completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(error);
      });

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);

  OCMVerify([mockUmpConsentInformation
      requestConsentInfoUpdateWithParameters:[OCMArg any]
                           completionHandler:[OCMArg any]]);
  FlutterError *resultError = (FlutterError *)returnedResult;
  XCTAssertEqualObjects(resultError.code, @"1");
  XCTAssertEqualObjects(resultError.details, @"domain");
  XCTAssertEqualObjects(resultError.message, @"description");
}

- (void)testLoadConsentForm_successAndDispose {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"UserMessagingPlatform#loadConsentForm"
                     arguments:@{}];

  id mockUmpConsentForm = OCMClassMock([UMPConsentForm class]);
  OCMStub([mockUmpConsentForm loadWithCompletionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(UMPConsentForm *form, NSError *loadError);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(mockUmpConsentForm, nil);
      });

  FLTUserMessagingPlatformManager *partialMock = OCMPartialMock(umpManager);
  FLTUserMessagingPlatformReaderWriter *mockReaderWriter =
      OCMClassMock([FLTUserMessagingPlatformReaderWriter class]);
  OCMStub([partialMock readerWriter]).andReturn(mockReaderWriter);

  [partialMock handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, mockUmpConsentForm);
  OCMVerify([mockUmpConsentForm loadWithCompletionHandler:[OCMArg any]]);
  OCMVerify([mockReaderWriter trackConsentForm:mockUmpConsentForm]);
}

- (void)testLoadConsentForm_error {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"UserMessagingPlatform#loadConsentForm"
                     arguments:@{}];

  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"description"};
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];
  id mockUmpConsentForm = OCMClassMock([UMPConsentForm class]);
  OCMStub([mockUmpConsentForm loadWithCompletionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(UMPConsentForm *form, NSError *loadError);
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(mockUmpConsentForm, error);
      });

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  OCMVerify([mockUmpConsentForm loadWithCompletionHandler:[OCMArg any]]);
  FlutterError *resultError = (FlutterError *)returnedResult;
  XCTAssertEqualObjects(resultError.code, @"1");
  XCTAssertEqualObjects(resultError.details, @"domain");
  XCTAssertEqualObjects(resultError.message, @"description");
}

- (void)testIsConsentFormAvailable_available {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"ConsentInformation#isConsentFormAvailable"
                     arguments:@{}];

  OCMStub([mockUmpConsentInformation formStatus])
      .andReturn(UMPFormStatusAvailable);

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, [[NSNumber alloc] initWithBool:YES]);
}

- (void)testIsConsentFormAvailable_notAvailable {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"ConsentInformation#isConsentFormAvailable"
                     arguments:@{}];

  OCMStub([mockUmpConsentInformation formStatus])
      .andReturn(UMPFormStatusUnavailable);

  [umpManager handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, [[NSNumber alloc] initWithBool:NO]);
}

- (void)testShowConsentForm_success {
  UIViewController *mockUIViewController = OCMClassMock(UIViewController.class);
  FLTUserMessagingPlatformManager *partialMock = OCMPartialMock(umpManager);
  OCMStub([partialMock rootController]).andReturn(mockUIViewController);

  UMPConsentForm *mockForm = OCMClassMock([UMPConsentForm class]);
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"ConsentForm#show"
                                        arguments:@{@"consentForm" : mockForm}];

  OCMStub([mockForm presentFromViewController:[OCMArg any]
                            completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil);
      });
  ;

  [partialMock handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([mockForm presentFromViewController:[OCMArg any]
                              completionHandler:[OCMArg any]]);
}

- (void)testShowConsentForm_error {
  UIViewController *mockUIViewController = OCMClassMock(UIViewController.class);
  FLTUserMessagingPlatformManager *partialMock = OCMPartialMock(umpManager);
  OCMStub([partialMock rootController]).andReturn(mockUIViewController);

  UMPConsentForm *mockForm = OCMClassMock([UMPConsentForm class]);
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"ConsentForm#show"
                                        arguments:@{@"consentForm" : mockForm}];

  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"description"};
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];
  OCMStub([mockForm presentFromViewController:[OCMArg any]
                            completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(error);
      });
  ;

  [partialMock handleMethodCall:methodCall result:flutterResult];

  XCTAssertTrue(resultInvoked);
  OCMVerify([mockForm presentFromViewController:[OCMArg any]
                              completionHandler:[OCMArg any]]);
  FlutterError *resultError = (FlutterError *)returnedResult;
  XCTAssertEqualObjects(resultError.code, @"1");
  XCTAssertEqualObjects(resultError.details, @"domain");
  XCTAssertEqualObjects(resultError.message, @"description");
}

@end
