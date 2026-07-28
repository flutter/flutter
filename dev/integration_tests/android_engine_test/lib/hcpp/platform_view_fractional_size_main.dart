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

/// The size of the platform view, in *physical* pixels.
///
/// Deliberately not a whole number of pixels. Android view geometry is
/// integral, so the engine has to snap this to the pixel grid; if it truncates
/// instead of rounding, the view ends up 200x200 and a line of
/// [_backgroundColor] is left uncovered along the right and bottom edges.
///
/// This is the same defect that a platform view covering the whole screen hits
/// on a device whose device pixel ratio does not evenly divide its resolution
/// (e.g. 1080 / 2.625 narrowed to a float, multiplied back out, is
/// 1079.9999656677246), just provoked deterministically on any device.
///
/// See https://github.com/flutter/flutter/issues/189834.
const double _viewPhysicalSize = 200.75;

/// The size of the clip applied to the platform view, in *physical* pixels.
///
/// Also deliberately not a whole number of pixels; the clip bounds are handed
/// to `FlutterMutatorsStack.pushClipRect` and have the same rounding hazard.
const double _clipPhysicalSize = 150.75;

const Color _backgroundColor = Colors.red;

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
  runApp(const FractionalSizeApp());
}

class FractionalSizeApp extends StatelessWidget {
  const FractionalSizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: FractionalSizeHomePage());
  }
}

class FractionalSizeHomePage extends StatefulWidget {
  const FractionalSizeHomePage({super.key});

  @override
  State<FractionalSizeHomePage> createState() => _FractionalSizeHomePageState();
}

class _FractionalSizeHomePageState extends State<FractionalSizeHomePage> {
  bool _isClipped = false;

  void _toggleClip() {
    setState(() {
      _isClipped = !_isClipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final double viewSize = _viewPhysicalSize / devicePixelRatio;

    Widget platformView = const _HybridCompositionAndroidPlatformView(
      viewType: 'box_platform_view',
    );
    if (_isClipped) {
      platformView = ClipRect(
        clipper: _FractionalClipper(dimension: _clipPhysicalSize / devicePixelRatio),
        child: platformView,
      );
    }

    // The platform view is pinned to the top left so that only its right and
    // bottom edges land on a fractional pixel, which is where the artifact
    // shows up.
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: <Widget>[
          Positioned(left: 0, top: 0, width: viewSize, height: viewSize, child: platformView),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ElevatedButton(
                key: const ValueKey<String>('toggle_clip_button'),
                onPressed: _toggleClip,
                child: Text(_isClipped ? 'Disable ClipRect' : 'Enable ClipRect'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips to a square of [dimension] anchored at the top left of the widget.
final class _FractionalClipper extends CustomClipper<Rect> {
  const _FractionalClipper({required this.dimension});

  final double dimension;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, dimension, dimension);

  @override
  bool shouldReclip(covariant _FractionalClipper oldClipper) {
    return oldClipper.dimension != dimension;
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
