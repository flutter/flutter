// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;

@import XCTest;
@import google_sign_in_ios;
@import google_sign_in_ios.Test;
@import GoogleSignIn;

// OCMock library doesn't generate a valid modulemap.
#import <OCMock/OCMock.h>

@interface FLTGoogleSignInPluginTest : XCTestCase

@property(strong, nonatomic) NSObject<FlutterBinaryMessenger> *mockBinaryMessenger;
@property(strong, nonatomic) NSObject<FlutterPluginRegistrar> *mockPluginRegistrar;
@property(strong, nonatomic) FLTGoogleSignInPlugin *plugin;
@property(strong, nonatomic) id mockSignIn;

@end

@implementation FLTGoogleSignInPluginTest

- (void)setUp {
  [super setUp];
  self.mockBinaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  self.mockPluginRegistrar = OCMProtocolMock(@protocol(FlutterPluginRegistrar));

  id mockSignIn = OCMClassMock([GIDSignIn class]);
  self.mockSignIn = mockSignIn;

  OCMStub(self.mockPluginRegistrar.messenger).andReturn(self.mockBinaryMessenger);
  self.plugin = [[FLTGoogleSignInPlugin alloc] initWithSignIn:mockSignIn];
  [FLTGoogleSignInPlugin registerWithRegistrar:self.mockPluginRegistrar];
}

