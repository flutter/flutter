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
        final popup = PopupWindowController(
          anchorRect: info.anchorRect,
          positioner: windowSettings.positioner,
          parent: widget.parentController,
        );
        return (
          controller: popup,
          builder: (BuildContext context) => PopupWindowContent(controller: popup),
        );
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) => OutlinedButton(
          onPressed: _controller.toggle,
          child: Text(_controller.isShowing ? 'Hide Popup' : 'Show Popup'),
        ),
      ),
    );
  }
}
