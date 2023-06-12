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

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'ad_instance_manager.dart';
import 'ad_listeners.dart';

/// Error information about why an ad operation failed.
class AdError {
  /// Creates an [AdError] with the given [code], [domain] and [message].
  @protected
  AdError(this.code, this.domain, this.message);

  /// Unique code to identify the error.
  ///
  /// See links below for possible error codes:
  /// Android:
  ///   https://developers.google.com/android/reference/com/google/android/gms/ads/AdRequest#constant-summary
  /// Ios:
  ///   https://developers.google.com/admob/ios/api/reference/Enums/GADErrorCode
  final int code;

  /// The domain from which the error came.
  final String domain;

  /// A message detailing the error.
  ///
  /// For example "Account not approved yet". See
  /// https://support.google.com/admob/answer/9905175 for explanations of
  /// common errors.
  final String message;

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message)';
  }
}

/// Contains information about the loaded ad or ad request.
///
/// For debugging and logging purposes. See
/// https://developers.google.com/admob/android/response-info for more
/// information on how this can be used.
class ResponseInfo {
  /// Constructs a [ResponseInfo] with the [responseId] and [mediationAdapterClassName].
  @protected
  const ResponseInfo(
      {this.responseId,
      this.mediationAdapterClassName,
      this.adapterResponses,
      this.loadedAdapterResponseInfo,
      required this.responseExtras});

  /// An identifier for the loaded ad.
  final String? responseId;

  /// The mediation adapter class name of the ad network that loaded the ad.
  final String? mediationAdapterClassName;

  /// The [AdapterResponseInfo]s containing metadata for each adapter included
  /// in the ad response.
  ///
  /// Can be used to debug the mediation waterfall execution.
  final List<AdapterResponseInfo>? adapterResponses;

  /// The [AdapterResponseInfo] of the adapter that was used to load the ad.
  ///
  /// This is null if the ad failed to load.
  final AdapterResponseInfo? loadedAdapterResponseInfo;

  /// Map of extra information about the ad response.
  final Map<String, dynamic> responseExtras;

  @override
  String toString() {
    return '$runtimeType(responseId: $responseId, '
        'mediationAdapterClassName: $mediationAdapterClassName, '
        'adapterResponses: $adapterResponses, '
        'loadedAdapterResponseInfo: $loadedAdapterResponseInfo), '
        'responseExtras: $responseExtras';
  }
}

/// Response information for an individual ad network in an ad response.
class AdapterResponseInfo {
  /// Constructs an [AdapterResponseInfo].
  @protected
  AdapterResponseInfo({
    required this.adapterClassName,
    required this.latencyMillis,
    required this.description,
    required this.adUnitMapping,
    required this.adSourceName,
    required this.adSourceId,
    required this.adSourceInstanceName,
    required this.adSourceInstanceId,
    this.adError,
  });

  /// A class name that identifies the ad network adapter.
  final String adapterClassName;

  /// The amount of time the ad network adapter spent loading an ad.
  ///
  /// 0 if the adapter was not attempted.
  final int latencyMillis;

  /// A log friendly string version of this object.
  final String description;

  /// Network configuration set on the AdMob UI.
  final Map<String, String> adUnitMapping;

  /// The error that occurred while rendering the ad.
  final AdError? adError;

  /// The ad source name associated with this adapter response.
  ///
  /// This is an empty string "" if the ad server did not populate this field.
  final String adSourceName;

  /// The ad source ID associated with this adapter response.
  ///
  /// This is an empty string "" if the ad server did not populate this field.
  final String adSourceId;

  /// The ad source instance name associated with this adapter response.
  ///
  /// This is an empty string "" if the ad server did not populate this field.
  final String adSourceInstanceName;

  /// The ad source instance id associated with this adapter response.
  ///
  /// This is an empty string "" if the ad server did not populate this field.
  final String adSourceInstanceId;
  @override
  String toString() {
    return '$runtimeType(adapterClassName: $adapterClassName, '
        'latencyMillis: $latencyMillis, '
        'description: $description, '
        'adUnitMapping: $adUnitMapping, '
        'adError: $adError, '
        'adSourceName: $adSourceName, '
        'adSourceId: $adSourceId, '
        'adSourceInstanceName: $adSourceInstanceName, '
        'adSourceInstanceId: $adSourceInstanceId)';
  }
}

/// Represents errors that occur when loading an ad.
class LoadAdError extends AdError {
  /// Default constructor for [LoadAdError].
  @protected
  LoadAdError(int code, String domain, String message, this.responseInfo)
      : super(code, domain, message);

  /// The [ResponseInfo] for the error.
  final ResponseInfo? responseInfo;

  @override
  String toString() {
    return '$runtimeType(code: $code, domain: $domain, message: $message'
        ', responseInfo: $responseInfo)';
  }
}

/// Targeting info per the AdMob API.
///
/// This class's properties mirror the native AdRequest API. See for example:
/// [AdRequest.Builder for Android](https://developers.google.com/android/reference/com/google/android/gms/ads/AdRequest.Builder).
class AdRequest {
  /// Default constructor for [AdRequest].
  const AdRequest({
    this.keywords,
    this.contentUrl,
    this.neighboringContentUrls,
    this.nonPersonalizedAds,
    this.httpTimeoutMillis,
    this.mediationExtrasIdentifier,
    this.extras,
  });

  /// Words or phrases describing the current user activity.
  final List<String>? keywords;

  /// URL string for a webpage whose content matches the app’s primary content.
  ///
  /// This webpage content is used for targeting and brand safety purposes.
  final String? contentUrl;

  /// URLs representing web content near an ad.
  final List<String>? neighboringContentUrls;

  /// Non-personalized ads are ads that are not based on a user’s past behavior.
  ///
  /// For more information:
  /// https://support.google.com/admob/answer/7676680?hl=en
  final bool? nonPersonalizedAds;

  /// A custom timeout for HTTPS calls during an ad request.
  ///
  /// This is only supported in Android. This value is ignored on iOS.
  final int? httpTimeoutMillis;

