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

// ignore_for_file: public_member_api_docs

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:collection';

import 'package:google_mobile_ads/src/ad_inspector_containers.dart';
import 'package:google_mobile_ads/src/ad_listeners.dart';
import 'package:google_mobile_ads/src/mobile_ads.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'request_configuration.dart';
import 'ad_containers.dart';

/// Loads and disposes [BannerAds] and [InterstitialAds].
AdInstanceManager instanceManager = AdInstanceManager(
  'plugins.flutter.io/google_mobile_ads',
);

/// Maintains access to loaded [Ad] instances and handles sending/receiving
/// messages to platform code.
class AdInstanceManager {
  AdInstanceManager(String channelName)
      : channel = MethodChannel(
          channelName,
          StandardMethodCodec(AdMessageCodec()),
        ) {
    channel.setMethodCallHandler((MethodCall call) async {
      assert(call.method == 'onAdEvent');

      final int adId = call.arguments['adId'];
      final String eventName = call.arguments['eventName'];

      final Ad? ad = adFor(adId);
      if (ad != null) {
        _onAdEvent(ad, eventName, call.arguments);
      } else {
        debugPrint('$Ad with id `$adId` is not available for $eventName.');
      }
    });
  }

  int _nextAdId = 0;
  final _BiMap<int, Ad> _loadedAds = _BiMap<int, Ad>();

  /// Invokes load and dispose calls.
  final MethodChannel channel;

