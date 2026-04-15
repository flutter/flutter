// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'dialog_window_content.dart';
import 'models.dart';
import 'popup_button.dart';
import 'rotated_wire_cube.dart';
import 'tooltip_button.dart';

class RegularWindowContent extends StatelessWidget {
  RegularWindowContent({super.key, required this.regularWindowController})
    : cubeColor = _generateRandomDarkColor();

  final RegularWindowController regularWindowController;
  final Color cubeColor;

  static Color _generateRandomDarkColor() {
    final random = Random();
    const lowerBound = 32;
    const span = 160;
    final int red = lowerBound + random.nextInt(span);
    final int green = lowerBound + random.nextInt(span);
    final int blue = lowerBound + random.nextInt(span);
    return Color.fromARGB(255, red, green, blue);
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final Size windowSize = WindowScope.contentSizeOf(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);
    final WindowRegistry windowRegistry = WindowRegistry.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Regular Window')),
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
                      builder: (BuildContext context) =>
                          RegularWindowContent(regularWindowController: controller),
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
                      builder: (BuildContext context) =>
                          DialogWindowContent(dialogWindowController: controller),
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
                  'Size: ${windowSize.width.toStringAsFixed(1)}\u00D7${windowSize.height.toStringAsFixed(1)}\n'
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

class CallbackRegularWindowControllerDelegate with RegularWindowControllerDelegate {
  CallbackRegularWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
