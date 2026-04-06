// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'element_position_tracker.dart';
import 'models.dart';

class TooltipButton extends StatefulWidget {
  const TooltipButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  TooltipWindowController? _tooltipController;
  ElementPositionTracker? _tooltipTracker;
  final GlobalKey _tooltipButtonKey = GlobalKey();

  @override
  void dispose() {
    _tooltipTracker?.dispose();
    super.dispose();
  }

  void _onPressed(
    final KeyedWindowManager windowManager,
    final WindowSettings windowSettings,
  ) {
    // Toggle tooltip visibility.
    if (_tooltipController != null) {
      _tooltipController!.destroy();
      _tooltipTracker?.dispose;
      setState(() {
        _tooltipController = null;
        _tooltipTracker = null;
      });
    } else {
      // Tooltip is not shown, show it.
      final tracker = ElementPositionTracker(
        element: _tooltipButtonKey.currentContext!,
      );
      final UniqueKey key = UniqueKey();
      final controller = TooltipWindowController(
        anchorRect: tracker.getGlobalRect()!,
        positioner: windowSettings.positioner,
        delegate: _TooltipWindowControllerDelegate(
          onDestroyed: () {
            windowManager.remove(key);
            tracker.dispose();
            if (mounted) {
              setState(() {
                _tooltipController = null;
                _tooltipTracker = null;
              });
            }
          },
        ),
        parent: widget.parentController,
      );
      tracker.onGlobalRectChange = (rect) {
        controller.updatePosition(anchorRect: rect);
      };
      windowManager.add(KeyedWindow(key: key, controller: controller));
      setState(() {
        _tooltipController = controller;
        _tooltipTracker = tracker;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final KeyedWindowManager windowManager = KeyedWindowManagerAccessor.of(
      context,
    );
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return OutlinedButton(
      key: _tooltipButtonKey,
      onPressed: () => _onPressed(windowManager, windowSettings),
      child: Text(_tooltipController != null ? 'Hide Tooltip' : 'Show Tooltip'),
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
