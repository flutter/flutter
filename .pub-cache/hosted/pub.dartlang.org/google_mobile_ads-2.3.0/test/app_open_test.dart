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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'test_util.dart';

// ignore_for_file: deprecated_member_use_from_same_package
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Open Tests', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      log.clear();
      instanceManager =
          AdInstanceManager('plugins.flutter.io/google_mobile_ads');
      instanceManager.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'loadAppOpenAd':
          case 'showAdWithoutView':
          case 'disposeAd':
            return Future<void>.value();
          default:
            assert(false);
            return null;
        }
      });
    });

    test('load show android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AppOpenAd? appOpenAd;
      AdRequest request = AdRequest();
      await AppOpenAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              appOpenAd = ad;
            },
            onAdFailedToLoad: (error) {}),
        orientation: AppOpenAd.orientationPortrait,
      );

      expect(log, <Matcher>[
        isMethodCall('loadAppOpenAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
          'orientation': AppOpenAd.orientationPortrait
        }),
      ]);

      // Simulate load callback
      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);

      AppOpenAd createdAd = instanceManager.adFor(0) as AppOpenAd;
      (createdAd).adLoadCallback.onAdLoaded(createdAd);
      expect(instanceManager.adFor(0), isNotNull);
      expect(appOpenAd, createdAd);

      log.clear();

      // Show the ad and verify method call.
      await appOpenAd!.show();
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);

      // Check that full screen events are passed correctly.
      Completer<AppOpenAd> impressionCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> failedToShowCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> showedCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> dismissedCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> clickedCompleter = Completer<AppOpenAd>();

      appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdImpression: (ad) => impressionCompleter.complete(ad),
        onAdShowedFullScreenContent: (ad) => showedCompleter.complete(ad),
        onAdFailedToShowFullScreenContent: (ad, error) =>
            failedToShowCompleter.complete(ad),
        onAdDismissedFullScreenContent: (ad) => dismissedCompleter.complete(ad),
        onAdClicked: (ad) => clickedCompleter.complete(ad),
      );

      await TestUtil.sendAdEvent(0, 'onAdImpression', instanceManager);
      expect(await impressionCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(0, 'onAdClicked', instanceManager);
      expect(await clickedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(
          0, 'onAdShowedFullScreenContent', instanceManager);
      expect(await showedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(
          0, 'onAdDismissedFullScreenContent', instanceManager);
      expect(await dismissedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(0, 'onFailedToShowFullScreenContent',
          instanceManager, {'error': AdError(1, 'domain', 'message')});
      expect(await failedToShowCompleter.future, appOpenAd);

      // Check paid event callback
      Completer<List<dynamic>> paidEventCompleter = Completer<List<dynamic>>();
      appOpenAd!.onPaidEvent = (ad, value, precision, currency) {
        paidEventCompleter.complete(<Object>[ad, value, precision, currency]);
      };

      const paidEventArgs = {
        'valueMicros': 1.2345,
        'precision': 0,
        'currencyCode': 'USD',
      };
      await TestUtil.sendAdEvent(
          0, 'onPaidEvent', instanceManager, paidEventArgs);
      List<dynamic> paidEventCallback = await paidEventCompleter.future;
      expect(paidEventCallback[0], appOpenAd);
      expect(paidEventCallback[1], 1.2345);
      expect(paidEventCallback[2], PrecisionType.unknown);
      expect(paidEventCallback[3], 'USD');
    });

    test('load show ios', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      AppOpenAd? appOpenAd;
      AdRequest request = AdRequest();
      await AppOpenAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              appOpenAd = ad;
            },
            onAdFailedToLoad: (error) {}),
        orientation: AppOpenAd.orientationLandscapeLeft,
      );

      expect(log, <Matcher>[
        isMethodCall('loadAppOpenAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
          'orientation': AppOpenAd.orientationLandscapeLeft
        }),
      ]);

      // Simulate load callback
      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);

      AppOpenAd createdAd = instanceManager.adFor(0) as AppOpenAd;
      (createdAd).adLoadCallback.onAdLoaded(createdAd);
      expect(instanceManager.adFor(0), isNotNull);
      expect(appOpenAd, createdAd);

      log.clear();

      // Show the ad and verify method call.
      await appOpenAd!.show();
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);

      // Check that full screen events are passed correctly.
      Completer<AppOpenAd> impressionCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> failedToShowCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> showedCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> dismissedCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> willDismissCompleter = Completer<AppOpenAd>();
      Completer<AppOpenAd> clickedCompleter = Completer<AppOpenAd>();

      appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdImpression: (ad) => impressionCompleter.complete(ad),
        onAdShowedFullScreenContent: (ad) => showedCompleter.complete(ad),
        onAdFailedToShowFullScreenContent: (ad, error) =>
            failedToShowCompleter.complete(ad),
        onAdDismissedFullScreenContent: (ad) => dismissedCompleter.complete(ad),
        onAdWillDismissFullScreenContent: (ad) =>
            willDismissCompleter.complete(ad),
        onAdClicked: (ad) => clickedCompleter.complete(ad),
      );

      await TestUtil.sendAdEvent(0, 'adDidRecordImpression', instanceManager);
      expect(await impressionCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(0, 'adDidRecordClick', instanceManager);
      expect(await clickedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(
          0, 'adWillPresentFullScreenContent', instanceManager);
      expect(await showedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(
          0, 'adDidDismissFullScreenContent', instanceManager);
      expect(await dismissedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(
          0, 'adWillDismissFullScreenContent', instanceManager);
      expect(await dismissedCompleter.future, appOpenAd);

      await TestUtil.sendAdEvent(
          0,
          'didFailToPresentFullScreenContentWithError',
          instanceManager,
          {'error': AdError(1, 'domain', 'message')});
      expect(await failedToShowCompleter.future, appOpenAd);

      // Check paid event callback
      Completer<List<dynamic>> paidEventCompleter = Completer<List<dynamic>>();
      appOpenAd!.onPaidEvent = (ad, value, precision, currency) {
        paidEventCompleter.complete(<Object>[ad, value, precision, currency]);
      };

      const paidEventArgs = {
        'valueMicros': 1.2345,
        'precision': 0,
        'currencyCode': 'USD',
      };
      await TestUtil.sendAdEvent(
          0, 'onPaidEvent', instanceManager, paidEventArgs);
      List<dynamic> paidEventCallback = await paidEventCompleter.future;
      expect(paidEventCallback[0], appOpenAd);
      expect(paidEventCallback[1], 1.2345);
      expect(paidEventCallback[2], PrecisionType.unknown);
      expect(paidEventCallback[3], 'USD');
    });
  });
}
