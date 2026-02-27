// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'widget_preview_scaffold_controller.dart';

/// Provides controls to change the zoom level of a [WidgetPreview].
class ZoomControls extends StatelessWidget {
  /// Provides controls to change the zoom level of a [WidgetPreview].
  const ZoomControls({
    super.key,
    required TransformationController transformationController,
  }) : _transformationController = transformationController;

  final TransformationController _transformationController;

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.black;
    return _ControlDecorator(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
            icon: Icon(Icons.zoom_in_sharp),
            color: iconColor,
          ),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
            icon: Icon(Icons.zoom_out),
            color: iconColor,
          ),
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: _reset,
            icon: Icon(Icons.zoom_out_map),
            color: iconColor,
          ),
        ],
      ),
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
      padding: EdgeInsets.all(densePadding),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: defaultBorderRadius,
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
    final theme = Theme.of(context);
    return _ControlDecorator(
      child: ValueListenableBuilder<LayoutType>(
        valueListenable: controller.layoutTypeListenable,
        builder: (context, selectedLayout, _) {
          return Row(
            children: [
              IconButton(
                style: theme.iconButtonTheme.style,
                visualDensity: VisualDensity.compact,
                onPressed: () => controller.layoutType = LayoutType.gridView,
                icon: Icon(Icons.grid_on),
                color: selectedLayout == LayoutType.gridView
                    ? Colors.blue
                    : Colors.black,
              ),
              IconButton(
                onPressed: () => controller.layoutType = LayoutType.listView,
                visualDensity: VisualDensity.compact,
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

class WidgetInspectorToggle extends StatelessWidget {
  const WidgetInspectorToggle({super.key, required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    return _ControlDecorator(
      child: ValueListenableBuilder(
        valueListenable: controller.widgetInspectorVisible,
        builder: (context, widgetInspectorVisible, _) {
          final theme = Theme.of(context);
          return IconButton(
            style: theme.iconButtonTheme.style,
            visualDensity: VisualDensity.compact,
            onPressed: controller.toggleWidgetInspectorVisible,
            // TODO(bkonyi): replace with widget inspector icon.
            icon: Icon(Icons.image_search),
            color: widgetInspectorVisible ? Colors.blue : Colors.black,
          );
        },
      ),
    );
  }
}

/// A toggle button that enables / disables filtering previews by the currently
/// selected source file.
///
/// This control is hidden if the DTD Editor service isn't available.
class FilterBySelectedFileToggle extends StatelessWidget {
  const FilterBySelectedFileToggle({super.key, required this.controller});

  @visibleForTesting
  static const kTooltip = 'Filter previews by selected file';

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
            tooltip: kTooltip,
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
  const SoftRestartButton({super.key, required this.softRestartListenable});

  final ValueNotifier<bool> softRestartListenable;

  @override
  Widget build(BuildContext context) {
    return _ControlDecorator(
      child: IconButton(
        tooltip: 'Hot restart',
        onPressed: _onRestart,
        icon: Icon(Icons.refresh),
        color: Colors.black,
      ),
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
        color: Colors.black,
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
  const BrightnessToggleButton({super.key, required this.brightnessListenable});

  final ValueNotifier<Brightness> brightnessListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Brightness>(
      valueListenable: brightnessListenable,
      builder: (context, brightness, _) {
        final brightness = brightnessListenable.value;
        return _ControlDecorator(
          child: IconButton(
            tooltip: 'Switch to ${brightness.isLight ? 'dark' : 'light'} mode',
            onPressed: _toggleBrightness,
            icon: Icon(brightness.isLight ? Icons.dark_mode : Icons.light_mode),
            color: Colors.black,
          ),
        );
      },
    );
  }

  void _toggleBrightness() {
    brightnessListenable.value = brightnessListenable.value.invert;
  }
}
