// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'window_settings.dart';

Future<void> windowSettingsDialog(
  BuildContext context,
  WindowSettings settings,
) async {
  return await showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext ctx) {
      return _WindowSettingsEditor(
        settings: WindowSettings.clone(settings),
        onClose: (WindowSettings newSettings) {
          settings.from(newSettings);
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
    },
  );
}

class _WindowSettingsEditor extends StatelessWidget {
  const _WindowSettingsEditor({required this.settings, required this.onClose});

  final WindowSettings settings;
  final void Function(WindowSettings) onClose;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(4),
      titlePadding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      title: const Center(child: Text('Window Settings')),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Regular'),
                    subtitle: ListenableBuilder(
                      listenable: settings,
                      builder: (BuildContext ctx, Widget? _) {
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: settings.regularSize.width
                                    .toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Initial width',
                                ),
                                onChanged: (String value) =>
                                    settings.regularSize = Size(
                                      double.tryParse(value) ?? 0,
                                      settings.regularSize.height,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextFormField(
                                initialValue: settings.regularSize.height
                                    .toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Initial height',
                                ),
                                onChanged: (String value) =>
                                    settings.regularSize = Size(
                                      settings.regularSize.width,
                                      double.tryParse(value) ?? 0,
                                    ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton(
            onPressed: () {
              onClose(settings);
            },
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}
