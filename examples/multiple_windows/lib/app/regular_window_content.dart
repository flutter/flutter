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

class RegularWindowContent extends StatefulWidget {
  const RegularWindowContent({super.key, required this.window});

  final RegularWindowController window;

  @override
  State<StatefulWidget> createState() => _RegularWindowContentState();
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

class _RegularWindowContentState extends State<RegularWindowContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Color cubeColor;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 2 * pi,
      duration: const Duration(seconds: 15),
    )..repeat();
    cubeColor = _generateRandomDarkColor();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Color _generateRandomDarkColor() {
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
              children: [
                RotatedWireCube(animation: _animation, cubeColor: cubeColor),
              ],
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
                Text(
                  'View #${widget.window.rootView.viewId}\n'
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
        builder: (BuildContext context, Widget? _) {
          final List<Widget> childViews = <Widget>[];
          for (final KeyedWindow window in windowManager.windows) {
            if (window.parent == widget.window) {
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
