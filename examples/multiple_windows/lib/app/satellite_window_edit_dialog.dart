// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';

void showSatelliteWindowEditDialog({
  required BuildContext context,
  required SatelliteWindowController controller,
}) {
  showDialog<void>(
    context: context,
    builder: (context) =>
        _SatelliteWindowEditDialog(controller: controller, onClose: () => Navigator.pop(context)),
  );
}

class _SatelliteWindowEditDialog extends StatefulWidget {
  const _SatelliteWindowEditDialog({required this.controller, required this.onClose});

  final SatelliteWindowController controller;
  final VoidCallback onClose;

  @override
  State<_SatelliteWindowEditDialog> createState() => _SatelliteWindowEditDialogState();
}

class _SatelliteWindowEditDialogState extends State<_SatelliteWindowEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  late Size initialSize;
  late String initialTitle;

  void _init() {
    widget.controller.addListener(_onNotification);
    initialSize = widget.controller.contentSize;
    initialTitle = widget.controller.title;
    widthController.text = initialSize.width.toString();
    heightController.text = initialSize.height.toString();
    titleController.text = initialTitle;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _SatelliteWindowEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onNotification);
      _init();
    }
  }

  void _onNotification() {
    if (widget.controller.contentSize != initialSize) {
      initialSize = widget.controller.contentSize;
      widthController.text = initialSize.width.toString();
      heightController.text = initialSize.height.toString();
    }
    if (widget.controller.title != initialTitle) {
      initialTitle = widget.controller.title;
      titleController.text = initialTitle;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final size = Size(double.parse(widthController.text), double.parse(heightController.text));
    final String title = titleController.text;
    if (size != initialSize) {
      widget.controller.setSize(size);
    }
    if (title != initialTitle) {
      widget.controller.setTitle(title);
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Window Properties'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: .min,
            children: [
              TextFormField(
                controller: widthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Width'),
                validator: validateWindowDimension,
              ),
              TextFormField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height'),
                validator: validateWindowDimension,
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        TextButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