  /// String identifier used in providing mediation extras.
  ///
  /// Only relevant if you use mediation and need to provide network extras
  /// to the ad request. This identifier will get passed to your platform-side
  /// mediation extras factory class, allowing for additional customization
  /// of network extras.
  final String? mediationExtrasIdentifier;

  /// Extras to pass to the AdMob adapter.
  final Map<String, String>? extras;

  @override
  bool operator ==(Object other) {
    return other is AdRequest &&
        listEquals<String>(keywords, other.keywords) &&
        contentUrl == other.contentUrl &&
        nonPersonalizedAds == other.nonPersonalizedAds &&
        listEquals(neighboringContentUrls, other.neighboringContentUrls) &&
        httpTimeoutMillis == other.httpTimeoutMillis &&
        mediationExtrasIdentifier == other.mediationExtrasIdentifier &&
        mapEquals<String, String>(extras, other.extras);
  }
}

/// Targeting info per the Ad Manager API.
class AdManagerAdRequest extends AdRequest {
  /// Constructs an [AdManagerAdRequest] from optional targeting information.
  const AdManagerAdRequest({
    List<String>? keywords,
    String? contentUrl,
    List<String>? neighboringContentUrls,
    this.customTargeting,
    this.customTargetingLists,
    bool? nonPersonalizedAds,
    int? httpTimeoutMillis,
    this.publisherProvidedId,
    String? mediationExtrasIdentifier,
    Map<String, String>? extras,
  }) : super(
          keywords: keywords,
          contentUrl: contentUrl,
          neighboringContentUrls: neighboringContentUrls,
          nonPersonalizedAds: nonPersonalizedAds,
          httpTimeoutMillis: httpTimeoutMillis,
          mediationExtrasIdentifier: mediationExtrasIdentifier,
          extras: extras,
        );

  /// Key-value pairs used for custom targeting.
  final Map<String, String>? customTargeting;

  /// Key-value pairs used for custom targeting.
  ///
  /// Any duplicate keys from [customTargeting] will be overwritten.
  final Map<String, List<String>>? customTargetingLists;

  /// The identifier used for frequency capping, audience segmentation
  /// and targeting, sequential ad rotation, and other audience-based ad
  /// delivery controls across devices.
  final String? publisherProvidedId;

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is AdManagerAdRequest &&
        mapEquals<String, String>(customTargeting, other.customTargeting) &&
        customTargetingLists.toString() ==
            other.customTargetingLists.toString() &&
        publisherProvidedId == other.publisherProvidedId;
  }
}

/// An [AdSize] with the given width and a Google-optimized height to create a banner ad.
///
/// See:
///   [AdSize.getAnchoredAdaptiveBannerAdSize].
class AnchoredAdaptiveBannerAdSize extends AdSize {
  /// Default constructor for [AnchoredAdaptiveBannerAdSize].
  ///
  /// This constructor should only be used internally.
  ///
  /// See:
  ///   [AdSize.getAnchoredAdaptiveBannerAdSize].
  AnchoredAdaptiveBannerAdSize(
    this.orientation, {
    required int width,
    required int height,
  }) : super(width: width, height: height);

  /// Orientation of the device used by the SDK to automatically find the correct height.
  final Orientation? orientation;
}

/// Ad units that render screen-width banner ads on any screen size across different devices in either [Orientation].
@Deprecated('Use adaptive banner instead')
class SmartBannerAdSize extends AdSize {
  /// Default constructor for [SmartBannerAdSize].
  SmartBannerAdSize(this.orientation) : super(width: -1, height: -1);

  /// Orientation of the device used by the SDK to automatically find the correct height.
  final Orientation orientation;
}

/// A dynamically sized banner that matches its parent's width and content height.
class FluidAdSize extends AdSize {
  /// Default constructor for [FluidAdSize].
  const FluidAdSize() : super(width: -3, height: -3);
}

/// A size for inline adaptive banner ads.
///
/// This ad size takes a width and optionally a maximum height and orientation.
/// They will be rendered at the provided width and have variable height decided
/// by Google servers.
///
/// You can obtain an instance of this using factory methods such as
/// [AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(width)].
///
/// After an inline adaptive banner ad is loaded, you should use
/// [BannerAd.getPlatformAdSize] or [AdManagerBannerAd.getPlatformAdSize] to get
/// the height to use for the ad container.
class InlineAdaptiveSize extends AdSize {
  /// Private constructor for [InlineAdaptiveSize].
  ///
  /// You should use one of the static constructors in [AdSize].
  const InlineAdaptiveSize._({
    required int width,
    this.maxHeight,
    this.orientation,
  }) : super(width: width, height: 0);

  /// The maximum height allowed.
  final int? maxHeight;

  /// The orientation. If none if specified the current orientation is used.
  final Orientation? orientation;

  /// Representation of [orientation] to pass to platform code.
  int? get orientationValue => orientation == null
      ? null
      : orientation == Orientation.portrait
          ? 0
          : 1;
}

/// [AdSize] represents the size of a banner ad.
///
/// There are six sizes available, which are the same for both iOS and Android.
/// See the guides for banners on [Android](https://developers.google.com/admob/android/banner#banner_sizes)
/// and [iOS](https://developers.google.com/admob/ios/banner#banner_sizes) for
/// additional details.
class AdSize {
  /// Constructs an [AdSize] with the given [width] and [height].
  const AdSize({
    required this.width,
    required this.height,
  });

  /// The vertical span of an ad.
  final int height;

  /// The horizontal span of an ad.
  final int width;

  /// The standard banner (320x50) size.
  static const AdSize banner = AdSize(width: 320, height: 50);

  /// The large banner (320x100) size.
  static const AdSize largeBanner = AdSize(width: 320, height: 100);

  /// The medium rectangle (300x250) size.
  static const AdSize mediumRectangle = AdSize(width: 300, height: 250);

  /// The full banner (468x60) size.
  static const AdSize fullBanner = AdSize(width: 468, height: 60);

