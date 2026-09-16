// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'popup_window_content.dart';

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  final NestedWindowController _anchorController = NestedWindowController();

  void _onPressed() {
    _anchorController.toggle();
  }

  WindowEntry _buildEntry(Rect? anchorRect, WindowSettings windowSettings) {
    final controller = PopupWindowController(
      anchorRect: anchorRect!,
      positioner: windowSettings.positioner,
      delegate: _PopupWindowControllerDelegate(
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
      builder: (BuildContext context) => PopupWindowContent(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return NestedWindow(
      controller: _anchorController,
      entryBuilder: (Rect? anchorRect) => _buildEntry(anchorRect, windowSettings),
      child: OutlinedButton(
        onPressed: _onPressed,
        child: ListenableBuilder(
          listenable: _anchorController,
          builder: (BuildContext context, Widget? child) =>
              Text(_anchorController.showing ? 'Hide Popup' : 'Show Popup'),
        ),
      ),
    );
  }
}

class _PopupWindowControllerDelegate extends PopupWindowControllerDelegate {
  _PopupWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
