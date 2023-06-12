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

import 'package:meta/meta.dart';

import 'ad_containers.dart';

/// The callback type to handle an event occurring for an [Ad].
typedef AdEventCallback = void Function(Ad ad);

/// Generic callback type for an event occurring on an Ad.
typedef GenericAdEventCallback<Ad> = void Function(Ad ad);

/// A callback type for when an error occurs loading a full screen ad.
typedef FullScreenAdLoadErrorCallback = void Function(LoadAdError error);

/// The callback type for when a user earns a reward.
typedef OnUserEarnedRewardCallback = void Function(
    AdWithoutView ad, RewardItem reward);

/// The callback type to handle an error loading an [Ad].
typedef AdLoadErrorCallback = void Function(Ad ad, LoadAdError error);

/// The callback type for when an ad receives revenue value.
typedef OnPaidEventCallback = void Function(
    Ad ad, double valueMicros, PrecisionType precision, String currencyCode);

/// The callback type for when a fluid ad's height changes.
typedef OnFluidAdHeightChangedListener = void Function(
    FluidAdManagerBannerAd ad, double height);

/// Allowed constants for precision type in [OnPaidEventCallback].
enum PrecisionType {
  /// An ad value with unknown precision.
  unknown,

  /// An ad value estimated from aggregated data.
  estimated,

  /// A publisher-provided ad value, such as manual CPMs in a mediation group.
  publisherProvided,

  /// The precise value paid for this ad.
  precise
}

/// Listener for app events.
class AppEventListener {
  /// Called when an app event is received.
  void Function(Ad ad, String name, String data)? onAppEvent;
}

/// Shared event callbacks used in Native and Banner ads.
abstract class AdWithViewListener {
  /// Default constructor for [AdWithViewListener], meant to be used by subclasses.
  @protected
  const AdWithViewListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdOpened,
    this.onAdWillDismissScreen,
    this.onAdImpression,
    this.onAdClosed,
    this.onPaidEvent,
    this.onAdClicked,
  });

  /// Called when an ad is successfully received.
  final AdEventCallback? onAdLoaded;

  /// Called when an ad request failed.
  final AdLoadErrorCallback? onAdFailedToLoad;

  /// A full screen view/overlay is presented in response to the user clicking
  /// on an ad. You may want to pause animations and time sensitive
  /// interactions.
  final AdEventCallback? onAdOpened;

  /// For iOS only. Called before dismissing a full screen view.
  final AdEventCallback? onAdWillDismissScreen;

  /// Called when the full screen view has been closed. You should restart
  /// anything paused while handling onAdOpened.
  final AdEventCallback? onAdClosed;

  /// Called when an impression occurs on the ad.
  final AdEventCallback? onAdImpression;

  /// Called when the ad is clicked.
  final AdEventCallback? onAdClicked;

  /// Callback to be invoked when an ad is estimated to have earned money.
  /// Available for allowlisted accounts only.
  final OnPaidEventCallback? onPaidEvent;
}

/// A listener for receiving notifications for the lifecycle of a [BannerAd].
class BannerAdListener extends AdWithViewListener {
  /// Constructs a [BannerAdListener] that notifies for the provided event callbacks.
  ///
  /// Typically you will override [onAdLoaded] and [onAdFailedToLoad]:
  /// ```dart
  /// BannerAdListener(
  ///   onAdLoaded: (ad) {
  ///     // Ad successfully loaded - display an AdWidget with the banner ad.
  ///   },
  ///   onAdFailedToLoad: (ad, error) {
  ///     // Ad failed to load - log the error and dispose the ad.
  ///   },
  ///   ...
  /// )
  /// ```
  const BannerAdListener({
    AdEventCallback? onAdLoaded,
    AdLoadErrorCallback? onAdFailedToLoad,
    AdEventCallback? onAdOpened,
    AdEventCallback? onAdClosed,
    AdEventCallback? onAdWillDismissScreen,
    AdEventCallback? onAdImpression,
    OnPaidEventCallback? onPaidEvent,
    AdEventCallback? onAdClicked,
  }) : super(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          onAdOpened: onAdOpened,
          onAdClosed: onAdClosed,
          onAdWillDismissScreen: onAdWillDismissScreen,
          onAdImpression: onAdImpression,
          onPaidEvent: onPaidEvent,
          onAdClicked: onAdClicked,
        );
}

/// A listener for receiving notifications for the lifecycle of an [AdManagerBannerAd].
class AdManagerBannerAdListener extends BannerAdListener
    implements AppEventListener {
  /// Constructs an [AdManagerBannerAdListener] with the provided event callbacks.
  ///
  /// Typically you will override [onAdLoaded] and [onAdFailedToLoad]:
  /// ```dart
  /// AdManagerBannerAdListener(
  ///   onAdLoaded: (ad) {
  ///     // Ad successfully loaded - display an AdWidget with the banner ad.
  ///   },
  ///   onAdFailedToLoad: (ad, error) {
  ///     // Ad failed to load - log the error and dispose the ad.
  ///   },
  ///   ...
  /// )
  /// ```
  AdManagerBannerAdListener({
    AdEventCallback? onAdLoaded,
    Function(Ad ad, LoadAdError error)? onAdFailedToLoad,
    AdEventCallback? onAdOpened,
    AdEventCallback? onAdWillDismissScreen,
    AdEventCallback? onAdClosed,
    AdEventCallback? onAdImpression,
    OnPaidEventCallback? onPaidEvent,
    this.onAppEvent,
    AdEventCallback? onAdClicked,
  }) : super(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
          onAdOpened: onAdOpened,
          onAdWillDismissScreen: onAdWillDismissScreen,
          onAdClosed: onAdClosed,
          onAdImpression: onAdImpression,
          onPaidEvent: onPaidEvent,
          onAdClicked: onAdClicked,
        );

  /// Called when an app event is received.
  @override
  void Function(Ad ad, String name, String data)? onAppEvent;
}

