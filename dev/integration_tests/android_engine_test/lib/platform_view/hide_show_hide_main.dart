// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

void main() async {
  ensureAndroidDevice();
  enableFlutterDriverExtension(commands: <CommandExtension>[nativeDriverCommands]);

  // Run on full screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MainApp());
}

final class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Visibility(
                visible: _show,
                maintainState: true,
                maintainSize: true,
                maintainAnimation: true,
                child: const _HybridCompositionAndroidPlatformView(
                  key: ValueKey<String>('PlatformView'),
                  viewType: 'changing_color_button_platform_view',
                ),
              ),
            ),
            ElevatedButton(
              key: const ValueKey<String>('TogglePlatformView'),
              onPressed: () {
                setState(() {
                  _show = !_show;
                });
              },
              child: Text(
                key: const ValueKey<String>('ToggleButtonText'),
                _show ? 'Hide Platform View' : 'Show Platform View',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HybridCompositionAndroidPlatformView extends StatelessWidget {
  const _HybridCompositionAndroidPlatformView({super.key, required this.viewType});

  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParamsCodec: const StandardMessageCodec(),
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
