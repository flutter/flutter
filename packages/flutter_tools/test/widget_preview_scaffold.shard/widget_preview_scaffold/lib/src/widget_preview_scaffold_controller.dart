// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'dtd/dtd_services.dart';
import 'widget_preview.dart';

/// Define the Enum for Layout Types
enum LayoutType { gridView, listView }

typedef PreviewsCallback = List<WidgetPreview> Function();

/// Controller used to process events and determine which previews should be
/// displayed and how they should be displayed in the [WidgetPreviewScaffold].
class WidgetPreviewScaffoldController {
  WidgetPreviewScaffoldController({
    required PreviewsCallback previews,
    @visibleForTesting WidgetPreviewScaffoldDtdServices? dtdServicesOverride,
  }) : _previews = previews,
       dtdServices = dtdServicesOverride ?? WidgetPreviewScaffoldDtdServices();

  /// Initializes the controller by establishing a connection to DTD and
  /// listening for events.
  Future<void> initialize() async {
    await dtdServices.connect();
    _registerListeners();
  }

  /// Cleanup internal controller state.
  Future<void> dispose() async {
    await dtdServices.dispose();

    _layoutType.dispose();
    _filterBySelectedFile.dispose();
  }

  /// Update state after the project has been reassembled due to a hot reload.
  void onHotReload() {
    _handleSelectedSourceFileChanged();
  }

  /// The active DTD connection used to communicate with other developer tooling.
  final WidgetPreviewScaffoldDtdServices dtdServices;

  final List<WidgetPreview> Function() _previews;

  /// Specifies how the previews should be laid out.
  ValueListenable<LayoutType> get layoutTypeListenable => _layoutType;
  final _layoutType = ValueNotifier<LayoutType>(LayoutType.gridView);

  LayoutType get layoutType => _layoutType.value;
  set layoutType(LayoutType type) => _layoutType.value = type;

  /// Specifies if only previews from the currently selected source file should be rendered.
  ValueListenable<bool> get filterBySelectedFileListenable =>
      _filterBySelectedFile;
  final _filterBySelectedFile = ValueNotifier<bool>(true);

  /// Enable or disable filtering by selected source file.
  void toggleFilterBySelectedFile() {
    _filterBySelectedFile.value = !_filterBySelectedFile.value;
  }

  /// The current set of previews to be displayed.
  ValueListenable<Iterable<WidgetPreview>> get filteredPreviewSetListenable =>
      _filteredPreviewSet;
  final _filteredPreviewSet = ValueNotifier<List<WidgetPreview>>([]);

  void _registerListeners() {
    dtdServices.selectedSourceFile.addListener(
      _handleSelectedSourceFileChanged,
    );
    filterBySelectedFileListenable.addListener(() {
      if (filterBySelectedFileListenable.value) {
        dtdServices.selectedSourceFile.addListener(
          _handleSelectedSourceFileChanged,
        );
      } else {
        dtdServices.selectedSourceFile.removeListener(
          _handleSelectedSourceFileChanged,
        );
      }
      // Update the state if filtering has changed.
      _handleSelectedSourceFileChanged();
    });
    // Set the initial state.
    _handleSelectedSourceFileChanged();
  }

  void _handleSelectedSourceFileChanged() {
    final selectedSourceFile = dtdServices.selectedSourceFile.value;
    if (selectedSourceFile != null && _filterBySelectedFile.value) {
      _filteredPreviewSet.value = _previews()
          .where(
            (preview) => preview.scriptUri == selectedSourceFile.uriAsString,
          )
          .toList();
      return;
    }
    _filteredPreviewSet.value = _previews();
  }
}
