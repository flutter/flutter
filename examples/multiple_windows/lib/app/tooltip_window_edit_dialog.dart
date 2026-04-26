// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'models.dart';

void showTooltipWindowEditDialog({
  required BuildContext context,
  required TooltipWindowController controller,
}) {
  showDialog<void>(
    context: context,
    builder: (context) =>
        _TooltipWindowEditDialog(controller: controller, onClose: () => Navigator.pop(context)),
  );
}

class _TooltipWindowEditDialog extends StatefulWidget {
  const _TooltipWindowEditDialog({required this.controller, required this.onClose});

  final TooltipWindowController controller;
  final VoidCallback onClose;

  @override
  State<StatefulWidget> createState() => _TooltipWindowEditDialogState();
}

class _TooltipWindowEditDialogState extends State<_TooltipWindowEditDialog> {
  late final TextEditingController leftController;
  late final TextEditingController topController;
  late final TextEditingController widthController;
  late final TextEditingController heightController;
  late final TextEditingController offsetXController;
  late final TextEditingController offsetYController;

  WindowPositionerAnchor? parentAnchor;
  WindowPositionerAnchor? childAnchor;

  void _init() {
    // TooltipWindowController doesn't expose anchorRect as a getter,
    // so we initialize with zero values that the user can edit.
    leftController = TextEditingController(text: '0.0');
    topController = TextEditingController(text: '0.0');
    widthController = TextEditingController(text: '100.0');
    heightController = TextEditingController(text: '100.0');
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
  void didUpdateWidget(covariant _TooltipWindowEditDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _init();
    }
  }

  @override
  void dispose() {
    leftController.dispose();
    topController.dispose();
    widthController.dispose();
    heightController.dispose();
    offsetXController.dispose();
    offsetYController.dispose();
    super.dispose();
  }

  void _onSave() {
    final double? left = double.tryParse(leftController.text);
    final double? top = double.tryParse(topController.text);
    final double? width = double.tryParse(widthController.text);
    final double? height = double.tryParse(heightController.text);
    final double? offsetX = double.tryParse(offsetXController.text);
    final double? offsetY = double.tryParse(offsetYController.text);

    Rect? newRect;
    if (left != null && top != null && width != null && height != null) {
      newRect = Rect.fromLTWH(left, top, width, height);
    }

    WindowPositioner? newPositioner;
    if (parentAnchor != null || childAnchor != null || offsetX != null || offsetY != null) {
      newPositioner = WindowPositioner(
        parentAnchor: parentAnchor ?? WindowPositionerAnchor.center,
        childAnchor: childAnchor ?? WindowPositionerAnchor.center,
        offset: Offset(offsetX ?? 0.0, offsetY ?? 0.0),
      );
    }

    if (newRect != null || newPositioner != null) {
      widget.controller.updatePosition(anchorRect: newRect, positioner: newPositioner);
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
            Text('Anchor Rectangle', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: leftController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Anchor Left'),
            ),
            TextField(
              controller: topController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Anchor Top'),
            ),
            TextField(
              controller: widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Anchor Width'),
            ),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Anchor Height'),
            ),
            const SizedBox(height: 16),
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
