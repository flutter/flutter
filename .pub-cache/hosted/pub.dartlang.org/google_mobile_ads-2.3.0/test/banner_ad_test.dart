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

  group('Banner Ad Tests', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      log.clear();
      instanceManager =
          AdInstanceManager('plugins.flutter.io/google_mobile_ads');
      instanceManager.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'loadBannerAd':
          case 'disposeAd':
            return Future<void>.value();
          default:
            assert(false);
            return null;
        }
      });
    });

    test('android loaded events', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AdRequest request = AdRequest();

      // Check that listener callbacks are invoked
      Completer<Ad> loaded = Completer<Ad>();
      Completer<List<dynamic>> failedToLoad = Completer<List<dynamic>>();
      Completer<Ad> opened = Completer<Ad>();
      Completer<Ad> clicked = Completer<Ad>();
      Completer<Ad> impression = Completer<Ad>();
      Completer<Ad> closed = Completer<Ad>();
      Completer<List<dynamic>> paidEvent = Completer<List<dynamic>>();

      BannerAdListener bannerListener = BannerAdListener(
        onAdLoaded: (ad) => loaded.complete(ad),
        onAdFailedToLoad: (ad, error) =>
            failedToLoad.complete(<Object>[ad, error]),
        onAdImpression: (ad) => impression.complete(ad),
        onPaidEvent: (ad, value, precision, currency) =>
            paidEvent.complete(<Object>[ad, value, precision, currency]),
        onAdClicked: (ad) => clicked.complete(ad),
        onAdClosed: (ad) => closed.complete(ad),
        onAdOpened: (ad) => opened.complete(ad),
      );

      var bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: 'ad-unit',
        listener: bannerListener,
        request: request,
      );
      await bannerAd.load();

      expect(log, <Matcher>[
        isMethodCall('loadBannerAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'ad-unit',
          'request': request,
          'size': AdSize.banner,
        }),
      ]);

      // Simulate load callback
      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);

      BannerAd createdAd = instanceManager.adFor(0) as BannerAd;
      expect(instanceManager.adFor(0), isNotNull);
      expect(bannerAd, createdAd);
      expect(await loaded.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'onAdImpression', instanceManager);
      expect(await impression.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'onAdClicked', instanceManager);
      expect(await clicked.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'onAdOpened', instanceManager);
      expect(await opened.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'onAdClosed', instanceManager);
      expect(await closed.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'onAdClicked', instanceManager);
      expect(await clicked.future, bannerAd);

      const paidEventArgs = {
        'valueMicros': 1.2345,
        'precision': 0,
        'currencyCode': 'USD',
      };
      await TestUtil.sendAdEvent(
          0, 'onPaidEvent', instanceManager, paidEventArgs);
      List<dynamic> paidEventCallback = await paidEvent.future;
      expect(paidEventCallback[0], bannerAd);
      expect(paidEventCallback[1], 1.2345);
      expect(paidEventCallback[2], PrecisionType.unknown);
      expect(paidEventCallback[3], 'USD');
    });

    test('onAdFailedToLoad banner', () async {
      var testOnAdFailedToLoad = (adId) async {
        final Completer<List<dynamic>> resultsCompleter =
            Completer<List<dynamic>>();

        final BannerAd banner = BannerAd(
          adUnitId: 'test-ad-unit',
          size: AdSize.banner,
          listener: BannerAdListener(
              onAdFailedToLoad: (Ad ad, LoadAdError error) =>
                  resultsCompleter.complete(<dynamic>[ad, error])),
          request: AdRequest(),
        );

        await banner.load();
        AdError adError = AdError(1, 'domain', 'error-message');
        AdapterResponseInfo adapterResponseInfo = AdapterResponseInfo(
          adapterClassName: 'adapter-name',
          latencyMillis: 500,
          description: 'message',
          adUnitMapping: {'key': 'value'},
          adError: adError,
          adSourceName: 'adSourceName',
          adSourceId: 'adSourceId',
          adSourceInstanceName: 'adSourceInstanceName',
          adSourceInstanceId: 'adSourceInstanceId',
        );

        List<AdapterResponseInfo> adapterResponses = [adapterResponseInfo];
        ResponseInfo responseInfo = ResponseInfo(
          responseId: 'id',
          mediationAdapterClassName: 'className',
          adapterResponses: adapterResponses,
          responseExtras: {'key': 'value'},
        );

        final MethodCall methodCall =
            MethodCall('onAdEvent', <dynamic, dynamic>{
          'adId': adId,
          'eventName': 'onAdFailedToLoad',
          'loadAdError': LoadAdError(1, 'domain', 'message', responseInfo),
        });

        final ByteData data =
            instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );

        final List<dynamic> results = await resultsCompleter.future;
        expect(results[0], banner);
        expect(results[1].code, 1);
        expect(results[1].domain, 'domain');
        expect(results[1].message, 'message');
        expect(results[1].responseInfo.responseId, responseInfo.responseId);
        expect(results[1].responseInfo.mediationAdapterClassName,
            responseInfo.mediationAdapterClassName);
        expect(results[1].responseInfo.responseExtras,
            responseInfo.responseExtras);
        List<AdapterResponseInfo> responses =
            results[1].responseInfo.adapterResponses;
        expect(responses.first.adapterClassName, 'adapter-name');
        expect(responses.first.latencyMillis, 500);
        expect(responses.first.description, 'message');
        expect(responses.first.adUnitMapping, {'key': 'value'});
        expect(responses.first.adError!.code, 1);
        expect(responses.first.adError!.message, 'error-message');
        expect(responses.first.adError!.domain, 'domain');
      };

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await testOnAdFailedToLoad(0);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await testOnAdFailedToLoad(1);
    });

    test('ios loaded events', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AdRequest request = AdRequest();

      // Check that listener callbacks are invoked
      Completer<Ad> loaded = Completer<Ad>();
      Completer<List<dynamic>> failedToLoad = Completer<List<dynamic>>();
      Completer<Ad> opened = Completer<Ad>();
      Completer<Ad> clicked = Completer<Ad>();
      Completer<Ad> impression = Completer<Ad>();
      Completer<Ad> closed = Completer<Ad>();
      Completer<Ad> willDismiss = Completer<Ad>();
      Completer<List<dynamic>> paidEvent = Completer<List<dynamic>>();

      BannerAdListener bannerListener = BannerAdListener(
        onAdLoaded: (ad) => loaded.complete(ad),
        onAdFailedToLoad: (ad, error) =>
            failedToLoad.complete(<Object>[ad, error]),
        onAdImpression: (ad) => impression.complete(ad),
        onPaidEvent: (ad, value, precision, currency) =>
            paidEvent.complete(<Object>[ad, value, precision, currency]),
        onAdClicked: (ad) => clicked.complete(ad),
        onAdClosed: (ad) => closed.complete(ad),
        onAdOpened: (ad) => opened.complete(ad),
        onAdWillDismissScreen: (ad) => willDismiss.complete(ad),
      );

      var bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: 'ad-unit',
        listener: bannerListener,
        request: request,
      );
      await bannerAd.load();

      expect(log, <Matcher>[
        isMethodCall('loadBannerAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'ad-unit',
          'request': request,
          'size': AdSize.banner,
        }),
      ]);

      // Simulate load callback
      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);

      BannerAd createdAd = instanceManager.adFor(0) as BannerAd;
      expect(instanceManager.adFor(0), isNotNull);
      expect(bannerAd, createdAd);
      expect(await loaded.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'onBannerImpression', instanceManager);
      expect(await impression.future, bannerAd);

      await TestUtil.sendAdEvent(0, 'adDidRecordClick', instanceManager);
      expect(await clicked.future, bannerAd);

      await TestUtil.sendAdEvent(
          0, 'onBannerWillPresentScreen', instanceManager);
      expect(await opened.future, bannerAd);

      await TestUtil.sendAdEvent(
          0, 'onBannerDidDismissScreen', instanceManager);
      expect(await closed.future, bannerAd);

      await TestUtil.sendAdEvent(
          0, 'onBannerWillDismissScreen', instanceManager);
      expect(await willDismiss.future, bannerAd);

      const paidEventArgs = {
        'valueMicros': 1.2345,
        'precision': 0,
        'currencyCode': 'USD',
      };
      await TestUtil.sendAdEvent(
          0, 'onPaidEvent', instanceManager, paidEventArgs);
      List<dynamic> paidEventCallback = await paidEvent.future;
      expect(paidEventCallback[0], bannerAd);
      expect(paidEventCallback[1], 1.2345);
      expect(paidEventCallback[2], PrecisionType.unknown);
      expect(paidEventCallback[3], 'USD');
    });

    test('dispose banner', () async {
      final BannerAd banner = BannerAd(
        adUnitId: 'test-ad-unit',
        size: AdSize.banner,
        listener: BannerAdListener(),
        request: AdRequest(),
      );

      await banner.load();
      log.clear();
      await banner.dispose();
      expect(log, <Matcher>[
        isMethodCall('disposeAd', arguments: <String, dynamic>{
          'adId': 0,
        })
      ]);

      expect(instanceManager.adFor(0), isNull);
      expect(instanceManager.adIdFor(banner), isNull);
    });

    test('calling dispose without awaiting load', () {
      final BannerAd banner = BannerAd(
        adUnitId: 'test-ad-unit',
        size: AdSize.banner,
        listener: BannerAdListener(),
        request: AdRequest(),
      );

      banner.load();
      banner.dispose();
      expect(instanceManager.adFor(0), isNull);
      expect(instanceManager.adIdFor(banner), isNull);
    });
  });
}
