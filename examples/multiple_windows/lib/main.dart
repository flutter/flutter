// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'app/main_window.dart';
import 'app/models.dart';

class MainControllerWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const MultiWindowApp());
}

class MultiWindowApp extends StatefulWidget {
  const MultiWindowApp({super.key});

  @override
  State<MultiWindowApp> createState() => _MultiWindowAppState();
}

class _MultiWindowAppState extends State<MultiWindowApp> {
  final WindowController controller = WindowController(
    size: const Size(800, 600),
    title: 'Multi-Window Reference Application',
    delegate: MainControllerWindowDelegate(),
  );
  final WindowSettings settings = WindowSettings();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WindowSettingsAccessor(
      windowSettings: settings,
      child: WindowManager(
        initialWindows: [
          WindowEntry(
            controller: controller,
            builder: (context) => MaterialApp(home: MainWindow(controller: controller)),
          ),
        ],
      ),
    );
  }
}