  /// The leaderboard (728x90) size.
  static const AdSize leaderboard = AdSize(width: 728, height: 90);

  /// A dynamically sized banner that matches its parent's width and expands/contracts its height to match the ad's content after loading completes.
  static const AdSize fluid = FluidAdSize();

  /// Ad units that render screen-width banner ads on any screen size across different devices in either [Orientation].
  ///
  /// Width of the current device can be found using:
  /// `MediaQuery.of(context).size.width.truncate()`.
  ///
  /// Returns `null` if a proper height could not be found for the device or
  /// window.
  static Future<AnchoredAdaptiveBannerAdSize?> getAnchoredAdaptiveBannerAdSize(
    Orientation orientation,
    int width,
  ) async {
    final num? height = await instanceManager.channel.invokeMethod<num?>(
      'AdSize#getAnchoredAdaptiveBannerAdSize',
      <String, Object?>{
        'orientation': describeEnum(orientation),
        'width': width,
      },
    );

    if (height == null) return null;
    return AnchoredAdaptiveBannerAdSize(
      orientation,
      width: width,
      height: height.truncate(),
    );
  }

  /// Returns an AdSize with the given width and a Google-optimized height to create a banner ad.
  ///
  /// The size returned will have an aspect ratio similar to AdSize, suitable for anchoring near the top or bottom of your app.
  /// The height will never be larger than 15% of the device's current orientation height and never smaller than 50px.
  /// This function always returns the same height for any width / device combination.
  /// For more details, visit: https://developers.google.com/android/reference/com/google/android/gms/ads/AdSize#getCurrentOrientationAnchoredAdaptiveBannerAdSize(android.content.Context,%20int)
  static Future<AnchoredAdaptiveBannerAdSize?>
      getCurrentOrientationAnchoredAdaptiveBannerAdSize(int width) async {
    final num? height = await instanceManager.channel.invokeMethod<num?>(
      'AdSize#getAnchoredAdaptiveBannerAdSize',
      <String, Object?>{
        'width': width,
      },
    );

    if (height == null) return null;
    return AnchoredAdaptiveBannerAdSize(
      null,
      width: width,
      height: height.truncate(),
    );
  }

  /// Gets an AdSize with the given width and height that is always 0.
  ///
  /// This ad size allows Google servers to choose an optimal ad size with a
  /// height less than or equal to the height of the screen in the current
  /// orientation.
  /// After the ad is loaded, you should update the height of the ad container
  /// by calling [BannerAd.getPlatformAdSize] or
  /// [AdManagerBannerAd.getPlatformAdSize] from the ad load callback.
  /// This ad size is most suitable for ads intended to be displayed inside
  /// scrollable content.
  static InlineAdaptiveSize getCurrentOrientationInlineAdaptiveBannerAdSize(
      int width) {
    return InlineAdaptiveSize._(width: width);
  }

  /// Gets an AdSize in landscape orientation with the given width and 0 height.
  ///
  /// This ad size allows Google servers to choose an optimal ad size with a
  /// height less than or equal to the height of the screen in landscape
  /// orientation.
  /// After the ad is loaded, you should update the height of the ad container
  /// by calling [BannerAd.getPlatformAdSize] or
  /// [AdManagerBannerAd.getPlatformAdSize] from the ad load callback.
  /// This ad size is most suitable for ads intended to be displayed inside
  /// scrollable content.
  static InlineAdaptiveSize getLandscapeInlineAdaptiveBannerAdSize(int width) {
    return InlineAdaptiveSize._(
        width: width, orientation: Orientation.landscape);
  }

  /// Gets an AdSize in portrait orientation with the given width and 0 height.
  ///
  /// This ad size allows Google servers to choose an optimal ad size with a
  /// height less than or equal to the height of the screen in portrait
  /// orientation.
  /// After the ad is loaded, you should update the height of the ad container
  /// by calling [BannerAd.getPlatformAdSize] or
  /// [AdManagerBannerAd.getPlatformAdSize] from the ad load callback.
  /// This ad size is most suitable for ads intended to be displayed inside
  /// scrollable content.
  static InlineAdaptiveSize getPortraitInlineAdaptiveBannerAdSize(int width) {
    return InlineAdaptiveSize._(
        width: width, orientation: Orientation.portrait);
  }

