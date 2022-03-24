// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Completer<void> _assetImageCompleter = Completer<void>();
final Completer<void> _networkImageCompleter = Completer<void>();

/// Notifies that Image.asset used in the test app loaded the image.
Future<void> get whenAssetImageLoads => _assetImageCompleter.future;

/// Notifies that Image.network used in the test app loaded the image.
Future<void> get whenNetworkImageLoads => _networkImageCompleter.future;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      OptionalMethodChannel('flutter/web_test_e2e', JSONMethodCodec());

  // Artificially override the device pixel ratio to force the framework to pick the 1.5x asset variants.
  await channel.invokeMethod<void>('setDevicePixelRatio', '1.5');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        key: const Key('mainapp'),
        title: 'Integration Test App',
        home: Column(children: <Widget>[
          const Text('Asset image:'),
          RepaintBoundary(child: Image.asset(
            'assets/icons/material/material.png',
            package: 'flutter_gallery_assets',
            frameBuilder: (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (frame != null) {
                _assetImageCompleter.complete();
              }
              return child;
            },
          )),
          const Text('Network image:'),
          RepaintBoundary(child: Image.network(
            'assets/packages/flutter_gallery_assets/assets/icons/material/material.png',
            frameBuilder: (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (frame != null) {
                _networkImageCompleter.complete();
              }
              return child;
            },
          )),
      ])
    );
  }
}
