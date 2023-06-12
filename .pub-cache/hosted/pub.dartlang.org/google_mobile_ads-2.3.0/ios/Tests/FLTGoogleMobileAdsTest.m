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
#import "../Classes/FLTGoogleMobileAdsCollection_Internal.h"
#import "../Classes/FLTGoogleMobileAdsPlugin.h"
#import "../Classes/FLTGoogleMobileAdsReaderWriter_Internal.h"
#import "../Classes/FLTMobileAds_Internal.h"

@interface FLTGoogleMobileAdsTest : XCTestCase
@end

@implementation FLTGoogleMobileAdsTest {
  FLTAdInstanceManager *_manager;
  NSObject<FlutterBinaryMessenger> *_mockMessenger;
  NSObject<FlutterMethodCodec> *_methodCodec;
}

static NSString *channel = @"plugins.flutter.io/google_mobile_ads";

- (void)setUp {
  _mockMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  _manager =
      [[FLTAdInstanceManager alloc] initWithBinaryMessenger:_mockMessenger];
  _methodCodec = [FlutterStandardMethodCodec
      codecWithReaderWriter:[[FLTGoogleMobileAdsReaderWriter alloc] init]];
}

- (void)testAdInstanceManagerLoadAd {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  FLTBannerAd *bannerAd = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:size
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];

  FLTBannerAd *mockBannerAd = OCMPartialMock(bannerAd);
  OCMStub([mockBannerAd load]);

  [_manager loadAd:bannerAd];

  OCMVerify([mockBannerAd load]);
  XCTAssertEqual([_manager adFor:@(1)], bannerAd);
  XCTAssertEqualObjects([_manager adIdFor:bannerAd], @(1));
}

- (void)testAdInstanceManagerDisposeAd {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  FLTBannerAd *bannerAd = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:size
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  FLTBannerAd *mockBannerAd = OCMPartialMock(bannerAd);
  OCMStub([mockBannerAd load]);

  [_manager loadAd:bannerAd];
  [_manager dispose:@(1)];

  XCTAssertNil([_manager adFor:@(1)]);
  XCTAssertNil([_manager adIdFor:bannerAd]);
}

- (void)testAdInstanceManagerDisposeAllAds {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  FLTBannerAd *bannerAd1 = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:size
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  FLTBannerAd *mockBannerAd1 = OCMPartialMock(bannerAd1);
  OCMStub([mockBannerAd1 load]);

  FLTBannerAd *bannerAd2 = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:size
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@2];
  FLTBannerAd *mockBannerAd2 = OCMPartialMock(bannerAd2);
  OCMStub([mockBannerAd2 load]);

  [_manager loadAd:bannerAd1];
  [_manager loadAd:bannerAd2];
  [_manager disposeAllAds];

  XCTAssertNil([_manager adFor:@(1)]);
  XCTAssertNil([_manager adIdFor:bannerAd1]);
  XCTAssertNil([_manager adFor:@(2)]);
  XCTAssertNil([_manager adIdFor:bannerAd2]);
}

