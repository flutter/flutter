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

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_inspector_containers.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mobile Ads', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    final List<MethodCall> log = <MethodCall>[];
    final AdMessageCodec codec = AdMessageCodec();

    setUpAll(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    setUp(() async {
      log.clear();
      MethodChannel(
        'plugins.flutter.io/google_mobile_ads',
        StandardMethodCodec(AdMessageCodec()),
      ).setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'MobileAds#initialize':
            return InitializationStatus(<String, AdapterStatus>{
              'aName': AdapterStatus(
                AdapterInitializationState.notReady,
                'desc',
                0,
              ),
            });
          case '_init':
          case 'MobileAds#setSameAppKeyEnabled':
          case 'MobileAds#setAppMuted':
          case 'MobileAds#setAppVolume':
          case 'MobileAds#disableSDKCrashReporting':
          case 'MobileAds#disableMediationInitialization':
            return null;
          case 'MobileAds#getVersionString':
            return Future<String>.value('Test-SDK-Version');
          case 'MobileAds#updateRequestConfiguration':
            return null;
          case 'MobileAds#getRequestConfiguration':
            return RequestConfiguration(
              maxAdContentRating: MaxAdContentRating.ma,
              tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
              tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
              testDeviceIds: <String>['test-device-id'],
            );
          case 'AdSize#getAnchoredAdaptiveBannerAdSize':
            return null;
          default:
            assert(false);
            return null;
        }
      });
    });

    test('encode/decode $AdapterInitializationState', () {
      final ByteData byteData =
          codec.encodeMessage(AdapterInitializationState.ready)!;

      final AdapterInitializationState result = codec.decodeMessage(byteData);
      expect(result, AdapterInitializationState.ready);
    });

    test('encode/decode $AdapterStatus', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final ByteData byteData = codec.encodeMessage(AdapterStatus(
        AdapterInitializationState.notReady,
        'describe',
        23,
      ))!;

      AdapterStatus result = codec.decodeMessage(byteData);
      expect(result.state, AdapterInitializationState.notReady);
      expect(result.description, 'describe');
      expect(result.latency, 0.023);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      result = codec.decodeMessage(byteData);
      expect(result.state, AdapterInitializationState.notReady);
      expect(result.description, 'describe');
      expect(result.latency, 23);
    });

    test('handle int values for AdapterStatus', () {
      final WriteBuffer buffer = WriteBuffer();
      codec.writeValue(buffer, AdapterInitializationState.ready);
      codec.writeValue(buffer, 'aDescription');
      codec.writeValue(buffer, 23);

      expect(
        () => codec.readValueOfType(
          136 /* AdMessageCodec._valueAdapterStatus */,
          ReadBuffer(buffer.done()),
        ),
        returnsNormally,
      );
    });

    test('encode/decode $InitializationStatus', () {
      final ByteData byteData =
          codec.encodeMessage(InitializationStatus(<String, AdapterStatus>{
        'adMediation': AdapterStatus(
          AdapterInitializationState.ready,
          'aDescription',
          0,
        ),
      }))!;

      final InitializationStatus result = codec.decodeMessage(byteData);
      expect(result.adapterStatuses, hasLength(1));
      final AdapterStatus status = result.adapterStatuses['adMediation']!;
      expect(status.state, AdapterInitializationState.ready);
      expect(status.description, 'aDescription');
      expect(status.latency, 0);
    });

    test('$MobileAds.initialize', () async {
      final InitializationStatus result = await MobileAds.instance.initialize();

      expect(log, <Matcher>[
        isMethodCall('_init', arguments: null),
        isMethodCall('MobileAds#initialize', arguments: null)
      ]);

      expect(result.adapterStatuses, hasLength(1));
      final AdapterStatus status = result.adapterStatuses['aName']!;
      expect(status.state, AdapterInitializationState.notReady);
      expect(status.description, 'desc');
      expect(status.latency, 0);
    });

    test('$MobileAds.openAdInspector success', () async {
      MethodChannel(
        'plugins.flutter.io/google_mobile_ads',
        StandardMethodCodec(AdMessageCodec()),
      ).setMockMethodCallHandler((MethodCall methodCall) async {
        return null;
      });

      Completer<AdInspectorError?> completer = Completer<AdInspectorError?>();
      MobileAds.instance.openAdInspector((error) {
        completer.complete(error);
      });

      AdInspectorError? error = await completer.future;
      expect(error, null);
    });

    test('$MobileAds.openAdInspector error', () async {
      MethodChannel(
        'plugins.flutter.io/google_mobile_ads',
        StandardMethodCodec(AdMessageCodec()),
      ).setMockMethodCallHandler((MethodCall methodCall) async {
        throw PlatformException(
            code: '1', details: 'details', message: 'message');
      });

      Completer<AdInspectorError?> completer = Completer<AdInspectorError?>();
      MobileAds.instance.openAdInspector((error) {
        completer.complete(error);
      });

      AdInspectorError? error = await completer.future;
      expect(error!.message, 'message');
      expect(error.code, '1');
      expect(error.domain, 'details');
    });

    test('$MobileAds.setSameAppKeyEnabled', () async {
      await MobileAds.instance.setSameAppKeyEnabled(true);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: {'isEnabled': true})
      ]);

      await MobileAds.instance.setSameAppKeyEnabled(false);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: {'isEnabled': true}),
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: {'isEnabled': false})
      ]);
    });

    test('encode/decode empty native ad options', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ByteData byteData = codec.encodeMessage(NativeAdOptions())!;

      NativeAdOptions result = codec.decodeMessage(byteData);
      expect(result.mediaAspectRatio, null);
      expect(result.adChoicesPlacement, null);
      expect(result.requestCustomMuteThisAd, null);
      expect(result.shouldRequestMultipleImages, null);
      expect(result.shouldReturnUrlsForImageAssets, null);
      expect(result.videoOptions, null);

      byteData =
          codec.encodeMessage(NativeAdOptions(videoOptions: VideoOptions()))!;
      result = codec.decodeMessage(byteData);
      expect(result.mediaAspectRatio, null);
      expect(result.adChoicesPlacement, null);
      expect(result.requestCustomMuteThisAd, null);
      expect(result.shouldRequestMultipleImages, null);
      expect(result.shouldReturnUrlsForImageAssets, null);
      expect(result.videoOptions!.clickToExpandRequested, null);
      expect(result.videoOptions!.customControlsRequested, null);
      expect(result.videoOptions!.startMuted, null);
    });

    test('encode/decode native ad options', () {
      NativeAdOptions nativeAdOptions = NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.topRightCorner,
          mediaAspectRatio: MediaAspectRatio.unknown,
          videoOptions: VideoOptions(
            clickToExpandRequested: false,
            customControlsRequested: false,
            startMuted: false,
          ),
          requestCustomMuteThisAd: false,
          shouldRequestMultipleImages: false,
          shouldReturnUrlsForImageAssets: false);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      ByteData byteData = codec.encodeMessage(nativeAdOptions)!;

      NativeAdOptions result = codec.decodeMessage(byteData);
      expect(result.mediaAspectRatio, MediaAspectRatio.unknown);
      expect(result.adChoicesPlacement, AdChoicesPlacement.topRightCorner);
      expect(result.requestCustomMuteThisAd, false);
      expect(result.shouldRequestMultipleImages, false);
      expect(result.shouldReturnUrlsForImageAssets, false);
      expect(result.videoOptions!.startMuted, false);
      expect(result.videoOptions!.customControlsRequested, false);
      expect(result.videoOptions!.clickToExpandRequested, false);

      nativeAdOptions = NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.bottomLeftCorner,
          mediaAspectRatio: MediaAspectRatio.landscape,
          videoOptions: VideoOptions(
            clickToExpandRequested: true,
            customControlsRequested: true,
            startMuted: true,
          ),
          requestCustomMuteThisAd: true,
          shouldRequestMultipleImages: true,
          shouldReturnUrlsForImageAssets: true);

      byteData = codec.encodeMessage(nativeAdOptions)!;
      result = codec.decodeMessage(byteData);

      expect(result.mediaAspectRatio, MediaAspectRatio.landscape);
      expect(result.adChoicesPlacement, AdChoicesPlacement.bottomLeftCorner);
      expect(result.requestCustomMuteThisAd, true);
      expect(result.shouldRequestMultipleImages, true);
      expect(result.shouldReturnUrlsForImageAssets, true);
      expect(result.videoOptions!.startMuted, true);
      expect(result.videoOptions!.customControlsRequested, true);
      expect(result.videoOptions!.clickToExpandRequested, true);
    });

    test('$MobileAds.setAppMuted', () async {
      await MobileAds.instance.setAppMuted(true);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setAppMuted', arguments: {'muted': true})
      ]);

      await MobileAds.instance.setAppMuted(false);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setAppMuted', arguments: {'muted': true}),
        isMethodCall('MobileAds#setAppMuted', arguments: {'muted': false})
      ]);
    });

    test('$MobileAds.setAppVolume', () async {
      await MobileAds.instance.setAppVolume(1.0);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setAppVolume', arguments: {'volume': 1.0})
      ]);
    });

    test('$MobileAds.disableSDKCrashReporting', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await MobileAds.instance.disableSDKCrashReporting();

      expect(log, <Matcher>[
        isMethodCall('MobileAds#disableSDKCrashReporting', arguments: null)
      ]);
    });

    test('$MobileAds.disableMediationInitialization', () async {
      await MobileAds.instance.disableMediationInitialization();

      expect(log, <Matcher>[
        isMethodCall('MobileAds#disableMediationInitialization',
            arguments: null)
      ]);
    });

    test('$MobileAds.getVersionString', () async {
      await MobileAds.instance.getVersionString();

      expect(log, <Matcher>[
        isMethodCall('MobileAds#getVersionString', arguments: null)
      ]);
    });

    test('$AdSize.getAnchoredAdaptiveBannerAdSize', () async {
      await AdSize.getAnchoredAdaptiveBannerAdSize(Orientation.portrait, 23);

      expect(log, <Matcher>[
        isMethodCall('AdSize#getAnchoredAdaptiveBannerAdSize',
            arguments: {'orientation': 'portrait', 'width': 23})
      ]);

      await AdSize.getAnchoredAdaptiveBannerAdSize(Orientation.landscape, 34);

      expect(log, <Matcher>[
        isMethodCall('AdSize#getAnchoredAdaptiveBannerAdSize',
            arguments: {'orientation': 'portrait', 'width': 23}),
        isMethodCall('AdSize#getAnchoredAdaptiveBannerAdSize',
            arguments: {'orientation': 'landscape', 'width': 34})
      ]);

      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(45);

      expect(log, <Matcher>[
        isMethodCall('AdSize#getAnchoredAdaptiveBannerAdSize',
            arguments: {'orientation': 'portrait', 'width': 23}),
        isMethodCall('AdSize#getAnchoredAdaptiveBannerAdSize',
            arguments: {'orientation': 'landscape', 'width': 34}),
        isMethodCall('AdSize#getAnchoredAdaptiveBannerAdSize',
            arguments: {'width': 45})
      ]);
    });

    test('encode/decode $MobileAds.getRequestConfiguration', () async {
      RequestConfiguration requestConfig =
          await MobileAds.instance.getRequestConfiguration();

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      ByteData byteData = codec.encodeMessage(requestConfig)!;
      RequestConfiguration result = codec.decodeMessage(byteData);

      expect(result.maxAdContentRating, MaxAdContentRating.ma);
      expect(result.tagForChildDirectedTreatment,
          TagForChildDirectedTreatment.yes);
      expect(result.tagForUnderAgeOfConsent, TagForUnderAgeOfConsent.no);
      expect(result.testDeviceIds, ['test-device-id']);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      byteData = codec.encodeMessage(requestConfig)!;
      result = codec.decodeMessage(byteData);

      expect(result.maxAdContentRating, MaxAdContentRating.ma);
      expect(result.tagForChildDirectedTreatment,
          TagForChildDirectedTreatment.yes);
      expect(result.tagForUnderAgeOfConsent, TagForUnderAgeOfConsent.no);
      expect(result.testDeviceIds, ['test-device-id']);
    });

    test('$MobileAds.RequestConfiguration', () async {
      RequestConfiguration requestConfiguration = RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.ma,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        testDeviceIds: <String>['test-device-id'],
      );

      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      RequestConfiguration result =
          await MobileAds.instance.getRequestConfiguration();
      expect(result.maxAdContentRating, MaxAdContentRating.ma);
      expect(result.tagForChildDirectedTreatment,
          TagForChildDirectedTreatment.yes);
      expect(result.tagForUnderAgeOfConsent, TagForUnderAgeOfConsent.no);
      expect(result.testDeviceIds, <String>['test-device-id']);
      expect(log, <Matcher>[
        isMethodCall('MobileAds#updateRequestConfiguration', arguments: {
          'maxAdContentRating': MaxAdContentRating.ma,
          'tagForChildDirectedTreatment': TagForChildDirectedTreatment.yes,
          'testDeviceIds': <String>['test-device-id'],
          'tagForUnderAgeOfConsent': TagForUnderAgeOfConsent.no,
        }),
        isMethodCall('MobileAds#getRequestConfiguration', arguments: null)
      ]);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      result = await MobileAds.instance.getRequestConfiguration();
      expect(result.maxAdContentRating, MaxAdContentRating.ma);
      expect(result.tagForChildDirectedTreatment,
          TagForChildDirectedTreatment.yes);
      expect(result.tagForUnderAgeOfConsent, TagForUnderAgeOfConsent.no);
      expect(result.testDeviceIds, <String>['test-device-id']);
      expect(log, <Matcher>[
        isMethodCall('MobileAds#updateRequestConfiguration', arguments: {
          'maxAdContentRating': MaxAdContentRating.ma,
          'tagForChildDirectedTreatment': TagForChildDirectedTreatment.yes,
          'testDeviceIds': <String>['test-device-id'],
          'tagForUnderAgeOfConsent': TagForUnderAgeOfConsent.no,
        }),
        isMethodCall('MobileAds#getRequestConfiguration', arguments: null),
        isMethodCall('MobileAds#getRequestConfiguration', arguments: null)
      ]);
    });
  });
}
