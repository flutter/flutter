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
import 'package:pedantic/pedantic.dart';
import 'test_util.dart';

// ignore_for_file: deprecated_member_use_from_same_package
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fluid Ad Tests', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      log.clear();
      instanceManager =
          AdInstanceManager('plugins.flutter.io/google_mobile_ads');
      instanceManager.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'loadFluidAd':
          case 'disposeAd':
            return Future<void>.value();
          default:
            assert(false);
            return null;
        }
      });
    });

    test('load android with callbacks', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      Completer<Ad> impressionCompleter = Completer<Ad>();
      Completer<Ad> loadedCompleter = Completer<Ad>();
      Completer<List<dynamic>> failedToLoadCompleter =
          Completer<List<dynamic>>();
      Completer<Ad> openedCompleter = Completer<Ad>();
      Completer<Ad> closedCompleter = Completer<Ad>();
      Completer<Ad> willDismissCompleter = Completer<Ad>();
      Completer<List<dynamic>> paidEventCompleter = Completer<List<dynamic>>();
      Completer<List<dynamic>> appEventCompleter = Completer<List<dynamic>>();
      Completer<List<dynamic>> heightChangedCompleter =
          Completer<List<dynamic>>();

      final FluidAdManagerBannerAd fluidAd = FluidAdManagerBannerAd(
        adUnitId: 'testId',
        listener: AdManagerBannerAdListener(
          onAdLoaded: (ad) => loadedCompleter.complete(ad),
          onAdFailedToLoad: (ad, error) =>
              failedToLoadCompleter.complete([ad, error]),
          onAdImpression: (ad) => impressionCompleter.complete(ad),
          onAdOpened: (ad) => openedCompleter.complete(ad),
          onAdClosed: (ad) => closedCompleter.complete(ad),
          onPaidEvent: (ad, value, precision, currencyCode) =>
              paidEventCompleter.complete([ad, value, precision, currencyCode]),
          onAppEvent: (ad, name, data) =>
              appEventCompleter.complete([ad, name, data]),
          onAdWillDismissScreen: (ad) => willDismissCompleter.complete(ad),
        ),
        onFluidAdHeightChangedListener: (ad, height) =>
            heightChangedCompleter.complete([ad, height]),
        request: AdManagerAdRequest(),
      );

      await fluidAd.load();
      expect(log, <Matcher>[
        isMethodCall('loadFluidAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'testId',
          'sizes': <AdSize>[FluidAdSize()],
          'request': AdManagerAdRequest(),
        })
      ]);

      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);
      Ad loadedAd = await loadedCompleter.future;
      expect(instanceManager.adFor(0), fluidAd);
      expect(loadedAd, loadedAd);

      await TestUtil.sendAdEvent(0, 'onAdImpression', instanceManager);
      expect(await impressionCompleter.future, loadedAd);

      await TestUtil.sendAdEvent(0, 'onAdOpened', instanceManager);
      expect(await openedCompleter.future, loadedAd);

      await TestUtil.sendAdEvent(0, 'onAdClosed', instanceManager);
      expect(await closedCompleter.future, loadedAd);

      const heightChangedArgs = {'height': 25};
      await TestUtil.sendAdEvent(
          0, 'onFluidAdHeightChanged', instanceManager, heightChangedArgs);
      expect(await heightChangedCompleter.future, [fluidAd, 25]);

      LoadAdError error = LoadAdError(1, 'domain', 'message', null);
      var errorArgs = {'loadAdError': error};
      await TestUtil.sendAdEvent(
          0, 'onAdFailedToLoad', instanceManager, errorArgs);
      List<dynamic> adAndError = await failedToLoadCompleter.future;
      expect(adAndError[0], loadedAd);
      expect(adAndError[1].toString(), error.toString());

      const appEventArgs = {'name': 'name', 'data': '1234'};
      await TestUtil.sendAdEvent(
          0, 'onAppEvent', instanceManager, appEventArgs);
      expect(await appEventCompleter.future, [fluidAd, 'name', '1234']);

      // will dismiss is iOS only event.
      var willDismissCompleted = false;
      unawaited(willDismissCompleter.future
          .whenComplete(() => willDismissCompleted = true));
      await TestUtil.sendAdEvent(
          0, 'onBannerWillDismissScreen', instanceManager);
      expect(willDismissCompleted, false);
    });

    test('load iOS with callbacks', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      Completer<Ad> impressionCompleter = Completer<Ad>();
      Completer<Ad> loadedCompleter = Completer<Ad>();
      Completer<List<dynamic>> failedToLoadCompleter =
          Completer<List<dynamic>>();
      Completer<Ad> openedCompleter = Completer<Ad>();
      Completer<Ad> closedCompleter = Completer<Ad>();
      Completer<Ad> willDismissCompleter = Completer<Ad>();
      Completer<List<dynamic>> paidEventCompleter = Completer<List<dynamic>>();
      Completer<List<dynamic>> appEventCompleter = Completer<List<dynamic>>();
      Completer<List<dynamic>> heightChangedCompleter =
          Completer<List<dynamic>>();

      final FluidAdManagerBannerAd fluidAd = FluidAdManagerBannerAd(
        adUnitId: 'testId',
        listener: AdManagerBannerAdListener(
          onAdLoaded: (ad) => loadedCompleter.complete(ad),
          onAdFailedToLoad: (ad, error) =>
              failedToLoadCompleter.complete([ad, error]),
          onAdImpression: (ad) => impressionCompleter.complete(ad),
          onAdOpened: (ad) => openedCompleter.complete(ad),
          onAdClosed: (ad) => closedCompleter.complete(ad),
          onPaidEvent: (ad, value, precision, currencyCode) =>
              paidEventCompleter.complete([ad, value, precision, currencyCode]),
          onAppEvent: (ad, name, data) =>
              appEventCompleter.complete([ad, name, data]),
          onAdWillDismissScreen: (ad) => willDismissCompleter.complete(ad),
        ),
        onFluidAdHeightChangedListener: (ad, height) =>
            heightChangedCompleter.complete([ad, height]),
        request: AdManagerAdRequest(),
      );

      await fluidAd.load();
      expect(log, <Matcher>[
        isMethodCall('loadFluidAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'testId',
          'sizes': <AdSize>[FluidAdSize()],
          'request': AdManagerAdRequest(),
        })
      ]);

      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);
      Ad loadedAd = await loadedCompleter.future;
      expect(instanceManager.adFor(0), fluidAd);
      expect(loadedAd, loadedAd);

      await TestUtil.sendAdEvent(0, 'onBannerImpression', instanceManager);
      expect(await impressionCompleter.future, loadedAd);

      await TestUtil.sendAdEvent(
          0, 'onBannerWillPresentScreen', instanceManager);
      expect(await openedCompleter.future, loadedAd);

      await TestUtil.sendAdEvent(
          0, 'onBannerDidDismissScreen', instanceManager);
      expect(await closedCompleter.future, loadedAd);

      const heightChangedArgs = {'height': 25};
      await TestUtil.sendAdEvent(
          0, 'onFluidAdHeightChanged', instanceManager, heightChangedArgs);
      expect(await heightChangedCompleter.future, [fluidAd, 25]);

      LoadAdError error = LoadAdError(1, 'domain', 'message', null);
      var errorArgs = {'loadAdError': error};
      await TestUtil.sendAdEvent(
          0, 'onAdFailedToLoad', instanceManager, errorArgs);
      List<dynamic> adAndError = await failedToLoadCompleter.future;
      expect(adAndError[0], loadedAd);
      expect(adAndError[1].toString(), error.toString());

      const appEventArgs = {'name': 'name', 'data': '1234'};
      await TestUtil.sendAdEvent(
          0, 'onAppEvent', instanceManager, appEventArgs);
      expect(await appEventCompleter.future, [fluidAd, 'name', '1234']);

      // will dismiss is iOS only event.
      await TestUtil.sendAdEvent(
          0, 'onBannerWillDismissScreen', instanceManager);
      expect(await willDismissCompleter.future, fluidAd);
    });
  });
}
