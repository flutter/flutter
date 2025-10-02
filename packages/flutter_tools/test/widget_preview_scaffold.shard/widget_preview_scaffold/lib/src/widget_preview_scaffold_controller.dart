// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
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
  }) : _previews = previews,
       dtdServices = dtdServicesOverride ?? WidgetPreviewScaffoldDtdServices() {
    // Overrides the default WidgetInspectorService instance to handle selection
    // events.
    _WidgetPreviewScaffoldInspectorService(dtdServices: dtdServices);
  }

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
    _filterBySelectedFile.value = await dtdServices.getFlag(
      kFilterBySelectedFilePreference,
      defaultValue: true,
    );
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

  /// Set to true when the Editor service is available over DTD.
  ValueListenable<bool> get editorServiceAvailable =>
      dtdServices.editorServiceAvailable;

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
    // Set the initial state.
    _updateFilteredPreviewSet();
  }

  void _updateFilteredPreviewSet({
    bool editorServiceAvailabilityUpdated = false,
  }) {
    final previews = _previews();
    final previewGroups = <String, WidgetPreviewGroup>{};
    for (final preview in previews) {
      final group = preview.previewData.group;
      previewGroups
          .putIfAbsent(
            group,
            () => WidgetPreviewGroup(name: group, previews: []),
          )
          .previews
          .add(preview);
    }

    // When we set the initial preview set, we always display all previews,
    // regardless of selection mode, unless we know the Editor DTD service is available.
    if (!editorServiceAvailable.value || !_filterBySelectedFile.value) {
      _filteredPreviewSet.value = previewGroups.values;
      return;
    }

    final selectedSourceFile = dtdServices.selectedSourceFile.value;
    // If the Editor service has only just become available and we're filtering
    // by selected file, we need to explicitly set the filtered preview set as
    // empty, otherwise `selectedSourceFile` will interpreted as a non-source
    // file being selected in the editor.
    if (editorServiceAvailabilityUpdated &&
        _filterBySelectedFile.value &&
        selectedSourceFile == null) {
      _filteredPreviewSet.value = [];
      return;
    }
    // If filtering by selected file, we don't update the filtered preview set
    // if the currently selected file is null. This can happen when a non-source
    // window is selected (e.g., the widget previewer itself in VSCode), so we
    // ignore these updates.
    if (selectedSourceFile != null) {
      // Convert to a file path for comparing to avoid issues with optional encoding in URIs.
      // See https://github.com/flutter/flutter/issues/175524.
      final selectedSourcePath = context.fromUri(
        selectedSourceFile.uriAsString,
      );
      _filteredPreviewSet.value = previewGroups.values
          .map(
            (group) => WidgetPreviewGroup(
              name: group.name,
              previews: group.previews
                  .where(
                    (preview) => context.equals(
                      // TODO(bkonyi): we can probably save some cycles by caching the file path
                      // rather than computing it on each filter.
                      context.fromUri(preview.scriptUri),
                      selectedSourcePath,
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

/// A custom [WidgetInspectorService] responsible for routing navigation events
/// to the IDE.
class _WidgetPreviewScaffoldInspectorService with WidgetInspectorService {
  _WidgetPreviewScaffoldInspectorService({required this.dtdServices}) {
    WidgetInspectorService.instance = this;
  }

  final WidgetPreviewScaffoldDtdServices dtdServices;

  // Keys used to specify the creation location of a widget when serializing a
  // DiagnosticsNode to JSON. This location is used by the widget inspector
  // to jump to the creation location of a selected widget.
  static const kFile = 'fileUri';
  static const kLine = 'line';
  static const kColumn = 'column';

  CodeLocation? _nextNavigationLocation;

  @protected
  @override
  bool setSelection(Object? object, [String? groupName]) {
    // The next navigation event sent to `postEvent` will be for this selection.
    // Save the location of preview annotation applications so we can override
    // the navigation target in `postEvent`.
    if (object is PreviewWidgetElement) {
      final previewData = (object.widget as PreviewWidget).preview;
      _nextNavigationLocation = CodeLocation(
        uri: previewData.scriptUri,
        line: previewData.line,
        column: previewData.column,
      );
    }
    final result = super.setSelection(object, groupName);
    _nextNavigationLocation = null;
    return result;
  }

  @override
  void postEvent(
    String eventKind,
    Map<Object, Object?> eventData, {
    String stream = 'Extension',
  }) {
    // It's unlikely that the widget previewer will be connected to directly by
    // an IDE via the VM service, so we forward navigation events via the
    // Editor DTD service.
    if (eventKind == 'navigate') {
      CodeLocation? location = _nextNavigationLocation;
      if (eventData case {
        kFile: final String file,
        kLine: final int line,
        kColumn: final int column,
      } when location == null) {
        location = CodeLocation(uri: file, line: line, column: column);
      } else if (location != null) {
        // If a [PreviewWidgetElement] was selected, we're not navigating to the
        // creation location of the widget. Override the location details in the
        // event data, just in case an IDE is attached and listening for
        // navigation events through the VM service.
        // TODO(bkonyi): determine if this is necessary
        eventData.addAll(<String, Object>{
          kFile: location.uri,
          kLine: location.line!,
          kColumn: location.column!,
        });
      }
      if (location != null) {
        dtdServices.navigateToCode(location);
      }
    }
    super.postEvent(eventKind, eventData, stream: stream);
  }
}
