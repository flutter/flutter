// Copyright 2021 Google LLC
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
#import <XCTest/XCTest.h>

#import "../Classes/FLTAdInstanceManager_Internal.h"
#import "../Classes/FLTGoogleMobileAdsPlugin.h"
#import "../Classes/FLTGoogleMobileAdsReaderWriter_Internal.h"
#import "../Classes/FLTMobileAds_Internal.h"

@interface FLTGoogleMobileAdsPluginMethodCallsTest : XCTestCase
@end

@interface FLTGoogleMobileAdsPlugin ()
@property UIViewController *rootController;
@end

@implementation FLTGoogleMobileAdsPluginMethodCallsTest {
  FLTGoogleMobileAdsPlugin *_fltGoogleMobileAdsPlugin;
  FLTAdInstanceManager *_mockAdInstanceManager;
}

- (void)setUp {
  id<FlutterBinaryMessenger> messenger =
      OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  FLTAdInstanceManager *manager =
      [[FLTAdInstanceManager alloc] initWithBinaryMessenger:messenger];
  _mockAdInstanceManager = OCMPartialMock(manager);
  _fltGoogleMobileAdsPlugin = [[FLTGoogleMobileAdsPlugin alloc] init];
  [_fltGoogleMobileAdsPlugin setValue:_mockAdInstanceManager
                               forKey:@"_manager"];
}

- (void)testDisposeAd {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"disposeAd"
                                        arguments:@{@"adId" : @1}];
  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([_mockAdInstanceManager dispose:@1]);
}

- (void)testLoadRewardedAd {
  FLTAdRequest *request = [[FLTAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"loadRewardedAd"
                                        arguments:@{
                                          @"adId" : @2,
                                          @"adUnitId" : @"testId",
                                          @"request" : request,
                                        }];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  BOOL (^verificationBlock)(FLTRewardedAd *) = ^BOOL(FLTRewardedAd *ad) {
    FLTAdRequest *adRequest = [ad valueForKey:@"_adRequest"];
    NSString *adUnit = [ad valueForKey:@"_adUnitId"];
    XCTAssertEqualObjects(adRequest, request);
    XCTAssertEqualObjects(adUnit, @"testId");
    return YES;
  };
  OCMVerify([_mockAdInstanceManager
      loadAd:[OCMArg checkWithBlock:verificationBlock]]);
}

- (void)testInternalInit {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"_init" arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([_mockAdInstanceManager disposeAllAds]);
}

- (void)testMobileAdsInitialize {
  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);
  GADInitializationStatus *mockInitStatus =
      OCMClassMock([GADInitializationStatus class]);
  OCMStub([mockInitStatus adapterStatusesByClassName]).andReturn(@{});
  OCMStub([gadMobileAdsClassMock startWithCompletionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        // Invoke the init handler twice.
        GADInitializationCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:2];
        completionHandler(mockInitStatus);
        completionHandler(mockInitStatus);
      });

  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#initialize"
                                        arguments:@{}];
  __block int resultInvokedCount = 0;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvokedCount += 1;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];
  XCTAssertEqual(resultInvokedCount, 1);
  XCTAssertEqual(
      [((FLTInitializationStatus *)returnedResult) adapterStatuses].count, 0);
}

- (void)testSetSameAppKeyEnabledYes {
  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);
  GADRequestConfiguration *gadRequestConfigurationMock =
      OCMClassMock([GADRequestConfiguration class]);
  OCMStub([gadMobileAdsClassMock requestConfiguration])
      .andReturn(gadRequestConfigurationMock);

  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#setSameAppKeyEnabled"
                     arguments:@{@"isEnabled" : @(YES)}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([gadRequestConfigurationMock
      setSameAppKeyEnabled:[OCMArg isEqual:@(YES)]]);
}

- (void)testSetSameAppKeyEnabledNo {
  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);
  GADRequestConfiguration *gadRequestConfigurationMock =
      OCMClassMock([GADRequestConfiguration class]);
  OCMStub([gadMobileAdsClassMock requestConfiguration])
      .andReturn(gadRequestConfigurationMock);

  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#setSameAppKeyEnabled"
                     arguments:@{@"isEnabled" : @0}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([gadRequestConfigurationMock setSameAppKeyEnabled:NO]);

  FlutterMethodCall *methodCallWithBool = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#setSameAppKeyEnabled"
                     arguments:@{@"isEnabled" : @NO}];

  __block bool resultInvokedWithBool = false;
  __block id _Nullable returnedResultWithBool;
  FlutterResult resultWithBool = ^(id _Nullable result) {
    resultInvokedWithBool = true;
    returnedResultWithBool = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCallWithBool
                                       result:resultWithBool];

  XCTAssertTrue(resultInvokedWithBool);
  XCTAssertNil(returnedResultWithBool);
  OCMVerify([gadRequestConfigurationMock setSameAppKeyEnabled:NO]);
}

