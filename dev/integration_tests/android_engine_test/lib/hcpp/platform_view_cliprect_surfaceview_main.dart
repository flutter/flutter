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
  runApp(const SimpleClipRectApp());
}

class SimpleClipRectApp extends StatelessWidget {
  const SimpleClipRectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(elevatedButtonTheme: const ElevatedButtonThemeData()),
      home: const ClipRectHomePage(),
    );
  }
}

class ClipRectHomePage extends StatefulWidget {
  const ClipRectHomePage({super.key});

  @override
  State<ClipRectHomePage> createState() => _ClipRectHomePageState();
}

class _ClipRectHomePageState extends State<ClipRectHomePage> {
  bool _isClipped = false;

  void _toggleClip() {
    setState(() {
      _isClipped = !_isClipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Content that will be clipped
    Widget content = const Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Background
        SizedBox.square(dimension: 500, child: ColoredBox(color: Colors.green)),
        // Platform View
        SizedBox.square(
          dimension: 400,
          child: _HybridCompositionAndroidPlatformView(
            viewType: 'blue_orange_gradient_surface_view_platform_view',
          ),
        ),
      ],
    );

    // Apply the ClipRect conditionally
    if (_isClipped) {
      content = ClipRect(clipper: const SimpleRectClipper(dimension: 300.0), child: content);
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          // Button to toggle the clip state
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              key: const ValueKey<String>('toggle_cliprect_button'),
              onPressed: _toggleClip,
              child: Text(_isClipped ? 'Disable ClipRect' : 'Enable ClipRect'),
            ),
          ),
          // Expanded takes remaining space for the clipped content
          Expanded(child: Center(child: content)),
        ],
      ),
    );
  }
}

// A simple clipper that enforces a strict bounding box of the specified dimension
class SimpleRectClipper extends CustomClipper<Rect> {
  const SimpleRectClipper({required this.dimension});

  final double dimension;

  @override
  Rect getClip(Size size) {
    // Centers the clip area over the widget
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: dimension,
      height: dimension,
    );
  }

  @override
  bool shouldReclip(covariant SimpleRectClipper oldClipper) {
    return oldClipper.dimension != dimension;
  }
}

// --- Platform View Definition ---
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
