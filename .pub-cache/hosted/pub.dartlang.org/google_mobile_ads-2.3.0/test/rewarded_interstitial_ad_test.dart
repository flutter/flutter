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

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'test_util.dart';

// ignore_for_file: deprecated_member_use_from_same_package
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rewarded Interstitial Ad Tests', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      log.clear();
      instanceManager =
          AdInstanceManager('plugins.flutter.io/google_mobile_ads');
      instanceManager.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'loadRewardedInterstitialAd':
          case 'showAdWithoutView':
          case 'disposeAd':
          case 'setServerSideVerificationOptions':
            return Future<void>.value();
          default:
            assert(false);
            return null;
        }
      });
    });

    test('load show rewarded interstitial android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      RewardedInterstitialAd? rewardedInterstitial;
      AdRequest request = AdRequest();
      await RewardedInterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedInterstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedInterstitialAd createdAd =
          instanceManager.adFor(0) as RewardedInterstitialAd;
      (createdAd).rewardedInterstitialAdLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadRewardedInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);
      expect(rewardedInterstitial, createdAd);

      log.clear();
      await rewardedInterstitial!
          .show(onUserEarnedReward: (ad, reward) => null);
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);

      // Check that full screen events are passed correctly.
      Completer<RewardedInterstitialAd> impressionCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> failedToShowCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> showedCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> dismissedCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> clickedCompleter =
          Completer<RewardedInterstitialAd>();

      rewardedInterstitial!.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdImpression: (ad) => impressionCompleter.complete(ad),
        onAdShowedFullScreenContent: (ad) => showedCompleter.complete(ad),
        onAdFailedToShowFullScreenContent: (ad, error) =>
            failedToShowCompleter.complete(ad),
        onAdDismissedFullScreenContent: (ad) => dismissedCompleter.complete(ad),
        onAdClicked: (ad) => clickedCompleter.complete(ad),
      );

      await TestUtil.sendAdEvent(0, 'onAdImpression', instanceManager);
      expect(await impressionCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(
          0, 'onAdShowedFullScreenContent', instanceManager);
      expect(await showedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(
          0, 'onAdDismissedFullScreenContent', instanceManager);
      expect(await dismissedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(0, 'onAdClicked', instanceManager);
      expect(await clickedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(0, 'onFailedToShowFullScreenContent',
          instanceManager, {'error': AdError(1, 'domain', 'message')});
      expect(await failedToShowCompleter.future, rewardedInterstitial);

      // Check paid event callback
      Completer<List<dynamic>> paidEventCompleter = Completer<List<dynamic>>();
      rewardedInterstitial!.onPaidEvent = (ad, value, precision, currency) {
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
      expect(paidEventCallback[0], rewardedInterstitial);
      expect(paidEventCallback[1], 1.2345);
      expect(paidEventCallback[2], PrecisionType.unknown);
      expect(paidEventCallback[3], 'USD');
    });

    test('load show rewarded interstitial ios', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      RewardedInterstitialAd? rewardedInterstitial;
      AdRequest request = AdRequest();
      await RewardedInterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedInterstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedInterstitialAd createdAd =
          instanceManager.adFor(0) as RewardedInterstitialAd;
      (createdAd).rewardedInterstitialAdLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadRewardedInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);
      expect(rewardedInterstitial, createdAd);

      log.clear();
      await rewardedInterstitial!
          .show(onUserEarnedReward: (ad, reward) => null);
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);

      // Check that full screen events are passed correctly.
      Completer<RewardedInterstitialAd> impressionCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> failedToShowCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> showedCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> dismissedCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> clickedCompleter =
          Completer<RewardedInterstitialAd>();
      Completer<RewardedInterstitialAd> willDismissCompleter =
          Completer<RewardedInterstitialAd>();

      rewardedInterstitial!.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdImpression: (ad) => impressionCompleter.complete(ad),
        onAdShowedFullScreenContent: (ad) => showedCompleter.complete(ad),
        onAdFailedToShowFullScreenContent: (ad, error) =>
            failedToShowCompleter.complete(ad),
        onAdDismissedFullScreenContent: (ad) => dismissedCompleter.complete(ad),
        onAdClicked: (ad) => clickedCompleter.complete(ad),
        onAdWillDismissFullScreenContent: (ad) =>
            willDismissCompleter.complete(ad),
      );

      await TestUtil.sendAdEvent(0, 'adDidRecordImpression', instanceManager);
      expect(await impressionCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(
          0, 'adWillPresentFullScreenContent', instanceManager);
      expect(await showedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(
          0, 'adDidDismissFullScreenContent', instanceManager);
      expect(await dismissedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(
          0, 'adWillDismissFullScreenContent', instanceManager);
      expect(await dismissedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(0, 'adDidRecordClick', instanceManager);
      expect(await clickedCompleter.future, rewardedInterstitial);

      await TestUtil.sendAdEvent(
          0,
          'didFailToPresentFullScreenContentWithError',
          instanceManager,
          {'error': AdError(1, 'domain', 'message')});
      expect(await failedToShowCompleter.future, rewardedInterstitial);

      // Check paid event callback
      Completer<List<dynamic>> paidEventCompleter = Completer<List<dynamic>>();
      rewardedInterstitial!.onPaidEvent = (ad, value, precision, currency) {
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
      expect(paidEventCallback[0], rewardedInterstitial);
      expect(paidEventCallback[1], 1.2345);
      expect(paidEventCallback[2], PrecisionType.unknown);
      expect(paidEventCallback[3], 'USD');
    });

    test('load show rewarded interstitial with $AdManagerAdRequest', () async {
      RewardedInterstitialAd? rewardedInterstitial;
      AdManagerAdRequest request = AdManagerAdRequest();
      await RewardedInterstitialAd.loadWithAdManagerAdRequest(
        adUnitId: 'test-ad-unit',
        adManagerRequest: request,
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedInterstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedInterstitialAd createdAd =
          instanceManager.adFor(0) as RewardedInterstitialAd;
      (createdAd).rewardedInterstitialAdLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadRewardedInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': null,
          'adManagerRequest': request,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      log.clear();
      await rewardedInterstitial!
          .show(onUserEarnedReward: (ad, reward) => null);
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);
    });

    test('onAdFailedToLoad rewarded interstitial', () async {
      final Completer<LoadAdError> resultsCompleter = Completer<LoadAdError>();
      final AdRequest request = AdRequest();
      await RewardedInterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) => null,
            onAdFailedToLoad: (error) => resultsCompleter.complete(error)),
      );

      expect(log, <Matcher>[
        isMethodCall('loadRewardedInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      // Simulate onAdFailedToLoad.
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
        responseExtras: {'key': 12345},
      );

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
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

      // The ad reference should be freed when load failure occurs.
      expect(instanceManager.adFor(0), isNull);

      // Check that load error matches.
      final LoadAdError result = await resultsCompleter.future;
      expect(result.code, 1);
      expect(result.domain, 'domain');
      expect(result.message, 'message');
      expect(result.responseInfo!.responseId, responseInfo.responseId);
      expect(result.responseInfo!.mediationAdapterClassName,
          responseInfo.mediationAdapterClassName);
      expect(result.responseInfo!.responseExtras, responseInfo.responseExtras);
      List<AdapterResponseInfo> responses =
          result.responseInfo!.adapterResponses!;
      expect(responses.first.adapterClassName, 'adapter-name');
      expect(responses.first.latencyMillis, 500);
      expect(responses.first.description, 'message');
      expect(responses.first.adUnitMapping, {'key': 'value'});
      expect(responses.first.adError!.code, 1);
      expect(responses.first.adError!.message, 'error-message');
      expect(responses.first.adError!.domain, 'domain');
    });

    test('onRewardedInterstitialAdUserEarnedReward', () async {
      final Completer<List<dynamic>> resultCompleter =
          Completer<List<dynamic>>();

      RewardedInterstitialAd? rewardedInterstitial;
      await RewardedInterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedInterstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedInterstitialAd createdAd =
          instanceManager.adFor(0) as RewardedInterstitialAd;
      createdAd.rewardedInterstitialAdLoadCallback.onAdLoaded(createdAd);
      // Reward callback is now set when you call show.
      await rewardedInterstitial!.show(
          onUserEarnedReward: (ad, item) =>
              resultCompleter.complete(<Object>[ad, item]));

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onRewardedInterstitialAdUserEarnedReward',
        'rewardItem': RewardItem(1, 'one'),
      });

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      final List<dynamic> result = await resultCompleter.future;
      expect(result[0], rewardedInterstitial!);
      expect(result[1].amount, 1);
      expect(result[1].type, 'one');
    });

    test('setServerSideVerificationOptions', () async {
      final adLoadCompleter = Completer<RewardedInterstitialAd>();
      await RewardedInterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              adLoadCompleter.complete(ad);
            },
            onAdFailedToLoad: (_) => null),
      );

      await TestUtil.sendAdEvent(0, 'onAdLoaded', instanceManager);
      expect(adLoadCompleter.isCompleted, true);
      final ad = await adLoadCompleter.future;

      log.clear();
      final ssv =
          ServerSideVerificationOptions(userId: 'id', customData: 'data');
      await ad.setServerSideOptions(ssv);
      expect(log, <Matcher>[
        isMethodCall('setServerSideVerificationOptions',
            arguments: <dynamic, dynamic>{
              'adId': 0,
              'serverSideVerificationOptions': ssv,
            }),
      ]);
    });
  });
}
