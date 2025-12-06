// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'window_content.dart';
import 'models.dart';
import 'rotated_wire_cube.dart';
import 'dart:math';
import 'package:flutter/src/widgets/_window.dart';
import 'tooltip_button.dart';

class RegularWindowContent extends StatelessWidget {
  RegularWindowContent({super.key, required this.window})
    : cubeColor = _generateRandomDarkColor();

  final RegularWindowController window;
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
    final WindowManager windowManager = WindowManagerAccessor.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    final child = Scaffold(
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
                    final UniqueKey key = UniqueKey();
                    windowManager.add(
                      KeyedWindow(
                        key: key,
                        controller: RegularWindowController(
                          preferredSize: windowSettings.regularSize,
                          delegate: CallbackRegularWindowControllerDelegate(
                            onDestroyed: () => windowManager.remove(key),
                          ),
                          title: 'Regular',
                        ),
                      ),
                    );
                  },
                  child: const Text('Create Regular Window'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final UniqueKey key = UniqueKey();
                    windowManager.add(
                      KeyedWindow(
                        key: key,
                        controller: DialogWindowController(
                          preferredSize: windowSettings.dialogSize,
                          delegate: CallbackDialogWindowControllerDelegate(
                            onDestroyed: () => windowManager.remove(key),
                          ),
                          parent: window,
                          title: 'Dialog',
                        ),
                      ),
                    );
                  },
                  child: const Text('Create Modal Dialog'),
                ),
                const SizedBox(height: 20),
                TooltipButton(parentController: window),
                const SizedBox(height: 20),
                Text(
                  'View #${window.rootView.viewId}\n'
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

    return ViewAnchor(
      view: ListenableBuilder(
        listenable: windowManager,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> childViews = <Widget>[];
          for (final KeyedWindow window in windowManager.windows) {
            if (window.parent == window.controller) {
              childViews.add(
                WindowContent(
                  controller: window.controller,
                  windowKey: window.key,
                  onDestroyed: () => windowManager.remove(window.key),
                  onError: () => windowManager.remove(window.key),
                ),
              );
            }
          }

          return ViewCollection(views: childViews);
        },
      ),
      child: child,
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