- (void)testAdInstanceManagerOnAdLoaded {
  FLTNativeAd *ad = [[FLTNativeAd alloc]
        initWithAdUnitId:@"testAdUnitId"
                 request:[[FLTAdRequest alloc] init]
         nativeAdFactory:OCMProtocolMock(@protocol(FLTNativeAdFactory))
           customOptions:nil
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1
         nativeAdOptions:nil];
  [_manager loadAd:ad];

  GADResponseInfo *responseInfo = OCMClassMock([GADResponseInfo class]);
  FLTGADResponseInfo *fltResponseInfo =
      [[FLTGADResponseInfo alloc] initWithResponseInfo:responseInfo];
  [_manager onAdLoaded:ad responseInfo:responseInfo];
  NSData *data = [_methodCodec
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"onAdEvent"
                                          arguments:@{
                                            @"adId" : @1,
                                            @"eventName" : @"onAdLoaded",
                                            @"responseInfo" : fltResponseInfo,
                                          }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testAdInstanceManagerOnAdFailedToLoad {
  FLTNativeAd *ad = [[FLTNativeAd alloc]
        initWithAdUnitId:@"testAdUnitId"
                 request:[[FLTAdRequest alloc] init]
         nativeAdFactory:OCMProtocolMock(@protocol(FLTNativeAdFactory))
           customOptions:nil
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1
         nativeAdOptions:nil];
  [_manager loadAd:ad];

  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"message"};
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];

  FLTLoadAdError *loadAdError = [[FLTLoadAdError alloc] initWithError:error];
  [_manager onAdFailedToLoad:ad error:error];
  NSData *data = [_methodCodec
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"onAdEvent"
                                          arguments:@{
                                            @"adId" : @1,
                                            @"eventName" : @"onAdFailedToLoad",
                                            @"loadAdError" : loadAdError,
                                          }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testAdInstanceManagerOnAdFailedToShow {
  FLTInterstitialAd *ad = OCMClassMock([FLTInterstitialAd class]);
  OCMStub([ad adId]).andReturn(@1);
  [_manager loadAd:ad];

  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"message"};
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];

  [_manager didFailToPresentFullScreenContentWithError:ad error:error];
  NSData *data = [_methodCodec
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"onAdEvent"
                                          arguments:@{
                                            @"adId" : @1,
                                            @"eventName" :
                                                @"didFailToPresentFullScreenCon"
                                                @"tentWithError",
                                            @"error" : error,
                                          }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testAdInstanceManagerOnAppEvent {
  FLTNativeAd *ad = [[FLTNativeAd alloc]
        initWithAdUnitId:@"testAdUnitId"
                 request:[[FLTAdRequest alloc] init]
         nativeAdFactory:OCMProtocolMock(@protocol(FLTNativeAdFactory))
           customOptions:nil
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1
         nativeAdOptions:nil];
  [_manager loadAd:ad];

  [_manager onAppEvent:ad name:@"color" data:@"red"];

  NSData *data = [_methodCodec
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"onAdEvent"
                                          arguments:@{
                                            @"adId" : @1,
                                            @"eventName" : @"onAppEvent",
                                            @"name" : @"color",
                                            @"data" : @"red"
                                          }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testAdInstanceManagerOnNativeAdEvents {
  FLTNativeAd *ad = [[FLTNativeAd alloc]
        initWithAdUnitId:@"testAdUnitId"
                 request:[[FLTAdRequest alloc] init]
         nativeAdFactory:OCMProtocolMock(@protocol(FLTNativeAdFactory))
           customOptions:nil
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1
         nativeAdOptions:nil];
  [_manager loadAd:ad];

  [_manager adDidRecordClick:ad];
  NSData *clickData = [self getDataForEvent:@"adDidRecordClick" adId:@1];
  OCMVerify([_mockMessenger sendOnChannel:channel message:clickData]);

  [_manager onNativeAdImpression:ad];
  NSData *impressionData = [self getDataForEvent:@"onNativeAdImpression"
                                            adId:@1];
  OCMVerify([_mockMessenger sendOnChannel:channel message:impressionData]);

  [_manager onNativeAdWillPresentScreen:ad];
  NSData *presentScreenData =
      [self getDataForEvent:@"onNativeAdWillPresentScreen" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:presentScreenData]));

  [_manager onNativeAdDidDismissScreen:ad];
  NSData *didDismissData = [self getDataForEvent:@"onNativeAdDidDismissScreen"
                                            adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:didDismissData]));

  [_manager onNativeAdWillDismissScreen:ad];
  NSData *willDismissData = [self getDataForEvent:@"onNativeAdWillDismissScreen"
                                             adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:willDismissData]));
}

