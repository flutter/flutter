// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Tooltip].

void main() => runApp(const TooltipExampleApp());

class TooltipExampleApp extends StatelessWidget {
  const TooltipExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TooltipSample(title: 'Tooltip Sample'),
    );
  }
}

class TooltipSample extends StatelessWidget {
  const TooltipSample({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<TooltipState> tooltipkey = GlobalKey<TooltipState>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Tooltip(
          // Provide a global key with the "TooltipState" type to show
          // the tooltip manually when trigger mode is set to manual.
          key: tooltipkey,
          triggerMode: TooltipTriggerMode.manual,
          showDuration: const Duration(seconds: 1),
          message: 'I am a Tooltip',
          child: const Text('Tap on the FAB'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show Tooltip programmatically on button tap.
          tooltipkey.currentState?.ensureTooltipVisible();
        },
        label: const Text('Show Tooltip'),
      ),
    );
  }
}
