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

@interface FLTBannerAdTest : XCTestCase
@end

@implementation FLTBannerAdTest {
  FLTAdInstanceManager *mockManager;
}

- (void)setUp {
  mockManager = (OCMClassMock([FLTAdInstanceManager class]));
}

- (void)testDelegates {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTBannerAd *bannerAd =
      [[FLTBannerAd alloc] initWithAdUnitId:@"testId"
                                       size:size
                                    request:[[FLTAdRequest alloc] init]
                         rootViewController:mockRootViewController
                                       adId:@1];
  bannerAd.manager = mockManager;

  [bannerAd load];

  XCTAssertEqual(bannerAd.bannerView.delegate, bannerAd);

  GADBannerView *bannerMock = OCMClassMock([GADBannerView class]);
  GADResponseInfo *responseInfo = OCMClassMock([GADResponseInfo class]);
  OCMStub([bannerMock responseInfo]).andReturn(responseInfo);

  [bannerAd.bannerView.delegate bannerViewDidReceiveAd:bannerMock];
  OCMVerify([mockManager onAdLoaded:[OCMArg isEqual:bannerAd]
                       responseInfo:[OCMArg isEqual:responseInfo]]);

  [bannerAd.bannerView.delegate bannerViewDidDismissScreen:bannerMock];
  OCMVerify([mockManager onBannerDidDismissScreen:[OCMArg isEqual:bannerAd]]);

  [bannerAd.bannerView.delegate bannerViewWillDismissScreen:bannerMock];
  OCMVerify([mockManager onBannerWillDismissScreen:[OCMArg isEqual:bannerAd]]);

  [bannerAd.bannerView.delegate bannerViewWillPresentScreen:bannerMock];
  OCMVerify([mockManager onBannerWillPresentScreen:[OCMArg isEqual:bannerAd]]);

  [bannerAd.bannerView.delegate bannerViewDidRecordImpression:bannerMock];
  OCMVerify([mockManager onBannerImpression:[OCMArg isEqual:bannerAd]]);

  [bannerAd.bannerView.delegate bannerViewDidRecordClick:bannerMock];
  OCMVerify([mockManager adDidRecordClick:[OCMArg isEqual:bannerAd]]);

  // Mock callback of paid event handler.
  GADAdValue *adValue = OCMClassMock([GADAdValue class]);
  OCMStub([adValue value]).andReturn(NSDecimalNumber.one);
  OCMStub([adValue precision]).andReturn(GADAdValuePrecisionEstimated);
  OCMStub([adValue currencyCode]).andReturn(@"currencyCode");

  bannerAd.bannerView.paidEventHandler(adValue);
  OCMVerify([mockManager
      onPaidEvent:[OCMArg isEqual:bannerAd]
            value:[OCMArg checkWithBlock:^BOOL(id obj) {
              FLTAdValue *adValue = obj;
              XCTAssertEqualObjects(
                  adValue.valueMicros,
                  [[NSDecimalNumber alloc] initWithInt:1000000]);
              XCTAssertEqual(adValue.precision, GADAdValuePrecisionEstimated);
              XCTAssertEqualObjects(adValue.currencyCode, @"currencyCode");
              return TRUE;
            }]]);

  NSString *domain = @"domain";
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"description"};
  NSError *error = [NSError errorWithDomain:domain code:1 userInfo:userInfo];
  [bannerAd.bannerView.delegate bannerView:OCMClassMock([GADBannerView class])
               didFailToReceiveAdWithError:error];
  OCMVerify([mockManager onAdFailedToLoad:[OCMArg isEqual:bannerAd]
                                    error:[OCMArg isEqual:error]]);
}

- (void)testLoad {
  FLTAdRequest *request = [[FLTAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTBannerAd *ad = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:[[FLTAdSize alloc] initWithWidth:@(1) height:@(2)]
                 request:request
      rootViewController:mockRootViewController
                    adId:@1];

  XCTAssertEqual(ad.bannerView.adUnitID, @"testId");
  XCTAssertEqual(ad.bannerView.rootViewController, mockRootViewController);

  FLTBannerAd *mockBannerAd = OCMPartialMock(ad);
  GADBannerView *mockView = OCMClassMock([GADBannerView class]);
  OCMStub([mockBannerAd bannerView]).andReturn(mockView);
  [mockBannerAd load];

  OCMVerify([mockView loadRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
                        GADRequest *requestArg = obj;
                        return
                            [requestArg.keywords isEqualToArray:@[ @"apple" ]];
                      }]]);
}

@end
