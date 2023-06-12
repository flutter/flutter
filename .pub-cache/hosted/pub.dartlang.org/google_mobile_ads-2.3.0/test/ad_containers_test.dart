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
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ignore_for_file: deprecated_member_use_from_same_package
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleMobileAds', () {
    final List<MethodCall> log = <MethodCall>[];
    final AdMessageCodec codec = AdMessageCodec();

    setUp(() async {
      log.clear();
      instanceManager =
          AdInstanceManager('plugins.flutter.io/google_mobile_ads');
      instanceManager.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'MobileAds#updateRequestConfiguration':
          case 'MobileAds#setSameAppKeyEnabled':
          case 'setImmersiveMode':
          case 'loadBannerAd':
          case 'loadNativeAd':
          case 'showAdWithoutView':
          case 'disposeAd':
          case 'loadRewardedAd':
          case 'loadInterstitialAd':
          case 'loadAdManagerInterstitialAd':
          case 'loadAdManagerBannerAd':
          case 'setServerSideVerificationOptions':
            return Future<void>.value();
          case 'getAdSize':
            return Future<dynamic>.value(AdSize.banner);
          default:
            assert(false);
            return null;
        }
      });
    });

    test('updateRequestConfiguration', () async {
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.ma,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        testDeviceIds: <String>['test-device-id'],
      );
      await instanceManager.updateRequestConfiguration(requestConfiguration);
      expect(log, <Matcher>[
        isMethodCall('MobileAds#updateRequestConfiguration',
            arguments: <String, dynamic>{
              'maxAdContentRating': MaxAdContentRating.ma,
              'tagForChildDirectedTreatment': TagForChildDirectedTreatment.yes,
              'tagForUnderAgeOfConsent': TagForUnderAgeOfConsent.yes,
              'testDeviceIds': <String>['test-device-id'],
            })
      ]);
    });

    test('setSameAppKeyEnabled', () async {
      await instanceManager.setSameAppKeyEnabled(true);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: <String, dynamic>{
              'isEnabled': true,
            })
      ]);

      await instanceManager.setSameAppKeyEnabled(false);

      expect(log, <Matcher>[
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: <String, dynamic>{
              'isEnabled': true,
            }),
        isMethodCall('MobileAds#setSameAppKeyEnabled',
            arguments: <String, dynamic>{
              'isEnabled': false,
            })
      ]);
    });

    test('load rewarded ad and set immersive mode and ssv', () async {
      RewardedAd? rewarded;
      AdRequest request = AdRequest();
      await RewardedAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewarded = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedAd createdAd = instanceManager.adFor(0) as RewardedAd;
      (createdAd).rewardedAdLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadRewardedAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);
      expect(rewarded, createdAd);

      // Set immersive mode
      log.clear();
      await createdAd.setImmersiveMode(true);
      expect(log, <Matcher>[
        isMethodCall('setImmersiveMode',
            arguments: {'adId': 0, 'immersiveModeEnabled': true})
      ]);

      // Set ssv
      log.clear();
      final ssv = ServerSideVerificationOptions();
      await createdAd.setServerSideOptions(ssv);
      expect(log, <Matcher>[
        isMethodCall('setServerSideVerificationOptions',
            arguments: {'adId': 0, 'serverSideVerificationOptions': ssv})
      ]);
    });

    test('load interstitial ad and set immersive mode', () async {
      InterstitialAd? interstitial;
      await InterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              interstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      InterstitialAd createdAd = (instanceManager.adFor(0) as InterstitialAd);
      (createdAd).adLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': interstitial!.request,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      log.clear();
      await createdAd.setImmersiveMode(false);
      expect(log, <Matcher>[
        isMethodCall('setImmersiveMode',
            arguments: {'adId': 0, 'immersiveModeEnabled': false})
      ]);
    });

    test('load ad manager interstitial and set immersive mode', () async {
      AdManagerInterstitialAd? interstitial;
      await AdManagerInterstitialAd.load(
        adUnitId: 'test-id',
        request: AdManagerAdRequest(),
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              interstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      AdManagerInterstitialAd createdAd =
          (instanceManager.adFor(0) as AdManagerInterstitialAd);
      (createdAd).adLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadAdManagerInterstitialAd',
            arguments: <String, dynamic>{
              'adId': 0,
              'adUnitId': 'test-id',
              'request': interstitial!.request,
            })
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      log.clear();
      await createdAd.setImmersiveMode(true);
      expect(log, <Matcher>[
        isMethodCall('setImmersiveMode',
            arguments: {'adId': 0, 'immersiveModeEnabled': true})
      ]);
    });

    test('load native', () async {
      final Map<String, Object> options = <String, Object>{'a': 1, 'b': 2};
      final NativeAdOptions nativeAdOptions = NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.bottomLeftCorner,
          mediaAspectRatio: MediaAspectRatio.any,
          videoOptions: VideoOptions(
            clickToExpandRequested: true,
            customControlsRequested: true,
            startMuted: true,
          ),
          requestCustomMuteThisAd: false,
          shouldRequestMultipleImages: true,
          shouldReturnUrlsForImageAssets: false);
      final NativeAd native = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        customOptions: options,
        listener: NativeAdListener(),
        request: AdRequest(),
        nativeAdOptions: nativeAdOptions,
      );

      await native.load();
      expect(log, <Matcher>[
        isMethodCall('loadNativeAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': native.request,
          'adManagerRequest': null,
          'factoryId': '0',
          'nativeAdOptions': nativeAdOptions,
          'customOptions': options,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    test('load native with $AdManagerAdRequest', () async {
      final Map<String, Object> options = <String, Object>{'a': 1, 'b': 2};

      final NativeAd native = NativeAd.fromAdManagerRequest(
        adUnitId: 'test-id',
        factoryId: '0',
        customOptions: options,
        listener: NativeAdListener(),
        adManagerRequest: AdManagerAdRequest(),
      );

      await native.load();
      expect(log, <Matcher>[
        isMethodCall('loadNativeAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-id',
          'request': null,
          'adManagerRequest': native.adManagerRequest,
          'factoryId': '0',
          'nativeAdOptions': null,
          'customOptions': options,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);
    });

    testWidgets('build ad widget iOS', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final NativeAd native = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await native.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              child: Column(
                key: UniqueKey(),
                children: [
                  SizedBox.fromSize(size: Size(200, 1000)),
                  Container(
                    height: 200,
                    width: 200,
                    child: AdWidget(ad: native),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final uiKitView = tester.widget(find.byType(UiKitView));
      expect(uiKitView, isNotNull);

      await native.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Build ad widget Android', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      // Create a loaded ad
      final ad = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );
      await ad.load();

      // Render ad in a scrolling view
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              child: Column(
                key: UniqueKey(),
                children: [
                  SizedBox.fromSize(size: Size(200, 1000)),
                  Container(
                    height: 200,
                    width: 200,
                    child: AdWidget(ad: ad),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On initial render, VisibilityRender should be in the UI
      final visibilityDetectorWidget =
          tester.widget(find.byKey(Key('android-platform-view-0')));
      expect(visibilityDetectorWidget, isNotNull);
      expect(visibilityDetectorWidget, isA<VisibilityDetector>());
      final platformViewLinks =
          tester.widgetList(find.byType(PlatformViewLink));
      expect(platformViewLinks.isEmpty, true);

      // Drag the ad widget into view
      await tester.drag(find.byType(SingleChildScrollView), Offset(0.0, -1000));
      await tester.pumpAndSettle();

      // PlatformViewLink should now be present instead of VisibilityDetector
      final detectors = tester.widgetList(find.byType(VisibilityDetector));
      expect(detectors.isEmpty, true);
      final platformViewLink = tester.widget(find.byType(PlatformViewLink));
      expect(platformViewLink, isNotNull);

      // Reset platform override
      await ad.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('warns when ad has not been loaded',
        (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: <Widget>[
                  AdWidget(ad: ad),
                ],
              ),
            ),
          ),
        );
      } finally {
        dynamic exception = tester.takeException();
        expect(exception, isA<FlutterError>());
        expect(
            (exception as FlutterError).toStringDeep(),
            'FlutterError\n'
            '   AdWidget requires Ad.load to be called before AdWidget is\n'
            '   inserted into the tree\n'
            '   Parameter ad is not loaded. Call Ad.load before AdWidget is\n'
            '   inserted into the tree.\n');
      }
    });

    testWidgets('warns when ad object is reused', (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await ad.load();

      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: <Widget>[
                  AdWidget(ad: ad),
                  AdWidget(ad: ad),
                ],
              ),
            ),
          ),
        );
      } finally {
        dynamic exception = tester.takeException();
        expect(exception, isA<FlutterError>());
        expect(
            (exception as FlutterError).toStringDeep(),
            'FlutterError\n'
            '   This AdWidget is already in the Widget tree\n'
            '   If you placed this AdWidget in a list, make sure you create a new\n'
            '   instance in the builder function with a unique ad object.\n'
            '   Make sure you are not using the same ad object in more than one\n'
            '   AdWidget.\n'
            '');
      }
    });

    testWidgets('warns when the widget is reused', (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );

      await ad.load();

      final AdWidget widget = AdWidget(ad: ad);
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: <Widget>[
                  widget,
                  widget,
                ],
              ),
            ),
          ),
        );
      } finally {
        dynamic exception = tester.takeException();
        expect(exception, isA<FlutterError>());
        expect(
            (exception as FlutterError).toStringDeep(),
            'FlutterError\n'
            '   This AdWidget is already in the Widget tree\n'
            '   If you placed this AdWidget in a list, make sure you create a new\n'
            '   instance in the builder function with a unique ad object.\n'
            '   Make sure you are not using the same ad object in more than one\n'
            '   AdWidget.\n'
            '');
      }
    });

    testWidgets(
        'ad objects can be reused if the widget holding the object is disposed',
        (WidgetTester tester) async {
      final NativeAd ad = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: '0',
        listener: NativeAdListener(),
        request: AdRequest(),
      );
      await ad.load();
      final AdWidget widget = AdWidget(ad: ad);
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: widget,
            ),
          ),
        );

        await tester.pumpWidget(Container());

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 100,
              height: 100,
              child: widget,
            ),
          ),
        );
      } finally {
        expect(tester.takeException(), isNull);
      }
    });

    test('load show rewarded', () async {
      RewardedAd? rewarded;
      AdRequest request = AdRequest();
      await RewardedAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewarded = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedAd createdAd = instanceManager.adFor(0) as RewardedAd;
      (createdAd).rewardedAdLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadRewardedAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
          'adManagerRequest': null,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);
      expect(rewarded, createdAd);

      log.clear();
      await rewarded!.show(onUserEarnedReward: (ad, reward) => null);
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);
    });

    test('load show rewarded with $AdManagerAdRequest', () async {
      RewardedAd? rewarded;
      AdManagerAdRequest request = AdManagerAdRequest();
      await RewardedAd.loadWithAdManagerAdRequest(
        adUnitId: 'test-ad-unit',
        adManagerRequest: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewarded = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      RewardedAd createdAd = instanceManager.adFor(0) as RewardedAd;
      (createdAd).rewardedAdLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadRewardedAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': null,
          'adManagerRequest': request,
        }),
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      log.clear();
      await rewarded!.show(onUserEarnedReward: (ad, reward) => null);
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);
    });

    test('load show interstitial', () async {
      InterstitialAd? interstitial;
      await InterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              interstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      InterstitialAd createdAd = (instanceManager.adFor(0) as InterstitialAd);
      (createdAd).adLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': interstitial!.request,
        })
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      log.clear();
      await interstitial!.show();
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);
    });

    test('load show ad manager interstitial', () async {
      AdManagerInterstitialAd? interstitial;
      await AdManagerInterstitialAd.load(
        adUnitId: 'test-id',
        request: AdManagerAdRequest(),
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              interstitial = ad;
            },
            onAdFailedToLoad: (error) => null),
      );

      AdManagerInterstitialAd createdAd =
          (instanceManager.adFor(0) as AdManagerInterstitialAd);
      (createdAd).adLoadCallback.onAdLoaded(createdAd);

      expect(log, <Matcher>[
        isMethodCall('loadAdManagerInterstitialAd',
            arguments: <String, dynamic>{
              'adId': 0,
              'adUnitId': 'test-id',
              'request': interstitial!.request,
            })
      ]);

      expect(instanceManager.adFor(0), isNotNull);

      log.clear();
      await interstitial!.show();
      expect(log, <Matcher>[
        isMethodCall('showAdWithoutView', arguments: <dynamic, dynamic>{
          'adId': 0,
        })
      ]);
    });

    test('onAdFailedToLoad interstitial', () async {
      final Completer<LoadAdError> resultsCompleter = Completer<LoadAdError>();
      final AdRequest request = AdRequest();
      await InterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) => null,
            onAdFailedToLoad: (error) => resultsCompleter.complete(error)),
      );

      expect(log, <Matcher>[
        isMethodCall('loadInterstitialAd', arguments: <String, dynamic>{
          'adId': 0,
          'adUnitId': 'test-ad-unit',
          'request': request,
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
        responseExtras: {'key1': 'value1'},
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

    test('onAdFailedToLoad ad manager interstitial', () async {
      final Completer<LoadAdError> resultsCompleter = Completer<LoadAdError>();
      final AdManagerAdRequest request = AdManagerAdRequest();
      await AdManagerInterstitialAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
            onAdLoaded: (ad) => null,
            onAdFailedToLoad: (error) => resultsCompleter.complete(error)),
      );

      expect(log, <Matcher>[
        isMethodCall('loadAdManagerInterstitialAd',
            arguments: <String, dynamic>{
              'adId': 0,
              'adUnitId': 'test-ad-unit',
              'request': request,
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
        responseExtras: {},
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

    test('onAdFailedToLoad rewarded', () async {
      final Completer<LoadAdError> resultsCompleter = Completer<LoadAdError>();
      final AdRequest request = AdRequest();
      await RewardedAd.load(
        adUnitId: 'test-ad-unit',
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) => null,
            onAdFailedToLoad: (error) => resultsCompleter.complete(error)),
      );

      expect(log, <Matcher>[
        isMethodCall('loadRewardedAd', arguments: <String, dynamic>{
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
        responseExtras: {'key1': 1234},
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

    test('onNativeAdImpression', () async {
      final Completer<Ad> adEventCompleter = Completer<Ad>();

      final NativeAd native = NativeAd(
        adUnitId: 'test-ad-unit',
        factoryId: 'testId',
        listener: NativeAdListener(
            onAdImpression: (Ad ad) => adEventCompleter.complete(ad)),
        request: AdRequest(),
      );

      await native.load();

      final MethodCall methodCall = MethodCall('onAdEvent',
          <dynamic, dynamic>{'adId': 0, 'eventName': 'onAdImpression'});

      final ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      expect(adEventCompleter.future, completion(native));
    });

    test('AdapterResponseInfo encoding', () async {
      var testAdapterResponseInfo = (adId) async {
        final Completer<Ad> loadCompleter = Completer<Ad>();

        AdRequest request = AdRequest();
        await RewardedAd.load(
            adUnitId: 'test-ad-unit',
            request: request,
            rewardedAdLoadCallback: RewardedAdLoadCallback(
                onAdLoaded: (ad) {
                  loadCompleter.complete(ad);
                },
                onAdFailedToLoad: (error) => null));

        AdapterResponseInfo adapterResponseInfo = AdapterResponseInfo(
          adapterClassName: 'adapter-name',
          latencyMillis: 500,
          description: 'message',
          adUnitMapping: {'key': 'value'},
          adSourceName: 'adSourceName',
          adSourceId: 'adSourceId',
          adSourceInstanceName: 'adSourceInstanceName',
          adSourceInstanceId: 'adSourceInstanceId',
        );
        final loadedAdapterResponseInfo = AdapterResponseInfo(
          adapterClassName: 'adapter-name',
          latencyMillis: 500,
          description: 'message',
          adUnitMapping: {'key': 'value'},
          adSourceName: 'adSourceName',
          adSourceId: 'adSourceId',
          adSourceInstanceName: 'adSourceInstanceName',
          adSourceInstanceId: 'adSourceInstanceId',
        );

        final responseInfo = ResponseInfo(
          mediationAdapterClassName: 'adapter',
          adapterResponses: [adapterResponseInfo],
          responseId: 'id',
          loadedAdapterResponseInfo: loadedAdapterResponseInfo,
          responseExtras: {},
        );
        final methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
          'adId': adId,
          'eventName': 'onAdLoaded',
          'responseInfo': responseInfo,
        });

        ByteData data =
            instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );
        final ad = await loadCompleter.future;

        expect(ad.responseInfo!.mediationAdapterClassName!, 'adapter');
        expect(ad.responseInfo!.responseId!, 'id');
        expect(ad.responseInfo!.responseExtras, responseInfo.responseExtras);
        final adapterResponse = ad.responseInfo!.adapterResponses!.first;
        expect(adapterResponse.adapterClassName, 'adapter-name');
        expect(adapterResponse.latencyMillis, 500);
        expect(adapterResponse.description, 'message');
        expect(adapterResponse.adUnitMapping, {'key': 'value'});
        expect(adapterResponse.adSourceName, 'adSourceName');
        expect(adapterResponse.adSourceId, 'adSourceId');
        expect(adapterResponse.adSourceInstanceName, 'adSourceInstanceName');
        expect(adapterResponse.adSourceInstanceId, 'adSourceInstanceId');
        final loadedResponse = ad.responseInfo!.loadedAdapterResponseInfo!;
        expect(loadedResponse.adapterClassName, 'adapter-name');
        expect(loadedResponse.latencyMillis, 500);
        expect(loadedResponse.description, 'message');
        expect(loadedResponse.adUnitMapping, {'key': 'value'});
        expect(loadedResponse.adSourceName, 'adSourceName');
        expect(loadedResponse.adSourceId, 'adSourceId');
        expect(loadedResponse.adSourceInstanceName, 'adSourceInstanceName');
        expect(loadedResponse.adSourceInstanceId, 'adSourceInstanceId');
      };
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await testAdapterResponseInfo(0);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await testAdapterResponseInfo(1);
    });

    test('onRewardedAdUserEarnedReward', () async {
      final Completer<List<dynamic>> resultCompleter =
          Completer<List<dynamic>>();

      RewardedAd? rewarded;
      await RewardedAd.load(
          adUnitId: 'test-ad-unit',
          request: AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
              onAdLoaded: (ad) {
                rewarded = ad;
              },
              onAdFailedToLoad: (error) => null));

      RewardedAd createdAd = instanceManager.adFor(0) as RewardedAd;
      createdAd.rewardedAdLoadCallback.onAdLoaded(createdAd);
      // Reward callback is now set when you call show.
      await rewarded!.show(
          onUserEarnedReward: (ad, item) =>
              resultCompleter.complete(<Object>[ad, item]));

      final MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onRewardedAdUserEarnedReward',
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
      expect(result[0], rewarded!);
      expect(result[1].amount, 1);
      expect(result[1].type, 'one');
    });

    test('onPaidEvent', () async {
      Completer<List<dynamic>> resultCompleter = Completer<List<dynamic>>();

      final BannerAd banner = BannerAd(
        adUnitId: 'test-ad-unit',
        size: AdSize.banner,
        listener: BannerAdListener(
          onPaidEvent: (Ad ad, double value, precision, String currencyCode) =>
              resultCompleter
                  .complete(<Object>[ad, value, precision, currencyCode]),
        ),
        request: AdRequest(),
      );

      await banner.load();

      // Check precision type: unknown
      MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onPaidEvent',
        'valueMicros': 1.2345,
        'precision': 0,
        'currencyCode': 'USD',
      });

      ByteData data =
          instanceManager.channel.codec.encodeMethodCall(methodCall);

      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        data,
        (ByteData? data) {},
      );

      List<dynamic> result = await resultCompleter.future;
      expect(result[0], banner);
      expect(result[1], 1.2345);
      expect(result[2], PrecisionType.unknown);
      expect(result[3], 'USD');

      // Unknown precision outside 0-3 range.
      resultCompleter = Completer<List<dynamic>>();
      methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onPaidEvent',
        'valueMicros': 1.2345,
        'precision': 9999,
        'currencyCode': 'USD',
      });
      data = instanceManager.channel.codec.encodeMethodCall(methodCall);
      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        instanceManager.channel.codec.encodeMethodCall(methodCall),
        (ByteData? data) {},
      );
      result = await resultCompleter.future;
      expect(result[2], PrecisionType.unknown);

      // Check precision type: estimated.
      // Also check that callback is invoked successfully for int valueMicros.
      resultCompleter = Completer<List<dynamic>>();
      methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onPaidEvent',
        'valueMicros': 12345, // int
        'precision': 1,
        'currencyCode': 'USD',
      });
      data = instanceManager.channel.codec.encodeMethodCall(methodCall);
      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        instanceManager.channel.codec.encodeMethodCall(methodCall),
        (ByteData? data) {},
      );
      result = await resultCompleter.future;
      expect(result[1], 12345);
      expect(result[2], PrecisionType.estimated);

      // Check precision type: publisherProvided.
      resultCompleter = Completer<List<dynamic>>();
      methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onPaidEvent',
        'valueMicros': 1.2345,
        'precision': 2,
        'currencyCode': 'USD',
      });
      data = instanceManager.channel.codec.encodeMethodCall(methodCall);
      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        instanceManager.channel.codec.encodeMethodCall(methodCall),
        (ByteData? data) {},
      );
      result = await resultCompleter.future;
      expect(result[2], PrecisionType.publisherProvided);

      // Check precision type: precise.
      resultCompleter = Completer<List<dynamic>>();
      methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
        'adId': 0,
        'eventName': 'onPaidEvent',
        'valueMicros': 1.2345,
        'precision': 3,
        'currencyCode': 'USD',
      });
      data = instanceManager.channel.codec.encodeMethodCall(methodCall);
      await instanceManager.channel.binaryMessenger.handlePlatformMessage(
        'plugins.flutter.io/google_mobile_ads',
        instanceManager.channel.codec.encodeMethodCall(methodCall),
        (ByteData? data) {},
      );
      result = await resultCompleter.future;
      expect(result[2], PrecisionType.precise);
    });

    test('encode/decode AdSize', () async {
      final ByteData byteData = codec.encodeMessage(AdSize.banner)!;
      expect(codec.decodeMessage(byteData), AdSize.banner);
    });

    test('encode/decode AdRequest Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final AdRequest adRequest = AdRequest(
        keywords: <String>['1', '2', '3'],
        contentUrl: 'contentUrl',
        nonPersonalizedAds: false,
        neighboringContentUrls: <String>['url1.com', 'url2.com'],
        httpTimeoutMillis: 12345,
        mediationExtrasIdentifier: 'identifier',
        extras: {'key': 'value'},
      );

      final AdRequest decodedRequest = AdRequest(
        keywords: <String>['1', '2', '3'],
        contentUrl: 'contentUrl',
        nonPersonalizedAds: false,
        neighboringContentUrls: <String>['url1.com', 'url2.com'],
        httpTimeoutMillis: 12345,
        mediationExtrasIdentifier: 'identifier',
        extras: {'key': 'value'},
      );
      final ByteData byteData = codec.encodeMessage(adRequest)!;
      expect(codec.decodeMessage(byteData), decodedRequest);
    });

    test('encode/decode AdRequest iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final AdRequest adRequest = AdRequest(
        keywords: <String>['1', '2', '3'],
        contentUrl: 'contentUrl',
        nonPersonalizedAds: false,
        neighboringContentUrls: <String>['url1.com', 'url2.com'],
        httpTimeoutMillis: 12345,
        mediationExtrasIdentifier: 'identifier',
        extras: {'key': 'value'},
      );

      final ByteData byteData = codec.encodeMessage(adRequest)!;
      AdRequest decoded = codec.decodeMessage(byteData);
      expect(decoded.httpTimeoutMillis, null);
      expect(decoded.neighboringContentUrls, adRequest.neighboringContentUrls);
      expect(decoded.contentUrl, adRequest.contentUrl);
      expect(decoded.nonPersonalizedAds, adRequest.nonPersonalizedAds);
      expect(decoded.keywords, adRequest.keywords);
      expect(decoded.mediationExtrasIdentifier, 'identifier');
    });

    test('encode/decode $LoadAdError', () async {
      final ResponseInfo responseInfo = ResponseInfo(
        responseId: 'id',
        mediationAdapterClassName: 'class',
        adapterResponses: null,
        responseExtras: {},
      );
      final ByteData byteData = codec.encodeMessage(
        LoadAdError(1, 'domain', 'message', responseInfo),
      )!;
      final LoadAdError error = codec.decodeMessage(byteData);
      expect(error.code, 1);
      expect(error.domain, 'domain');
      expect(error.message, 'message');
      expect(error.responseInfo?.responseId, responseInfo.responseId);
      expect(error.responseInfo?.responseExtras, responseInfo.responseExtras);
      expect(error.responseInfo?.mediationAdapterClassName,
          responseInfo.mediationAdapterClassName);
      expect(error.responseInfo?.adapterResponses, null);
    });

    test('encode/decode $RewardItem', () async {
      final ByteData byteData = codec.encodeMessage(RewardItem(1, 'type'))!;

      final RewardItem result = codec.decodeMessage(byteData);
      expect(result.amount, 1);
      expect(result.type, 'type');
    });

    test('encode/decode $InlineAdaptiveSize', () async {
      ByteData byteData = codec.encodeMessage(
          AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(100))!;

      InlineAdaptiveSize result = codec.decodeMessage(byteData);
      expect(result.orientation, null);
      expect(result.width, 100);
      expect(result.maxHeight, null);
      expect(result.height, 0);

      byteData = codec
          .encodeMessage(AdSize.getPortraitInlineAdaptiveBannerAdSize(200))!;

      result = codec.decodeMessage(byteData);
      expect(result.orientation, Orientation.portrait);
      expect(result.width, 200);
      expect(result.maxHeight, null);
      expect(result.height, 0);

      byteData = codec
          .encodeMessage(AdSize.getLandscapeInlineAdaptiveBannerAdSize(20))!;

      result = codec.decodeMessage(byteData);
      expect(result.orientation, Orientation.landscape);
      expect(result.width, 20);
      expect(result.maxHeight, null);
      expect(result.height, 0);

      byteData =
          codec.encodeMessage(AdSize.getInlineAdaptiveBannerAdSize(20, 50))!;

      result = codec.decodeMessage(byteData);
      expect(result.orientation, null);
      expect(result.width, 20);
      expect(result.maxHeight, 50);
      expect(result.height, 0);
    });

    test('encode/decode $AnchoredAdaptiveBannerAdSize', () async {
      final ByteData byteDataPortrait = codec.encodeMessage(
          AnchoredAdaptiveBannerAdSize(Orientation.portrait,
              width: 23, height: 34))!;

      final AnchoredAdaptiveBannerAdSize resultPortrait =
          codec.decodeMessage(byteDataPortrait);
      expect(resultPortrait.orientation, Orientation.portrait);
      expect(resultPortrait.width, 23);
      expect(resultPortrait.height, -1);

      final ByteData byteDataLandscape = codec.encodeMessage(
          AnchoredAdaptiveBannerAdSize(Orientation.landscape,
              width: 34, height: 23))!;

      final AnchoredAdaptiveBannerAdSize resultLandscape =
          codec.decodeMessage(byteDataLandscape);
      expect(resultLandscape.orientation, Orientation.landscape);
      expect(resultLandscape.width, 34);
      expect(resultLandscape.height, -1);

      final ByteData byteData = codec.encodeMessage(
          AnchoredAdaptiveBannerAdSize(null, width: 45, height: 34))!;

      final AnchoredAdaptiveBannerAdSize result = codec.decodeMessage(byteData);
      expect(result.orientation, null);
      expect(result.width, 45);
      expect(result.height, -1);
    });

    test('encode/decode $SmartBannerAdSize', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ByteData byteData =
          codec.encodeMessage(SmartBannerAdSize(Orientation.portrait))!;

      final SmartBannerAdSize result = codec.decodeMessage(byteData);
      expect(result.orientation, Orientation.portrait);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final WriteBuffer expectedBuffer = WriteBuffer();
      expectedBuffer.putUint8(143);

      final WriteBuffer actualBuffer = WriteBuffer();
      codec.writeAdSize(actualBuffer, SmartBannerAdSize(Orientation.portrait));
      expect(
        expectedBuffer.done().buffer.asInt8List(),
        actualBuffer.done().buffer.asInt8List(),
      );
    });

    test('encode/decode $FluidAdSize', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ByteData byteData = codec.encodeMessage(FluidAdSize())!;

      final FluidAdSize result = codec.decodeMessage(byteData);
      expect(result.width, -3);
      expect(result.height, -3);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final WriteBuffer expectedBuffer = WriteBuffer();
      expectedBuffer.putUint8(130);

      final WriteBuffer actualBuffer = WriteBuffer();
      codec.writeAdSize(actualBuffer, FluidAdSize());
      expect(
        expectedBuffer.done().buffer.asInt8List(),
        actualBuffer.done().buffer.asInt8List(),
      );
    });

    test('encode/decode $AdManagerAdRequest Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final AdManagerAdRequest request = AdManagerAdRequest(
        keywords: <String>['who'],
        contentUrl: 'dat',
        customTargeting: <String, String>{'boy': 'who'},
        customTargetingLists: <String, List<String>>{
          'him': <String>['is']
        },
        nonPersonalizedAds: true,
        neighboringContentUrls: <String>['url1.com', 'url2.com'],
        httpTimeoutMillis: 5000,
        publisherProvidedId: 'test-pub-id',
        mediationExtrasIdentifier: 'identifier',
        extras: {'key': 'value'},
      );
      final ByteData byteData = codec.encodeMessage(request)!;

      final AdManagerAdRequest decodedRequest = AdManagerAdRequest(
        keywords: <String>['who'],
        contentUrl: 'dat',
        customTargeting: <String, String>{'boy': 'who'},
        customTargetingLists: <String, List<String>>{
          'him': <String>['is']
        },
        nonPersonalizedAds: true,
        neighboringContentUrls: <String>['url1.com', 'url2.com'],
        httpTimeoutMillis: 5000,
        publisherProvidedId: 'test-pub-id',
        mediationExtrasIdentifier: 'identifier',
        extras: {'key': 'value'},
      );
      expect(
        codec.decodeMessage(byteData),
        decodedRequest,
      );
    });

    test('encode/decode $AdManagerAdRequest iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final AdManagerAdRequest request = AdManagerAdRequest(
        keywords: <String>['who'],
        contentUrl: 'dat',
        customTargeting: <String, String>{'boy': 'who'},
        customTargetingLists: <String, List<String>>{
          'him': <String>['is']
        },
        nonPersonalizedAds: true,
        neighboringContentUrls: <String>['url1.com', 'url2.com'],
        httpTimeoutMillis: 5000,
        publisherProvidedId: 'test-pub-id',
        mediationExtrasIdentifier: 'identifier',
        extras: {'key': 'value'},
      );

      final ByteData byteData = codec.encodeMessage(request)!;
      AdManagerAdRequest decoded = codec.decodeMessage(byteData);
      expect(decoded.httpTimeoutMillis, null);
      expect(decoded.neighboringContentUrls, request.neighboringContentUrls);
      expect(decoded.contentUrl, request.contentUrl);
      expect(decoded.nonPersonalizedAds, request.nonPersonalizedAds);
      expect(decoded.keywords, request.keywords);
      expect(decoded.publisherProvidedId, request.publisherProvidedId);
      expect(decoded.customTargeting, request.customTargeting);
      expect(decoded.customTargetingLists, request.customTargetingLists);
      expect(decoded.mediationExtrasIdentifier, 'identifier');
    });

    test('ad click native', () async {
      var testNativeClick = (eventName, adId) async {
        final Completer<Ad> adClickCompleter = Completer<Ad>();

        final NativeAd native = NativeAd(
          adUnitId: 'test-ad-unit',
          factoryId: 'testId',
          listener: NativeAdListener(
              onAdClicked: (ad) => adClickCompleter.complete(ad)),
          request: AdRequest(),
        );

        await native.load();

        final MethodCall methodCall = MethodCall('onAdEvent',
            <dynamic, dynamic>{'adId': adId, 'eventName': eventName});

        final ByteData data =
            instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );

        expect(adClickCompleter.future, completion(native));
      };

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await testNativeClick('adDidRecordClick', 0);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await testNativeClick('onAdClicked', 1);
    });

    test('ad click rewarded', () async {
      var testRewardedClick = (eventName, adId) async {
        final Completer<Ad> adClickCompleter = Completer<Ad>();

        // Load an ad
        RewardedAd? rewarded;
        AdRequest request = AdRequest();
        await RewardedAd.load(
            adUnitId: 'test-ad-unit',
            request: request,
            rewardedAdLoadCallback: RewardedAdLoadCallback(
                onAdLoaded: (ad) {
                  rewarded = ad;
                  ad.fullScreenContentCallback = FullScreenContentCallback(
                      onAdClicked: (ad) => adClickCompleter.complete(ad));
                },
                onAdFailedToLoad: (error) => null));

        MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
          'adId': adId,
          'eventName': 'onAdLoaded',
        });

        ByteData data =
            instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );

        // Handle adDidRecordClick method call
        methodCall = MethodCall('onAdEvent',
            <dynamic, dynamic>{'adId': adId, 'eventName': eventName});

        data = instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );
        expect(adClickCompleter.future, completion(rewarded!));
      };

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await testRewardedClick('adDidRecordClick', 0);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await testRewardedClick('onAdClicked', 1);
    });

    test('ad click interstitial', () async {
      var testClick = (eventName, adId) async {
        final Completer<Ad> adClickCompleter = Completer<Ad>();

        // Load an ad
        InterstitialAd? interstitialAd;
        AdRequest request = AdRequest();
        await InterstitialAd.load(
          adUnitId: 'test-ad-unit',
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                interstitialAd = ad;
                ad.fullScreenContentCallback = FullScreenContentCallback(
                    onAdClicked: (ad) => adClickCompleter.complete(ad));
              },
              onAdFailedToLoad: (error) => null),
        );

        MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
          'adId': adId,
          'eventName': 'onAdLoaded',
        });

        ByteData data =
            instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );

        // Handle adDidRecordClick method call
        methodCall = MethodCall('onAdEvent',
            <dynamic, dynamic>{'adId': adId, 'eventName': eventName});

        data = instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );
        expect(adClickCompleter.future, completion(interstitialAd!));
      };

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await testClick('adDidRecordClick', 0);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await testClick('onAdClicked', 1);
    });

    test('ad click interstitial', () async {
      var testClick = (eventName, adId) async {
        final Completer<Ad> adClickCompleter = Completer<Ad>();

        // Load an ad
        InterstitialAd? interstitialAd;
        AdRequest request = AdRequest();
        await InterstitialAd.load(
          adUnitId: 'test-ad-unit',
          request: request,
          adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) {
                interstitialAd = ad;
                ad.fullScreenContentCallback = FullScreenContentCallback(
                    onAdClicked: (ad) => adClickCompleter.complete(ad));
              },
              onAdFailedToLoad: (error) => null),
        );

        MethodCall methodCall = MethodCall('onAdEvent', <dynamic, dynamic>{
          'adId': adId,
          'eventName': 'onAdLoaded',
        });

        ByteData data =
            instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );

        // Handle adDidRecordClick method call
        methodCall = MethodCall('onAdEvent',
            <dynamic, dynamic>{'adId': adId, 'eventName': eventName});

        data = instanceManager.channel.codec.encodeMethodCall(methodCall);

        await instanceManager.channel.binaryMessenger.handlePlatformMessage(
          'plugins.flutter.io/google_mobile_ads',
          data,
          (ByteData? data) {},
        );
        expect(adClickCompleter.future, completion(interstitialAd!));
      };

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await testClick('adDidRecordClick', 0);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await testClick('onAdClicked', 1);
    });
  });
}
