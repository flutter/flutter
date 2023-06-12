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

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'constants.dart';
import 'dart:io' show Platform;

/// This example demonstrates inline ads in a list view, where the ad objects
/// live for the lifetime of this widget.
class ReusableInlineExample extends StatefulWidget {
  @override
  _ReusableInlineExampleState createState() => _ReusableInlineExampleState();
}

class _ReusableInlineExampleState extends State<ReusableInlineExample> {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  AdManagerBannerAd? _adManagerBannerAd;
  bool _adManagerBannerAdIsLoaded = false;

  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.separated(
            itemCount: 20,
            separatorBuilder: (BuildContext context, int index) {
              return Container(
                height: 40,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final BannerAd? bannerAd = _bannerAd;
              if (index == 5 && _bannerAdIsLoaded && bannerAd != null) {
                return Container(
                    height: bannerAd.size.height.toDouble(),
                    width: bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: bannerAd));
              }

              final AdManagerBannerAd? adManagerBannerAd = _adManagerBannerAd;
              if (index == 10 &&
                  _adManagerBannerAdIsLoaded &&
                  adManagerBannerAd != null) {
                return Container(
                    height: adManagerBannerAd.sizes[0].height.toDouble(),
                    width: adManagerBannerAd.sizes[0].width.toDouble(),
                    child: AdWidget(ad: _adManagerBannerAd!));
              }

              final NativeAd? nativeAd = _nativeAd;
              if (index == 15 && _nativeAdIsLoaded && nativeAd != null) {
                return Container(
                    width: 250, height: 350, child: AdWidget(ad: nativeAd));
              }

              return Text(
                Constants.placeholderText,
                style: TextStyle(fontSize: 24),
              );
            },
          ),
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create the ad objects and load ads.
    _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716',
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            print('$BannerAd loaded.');
            setState(() {
              _bannerAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('$BannerAd failedToLoad: $error');
            ad.dispose();
          },
          onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
          onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
        ),
        request: AdRequest())
      ..load();

    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511',
      request: AdRequest(),
      factoryId: 'adFactoryExample',
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          print('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$NativeAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$NativeAd onAdClosed.'),
      ),
    )..load();

    _adManagerBannerAd = AdManagerBannerAd(
      adUnitId: '/6499/example/banner',
      request: AdManagerAdRequest(nonPersonalizedAds: true),
      sizes: <AdSize>[AdSize.largeBanner],
      listener: AdManagerBannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$AdManagerBannerAd loaded.');
          setState(() {
            _adManagerBannerAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$AdManagerBannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$AdManagerBannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$AdManagerBannerAd onAdClosed.'),
      ),
    )..load();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
    _adManagerBannerAd?.dispose();
    _nativeAd?.dispose();
  }
}
