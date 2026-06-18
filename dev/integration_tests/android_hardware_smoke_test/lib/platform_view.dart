// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// The active rendering mode for the platform view.
enum PlatformViewMode {
  /// Texture Layer Hybrid Composition (TLHC) using `initSurfaceAndroidView`.
  textureLayer,

  /// Hybrid Composition (HC) using `initExpensiveAndroidView`.
  hybridComposition,

  /// Hybrid Composition++ (HCPP) using `initHybridAndroidView`.
  hybridCompositionPlusPlus,
}

/// A custom widget embedding a native Android TextView inside the Flutter
/// layout hierarchy using the specified [PlatformViewMode] and drawing a Flutter overlay on top.
class AndroidPlatformView extends StatelessWidget {
  const AndroidPlatformView({super.key, required this.mode, this.onCreated});

  final PlatformViewMode mode;
  final VoidCallback? onCreated;

  @override
  Widget build(BuildContext context) {
    const viewType = 'com.example.android_hardware_smoke_test/native_text_view';
    final String modeLabel = switch (mode) {
      PlatformViewMode.textureLayer => 'TLHC',
      PlatformViewMode.hybridComposition => 'HC',
      PlatformViewMode.hybridCompositionPlusPlus => 'HCPP',
    };
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'text': 'Native ($modeLabel)\n🐞 View 🪲\nContent ',
    };

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: PlatformViewLink(
            // Prevent hangs when switching between PlatformViewModes in subsequent test cases.
            key: ValueKey<PlatformViewMode>(mode),
            viewType: viewType,
            surfaceFactory:
                (BuildContext context, PlatformViewController controller) {
                  return AndroidViewSurface(
                    controller: controller as AndroidViewController,
                    gestureRecognizers:
                        const <Factory<OneSequenceGestureRecognizer>>{},
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                  );
                },
            onCreatePlatformView: (PlatformViewCreationParams params) {
              final AndroidViewController controller = switch (mode) {
                PlatformViewMode.textureLayer =>
                  PlatformViewsService.initSurfaceAndroidView(
                    id: params.id,
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                    onFocus: () => params.onFocusChanged(true),
                  ),
                PlatformViewMode.hybridComposition =>
                  PlatformViewsService.initExpensiveAndroidView(
                    id: params.id,
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                    onFocus: () => params.onFocusChanged(true),
                  ),
                PlatformViewMode.hybridCompositionPlusPlus =>
                  PlatformViewsService.initHybridAndroidView(
                    id: params.id,
                    viewType: viewType,
                    layoutDirection: TextDirection.ltr,
                    creationParams: creationParams,
                    creationParamsCodec: const StandardMessageCodec(),
                    onFocus: () => params.onFocusChanged(true),
                  ),
              };
              return controller
                ..addOnPlatformViewCreatedListener((int id) {
                  params.onPlatformViewCreated(id);
                  onCreated?.call();
                })
                ..create();
            },
          ),
        ),
        Center(
          child: Container(
            width: 120,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.red.withValues(
                alpha: 0.6,
              ), // Semi-transparent overlay
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.0),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Flutter\n🐦🐦🐦',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
