// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'widget_preview_scaffold_controller.dart';

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
          icon: Icons.zoom_out_map,
        ),
      ],
    );
  }

  void _zoomIn() {
    _transformationController.value = Matrix4.copy(
      _transformationController.value,
    ).scaledByDouble(1.1, 1.1, 1.1, 1);
  }

  void _zoomOut() {
    final Matrix4 updated = Matrix4.copy(
      _transformationController.value,
    ).scaledByDouble(0.9, 0.9, 0.9, 1);

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

class _ControlDecorator extends StatelessWidget {
  const _ControlDecorator({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: child,
    );
  }
}

/// Allows for controlling the grid vs layout view in the preview environment.
class LayoutTypeSelector extends StatelessWidget {
  const LayoutTypeSelector({super.key, required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    return _ControlDecorator(
      child: ValueListenableBuilder<LayoutType>(
        valueListenable: controller.layoutTypeListenable,
        builder: (context, selectedLayout, _) {
          return Row(
            children: [
              IconButton(
                onPressed: () => controller.layoutType = LayoutType.gridView,
                icon: Icon(Icons.grid_on),
                color: selectedLayout == LayoutType.gridView
                    ? Colors.blue
                    : Colors.black,
              ),
              IconButton(
                onPressed: () => controller.layoutType = LayoutType.listView,
                icon: Icon(Icons.view_list),
                color: selectedLayout == LayoutType.listView
                    ? Colors.blue
                    : Colors.black,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A toggle button that enables / disables filtering previews by the currently
/// selected source file.
class FilterBySelectedFileToggle extends StatelessWidget {
  const FilterBySelectedFileToggle({super.key, required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    return _ControlDecorator(
      child: ValueListenableBuilder(
        valueListenable: controller.filterBySelectedFileListenable,
        builder: (context, value, child) {
          return IconButton(
            onPressed: controller.toggleFilterBySelectedFile,
            icon: Icon(Icons.file_open),
            color: value ? Colors.blue : Colors.black,
            tooltip: 'Filter previews by selected file',
          );
        },
      ),
    );
  }
}

/// A button that triggers a "soft" restart of a previewed widget.
///
/// A soft restart removes the previewed widget from the widget tree for a frame before
/// re-inserting it on the next frame. This has the effect of re-running local initializers in
/// State objects, which normally requires a hot restart to accomplish in a normal application.
class SoftRestartButton extends StatelessWidget {
  const SoftRestartButton({
    super.key,
    required this.enabled,
    required this.softRestartListenable,
  });

  final ValueNotifier<bool> softRestartListenable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _WidgetPreviewIconButton(
      tooltip: 'Hot restart',
      onPressed: enabled ? _onRestart : null,
      icon: Icons.refresh,
    );
  }

  void _onRestart() {
    softRestartListenable.value = true;
  }
}

/// A button that triggers a restart of the widget previewer through a hot restart request made
/// through DTD.
class WidgetPreviewerRestartButton extends StatelessWidget {
  const WidgetPreviewerRestartButton({super.key, required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    return _ControlDecorator(
      child: IconButton(
        tooltip: 'Restart the Widget Previewer',
        onPressed: controller.dtdServices.hotRestartPreviewer,
        icon: Icon(Icons.restart_alt),
      ),
    );
  }
}

extension on Brightness {
  Brightness get invert => isLight ? Brightness.dark : Brightness.light;
  bool get isLight => this == Brightness.light;
}

/// A button that toggles the current theme brightness.
class BrightnessToggleButton extends StatelessWidget {
  const BrightnessToggleButton({
    super.key,
    required this.enabled,
    required this.brightnessListenable,
  });

  final ValueNotifier<Brightness> brightnessListenable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: brightnessListenable,
      builder: (context, brightness, _) {
        final brightness = brightnessListenable.value;
        return _WidgetPreviewIconButton(
          tooltip: 'Switch to ${brightness.isLight ? 'dark' : 'light'} mode',
          onPressed: enabled ? _toggleBrightness : null,
          icon: brightness.isLight ? Icons.dark_mode : Icons.light_mode,
        );
      },
    );
  }

  void _toggleBrightness() {
    brightnessListenable.value = brightnessListenable.value.invert;
  }
}