  /// Gets an AdSize with the given width and height that is always 0.
  ///
  /// This ad size allows Google servers to choose an optimal ad size with a
  /// height less than or equal to [maxHeight].
  /// After the ad is loaded, you should update the height of the ad container
  /// by calling [BannerAd.getPlatformAdSize] or
  /// [AdManagerBannerAd.getPlatformAdSize] from the ad load callback.
  /// This ad size is most suitable for ads intended to be displayed inside
  /// scrollable content.
  static InlineAdaptiveSize getInlineAdaptiveBannerAdSize(
      int width, int maxHeight) {
    return InlineAdaptiveSize._(width: width, maxHeight: maxHeight);
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in either orientation on Android.
  @Deprecated('Use adaptive banner instead')
  static AdSize get smartBanner {
    assert(defaultTargetPlatform == TargetPlatform.android);
    // Orientation is not used on Android.
    return smartBannerPortrait;
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in portrait on iOS.
  @Deprecated('Use adaptive banner instead')
  static AdSize get smartBannerPortrait {
    return getSmartBanner(Orientation.portrait);
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in landscape on iOS.
  @Deprecated('Use adaptive banner instead')
  static AdSize get smartBannerLandscape {
    return getSmartBanner(Orientation.landscape);
  }

  /// Ad units that render screen-width banner ads on any screen size across different devices in either [Orientation].
  @Deprecated('Use adaptive banner instead')
  static SmartBannerAdSize getSmartBanner(Orientation orientation) {
    return SmartBannerAdSize(orientation);
  }

  @override
  bool operator ==(Object other) {
    return other is AdSize && width == other.width && height == other.height;
  }
}

/// The base class for all ads.
///
/// A valid [adUnitId] is required.
abstract class Ad {
  /// Default constructor, used by subclasses.
  Ad({required this.adUnitId, this.responseInfo});

  /// Identifies the source of [Ad]s for your application.
  ///
  /// For testing use a [sample ad unit](https://developers.google.com/admob/ios/test-ads#sample_ad_units).
  final String adUnitId;

  /// Frees the plugin resources associated with this ad.
  Future<void> dispose() {
    return instanceManager.disposeAd(this);
  }

  /// Contains information about the loaded request.
  ///
  /// Only present if the ad has been successfully loaded.
  ResponseInfo? responseInfo;
}

/// Base class for mobile [Ad] that has an in-line view.
///
/// A valid [adUnitId] and [size] are required.
abstract class AdWithView extends Ad {
  /// Default constructor, used by subclasses.
  AdWithView({required String adUnitId, required this.listener})
      : super(adUnitId: adUnitId);

  /// The [AdWithViewListener] for the ad.
  final AdWithViewListener listener;

  /// Starts loading this ad.
  ///
  /// Loading callbacks are sent to this [Ad]'s [listener].
  Future<void> load();
}

/// An [Ad] that is overlaid on top of the UI.
abstract class AdWithoutView extends Ad {
  /// Default constructor used by subclasses.
  AdWithoutView({required String adUnitId}) : super(adUnitId: adUnitId);

  /// Callback to be invoked when an ad is estimated to have earned money.
  /// Available for allowlisted accounts only.
  OnPaidEventCallback? onPaidEvent;

  /// Sets whether this ad will be displayed in immersive mode (Android only).
  ///
  /// This is a no-op on iOS.
  /// See https://developer.android.com/training/system-ui/immersive#immersive
  /// for more information on immersive mode.
  Future<void> setImmersiveMode(bool immersiveModeEnabled) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Future.value();
    } else {
      return instanceManager.setImmersiveMode(this, immersiveModeEnabled);
    }
  }
}

/// Displays an [Ad] as a Flutter widget.
///
/// This widget takes ads inheriting from [AdWithView]
/// (e.g. [BannerAd] and [NativeAd]) and allows them to be added to the Flutter
/// widget tree.
///
/// Must call `load()` first before showing the widget. Otherwise, a
/// [PlatformException] will be thrown.
class AdWidget extends StatefulWidget {
  /// Default constructor for [AdWidget].
  ///
  /// [ad] must be loaded before this is added to the widget tree.
  const AdWidget({Key? key, required this.ad}) : super(key: key);

  /// Ad to be displayed as a widget.
  final AdWithView ad;

  @override
  _AdWidgetState createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> {
  bool _adIdAlreadyMounted = false;
  bool _adLoadNotCalled = false;
  bool _firstVisibleOccurred = false;

  @override
  void initState() {
    super.initState();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      if (instanceManager.isWidgetAdIdMounted(adId)) {
        _adIdAlreadyMounted = true;
      }
      instanceManager.mountWidgetAdId(adId);
    } else {
      _adLoadNotCalled = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      instanceManager.unmountWidgetAdId(adId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_adIdAlreadyMounted) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('This AdWidget is already in the Widget tree'),
        ErrorHint(
            'If you placed this AdWidget in a list, make sure you create a new instance '
            'in the builder function with a unique ad object.'),
        ErrorHint(
            'Make sure you are not using the same ad object in more than one AdWidget.'),
      ]);
    }
    if (_adLoadNotCalled) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'AdWidget requires Ad.load to be called before AdWidget is inserted into the tree'),
        ErrorHint(
            'Parameter ad is not loaded. Call Ad.load before AdWidget is inserted into the tree.'),
      ]);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Do not attach the platform view widget until it will actually become
      // visible. This is a workaround for
      // https://github.com/googleads/googleads-mobile-flutter/issues/580,
      // where impressions are erroneously fired due to how platform views are
      // rendered.
      // TODO (jjliu15): Remove this after the flutter issue is resolved.
      if (_firstVisibleOccurred) {
        return PlatformViewLink(
          viewType: '${instanceManager.channel.name}/ad_widget',
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <
                  Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: '${instanceManager.channel.name}/ad_widget',
              layoutDirection: TextDirection.ltr,
              creationParams: instanceManager.adIdFor(widget.ad),
              creationParamsCodec: StandardMessageCodec(),
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        );
      } else {
        final adId = instanceManager.adIdFor(widget.ad);
        return VisibilityDetector(
          key: Key('android-platform-view-$adId'),
          onVisibilityChanged: (visibilityInfo) {
            if (!_firstVisibleOccurred &&
                visibilityInfo.visibleFraction > 0.01) {
              setState(() {
                _firstVisibleOccurred = true;
              });
            }
          },
          child: Container(),
        );
      }
    }

    return UiKitView(
      viewType: '${instanceManager.channel.name}/ad_widget',
      creationParams: instanceManager.adIdFor(widget.ad),
      creationParamsCodec: StandardMessageCodec(),
    );
  }
}

/// A widget for displaying [FluidAdManagerBannerAd].
///
/// This widget adjusts its height based on the platform rendered ad.
class FluidAdWidget extends StatefulWidget {
  /// Constructs a [FluidAdWidget].
  const FluidAdWidget({Key? key, required this.ad, this.width})
      : super(key: key);

  /// Ad to be displayed as a widget.
  final FluidAdManagerBannerAd ad;

  /// The width to set for the ad widget.
  final double? width;

  @override
  _FluidAdWidgetState createState() => _FluidAdWidgetState();
}

class _FluidAdWidgetState extends State<FluidAdWidget> {
  bool _adIdAlreadyMounted = false;
  bool _adLoadNotCalled = false;
  double _height = 0;

