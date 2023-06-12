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
#import "../Classes/FLTAd_Internal.h"

@interface FLTRewardedAdTest : XCTestCase
@end

@implementation FLTRewardedAdTest {
  FLTAdInstanceManager *mockManager;
}

- (void)setUp {
  mockManager = (OCMClassMock([FLTAdInstanceManager class]));
}

- (void)testLoadShowRewardedAdGADRequest {
  FLTAdRequest *request = OCMClassMock([FLTAdRequest class]);
  OCMStub([request keywords]).andReturn(@[ @"apple" ]);
  GADRequest *gadRequest = OCMClassMock([GADRequest class]);
  OCMStub([request asGADRequest:[OCMArg any]]).andReturn(gadRequest);

  [self testLoadShowRewardedAd:request gadOrGAMRequest:gadRequest];
}

- (void)testLoadShowRewardedAdGAMRequest {
  FLTGAMAdRequest *request = OCMClassMock([FLTGAMAdRequest class]);
  OCMStub([request keywords]).andReturn(@[ @"apple" ]);
  GAMRequest *gamRequest = OCMClassMock([GAMRequest class]);
  OCMStub([request asGAMRequest:[OCMArg any]]).andReturn(gamRequest);

  [self testLoadShowRewardedAd:request gadOrGAMRequest:gamRequest];
}