- (void)testSetAppMuted {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#setAppMuted"
                                        arguments:@{@"muted" : @(YES)}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  XCTAssertTrue(GADMobileAds.sharedInstance.applicationMuted);

  methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#setAppMuted"
                                        arguments:@{@"muted" : @(NO)}];

  resultInvoked = false;
  result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  XCTAssertFalse(GADMobileAds.sharedInstance.applicationMuted);
}

- (void)testSetAppVolume {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#setAppVolume"
                                        arguments:@{@"volume" : @1.0f}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  XCTAssertEqual(GADMobileAds.sharedInstance.applicationVolume, 1.0f);
}

- (void)testDisableSDKCrashReporting {
  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#disableSDKCrashReporting"
                     arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([gadMobileAdsClassMock disableSDKCrashReporting]);
}

- (void)testDisableMediationInitialization {
  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);

  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#disableMediationInitialization"
                     arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertNil(returnedResult);
  OCMVerify([gadMobileAdsClassMock disableMediationInitialization]);
}

- (void)testGetVersionString {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#getVersionString"
                                        arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, [GADMobileAds.sharedInstance sdkVersion]);
}

- (void)testOpenDebugMenu {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#openDebugMenu"
                     arguments:@{@"adUnitId" : @"test-ad-unit"}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  FLTGoogleMobileAdsPlugin *mockPlugin =
      OCMPartialMock(_fltGoogleMobileAdsPlugin);
  UIViewController *mockUIViewController = OCMClassMock(UIViewController.class);
  OCMStub([mockPlugin rootController]).andReturn(mockUIViewController);

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  OCMVerify([mockUIViewController
      presentViewController:[OCMArg isKindOfClass:[GADDebugOptionsViewController
                                                      class]]
                   animated:[OCMArg any]
                 completion:[OCMArg isNil]]);
  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, nil);
}

- (void)testOpenAdInspectorSuccess {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#openAdInspector"
                                        arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);

  OCMStub([gadMobileAdsClassMock
              presentAdInspectorFromViewController:[OCMArg any]
                                 completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        GADAdInspectorCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(nil);
      });

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  OCMVerify([gadMobileAdsClassMock
      presentAdInspectorFromViewController:[OCMArg any]
                         completionHandler:[OCMArg any]]);
  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult, nil);
}

- (void)testOpenAdInspectorError {
  FlutterMethodCall *methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"MobileAds#openAdInspector"
                                        arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  id gadMobileAdsClassMock = OCMClassMock([GADMobileAds class]);
  OCMStub(ClassMethod([gadMobileAdsClassMock sharedInstance]))
      .andReturn((GADMobileAds *)gadMobileAdsClassMock);
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : @"message",
  };
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];

  OCMStub([gadMobileAdsClassMock
              presentAdInspectorFromViewController:[OCMArg any]
                                 completionHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        GADAdInspectorCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler(error);
      });

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  OCMVerify([gadMobileAdsClassMock
      presentAdInspectorFromViewController:[OCMArg any]
                         completionHandler:[OCMArg any]]);
  XCTAssertTrue(resultInvoked);
  FlutterError *resultError = (FlutterError *)returnedResult;

  XCTAssertEqualObjects(resultError.code, @"1");
  XCTAssertEqualObjects(resultError.message, @"message");
  XCTAssertEqualObjects(resultError.details, @"domain");
}

- (void)testGetRequestConfiguration {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"MobileAds#getRequestConfiguration"
                     arguments:@{}];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(returnedResult,
                 [GADMobileAds.sharedInstance requestConfiguration]);
}

- (void)testGetAnchoredAdaptiveBannerAdSize {
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"AdSize#getAnchoredAdaptiveBannerAdSize"
                     arguments:@{
                       @"orientation" : @"portrait",
                       @"width" : @23,
                     }];

  __block bool resultInvoked = false;
  __block id _Nullable returnedResult;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(
      [returnedResult doubleValue],
      GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(23).size.height);

  methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"AdSize#getAnchoredAdaptiveBannerAdSize"
                     arguments:@{
                       @"orientation" : @"landscape",
                       @"width" : @34,
                     }];

  resultInvoked = false;
  result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual(
      [returnedResult doubleValue],
      GADLandscapeAnchoredAdaptiveBannerAdSizeWithWidth(34).size.height);

  methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"AdSize#getAnchoredAdaptiveBannerAdSize"
                     arguments:@{
                       @"width" : @45,
                     }];

  resultInvoked = false;
  result = ^(id _Nullable result) {
    resultInvoked = true;
    returnedResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  XCTAssertEqual([returnedResult doubleValue],
                 GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(45)
                     .size.height);
}

