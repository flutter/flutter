// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();

  if (kIsWeb || !io.Platform.isAndroid) {
    throw UnsupportedError('This app should only run on Android devices.');
  }

  runApp(const MainApp());
}

final class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Draw a full-screen blue rectangle.
    return const DecoratedBox(decoration: BoxDecoration(color: Colors.blue));
  }
}
