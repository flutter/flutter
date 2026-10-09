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
  final NestedWindowController _controller = NestedWindowController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return NestedWindow(
      controller: _controller,
      windowBuilder: (BuildContext context, NestedWindowLayoutInfo info) {
        final tooltip = TooltipWindowController(
          anchorRect: info.anchorRect,
          positioner: windowSettings.positioner,
          parent: widget.parentController,
        );
        return (
          controller: tooltip,
          builder: (BuildContext context) => TooltipWindowContent(controller: tooltip),
        );
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) => OutlinedButton(
          onPressed: _controller.toggle,
          child: Text(_controller.isShowing ? 'Hide Tooltip' : 'Show Tooltip'),
        ),
      ),
    );
  }
}
