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

#import "FLTGoogleMobileAdsPlugin.h"
#import "FLTAdUtil.h"
#import "FLTAppStateNotifier.h"
#import "FLTNSString.h"
#import "UserMessagingPlatform/FLTUserMessagingPlatformManager.h"

@interface FLTGoogleMobileAdsPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property NSMutableDictionary<NSString *, id<FLTNativeAdFactory>>
    *nativeAdFactories;
@end

/// Initialization handler for GMASDK. Invokes result at most once.
@interface FLTInitializationHandler : NSObject
- (instancetype)initWithResult:(FlutterResult)result;
- (void)handleInitializationComplete:(GADInitializationStatus *_Nonnull)status;
@end

@implementation FLTInitializationHandler {
  FlutterResult _result;
  BOOL _isInitializationCompleted;
}

- (instancetype)initWithResult:(FlutterResult)result {
  self = [super init];
  if (self) {
    _isInitializationCompleted = false;
    _result = result;
  }
  return self;
}

- (void)handleInitializationComplete:(GADInitializationStatus *_Nonnull)status {
  if (_isInitializationCompleted) {
    return;
  }
  _result([[FLTInitializationStatus alloc] initWithStatus:status]);
  _isInitializationCompleted = true;
}

@end

@implementation FLTGoogleMobileAdsPlugin {
  NSMutableDictionary<NSString *, id<FLTNativeAdFactory>> *_nativeAdFactories;
  FLTAdInstanceManager *_manager;
  id<FLTMediationNetworkExtrasProvider> _mediationNetworkExtrasProvider;
  FLTGoogleMobileAdsReaderWriter *_readerWriter;
  FLTAppStateNotifier *_appStateNotifier;
  FLTUserMessagingPlatformManager *_userMessagingPlatformManager;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTGoogleMobileAdsPlugin *instance = [[FLTGoogleMobileAdsPlugin alloc]
      initWithBinaryMessenger:registrar.messenger];
  [registrar publish:instance];

  FLTGoogleMobileAdsReaderWriter *readerWriter =
      [[FLTGoogleMobileAdsReaderWriter alloc] init];
  instance->_readerWriter = readerWriter;

  NSObject<FlutterMethodCodec> *codec =
      [FlutterStandardMethodCodec codecWithReaderWriter:readerWriter];

  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.flutter.io/google_mobile_ads"
            binaryMessenger:[registrar messenger]
                      codec:codec];
  [registrar addMethodCallDelegate:instance channel:channel];

  FLTNewGoogleMobileAdsViewFactory *viewFactory =
      [[FLTNewGoogleMobileAdsViewFactory alloc]
          initWithManager:instance->_manager];
  [registrar
      registerViewFactory:viewFactory
                   withId:@"plugins.flutter.io/google_mobile_ads/ad_widget"];
}

- (instancetype)init {
  self = [super init];
  return self;
}

- (instancetype)initWithBinaryMessenger:
    (id<FlutterBinaryMessenger>)binaryMessenger {
  self = [self init];
  if (self) {
    _nativeAdFactories = [NSMutableDictionary dictionary];
    _manager =
        [[FLTAdInstanceManager alloc] initWithBinaryMessenger:binaryMessenger];
    _appStateNotifier =
        [[FLTAppStateNotifier alloc] initWithBinaryMessenger:binaryMessenger];
    _userMessagingPlatformManager = [[FLTUserMessagingPlatformManager alloc]
        initWithBinaryMessenger:binaryMessenger];
  }

  return self;
}

