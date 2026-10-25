// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';

void showPopupWindowEditDialog({
  required BuildContext context,
  required PopupWindowController controller,
}) {
  showDialog<void>(
    context: context,
    builder: (context) =>
        _PopupWindowEditDialog(controller: controller, onClose: () => Navigator.pop(context)),
  );
}

class _PopupWindowEditDialog extends StatefulWidget {
  const _PopupWindowEditDialog({required this.controller, required this.onClose});

  final PopupWindowController controller;
  final VoidCallback onClose;

  @override
  State<StatefulWidget> createState() => _PopupWindowEditDialogState();
}

class _PopupWindowEditDialogState extends State<_PopupWindowEditDialog> {
  late final TextEditingController offsetXController;
  late final TextEditingController offsetYController;

  WindowPositionerAnchor? parentAnchor;
  WindowPositionerAnchor? childAnchor;

  void _init() {
    offsetXController = TextEditingController(text: '0.0');
    offsetYController = TextEditingController(text: '0.0');
    parentAnchor = null;
    childAnchor = null;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _PopupWindowEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _init();
    }
  }

  @override
  void dispose() {
    offsetXController.dispose();
    offsetYController.dispose();
    super.dispose();
  }

  void _onSave() {
    final double? offsetX = double.tryParse(offsetXController.text);
    final double? offsetY = double.tryParse(offsetYController.text);

    WindowPositioner? newPositioner;
    if (parentAnchor != null || childAnchor != null || offsetX != null || offsetY != null) {
      newPositioner = WindowPositioner(
        parentAnchor: parentAnchor ?? WindowPositionerAnchor.center,
        childAnchor: childAnchor ?? WindowPositionerAnchor.center,
        offset: Offset(offsetX ?? 0.0, offsetY ?? 0.0),
      );
    }

    if (newPositioner != null) {
      widget.controller.updatePosition(positioner: newPositioner);
    }

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Window Properties'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Positioner', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<WindowPositionerAnchor>(
              initialValue: parentAnchor,
              decoration: const InputDecoration(labelText: 'Parent Anchor'),
              items: WindowPositionerAnchor.values.map((anchor) {
                return DropdownMenuItem(value: anchor, child: Text(anchorToString(anchor)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  parentAnchor = value;
                });
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<WindowPositionerAnchor>(
              initialValue: childAnchor,
              decoration: const InputDecoration(labelText: 'Child Anchor'),
              items: WindowPositionerAnchor.values.map((anchor) {
                return DropdownMenuItem(value: anchor, child: Text(anchorToString(anchor)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  childAnchor = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: offsetXController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Offset X'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: offsetYController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Offset Y'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        TextButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
