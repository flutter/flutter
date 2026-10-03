// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'popup_window_content.dart';

class _PopupDelegate with PopupWindowControllerDelegate {
  _PopupDelegate(this.onDestroyed);

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    onDestroyed();
  }
}

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  PopupWindowController? _popup;
  bool _disposing = false;

  void _onPopupDestroyed(PopupWindowController popup) {
    if (_disposing || _popup != popup) {
      return;
    }
    setState(() {
      _popup = null;
    });
  }

  void _onPressed(BuildContext anchorContext, WindowSettings windowSettings) {
    if (_popup != null) {
      _popup!.destroy();
      return;
    }
    final NestedWindowLayoutInfo info = NestedWindow.layoutInfoOf(anchorContext);
    late final PopupWindowController popup;
    popup = PopupWindowController(
      anchorRect: info.anchorRect,
      positioner: windowSettings.positioner,
      parent: widget.parentController,
      delegate: _PopupDelegate(() => _onPopupDestroyed(popup)),
    );
    setState(() {
      _popup = popup;
    });
  }

  @override
  void dispose() {
    _disposing = true;
    _popup?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return NestedWindow(
      controller: _popup,
      builder: (BuildContext context, PopupWindowController popup) =>
          PopupWindowContent(controller: popup),
      child: Builder(
        builder: (BuildContext anchorContext) => OutlinedButton(
          onPressed: () => _onPressed(anchorContext, windowSettings),
          child: Text(_popup != null ? 'Hide Popup' : 'Show Popup'),
        ),
      ),
    );
  }
}
