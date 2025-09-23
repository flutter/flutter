// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'dtd/dtd_services.dart';
import 'widget_preview.dart';

/// Define the Enum for Layout Types
enum LayoutType { gridView, listView }

typedef WidgetPreviewGroups = Iterable<WidgetPreviewGroup>;
typedef PreviewsCallback = WidgetPreviewGroups Function();

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
    context = path.Context(
      style: dtdServices.isWindows
          ? path.Style.windows
          : path.Style.posix,
    );
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
    _updateFilteredPreviewSet();
  }

  /// The active DTD connection used to communicate with other developer tooling.
  final WidgetPreviewScaffoldDtdServices dtdServices;

  final PreviewsCallback _previews;

  late final path.Context context;

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
  ValueListenable<WidgetPreviewGroups> get filteredPreviewSetListenable =>
      _filteredPreviewSet;
  final _filteredPreviewSet = ValueNotifier<WidgetPreviewGroups>([]);

  void _registerListeners() {
    dtdServices.selectedSourceFile.addListener(_updateFilteredPreviewSet);
    filterBySelectedFileListenable.addListener(_updateFilteredPreviewSet);
    // Set the initial state.
    _updateFilteredPreviewSet(initial: true);
  }

  void _updateFilteredPreviewSet({bool initial = false}) {
    // When we set the initial preview set, we always display all previews,
    // regardless of selection mode as we're unable to query the currently
    // selected file.
    //
    // This special case can be removed when https://github.com/dart-lang/sdk/issues/61538
    // is resolved.
    // TODO(bkonyi): remove special case
    if (!_filterBySelectedFile.value || initial) {
      _filteredPreviewSet.value = _previews();
      return;
    }
    // If filtering by selected file, we don't update the filtered preview set
    // if the currently selected file is null. This can happen when a non-source
    // window is selected (e.g., the widget previewer itself in VSCode), so we
    // ignore these updates.
    final selectedSourceFile = dtdServices.selectedSourceFile.value;
    if (selectedSourceFile != null) {
      final isWindows = dtdServices.isWindows;
      _filteredPreviewSet.value = _previews()
          .map(
            (group) => WidgetPreviewGroup(
              name: group.name,
              previews: group.previews
                  .where(
                    (preview) => context.equals(
                      // TODO(bkonyi): we can probably save some cycles by caching the file URI
                      // rather than computing it on each filter.
                      Uri.parse(
                        preview.scriptUri,
                      ).toFilePath(windows: isWindows),
                      selectedSourceFile.uriAsString,
                    ),
                  )
                  .toList(),
            ),
          )
          .where((group) => group.hasPreviews)
          .toList();
    }
  }
}
