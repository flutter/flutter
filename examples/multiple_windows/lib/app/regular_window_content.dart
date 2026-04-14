// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'dialog_window_content.dart';

import 'popup_button.dart';
import 'models.dart';
import 'rotated_wire_cube.dart';
import 'dart:math';
import 'package:flutter/src/widgets/_window.dart';
import 'tooltip_button.dart';

class RegularWindowContent extends StatelessWidget {
  RegularWindowContent({super.key, required this.regularWindowController})
    : cubeColor = _generateRandomDarkColor();

  final RegularWindowController regularWindowController;
  final Color cubeColor;

  static Color _generateRandomDarkColor() {
    final random = Random();
    const int lowerBound = 32;
    const int span = 160;
    int red = lowerBound + random.nextInt(span);
    int green = lowerBound + random.nextInt(span);
    int blue = lowerBound + random.nextInt(span);
    return Color.fromARGB(255, red, green, blue);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final windowSize = WindowScope.contentSizeOf(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);
    final windowRegistry = WindowRegistry.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Regular Window')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [RotatedWireCube(cubeColor: cubeColor)],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    late final WindowEntry entry;
                    final controller = RegularWindowController(
                      delegate: CallbackRegularWindowControllerDelegate(
                        onDestroyed: () => windowRegistry.unregister(entry),
                      ),
                      title: 'Regular',
                      preferredSize: windowSettings.regularSize,
                    );

                    entry = WindowEntry(
                      controller: controller,
                      builder: (BuildContext context) => RegularWindowContent(
                        regularWindowController: controller,
                      ),
                    );
                    windowRegistry.register(entry);
                  },
                  child: const Text('Create Regular Window'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    late final WindowEntry entry;
                    final controller = DialogWindowController(
                      delegate: CallbackDialogWindowControllerDelegate(
                        onDestroyed: () => windowRegistry.unregister(entry),
                      ),
                      title: 'Modal Dialog',
                      preferredSize: windowSettings.dialogSize,
                      parent: regularWindowController,
                      decorated: windowSettings.dialogDecorated,
                    );

                    entry = WindowEntry(
                      controller: controller,
                      builder: (BuildContext context) => DialogWindowContent(
                        dialogWindowController: controller,
                      ),
                    );
                    windowRegistry.register(entry);
                  },
                  child: const Text('Create Modal Dialog'),
                ),
                const SizedBox(height: 20),
                TooltipButton(parentController: regularWindowController),
                const SizedBox(height: 20),
                PopupButton(parentController: regularWindowController),
                const SizedBox(height: 20),
                Text(
                  'View #${regularWindowController.rootView.viewId}\n'
                  'Size: ${(windowSize.width).toStringAsFixed(1)}\u00D7${(windowSize.height).toStringAsFixed(1)}\n'
                  'Device Pixel Ratio: $dpr',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CallbackRegularWindowControllerDelegate
    with RegularWindowControllerDelegate {
  CallbackRegularWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
