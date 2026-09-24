// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'tooltip_window_content.dart';

class TooltipButton extends StatefulWidget {
  const TooltipButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  final NestedWindowController _anchorController = NestedWindowController();

  void _onPressed() {
    _anchorController.toggle();
  }

  WindowEntry _buildEntry(Rect? anchorRect, WindowSettings windowSettings) {
    final controller = TooltipWindowController(
      anchorRect: anchorRect ?? Rect.zero,
      positioner: windowSettings.positioner,
      delegate: _TooltipWindowControllerDelegate(
        onDestroyed: () {
          if (mounted) {
            _anchorController.hide();
          }
        },
      ),
      parent: widget.parentController,
    );
    return WindowEntry(
      controller: controller,
      builder: (BuildContext context) => TooltipWindowContent(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return NestedWindow(
      controller: _anchorController,
      entryBuilder: (anchorRect) => _buildEntry(anchorRect, windowSettings),
      child: OutlinedButton(
        onPressed: _onPressed,
        child: ListenableBuilder(
          listenable: _anchorController,
          builder: (BuildContext context, Widget? child) =>
              Text(_anchorController.showing ? 'Hide Tooltip' : 'Show Tooltip'),
        ),
      ),
    );
  }
}

class _TooltipWindowControllerDelegate extends TooltipWindowControllerDelegate {
  _TooltipWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
