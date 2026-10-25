// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'popup_window_content.dart';

class WindowAnchorController {
  void showWindow(BaseWindowController controller) {
    if (controller != _controller) {
      hide();
      _controller = controller;
      _state?.controllerDidChange();
    }
  }

  bool get isWindowVisible => _controller != null && !_controller!.isDestroyed;

  ValueGetter<Rect> get anchorRect {
    return () {
      return _state?.anchorRect ?? Rect.zero;
    };
  }

  void hide() {
    final BaseWindowController? controller = _controller;
    if (controller == null) {
      return;
    }
    _controller = null;
    if (!controller.isDestroyed) {
      controller.destroy();
    }
    _state?.controllerDidChange();
  }

  _WindowAnchorState? _state;
  BaseWindowController? _controller;
}

class WindowAnchor extends StatefulWidget {
  const WindowAnchor({
    super.key,
    required this.controller,
    required this.contentBuilder,
    this.child,
  });

  final WindowAnchorController controller;
  final WidgetBuilder contentBuilder;
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _WindowAnchorState();
}

class _WindowAnchorState extends State<WindowAnchor> {
  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void dispose() {
    widget.controller._state = null;
    widget.controller.hide();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WindowAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  void controllerDidChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final BaseWindowController? windowController = widget.controller._controller;
    if (windowController != null && !windowController.isDestroyed) {
      return ViewAnchor(
        view: View(view: windowController.rootView, child: widget.contentBuilder(context)),
        child: widget.child ?? const SizedBox.shrink(),
      );
    }
    return widget.child ?? const SizedBox.shrink();
  }

  Rect get anchorRect {
    // Bounds of the anchor in the coordinates of its view.
    final renderObject = context.findRenderObject()! as RenderBox;
    return MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    );
  }
}

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  final anchorController = WindowAnchorController();

  void _onPressed(WindowSettings windowSettings) {
    // Toggle popup visibility.
    if (anchorController.isWindowVisible) {
      anchorController.hide();
    } else {
      final popupController = PopupWindowController(
        anchorRect: anchorController.anchorRect,
        parent: widget.parentController,
        positioner: windowSettings.positioner,
        delegate: _PopupWindowControllerDelegate(
          onDestroyed: () {
            anchorController.hide();
          },
        ),
      );
      anchorController.showWindow(popupController);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final WindowSettings windowSettings = WindowSettingsAccessor.of(context);

    return WindowAnchor(
      controller: anchorController,
      contentBuilder: (context) => const PopupWindowContent(),
      child: OutlinedButton(
        onPressed: () => _onPressed(windowSettings),
        child: Text(anchorController.isWindowVisible ? 'Hide Popup' : 'Show Popup'),
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