/// A listener for receiving notifications for the lifecycle of a [NativeAd].
class NativeAdListener extends AdWithViewListener {
  /// Constructs a [NativeAdListener] with the provided event callbacks.
  ///
  /// Typically you will override [onAdLoaded] and [onAdFailedToLoad]:
  /// ```dart
  /// NativeAdListener(
  ///   onAdLoaded: (ad) {
  ///     // Ad successfully loaded - display an AdWidget with the native ad.
  ///   },
  ///   onAdFailedToLoad: (ad, error) {
  ///     // Ad failed to load - log the error and dispose the ad.
  ///   },
  ///   ...
  /// )
  /// ```
  NativeAdListener({
    AdEventCallback? onAdLoaded,
    Function(Ad ad, LoadAdError error)? onAdFailedToLoad,
    AdEventCallback? onAdOpened,
    AdEventCallback? onAdWillDismissScreen,
    AdEventCallback? onAdClosed,
    AdEventCallback? onAdImpression,
    OnPaidEventCallback? onPaidEvent,
    AdEventCallback? onAdClicked,
  }) : super(
            onAdLoaded: onAdLoaded,
            onAdFailedToLoad: onAdFailedToLoad,
            onAdOpened: onAdOpened,
            onAdWillDismissScreen: onAdWillDismissScreen,
            onAdClosed: onAdClosed,
            onAdImpression: onAdImpression,
            onPaidEvent: onPaidEvent,
            onAdClicked: onAdClicked);
}

/// Callback events for for full screen ads, such as Rewarded and Interstitial.
class FullScreenContentCallback<Ad> {
  /// Construct a new [FullScreenContentCallback].
  ///
  /// [Ad.dispose] should be called from [onAdFailedToShowFullScreenContent]
  /// and [onAdDismissedFullScreenContent], in order to free up resources.
  const FullScreenContentCallback({
    this.onAdShowedFullScreenContent,
    this.onAdImpression,
    this.onAdFailedToShowFullScreenContent,
    this.onAdWillDismissFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdClicked,
  });

  /// Called when an ad shows full screen content.
  final GenericAdEventCallback<Ad>? onAdShowedFullScreenContent;

  /// Called when an ad dismisses full screen content.
  final GenericAdEventCallback<Ad>? onAdDismissedFullScreenContent;

  /// For iOS only. Called before dismissing a full screen view.
  final GenericAdEventCallback<Ad>? onAdWillDismissFullScreenContent;

  /// Called when an ad impression occurs.
  final GenericAdEventCallback<Ad>? onAdImpression;

  /// Called when an ad is clicked.
  final GenericAdEventCallback<Ad>? onAdClicked;

  /// Called when ad fails to show full screen content.
  final void Function(Ad ad, AdError error)? onAdFailedToShowFullScreenContent;
}

/// Generic parent class for ad load callbacks.
abstract class FullScreenAdLoadCallback<T> {
  /// Default constructor for [FullScreenAdLoadCallback[, used by subclasses.
  const FullScreenAdLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });

  /// Called when the ad successfully loads.
  final GenericAdEventCallback<T> onAdLoaded;

  /// Called when an error occurs loading the ad.
  final FullScreenAdLoadErrorCallback onAdFailedToLoad;
}

/// This class holds callbacks for loading a [RewardedAd].
class RewardedAdLoadCallback extends FullScreenAdLoadCallback<RewardedAd> {
  /// Construct a [RewardedAdLoadCallback].
  const RewardedAdLoadCallback({
    required GenericAdEventCallback<RewardedAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
  }) : super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
}

/// This class holds callbacks for loading an [AppOpenAd].
class AppOpenAdLoadCallback extends FullScreenAdLoadCallback<AppOpenAd> {
  /// Construct an [AppOpenAdLoadCallback].
  const AppOpenAdLoadCallback({
    required GenericAdEventCallback<AppOpenAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
  }) : super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
}

/// This class holds callbacks for loading an [InterstitialAd].
class InterstitialAdLoadCallback
    extends FullScreenAdLoadCallback<InterstitialAd> {
  /// Construct a [InterstitialAdLoadCallback].
  const InterstitialAdLoadCallback({
    required GenericAdEventCallback<InterstitialAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
  }) : super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
}

/// This class holds callbacks for loading an [AdManagerInterstitialAd].
class AdManagerInterstitialAdLoadCallback
    extends FullScreenAdLoadCallback<AdManagerInterstitialAd> {
  /// Construct a [AdManagerInterstitialAdLoadCallback].
  const AdManagerInterstitialAdLoadCallback({
    required GenericAdEventCallback<AdManagerInterstitialAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
  }) : super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
}

/// This class holds callbacks for loading a [RewardedInterstitialAd].
class RewardedInterstitialAdLoadCallback
    extends FullScreenAdLoadCallback<RewardedInterstitialAd> {
  /// Construct a [RewardedInterstitialAdLoadCallback].
  const RewardedInterstitialAdLoadCallback({
    required GenericAdEventCallback<RewardedInterstitialAd> onAdLoaded,
    required FullScreenAdLoadErrorCallback onAdFailedToLoad,
  }) : super(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
}
