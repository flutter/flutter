// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A custom widget embedding a native Android TextView inside the Flutter
/// layout hierarchy using Hybrid Composition and drawing a Flutter overlay on top.
class AndroidPlatformView extends StatelessWidget {
  const AndroidPlatformView({super.key, this.onCreated});

  final VoidCallback? onCreated;

  @override
  Widget build(BuildContext context) {
    const viewType = 'com.example.android_hardware_smoke_test/native_text_view';
    const creationParams = <String, dynamic>{'text': 'Native View Content'};

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: PlatformViewLink(
            viewType: viewType,
            surfaceFactory: (BuildContext context, PlatformViewController controller) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              );
            },
            onCreatePlatformView: (PlatformViewCreationParams params) {
              return PlatformViewsService.initAndroidView(
                  id: params.id,
                  viewType: viewType,
                  layoutDirection: TextDirection.ltr,
                  creationParams: creationParams,
                  creationParamsCodec: const StandardMessageCodec(),
                  onFocus: () => params.onFocusChanged(true),
                )
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
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.7), // Semi-transparent overlay
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.0),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Flutter',
              style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
