// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'regular_window_content.dart';
import 'models.dart';
import 'package:flutter/src/widgets/_window.dart';

class WindowControllerRender extends StatelessWidget {
  const WindowControllerRender({
    required super.key,
    required this.controller,
    required this.onDestroyed,
    required this.onError,
    required this.windowSettings,
    required this.windowManagerModel,
  });

  final BaseWindowController controller;
  final VoidCallback onDestroyed;
  final VoidCallback onError;
  final WindowSettings windowSettings;
  final WindowManagerModel windowManagerModel;

  @override
  Widget build(BuildContext context) {
    return switch (controller) {
      final RegularWindowController regular => RegularWindow(
        key: key,
        controller: regular,
        child: RegularWindowContent(
          window: regular,
          windowSettings: windowSettings,
          windowManagerModel: windowManagerModel,
        ),
      ),
    };
  }
}