  @override
  void initState() {
    super.initState();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      if (instanceManager.isWidgetAdIdMounted(adId)) {
        _adIdAlreadyMounted = true;
      }
      instanceManager.mountWidgetAdId(adId);
    } else {
      _adLoadNotCalled = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    final int? adId = instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      instanceManager.unmountWidgetAdId(adId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_adIdAlreadyMounted) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('This AdWidget is already in the Widget tree'),
        ErrorHint(
            'If you placed this AdWidget in a list, make sure you create a new instance '
            'in the builder function with a unique ad object.'),
        ErrorHint(
            'Make sure you are not using the same ad object in more than one AdWidget.'),
      ]);
    }
    if (_adLoadNotCalled) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'AdWidget requires Ad.load to be called before AdWidget is inserted into the tree'),
        ErrorHint(
            'Parameter ad is not loaded. Call Ad.load before AdWidget is inserted into the tree.'),
      ]);
    }

    widget.ad.onFluidAdHeightChangedListener = (ad, height) {
      setState(() {
        _height = height;
      });
    };

    Widget platformView;
    double height;
    if (defaultTargetPlatform == TargetPlatform.android) {
      platformView = PlatformViewLink(
        viewType: '${instanceManager.channel.name}/ad_widget',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: '${instanceManager.channel.name}/ad_widget',
            layoutDirection: TextDirection.ltr,
            creationParams: instanceManager.adIdFor(widget.ad),
            creationParamsCodec: StandardMessageCodec(),
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
      height = _height / MediaQuery.of(context).devicePixelRatio;
    } else {
      platformView = UiKitView(
        viewType: '${instanceManager.channel.name}/ad_widget',
        creationParams: instanceManager.adIdFor(widget.ad),
        creationParamsCodec: StandardMessageCodec(),
      );
      height = _height;
    }

    return Container(
      height: max(1, height),
      width: widget.width == null ? 1 : max(1, widget.width!),
      child: platformView,
    );
  }
}

/// A banner ad.
///
/// This ad can either be overlaid on top of all flutter widgets as a static
/// view or displayed as a typical Flutter widget. To display as a widget,
/// instantiate an [AdWidget] with this as a parameter.
class BannerAd extends AdWithView {
  /// Creates a [BannerAd].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  BannerAd({
    required this.size,
    required String adUnitId,
    required this.listener,
    required this.request,
  }) : super(adUnitId: adUnitId, listener: listener);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// Represents the size of a banner ad.
  ///
  /// There are six sizes available, which are the same for both iOS and Android.
  /// See the guides for banners on Android](https://developers.google.com/admob/android/banner#banner_sizes)
  /// and [iOS](https://developers.google.com/admob/ios/banner#banner_sizes) for additional details.
  final AdSize size;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final BannerAdListener listener;

  @override
  Future<void> load() async {
    await instanceManager.loadBannerAd(this);
  }

  /// Returns the AdSize of the associated platform ad object.
  ///
  /// The dimensions of the [AdSize] returned here may differ from [size],
  /// depending on what type of [AdSize] was used.
  /// The future will resolve to null if [load] has not been called yet.
  Future<AdSize?> getPlatformAdSize() async {
    return await instanceManager.getAdSize(this);
  }
}

/// An 'AdManagerBannerAd' that has fluid ad size.
///
/// These ads will dynamically adjust their height to match the width of the ad.
/// This should be used with [FluidAdWidget], which displays the ad in a widget
/// that adjusts its height to the height of the platform rendered ad.
class FluidAdManagerBannerAd extends AdManagerBannerAd {
  /// Creates a [FluidAdManagerBannerAd].
  ///
  /// These ads dynamically change their height based on the width.
  /// Set [onFluidAdHeightChangedListener] to get notified of height updates.
  FluidAdManagerBannerAd({
    required String adUnitId,
    required AdManagerBannerAdListener listener,
    required AdManagerAdRequest request,
    this.onFluidAdHeightChangedListener,
  }) : super(
          sizes: [FluidAdSize()],
          adUnitId: adUnitId,
          listener: listener,
          request: request,
        );

  /// Listener for when the height of the ad changes.
  OnFluidAdHeightChangedListener? onFluidAdHeightChangedListener;

  @override
  Future<void> load() async {
    return instanceManager.loadFluidAd(this);
  }
}

/// A banner ad displayed with Google Ad Manager.
///
/// This ad can either be overlaid on top of all flutter widgets by passing this
/// to an [AdWidget] after calling [load].
class AdManagerBannerAd extends AdWithView {
  /// Default constructor for [AdManagerBannerAd].
  ///
  /// [sizes], [adUnitId], [listener], and [request] are all required values.
  AdManagerBannerAd({
    required this.sizes,
    required String adUnitId,
    required this.listener,
    required this.request,
  })  : assert(sizes.isNotEmpty),
        super(adUnitId: adUnitId, listener: listener);

  /// Targeting information used to fetch an [Ad].
  final AdManagerAdRequest request;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final AdManagerBannerAdListener listener;

  /// Ad sizes supported by this [AdManagerBannerAd].
  ///
  /// In most cases, only one ad size will be specified. Multiple ad sizes can
  /// be specified if your application can appropriately handle multiple ad
  /// sizes. If multiple ad sizes are specified, the [AdManagerBannerAd] will
  /// assume the size of the first ad size until an ad is loaded.
  final List<AdSize> sizes;

  @override
  Future<void> load() async {
    await instanceManager.loadAdManagerBannerAd(this);
  }

  /// Returns the AdSize of the associated platform ad object.
  ///
  /// The future will resolve to null if [load] has not been called yet.
  /// The dimensions of the [AdSize] returned here may differ from [sizes],
  /// depending on what type of [AdSize] was used.
  Future<AdSize?> getPlatformAdSize() async {
    return await instanceManager.getAdSize(this);
  }
}

