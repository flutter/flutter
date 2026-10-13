// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:android_driver_extensions/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

import '../src/allow_list_devices.dart';

/// A [BackdropFilter] blur that straddles an HCPP platform view and Flutter
/// content.
///
/// Under HCPP the platform view's pixels never reach Flutter, so the engine
/// asks SurfaceFlinger to blur behind the Flutter overlay instead (see
/// `BackdropBlurCarrier.java`). On devices with native blur (API 37+ with
/// cross-window blur enabled) both halves of the panel are blurred with no
/// seam; elsewhere only the Flutter half is blurred.
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
  runApp(const _BackdropBlurApp());
}

final class _BackdropBlurApp extends StatefulWidget {
  const _BackdropBlurApp();

  @override
  State<_BackdropBlurApp> createState() => _BackdropBlurAppState();
}

final class _BackdropBlurAppState extends State<_BackdropBlurApp> {
  bool _blurVisible = true;

  void _toggleBlur() {
    setState(() {
      _blurVisible = !_blurVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            // High-contrast Flutter content on the right so the blur edge is
            // visible on both sides of the platform view boundary.
            const Positioned.fill(child: CustomPaint(painter: _CheckerboardPainter())),
            // Platform view on the left 60% of the screen.
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 240,
              child: _HybridCompositionAndroidPlatformView(
                viewType: 'blue_orange_gradient_platform_view',
              ),
            ),
            // A rounded blur panel straddling the platform view's right edge.
            if (_blurVisible)
              Positioned(
                left: 140,
                top: 200,
                width: 200,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: const ColoredBox(color: Color(0x33FFFFFF)),
                  ),
                ),
              ),
            // A sharp Flutter element above the blur, to verify the overlay
            // is still composited (unblurred) on top.
            Positioned(
              left: 190,
              top: 250,
              width: 100,
              height: 60,
              child: TextButton(
                key: const ValueKey<String>('ToggleBlur'),
                style: TextButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _toggleBlur,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double cell = 40;
    final Paint a = Paint()..color = const Color(0xFF6A1B9A);
    final Paint b = Paint()..color = const Color(0xFFFFEB3B);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final bool odd = ((x / cell).floor() + (y / cell).floor()).isOdd;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), odd ? a : b);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
