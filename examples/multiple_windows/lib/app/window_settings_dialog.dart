// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:flutter/src/widgets/_window_positioner.dart';
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
  final TextEditingController _offsetDxController = TextEditingController();
  final TextEditingController _offsetDyController = TextEditingController();

  late bool _flipX;
  late bool _flipY;
  late bool _slideX;
  late bool _slideY;
  late bool _resizeX;
  late bool _resizeY;

  late WindowPositionerAnchor _parentAnchor;

  late WindowPositionerAnchor _childAnchor;

  @override
  void initState() {
    super.initState();
    _regularWidthController.text = widget.settings.regularSize.width.toString();
    _regularHeightController.text = widget.settings.regularSize.height
        .toString();
    _regularWidthController.addListener(_updateRegularSize);
    _regularHeightController.addListener(_updateRegularSize);
    _dialogWidthController.addListener(_updateDialogSize);
    _dialogHeightController.addListener(_updateDialogSize);
    _dialogWidthController.text = widget.settings.dialogSize.width.toString();
    _dialogHeightController.text = widget.settings.dialogSize.height.toString();
    _offsetDxController.text = widget.settings.positioner.offset.dx.toString();
    _offsetDyController.text = widget.settings.positioner.offset.dy.toString();
    _flipX = widget.settings.positioner.constraintAdjustment.flipX;
    _flipY = widget.settings.positioner.constraintAdjustment.flipY;
    _slideX = widget.settings.positioner.constraintAdjustment.slideX;
    _slideY = widget.settings.positioner.constraintAdjustment.slideY;
    _resizeX = widget.settings.positioner.constraintAdjustment.resizeX;
    _resizeY = widget.settings.positioner.constraintAdjustment.resizeY;
    _parentAnchor = widget.settings.positioner.parentAnchor;
    _childAnchor = widget.settings.positioner.childAnchor;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(4),
      titlePadding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      title: const Center(child: Text('Window Settings')),
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildRegularEditor(),
                    const Divider(),
                    _buildDialogEditor(),
                    const Divider(),
                    _buildTooltipEditor(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegularEditor() {
    return ListTile(
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
              decoration: const InputDecoration(labelText: 'Initial height'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogEditor() {
    return ListTile(
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
              decoration: const InputDecoration(labelText: 'Initial height'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltipEditor() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: const Text('Tooltip'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parent Anchor',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          DropdownButton<WindowPositionerAnchor>(
            isExpanded: true,
            value: _parentAnchor,
            items: [
              for (WindowPositionerAnchor anchor
                  in WindowPositionerAnchor.values)
                DropdownMenuItem(
                  value: anchor,
                  child: Text(anchorToString(anchor)),
                ),
            ],
            onChanged: (WindowPositionerAnchor? value) {
              if (value != null) {
                setState(() {
                  _parentAnchor = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Child Anchor',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          DropdownButton<WindowPositionerAnchor>(
            isExpanded: true,
            value: _childAnchor,
            items: WindowPositionerAnchor.values.map((anchor) {
              return DropdownMenuItem(
                value: anchor,
                child: Text(anchorToString(anchor)),
              );
            }).toList(),
            onChanged: (WindowPositionerAnchor? value) {
              if (value != null) {
                setState(() {
                  _childAnchor = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Offset',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _offsetDxController,
                  decoration: const InputDecoration(labelText: 'X'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextFormField(
                  controller: _offsetDyController,
                  decoration: const InputDecoration(labelText: 'Y'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Constraint Adjustment',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Flip',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              const SizedBox(
                width: 30,
                child: Text('X', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _flipX,
                onChanged: (bool value) {
                  setState(() {
                    _flipX = value;
                  });
                },
              ),
              const SizedBox(width: 24),
              const SizedBox(
                width: 30,
                child: Text('Y', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _flipY,
                onChanged: (bool value) {
                  setState(() {
                    _flipY = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Slide',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              const SizedBox(
                width: 30,
                child: Text('X', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _slideX,
                onChanged: (bool value) {
                  setState(() {
                    _slideX = value;
                  });
                },
              ),
              const SizedBox(width: 24),
              const SizedBox(
                width: 30,
                child: Text('Y', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _slideY,
                onChanged: (bool value) {
                  setState(() {
                    _slideY = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Resize',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              const SizedBox(
                width: 30,
                child: Text('X', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _resizeX,
                onChanged: (bool value) {
                  setState(() {
                    _resizeX = value;
                  });
                },
              ),
              const SizedBox(width: 24),
              const SizedBox(
                width: 30,
                child: Text('Y', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: _resizeY,
                onChanged: (bool value) {
                  setState(() {
                    _resizeY = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
          const SizedBox(width: 12),
          FilledButton(
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

              widget.settings.positioner = widget.settings.positioner.copyWith(
                parentAnchor: _parentAnchor,
                childAnchor: _childAnchor,
                offset: Offset(
                  double.tryParse(_offsetDxController.text) ??
                      widget.settings.positioner.offset.dx,
                  double.tryParse(_offsetDyController.text) ??
                      widget.settings.positioner.offset.dy,
                ),

                constraintAdjustment: WindowPositionerConstraintAdjustment(
                  flipX: _flipX,
                  flipY: _flipY,
                  slideX: _slideX,
                  slideY: _slideY,
                  resizeX: _resizeX,
                  resizeY: _resizeY,
                ),
              );
              widget.onClose();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _updateRegularSize() {
    widget.settings.regularSize = Size(
      double.tryParse(_regularWidthController.text) ??
          widget.settings.regularSize.width,
      double.tryParse(_regularHeightController.text) ??
          widget.settings.regularSize.height,
    );
  }

  void _updateDialogSize() {
    widget.settings.dialogSize = Size(
      double.tryParse(_dialogWidthController.text) ??
          widget.settings.dialogSize.width,
      double.tryParse(_dialogHeightController.text) ??
          widget.settings.dialogSize.height,
    );
  }

  @override
  void dispose() {
    _regularWidthController.removeListener(_updateRegularSize);
    _regularHeightController.removeListener(_updateRegularSize);
    _dialogWidthController.removeListener(_updateDialogSize);
    _dialogHeightController.removeListener(_updateDialogSize);
    _regularWidthController.dispose();
    _regularHeightController.dispose();
    _dialogWidthController.dispose();
    _dialogHeightController.dispose();
    super.dispose();
  }
}