/// A NativeAd.
///
/// Native ads are ad assets that are presented to users via UI components that
/// are native to the platform. (e.g. A
/// [View](https://developer.android.com/reference/android/view/View) on Android
/// or a
/// [UIView](https://developer.apple.com/documentation/uikit/uiview?language=objc)
/// on iOS). Using Flutter widgets to create native ads is NOT supported by
/// this.
///
/// Using platform specific UI components, these ads can be formatted to match
/// the visual design of the user experience in which they live. In coding
/// terms, this means that when a native ad loads, your app receives a NativeAd
/// object that contains its assets, and the app (rather than the Google Mobile
/// Ads SDK) is then responsible for displaying them.
///
/// See the README for more details on using Native Ads.
///
/// To display this ad, instantiate an [AdWidget] with this as a parameter after
/// calling [load].
class NativeAd extends AdWithView {
  /// Creates a [NativeAd].
  ///
  /// A valid [adUnitId], nonnull [listener], nonnull [request], and nonnull
  /// [factoryId] is required.
  /// Use [nativeAdOptions] to customize the native ad request.
  /// Use [customOptions] to pass data to your native ad factory.
  NativeAd({
    required String adUnitId,
    required this.factoryId,
    required this.listener,
    required this.request,
    this.nativeAdOptions,
    this.customOptions,
  })  : adManagerRequest = null,
        assert(request != null),
        super(adUnitId: adUnitId, listener: listener);

  /// Creates a [NativeAd] with Ad Manager.
  ///
  /// A valid [adUnitId], nonnull [listener], nonnull [adManagerRequest], and
  /// nonnull [factoryId] is required.
  /// Use [nativeAdOptions] to customize the native ad request.
  /// Use [customOptions] to pass data to your native ad factory.
  NativeAd.fromAdManagerRequest({
    required String adUnitId,
    required this.factoryId,
    required this.listener,
    required this.adManagerRequest,
    this.nativeAdOptions,
    this.customOptions,
  })  : request = null,
        assert(adManagerRequest != null),
        super(adUnitId: adUnitId, listener: listener);

  /// An identifier for the factory that creates the Platform view.
  final String factoryId;

  /// A listener for receiving events in the ad lifecycle.
  @override
  final NativeAdListener listener;

  /// Optional options used to create the [NativeAd].
  ///
  /// These options are passed to the platform's `NativeAdFactory`.
  Map<String, Object>? customOptions;

  /// Targeting information used to fetch an [Ad].
  final AdRequest? request;

  /// Targeting information used to fetch an [Ad] with Ad Manager.
  final AdManagerAdRequest? adManagerRequest;

  /// Options to configure the native ad request.
  final NativeAdOptions? nativeAdOptions;

  @override
  Future<void> load() async {
    await instanceManager.loadNativeAd(this);
  }
}

/// A full-screen interstitial ad for the Google Mobile Ads Plugin.
class InterstitialAd extends AdWithoutView {
  /// Creates an [InterstitialAd].
  ///
  /// A valid [adUnitId] from the AdMob dashboard, a nonnull [listener], and a
  /// nonnull [request] is required.
  InterstitialAd._({
    required String adUnitId,
    required this.request,
    required this.adLoadCallback,
  }) : super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final InterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;

  /// Loads an [InterstitialAd] with the given [adUnitId] and [request].
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  }) async {
    InterstitialAd ad = InterstitialAd._(
        adUnitId: adUnitId, adLoadCallback: adLoadCallback, request: request);

    await instanceManager.loadInterstitialAd(ad);
  }

  /// Displays this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    return instanceManager.showAdWithoutView(this);
  }
}

/// A full-screen interstitial ad for use with Ad Manager.
class AdManagerInterstitialAd extends AdWithoutView {
  /// Creates an [AdManagerInterstitialAd].
  ///
  /// A valid [adUnitId] from the Ad Manager dashboard, a nonnull [listener],
  /// and nonnull [request] is required.
  AdManagerInterstitialAd._({
    required String adUnitId,
    required this.request,
    required this.adLoadCallback,
  }) : super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdManagerAdRequest request;

  /// Callback to be invoked when the ad finishes loading.
  final AdManagerInterstitialAdLoadCallback adLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<AdManagerInterstitialAd>? fullScreenContentCallback;

  /// An optional listener for app events.
  AppEventListener? appEventListener;

  /// Loads an [AdManagerInterstitialAd] with the given [adUnitId] and [request].
  static Future<void> load({
    required String adUnitId,
    required AdManagerAdRequest request,
    required AdManagerInterstitialAdLoadCallback adLoadCallback,
    AppEventListener? appEventListener,
  }) async {
    AdManagerInterstitialAd ad = AdManagerInterstitialAd._(
        adUnitId: adUnitId, adLoadCallback: adLoadCallback, request: request);

    await instanceManager.loadAdManagerInterstitialAd(ad);
  }

  /// Displays this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    return instanceManager.showAdWithoutView(this);
  }
}

/// An [Ad] where a user has the option of interacting with in exchange for in-app rewards.
///
/// Because the video assets are so large, it's a good idea to start loading an
/// ad well in advance of when it's likely to be needed.
class RewardedAd extends AdWithoutView {
  /// Creates a [RewardedAd] with an [AdRequest].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  RewardedAd._({
    required String adUnitId,
    required this.rewardedAdLoadCallback,
    required this.request,
  })  : adManagerRequest = null,
        super(adUnitId: adUnitId);

  /// Creates a [RewardedAd] with a [AdManagerAdRequest].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  RewardedAd._fromAdManagerRequest({
    required String adUnitId,
    required this.rewardedAdLoadCallback,
    required this.adManagerRequest,
  })  : request = null,
        super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdRequest? request;

  /// Targeting information used to fetch an [Ad] using Ad Manager.
  final AdManagerAdRequest? adManagerRequest;

  /// Callbacks for events that occur when attempting to load an ad.
  final RewardedAdLoadCallback rewardedAdLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  /// Callback for when the user earns a reward.
  OnUserEarnedRewardCallback? onUserEarnedRewardCallback;

  /// Loads a [RewardedAd] using an [AdRequest].
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) async {
    RewardedAd rewardedAd = RewardedAd._(
        adUnitId: adUnitId,
        request: request,
        rewardedAdLoadCallback: rewardedAdLoadCallback);

    await instanceManager.loadRewardedAd(rewardedAd);
  }

  /// Loads a [RewardedAd] using an [AdManagerAdRequest].
  static Future<void> loadWithAdManagerAdRequest({
    required String adUnitId,
    required AdManagerAdRequest adManagerRequest,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) async {
    RewardedAd rewardedAd = RewardedAd._fromAdManagerRequest(
        adUnitId: adUnitId,
        adManagerRequest: adManagerRequest,
        rewardedAdLoadCallback: rewardedAdLoadCallback);

    await instanceManager.loadRewardedAd(rewardedAd);
  }

  /// Display this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  /// [onUserEarnedReward] will be invoked when the user earns a reward.
  Future<void> show({required OnUserEarnedRewardCallback onUserEarnedReward}) {
    onUserEarnedRewardCallback = onUserEarnedReward;
    return instanceManager.showAdWithoutView(this);
  }

  /// Set [ServerSideVerificationOptions] for the ad.
  Future<void> setServerSideOptions(ServerSideVerificationOptions options) {
    return instanceManager.setServerSideVerificationOptions(options, this);
  }
}

