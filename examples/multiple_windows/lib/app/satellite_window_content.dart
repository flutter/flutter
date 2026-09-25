// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

class SatelliteWindowContent extends StatelessWidget {
  const SatelliteWindowContent({super.key, required this.satelliteWindowController});

  final SatelliteWindowController satelliteWindowController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FocusScope(
        autofocus: true,
        child: IntrinsicWidth(
          child: Material(
            child: Column(
              mainAxisSize: .min,
              children: [
                AppBar(title: const Text('Satellite')),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      ListenableBuilder(
                        listenable: satelliteWindowController,
                        builder: (BuildContext context, Widget? _) {
                          final double dpr = MediaQuery.of(context).devicePixelRatio;
                          final Size windowSize = WindowScope.contentSizeOf(context);
                          return Text(
                            'View ID: ${satelliteWindowController.rootView.viewId}\n'
                            'Parent View ID: ${satelliteWindowController.parent.rootView.viewId}\n'
                            'Size: ${windowSize.width.toStringAsFixed(1)}\u00D7${windowSize.height.toStringAsFixed(1)}\n'
                            'Device Pixel Ratio: $dpr',
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: satelliteWindowController.destroy,
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
