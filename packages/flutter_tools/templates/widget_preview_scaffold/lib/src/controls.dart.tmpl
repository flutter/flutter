// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _WidgetPreviewIconButton extends StatelessWidget {
  const _WidgetPreviewIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final void Function()? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Ink(
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: onPressed != null ? Colors.lightBlue : Colors.grey,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(color: Colors.white, icon),
        ),
      ),
    );
  }
}

/// Provides controls to change the zoom level of a [WidgetPreview].
class ZoomControls extends StatelessWidget {
  /// Provides controls to change the zoom level of a [WidgetPreview].
  const ZoomControls({
    super.key,
    required TransformationController transformationController,
    required this.enabled,
  }) : _transformationController = transformationController;

  final TransformationController _transformationController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _WidgetPreviewIconButton(
          tooltip: 'Zoom in',
          onPressed: enabled ? _zoomIn : null,
          icon: Icons.zoom_in,
        ),
        const SizedBox(width: 10),
        _WidgetPreviewIconButton(
          tooltip: 'Zoom out',
          onPressed: enabled ? _zoomOut : null,
          icon: Icons.zoom_out,
        ),
        const SizedBox(width: 10),
        _WidgetPreviewIconButton(
          tooltip: 'Reset zoom',
          onPressed: enabled ? _reset : null,
          icon: Icons.refresh,
        ),
      ],
    );
  }

  void _zoomIn() {
    _transformationController.value = Matrix4.copy(
      _transformationController.value,
    ).scaled(1.1);
  }

  void _zoomOut() {
    final Matrix4 updated = Matrix4.copy(
      _transformationController.value,
    ).scaled(0.9);

    // Don't allow for zooming out past the original size of the widget.
    // Assumes scaling is evenly applied to the entire matrix.
    if (updated.entry(0, 0) < 1.0) {
      updated.setIdentity();
    }

    _transformationController.value = updated;
  }

  void _reset() {
    _transformationController.value = Matrix4.identity();
  }
}
