// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
// See: https://github.com/flutter/flutter/issues/177586
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

/// Flutter code sample for [Tooltip].

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runWidget(
      RegularWindow(
        controller: RegularWindowController(
          preferredSize: const Size(800, 600),
          preferredConstraints: const BoxConstraints(
            minWidth: 640,
            minHeight: 480,
          ),
          title: 'Multi-Window Tooltip Sample',
        ),
        child: const TooltipExampleApp(),
      ),
    );
  } on UnsupportedError catch (_) {
    // TODO(mattkae): Remove this catch block when windowing is supported in tests.
    // For now, we need to catch the error so that the API smoke tests pass.
    runApp(const TooltipExampleApp());
  }
}

class TooltipExampleApp extends StatelessWidget {
  const TooltipExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        tooltipTheme: const TooltipThemeData(preferBelow: false),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Tooltip Sample')),
        body: const Center(child: TooltipSample()),
      ),
    );
  }
}

class TooltipSample extends StatelessWidget {
  const TooltipSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'I am a Tooltip',
      child: Text('Hover over the text to show a tooltip.'),
    );
  }
}
