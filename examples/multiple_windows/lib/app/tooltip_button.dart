// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'tooltip_window_content.dart';
import 'element_position_tracker.dart';
import 'models.dart';

class TooltipButton extends StatefulWidget {
  const TooltipButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  WindowEntry? _tooltipEntry;
  ElementPositionTracker? _tooltipTracker;
  final GlobalKey _tooltipButtonKey = GlobalKey();

  @override
  void dispose() {
    _tooltipTracker?.dispose();
    super.dispose();
  }

  void _onPressed(
    final WindowRegistry windowRegistry,
    final WindowSettings windowSettings,
  ) {
    // Toggle tooltip visibility.
    if (_tooltipEntry != null) {
      _tooltipEntry!.controller.destroy();
      _tooltipTracker?.dispose();
      setState(() {
        _tooltipEntry = null;
        _tooltipTracker = null;
      });
    } else {
      // Tooltip is not shown, show it.
      final tracker = ElementPositionTracker(
        element: _tooltipButtonKey.currentContext!,
      );
      late final WindowEntry entry;
      final controller = TooltipWindowController(
        anchorRect: tracker.getGlobalRect()!,
        positioner: windowSettings.positioner,
        delegate: _TooltipWindowControllerDelegate(
          onDestroyed: () {
            windowRegistry.unregister(entry);
            tracker.dispose();
            if (mounted) {
              setState(() {
                _tooltipEntry = null;
                _tooltipTracker = null;
              });
            }
          },
        ),
        parent: widget.parentController,
      );
      entry = WindowEntry(
        controller: controller,
        builder: (BuildContext context) =>
            TooltipWindowContent(controller: controller),
      );
      windowRegistry.register(entry);
      tracker.onGlobalRectChange = (rect) {
        controller.updatePosition(anchorRect: rect);
      };
      setState(() {
        _tooltipEntry = entry;
        _tooltipTracker = tracker;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WindowRegistry windowManager = WindowRegistry.of(context);
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return OutlinedButton(
      key: _tooltipButtonKey,
      onPressed: () => _onPressed(windowManager, windowSettings),
      child: Text(_tooltipEntry != null ? 'Hide Tooltip' : 'Show Tooltip'),
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
