// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:widget_preview_scaffold/src/dtd/dtd_services.dart';
import 'package:widget_preview_scaffold/src/dtd/editor_service.dart';
import 'package:widget_preview_scaffold/src/widget_preview_rendering.dart';

/// A custom [WidgetInspectorService] responsible for routing navigation events
/// to the IDE.
///
/// IMPORTANT NOTE: this **must** be called before WidgetsFlutterBinding.ensureInitialized()
/// is called, otherwise the inspector service extensions will be registered against
/// the default WidgetInspectorService, causing overrides to not be invoked.
class WidgetPreviewScaffoldInspectorService with WidgetInspectorService {
  WidgetPreviewScaffoldInspectorService({required this.dtdServices}) {
    WidgetInspectorService.instance = this;
  }

  /// The DTD services instance used to communicate with the tool.
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
