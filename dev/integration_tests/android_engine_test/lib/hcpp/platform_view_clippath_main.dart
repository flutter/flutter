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
  runApp(const _ComplicatedClipPathWrappedMainApp());
}

final class _ComplicatedClipPathWrappedMainApp extends StatefulWidget {
  const _ComplicatedClipPathWrappedMainApp();

  @override
  State<_ComplicatedClipPathWrappedMainApp> createState() {
    return _ComplicatedClipPathWrappedMainAppState();
  }
}

class _ComplicatedClipPathWrappedMainAppState extends State<_ComplicatedClipPathWrappedMainApp> {
  final CustomClipper<Path> _triangleClipper = TriangleClipper();
  CustomClipper<Path>? _triangleOrEmpty = TriangleClipper();

  void _toggleTriangleClipper() {
    setState(() {
      if (_triangleOrEmpty == null) {
        _triangleOrEmpty = _triangleClipper;
      } else {
        _triangleOrEmpty = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ClipPath(
        clipper: _triangleOrEmpty,
        child: ClipPath(
          clipper: CubicWaveClipper(),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                TextButton(
                  key: const ValueKey<String>('ToggleTriangleClipping'),
                  onPressed: _toggleTriangleClipper,
                  child: const SizedBox(
                    width: 500,
                    height: 500,
                    child: ColoredBox(color: Colors.green),
                  ),
                ),
                const SizedBox(
                  width: 400,
                  height: 400,
                  child: _HybridCompositionAndroidPlatformView(
                    viewType: 'changing_color_button_platform_view',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Clips to show the top half of the screen, with a cubic wave as the dividing
// line.
class CubicWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    // Closer to 1 moves the wave lower, closer to 0 moves it higher.
    final double waveHeight = size.height * 0.65;

    path.lineTo(0, waveHeight);

    path.cubicTo(
      size.width * 0.25,
      waveHeight * 0.8,
      size.width * 0.75,
      waveHeight * 1.2,
      size.width,
      waveHeight,
    );

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

// Clips a triangle off the top left of the screen.
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
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
