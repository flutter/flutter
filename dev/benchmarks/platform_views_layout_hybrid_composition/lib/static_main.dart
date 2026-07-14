// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'package:flutter/services.dart';

import 'android_platform_view.dart';

void main() {
  const MethodChannel channel = MethodChannel('samples.flutter.dev/invalidation');
  enableFlutterDriverExtension(handler: (String? command) async {
    if (command == 'startInvalidation') {
      await channel.invokeMethod<void>('startInvalidationLoop');
      return 'started';
    } else if (command == 'stopInvalidation') {
      await channel.invokeMethod<void>('stopInvalidationLoop');
      return 'stopped';
    }
    return 'unknown';
  });
  runApp(const PlatformViewApp());
}

class PlatformViewApp extends StatefulWidget {
  const PlatformViewApp({super.key});

  @override
  PlatformViewAppState createState() => PlatformViewAppState();
}

class PlatformViewAppState extends State<PlatformViewApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Advanced Layout - Static', home: PlatformViewLayout());
  }
}

class PlatformViewLayout extends StatelessWidget {
  const PlatformViewLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform View Static Layout')),
      body: ListView.builder(
        key: const Key('platform-views-scroll'),
        itemCount: 200,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: Material(
              elevation: (index % 5 + 1).toDouble(),
              color: Colors.white,
              child: Stack(children: <Widget>[
                const DummyPlatformView(),
                // Static overlay
                Container(
                  color: Colors.amber,
                  width: 50.0,
                  height: 50.0,
                  child: const Center(child: Text('Static')),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class DummyPlatformView extends StatelessWidget {
  const DummyPlatformView({super.key});

  @override
  Widget build(BuildContext context) {
    const viewType = 'benchmarks/platform_views_layout_hybrid_composition/DummyPlatformView';
    late Widget nativeView;
    if (Platform.isIOS) {
      nativeView = const UiKitView(viewType: viewType);
    } else if (Platform.isAndroid) {
      nativeView = const AndroidPlatformView(viewType: viewType);
    } else {
      assert(false, 'Invalid platform');
    }
    return Container(color: Colors.purple, height: 200.0, width: 300.0, child: nativeView);
  }
}