+ (BOOL)registerMediationNetworkExtrasProvider:
            (id<FLTMediationNetworkExtrasProvider> _Nonnull)
                mediationNetworkExtrasProvider
                                      registry:
                                          (id<FlutterPluginRegistry> _Nonnull)
                                              registry {
  NSString *pluginClassName =
      NSStringFromClass([FLTGoogleMobileAdsPlugin class]);
  FLTGoogleMobileAdsPlugin *adMobPlugin = (FLTGoogleMobileAdsPlugin *)[registry
      valuePublishedByPlugin:pluginClassName];
  if (!adMobPlugin) {
    NSLog(@"Could not find a %@ instance registering mediation extras "
          @"provider. The plugin may "
          @"have not been registered.",
          pluginClassName);
    return NO;
  }

  adMobPlugin->_mediationNetworkExtrasProvider = mediationNetworkExtrasProvider;
  adMobPlugin->_readerWriter.mediationNetworkExtrasProvider =
      mediationNetworkExtrasProvider;

  return YES;
}

+ (void)unregisterMediationNetworkExtrasProvider:
    (id<FlutterPluginRegistry> _Nonnull)registry {
  NSString *pluginClassName =
      NSStringFromClass([FLTGoogleMobileAdsPlugin class]);
  FLTGoogleMobileAdsPlugin *adMobPlugin = (FLTGoogleMobileAdsPlugin *)[registry
      valuePublishedByPlugin:pluginClassName];
  if (!adMobPlugin) {
    NSLog(@"Could not find a %@ instance deregistering mediation extras "
          @"provider. The plugin may "
          @"have not been registered.",
          pluginClassName);
    return;
  }

  adMobPlugin->_mediationNetworkExtrasProvider = nil;
  adMobPlugin->_readerWriter.mediationNetworkExtrasProvider = nil;
}

+ (BOOL)registerNativeAdFactory:(id<FlutterPluginRegistry>)registry
                      factoryId:(NSString *)factoryId
                nativeAdFactory:(id<FLTNativeAdFactory>)nativeAdFactory {
  NSString *pluginClassName =
      NSStringFromClass([FLTGoogleMobileAdsPlugin class]);
  FLTGoogleMobileAdsPlugin *adMobPlugin = (FLTGoogleMobileAdsPlugin *)[registry
      valuePublishedByPlugin:pluginClassName];
  if (!adMobPlugin) {
    NSString *reason =
        [NSString stringWithFormat:@"Could not find a %@ instance. The plugin "
                                   @"may have not been registered.",
                                   pluginClassName];
    [NSException exceptionWithName:NSInvalidArgumentException
                            reason:reason
                          userInfo:nil];
  }

  if (adMobPlugin.nativeAdFactories[factoryId]) {
    NSLog(@"A NativeAdFactory with the following factoryId already exists: %@",
          factoryId);
    return NO;
  }

  [adMobPlugin.nativeAdFactories setValue:nativeAdFactory forKey:factoryId];
  return YES;
}

+ (id<FLTNativeAdFactory>)unregisterNativeAdFactory:
                              (id<FlutterPluginRegistry>)registry
                                          factoryId:(NSString *)factoryId {
  FLTGoogleMobileAdsPlugin *adMobPlugin = (FLTGoogleMobileAdsPlugin *)[registry
      valuePublishedByPlugin:NSStringFromClass(
                                 [FLTGoogleMobileAdsPlugin class])];

  id<FLTNativeAdFactory> factory = adMobPlugin.nativeAdFactories[factoryId];
  if (factory)
    [adMobPlugin.nativeAdFactories removeObjectForKey:factoryId];
  return factory;
}

