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

/// This example demonstrates fluid ads.
class FluidExample extends StatefulWidget {
  @override
  _FluidExampleExampleState createState() => _FluidExampleExampleState();
}

class _FluidExampleExampleState extends State<FluidExample> {
  FluidAdManagerBannerAd? _fluidAd;
  double _width = 200.0;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text('Fluid example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.separated(
            itemCount: 3,
            separatorBuilder: (BuildContext context, int index) {
              return Container(
                height: 40,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              if (index == 1) {
                return Align(
                  alignment: Alignment.center,
                  child: FluidAdWidget(
                    width: _width,
                    ad: _fluidAd!,
                  ),
                );
              } else if (index == 2) {
                return ElevatedButton(
                    onPressed: () {
                      double newWidth;
                      if (_width == 200.0) {
                        newWidth = 100.0;
                      } else if (_width == 100.0) {
                        newWidth = 150.0;
                      } else {
                        newWidth = 200.0;
                      }
                      setState(() {
                        _width = newWidth;
                      });
                    },
                    child: Text('Change size'));
              }
              return Text(
                Constants.placeholderText,
                style: TextStyle(fontSize: 24),
              );
            },
          ),
        ),
      ));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create the ad objects and load ads.
    _fluidAd = FluidAdManagerBannerAd(
      adUnitId: '/6499/example/APIDemo/Fluid',
      request: AdManagerAdRequest(nonPersonalizedAds: true),
      listener: AdManagerBannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$_fluidAd loaded.');
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$_fluidAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$_fluidAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$_fluidAd onAdClosed.'),
      ),
    )..load();
  }

  @override
  void dispose() {
    super.dispose();
    _fluidAd?.dispose();
  }
}
