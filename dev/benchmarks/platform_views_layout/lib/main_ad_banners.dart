// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  runApp(
      const PlatformViewApp()
  );
}

class PlatformViewApp extends StatefulWidget {
  const PlatformViewApp({
    super.key,
  });

  @override
  PlatformViewAppState createState() => PlatformViewAppState();
}

class PlatformViewAppState extends State<PlatformViewApp> {

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  BannerAd getBanner() {
    var bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {},
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {},
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    );

    bannerAd.load();
    return bannerAd;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      title: 'Advanced Layout',
      home: Scaffold(
        appBar: AppBar(title: const Text('Platform View Ad Banners')),
        body: ListView.builder(
          key: const Key('platform-views-scroll'), // This key is used by the driver test.
          itemCount: 250,
          itemBuilder: (BuildContext context, int index) {
            return index.isEven
                // Adjust the height so that there are multiple ad banners on screen at the same time.
                ? Container(height: 250.0, color: Colors.yellow)
                : SizedBox(
                  width: 320,
                  height: 50,
                  child: AdWidget(ad: getBanner()),
                );
          },
        ),
      ),
    );
  }
}
