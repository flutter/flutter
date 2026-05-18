// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';
import 'dtd/dtd_services.dart';
import 'widget_preview.dart';

/// Define the Enum for Layout Types
enum LayoutType { gridView, listView }

typedef WidgetPreviews = Iterable<WidgetPreview>;
typedef WidgetPreviewGroups = Iterable<WidgetPreviewGroup>;
typedef PreviewsCallback = WidgetPreviews Function();

/// Controller used to process events and determine which previews should be
/// displayed and how they should be displayed in the [WidgetPreviewScaffold].
class WidgetPreviewScaffoldController {
  WidgetPreviewScaffoldController({
    required PreviewsCallback previews,
    @visibleForTesting WidgetPreviewScaffoldDtdServices? dtdServicesOverride,
    // ignore: prefer_initializing_formals
  }) : _previews = previews,
       dtdServices = dtdServicesOverride ?? WidgetPreviewScaffoldDtdServices();

  @visibleForTesting
  static const kFilterBySelectedFilePreference = 'filterBySelectedFile';

  /// Initializes the controller by establishing a connection to DTD and
  /// listening for events.
  Future<void> initialize() async {
    await dtdServices.connect();
    context = path.Context(
      style: dtdServices.isWindows ? path.Style.windows : path.Style.posix,
    );
    _registerListeners();
    await Future.wait<void>([
      dtdServices
          .getFlag(kFilterBySelectedFilePreference, defaultValue: true)
          .then((value) => _filterBySelectedFile.value = value),
      dtdServices.getDevToolsUri().then((uri) {
        devToolsUri = uri;
      }),
    ]);
  }

  /// Cleanup internal controller state.
  Future<void> dispose() async {
    await dtdServices.dispose();

    _layoutType.dispose();
    _filterBySelectedFile.dispose();
    _searchQuery.dispose();
    for (final searchField in _searchFields) {
      searchField.dispose();
    }
  }

  /// Update state after the project has been reassembled due to a hot reload.
  void onHotReload() => _updateFilteredPreviewSet();

  /// The active DTD connection used to communicate with other developer tooling.
  final WidgetPreviewScaffoldDtdServices dtdServices;

  final PreviewsCallback _previews;

  late final path.Context context;

  /// Specifies how the previews should be laid out.
  ValueListenable<LayoutType> get layoutTypeListenable => _layoutType;
  final _layoutType = ValueNotifier<LayoutType>(LayoutType.gridView);

  LayoutType get layoutType => _layoutType.value;
  set layoutType(LayoutType type) => _layoutType.value = type;

  /// Set to true when the Editor service is available over DTD.
  ValueListenable<bool> get editorServiceAvailable =>
      dtdServices.editorServiceAvailable;

  /// The DevTools instance that's used to display the widget inspector within the previewer.
  late final Uri devToolsUri;

  /// Specifies if only previews from the currently selected source file should be rendered.
  ValueListenable<bool> get filterBySelectedFileListenable =>
      _filterBySelectedFile;
  final _filterBySelectedFile = ValueNotifier<bool>(true);

  /// Enable or disable filtering by selected source file.
  Future<void> toggleFilterBySelectedFile() async {
    final updated = !_filterBySelectedFile.value;
    await dtdServices.setPreference(kFilterBySelectedFilePreference, updated);
    _filterBySelectedFile.value = updated;
  }

  /// The current case-insensitive query used to search previews.
  ValueListenable<String> get searchQueryListenable => _searchQuery;
  final _searchQuery = ValueNotifier<String>('');

  /// Update the search query used to filter previews.
  void updateSearchQuery(String query) => _searchQuery.value = query;

  /// Whether to include group names when applying search filters.
  ValueListenable<bool> get searchByGroupNameListenable => _searchByGroupName;
  final _searchByGroupName = ValueNotifier<bool>(true);

  /// Whether to include preview names when applying search filters.
  ValueListenable<bool> get searchByPreviewNameListenable =>
      _searchByPreviewName;
  final _searchByPreviewName = ValueNotifier<bool>(true);

  /// Whether to include script URIs when applying search filters.
  ValueListenable<bool> get searchByContainingScriptListenable =>
      _searchByContainingScript;
  final _searchByContainingScript = ValueNotifier<bool>(true);

  /// Whether to include package names when applying search filters.
  ValueListenable<bool> get searchByContainingPackageListenable =>
      _searchByContainingPackage;
  final _searchByContainingPackage = ValueNotifier<bool>(true);

  /// Toggle inclusion of group names in search filters.
  ///
  /// Returns true if the filter state was changed.
  bool toggleSearchByGroupName() => _toggleSearchField(_searchByGroupName);

  /// Toggle inclusion of preview names in search filters.
  ///
  /// Returns true if the filter state was changed.
  bool toggleSearchByPreviewName() => _toggleSearchField(_searchByPreviewName);

  /// Toggle inclusion of script URIs in search filters.
  ///
  /// Returns true if the filter state was changed.
  bool toggleSearchByContainingScript() =>
      _toggleSearchField(_searchByContainingScript);