/// Rewarded interstitials are full screen ads that reward users and can be
/// shown without a user opt in.
///
/// This ad format is different than [RewardedAd] because rewarded ads require
/// the user to opt-in to watching the video. This ad format is different than
/// [InterstitialAd] because interstitial ads do not reward the user.
///
/// Because the video assets are so large, it's a good idea to start loading an
/// ad well in advance of when it's likely to be needed.
class RewardedInterstitialAd extends AdWithoutView {
  /// Creates a [RewardedInterstitialAd] with an [AdRequest].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  RewardedInterstitialAd._({
    required String adUnitId,
    required this.rewardedInterstitialAdLoadCallback,
    required this.request,
  })  : adManagerRequest = null,
        super(adUnitId: adUnitId);

  /// Creates a [RewardedInterstitialAd] with an [AdManagerAdRequest].
  ///
  /// A valid [adUnitId], nonnull [listener], and nonnull request is required.
  RewardedInterstitialAd._fromAdManagerRequest({
    required String adUnitId,
    required this.rewardedInterstitialAdLoadCallback,
    required this.adManagerRequest,
  })  : request = null,
        super(adUnitId: adUnitId);

  /// Targeting information used to fetch an [Ad].
  final AdRequest? request;

  /// Targeting information used to fetch an [Ad] using Ad Manager.
  final AdManagerAdRequest? adManagerRequest;

  /// Callbacks for events that occur when attempting to load an ad.
  final RewardedInterstitialAdLoadCallback rewardedInterstitialAdLoadCallback;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<RewardedInterstitialAd>? fullScreenContentCallback;

  /// Callback for when the user earns a reward.
  OnUserEarnedRewardCallback? onUserEarnedRewardCallback;

  /// Loads a [RewardedInterstitialAd] using an [AdRequest].
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedInterstitialAdLoadCallback
        rewardedInterstitialAdLoadCallback,
  }) async {
    RewardedInterstitialAd rewardedInterstitialAd = RewardedInterstitialAd._(
        adUnitId: adUnitId,
        request: request,
        rewardedInterstitialAdLoadCallback: rewardedInterstitialAdLoadCallback);

    await instanceManager.loadRewardedInterstitialAd(rewardedInterstitialAd);
  }

  /// Loads a [RewardedInterstitialAd] using an [AdManagerAdRequest].
  static Future<void> loadWithAdManagerAdRequest({
    required String adUnitId,
    required AdManagerAdRequest adManagerRequest,
    required RewardedInterstitialAdLoadCallback
        rewardedInterstitialAdLoadCallback,
  }) async {
    RewardedInterstitialAd rewardedInterstitialAd =
        RewardedInterstitialAd._fromAdManagerRequest(
            adUnitId: adUnitId,
            adManagerRequest: adManagerRequest,
            rewardedInterstitialAdLoadCallback:
                rewardedInterstitialAdLoadCallback);

    await instanceManager.loadRewardedInterstitialAd(rewardedInterstitialAd);
  }

  /// Display this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  /// [onUserEarnedReward] will be invoked when the user earns a reward.
  Future<void> show({required OnUserEarnedRewardCallback onUserEarnedReward}) {
    onUserEarnedRewardCallback = onUserEarnedReward;
    return instanceManager.showAdWithoutView(this);
  }

  /// Set [ServerSideVerificationOptions] for the ad.
  Future<void> setServerSideOptions(ServerSideVerificationOptions options) {
    return instanceManager.setServerSideVerificationOptions(options, this);
  }
}

/// Credit information about a reward received from a [RewardedAd] or
/// [RewardedInterstitialAd].
class RewardItem {
  /// Default constructor for [RewardItem].
  ///
  /// This is mostly used to return [RewardItem]s for a [RewardedAd] or
  /// [RewardedInterstitialAd] and shouldn't be needed to be used directly.
  RewardItem(this.amount, this.type);

  /// Credit amount rewarded from a [RewardedAd] or [RewardedInterstitialAd].
  final num amount;

  /// Type of credit rewarded.
  final String type;
}

/// Options for RewardedAd server-side verification callbacks.
///
/// See https://developers.google.com/admob/ios/rewarded-video-ssv and
/// https://developers.google.com/admob/android/rewarded-video-ssv for more
/// information.
class ServerSideVerificationOptions {
  /// The user id to be used in server-to-server reward callbacks.
  final String? userId;

  /// The custom data to be used in server-to-server reward callbacks
  final String? customData;

  /// Create [ServerSideVerificationOptions] with the userId or customData.
  ServerSideVerificationOptions({this.userId, this.customData});

  @override
  bool operator ==(other) {
    return other is ServerSideVerificationOptions &&
        userId == other.userId &&
        customData == other.customData;
  }
}

/// A full-screen app open ad for the Google Mobile Ads Plugin.
class AppOpenAd extends AdWithoutView {
  /// Portrait orientation.
  static const int orientationPortrait = 1;

  /// Landscape orientation left.
  ///
  /// Android does not distinguish between left/right, and will treat this
  /// the same way as [orientationLandscapeRight].
  static const int orientationLandscapeLeft = 2;