- (void)testGetAdSize_bannerAd {
  // Method calls to load a banner ad.
  FlutterMethodCall *loadAdMethodCall = [FlutterMethodCall
      methodCallWithMethodName:@"loadBannerAd"
                     arguments:@{
                       @"adId" : @(1),
                       @"adUnitId" : @"ad-unit-id",
                       @"size" : [[FLTAdSize alloc] initWithWidth:@1 height:@2],
                       @"request" : [[FLTAdRequest alloc] init],
                     }];

  __block bool loadAdResultInvoked = false;
  __block id _Nullable returnedLoadAdResult;
  FlutterResult loadAdResult = ^(id _Nullable result) {
    loadAdResultInvoked = true;
    returnedLoadAdResult = result;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:loadAdMethodCall
                                       result:loadAdResult];

  XCTAssertTrue(loadAdResultInvoked);
  XCTAssertNil(returnedLoadAdResult);

  // Method call to get the ad size.
  __block bool getAdSizeResultInvoked = false;
  __block FLTAdSize *_Nullable returnedGetAdSizeResult;
  FlutterResult getAdSizeResult = ^(id _Nullable result) {
    getAdSizeResultInvoked = true;
    returnedGetAdSizeResult = result;
  };

  FlutterMethodCall *getAdSizeMethodCall =
      [FlutterMethodCall methodCallWithMethodName:@"getAdSize"
                                        arguments:@{@"adId" : @(1)}];
  [_fltGoogleMobileAdsPlugin handleMethodCall:getAdSizeMethodCall
                                       result:getAdSizeResult];

  XCTAssertTrue(getAdSizeResultInvoked);
  XCTAssertEqualObjects(returnedGetAdSizeResult.width, @1);
  XCTAssertEqualObjects(returnedGetAdSizeResult.height, @2);
}

- (void)testServerSideVerificationOptions_rewardedAd {
  // Mock having already loaded an ad
  FLTRewardedAd *mockAd = OCMClassMock([FLTRewardedAd class]);
  OCMStub([_mockAdInstanceManager adFor:[OCMArg isEqual:@1]]).andReturn(mockAd);

  // Method calls to set ssv
  FLTServerSideVerificationOptions *mockSSV =
      OCMClassMock([FLTServerSideVerificationOptions class]);
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"setServerSideVerificationOptions"
                     arguments:@{
                       @"adId" : @(1),
                       @"adUnitId" : @"ad-unit-id",
                       @"serverSideVerificationOptions" : mockSSV,
                     }];

  __block bool resultInvoked = false;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  OCMVerify([mockAd setServerSideVerificationOptions:[OCMArg isEqual:mockSSV]]);
}

- (void)testServerSideVerificationOptions_rewardedInterstitialAd {
  // Mock having already loaded an ad
  FLTRewardedInterstitialAd *mockAd =
      OCMClassMock([FLTRewardedInterstitialAd class]);
  OCMStub([_mockAdInstanceManager adFor:[OCMArg isEqual:@1]]).andReturn(mockAd);

  // Method calls to set ssv
  FLTServerSideVerificationOptions *mockSSV =
      OCMClassMock([FLTServerSideVerificationOptions class]);
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"setServerSideVerificationOptions"
                     arguments:@{
                       @"adId" : @(1),
                       @"adUnitId" : @"ad-unit-id",
                       @"serverSideVerificationOptions" : mockSSV,
                     }];

  __block bool resultInvoked = false;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  XCTAssertTrue(resultInvoked);
  OCMVerify([mockAd setServerSideVerificationOptions:[OCMArg isEqual:mockSSV]]);
}

- (void)testServerSideVerificationOptions_nullAd {
  // Try to set ssv without any ads being loaded
  FLTServerSideVerificationOptions *mockSSV =
      OCMClassMock([FLTServerSideVerificationOptions class]);
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"setServerSideVerificationOptions"
                     arguments:@{
                       @"adId" : @(1),
                       @"adUnitId" : @"ad-unit-id",
                       @"serverSideVerificationOptions" : mockSSV,
                     }];

  __block bool resultInvoked = false;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  // Result still invoked - no op
  XCTAssertTrue(resultInvoked);
}

- (void)testServerSideVerificationOptions_invalidAdType {
  // Mock having already loaded an ad that does not support ssv
  // Strict mock will fail if there are any interactions
  FLTBannerAd *mockAd = OCMStrictClassMock([FLTBannerAd class]);
  OCMStub([_mockAdInstanceManager adFor:[OCMArg isEqual:@1]]).andReturn(mockAd);

  // Try to set ssv without any ads being loaded
  FLTServerSideVerificationOptions *mockSSV =
      OCMClassMock([FLTServerSideVerificationOptions class]);
  FlutterMethodCall *methodCall = [FlutterMethodCall
      methodCallWithMethodName:@"setServerSideVerificationOptions"
                     arguments:@{
                       @"adId" : @(1),
                       @"adUnitId" : @"ad-unit-id",
                       @"serverSideVerificationOptions" : mockSSV,
                     }];

  __block bool resultInvoked = false;
  FlutterResult result = ^(id _Nullable result) {
    resultInvoked = true;
  };

  [_fltGoogleMobileAdsPlugin handleMethodCall:methodCall result:result];

  // Result still invoked - no op
  XCTAssertTrue(resultInvoked);
}

@end
