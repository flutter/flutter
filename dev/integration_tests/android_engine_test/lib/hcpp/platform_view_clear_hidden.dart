// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

void main() {
  ensureAndroidDevice();
  enableFlutterDriverExtension(
    handler: (String? command) async {
      return json.encode(<String, Object?>{
        'supported': await HybridAndroidViewController.checkIfSupported(),
      });
    },
    commands: <CommandExtension>[nativeDriverCommands],
  );

  runApp(const MyApp());
}

/// A reusable widget that encapsulates the creation of the platform view.
class PlatformViewWidget extends StatelessWidget {
  const PlatformViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: PlatformViewLink(
          viewType: 'changing_color_button_platform_view',
          surfaceFactory: (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initHybridAndroidView(
                id: params.id,
                viewType: 'changing_color_button_platform_view',
                layoutDirection: TextDirection.ltr,
                creationParamsCodec: const StandardMessageCodec(),
              )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showRightView = true;

  void _toggleRightView() {
    setState(() {
      _showRightView = !_showRightView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Platform View Toggle Demo')),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                key: const ValueKey<String>('ToggleRightView'),
                onPressed: _toggleRightView,
                child: Text(_showRightView ? 'Hide Right View' : 'Show Right View'),
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  // The left platform view is always visible.
                  const Expanded(child: PlatformViewWidget()),

                  // The right platform view's visibility is toggled,
                  // but it always occupies space in the layout.
                  Expanded(
                    child: Visibility(
                      visible: _showRightView,
                      maintainState: true,
                      maintainSize: true,
                      maintainAnimation: true,
                      child: const PlatformViewWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
