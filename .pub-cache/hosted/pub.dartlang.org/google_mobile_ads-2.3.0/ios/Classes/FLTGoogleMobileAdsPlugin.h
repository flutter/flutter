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

#import <Flutter/Flutter.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "FLTAdInstanceManager_Internal.h"
#import "FLTAd_Internal.h"
#import "FLTMediationNetworkExtrasProvider.h"
#import "FLTMobileAds_Internal.h"

#define FLTLogWarning(format, ...)                                             \
  NSLog((@"GoogleMobileAdsPlugin <warning> " format), ##__VA_ARGS__)

/**
 * Creates a `GADNativeAdView` to be shown in a Flutter app.
 *
 * When a Native Ad is created in Dart, this protocol is responsible for
 * building the `GADNativeAdView`. Register a class that implements this with a
 * `FLTGoogleMobileAdsPlugin` to use in conjunction with Flutter.
 */
@protocol FLTNativeAdFactory
@required
/**
 * Creates a `GADNativeAdView` with a `GADNativeAd`.
 *
 * @param nativeAd Ad information used to create a `GADNativeAdView`
 * @param customOptions Used to pass additional custom options to create the
 * `GADNativeAdView`. Nullable.
 * @return a `GADNativeAdView` that is overlaid on top of the FlutterView.
 */
- (GADNativeAdView *_Nullable)createNativeAd:(GADNativeAd *_Nonnull)nativeAd
                               customOptions:
                                   (NSDictionary *_Nullable)customOptions;
@end

/**
 * Flutter plugin providing access to the Google Mobile Ads API.
 */
@interface FLTGoogleMobileAdsPlugin : NSObject <FlutterPlugin>

/**
 * Registers a FLTMediationNetworkExtrasProvider used to provide mediation
 * extras when the plugin creates ad requests.
 *
 * @param mediationNetworkExtrasProvider the FLTMediationNetworkExtrasProvider
 * which will be used to get extras when ad requests are created.
 * @param registry the associated FlutterPluginRegistry the plugin will be
 * attached to
 * @return whether mediationNetworkExtrasProvider was successfully registered to
 * a FLTGoogleMobileAdsPlugin in the registry.
 */
+ (BOOL)registerMediationNetworkExtrasProvider:
            (id<FLTMediationNetworkExtrasProvider> _Nonnull)
                mediationNetworkExtrasProvider
                                      registry:
                                          (id<FlutterPluginRegistry> _Nonnull)
                                              registry;

/*
 * Unregisters any FLTMediationNetworkExtrasProvider that was associated with
 * the FLTGoogleMobileAdsPlugin in registry.
 */
+ (void)unregisterMediationNetworkExtrasProvider:
    (id<FlutterPluginRegistry> _Nonnull)registry;

/**
 * Adds a `FLTNativeAdFactory` used to create a `GADNativeAdView`s from a Native
 * Ad created in Dart.
 *
 * @param registry maintains access to a `FLTGoogleMobileAdsPlugin`` instance.
 * @param factoryId a unique identifier for the ad factory. The Native Ad
 * created in Dart includes a parameter that refers to this.
 * @param nativeAdFactory creates `GADNativeAdView`s when a Native Ad is created
 * in Dart.
 * @return whether the factoryId is unique and the nativeAdFactory was
 * successfully added.
 */
+ (BOOL)registerNativeAdFactory:(id<FlutterPluginRegistry> _Nonnull)registry
                      factoryId:(NSString *_Nonnull)factoryId
                nativeAdFactory:
                    (id<FLTNativeAdFactory> _Nonnull)nativeAdFactory;

/**
 * Unregisters a `FLTNativeAdFactory` used to create `GADNativeAdView`s from a
 * Native Ad created in Dart.
 *
 * @param registry maintains access to a `FLTGoogleMobileAdsPlugin `instance.
 * @param factoryId a unique identifier for the ad factory. The Native Ad
 * created in Dart includes a parameter that refers to this.
 * @return the previous `FLTNativeAdFactory` associated with this factoryId, or
 * null if there was none for this factoryId.
 */
+ (id<FLTNativeAdFactory> _Nullable)
    unregisterNativeAdFactory:(id<FlutterPluginRegistry> _Nonnull)registry
                    factoryId:(NSString *_Nonnull)factoryId;
@end