- (void)testUnimplementedMethod {
  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"bogus"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(id result) {
                           XCTAssertEqualObjects(result, FlutterMethodNotImplemented);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSignOut {
  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signOut"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(id result) {
                           XCTAssertNil(result);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  OCMVerify([self.mockSignIn signOut]);
}

- (void)testDisconnect {
  [[self.mockSignIn stub] disconnectWithCallback:[OCMArg invokeBlockWithArgs:[NSNull null], nil]];
  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"disconnect"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSDictionary *result) {
                           XCTAssertEqualObjects(result, @{});
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testDisconnectIgnoresError {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                   userInfo:nil];
  [[self.mockSignIn stub] disconnectWithCallback:[OCMArg invokeBlockWithArgs:error, nil]];
  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"disconnect"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSDictionary *result) {
                           XCTAssertEqualObjects(result, @{});
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Init

- (void)testInitNoClientIdError {
  // Init plugin without GoogleService-Info.plist.
  self.plugin = [[FLTGoogleSignInPlugin alloc] initWithSignIn:self.mockSignIn
                                  withGoogleServiceProperties:nil];

  // init call does not provide a clientId.
  FlutterMethodCall *initMethodCall = [FlutterMethodCall methodCallWithMethodName:@"init"
                                                                        arguments:@{}];

  XCTestExpectation *initExpectation =
      [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:initMethodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"missing-config");
                           [initExpectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testInitGoogleServiceInfoPlist {
  FlutterMethodCall *initMethodCall =
      [FlutterMethodCall methodCallWithMethodName:@"init"
                                        arguments:@{@"hostedDomain" : @"example.com"}];

  XCTestExpectation *initExpectation =
      [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:initMethodCall
                         result:^(id result) {
                           XCTAssertNil(result);
                           [initExpectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Initialization values used in the next sign in request.
  FlutterMethodCall *signInMethodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                          arguments:nil];
  [self.plugin handleMethodCall:signInMethodCall
                         result:^(id r){
                         }];
  OCMVerify([self.mockSignIn
       signInWithConfiguration:[OCMArg checkWithBlock:^BOOL(GIDConfiguration *configuration) {
         // Set in example app GoogleService-Info.plist.
         return
             [configuration.hostedDomain isEqualToString:@"example.com"] &&
             [configuration.clientID
                 isEqualToString:
                     @"479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com"] &&
             [configuration.serverClientID isEqualToString:@"YOUR_SERVER_CLIENT_ID"];
       }]
      presentingViewController:[OCMArg isKindOfClass:[FlutterViewController class]]
                          hint:nil
              additionalScopes:OCMOCK_ANY
                      callback:OCMOCK_ANY]);
}

- (void)testInitDynamicClientIdNullDomain {
  // Init plugin without GoogleService-Info.plist.
  self.plugin = [[FLTGoogleSignInPlugin alloc] initWithSignIn:self.mockSignIn
                                  withGoogleServiceProperties:nil];

  FlutterMethodCall *initMethodCall = [FlutterMethodCall
      methodCallWithMethodName:@"init"
                     arguments:@{@"hostedDomain" : [NSNull null], @"clientId" : @"mockClientId"}];

  XCTestExpectation *initExpectation =
      [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:initMethodCall
                         result:^(id result) {
                           XCTAssertNil(result);
                           [initExpectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Initialization values used in the next sign in request.
  FlutterMethodCall *signInMethodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                          arguments:nil];
  [self.plugin handleMethodCall:signInMethodCall
                         result:^(id r){
                         }];
  OCMVerify([self.mockSignIn
       signInWithConfiguration:[OCMArg checkWithBlock:^BOOL(GIDConfiguration *configuration) {
         return configuration.hostedDomain == nil &&
                [configuration.clientID isEqualToString:@"mockClientId"];
       }]
      presentingViewController:[OCMArg isKindOfClass:[FlutterViewController class]]
                          hint:nil
              additionalScopes:OCMOCK_ANY
                      callback:OCMOCK_ANY]);
}

- (void)testInitDynamicServerClientIdNullDomain {
  FlutterMethodCall *initMethodCall =
      [FlutterMethodCall methodCallWithMethodName:@"init"
                                        arguments:@{
                                          @"hostedDomain" : [NSNull null],
                                          @"serverClientId" : @"mockServerClientId"
                                        }];

  XCTestExpectation *initExpectation =
      [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:initMethodCall
                         result:^(id result) {
                           XCTAssertNil(result);
                           [initExpectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Initialization values used in the next sign in request.
  FlutterMethodCall *signInMethodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                          arguments:nil];
  [self.plugin handleMethodCall:signInMethodCall
                         result:^(id r){
                         }];
  OCMVerify([self.mockSignIn
       signInWithConfiguration:[OCMArg checkWithBlock:^BOOL(GIDConfiguration *configuration) {
         return configuration.hostedDomain == nil &&
                [configuration.serverClientID isEqualToString:@"mockServerClientId"];
       }]
      presentingViewController:[OCMArg isKindOfClass:[FlutterViewController class]]
                          hint:nil
              additionalScopes:OCMOCK_ANY
                      callback:OCMOCK_ANY]);
}

#pragma mark - Is signed in

- (void)testIsNotSignedIn {
  OCMStub([self.mockSignIn hasPreviousSignIn]).andReturn(NO);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"isSignedIn"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSNumber *result) {
                           XCTAssertFalse(result.boolValue);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testIsSignedIn {
  OCMStub([self.mockSignIn hasPreviousSignIn]).andReturn(YES);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"isSignedIn"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSNumber *result) {
                           XCTAssertTrue(result.boolValue);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Sign in silently

- (void)testSignInSilently {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([mockUser userID]).andReturn(@"mockID");

  [[self.mockSignIn stub]
      restorePreviousSignInWithCallback:[OCMArg invokeBlockWithArgs:mockUser, [NSNull null], nil]];

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signInSilently"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSDictionary<NSString *, NSString *> *result) {
                           XCTAssertEqualObjects(result[@"displayName"], [NSNull null]);
                           XCTAssertEqualObjects(result[@"email"], [NSNull null]);
                           XCTAssertEqualObjects(result[@"id"], @"mockID");
                           XCTAssertEqualObjects(result[@"photoUrl"], [NSNull null]);
                           XCTAssertEqualObjects(result[@"serverAuthCode"], [NSNull null]);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSignInSilentlyWithError {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                   userInfo:nil];

  [[self.mockSignIn stub]
      restorePreviousSignInWithCallback:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signInSilently"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"sign_in_required");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Sign in

- (void)testSignIn {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  id mockUserProfile = OCMClassMock([GIDProfileData class]);
  OCMStub([mockUserProfile name]).andReturn(@"mockDisplay");
  OCMStub([mockUserProfile email]).andReturn(@"mock@example.com");
  OCMStub([mockUserProfile hasImage]).andReturn(YES);
  OCMStub([mockUserProfile imageURLWithDimension:1337])
      .andReturn([NSURL URLWithString:@"https://example.com/profile.png"]);

  OCMStub([mockUser profile]).andReturn(mockUserProfile);
  OCMStub([mockUser userID]).andReturn(@"mockID");
  OCMStub([mockUser serverAuthCode]).andReturn(@"mockAuthCode");

  [[self.mockSignIn expect]
       signInWithConfiguration:[OCMArg checkWithBlock:^BOOL(GIDConfiguration *configuration) {
         return [configuration.clientID
             isEqualToString:
                 @"479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com"];
       }]
      presentingViewController:[OCMArg isKindOfClass:[FlutterViewController class]]
                          hint:nil
              additionalScopes:@[]
                      callback:[OCMArg invokeBlockWithArgs:mockUser, [NSNull null], nil]];

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin
      handleMethodCall:methodCall
                result:^(NSDictionary<NSString *, NSString *> *result) {
                  XCTAssertEqualObjects(result[@"displayName"], @"mockDisplay");
                  XCTAssertEqualObjects(result[@"email"], @"mock@example.com");
                  XCTAssertEqualObjects(result[@"id"], @"mockID");
                  XCTAssertEqualObjects(result[@"photoUrl"], @"https://example.com/profile.png");
                  XCTAssertEqualObjects(result[@"serverAuthCode"], @"mockAuthCode");
                  [expectation fulfill];
                }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  OCMVerifyAll(self.mockSignIn);
}

- (void)testSignInWithInitializedScopes {
  FlutterMethodCall *initMethodCall =
      [FlutterMethodCall methodCallWithMethodName:@"init"
                                        arguments:@{@"scopes" : @[ @"initial1", @"initial2" ]}];

  XCTestExpectation *initExpectation =
      [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:initMethodCall
                         result:^(id result) {
                           XCTAssertNil(result);
                           [initExpectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([mockUser userID]).andReturn(@"mockID");

  [[self.mockSignIn expect]
       signInWithConfiguration:OCMOCK_ANY
      presentingViewController:OCMOCK_ANY
                          hint:nil
              additionalScopes:[OCMArg checkWithBlock:^BOOL(NSArray<NSString *> *scopes) {
                return [[NSSet setWithArray:scopes]
                    isEqualToSet:[NSSet setWithObjects:@"initial1", @"initial2", nil]];
              }]
                      callback:[OCMArg invokeBlockWithArgs:mockUser, [NSNull null], nil]];

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSDictionary<NSString *, NSString *> *result) {
                           XCTAssertEqualObjects(result[@"id"], @"mockID");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  OCMVerifyAll(self.mockSignIn);
}

- (void)testSignInAlreadyGranted {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([mockUser userID]).andReturn(@"mockID");

  [[self.mockSignIn stub]
       signInWithConfiguration:OCMOCK_ANY
      presentingViewController:OCMOCK_ANY
                          hint:nil
              additionalScopes:OCMOCK_ANY
                      callback:[OCMArg invokeBlockWithArgs:mockUser, [NSNull null], nil]];

  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeScopesAlreadyGranted
                                   userInfo:nil];
  [[self.mockSignIn stub] addScopes:OCMOCK_ANY
           presentingViewController:OCMOCK_ANY
                           callback:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSDictionary<NSString *, NSString *> *result) {
                           XCTAssertEqualObjects(result[@"id"], @"mockID");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSignInError {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeCanceled
                                   userInfo:nil];
  [[self.mockSignIn stub]
       signInWithConfiguration:OCMOCK_ANY
      presentingViewController:OCMOCK_ANY
                          hint:nil
              additionalScopes:OCMOCK_ANY
                      callback:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"sign_in_canceled");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSignInException {
  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"signIn"
                                                                    arguments:nil];
  OCMExpect([self.mockSignIn signInWithConfiguration:OCMOCK_ANY
                            presentingViewController:OCMOCK_ANY
                                                hint:OCMOCK_ANY
                                    additionalScopes:OCMOCK_ANY
                                            callback:OCMOCK_ANY])
      .andThrow([NSException exceptionWithName:@"MockName" reason:@"MockReason" userInfo:nil]);

  __block FlutterError *error;
  XCTAssertThrows([self.plugin handleMethodCall:methodCall
                                         result:^(FlutterError *result) {
                                           error = result;
                                         }]);

  XCTAssertEqualObjects(error.code, @"google_sign_in");
  XCTAssertEqualObjects(error.message, @"MockReason");
  XCTAssertEqualObjects(error.details, @"MockName");
}

#pragma mark - Get tokens

- (void)testGetTokens {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);

  id mockAuthentication = OCMClassMock([GIDAuthentication class]);
  OCMStub([mockAuthentication idToken]).andReturn(@"mockIdToken");
  OCMStub([mockAuthentication accessToken]).andReturn(@"mockAccessToken");
  [[mockAuthentication stub]
      doWithFreshTokens:[OCMArg invokeBlockWithArgs:mockAuthentication, [NSNull null], nil]];
  OCMStub([mockUser authentication]).andReturn(mockAuthentication);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"getTokens"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSDictionary<NSString *, NSString *> *result) {
                           XCTAssertEqualObjects(result[@"idToken"], @"mockIdToken");
                           XCTAssertEqualObjects(result[@"accessToken"], @"mockAccessToken");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetTokensNoAuthKeychainError {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);

  id mockAuthentication = OCMClassMock([GIDAuthentication class]);
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeHasNoAuthInKeychain
                                   userInfo:nil];
  [[mockAuthentication stub]
      doWithFreshTokens:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];
  OCMStub([mockUser authentication]).andReturn(mockAuthentication);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"getTokens"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"sign_in_required");
                           XCTAssertEqualObjects(result.message, kGIDSignInErrorDomain);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetTokensCancelledError {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);

  id mockAuthentication = OCMClassMock([GIDAuthentication class]);
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeCanceled
                                   userInfo:nil];
  [[mockAuthentication stub]
      doWithFreshTokens:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];
  OCMStub([mockUser authentication]).andReturn(mockAuthentication);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"getTokens"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"sign_in_canceled");
                           XCTAssertEqualObjects(result.message, kGIDSignInErrorDomain);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetTokensURLError {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);

  id mockAuthentication = OCMClassMock([GIDAuthentication class]);
  NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
  [[mockAuthentication stub]
      doWithFreshTokens:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];
  OCMStub([mockUser authentication]).andReturn(mockAuthentication);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"getTokens"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"network_error");
                           XCTAssertEqualObjects(result.message, NSURLErrorDomain);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetTokensUnknownError {
  id mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);

  id mockAuthentication = OCMClassMock([GIDAuthentication class]);
  NSError *error = [NSError errorWithDomain:@"BogusDomain" code:42 userInfo:nil];
  [[mockAuthentication stub]
      doWithFreshTokens:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];
  OCMStub([mockUser authentication]).andReturn(mockAuthentication);

  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"getTokens"
                                                                    arguments:nil];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"sign_in_failed");
                           XCTAssertEqualObjects(result.message, @"BogusDomain");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Request scopes

- (void)testRequestScopesResultErrorIfNotSignedIn {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeNoCurrentUser
                                   userInfo:nil];
  [[self.mockSignIn stub] addScopes:@[ @"mockScope1" ]
           presentingViewController:OCMOCK_ANY
                           callback:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                        arguments:@{@"scopes" : @[ @"mockScope1" ]}];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"sign_in_required");
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRequestScopesIfNoMissingScope {
  NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                       code:kGIDSignInErrorCodeScopesAlreadyGranted
                                   userInfo:nil];
  [[self.mockSignIn stub] addScopes:@[ @"mockScope1" ]
           presentingViewController:OCMOCK_ANY
                           callback:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                        arguments:@{@"scopes" : @[ @"mockScope1" ]}];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSNumber *result) {
                           XCTAssertTrue(result.boolValue);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRequestScopesWithUnknownError {
  NSError *error = [NSError errorWithDomain:@"BogusDomain" code:42 userInfo:nil];
  [[self.mockSignIn stub] addScopes:@[ @"mockScope1" ]
           presentingViewController:OCMOCK_ANY
                           callback:[OCMArg invokeBlockWithArgs:[NSNull null], error, nil]];

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                        arguments:@{@"scopes" : @[ @"mockScope1" ]}];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSNumber *result) {
                           XCTAssertFalse(result.boolValue);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRequestScopesException {
  FlutterMethodCall *methodCall = [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                                                    arguments:nil];
  OCMExpect([self.mockSignIn addScopes:@[] presentingViewController:OCMOCK_ANY callback:OCMOCK_ANY])
      .andThrow([NSException exceptionWithName:@"MockName" reason:@"MockReason" userInfo:nil]);

  [self.plugin handleMethodCall:methodCall
                         result:^(FlutterError *result) {
                           XCTAssertEqualObjects(result.code, @"request_scopes");
                           XCTAssertEqualObjects(result.message, @"MockReason");
                           XCTAssertEqualObjects(result.details, @"MockName");
                         }];
}

- (void)testRequestScopesReturnsFalseIfOnlySubsetGranted {
  GIDGoogleUser *mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);
  NSArray<NSString *> *requestedScopes = @[ @"mockScope1", @"mockScope2" ];

  // Only grant one of the two requested scopes.
  OCMStub(mockUser.grantedScopes).andReturn(@[ @"mockScope1" ]);

  [[self.mockSignIn stub] addScopes:requestedScopes
           presentingViewController:OCMOCK_ANY
                           callback:[OCMArg invokeBlockWithArgs:mockUser, [NSNull null], nil]];

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                        arguments:@{@"scopes" : requestedScopes}];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns false"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSNumber *result) {
                           XCTAssertFalse(result.boolValue);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRequestsInitializedScopes {
  FlutterMethodCall *initMethodCall =
      [FlutterMethodCall methodCallWithMethodName:@"init"
                                        arguments:@{@"scopes" : @[ @"initial1", @"initial2" ]}];

  XCTestExpectation *initExpectation =
      [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:initMethodCall
                         result:^(id result) {
                           XCTAssertNil(result);
                           [initExpectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];

  // Include one of the initially requested scopes.
  NSArray<NSString *> *addedScopes = @[ @"initial1", @"addScope1", @"addScope2" ];

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                        arguments:@{@"scopes" : addedScopes}];

  [self.plugin handleMethodCall:methodCall
                         result:^(id result){
                         }];

  // All four scopes are requested.
  [[self.mockSignIn verify]
                     addScopes:[OCMArg checkWithBlock:^BOOL(NSArray<NSString *> *scopes) {
                       return [[NSSet setWithArray:scopes]
                           isEqualToSet:[NSSet setWithObjects:@"initial1", @"initial2",
                                                              @"addScope1", @"addScope2", nil]];
                     }]
      presentingViewController:OCMOCK_ANY
                      callback:OCMOCK_ANY];
}

- (void)testRequestScopesReturnsTrueIfGranted {
  GIDGoogleUser *mockUser = OCMClassMock([GIDGoogleUser class]);
  OCMStub([self.mockSignIn currentUser]).andReturn(mockUser);
  NSArray<NSString *> *requestedScopes = @[ @"mockScope1", @"mockScope2" ];

  // Grant both of the requested scopes.
  OCMStub(mockUser.grantedScopes).andReturn(requestedScopes);

  [[self.mockSignIn stub] addScopes:requestedScopes
           presentingViewController:OCMOCK_ANY
                           callback:[OCMArg invokeBlockWithArgs:mockUser, [NSNull null], nil]];

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"requestScopes"
                                        arguments:@{@"scopes" : requestedScopes}];

  XCTestExpectation *expectation = [self expectationWithDescription:@"expect result returns true"];
  [self.plugin handleMethodCall:methodCall
                         result:^(NSNumber *result) {
                           XCTAssertTrue(result.boolValue);
                           [expectation fulfill];
                         }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