// Helper method for testing with FLTAdRequest and FLTGAMAdRequest.
- (void)testLoadShowRewardedAd:(FLTAdRequest *)request
               gadOrGAMRequest:(GADRequest *)gadOrGAMRequest {
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTRewardedAd *ad =
      [[FLTRewardedAd alloc] initWithAdUnitId:@"testId"
                                      request:request
                           rootViewController:mockRootViewController
                                         adId:@1];
  ad.manager = mockManager;

  // Stub the load call to invoke successful load callback.
  id rewardedClassMock = OCMClassMock([GADRewardedAd class]);
  OCMStub(ClassMethod([rewardedClassMock loadWithAdUnitID:[OCMArg any]
                                                  request:[OCMArg any]
                                        completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(GADRewardedAd *ad, NSError *error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(rewardedClassMock, nil);
      });
  // Stub setting of FullScreenContentDelegate to invoke delegate callbacks.
  NSError *error = OCMClassMock([NSError class]);
  __block id<GADFullScreenContentDelegate> fullScreenContentDelegate;
  OCMStub([rewardedClassMock setFullScreenContentDelegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        [invocation getArgument:&fullScreenContentDelegate atIndex:2];
        XCTAssertEqual(fullScreenContentDelegate, ad);
      });
  GADResponseInfo *responseInfo = OCMClassMock([GADResponseInfo class]);
  OCMStub([rewardedClassMock responseInfo]).andReturn(responseInfo);
  // Stub presentFromRootViewController to invoke reward callback.
  GADAdReward *mockReward = OCMClassMock([GADAdReward class]);
  OCMStub([mockReward amount]).andReturn(@1.0);
  OCMStub([mockReward type]).andReturn(@"type");
  OCMStub([rewardedClassMock adReward]).andReturn(mockReward);
  OCMStub([rewardedClassMock presentFromRootViewController:[OCMArg any]
                                  userDidEarnRewardHandler:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        GADUserDidEarnRewardHandler rewardHandler;
        [invocation getArgument:&rewardHandler atIndex:3];
        rewardHandler();
      });

  // Mock callback of paid event handler.
  GADAdValue *adValue = OCMClassMock([GADAdValue class]);
  OCMStub([adValue value]).andReturn(NSDecimalNumber.one);
  OCMStub([adValue precision]).andReturn(GADAdValuePrecisionEstimated);
  OCMStub([adValue currencyCode]).andReturn(@"currencyCode");
  OCMStub([rewardedClassMock
      setPaidEventHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        GADPaidEventHandler handler = obj;
        handler(adValue);
        return YES;
      }]]);

  // Setup mock for UIApplication.sharedInstance
  id uiApplicationClassMock = OCMClassMock([UIApplication class]);
  OCMStub(ClassMethod([uiApplicationClassMock sharedApplication]))
      .andReturn(uiApplicationClassMock);

  // Call load and check expected interactions with mocks.
  [ad load];

  OCMVerify(ClassMethod([rewardedClassMock
       loadWithAdUnitID:[OCMArg isEqual:@"testId"]
                request:[OCMArg isEqual:gadOrGAMRequest]
      completionHandler:[OCMArg any]]));
  OCMVerify([mockManager onAdLoaded:[OCMArg isEqual:ad]
                       responseInfo:[OCMArg isEqual:responseInfo]]);
  OCMVerify(
      [rewardedClassMock setFullScreenContentDelegate:[OCMArg isEqual:ad]]);
  XCTAssertEqual(ad.rewardedAd, rewardedClassMock);
  OCMVerify([mockManager
      onPaidEvent:[OCMArg isEqual:ad]
            value:[OCMArg checkWithBlock:^BOOL(id obj) {
              FLTAdValue *adValue = obj;
              XCTAssertEqualObjects(
                  adValue.valueMicros,
                  [[NSDecimalNumber alloc] initWithInt:1000000]);
              XCTAssertEqual(adValue.precision, GADAdValuePrecisionEstimated);
              XCTAssertEqualObjects(adValue.currencyCode, @"currencyCode");
              return TRUE;
            }]]);

  // Set SSV and verify interactions with mocks
  FLTServerSideVerificationOptions *serverSideVerificationOptions =
      OCMClassMock([FLTServerSideVerificationOptions class]);
  GADServerSideVerificationOptions *gadOptions =
      OCMClassMock([GADServerSideVerificationOptions class]);
  OCMStub([serverSideVerificationOptions asGADServerSideVerificationOptions])
      .andReturn(gadOptions);

  [ad setServerSideVerificationOptions:serverSideVerificationOptions];

  OCMVerify([rewardedClassMock
      setServerSideVerificationOptions:[OCMArg isEqual:gadOptions]]);

  // Show the ad and verify callbacks invoked
  [ad show];

  OCMVerify([rewardedClassMock
      presentFromRootViewController:[OCMArg isEqual:mockRootViewController]
           userDidEarnRewardHandler:[OCMArg any]]);

  [fullScreenContentDelegate adWillPresentFullScreenContent:rewardedClassMock];
  OCMVerify([mockManager adWillPresentFullScreenContent:[OCMArg isEqual:ad]]);
  // Verify that we hide status bar
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  OCMVerify([uiApplicationClassMock setStatusBarHidden:YES]);
#pragma clang diagnostic pop

  [fullScreenContentDelegate adDidRecordImpression:rewardedClassMock];
  OCMVerify([mockManager adDidRecordImpression:[OCMArg isEqual:ad]]);

  [fullScreenContentDelegate adDidRecordClick:rewardedClassMock];
  OCMVerify([mockManager adDidRecordClick:[OCMArg isEqual:ad]]);

  [fullScreenContentDelegate adDidDismissFullScreenContent:rewardedClassMock];
  OCMVerify([mockManager adDidDismissFullScreenContent:[OCMArg isEqual:ad]]);

  [fullScreenContentDelegate adWillDismissFullScreenContent:rewardedClassMock];
  OCMVerify([mockManager adWillDismissFullScreenContent:[OCMArg isEqual:ad]]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  OCMVerify([uiApplicationClassMock setStatusBarHidden:NO]);
#pragma clang diagnostic pop

  [ad ad:rewardedClassMock didFailToPresentFullScreenContentWithError:error];
  OCMVerify([mockManager
      didFailToPresentFullScreenContentWithError:[OCMArg isEqual:ad]
                                           error:[OCMArg isEqual:error]]);

  // Verify reward callback.
  OCMVerify([mockManager
      onRewardedAdUserEarnedReward:[OCMArg isEqual:ad]
                            reward:[OCMArg checkWithBlock:^BOOL(id obj) {
                              FLTRewardItem *reward = (FLTRewardItem *)obj;
                              XCTAssertEqual(reward.amount, @1.0);
                              XCTAssertEqual(reward.type, @"type");
                              return true;
                            }]]);
}

- (void)testFailedToLoadGADRequest {
  FLTAdRequest *request = OCMClassMock([FLTAdRequest class]);
  OCMStub([request keywords]).andReturn(@[ @"apple" ]);
  GADRequest *gadRequest = OCMClassMock([GADRequest class]);
  OCMStub([request asGADRequest:[OCMArg any]]).andReturn(gadRequest);
  [self testFailedToLoad:request];
}

- (void)testFailedToLoadGAMRequest {
  FLTGAMAdRequest *request = OCMClassMock([FLTGAMAdRequest class]);
  OCMStub([request keywords]).andReturn(@[ @"apple" ]);
  GAMRequest *gamRequest = OCMClassMock([GAMRequest class]);
  OCMStub([request asGAMRequest:[OCMArg any]]).andReturn(gamRequest);
  [self testFailedToLoad:request];
}

// Helper for testing failed to load.
- (void)testFailedToLoad:(FLTAdRequest *)request {
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTRewardedAd *ad =
      [[FLTRewardedAd alloc] initWithAdUnitId:@"testId"
                                      request:request
                           rootViewController:mockRootViewController
                                         adId:@1];
  ad.manager = mockManager;

  id rewardedClassMock = OCMClassMock([GADRewardedAd class]);
  NSError *error = OCMClassMock([NSError class]);
  OCMStub(ClassMethod([rewardedClassMock loadWithAdUnitID:[OCMArg any]
                                                  request:[OCMArg any]
                                        completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(GADRewardedAd *ad, NSError *error);
        [invocation getArgument:&completionHandler atIndex:4];
        completionHandler(nil, error);
      });

  [ad load];

  OCMVerify(ClassMethod([rewardedClassMock loadWithAdUnitID:[OCMArg any]
                                                    request:[OCMArg any]
                                          completionHandler:[OCMArg any]]));
  OCMVerify([mockManager onAdFailedToLoad:[OCMArg isEqual:ad]
                                    error:[OCMArg isEqual:error]]);
}

@end