- (void)testAdInstanceManagerOnRewardedAdUserEarnedReward {
  FLTRewardedAd *ad = [[FLTRewardedAd alloc]
        initWithAdUnitId:@"testId"
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  [_manager loadAd:ad];

  [_manager onRewardedAdUserEarnedReward:ad
                                  reward:[[FLTRewardItem alloc]
                                             initWithAmount:@(1)
                                                       type:@"type"]];
  NSData *data = [_methodCodec
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"onAdEvent"
                                          arguments:@{
                                            @"adId" : @1,
                                            @"eventName" :
                                                @"onRewardedAdUserEarnedReward",
                                            @"rewardItem" :
                                                [[FLTRewardItem alloc]
                                                    initWithAmount:@(1)
                                                              type:@"type"]
                                          }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testAdInstanceManagerOnRewardedInterstitialAdUserEarnedReward {
  FLTRewardedInterstitialAd *ad = [[FLTRewardedInterstitialAd alloc]
        initWithAdUnitId:@"testId"
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  [_manager loadAd:ad];

  [_manager
      onRewardedInterstitialAdUserEarnedReward:ad
                                        reward:[[FLTRewardItem alloc]
                                                   initWithAmount:@(1)
                                                             type:@"type"]];
  NSData *data = [_methodCodec
      encodeMethodCall:
          [FlutterMethodCall
              methodCallWithMethodName:@"onAdEvent"
                             arguments:@{
                               @"adId" : @1,
                               @"eventName" :
                                   @"onRewardedInterstitialAdUserEarnedReward",
                               @"rewardItem" : [[FLTRewardItem alloc]
                                   initWithAmount:@(1)
                                             type:@"type"]
                             }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testAdInstanceManagerOnPaidEvent {
  FLTNativeAd *ad = [[FLTNativeAd alloc]
        initWithAdUnitId:@"testAdUnitId"
                 request:[[FLTAdRequest alloc] init]
         nativeAdFactory:OCMProtocolMock(@protocol(FLTNativeAdFactory))
           customOptions:nil
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1
         nativeAdOptions:nil];
  [_manager loadAd:ad];

  NSDecimalNumber *valueDecimal = [[NSDecimalNumber alloc] initWithInt:1];
  FLTAdValue *value = [[FLTAdValue alloc] initWithValue:valueDecimal
                                              precision:12
                                           currencyCode:@"code"];

  [_manager onPaidEvent:ad value:value];
  NSData *data = [_methodCodec
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"onAdEvent"
                                          arguments:@{
                                            @"adId" : @1,
                                            @"eventName" : @"onPaidEvent",
                                            @"valueMicros" : value.valueMicros,
                                            @"precision" :
                                                [NSNumber numberWithInteger:12],
                                            @"currencyCode" : @"code"
                                          }]];
  OCMVerify([_mockMessenger sendOnChannel:channel message:data]);
}

- (void)testBannerEvents {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  FLTBannerAd *ad = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:size
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  FLTBannerAd *mockBannerAd = OCMPartialMock(ad);
  OCMStub([mockBannerAd load]);

  [_manager loadAd:ad];

  [_manager onBannerImpression:ad];
  NSData *impressionData = [self getDataForEvent:@"onBannerImpression" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:impressionData]));

  [_manager onBannerWillDismissScreen:ad];
  NSData *willDismissData = [self getDataForEvent:@"onBannerWillDismissScreen"
                                             adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:willDismissData]));

  [_manager onBannerDidDismissScreen:ad];
  NSData *didDismissData = [self getDataForEvent:@"onBannerDidDismissScreen"
                                            adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:didDismissData]));

  [_manager onBannerWillPresentScreen:ad];
  NSData *willPresentData = [self getDataForEvent:@"onBannerWillPresentScreen"
                                             adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:willPresentData]));
}

