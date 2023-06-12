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

@interface FLTFluidGAMBannerAdTest : XCTestCase
@end

@implementation FLTFluidGAMBannerAdTest {
  FLTAdInstanceManager *mockManager;
}

- (void)setUp {
  mockManager = (OCMClassMock([FLTAdInstanceManager class]));
}

- (void)testDelegates {
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTFluidGAMBannerAd *fluidAd = [[FLTFluidGAMBannerAd alloc]
        initWithAdUnitId:@"testId"
                 request:[[FLTGAMAdRequest alloc] init]
      rootViewController:mockRootViewController
                    adId:@1];
  fluidAd.manager = mockManager;

  [fluidAd load];
  GAMBannerView *adView = (GAMBannerView *)fluidAd.bannerView;
  XCTAssertEqual(adView.appEventDelegate, fluidAd);
  XCTAssertEqual(adView.delegate, fluidAd);

  [fluidAd.bannerView.delegate
      bannerViewDidReceiveAd:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onAdLoaded:[OCMArg isEqual:fluidAd]
                       responseInfo:[OCMArg isEqual:adView.responseInfo]]);

  [fluidAd.bannerView.delegate
      bannerViewDidDismissScreen:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerDidDismissScreen:[OCMArg isEqual:fluidAd]]);

  [fluidAd.bannerView.delegate
      bannerViewWillDismissScreen:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerWillDismissScreen:[OCMArg isEqual:fluidAd]]);

  [fluidAd.bannerView.delegate
      bannerViewWillPresentScreen:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerWillPresentScreen:[OCMArg isEqual:fluidAd]]);

  [fluidAd.bannerView.delegate
      bannerViewDidRecordImpression:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager onBannerImpression:[OCMArg isEqual:fluidAd]]);

  [fluidAd.bannerView.delegate
      bannerViewDidRecordClick:OCMClassMock([GADBannerView class])];
  OCMVerify([mockManager adDidRecordClick:[OCMArg isEqual:fluidAd]]);

  // Mock callback of paid event handler.
  GADAdValue *adValue = OCMClassMock([GADAdValue class]);
  OCMStub([adValue value]).andReturn(NSDecimalNumber.one);
  OCMStub([adValue precision]).andReturn(GADAdValuePrecisionEstimated);
  OCMStub([adValue currencyCode]).andReturn(@"currencyCode");

  fluidAd.bannerView.paidEventHandler(adValue);
  OCMVerify([mockManager
      onPaidEvent:[OCMArg isEqual:fluidAd]
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
  [fluidAd.bannerView.delegate bannerView:OCMClassMock([GADBannerView class])
              didFailToReceiveAdWithError:error];
  OCMVerify([mockManager onAdFailedToLoad:[OCMArg isEqual:fluidAd]
                                    error:[OCMArg isEqual:error]]);

  [adView.appEventDelegate adView:adView
               didReceiveAppEvent:@"appEvent"
                         withInfo:@"info"];
  OCMVerify([mockManager onAppEvent:[OCMArg isEqual:fluidAd]
                               name:[OCMArg isEqual:@"appEvent"]
                               data:[OCMArg isEqual:@"info"]]);
}

- (void)testPlatformViewSetup {
  // Setup mocks
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);

  id scrollViewClassMock = OCMClassMock([UIScrollView class]);
  OCMStub([scrollViewClassMock alloc]).andReturn(scrollViewClassMock);
  OCMStub([scrollViewClassMock initWithFrame:CGRectZero])
      .andReturn(scrollViewClassMock);

  id gamBannerClassMock = OCMClassMock([GAMBannerView class]);
  OCMStub([gamBannerClassMock alloc]).andReturn(gamBannerClassMock);
  OCMStub([gamBannerClassMock initWithAdSize:GADAdSizeFluid])
      .andReturn(gamBannerClassMock);

  // Create and load an ad.
  FLTFluidGAMBannerAd *fluidAd = [[FLTFluidGAMBannerAd alloc]
        initWithAdUnitId:@"testId"
                 request:[[FLTGAMAdRequest alloc] init]
      rootViewController:mockRootViewController
                    adId:@1];
  fluidAd.manager = mockManager;

  // Mimic successful loading of an ad.
  [fluidAd load];
  [fluidAd.bannerView.delegate
      bannerViewDidReceiveAd:OCMClassMock([GADBannerView class])];

  // The banner view should be contained within a scrollview.
  XCTAssertEqualObjects(fluidAd.view, scrollViewClassMock);
  OCMVerify([(UIScrollView *)scrollViewClassMock
      addSubview:[OCMArg isKindOfClass:GAMBannerView.class]]);
  OCMVerify([(UIScrollView *)scrollViewClassMock
      setShowsHorizontalScrollIndicator:NO]);
  OCMVerify(
      [(UIScrollView *)scrollViewClassMock setShowsVerticalScrollIndicator:NO]);

  [scrollViewClassMock stopMocking];
  [gamBannerClassMock stopMocking];
}

- (void)testSizeChangedEvent {
  // Setup mocks
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);

  // Create and load an ad.
  FLTFluidGAMBannerAd *fluidAd = [[FLTFluidGAMBannerAd alloc]
        initWithAdUnitId:@"testId"
                 request:[[FLTGAMAdRequest alloc] init]
      rootViewController:mockRootViewController
                    adId:@1];
  fluidAd.manager = mockManager;

  // Mimic successful loading of an ad.
  [fluidAd load];
  [fluidAd.bannerView.delegate
      bannerViewDidReceiveAd:OCMClassMock([GADBannerView class])];

  [fluidAd.bannerView.adSizeDelegate
                  adView:fluidAd.bannerView
      willChangeAdSizeTo:GADAdSizeFromCGSize(CGSizeMake(0, 25))];
  OCMVerify([mockManager onFluidAdHeightChanged:fluidAd height:25]);
}

- (void)testLoad {
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  UIViewController *mockRootViewController =
      OCMClassMock([UIViewController class]);
  FLTFluidGAMBannerAd *ad =
      [[FLTFluidGAMBannerAd alloc] initWithAdUnitId:@"testId"
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
