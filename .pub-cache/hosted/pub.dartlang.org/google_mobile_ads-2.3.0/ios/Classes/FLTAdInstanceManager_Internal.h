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

#import "FLTAd_Internal.h"
#import "FLTGoogleMobileAdsCollection_Internal.h"
#import "FLTGoogleMobileAdsReaderWriter_Internal.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@protocol FLTAd;
@class FLTBannerAd;
@class FLTNativeAd;
@class FLTRewardedAd;
@class FLTRewardedInterstitialAd;
@class FLTRewardItem;
@class FLTAdValue;

@interface FLTAdInstanceManager : NSObject
- (instancetype _Nonnull)initWithBinaryMessenger:
    (id<FlutterBinaryMessenger> _Nonnull)binaryMessenger;
- (id<FLTAd> _Nullable)adFor:(NSNumber *_Nonnull)adId;
- (NSNumber *_Nullable)adIdFor:(id<FLTAd> _Nonnull)ad;
- (void)loadAd:(id<FLTAd> _Nonnull)ad;
- (void)dispose:(NSNumber *_Nonnull)adId;
- (void)showAdWithID:(NSNumber *_Nonnull)adId;
- (void)onAdLoaded:(id<FLTAd> _Nonnull)ad
      responseInfo:(GADResponseInfo *_Nonnull)responseInfo;
- (void)onAdFailedToLoad:(id<FLTAd> _Nonnull)ad error:(NSError *_Nonnull)error;
- (void)onAppEvent:(id<FLTAd> _Nonnull)ad
              name:(NSString *_Nullable)name
              data:(NSString *_Nullable)data;
- (void)onNativeAdImpression:(FLTNativeAd *_Nonnull)ad;
- (void)onNativeAdWillPresentScreen:(FLTNativeAd *_Nonnull)ad;
- (void)onNativeAdDidDismissScreen:(FLTNativeAd *_Nonnull)ad;
- (void)onNativeAdWillDismissScreen:(FLTNativeAd *_Nonnull)ad;
- (void)onRewardedAdUserEarnedReward:(FLTRewardedAd *_Nonnull)ad
                              reward:(FLTRewardItem *_Nonnull)reward;
- (void)onRewardedInterstitialAdUserEarnedReward:
            (FLTRewardedInterstitialAd *_Nonnull)ad
                                          reward:
                                              (FLTRewardItem *_Nonnull)reward;
- (void)onPaidEvent:(id<FLTAd> _Nonnull)ad value:(FLTAdValue *_Nonnull)value;
- (void)onBannerImpression:(FLTBannerAd *_Nonnull)ad;
- (void)onBannerWillDismissScreen:(FLTBannerAd *_Nonnull)ad;
- (void)onBannerDidDismissScreen:(FLTBannerAd *_Nonnull)ad;
- (void)onBannerWillPresentScreen:(FLTBannerAd *_Nonnull)ad;

- (void)adWillPresentFullScreenContent:(id<FLTAd> _Nonnull)ad;
- (void)adDidDismissFullScreenContent:(id<FLTAd> _Nonnull)ad;
- (void)adWillDismissFullScreenContent:(id<FLTAd> _Nonnull)ad;
- (void)adDidRecordImpression:(id<FLTAd> _Nonnull)ad;
- (void)adDidRecordClick:(id<FLTAd> _Nonnull)ad;
- (void)didFailToPresentFullScreenContentWithError:(id<FLTAd> _Nonnull)ad
                                             error:(NSError *_Nonnull)error;
- (void)onFluidAdHeightChanged:(id<FLTAd> _Nonnull)ad height:(CGFloat)height;
- (void)disposeAllAds;
@end

@interface FLTNewGoogleMobileAdsViewFactory
    : NSObject <FlutterPlatformViewFactory>
@property(readonly) FLTAdInstanceManager *_Nonnull manager;
- (instancetype _Nonnull)initWithManager:
    (FLTAdInstanceManager *_Nonnull)manager;
@end
