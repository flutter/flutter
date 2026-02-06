// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

void showRegularWindowEditDialog({
  required BuildContext context,
  required RegularWindowController controller,
}) {
  showDialog(
    context: context,
    builder: (context) => _RegularWindowEditDialog(
      controller: controller,
      onClose: () => Navigator.pop(context),
    ),
  );
}

class _RegularWindowEditDialog extends StatefulWidget {
  const _RegularWindowEditDialog({
    required this.controller,
    required this.onClose,
  });

  final RegularWindowController controller;
  final VoidCallback onClose;

  @override
  State<StatefulWidget> createState() => _RegularWindowEditDialogState();
}

class _RegularWindowEditDialogState extends State<_RegularWindowEditDialog> {
  late Size initialSize;
  late String initialTitle;
  late bool initialFullscreen;
  late bool initialMaximized;
  late bool initialMinimized;

  late final TextEditingController widthController;
  late final TextEditingController heightController;
  late final TextEditingController titleController;

  bool? nextIsFullscreen;
  bool? nextIsMaximized;
  bool? nextIsMinimized;

  void _init() {
    widget.controller.addListener(_onNotification);
    initialSize = widget.controller.contentSize;
    initialTitle = widget.controller.title;
    initialFullscreen = widget.controller.isFullscreen;
    initialMaximized = widget.controller.isMaximized;
    initialMinimized = widget.controller.isMinimized;

    widthController = TextEditingController(text: initialSize.width.toString());
    heightController = TextEditingController(
      text: initialSize.height.toString(),
    );
    titleController = TextEditingController(text: initialTitle);
    nextIsFullscreen = null;
    nextIsMaximized = null;
    nextIsMinimized = null;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _RegularWindowEditDialog oldWidget) {
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
    if (widget.controller.isFullscreen != initialFullscreen) {
      setState(() {
        initialFullscreen = widget.controller.isFullscreen;
        nextIsFullscreen = null;
      });
    }
    if (widget.controller.isMaximized != initialMaximized) {
      setState(() {
        initialMaximized = widget.controller.isMaximized;
        nextIsMaximized = null;
      });
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
    double? width = double.tryParse(widthController.text);
    double? height = double.tryParse(heightController.text);
    String? title = titleController.text.isEmpty ? null : titleController.text;
    if (width != null &&
        height != null &&
        (width != initialSize.width || height != initialSize.height)) {
      widget.controller.setSize(Size(width, height));
    }
    if (title != null && title != initialTitle) {
      widget.controller.setTitle(title);
    }
    if (nextIsFullscreen != null && nextIsFullscreen != initialFullscreen) {
      widget.controller.setFullscreen(nextIsFullscreen!);
    }
    if (nextIsMaximized != null && nextIsMaximized != initialMaximized) {
      widget.controller.setMaximized(nextIsMaximized!);
    }
    if (nextIsMinimized != null && nextIsMinimized != initialMinimized) {
      widget.controller.setMinimized(nextIsMinimized!);
    }

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Window Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Width'),
          ),
          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Height'),
          ),
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          CheckboxListTile(
            title: const Text('Fullscreen'),
            value: nextIsFullscreen ?? initialFullscreen,
            onChanged: (bool? value) {
              if (value != null) {
                setState(() => nextIsFullscreen = value);
              }
            },
          ),
          CheckboxListTile(
            title: const Text('Maximized'),
            value: nextIsMaximized ?? initialMaximized,
            onChanged: (bool? value) {
              if (value != null) {
                setState(() => nextIsMaximized = value);
              }
            },
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
        TextButton(onPressed: () => widget.onClose(), child: Text('Cancel')),
        TextButton(onPressed: () => _onSave(), child: Text('Save')),
      ],
    );
  }
}