  void _onAdEvent(Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _onAdEventAndroid(ad, eventName, arguments);
    } else {
      _onAdEventIOS(ad, eventName, arguments);
    }
  }

  void _onAdEventIOS(Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    switch (eventName) {
      case 'onAdLoaded':
        _invokeOnAdLoaded(ad, eventName, arguments);
        break;
      case 'onAdFailedToLoad':
        _invokeOnAdFailedToLoad(ad, eventName, arguments);
        break;
      case 'onAppEvent':
        _invokeOnAppEvent(ad, eventName, arguments);
        break;
      case 'adDidRecordClick':
        _invokeOnAdClicked(ad, eventName);
        break;
      case 'onNativeAdWillPresentScreen': // Fall through
      case 'onBannerWillPresentScreen':
        _invokeOnAdOpened(ad, eventName);
        break;
      case 'onNativeAdDidDismissScreen': // Fall through
      case 'onBannerDidDismissScreen':
        _invokeOnAdClosed(ad, eventName);
        break;
      case 'onBannerWillDismissScreen': // Fall through
      case 'onNativeAdWillDismissScreen':
        if (ad is AdWithView) {
          ad.listener.onAdWillDismissScreen?.call(ad);
        } else {
          debugPrint('invalid ad: $ad, for event name: $eventName');
        }
        break;
      case 'onRewardedAdUserEarnedReward':
      case 'onRewardedInterstitialAdUserEarnedReward':
        _invokeOnUserEarnedReward(ad, eventName, arguments);
        break;
      case 'onBannerImpression':
      case 'adDidRecordImpression': // Fall through
      case 'onNativeAdImpression': // Fall through
        _invokeOnAdImpression(ad, eventName);
        break;
      case 'adWillPresentFullScreenContent':
        _invokeOnAdShowedFullScreenContent(ad, eventName);
        break;
      case 'adDidDismissFullScreenContent':
        _invokeOnAdDismissedFullScreenContent(ad, eventName);
        break;
      case 'adWillDismissFullScreenContent':
        if (ad is RewardedAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
        } else if (ad is InterstitialAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
        } else if (ad is RewardedInterstitialAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
        } else if (ad is AdManagerInterstitialAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
        } else if (ad is AppOpenAd) {
          ad.fullScreenContentCallback?.onAdWillDismissFullScreenContent
              ?.call(ad);
        } else {
          debugPrint('invalid ad: $ad, for event name: $eventName');
        }
        break;
      case 'didFailToPresentFullScreenContentWithError':
        _invokeOnAdFailedToShowFullScreenContent(ad, eventName, arguments);
        break;
      case 'onPaidEvent':
        _invokePaidEvent(ad, eventName, arguments);
        break;
      case 'onFluidAdHeightChanged':
        _invokeFluidAdHeightChanged(ad, arguments);
        break;
      default:
        debugPrint('invalid ad event name: $eventName');
    }
  }

  void _onAdEventAndroid(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    switch (eventName) {
      case 'onAdLoaded':
        _invokeOnAdLoaded(ad, eventName, arguments);
        break;
      case 'onAdFailedToLoad':
        _invokeOnAdFailedToLoad(ad, eventName, arguments);
        break;
      case 'onAdOpened':
        _invokeOnAdOpened(ad, eventName);
        break;
      case 'onAdClosed':
        _invokeOnAdClosed(ad, eventName);
        break;
      case 'onAppEvent':
        _invokeOnAppEvent(ad, eventName, arguments);
        break;
      case 'onRewardedAdUserEarnedReward':
      case 'onRewardedInterstitialAdUserEarnedReward':
        _invokeOnUserEarnedReward(ad, eventName, arguments);
        break;
      case 'onAdImpression':
        _invokeOnAdImpression(ad, eventName);
        break;
      case 'onFailedToShowFullScreenContent':
        _invokeOnAdFailedToShowFullScreenContent(ad, eventName, arguments);
        break;
      case 'onAdShowedFullScreenContent':
        _invokeOnAdShowedFullScreenContent(ad, eventName);
        break;
      case 'onAdDismissedFullScreenContent':
        _invokeOnAdDismissedFullScreenContent(ad, eventName);
        break;
      case 'onPaidEvent':
        _invokePaidEvent(ad, eventName, arguments);
        break;
      case 'onFluidAdHeightChanged':
        _invokeFluidAdHeightChanged(ad, arguments);
        break;
      case 'onAdClicked':
        _invokeOnAdClicked(ad, eventName);
        break;
      default:
        debugPrint('invalid ad event name: $eventName');
    }
  }

  void _invokeFluidAdHeightChanged(Ad ad, Map<dynamic, dynamic> arguments) {
    assert(ad is FluidAdManagerBannerAd);
    (ad as FluidAdManagerBannerAd)
        .onFluidAdHeightChangedListener
        ?.call(ad, arguments['height'].toDouble());
  }

  void _invokeOnAdLoaded(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    ad.responseInfo = arguments['responseInfo'];
    if (ad is AdWithView) {
      ad.listener.onAdLoaded?.call(ad);
    } else if (ad is RewardedAd) {
      ad.rewardedAdLoadCallback.onAdLoaded.call(ad);
    } else if (ad is InterstitialAd) {
      ad.adLoadCallback.onAdLoaded.call(ad);
    } else if (ad is RewardedInterstitialAd) {
      ad.rewardedInterstitialAdLoadCallback.onAdLoaded.call(ad);
    } else if (ad is AdManagerInterstitialAd) {
      ad.adLoadCallback.onAdLoaded.call(ad);
    } else if (ad is AppOpenAd) {
      ad.adLoadCallback.onAdLoaded.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToLoad(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (ad is AdWithView) {
      ad.listener.onAdFailedToLoad?.call(ad, arguments['loadAdError']);
    } else if (ad is RewardedAd) {
      ad.dispose();
      ad.rewardedAdLoadCallback.onAdFailedToLoad.call(arguments['loadAdError']);
    } else if (ad is InterstitialAd) {
      ad.dispose();
      ad.adLoadCallback.onAdFailedToLoad.call(arguments['loadAdError']);
    } else if (ad is RewardedInterstitialAd) {
      ad.dispose();
      ad.rewardedInterstitialAdLoadCallback.onAdFailedToLoad
          .call(arguments['loadAdError']);
    } else if (ad is AdManagerInterstitialAd) {
      ad.dispose();
      ad.adLoadCallback.onAdFailedToLoad.call(arguments['loadAdError']);
    } else if (ad is AppOpenAd) {
      ad.adLoadCallback.onAdFailedToLoad.call(arguments['loadAdError']);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAppEvent(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (ad is AdManagerBannerAd) {
      ad.listener.onAppEvent?.call(ad, arguments['name'], arguments['data']);
    } else if (ad is AdManagerInterstitialAd) {
      ad.appEventListener?.onAppEvent
          ?.call(ad, arguments['name'], arguments['data']);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnUserEarnedReward(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    assert(arguments['rewardItem'] != null);
    if (ad is RewardedAd) {
      ad.onUserEarnedRewardCallback?.call(ad, arguments['rewardItem']);
    } else if (ad is RewardedInterstitialAd) {
      ad.onUserEarnedRewardCallback?.call(ad, arguments['rewardItem']);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdOpened(Ad ad, String eventName) {
    if (ad is AdWithView) {
      ad.listener.onAdOpened?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdClosed(Ad ad, String eventName) {
    if (ad is AdWithView) {
      ad.listener.onAdClosed?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdShowedFullScreenContent(Ad ad, String eventName) {
    if (ad is RewardedAd) {
      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
    } else if (ad is RewardedInterstitialAd) {
      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
    } else if (ad is AdManagerInterstitialAd) {
      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
    } else if (ad is AppOpenAd) {
      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdDismissedFullScreenContent(Ad ad, String eventName) {
    if (ad is RewardedAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else if (ad is RewardedInterstitialAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else if (ad is AdManagerInterstitialAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else if (ad is AppOpenAd) {
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdFailedToShowFullScreenContent(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    if (ad is RewardedAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else if (ad is RewardedInterstitialAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else if (ad is AdManagerInterstitialAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else if (ad is AppOpenAd) {
      ad.fullScreenContentCallback?.onAdFailedToShowFullScreenContent
          ?.call(ad, arguments['error']);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdImpression(Ad ad, String eventName) {
    if (ad is AdWithView) {
      ad.listener.onAdImpression?.call(ad);
    } else if (ad is RewardedAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else if (ad is RewardedInterstitialAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else if (ad is AdManagerInterstitialAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else if (ad is AppOpenAd) {
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokeOnAdClicked(Ad ad, String eventName) {
    if (ad is NativeAd) {
      ad.listener.onAdClicked?.call(ad);
    } else if (ad is AdWithView) {
      ad.listener.onAdClicked?.call(ad);
    } else if (ad is RewardedAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else if (ad is RewardedInterstitialAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else if (ad is AdManagerInterstitialAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else if (ad is AppOpenAd) {
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  void _invokePaidEvent(
      Ad ad, String eventName, Map<dynamic, dynamic> arguments) {
    assert(arguments['valueMicros'] != null && arguments['valueMicros'] is num);

    int precisionTypeInt = arguments['precision'];
    PrecisionType precisionType;
    switch (precisionTypeInt) {
      case 0:
        precisionType = PrecisionType.unknown;
        break;
      case 1:
        precisionType = PrecisionType.estimated;
        break;
      case 2:
        precisionType = PrecisionType.publisherProvided;
        break;
      case 3:
        precisionType = PrecisionType.precise;
        break;
      default:
        debugPrint('Unexpected precisionType: $precisionTypeInt');
        precisionType = PrecisionType.unknown;
        break;
    }
    if (ad is AdWithView) {
      ad.listener.onPaidEvent?.call(
        ad,
        arguments['valueMicros'].toDouble(),
        precisionType,
        arguments['currencyCode'],
      );
    } else if (ad is AdWithoutView) {
      ad.onPaidEvent?.call(
        ad,
        arguments['valueMicros'].toDouble(),
        precisionType,
        arguments['currencyCode'],
      );
    } else {
      debugPrint('invalid ad: $ad, for event name: $eventName');
    }
  }

  Future<InitializationStatus> initialize() async {
    return (await instanceManager.channel.invokeMethod<InitializationStatus>(
      'MobileAds#initialize',
    ))!;
  }

  Future<AdSize> getAdSize(Ad ad) async {
    return (await instanceManager.channel.invokeMethod<AdSize>(
      'getAdSize',
      <dynamic, dynamic>{
        'adId': adIdFor(ad),
      },
    ))!;
  }

  /// Returns null if an invalid [adId] was passed in.
  Ad? adFor(int adId) => _loadedAds[adId];

  /// Returns null if an invalid [Ad] was passed in.
  int? adIdFor(Ad ad) => _loadedAds.inverse[ad];

  final Set<int> _mountedWidgetAdIds = <int>{};

  /// Returns true if the [adId] is already mounted in a [WidgetAd].
  bool isWidgetAdIdMounted(int adId) => _mountedWidgetAdIds.contains(adId);

  /// Indicates that [adId] is mounted in widget tree.
  void mountWidgetAdId(int adId) => _mountedWidgetAdIds.add(adId);

  /// Indicates that [adId] is unmounted from the widget tree.
  void unmountWidgetAdId(int adId) => _mountedWidgetAdIds.remove(adId);

  /// Starts loading the ad if not previously loaded.
  ///
  /// Does nothing if we have already tried to load the ad.
  Future<void> loadBannerAd(BannerAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadBannerAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
        'size': ad.size,
      },
    );
  }

  Future<void> loadInterstitialAd(InterstitialAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadInterstitialAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadNativeAd(NativeAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadNativeAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
        'adManagerRequest': ad.adManagerRequest,
        'factoryId': ad.factoryId,
        'nativeAdOptions': ad.nativeAdOptions,
        'customOptions': ad.customOptions,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadRewardedAd(RewardedAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadRewardedAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
        'adManagerRequest': ad.adManagerRequest,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadRewardedInterstitialAd(RewardedInterstitialAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadRewardedInterstitialAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
        'adManagerRequest': ad.adManagerRequest,
      },
    );
  }

  /// Load an app open ad.
  Future<void> loadAppOpenAd(AppOpenAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadAppOpenAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
        'adManagerRequest': ad.adManagerAdRequest,
        'orientation': ad.orientation,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadAdManagerBannerAd(AdManagerBannerAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadAdManagerBannerAd',
      <dynamic, dynamic>{
        'adId': adId,
        'sizes': ad.sizes,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
      },
    );
  }

  /// Starts loading the ad if not previously loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadFluidAd(FluidAdManagerBannerAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadFluidAd',
      <dynamic, dynamic>{
        'adId': adId,
        'sizes': ad.sizes,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
      },
    );
  }

  /// Loads an ad if not currently loading or loaded.
  ///
  /// Loading also terminates if ad is already in the process of loading.
  Future<void> loadAdManagerInterstitialAd(AdManagerInterstitialAd ad) {
    if (adIdFor(ad) != null) {
      return Future<void>.value();
    }

    final int adId = _nextAdId++;
    _loadedAds[adId] = ad;
    return channel.invokeMethod<void>(
      'loadAdManagerInterstitialAd',
      <dynamic, dynamic>{
        'adId': adId,
        'adUnitId': ad.adUnitId,
        'request': ad.request,
      },
    );
  }

  /// Free the plugin resources associated with this ad.
  ///
  /// Disposing a banner ad that's been shown removes it from the screen.
  /// Interstitial ads can't be programmatically removed from view.
  Future<void> disposeAd(Ad ad) {
    final int? adId = adIdFor(ad);
    final Ad? disposedAd = _loadedAds.remove(adId);
    if (disposedAd == null) {
      return Future<void>.value();
    }
    return channel.invokeMethod<void>(
      'disposeAd',
      <dynamic, dynamic>{
        'adId': adId,
      },
    );
  }

  /// Display an [AdWithoutView] that is overlaid on top of the application.
  Future<void> showAdWithoutView(AdWithoutView ad) {
    assert(
      adIdFor(ad) != null,
      '$Ad has not been loaded or has already been disposed.',
    );

    return channel.invokeMethod<void>(
      'showAdWithoutView',
      <dynamic, dynamic>{
        'adId': adIdFor(ad),
      },
    );
  }

  /// Gets the global [RequestConfiguration].
  Future<RequestConfiguration> getRequestConfiguration() async {
    return (await instanceManager.channel.invokeMethod<RequestConfiguration>(
        'MobileAds#getRequestConfiguration'))!;
  }

  /// Set the [RequestConfiguration] to apply for future ad requests.
  Future<void> updateRequestConfiguration(
      RequestConfiguration requestConfiguration) {
    return channel.invokeMethod<void>(
      'MobileAds#updateRequestConfiguration',
      <dynamic, dynamic>{
        'maxAdContentRating': requestConfiguration.maxAdContentRating,
        'tagForChildDirectedTreatment':
            requestConfiguration.tagForChildDirectedTreatment,
        'testDeviceIds': requestConfiguration.testDeviceIds,
        'tagForUnderAgeOfConsent': requestConfiguration.tagForUnderAgeOfConsent,
      },
    );
  }

  /// Set whether same app key is enabled.
  Future<void> setSameAppKeyEnabled(bool isEnabled) {
    return channel.invokeMethod<void>(
      'MobileAds#setSameAppKeyEnabled',
      <dynamic, dynamic>{
        'isEnabled': isEnabled,
      },
    );
  }

  /// Mute / Unmute app.
  Future<void> setAppMuted(bool muted) {
    return channel.invokeMethod<void>(
      'MobileAds#setAppMuted',
      <dynamic, dynamic>{
        'muted': muted,
      },
    );
  }

  /// Set app volume.
  Future<void> setAppVolume(double volume) {
    return channel.invokeMethod<void>(
      'MobileAds#setAppVolume',
      <dynamic, dynamic>{
        'volume': volume,
      },
    );
  }

  /// Enable / Disable immersive mode for the Ad.
  Future<void> setImmersiveMode(AdWithoutView ad, bool immersiveModeEnabled) {
    assert(
      adIdFor(ad) != null,
      '$ad has not been loaded or has already been disposed.',
    );

    return channel.invokeMethod<void>(
      'setImmersiveMode',
      <dynamic, dynamic>{
        'adId': adIdFor(ad),
        'immersiveModeEnabled': immersiveModeEnabled,
      },
    );
  }

  /// Disables automated SDK crash reporting.
  Future<void> disableSDKCrashReporting() {
    return channel.invokeMethod<void>('MobileAds#disableSDKCrashReporting');
  }

  /// Disables mediation adapter initialization during initialization of the GMA SDK.
  Future<void> disableMediationInitialization() {
    return channel
        .invokeMethod<void>('MobileAds#disableMediationInitialization');
  }

  /// Gets the version string of Google Mobile Ads SDK.
  Future<String> getVersionString() async {
    return (await instanceManager.channel
        .invokeMethod<String>('MobileAds#getVersionString'))!;
  }

  /// Set server side verification options on the ad.
  Future<void> setServerSideVerificationOptions(
    ServerSideVerificationOptions options,
    Ad ad,
  ) {
    return channel.invokeMethod<void>(
      'setServerSideVerificationOptions',
      <dynamic, dynamic>{
        'adId': adIdFor(ad),
        'serverSideVerificationOptions': options,
      },
    );
  }

  /// Opens the debug menu.
  ///
  /// Returns a Future that completes when the platform side api has been
  /// invoked.
  Future<void> openDebugMenu(String adUnitId) async {
    return channel.invokeMethod<void>(
      'MobileAds#openDebugMenu',
      <dynamic, dynamic>{
        'adUnitId': adUnitId,
      },
    );
  }

  /// Send a platform message to open the ad inspector.
  void openAdInspector(OnAdInspectorClosedListener listener) async {
    try {
      await channel.invokeMethod<void>('MobileAds#openAdInspector');
      listener(null);
    } on PlatformException catch (e) {
      var error =
          AdInspectorError(code: e.code, domain: e.details, message: e.message);
      listener(error);
    }
  }
}

@visibleForTesting
class AdMessageCodec extends StandardMessageCodec {
  // The type values below must be consistent for each platform.
  static const int _valueAdSize = 128;
  static const int _valueAdRequest = 129;
  static const int _valueFluidAdSize = 130;
  static const int _valueRewardItem = 132;
  static const int _valueLoadAdError = 133;
  static const int _valueAdManagerAdRequest = 134;
  static const int _valueInitializationState = 135;
  static const int _valueAdapterStatus = 136;
  static const int _valueInitializationStatus = 137;
  static const int _valueServerSideVerificationOptions = 138;
  static const int _valueAdError = 139;
  static const int _valueResponseInfo = 140;
  static const int _valueAdapterResponseInfo = 141;
  static const int _valueAnchoredAdaptiveBannerAdSize = 142;
  static const int _valueSmartBannerAdSize = 143;
  static const int _valueNativeAdOptions = 144;
  static const int _valueVideoOptions = 145;
  static const int _valueInlineAdaptiveBannerAdSize = 146;
  static const int _valueRequestConfigurationParams = 148;

  @override
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value is AdSize) {
      writeAdSize(buffer, value);
    } else if (value is AdManagerAdRequest) {
      buffer.putUint8(_valueAdManagerAdRequest);
      writeValue(buffer, value.keywords);
      writeValue(buffer, value.contentUrl);
      writeValue(buffer, value.customTargeting);
      writeValue(buffer, value.customTargetingLists);
      writeValue(buffer, value.nonPersonalizedAds);
      writeValue(buffer, value.neighboringContentUrls);
      if (defaultTargetPlatform == TargetPlatform.android) {
        writeValue(buffer, value.httpTimeoutMillis);
      }
      writeValue(buffer, value.publisherProvidedId);
      writeValue(buffer, value.mediationExtrasIdentifier);
      writeValue(buffer, value.extras);
    } else if (value is AdRequest) {
      buffer.putUint8(_valueAdRequest);
      writeValue(buffer, value.keywords);
      writeValue(buffer, value.contentUrl);
      writeValue(buffer, value.nonPersonalizedAds);
      writeValue(buffer, value.neighboringContentUrls);
      if (defaultTargetPlatform == TargetPlatform.android) {
        writeValue(buffer, value.httpTimeoutMillis);
      }
      writeValue(buffer, value.mediationExtrasIdentifier);
      writeValue(buffer, value.extras);
    } else if (value is RewardItem) {
      buffer.putUint8(_valueRewardItem);
      writeValue(buffer, value.amount);
      writeValue(buffer, value.type);
    } else if (value is ResponseInfo) {
      buffer.putUint8(_valueResponseInfo);
      writeValue(buffer, value.responseId);
      writeValue(buffer, value.mediationAdapterClassName);
      writeValue(buffer, value.adapterResponses);
      writeValue(buffer, value.loadedAdapterResponseInfo);
      writeValue(buffer, value.responseExtras);
    } else if (value is AdapterResponseInfo) {
      buffer.putUint8(_valueAdapterResponseInfo);
      writeValue(buffer, value.adapterClassName);
      writeValue(buffer, value.latencyMillis);
      writeValue(buffer, value.description);
      writeValue(buffer, value.adUnitMapping);
      writeValue(buffer, value.adError);
      writeValue(buffer, value.adSourceName);
      writeValue(buffer, value.adSourceId);
      writeValue(buffer, value.adSourceInstanceName);
      writeValue(buffer, value.adSourceInstanceId);
    } else if (value is LoadAdError) {
      buffer.putUint8(_valueLoadAdError);
      writeValue(buffer, value.code);
      writeValue(buffer, value.domain);
      writeValue(buffer, value.message);
      writeValue(buffer, value.responseInfo);
    } else if (value is AdError) {
      buffer.putUint8(_valueAdError);
      writeValue(buffer, value.code);
      writeValue(buffer, value.domain);
      writeValue(buffer, value.message);
    } else if (value is AdapterInitializationState) {
      buffer.putUint8(_valueInitializationState);
      writeValue(buffer, describeEnum(value));
    } else if (value is AdapterStatus) {
      buffer.putUint8(_valueAdapterStatus);
      writeValue(buffer, value.state);
      writeValue(buffer, value.description);
      writeValue(buffer, value.latency);
    } else if (value is InitializationStatus) {
      buffer.putUint8(_valueInitializationStatus);
      writeValue(buffer, value.adapterStatuses);
    } else if (value is ServerSideVerificationOptions) {
      buffer.putUint8(_valueServerSideVerificationOptions);
      writeValue(buffer, value.userId);
      writeValue(buffer, value.customData);
    } else if (value is NativeAdOptions) {
      buffer.putUint8(_valueNativeAdOptions);
      writeValue(buffer, value.adChoicesPlacement?.intValue);
      writeValue(buffer, value.mediaAspectRatio?.intValue);
      writeValue(buffer, value.videoOptions);
      writeValue(buffer, value.requestCustomMuteThisAd);
      writeValue(buffer, value.shouldRequestMultipleImages);
      writeValue(buffer, value.shouldReturnUrlsForImageAssets);
    } else if (value is VideoOptions) {
      buffer.putUint8(_valueVideoOptions);
      writeValue(buffer, value.clickToExpandRequested);
      writeValue(buffer, value.customControlsRequested);
      writeValue(buffer, value.startMuted);
    } else if (value is RequestConfiguration) {
      buffer.putUint8(_valueRequestConfigurationParams);
      writeValue(buffer, value.maxAdContentRating);
      writeValue(buffer, value.tagForChildDirectedTreatment);
      writeValue(buffer, value.tagForUnderAgeOfConsent);
      writeValue(buffer, value.testDeviceIds);
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  dynamic readValueOfType(dynamic type, ReadBuffer buffer) {
    switch (type) {
      case _valueInlineAdaptiveBannerAdSize:
        final num width = readValueOfType(buffer.getUint8(), buffer);
        final num? maxHeight = readValueOfType(buffer.getUint8(), buffer);
        final num? orientation = readValueOfType(buffer.getUint8(), buffer);
        if (orientation != null) {
          return orientation.toInt() == 0
              ? AdSize.getPortraitInlineAdaptiveBannerAdSize(width.toInt())
              : AdSize.getLandscapeInlineAdaptiveBannerAdSize(width.toInt());
        } else if (maxHeight != null) {
          return AdSize.getInlineAdaptiveBannerAdSize(
              width.toInt(), maxHeight.toInt());
        } else {
          return AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(
              width.toInt());
        }

      case _valueAnchoredAdaptiveBannerAdSize:
        final String? orientationStr =
            readValueOfType(buffer.getUint8(), buffer);
        final num width = readValueOfType(buffer.getUint8(), buffer);
        Orientation? orientation;
        if (orientationStr != null) {
          orientation = Orientation.values.firstWhere(
            (Orientation orientation) =>
                describeEnum(orientation) == orientationStr,
          );
        }
        return AnchoredAdaptiveBannerAdSize(
          orientation,
          width: width.truncate(),
          height: -1, // Unused value
        );
      case _valueSmartBannerAdSize:
        final String orientationStr =
            readValueOfType(buffer.getUint8(), buffer);
        return SmartBannerAdSize(
          Orientation.values.firstWhere(
            (Orientation orientation) =>
                describeEnum(orientation) == orientationStr,
          ),
        );
      case _valueAdSize:
        num width = readValueOfType(buffer.getUint8(), buffer);
        num height = readValueOfType(buffer.getUint8(), buffer);
        return AdSize(
          width: width.toInt(),
          height: height.toInt(),
        );
      case _valueFluidAdSize:
        return FluidAdSize();
      case _valueAdRequest:
        return AdRequest(
          keywords: readValueOfType(buffer.getUint8(), buffer)?.cast<String>(),
          contentUrl: readValueOfType(buffer.getUint8(), buffer),
          nonPersonalizedAds: readValueOfType(buffer.getUint8(), buffer),
          neighboringContentUrls:
              readValueOfType(buffer.getUint8(), buffer)?.cast<String>(),
          httpTimeoutMillis: (defaultTargetPlatform == TargetPlatform.android)
              ? readValueOfType(buffer.getUint8(), buffer)
              : null,
          mediationExtrasIdentifier: readValueOfType(buffer.getUint8(), buffer),
          extras: readValueOfType(buffer.getUint8(), buffer)
              ?.cast<String, String>(),
        );
      case _valueRewardItem:
        return RewardItem(
          readValueOfType(buffer.getUint8(), buffer),
          readValueOfType(buffer.getUint8(), buffer),
        );
      case _valueResponseInfo:
        return ResponseInfo(
          responseId: readValueOfType(buffer.getUint8(), buffer),
          mediationAdapterClassName: readValueOfType(buffer.getUint8(), buffer),
          adapterResponses: readValueOfType(buffer.getUint8(), buffer)
              ?.cast<AdapterResponseInfo>(),
          loadedAdapterResponseInfo: readValueOfType(buffer.getUint8(), buffer),
          responseExtras: _deepCastStringKeyDynamicValueMap(
              readValueOfType(buffer.getUint8(), buffer)),
        );
      case _valueAdapterResponseInfo:
        return AdapterResponseInfo(
            adapterClassName: _safeReadString(buffer),
            latencyMillis: readValueOfType(buffer.getUint8(), buffer),
            description: _safeReadString(buffer),
            adUnitMapping:
                _deepCastStringMap(readValueOfType(buffer.getUint8(), buffer)),
            adError: readValueOfType(buffer.getUint8(), buffer),
            adSourceName: _safeReadString(buffer),
            adSourceId: _safeReadString(buffer),
            adSourceInstanceName: _safeReadString(buffer),
            adSourceInstanceId: _safeReadString(buffer));
      case _valueLoadAdError:
        return LoadAdError(
          readValueOfType(buffer.getUint8(), buffer),
          readValueOfType(buffer.getUint8(), buffer),
          readValueOfType(buffer.getUint8(), buffer),
          readValueOfType(buffer.getUint8(), buffer),
        );
      case _valueAdError:
        return AdError(
            readValueOfType(buffer.getUint8(), buffer),
            readValueOfType(buffer.getUint8(), buffer),
            readValueOfType(buffer.getUint8(), buffer));
      case _valueAdManagerAdRequest:
        return AdManagerAdRequest(
          keywords: readValueOfType(buffer.getUint8(), buffer)?.cast<String>(),
          contentUrl: readValueOfType(buffer.getUint8(), buffer),
          customTargeting: readValueOfType(buffer.getUint8(), buffer)
              ?.cast<String, String>(),
          customTargetingLists: _tryDeepMapCast<String>(
            readValueOfType(buffer.getUint8(), buffer),
          ),
          nonPersonalizedAds: readValueOfType(buffer.getUint8(), buffer),
          neighboringContentUrls:
              readValueOfType(buffer.getUint8(), buffer)?.cast<String>(),
          httpTimeoutMillis: (defaultTargetPlatform == TargetPlatform.android)
              ? readValueOfType(buffer.getUint8(), buffer)
              : null,
          publisherProvidedId: readValueOfType(buffer.getUint8(), buffer),
          mediationExtrasIdentifier: readValueOfType(buffer.getUint8(), buffer),
          extras: readValueOfType(buffer.getUint8(), buffer)
              ?.cast<String, String>(),
        );
      case _valueInitializationState:
        switch (readValueOfType(buffer.getUint8(), buffer)) {
          case 'notReady':
            return AdapterInitializationState.notReady;
          case 'ready':
            return AdapterInitializationState.ready;
        }
        throw ArgumentError();
      case _valueAdapterStatus:
        final AdapterInitializationState state =
            readValueOfType(buffer.getUint8(), buffer);
        final String description = readValueOfType(buffer.getUint8(), buffer);

        double latency = readValueOfType(buffer.getUint8(), buffer).toDouble();
        // Android provides this value as an int in milliseconds while iOS
        // provides this value as a double in seconds.
        if (defaultTargetPlatform == TargetPlatform.android) {
          latency /= 1000;
        }

        return AdapterStatus(state, description, latency);
      case _valueInitializationStatus:
        return InitializationStatus(
          readValueOfType(buffer.getUint8(), buffer)
              .cast<String, AdapterStatus>(),
        );
      case _valueServerSideVerificationOptions:
        return ServerSideVerificationOptions(
            userId: readValueOfType(buffer.getUint8(), buffer),
            customData: readValueOfType(buffer.getUint8(), buffer));
      case _valueNativeAdOptions:
        int? adChoices = readValueOfType(buffer.getUint8(), buffer);
        int? mediaAspectRatio = readValueOfType(buffer.getUint8(), buffer);
        return NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacementExtension.fromInt(adChoices),
          mediaAspectRatio: MediaAspectRatioExtension.fromInt(mediaAspectRatio),
          videoOptions: readValueOfType(buffer.getUint8(), buffer),
          requestCustomMuteThisAd: readValueOfType(buffer.getUint8(), buffer),
          shouldRequestMultipleImages:
              readValueOfType(buffer.getUint8(), buffer),
          shouldReturnUrlsForImageAssets:
              readValueOfType(buffer.getUint8(), buffer),
        );
      case _valueVideoOptions:
        return VideoOptions(
          clickToExpandRequested: readValueOfType(buffer.getUint8(), buffer),
          customControlsRequested: readValueOfType(buffer.getUint8(), buffer),
          startMuted: readValueOfType(buffer.getUint8(), buffer),
        );
      case _valueRequestConfigurationParams:
        return RequestConfiguration(
          maxAdContentRating: readValueOfType(buffer.getUint8(), buffer),
          tagForChildDirectedTreatment:
              readValueOfType(buffer.getUint8(), buffer),
          tagForUnderAgeOfConsent: readValueOfType(buffer.getUint8(), buffer),
          testDeviceIds:
              readValueOfType(buffer.getUint8(), buffer).cast<String>(),
        );
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  Map<String, List<T>>? _tryDeepMapCast<T>(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    return map.map<String, List<T>>(
      (dynamic key, dynamic value) => MapEntry<String, List<T>>(
        key,
        value?.cast<T>(),
      ),
    );
  }

  Map<String, String> _deepCastStringMap(Map<dynamic, dynamic>? map) {
    if (map == null) return {};
    return map.map<String, String>(
      (dynamic key, dynamic value) => MapEntry<String, String>(
        key,
        value,
      ),
    );
  }

  Map<String, dynamic> _deepCastStringKeyDynamicValueMap(
      Map<dynamic, dynamic>? map) {
    if (map == null) return {};
    return map.map<String, dynamic>(
      (dynamic key, dynamic value) => MapEntry<String, dynamic>(
        key,
        value,
      ),
    );
  }

  /// Reads the next value as a non-nullable string.
  ///
  /// Returns '' if the next value is null.
  String _safeReadString(ReadBuffer buffer) {
    return readValueOfType(buffer.getUint8(), buffer) ?? '';
  }

  void writeAdSize(WriteBuffer buffer, AdSize value) {
    if (value is InlineAdaptiveSize) {
      buffer.putUint8(_valueInlineAdaptiveBannerAdSize);
      writeValue(buffer, value.width);
      writeValue(buffer, value.maxHeight);
      writeValue(buffer, value.orientationValue);
    } else if (value is AnchoredAdaptiveBannerAdSize) {
      buffer.putUint8(_valueAnchoredAdaptiveBannerAdSize);
      var orientationValue;
      if (value.orientation != null) {
        orientationValue = describeEnum(value.orientation as Orientation);
      }
      writeValue(buffer, orientationValue);
      writeValue(buffer, value.width);
    } else if (value is SmartBannerAdSize) {
      buffer.putUint8(_valueSmartBannerAdSize);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        writeValue(buffer, describeEnum(value.orientation));
      }
    } else if (value is FluidAdSize) {
      buffer.putUint8(_valueFluidAdSize);
    } else {
      buffer.putUint8(_valueAdSize);
      writeValue(buffer, value.width);
      writeValue(buffer, value.height);
    }
  }
}

/// An extension that maps each [MediaAspectRatio] to an int.
extension MediaAspectRatioExtension on MediaAspectRatio {
  /// Gets the int mapping to pass to platform channel.
  int get intValue {
    switch (this) {
      case MediaAspectRatio.unknown:
        return 0;
      case MediaAspectRatio.any:
        return 1;
      case MediaAspectRatio.landscape:
        return 2;
      case MediaAspectRatio.portrait:
        return 3;
      case MediaAspectRatio.square:
        return 4;
    }
  }

  /// Maps an int back to [MediaAspectRatio].
  static MediaAspectRatio? fromInt(int? intValue) {
    switch (intValue) {
      case 0:
        return MediaAspectRatio.unknown;
      case 1:
        return MediaAspectRatio.any;
      case 2:
        return MediaAspectRatio.landscape;
      case 3:
        return MediaAspectRatio.portrait;
      case 4:
        return MediaAspectRatio.square;
      default:
        return null;
    }
  }
}

/// An extension that maps each [AdChoicesPlacement] to an int.
extension AdChoicesPlacementExtension on AdChoicesPlacement {
  /// Gets the int mapping to pass to platform channel.
  int get intValue {
    switch (this) {
      case AdChoicesPlacement.topRightCorner:
        return 0;
      case AdChoicesPlacement.topLeftCorner:
        return 1;
      case AdChoicesPlacement.bottomRightCorner:
        return 2;
      case AdChoicesPlacement.bottomLeftCorner:
        return 3;
    }
  }

  /// Maps an int back to [AdChoicesPlacement].
  static AdChoicesPlacement? fromInt(int? intValue) {
    switch (intValue) {
      case 0:
        return AdChoicesPlacement.topRightCorner;
      case 1:
        return AdChoicesPlacement.topLeftCorner;
      case 2:
        return AdChoicesPlacement.bottomRightCorner;
      case 3:
        return AdChoicesPlacement.bottomLeftCorner;
      default:
        return null;
    }
  }
}

class _BiMap<K extends Object, V extends Object> extends MapBase<K, V> {
  _BiMap() {
    _inverse = _BiMap<V, K>._inverse(this);
  }

  _BiMap._inverse(this._inverse);

  final Map<K, V> _map = <K, V>{};
  late _BiMap<V, K> _inverse;

  _BiMap<V, K> get inverse => _inverse;

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(K key, V value) {
    assert(!_map.containsKey(key));
    assert(!inverse.containsKey(value));
    _map[key] = value;
    inverse._map[value] = key;
  }

  @override
  void clear() {
    _map.clear();
    inverse._map.clear();
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V? remove(Object? key) {
    if (key == null) return null;
    final V? value = _map[key];
    inverse._map.remove(value);
    return _map.remove(key);
  }
}
