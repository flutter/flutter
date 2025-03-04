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

void main() async {
  ensureAndroidDevice();
  enableFlutterDriverExtension(
    handler: (String? command) async {
      return json.encode(<String, Object?>{
        'supported': await HybridAndroidViewController.checkIfSupported(),
      });
    },
    commands: <CommandExtension>[nativeDriverCommands],
  );

  // Run on full screen.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const _OpacityWrappedMainApp());
}

final class _OpacityWrappedMainApp extends StatefulWidget {
  const _OpacityWrappedMainApp();

  @override
  State<_OpacityWrappedMainApp> createState() {
    return _OpacityWrappedMainAppState();
  }
}

class _OpacityWrappedMainAppState extends State<_OpacityWrappedMainApp> {
  double opacity = 0.3;

  void _toggleOpacity() {
    setState(() {
      if (opacity == 1) {
        opacity = 0.3;
      } else {
        opacity = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Opacity(
        opacity: opacity,
        child: ColoredBox(
          color: Colors.white,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              TextButton(
                key: const ValueKey<String>('ToggleOpacity'),
                onPressed: _toggleOpacity,
                child: const SizedBox(
                  width: 300,
                  height: 300,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
              const SizedBox(
                width: 200,
                height: 200,
                child: _HybridCompositionAndroidPlatformView(
                  viewType: 'changing_color_button_platform_view',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HybridCompositionAndroidPlatformView extends StatelessWidget {
  const _HybridCompositionAndroidPlatformView({required this.viewType});

  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initHybridAndroidView(
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
