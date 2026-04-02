// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'window_content.dart';
import 'models.dart';
import 'element_position_tracker.dart';

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  PopupWindowController? _popupController;
  ElementPositionTracker? _popupTracker;
  final GlobalKey _popupButtonKey = GlobalKey();

  @override
  void dispose() {
    _popupTracker?.dispose();
    super.dispose();
  }

  void _onPressed(
    final KeyedWindowManager windowManager,
    final WindowSettings windowSettings,
  ) {
    // Toggle popup visibility.
    if (_popupController != null) {
      _popupController!.destroy();
      _popupTracker?.dispose();
      _popupWindow = null;
      setState(() {
        _popupController = null;
        _popupTracker = null;
      });
    } else {
      // Popup is not shown, show it.
      final tracker = ElementPositionTracker(
        element: _popupButtonKey.currentContext!,
      );
      final UniqueKey key = UniqueKey();
      final controller = PopupWindowController(
        anchorRect: tracker.getGlobalRect()!,
        positioner: windowSettings.positioner,
        delegate: _PopupWindowControllerDelegate(
          onDestroyed: () {
            windowManager.remove(key);
            tracker.dispose();
            _popupController = null;
            _popupTracker = null;
          },
        ),
        parent: widget.parentController,
      );
      tracker.onGlobalRectChange = (rect) {
        controller.updatePosition(anchorRect: rect);
      };
      setState(() {
        _popupWindow = WindowContent(
          windowKey: _windowKey,
          controller: controller,
          onDestroyed: () {},
          onError: () {},
        );
        _popupController = controller;
        _popupTracker = tracker;
      });
    }
  }

  final _windowKey = GlobalKey();
  final _viewAnchorKey = GlobalKey();
  Widget? _popupWindow;

  @override
  Widget build(BuildContext context) {
    final KeyedWindowManager windowManager = KeyedWindowManagerAccessor.of(
      context,
    );
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return ViewAnchor(
      key: _viewAnchorKey,
      view: _popupWindow,
      child: OutlinedButton(
        key: _popupButtonKey,
        onPressed: () => _onPressed(windowManager, windowSettings),
        child: Text(_popupController != null ? 'Hide Popup' : 'Show Popup'),
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
