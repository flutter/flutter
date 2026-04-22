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

class RegularWindowContent extends StatefulWidget {
  const RegularWindowContent({super.key, required this.regularWindowController});

  final RegularWindowController regularWindowController;

  @override
  State<RegularWindowContent> createState() => _RegularWindowContentState();
}

class _RegularWindowContentState extends State<RegularWindowContent> {
  late final Color cubeColor;

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
  void initState() {
    super.initState();
    cubeColor = _generateRandomDarkColor();
  }

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final Size windowSize = WindowScope.contentSizeOf(context);

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
                _WindowCreationButtons(regularWindowController: widget.regularWindowController),
                const SizedBox(height: 20),
                TooltipButton(parentController: widget.regularWindowController),
                const SizedBox(height: 20),
                PopupButton(parentController: widget.regularWindowController),
                const SizedBox(height: 20),
                Text(
                  'View #${widget.regularWindowController.rootView.viewId}\n'
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

/// Extracted widget that depends on [WindowRegistry] so that registry changes
/// (e.g. opening/closing windows) only rebuild these buttons, not the entire
/// [RegularWindowContent] tree.
class _WindowCreationButtons extends StatelessWidget {
  const _WindowCreationButtons({required this.regularWindowController});

  final RegularWindowController regularWindowController;

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);
    final WindowRegistry windowRegistry = WindowRegistry.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
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
      ],
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
