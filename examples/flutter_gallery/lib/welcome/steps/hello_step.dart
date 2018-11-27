// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/welcome/step.dart';

const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

class FlutterWelcomeStep extends WelcomeStep {
  FlutterWelcomeStep({TickerProvider tickerProvider})
      : super(tickerProvider: tickerProvider);

  @override
  String title() => 'Welcome to Flutter!';
  @override
  String subtitle() =>
      'Flutter allows you to build beautiful native apps on iOS and Android from a single codebase.';

  @override
  Widget imageWidget() {
    return Image.asset(
      'welcome/welcome_hello.png',
      package: _kGalleryAssetsPackage,
    );
  }

  @override
  void animate({bool restart}) {}
}
