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
       _dtdServices = dtdServicesOverride ?? WidgetPreviewScaffoldDtdServices();

  /// Initializes the controller by establishing a connection to DTD and
  /// listening for events.
  Future<void> initialize() async {
    await dtdServices.connect();
    _registerListeners();
  }

  /// Cleanup internal controller state.
  Future<void> dispose() async {
    _cleanupListeners();
    await dtdServices.dispose();
  }

  /// Update state after the project has been reassembled due to a hot reload.
  void onHotReload() {
    _handleSelectedSourceFileChanged();
  }

  /// The active DTD connection used to communicate with other developer tooling.
  WidgetPreviewScaffoldDtdServices get dtdServices => _dtdServices;
  final WidgetPreviewScaffoldDtdServices _dtdServices;

  final List<WidgetPreview> Function() _previews;

  /// Specifies how the previews should be laid out.
  ValueListenable<LayoutType> get layoutTypeListenable => _layoutType;
  final _layoutType = ValueNotifier<LayoutType>(LayoutType.gridView);

  LayoutType get layoutType => _layoutType.value;
  set layoutType(LayoutType type) => _layoutType.value = type;

  ValueListenable<bool> get filterBySelectedFileListenable =>
      _filterBySelectedFile;
  final _filterBySelectedFile = ValueNotifier<bool>(true);

  void toggleFilterBySelectedFile() {
    _filterBySelectedFile.value = !_filterBySelectedFile.value;
    _handleSelectedSourceFileChanged();
  }

  /// The current set of previews to be displayed.
  ValueListenable<List<WidgetPreview>> get filteredPreviewSetListenable =>
      _filteredPreviewSet;
  final _filteredPreviewSet = ValueNotifier<List<WidgetPreview>>([]);

  void _registerListeners() {
    dtdServices.selectedSourceFile.addListener(
      _handleSelectedSourceFileChanged,
    );
    // Set the initial state.
    _handleSelectedSourceFileChanged();
  }

  void _cleanupListeners() {
    dtdServices.selectedSourceFile.removeListener(
      _handleSelectedSourceFileChanged,
    );
  }

  void _handleSelectedSourceFileChanged() {
    final selectedSourceFile = dtdServices.selectedSourceFile.value;
    if (selectedSourceFile == null || !_filterBySelectedFile.value) {
      _filteredPreviewSet.value = _previews();
      return;
    }
    _filteredPreviewSet.value = _previews()
        .where((preview) => preview.scriptUri == selectedSourceFile.uriAsString)
        .toList();
  }
}
