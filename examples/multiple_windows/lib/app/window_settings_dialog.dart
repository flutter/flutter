// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'models.dart';

Future<void> showWindowSettingsDialog(
  BuildContext context,
  WindowSettings settings,
) async {
  return await showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext ctx) {
      return _WindowSettingsEditor(
        settings: settings,
        onClose: () => Navigator.of(context, rootNavigator: true).pop(),
      );
    },
  );
}

class _WindowSettingsEditor extends StatefulWidget {
  const _WindowSettingsEditor({required this.settings, required this.onClose});

  final WindowSettings settings;
  final void Function() onClose;

  @override
  State<_WindowSettingsEditor> createState() => _WindowSettingsEditorState();
}

class _WindowSettingsEditorState extends State<_WindowSettingsEditor> {
  final TextEditingController _regularWidthController = TextEditingController();
  final TextEditingController _regularHeightController =
      TextEditingController();
  final TextEditingController _dialogWidthController = TextEditingController();
  final TextEditingController _dialogHeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _regularWidthController.text = widget.settings.regularSize.width.toString();
    _regularHeightController.text = widget.settings.regularSize.height
        .toString();
    _dialogWidthController.text = widget.settings.dialogSize.width.toString();
    _dialogHeightController.text = widget.settings.dialogSize.height.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(4),
      titlePadding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      title: const Center(child: Text('Window Settings')),
      children: [
        ListTile(
          title: const Text('Regular'),
          subtitle: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _regularWidthController,
                  decoration: const InputDecoration(labelText: 'Initial width'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  controller: _regularHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Initial height',
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          title: const Text('Dialog'),
          subtitle: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dialogWidthController,
                  decoration: const InputDecoration(labelText: 'Initial width'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  controller: _dialogHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Initial height',
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton(
            onPressed: () {
              widget.settings.regularSize = Size(
                double.tryParse(_regularWidthController.text) ??
                    widget.settings.regularSize.width,
                double.tryParse(_regularHeightController.text) ??
                    widget.settings.regularSize.height,
              );
              widget.settings.dialogSize = Size(
                double.tryParse(_dialogWidthController.text) ??
                    widget.settings.dialogSize.width,
                double.tryParse(_dialogHeightController.text) ??
                    widget.settings.dialogSize.height,
              );
              widget.onClose();
            },
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}