- (UIViewController *)rootController {
  return UIApplication.sharedApplication.delegate.window.rootViewController;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  UIViewController *rootController = self.rootController;

  if ([call.method isEqualToString:@"MobileAds#initialize"]) {
    FLTInitializationHandler *handler =
        [[FLTInitializationHandler alloc] initWithResult:result];
    [[GADMobileAds sharedInstance]
        startWithCompletionHandler:^(GADInitializationStatus *_Nonnull status) {
          [handler handleInitializationComplete:status];
        }];
  } else if ([call.method isEqualToString:@"_init"]) {
    [_manager disposeAllAds];
    result(nil);
  } else if ([call.method isEqualToString:@"MobileAds#setSameAppKeyEnabled"]) {
    GADRequestConfiguration *requestConfig =
        GADMobileAds.sharedInstance.requestConfiguration;
    NSNumber *isEnabled = call.arguments[@"isEnabled"];
    [requestConfig setSameAppKeyEnabled:isEnabled.boolValue];
    result(nil);
  } else if ([call.method isEqualToString:@"MobileAds#setAppMuted"]) {
    GADMobileAds.sharedInstance.applicationMuted =
        [call.arguments[@"muted"] boolValue];
    result(nil);
  } else if ([call.method isEqualToString:@"MobileAds#setAppVolume"]) {
    GADMobileAds.sharedInstance.applicationVolume =
        [call.arguments[@"volume"] floatValue];
    result(nil);
  } else if ([call.method
                 isEqualToString:@"MobileAds#disableSDKCrashReporting"]) {
    [GADMobileAds.sharedInstance disableSDKCrashReporting];
    result(nil);
  } else if ([call.method
                 isEqualToString:@"MobileAds#disableMediationInitialization"]) {
    [GADMobileAds.sharedInstance disableMediationInitialization];
    result(nil);
  } else if ([call.method isEqualToString:@"MobileAds#openDebugMenu"]) {
    NSString *adUnitId = call.arguments[@"adUnitId"];
    GADDebugOptionsViewController *debugOptionsViewController =
        [GADDebugOptionsViewController
            debugOptionsViewControllerWithAdUnitID:adUnitId];
    [rootController presentViewController:debugOptionsViewController
                                 animated:YES
                               completion:nil];
    result(nil);
  } else if ([call.method isEqualToString:@"MobileAds#openAdInspector"]) {
    [GADMobileAds.sharedInstance
        presentAdInspectorFromViewController:rootController
                           completionHandler:^(NSError *error) {
                             if (error) {
                               result([FlutterError
                                   errorWithCode:[[NSString alloc]
                                                     initWithInt:error.code]
                                         message:error.localizedDescription
                                         details:error.domain]);
                             } else {
                               result(nil);
                             }
                           }];
  } else if ([call.method isEqualToString:@"MobileAds#getVersionString"]) {
    result([GADMobileAds.sharedInstance sdkVersion]);
  } else if ([call.method
                 isEqualToString:@"MobileAds#getRequestConfiguration"]) {
    result(GADMobileAds.sharedInstance.requestConfiguration);
  } else if ([call.method
                 isEqualToString:@"MobileAds#updateRequestConfiguration"]) {
    NSString *maxAdContentRating = call.arguments[@"maxAdContentRating"];
    NSNumber *tagForChildDirectedTreatment =
        call.arguments[@"tagForChildDirectedTreatment"];
    NSNumber *tagForUnderAgeOfConsent =
        call.arguments[@"tagForUnderAgeOfConsent"];
    NSArray<NSString *> *testDeviceIds = call.arguments[@"testDeviceIds"];

    if (maxAdContentRating != NULL && maxAdContentRating != (id)[NSNull null]) {
      if ([maxAdContentRating isEqualToString:@"G"]) {
        GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating =
            GADMaxAdContentRatingGeneral;
      } else if ([maxAdContentRating isEqualToString:@"PG"]) {
        GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating =
            GADMaxAdContentRatingParentalGuidance;
      } else if ([maxAdContentRating isEqualToString:@"T"]) {
        GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating =
            GADMaxAdContentRatingTeen;
      } else if ([maxAdContentRating isEqualToString:@"MA"]) {
        GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating =
            GADMaxAdContentRatingMatureAudience;
      }
    }
    if (tagForChildDirectedTreatment != NULL &&
        tagForChildDirectedTreatment != (id)[NSNull null]) {
      switch ([tagForChildDirectedTreatment intValue]) {
      case 0:
        [GADMobileAds.sharedInstance.requestConfiguration
            tagForChildDirectedTreatment:NO];
        break;
      case 1:
        [GADMobileAds.sharedInstance.requestConfiguration
            tagForChildDirectedTreatment:YES];
        break;
      }
    }
    if (tagForUnderAgeOfConsent != NULL &&
        tagForUnderAgeOfConsent != (id)[NSNull null]) {
      switch ([tagForUnderAgeOfConsent intValue]) {
      case 0:
        [GADMobileAds.sharedInstance.requestConfiguration
            tagForUnderAgeOfConsent:NO];
        break;
      case 1:
        [GADMobileAds.sharedInstance.requestConfiguration
            tagForUnderAgeOfConsent:YES];
        break;
      }
    }
    if (testDeviceIds != NULL && testDeviceIds != (id)[NSNull null]) {
      GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers =
          testDeviceIds;
    }
    result(nil);
  } else if ([call.method isEqualToString:@"loadBannerAd"]) {
    FLTBannerAd *ad =
        [[FLTBannerAd alloc] initWithAdUnitId:call.arguments[@"adUnitId"]
                                         size:call.arguments[@"size"]
                                      request:call.arguments[@"request"]
                           rootViewController:rootController
                                         adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadAdManagerBannerAd"]) {
    FLTGAMBannerAd *ad =
        [[FLTGAMBannerAd alloc] initWithAdUnitId:call.arguments[@"adUnitId"]
                                           sizes:call.arguments[@"sizes"]
                                         request:call.arguments[@"request"]
                              rootViewController:rootController
                                            adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadFluidAd"]) {
    FLTFluidGAMBannerAd *ad = [[FLTFluidGAMBannerAd alloc]
          initWithAdUnitId:call.arguments[@"adUnitId"]
                   request:call.arguments[@"request"]
        rootViewController:rootController
                      adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadNativeAd"]) {
    NSString *factoryId = call.arguments[@"factoryId"];
    id<FLTNativeAdFactory> factory = _nativeAdFactories[factoryId];

    if (!factory) {
      NSString *message =
          [NSString stringWithFormat:@"Can't find NativeAdFactory with id: %@",
                                     factoryId];
      result([FlutterError errorWithCode:@"NativeAdError"
                                 message:message
                                 details:nil]);
      return;
    }

    FLTAdRequest *request;
    if ([FLTAdUtil isNotNull:call.arguments[@"request"]]) {
      request = call.arguments[@"request"];
    } else if ([FLTAdUtil isNotNull:call.arguments[@"adManagerRequest"]]) {
      request = call.arguments[@"adManagerRequest"];
    }

    FLTNativeAd *ad = [[FLTNativeAd alloc]
          initWithAdUnitId:call.arguments[@"adUnitId"]
                   request:request
           nativeAdFactory:(id)factory
             customOptions:call.arguments[@"customOptions"]
        rootViewController:rootController
                      adId:call.arguments[@"adId"]
           nativeAdOptions:call.arguments[@"nativeAdOptions"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadInterstitialAd"]) {
    FLTInterstitialAd *ad =
        [[FLTInterstitialAd alloc] initWithAdUnitId:call.arguments[@"adUnitId"]
                                            request:call.arguments[@"request"]
                                 rootViewController:rootController
                                               adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadAdManagerInterstitialAd"]) {
    FLTGAMInterstitialAd *ad = [[FLTGAMInterstitialAd alloc]
          initWithAdUnitId:call.arguments[@"adUnitId"]
                   request:call.arguments[@"request"]
        rootViewController:rootController
                      adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadRewardedAd"]) {
    FLTAdRequest *request;
    if ([FLTAdUtil isNotNull:call.arguments[@"request"]]) {
      request = call.arguments[@"request"];
    } else if ([FLTAdUtil isNotNull:call.arguments[@"adManagerRequest"]]) {
      request = call.arguments[@"adManagerRequest"];
    } else {
      result([FlutterError
          errorWithCode:@"InvalidRequest"
                message:@"A null or invalid ad request was provided."
                details:nil]);
      return;
    }

    FLTRewardedAd *ad =
        [[FLTRewardedAd alloc] initWithAdUnitId:call.arguments[@"adUnitId"]
                                        request:request
                             rootViewController:rootController
                                           adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadRewardedInterstitialAd"]) {
    FLTAdRequest *request;
    if ([FLTAdUtil isNotNull:call.arguments[@"request"]]) {
      request = call.arguments[@"request"];
    } else if ([FLTAdUtil isNotNull:call.arguments[@"adManagerRequest"]]) {
      request = call.arguments[@"adManagerRequest"];
    } else {
      result([FlutterError
          errorWithCode:@"InvalidRequest"
                message:@"A null or invalid ad request was provided."
                details:nil]);
      return;
    }

    FLTRewardedInterstitialAd *ad = [[FLTRewardedInterstitialAd alloc]
          initWithAdUnitId:call.arguments[@"adUnitId"]
                   request:request
        rootViewController:rootController
                      adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"loadAppOpenAd"]) {
    FLTAdRequest *request;
    if ([FLTAdUtil isNotNull:call.arguments[@"request"]]) {
      request = call.arguments[@"request"];
    } else if ([FLTAdUtil isNotNull:call.arguments[@"adManagerRequest"]]) {
      request = call.arguments[@"adManagerRequest"];
    } else {
      result([FlutterError
          errorWithCode:@"InvalidRequest"
                message:@"A null or invalid ad request was provided."
                details:nil]);
      return;
    }
    FLTAppOpenAd *ad =
        [[FLTAppOpenAd alloc] initWithAdUnitId:call.arguments[@"adUnitId"]
                                       request:request
                            rootViewController:rootController
                                   orientation:call.arguments[@"orientation"]
                                          adId:call.arguments[@"adId"]];
    [_manager loadAd:ad];
    result(nil);
  } else if ([call.method isEqualToString:@"disposeAd"]) {
    [_manager dispose:call.arguments[@"adId"]];
    result(nil);
  } else if ([call.method isEqualToString:@"showAdWithoutView"]) {
    [_manager showAdWithID:call.arguments[@"adId"]];
    result(nil);
  } else if ([call.method
                 isEqualToString:@"AdSize#getAnchoredAdaptiveBannerAdSize"]) {
    FLTAnchoredAdaptiveBannerSize *size = [[FLTAnchoredAdaptiveBannerSize alloc]
        initWithFactory:[[FLTAdSizeFactory alloc] init]
            orientation:call.arguments[@"orientation"]
                  width:call.arguments[@"width"]];
    if (IsGADAdSizeValid(size.size)) {
      result(size.height);
    } else {
      result(nil);
    }
  } else if ([call.method isEqualToString:@"getAdSize"]) {
    id<FLTAd> ad = [_manager adFor:call.arguments[@"adId"]];
    if ([FLTAdUtil isNull:ad]) {
      // Called on an ad that hasn't been loaded yet.
      result(nil);
    }
    if ([ad isKindOfClass:[FLTBannerAd class]]) {
      FLTBannerAd *bannerAd = (FLTBannerAd *)ad;
      result([bannerAd getAdSize]);
    } else {
      result(FlutterMethodNotImplemented);
    }
  } else if ([call.method
                 isEqualToString:@"setServerSideVerificationOptions"]) {
    id<FLTAd> ad = [_manager adFor:call.arguments[@"adId"]];
    FLTServerSideVerificationOptions *options =
        call.arguments[@"serverSideVerificationOptions"];
    if ([ad isKindOfClass:[FLTRewardedAd class]]) {
      FLTRewardedAd *rewardedAd = (FLTRewardedAd *)ad;
      [rewardedAd setServerSideVerificationOptions:options];
    } else if ([ad isKindOfClass:[FLTRewardedInterstitialAd class]]) {
      FLTRewardedInterstitialAd *rewardedInterstitialAd =
          (FLTRewardedInterstitialAd *)ad;
      [rewardedInterstitialAd setServerSideVerificationOptions:options];
    } else {
      NSLog(@"Error - setServerSideVerificationOptions called on missing or "
            @"invalid ad id: %@",
            call.arguments[@"adId"]);
    }
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}
@end
