// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'tooltip_window_content.dart';

class _TooltipDelegate with TooltipWindowControllerDelegate {
  _TooltipDelegate(this.onDestroyed);

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    onDestroyed();
  }
}

class TooltipButton extends StatefulWidget {
  const TooltipButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  TooltipWindowController? _tooltip;
  bool _disposing = false;

  void _onTooltipDestroyed(TooltipWindowController tooltip) {
    if (_disposing || _tooltip != tooltip) {
      return;
    }
    setState(() {
      _tooltip = null;
    });
  }

  void _onPressed(BuildContext anchorContext, WindowSettings windowSettings) {
    if (_tooltip != null) {
      _tooltip!.destroy();
      return;
    }
    final NestedWindowLayoutInfo info = NestedWindow.layoutInfoOf(anchorContext);
    late final TooltipWindowController tooltip;
    tooltip = TooltipWindowController(
      anchorRect: info.anchorRect,
      positioner: windowSettings.positioner,
      parent: widget.parentController,
      delegate: _TooltipDelegate(() => _onTooltipDestroyed(tooltip)),
    );
    setState(() {
      _tooltip = tooltip;
    });
  }

  @override
  void dispose() {
    _disposing = true;
    _tooltip?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return NestedWindow(
      controller: _tooltip,
      builder: (BuildContext context, TooltipWindowController tooltip) =>
          TooltipWindowContent(controller: tooltip),
      child: Builder(
        builder: (BuildContext anchorContext) => OutlinedButton(
          onPressed: () => _onPressed(anchorContext, windowSettings),
          child: Text(_tooltip != null ? 'Hide Tooltip' : 'Show Tooltip'),
        ),
      ),
    );
  }
}
