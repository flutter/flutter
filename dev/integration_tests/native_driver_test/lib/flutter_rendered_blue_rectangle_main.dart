// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:native_driver/extension.dart';

import 'src/allow_list_devices.dart';

void main() {
  ensureAndroidOrIosDevice();
  enableFlutterDriverExtension(commands: <CommandExtension>[
    nativeDriverExtension,
  ]);

  // Run on full screen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
