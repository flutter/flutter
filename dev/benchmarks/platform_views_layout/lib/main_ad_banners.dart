// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      title: 'Advanced Layout',
      home: Scaffold(
        appBar: AppBar(title: const Text('Platform View Ad Banners')),
        body: ListView.builder(
          key: const Key('platform-views-scroll'), // This key is used by the driver test.
          itemCount: 200,
          itemBuilder: (BuildContext context, int index) {
            return index.isEven
                // Adjust the height so that there are multiple ad banners on screen at the same time.
                ? Container(height: 50.0, color: Colors.yellow)
                : const DummyAdBanner();
          },
        ),
      ),
    );
  }
}

class DummyAdBanner extends StatelessWidget {
  const DummyAdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // mimic admob standard banner size (320x50)
      // TODO: use real admob banner? or use webview?
      width: 320.0,
      height: 50.0,
      child: const UiKitView(viewType: 'benchmarks/platform_views_layout/DummyPlatformView'),
    );
  }
}
