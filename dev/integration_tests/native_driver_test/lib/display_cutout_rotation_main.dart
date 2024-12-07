// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:native_driver/extension.dart';

import 'src/allow_list_devices.dart';

void main() async {
  ensureAndroidOrIosDevice();
  enableFlutterDriverExtension(commands: <CommandExtension>[
    nativeDriverCommands,
  ]);

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
  @override
  Widget build(BuildContext context) {
    final List<DisplayFeature> displayFeatures =
        MediaQuery.of(context).displayFeatures;
    displayFeatures.retainWhere(
        (DisplayFeature feature) => feature.type == DisplayFeatureType.cutout);
    String text;
    if (displayFeatures.isEmpty) {
      text = 'CutoutNone';
    } else if (displayFeatures.length > 1) {
      text = 'CutoutMany';
    } else {
      final Rect cutout = displayFeatures[0].bounds;
      if (cutout.top == 0) {
        text = 'CutoutTop';
      } else if (cutout.left == 0) {
        text = 'CutoutLeft';
      } else {
        text = 'CutoutNeither';
      }
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Text('Cutout status: $text', key: Key(text)),
    );
  }
}
