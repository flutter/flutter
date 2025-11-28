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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showTexture = true;

  void _toggleTexture() {
    setState(() {
      _showTexture = !_showTexture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('HCPP Platform View Bug Demo')),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                key: const ValueKey<String>('ToggleTexture'),
                onPressed: _toggleTexture,
                child: Text(_showTexture ? 'Hide Texture' : 'Show Texture'),
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: PlatformViewLink(
                          viewType: 'changing_color_button_platform_view',
                          surfaceFactory:
                              (BuildContext context, PlatformViewController controller) {
                                return AndroidViewSurface(
                                  controller: controller as AndroidViewController,
                                  hitTestBehavior: PlatformViewHitTestBehavior.transparent,
                                  gestureRecognizers:
                                      const <Factory<OneSequenceGestureRecognizer>>{},
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
                    ),

                    if (_showTexture)
                      const Center(
                        child: SizedBox(
                          width: 275,
                          height: 275,
                          child: Opacity(
                            opacity: 0.5,
                            child: Texture(
                              // Intentionally use an unknown texture ID: this
                              // results a black rectangle which is good enough
                              // for our purposes.
                              textureId: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
