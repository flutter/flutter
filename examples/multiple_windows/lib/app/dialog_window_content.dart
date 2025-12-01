// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'models.dart';
import 'window_content.dart';
import 'package:flutter/src/widgets/_window.dart';

class DialogWindowContent extends StatelessWidget {
  const DialogWindowContent({super.key, required this.window});

  final DialogWindowController window;

  @override
  Widget build(BuildContext context) {
    final WindowManager windowManager = WindowManagerAccessor.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    final child = FocusScope(
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(title: Text('Dialog')),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                ListenableBuilder(
                  listenable: window,
                  builder: (BuildContext context, Widget? _) {
                    final dpr = MediaQuery.of(context).devicePixelRatio;
                    final windowSize = WindowScope.contentSizeOf(context);
                    return Text(
                      'View ID: ${window.rootView.viewId}\n'
                      'Parent View ID: ${window.parent?.rootView.viewId ?? "None"}\n'
                      'Size: ${(windowSize.width).toStringAsFixed(1)}\u00D7${(windowSize.height).toStringAsFixed(1)}\n'
                      'Device Pixel Ratio: $dpr',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    window.destroy();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
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
