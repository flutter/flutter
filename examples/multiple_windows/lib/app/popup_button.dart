// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'models.dart';
import 'popup_window_content.dart';
import 'element_position_tracker.dart';

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  WindowEntry? _popupWindowEntry;
  ElementPositionTracker? _popupTracker;
  final GlobalKey _popupButtonKey = GlobalKey();

  @override
  void dispose() {
    _popupTracker?.dispose();
    super.dispose();
  }

  void _onPressed(
    final WindowRegistry windowRegistry,
    final WindowSettings windowSettings,
  ) {
    // Toggle popup visibility.
    if (_popupWindowEntry != null) {
      _popupWindowEntry!.controller.destroy();
      _popupTracker?.dispose();
      setState(() {
        _popupWindowEntry = null;
        _popupTracker = null;
      });
    } else {
      // Popup is not shown, show it.
      final tracker = ElementPositionTracker(
        element: _popupButtonKey.currentContext!,
      );
      late final WindowEntry entry;
      final controller = PopupWindowController(
        anchorRect: tracker.getGlobalRect()!,
        positioner: windowSettings.positioner,
        delegate: _PopupWindowControllerDelegate(
          onDestroyed: () {
            windowRegistry.unregister(entry);
            tracker.dispose();
            if (mounted) {
              setState(() {
                _popupWindowEntry = null;
                _popupTracker = null;
              });
            }
          },
        ),
        parent: widget.parentController,
      );
      entry = WindowEntry(
        controller: controller,
        builder: (BuildContext context) =>
            PopupWindowContent(controller: controller),
      );
      windowRegistry.register(entry);
      tracker.onGlobalRectChange = (rect) {
        controller.updatePosition(anchorRect: rect);
      };
      setState(() {
        _popupWindowEntry = entry;
        _popupTracker = tracker;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WindowRegistry windowManager = WindowRegistry.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return OutlinedButton(
      key: _popupButtonKey,
      onPressed: () => _onPressed(windowManager, windowSettings),
      child: Text(_popupWindowEntry != null ? 'Hide Popup' : 'Show Popup'),
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
