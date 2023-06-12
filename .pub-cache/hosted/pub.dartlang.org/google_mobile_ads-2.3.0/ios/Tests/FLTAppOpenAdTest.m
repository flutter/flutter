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

@interface FLTAppOpenAdTest : XCTestCase
@end

@implementation FLTAppOpenAdTest {
  FLTAdInstanceManager *mockManager;
}

- (void)setUp {
  mockManager = (OCMClassMock([FLTAdInstanceManager class]));
}

- (void)testLoadShowGADRequest {
  FLTAdRequest *request = OCMClassMock([FLTAdRequest class]);
  OCMStub([request keywords]).andReturn(@[ @"apple" ]);
  GADRequest *gadRequest = OCMClassMock([GADRequest class]);
  OCMStub([request asGADRequest:[OCMArg any]]).andReturn(gadRequest);

  [self testLoadShowAppOpenAd:request gadOrGAMRequest:gadRequest];
}

- (void)testLoadShowGAMRequest {
  FLTGAMAdRequest *request = OCMClassMock([FLTGAMAdRequest class]);
  OCMStub([request keywords]).andReturn(@[ @"apple" ]);
  GAMRequest *gamRequest = OCMClassMock([GAMRequest class]);
  OCMStub([request asGAMRequest:[OCMArg any]]).andReturn(gamRequest);
  FLTServerSideVerificationOptions *serverSideVerificationOptions =
      OCMClassMock([FLTServerSideVerificationOptions class]);
  GADServerSideVerificationOptions *gadOptions =
      OCMClassMock([GADServerSideVerificationOptions class]);
  OCMStub([serverSideVerificationOptions asGADServerSideVerificationOptions])
      .andReturn(gadOptions);

  [self testLoadShowAppOpenAd:request gadOrGAMRequest:gamRequest];
}

// Helper method for testing with FLTAdRequest and FLTGAMAdRequest.
- (void)testLoadShowAppOpenAd:(FLTAdRequest *)request
              gadOrGAMRequest:(GADRequest *)gadOrGAMRequest {
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTAppOpenAd *ad =
      [[FLTAppOpenAd alloc] initWithAdUnitId:@"testId"
                                     request:request
                          rootViewController:mockRootViewController
                                 orientation:@1
                                        adId:@1];
  ad.manager = mockManager;

  // Stub the load call to invoke successful load callback.
  id appOpenClassMock = OCMClassMock([GADAppOpenAd class]);
  OCMStub(ClassMethod([appOpenClassMock
               loadWithAdUnitID:[OCMArg any]
                        request:[OCMArg any]
                    orientation:UIInterfaceOrientationPortrait
              completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(GADAppOpenAd *ad, NSError *error);
        [invocation getArgument:&completionHandler atIndex:5];
        completionHandler(appOpenClassMock, nil);
      });
  // Stub setting of FullScreenContentDelegate to invoke delegate callbacks.
  NSError *error = OCMClassMock([NSError class]);
  OCMStub([appOpenClassMock setFullScreenContentDelegate:[OCMArg any]])
      .andDo(^(NSInvocation *invocation) {
        id<GADFullScreenContentDelegate> delegate;
        [invocation getArgument:&delegate atIndex:2];
        XCTAssertEqual(delegate, ad);
        [delegate adDidRecordImpression:appOpenClassMock];
        [delegate adDidRecordClick:appOpenClassMock];
        [delegate adDidDismissFullScreenContent:appOpenClassMock];
        [delegate adWillPresentFullScreenContent:appOpenClassMock];
        [delegate adWillDismissFullScreenContent:appOpenClassMock];
        [delegate ad:appOpenClassMock
            didFailToPresentFullScreenContentWithError:error];
      });
  GADResponseInfo *responseInfo = OCMClassMock([GADResponseInfo class]);
  OCMStub([appOpenClassMock responseInfo]).andReturn(responseInfo);

  // Mock callback of paid event handler.
  GADAdValue *adValue = OCMClassMock([GADAdValue class]);
  OCMStub([adValue value]).andReturn(NSDecimalNumber.one);
  OCMStub([adValue precision]).andReturn(GADAdValuePrecisionEstimated);
  OCMStub([adValue currencyCode]).andReturn(@"currencyCode");
  OCMStub([appOpenClassMock
      setPaidEventHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        GADPaidEventHandler handler = obj;
        handler(adValue);
        return YES;
      }]]);
  // Call load and check expected interactions with mocks.
  [ad load];

  OCMVerify(ClassMethod([appOpenClassMock
       loadWithAdUnitID:[OCMArg isEqual:@"testId"]
                request:[OCMArg isEqual:gadOrGAMRequest]
            orientation:UIInterfaceOrientationPortrait
      completionHandler:[OCMArg any]]));
  OCMVerify([mockManager onAdLoaded:[OCMArg isEqual:ad]
                       responseInfo:[OCMArg isEqual:responseInfo]]);
  OCMVerify(
      [appOpenClassMock setFullScreenContentDelegate:[OCMArg isEqual:ad]]);
  XCTAssertEqual(ad.appOpenAd, appOpenClassMock);
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

  [ad show];

  OCMVerify([appOpenClassMock
      presentFromRootViewController:[OCMArg isEqual:mockRootViewController]]);

  // Verify full screen callbacks.
  OCMVerify([mockManager adWillPresentFullScreenContent:[OCMArg isEqual:ad]]);
  OCMVerify([mockManager adDidDismissFullScreenContent:[OCMArg isEqual:ad]]);
  OCMVerify([mockManager adWillDismissFullScreenContent:[OCMArg isEqual:ad]]);
  OCMVerify([mockManager adDidRecordImpression:[OCMArg isEqual:ad]]);
  OCMVerify([mockManager adDidRecordClick:[OCMArg isEqual:ad]]);
  OCMVerify([mockManager
      didFailToPresentFullScreenContentWithError:[OCMArg isEqual:ad]
                                           error:[OCMArg isEqual:error]]);
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
  FLTAppOpenAd *ad =
      [[FLTAppOpenAd alloc] initWithAdUnitId:@"testId"
                                     request:request
                          rootViewController:mockRootViewController
                                 orientation:@2
                                        adId:@1];
  ad.manager = mockManager;

  id appOpenClassMock = OCMClassMock([GADAppOpenAd class]);
  NSError *error = OCMClassMock([NSError class]);
  OCMStub(ClassMethod([appOpenClassMock
               loadWithAdUnitID:[OCMArg any]
                        request:[OCMArg any]
                    orientation:UIInterfaceOrientationLandscapeLeft
              completionHandler:[OCMArg any]]))
      .andDo(^(NSInvocation *invocation) {
        void (^completionHandler)(GADAppOpenAd *ad, NSError *error);
        [invocation getArgument:&completionHandler atIndex:5];
        completionHandler(nil, error);
      });

  [ad load];

  OCMVerify(ClassMethod([appOpenClassMock
       loadWithAdUnitID:[OCMArg any]
                request:[OCMArg any]
            orientation:UIInterfaceOrientationLandscapeLeft
      completionHandler:[OCMArg any]]));
  OCMVerify([mockManager onAdFailedToLoad:[OCMArg isEqual:ad]
                                    error:[OCMArg isEqual:error]]);
}

@end