  /// Toggle inclusion of package names in search filters.
  ///
  /// Returns true if the filter state was changed.
  bool toggleSearchByContainingPackage() =>
      _toggleSearchField(_searchByContainingPackage);

  /// Specifies if the DevTools Widget Inspector should be visible.
  ValueListenable<bool> get widgetInspectorVisible => _widgetInspectorVisible;
  final _widgetInspectorVisible = ValueNotifier<bool>(false);

  /// Enable or disable the DevTools Widget Inspector.
  void toggleWidgetInspectorVisible() =>
      _widgetInspectorVisible.value = !_widgetInspectorVisible.value;

  /// The current set of previews to be displayed.
  ValueListenable<WidgetPreviewGroups> get filteredPreviewSetListenable =>
      _filteredPreviewSet;
  final _filteredPreviewSet = ValueNotifier<WidgetPreviewGroups>([]);

  void _registerListeners() {
    dtdServices.selectedSourceFile.addListener(_updateFilteredPreviewSet);
    editorServiceAvailable.addListener(
      () => _updateFilteredPreviewSet(editorServiceAvailabilityUpdated: true),
    );
    filterBySelectedFileListenable.addListener(_updateFilteredPreviewSet);
    searchQueryListenable.addListener(_updateFilteredPreviewSet);
    for (final searchField in _searchFields) {
      searchField.addListener(_updateFilteredPreviewSet);
    }
    // Set the initial state.
    _updateFilteredPreviewSet();
  }

  late final _searchFields = <ValueNotifier<bool>>[
    _searchByGroupName,
    _searchByPreviewName,
    _searchByContainingScript,
    _searchByContainingPackage,
  ];

  String _getSearchableValue(
    WidgetPreview preview,
    ValueNotifier<bool> searchField,
  ) {
    if (identical(searchField, _searchByGroupName)) {
      return preview.previewData.group.toLowerCase();
    }
    if (identical(searchField, _searchByPreviewName)) {
      return (preview.name ?? '').toLowerCase();
    }
    if (identical(searchField, _searchByContainingScript)) {
      return preview.scriptUri.toLowerCase();
    }
    if (identical(searchField, _searchByContainingPackage)) {
      return preview.packageName.toLowerCase();
    }

    throw StateError('Unknown search field');
  }

  bool _toggleSearchField(ValueNotifier<bool> searchField) {
    if (searchField.value && !_hasAnotherActiveSearchField(searchField)) {
      return false;
    }
    searchField.value = !searchField.value;
    return true;
  }

  bool _hasAnotherActiveSearchField(ValueNotifier<bool> activeSearchField) =>
      _searchFields.any(
        (field) => !identical(field, activeSearchField) && field.value,
      );

  bool _matchesSearchFilter(WidgetPreview preview, String searchQuery) {
    if (searchQuery.isEmpty) {
      return true;
    }

    for (final searchField in _searchFields) {
      if (!searchField.value) {
        continue;
      }
      if (_getSearchableValue(preview, searchField).contains(searchQuery)) {
        return true;
      }
    }

    return false;
  }

  void _updateFilteredPreviewSet({
    bool editorServiceAvailabilityUpdated = false,
  }) {
    final previews = _previews();

    final normalizedSearchQuery = _searchQuery.value.trim().toLowerCase();
    String? selectedSourcePath;

    if (editorServiceAvailable.value && _filterBySelectedFile.value) {
      final selectedSourceFile = dtdServices.selectedSourceFile.value;
      // If the Editor service has only just become available and we're filtering
      // by selected file, we need to explicitly set the filtered preview set as
      // empty, otherwise `selectedSourceFile` will interpreted as a non-source
      // file being selected in the editor.
      if (editorServiceAvailabilityUpdated && selectedSourceFile == null) {
        _filteredPreviewSet.value = [];
        return;
      }
      // If filtering by selected file, we don't update the filtered preview set
      // if the currently selected file is null. This can happen when a non-source
      // window is selected (e.g., the widget previewer itself in VSCode), so we
      // ignore these updates.
      if (selectedSourceFile == null) {
        return;
      }
      // Convert to a file path for comparing to avoid issues with optional encoding in URIs.
      // See https://github.com/flutter/flutter/issues/175524.
      selectedSourcePath = context.fromUri(selectedSourceFile.uriAsString);
    }

    final previewGroups = <String, WidgetPreviewGroup>{};
    for (final preview in previews) {
      if (selectedSourcePath != null &&
          !context.equals(
            // TODO(bkonyi): we can probably save some cycles by caching the file path
            // rather than computing it on each filter.
            context.fromUri(preview.scriptUri),
            selectedSourcePath,
          )) {
        continue;
      }
      if (!_matchesSearchFilter(preview, normalizedSearchQuery)) {
        continue;
      }

      final group = preview.previewData.group;
      previewGroups
          .putIfAbsent(
            group,
            () => WidgetPreviewGroup(name: group, previews: []),
          )
          .previews
          .add(preview);
    }
    _filteredPreviewSet.value = previewGroups.values.toList();
  }
}