  /// Landscape orientation right.
  ///
  /// Android does not distinguish between left/right, and will treat this
  /// the same way as [orientationLandscapeLeft].
  static const int orientationLandscapeRight = 3;

  AppOpenAd._({
    required String adUnitId,
    required this.adLoadCallback,
    required this.request,
    required this.orientation,
  })  : adManagerAdRequest = null,
        super(adUnitId: adUnitId);

  AppOpenAd._fromAdManagerRequest({
    required String adUnitId,
    required this.adLoadCallback,
    required this.adManagerAdRequest,
    required this.orientation,
  })  : request = null,
        super(adUnitId: adUnitId);

  /// The [AdRequest] used to load the ad.
  final AdRequest? request;

  /// The [AdManagerAdRequest] used to load the ad.
  final AdManagerAdRequest? adManagerAdRequest;

  /// Listener for ad load events.
  final AppOpenAdLoadCallback adLoadCallback;

  /// The requested orientation.
  ///
  /// Must be [orientationPortrait], [orientationLandscapeLeft], or
  /// [orientationLandscapeRight].
  final int orientation;

  /// Callbacks to be invoked when ads show and dismiss full screen content.
  FullScreenContentCallback<AppOpenAd>? fullScreenContentCallback;

  /// Loads a [AppOpenAd] using an [AdRequest].
  static Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required AppOpenAdLoadCallback adLoadCallback,
    required int orientation,
  }) async {
    AppOpenAd ad = AppOpenAd._(
      adUnitId: adUnitId,
      adLoadCallback: adLoadCallback,
      request: request,
      orientation: orientation,
    );
    await instanceManager.loadAppOpenAd(ad);
  }

  /// Loads an [AppOpenAd] using an [AdManagerRequest].
  static Future<void> loadWithAdManagerAdRequest({
    required String adUnitId,
    required AdManagerAdRequest adManagerAdRequest,
    required AppOpenAdLoadCallback adLoadCallback,
    required int orientation,
  }) async {
    AppOpenAd ad = AppOpenAd._fromAdManagerRequest(
      adUnitId: adUnitId,
      adLoadCallback: adLoadCallback,
      adManagerAdRequest: adManagerAdRequest,
      orientation: orientation,
    );
    await instanceManager.loadAppOpenAd(ad);
  }

  /// Displays this on top of the application.
  ///
  /// Set [fullScreenContentCallback] before calling this method to be
  /// notified of events that occur when showing the ad.
  Future<void> show() {
    return instanceManager.showAdWithoutView(this);
  }
}

/// Media aspect ratio for native ads.
enum MediaAspectRatio {
  /// Unknown media aspect ratio.
  unknown,

  /// Any media aspect ratio.
  any,

  /// Landscape media aspect ratio.
  landscape,

  /// Portrait media aspect ratio.
  portrait,

  /// Close to square media aspect ratio. This is not a strict 1:1 aspect ratio.
  square
}

/// Indicates preferred location of AdChoices icon.
enum AdChoicesPlacement {
  /// Top right corner.
  topRightCorner,

  /// Top left corner.
  topLeftCorner,

  /// Bottom right corner.
  bottomRightCorner,

  /// Bottom left corner.
  bottomLeftCorner
}

/// Used to configure native ad requests.
class NativeAdOptions {
  /// Where to place the AdChoices icon.
  ///
  /// Default is top right.
  final AdChoicesPlacement? adChoicesPlacement;

  /// The media aspect ratio.
  ///
  /// Default is unknown, which will apply no restrictions.
  final MediaAspectRatio? mediaAspectRatio;

  /// Options for video.
  final VideoOptions? videoOptions;

  /// Whether to request a custom implementation for the Mute This Ad feature.
  ///
  /// Default value is false.
  final bool? requestCustomMuteThisAd;

  /// Sets whether multiple images should be requested or not.
  ///
  /// Default value is false.
  final bool? shouldRequestMultipleImages;

  /// Indicates whether image asset content should be loaded by the SDK.
  ///
  /// If set to true, the SDK will not load image asset content and native ad
  /// image URLs can be used to fetch content. Defaults to false.
  final bool? shouldReturnUrlsForImageAssets;

  /// Construct a NativeAdOptions, an optional class used to further customize
  /// native ad requests.
  NativeAdOptions({
    this.adChoicesPlacement,
    this.mediaAspectRatio,
    this.videoOptions,
    this.requestCustomMuteThisAd,
    this.shouldRequestMultipleImages,
    this.shouldReturnUrlsForImageAssets,
  });

  @override
  bool operator ==(other) {
    return other is NativeAdOptions &&
        adChoicesPlacement == other.adChoicesPlacement &&
        mediaAspectRatio == other.mediaAspectRatio &&
        videoOptions == other.videoOptions &&
        requestCustomMuteThisAd == other.requestCustomMuteThisAd &&
        shouldRequestMultipleImages == other.shouldRequestMultipleImages &&
        shouldReturnUrlsForImageAssets == other.shouldReturnUrlsForImageAssets;
  }
}

/// Options for controlling video playback in supported ad formats.
class VideoOptions {
  /// Whether the requested video should have the click to expand behavior.
  final bool? clickToExpandRequested;

  /// Whether the requested video should have custom controls enabled.
  ///
  /// Custom controls are for play/pause/mute/unmute.
  final bool? customControlsRequested;

  /// Indicates whether videos should start muted.
  ///
  /// By default this property value is YES.
  final bool? startMuted;

  /// Constructs a VideoOptions to further customize a native ad request.
  ///
  /// This is only necessary if you wish to further customize your native ad
  /// integration.
  VideoOptions({
    this.clickToExpandRequested,
    this.customControlsRequested,
    this.startMuted,
  });

  @override
  bool operator ==(other) {
    return other is VideoOptions &&
        clickToExpandRequested == other.clickToExpandRequested &&
        customControlsRequested == other.customControlsRequested &&
        startMuted == other.startMuted;
  }
}
