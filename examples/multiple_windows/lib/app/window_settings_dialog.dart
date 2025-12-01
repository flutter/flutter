// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  @override
  void initState() {
    super.initState();
    _regularWidthController.text = widget.settings.regularSize.width.toString();
    _regularHeightController.text = widget.settings.regularSize.height
        .toString();
    _dialogWidthController.text = widget.settings.dialogSize.width.toString();
    _dialogHeightController.text = widget.settings.dialogSize.height.toString();
    _offsetDxController.text = widget.settings.positioner.offset.dx.toString();
    _offsetDyController.text = widget.settings.positioner.offset.dy.toString();

    // ignore: invalid_use_of_internal_member
    _flipX = widget.settings.positioner.constraintAdjustment.flipX;
    // ignore: invalid_use_of_internal_member
    _flipY = widget.settings.positioner.constraintAdjustment.flipY;
    // ignore: invalid_use_of_internal_member
    _slideX = widget.settings.positioner.constraintAdjustment.slideX;
    // ignore: invalid_use_of_internal_member
    _slideY = widget.settings.positioner.constraintAdjustment.slideY;
    // ignore: invalid_use_of_internal_member
    _resizeX = widget.settings.positioner.constraintAdjustment.resizeX;
    // ignore: invalid_use_of_internal_member
    _resizeY = widget.settings.positioner.constraintAdjustment.resizeY;
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
          child: ListView(
            children: [
              ListTile(
                title: const Text('Regular'),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _regularWidthController,
                        decoration: const InputDecoration(
                          labelText: 'Initial width',
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Initial width',
                        ),
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
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Tooltip Offset'),
                subtitle: Row(
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
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Tooltip Constraint Adjustment'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('X'),
                        Switch(
                          value: _flipX,
                          onChanged: (bool value) {
                            setState(() {
                              _flipX = value;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        const Text('Y'),
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Slide',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('X'),
                        Switch(
                          value: _slideX,
                          onChanged: (bool value) {
                            setState(() {
                              _slideX = value;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        const Text('Y'),
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resize',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('X'),
                        Switch(
                          value: _resizeX,
                          onChanged: (bool value) {
                            setState(() {
                              _resizeX = value;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        const Text('Y'),
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
                    // ignore: invalid_use_of_internal_member
                    widget.settings.positioner = widget.settings.positioner
                        .copyWith(
                          offset: Offset(
                            double.tryParse(_offsetDxController.text) ??
                                widget.settings.positioner.offset.dx,
                            double.tryParse(_offsetDyController.text) ??
                                widget.settings.positioner.offset.dy,
                          ),
                          // ignore: invalid_use_of_internal_member
                          constraintAdjustment:
                              WindowPositionerConstraintAdjustment(
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
