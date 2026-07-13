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

class WindowContent extends StatefulWidget {
  const WindowContent({super.key, required this.windowController});

  final WindowController windowController;

  @override
  State<WindowContent> createState() => _WindowContentState();
}

class _WindowContentState extends State<WindowContent> {
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

    return Overlay.wrap(
      alwaysSizeToContent: true,
      child: IntrinsicWidth(
        child: Material(
          child: Column(
            mainAxisSize: .min,
            children: [
              AppBar(title: const Text('Regular Window')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Column(
                      mainAxisSize: .min,
                      children: [RotatedWireCube(cubeColor: cubeColor)],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisSize: .min,
                      children: [
                        _WindowCreationButtons(
                          windowController: widget.windowController,
                        ),
                        const SizedBox(height: 20),
                        TooltipButton(parentController: widget.windowController),
                        const SizedBox(height: 20),
                        PopupButton(parentController: widget.windowController),
                        const SizedBox(height: 20),
                        Text(
                          'View #${widget.windowController.rootView.viewId}\n'
                          'Size: ${windowSize.width.toStringAsFixed(1)}\u00D7${windowSize.height.toStringAsFixed(1)}\n'
                          'Device Pixel Ratio: $dpr',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extracted widget that depends on [WindowRegistry] so that registry changes
/// (e.g. opening/closing windows) only rebuild these buttons, not the entire
/// [WindowContent] tree.
class _WindowCreationButtons extends StatelessWidget {
  const _WindowCreationButtons({required this.windowController});

  final WindowController windowController;

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);
    final WindowRegistry windowRegistry = WindowRegistry.of(context);

    return Column(
      mainAxisSize: .min,
      children: [
        ElevatedButton(
          onPressed: () {
            late final WindowEntry entry;
            final controller = WindowController(
              delegate: CallbackWindowControllerDelegate(
                onDestroyed: () => windowRegistry.unregister(entry),
              ),
              title: 'Regular',
              size: windowSettings.regularSize,
            );

            entry = WindowEntry(
              controller: controller,
              builder: (BuildContext context) =>
                  WindowContent(windowController: controller),
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
              size: windowSettings.dialogSize,
              parent: windowController,
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

class CallbackWindowControllerDelegate with WindowControllerDelegate {
  CallbackWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
