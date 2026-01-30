// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [RawTooltip].

void main() => runApp(const RawTooltipExampleApp());

class RawTooltipExampleApp extends StatelessWidget {
  const RawTooltipExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const RawTooltipSample(title: 'RawTooltip Sample'),
    );
  }
}

class RawTooltipSample extends StatelessWidget {
  const RawTooltipSample({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<RawTooltipState> rawTooltipKey =
        GlobalKey<RawTooltipState>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: RawTooltip(
          // Provide a global key with the "RawTooltipState" type to show
          // the rawTooltip manually when trigger mode is set to manual.
          key: rawTooltipKey,
          semanticsTooltip: 'I am a RawTooltip message',
          triggerMode: TooltipTriggerMode.manual,
          positionDelegate: (TooltipPositionContext context) {
            // Use the context information to position the rawTooltip to the right of
            // the target.
            return Offset(
              context.target.dx + context.targetSize.width / 2,
              context.target.dy - context.tooltipSize.height / 2,
            );
          },
          tooltipBuilder: (BuildContext context, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: Text('I am a RawTooltip message'),
            );
          },
          child: Container(
            height: 100,
            width: 200,
            color: Colors.blue,
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            child: const Text(
              'Hover over this box or\n'
              'tap on the FAB to show the tooltip',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Show RawTooltip programmatically on button tap.
          rawTooltipKey.currentState?.ensureTooltipVisible();
        },
        label: const Text('Show RawTooltip'),
      ),
    );
  }
}