- (void)testFullScreenEventsRewardedAd {
  FLTRewardedAd *rewardedAd = [[FLTRewardedAd alloc]
        initWithAdUnitId:@"testId"
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  [_manager loadAd:rewardedAd];

  [_manager adWillPresentFullScreenContent:rewardedAd];
  NSData *didPresentData =
      [self getDataForEvent:@"adWillPresentFullScreenContent" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:didPresentData]));

  [_manager adDidDismissFullScreenContent:rewardedAd];
  NSData *didDismissData =
      [self getDataForEvent:@"adDidDismissFullScreenContent" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:didDismissData]));

  [_manager adWillDismissFullScreenContent:rewardedAd];
  NSData *willDismissData =
      [self getDataForEvent:@"adWillDismissFullScreenContent" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:willDismissData]));

  [_manager adDidRecordImpression:rewardedAd];
  NSData *impressionData = [self getDataForEvent:@"adDidRecordImpression"
                                            adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:impressionData]));
}

- (void)testFullScreenEventsRewardedInterstitialAd {
  FLTRewardedInterstitialAd *rewardedInterstitialAd =
      [[FLTRewardedInterstitialAd alloc]
            initWithAdUnitId:@"testId"
                     request:[[FLTAdRequest alloc] init]
          rootViewController:OCMClassMock([UIViewController class])
                        adId:@1];
  [_manager loadAd:rewardedInterstitialAd];

  [_manager adWillPresentFullScreenContent:rewardedInterstitialAd];
  NSData *didPresentData =
      [self getDataForEvent:@"adWillPresentFullScreenContent" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:didPresentData]));

  [_manager adDidDismissFullScreenContent:rewardedInterstitialAd];
  NSData *didDismissData =
      [self getDataForEvent:@"adDidDismissFullScreenContent" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:didDismissData]));

  [_manager adWillDismissFullScreenContent:rewardedInterstitialAd];
  NSData *willDismissData =
      [self getDataForEvent:@"adWillDismissFullScreenContent" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:willDismissData]));

  [_manager adDidRecordImpression:rewardedInterstitialAd];
  NSData *impressionData = [self getDataForEvent:@"adDidRecordImpression"
                                            adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:impressionData]));
}

- (void)testEventSentForDisposedAd {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  FLTBannerAd *bannerAd = [[FLTBannerAd alloc]
        initWithAdUnitId:@"testId"
                    size:size
                 request:[[FLTAdRequest alloc] init]
      rootViewController:OCMClassMock([UIViewController class])
                    adId:@1];
  FLTBannerAd *mockBannerAd = OCMPartialMock(bannerAd);
  OCMStub([mockBannerAd load]);

  [_manager loadAd:bannerAd];
  [_manager dispose:@(1)];

  XCTAssertNil([_manager adFor:@(1)]);
  XCTAssertNil([_manager adIdFor:bannerAd]);

  GADBannerView *mockGADBannerView = OCMClassMock([GADBannerView class]);
  [bannerAd bannerViewDidRecordImpression:mockGADBannerView];

  NSData *impressionData = [self getDataForEvent:@"onBannerImpression" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:impressionData]));
}

// Helper method to create encoded data for an event and ad id.
- (NSData *)getDataForEvent:(NSString *)name adId:(NSNumber *)adId {
  return [_methodCodec
      encodeMethodCall:[FlutterMethodCall methodCallWithMethodName:@"onAdEvent"
                                                         arguments:@{
                                                           @"adId" : @1,
                                                           @"eventName" : name
                                                         }]];
}

- (void)testAdClick {
  FLTRewardedInterstitialAd *rewardedInterstitialAd =
      [[FLTRewardedInterstitialAd alloc]
            initWithAdUnitId:@"testId"
                     request:[[FLTAdRequest alloc] init]
          rootViewController:OCMClassMock([UIViewController class])
                        adId:@1];

  [_manager adDidRecordClick:rewardedInterstitialAd];
  NSData *impressionData = [self getDataForEvent:@"adDidRecordClick" adId:@1];
  OCMVerify(([_mockMessenger sendOnChannel:channel message:impressionData]));
}

@end
