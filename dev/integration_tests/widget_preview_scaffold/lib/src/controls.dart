// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'theme/theme.dart';
import 'widget_preview_scaffold_controller.dart';

enum _PreviewSearchFilter {
  groupName('Group name'),
  previewName('Preview name'),
  containingScript('Containing script'),
  containingPackage('Containing package');

  const _PreviewSearchFilter(this.label);

  final String label;
}

abstract class _SearchFilterConfig {
  const _SearchFilterConfig(this.filter, this._controller);

  final _PreviewSearchFilter filter;
  final WidgetPreviewScaffoldController _controller;

  String get label => filter.label;

  ValueListenable<bool> listenable();

  bool onToggle();
}

class _GroupSearchFilter extends _SearchFilterConfig {
  const _GroupSearchFilter(WidgetPreviewScaffoldController controller)
    : super(_PreviewSearchFilter.groupName, controller);

  @override
  ValueListenable<bool> listenable() => _controller.searchByGroupNameListenable;

  @override
  bool onToggle() => _controller.toggleSearchByGroupName();
}

class _PreviewNameSearchFilter extends _SearchFilterConfig {
  const _PreviewNameSearchFilter(WidgetPreviewScaffoldController controller)
    : super(_PreviewSearchFilter.previewName, controller);

  @override
  ValueListenable<bool> listenable() =>
      _controller.searchByPreviewNameListenable;

  @override
  bool onToggle() => _controller.toggleSearchByPreviewName();
}

class _ContainingScriptSearchFilter extends _SearchFilterConfig {
  const _ContainingScriptSearchFilter(
    WidgetPreviewScaffoldController controller,
  ) : super(_PreviewSearchFilter.containingScript, controller);

  @override
  ValueListenable<bool> listenable() =>
      _controller.searchByContainingScriptListenable;

  @override
  bool onToggle() => _controller.toggleSearchByContainingScript();
}

class _ContainingPackageSearchFilter extends _SearchFilterConfig {
  const _ContainingPackageSearchFilter(
    WidgetPreviewScaffoldController controller,
  ) : super(_PreviewSearchFilter.containingPackage, controller);

  @override
  ValueListenable<bool> listenable() =>
      _controller.searchByContainingPackageListenable;

  @override
  bool onToggle() => _controller.toggleSearchByContainingPackage();
}

/// Provides controls to change the zoom level of a [WidgetPreview].
class ZoomControls extends StatelessWidget {
  /// Provides controls to change the zoom level of a [WidgetPreview].
  const ZoomControls({
    super.key,
    required TransformationController transformationController,
    // ignore: prefer_initializing_formals
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

/// Controls for searching and filtering widget previews.
///
/// This widget combines a text query field with a popup menu for selecting
/// which preview fields are included in search.
class PreviewSearchControls extends StatefulWidget {
  const PreviewSearchControls({super.key, required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  State<PreviewSearchControls> createState() => _PreviewSearchControlsState();
}

class _PreviewSearchControlsState extends State<PreviewSearchControls> {
  late final TextEditingController _searchController;
  late final List<_SearchFilterConfig> _searchFilters;

  @override
  void initState() {
    super.initState();
    _searchFilters = <_SearchFilterConfig>[
      _GroupSearchFilter(widget.controller),
      _PreviewNameSearchFilter(widget.controller),
      _ContainingScriptSearchFilter(widget.controller),
      _ContainingPackageSearchFilter(widget.controller),
    ];
    _searchController = TextEditingController(
      text: widget.controller.searchQueryListenable.value,
    );
    widget.controller.searchQueryListenable.addListener(
      _syncControllerQueryToTextField,
    );
  }

  @override
  void didUpdateWidget(covariant PreviewSearchControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) {
      return;
    }
    oldWidget.controller.searchQueryListenable.removeListener(
      _syncControllerQueryToTextField,
    );
    widget.controller.searchQueryListenable.addListener(
      _syncControllerQueryToTextField,
    );
    _searchFilters
      ..clear()
      ..addAll(<_SearchFilterConfig>[
        _GroupSearchFilter(widget.controller),
        _PreviewNameSearchFilter(widget.controller),
        _ContainingScriptSearchFilter(widget.controller),
        _ContainingPackageSearchFilter(widget.controller),
      ]);
    _syncControllerQueryToTextField();
  }

  @override
  void dispose() {
    widget.controller.searchQueryListenable.removeListener(
      _syncControllerQueryToTextField,
    );
    _searchController.dispose();
    super.dispose();
  }

  void _syncControllerQueryToTextField() {
    final query = widget.controller.searchQueryListenable.value;
    if (_searchController.text == query) {
      return;
    }

    _searchController.value = _searchController.value.copyWith(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ControlDecorator(
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: defaultButtonHeight,
              child: TextField(
                controller: _searchController,
                style: theme.regularTextStyleWithColor(Colors.black),
                cursorColor: Colors.black,
                textAlignVertical: TextAlignVertical.center,
                onChanged: widget.controller.updateSearchQuery,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search previews',
                  hintStyle: theme.regularTextStyleWithColor(Colors.black54),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: densePadding,
                    horizontal: denseSpacing,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: defaultIconSize,
                    color: Colors.black54,
                  ),
                  suffixIcon: _SearchClearButton(controller: widget.controller),
                ),
              ),
            ),
          ),
          Container(height: 16, width: 1, color: Colors.black26),
          _SearchFiltersMenuButton(searchFilters: _searchFilters),
        ],
      ),
    );
  }
}

class _SearchClearButton extends StatelessWidget {
  const _SearchClearButton({required this.controller});

  final WidgetPreviewScaffoldController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: controller.searchQueryListenable,
      builder: (context, query, _) {
        if (query.isEmpty) {
          return const SizedBox.shrink();
        }
        return IconButton(
          tooltip: 'Clear search',
          style: theme.iconButtonTheme.style,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.clear, size: defaultIconSize),
          color: Colors.black,
          onPressed: () => controller.updateSearchQuery(''),
        );
      },
    );
  }
}

class _SearchFiltersMenuButton extends StatelessWidget {
  const _SearchFiltersMenuButton({required this.searchFilters});

  final List<_SearchFilterConfig> searchFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(
        searchFilters
            .map<Listenable>((filter) => filter.listenable())
            .toList(growable: false),
      ),
      builder: (context, _) {
        final allFiltersEnabled = searchFilters.every(
          (filter) => filter.listenable().value,
        );
        return PopupMenuButton<_PreviewSearchFilter>(
          tooltip: 'Search fields',
          style: theme.iconButtonTheme.style,
          iconColor: allFiltersEnabled ? Colors.black : Colors.blue,
          iconSize: defaultIconSize,
          icon: const Icon(Icons.filter_list),
          onSelected: (_PreviewSearchFilter selected) {
            final didToggle = searchFilters
                .firstWhere((filter) => filter.filter == selected)
                .onToggle();
            if (!didToggle) {
              _showNoRemainingSearchFilterSnackBar(context);
            }
          },
          itemBuilder: (context) {
            return searchFilters
                .map(
                  (filter) => CheckedPopupMenuItem<_PreviewSearchFilter>(
                    value: filter.filter,
                    checked: filter.listenable().value,
                    child: Text(filter.label),
                  ),
                )
                .toList(growable: false);
          },
        );
      },
    );
  }

  void _showNoRemainingSearchFilterSnackBar(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('At least one search field must remain enabled.'),
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
