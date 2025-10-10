// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'dialog_window_content.dart';
import 'regular_window_content.dart';
import 'package:flutter/src/widgets/_window.dart';

/// Responsible for rendering the appropriate content for a window based on
/// the type of the window.
class WindowContent extends StatelessWidget {
  const WindowContent({
    required this.windowKey,
    required this.controller,
    required this.onDestroyed,
    required this.onError,
    super.key,
  });

  final Key windowKey;
  final BaseWindowController controller;
  final VoidCallback onDestroyed;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) {
    return switch (controller) {
      final RegularWindowController regular => RegularWindow(
        key: windowKey,
        controller: regular,
        child: MaterialApp(home: RegularWindowContent(window: regular)),
      ),
      final DialogWindowController dialog => DialogWindow(
        key: windowKey,
        controller: dialog,
        child: MaterialApp(home: DialogWindowContent(window: dialog)),
      ),
    };
  }
}
