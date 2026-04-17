// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'models.dart';

class DialogWindowContent extends StatelessWidget {
  const DialogWindowContent({super.key, required this.dialogWindowController});

  final DialogWindowController dialogWindowController;

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return FocusScope(
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Dialog')),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final WindowRegistry windowRegistry = WindowRegistry.of(context);

                    late final WindowEntry entry;
                    final controller = DialogWindowController(
                      delegate: CallbackDialogWindowControllerDelegate(
                        onDestroyed: () => windowRegistry.unregister(entry),
                      ),
                      title: 'Modal Dialog',
                      preferredSize: windowSettings.dialogSize,
                      parent: dialogWindowController,
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
                ListenableBuilder(
                  listenable: dialogWindowController,
                  builder: (BuildContext context, Widget? _) {
                    final double dpr = MediaQuery.of(context).devicePixelRatio;
                    final Size windowSize = WindowScope.contentSizeOf(context);
                    return Text(
                      'View ID: ${dialogWindowController.rootView.viewId}\n'
                      'Parent View ID: ${dialogWindowController.parent?.rootView.viewId ?? "None"}\n'
                      'Size: ${windowSize.width.toStringAsFixed(1)}\u00D7${windowSize.height.toStringAsFixed(1)}\n'
                      'Device Pixel Ratio: $dpr',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    dialogWindowController.destroy();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
