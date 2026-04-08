// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

void showDialogWindowEditDialog({
  required BuildContext context,
  required DialogWindowController controller,
}) {
  showDialog<void>(
    context: context,
    builder: (context) =>
        _DialogWindowEditDialog(controller: controller, onClose: () => Navigator.pop(context)),
  );
}

class _DialogWindowEditDialog extends StatefulWidget {
  const _DialogWindowEditDialog({required this.controller, required this.onClose});

  final DialogWindowController controller;
  final VoidCallback onClose;

  @override
  State<StatefulWidget> createState() => _DialogWindowEditDialogState();
}

class _DialogWindowEditDialogState extends State<_DialogWindowEditDialog> {
  late Size initialSize;
  late String initialTitle;
  late bool initialMinimized;

  late final TextEditingController widthController;
  late final TextEditingController heightController;
  late final TextEditingController titleController;

  bool? nextIsMinimized;

  void _init() {
    widget.controller.addListener(_onNotification);
    initialSize = widget.controller.contentSize;
    initialTitle = widget.controller.title;
    initialMinimized = widget.controller.isMinimized;

    widthController = TextEditingController(text: initialSize.width.toString());
    heightController = TextEditingController(text: initialSize.height.toString());
    titleController = TextEditingController(text: initialTitle);
    nextIsMinimized = null;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _DialogWindowEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onNotification);
      _init();
    }
  }

  void _onNotification() {
    // We listen on the state of the controller. If a value that the user
    // can edit changes from what it was initially set to, we invalidate
    // their current change and store the new "initial" value.
    if (widget.controller.contentSize != initialSize) {
      initialSize = widget.controller.contentSize;
      widthController.text = widget.controller.contentSize.width.toString();
      heightController.text = widget.controller.contentSize.height.toString();
    }
    if (widget.controller.isMinimized != initialMinimized) {
      setState(() {
        initialMinimized = widget.controller.isMinimized;
        nextIsMinimized = null;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNotification);
    widthController.dispose();
    heightController.dispose();
    titleController.dispose();
    super.dispose();
  }

  void _onSave() {
    final double? width = double.tryParse(widthController.text);
    final double? height = double.tryParse(heightController.text);
    final String? title = titleController.text.isEmpty ? null : titleController.text;
    if (width != null &&
        height != null &&
        (width != initialSize.width || height != initialSize.height)) {
      widget.controller.setSize(Size(width, height));
    }
    if (title != null && title != initialTitle) {
      widget.controller.setTitle(title);
    }
    if (nextIsMinimized != null && nextIsMinimized != initialMinimized) {
      widget.controller.setMinimized(nextIsMinimized!);
    }

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Window Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Width'),
          ),
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height'),
          ),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          CheckboxListTile(
            title: const Text('Minimized'),
            value: nextIsMinimized ?? initialMinimized,
            onChanged: (bool? value) {
              if (value != null) {
                setState(() => nextIsMinimized = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        TextButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
