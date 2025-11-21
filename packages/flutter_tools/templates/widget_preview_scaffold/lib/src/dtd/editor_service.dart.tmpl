// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dtd/dtd.dart';
import 'package:flutter/foundation.dart';
import 'package:widget_preview_scaffold/src/dtd/dtd_services.dart';
import 'package:widget_preview_scaffold/src/dtd/utils.dart';

/// Provides support for interacting with the Editor DTD service registered by IDE plugins.
mixin DtdEditorService {
  DartToolingDaemon get dtd;

  /// The name of the Editor service.
  static const String kEditorService = 'Editor';

  /// The name of the Editor's getActiveLocation method.
  static const String kGetActiveLocation = 'getActiveLocation';

  /// The name of the Editor's navigateToCode method.
  static const String kNavigateToCode = 'navigateToCode';

  /// The name of the DTD Service stream.
  static const String kServiceStream = 'Service';

  /// The kind of the event sent over the [kServiceStream] stream when a new
  /// service method is registered.
  static const kServiceRegistered = 'ServiceRegistered';

  /// The kind of the event sent over the [kServiceStream] stream when a
  /// service method is unregistered.
  static const kServiceUnregistered = 'ServiceUnregistered';

  /// Whether or not the Editor service is available.
  ValueListenable<bool> get editorServiceAvailable => _editorServiceAvailable;
  static final _editorServiceAvailable = ValueNotifier<bool>(false);

  /// The currently selected source file in the IDE.
  ValueListenable<TextDocument?> get selectedSourceFile => _selectedSourceFile;
  static final _selectedSourceFile = ValueNotifier<TextDocument?>(null);

  /// The current theming set in the IDE.
  ValueListenable<EditorTheme?> get editorTheme => _editorTheme;
  static final _editorTheme = ValueNotifier<EditorTheme?>(null);

  /// Start listening for events on the Editor stream.
  Future<void> initializeEditorService(
    WidgetPreviewScaffoldDtdServices dtdServices,
  ) async {
    final editorKindMap = EditorEventKind.values.asNameMap();
    dtd.onEvent(kEditorService).listen((data) {
      final kind = editorKindMap[data.kind];
      switch (kind) {
        // Unknown event. Use null here so we get exhaustiveness checking for
        // the rest.
        case null:
          break;
        case EditorEventKind.themeChanged:
          _editorTheme.value = ThemeChangedEvent.fromJson(data.data).theme;
        case EditorEventKind.activeLocationChanged:
          _selectedSourceFile.value = ActiveLocationChangedEvent.fromJson(
            data.data,
          ).textDocument;
      }
    });
    await dtd.safeStreamListen(kEditorService);

    dtd.onEvent(kServiceStream).listen((data) async {
      switch (data) {
        case DTDEvent(
          kind: kServiceRegistered,
          data: {
            DtdParameters.service: kEditorService,
            DtdParameters.method: kGetActiveLocation,
          },
        ):
          // Manually retrieve the currently selected source file.
          unawaited(_updateSelectedSourceFile());
          _editorServiceAvailable.value = true;
        case DTDEvent(
          kind: kServiceRegistered,
          data: {DtdParameters.service: kEditorService},
        ):
          _editorServiceAvailable.value = true;
        case DTDEvent(
          kind: kServiceUnregistered,
          data: {DtdParameters.service: kEditorService},
        ):
          _editorServiceAvailable.value = false;
      }
    });
    await dtd.safeStreamListen(kServiceStream);
  }

  @mustCallSuper
  void dispose() {
    _selectedSourceFile.dispose();
    _editorServiceAvailable.dispose();
    _editorTheme.dispose();
  }

  Future<void> _updateSelectedSourceFile() async {
    final response = await dtd.safeCall(kEditorService, kGetActiveLocation);
    if (response != null) {
      _selectedSourceFile.value = ActiveLocation.fromJson(
        response.result,
      ).textDocument;
    }
  }

  /// Tells the editor to navigate to a given code [location].
  ///
  /// Only locations with `file://` URIs are valid.
  Future<void> navigateToCode(CodeLocation location) async {
    await dtd.safeCall(
      kEditorService,
      kNavigateToCode,
      params: location.toJson(),
    );
  }
}

// TODO(bkonyi): much of the following code is copied from the DevTools codebase. We should publish
// a package containing these DTD services. See https://github.com/flutter/devtools/issues/9306.

/// Known kinds of events that may come from the editor.
///
/// This list is not guaranteed to match actual events from any given editor as
/// the editor might not implement all functionality or may be a future version
/// running against an older version of this code/DevTools.
enum EditorEventKind {
  /// The kind for a [ThemeChangedEvent].
  themeChanged,

  /// The kind for an [ActiveLocationChangedEvent] event.
  activeLocationChanged,
}

/// A base class for all known events that an editor can produce.
///
/// The set of subclasses is not guaranteed to match actual events from any
/// given editor as the editor might not implement all functionality or may be a
/// future version running against an older version of this code/DevTools.
sealed class EditorEvent {
  EditorEventKind get kind;
}

/// UI settings for an editor's theme.
class EditorTheme {
  EditorTheme({
    required this.isDarkMode,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.fontSize,
  });

  EditorTheme.fromJson(Map<String, Object?> map)
    : this(
        isDarkMode: map[Field.isDarkMode] as bool,
        backgroundColor: map[Field.backgroundColor] as String?,
        foregroundColor: map[Field.foregroundColor] as String?,
        fontSize: map[Field.fontSize] as int?,
      );

  final bool isDarkMode;
  final String? backgroundColor;
  final String? foregroundColor;
  final int? fontSize;

  Map<String, Object?> toJson() => {
    Field.isDarkMode: isDarkMode,
    Field.backgroundColor: backgroundColor,
    Field.foregroundColor: foregroundColor,
    Field.fontSize: fontSize,
  };
}

class ThemeChangedEvent extends EditorEvent {
  ThemeChangedEvent({required this.theme});

  ThemeChangedEvent.fromJson(Map<String, Object?> map)
    : this(
        theme: EditorTheme.fromJson(map[Field.theme] as Map<String, Object?>),
      );

  final EditorTheme theme;

  @override
  EditorEventKind get kind => EditorEventKind.themeChanged;

  Map<String, Object?> toJson() => {Field.theme: theme};
}

/// An event sent by an editor when the current cursor position/s change.
class ActiveLocationChangedEvent extends ActiveLocation implements EditorEvent {
  ActiveLocationChangedEvent({required ActiveLocation activeLocation})
    : super(
        selections: activeLocation.selections,
        textDocument: activeLocation.textDocument,
      );

  ActiveLocationChangedEvent.fromJson(Map<String, Object?> map)
    : this(activeLocation: ActiveLocation.fromJson(map));

  @override
  EditorEventKind get kind => EditorEventKind.activeLocationChanged;
}

class ActiveLocation {
  ActiveLocation({required this.selections, required this.textDocument});

  ActiveLocation.fromJson(Map<String, Object?> map)
    : this(
        textDocument: map.containsKey(Field.textDocument)
            ? TextDocument.fromJson(
                map[Field.textDocument] as Map<String, Object?>,
              )
            : null,
        selections: (map[Field.selections] as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(EditorSelection.fromJson)
            .toList(),
      );

  final List<EditorSelection> selections;
  final TextDocument? textDocument;

  Map<String, Object?> toJson() => {
    Field.selections: selections,
    Field.textDocument: textDocument,
  };
}

/// A reference to a text document in the editor.
///
/// The [uriAsString] is a file URI to the text document.
///
/// The [version] is an integer corresponding to LSP's
/// [VersionedTextDocumentIdentifier](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#versionedTextDocumentIdentifier)
class TextDocument {
  TextDocument({required this.uriAsString, required this.version});

  TextDocument.fromJson(Map<String, Object?> map)
    : this(
        uriAsString: map[Field.uri] as String,
        version: map[Field.version] as int?,
      );

  final String uriAsString;
  final int? version;

  Map<String, Object?> toJson() => {
    Field.uri: uriAsString,
    Field.version: version,
  };

  @override
  bool operator ==(Object other) {
    return other is TextDocument &&
        other.uriAsString == uriAsString &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(uriAsString, version);
}

/// The starting and ending cursor positions in the editor.
class EditorSelection {
  EditorSelection({required this.active, required this.anchor});

  EditorSelection.fromJson(Map<String, Object?> map)
    : this(
        active: CursorPosition.fromJson(
          map[Field.active] as Map<String, Object?>,
        ),
        anchor: CursorPosition.fromJson(
          map[Field.anchor] as Map<String, Object?>,
        ),
      );

  final CursorPosition active;
  final CursorPosition anchor;

  Map<String, Object?> toJson() => {
    Field.active: active.toJson(),
    Field.anchor: anchor.toJson(),
  };
}

/// A range in the editor expressed as (zero-based) start and end positions.
class EditorRange {
  EditorRange({required this.start, required this.end});

  EditorRange.fromJson(Map<String, Object?> map)
    : this(
        start: CursorPosition.fromJson(
          map[Field.start] as Map<String, Object?>,
        ),
        end: CursorPosition.fromJson(map[Field.end] as Map<String, Object?>),
      );

  /// The range's start position.
  final CursorPosition start;

  /// The range's end position.
  final CursorPosition end;

  Map<String, Object?> toJson() => {
    Field.start: start.toJson(),
    Field.end: end.toJson(),
  };
}

/// Representation of a single cursor position in the editor.
///
/// The cursor position is after the given [character] of the [line].
class CursorPosition {
  CursorPosition({required this.character, required this.line});

  CursorPosition.fromJson(Map<String, Object?> map)
    : this(
        character: map[Field.character] as int,
        line: map[Field.line] as int,
      );

  /// The zero-based character number of this position.
  final int character;

  /// The zero-based line number of this position.
  final int line;

  Map<String, Object?> toJson() => {
    Field.character: character,
    Field.line: line,
  };

  @override
  bool operator ==(Object other) {
    return other is CursorPosition &&
        other.character == character &&
        other.line == line;
  }

  @override
  int get hashCode => Object.hash(character, line);
}

/// Parameters for the `navigateToCode` request.
class CodeLocation {
  const CodeLocation({required this.uri, this.line, this.column});

  /// The URI of the location to navigate to. Only `file://` URIs are supported
  /// unless the service registration's `capabilities` indicate other schemes
  /// are supported.
  ///
  /// Editors should return error code 144 if a caller passes a URI with an
  /// unsupported scheme.
  final String uri;

  /// Optional 1-based line number to navigate to.
  final int? line;

  /// Optional 1-based column number to navigate to.
  final int? column;

  Map<String, Object?> toJson() => {
    Field.uri: uri,
    Field.line: ?line,
    Field.column: ?column,
  };
}

/// Constants for all fields used in JSON maps to avoid literal strings that
/// may have typos sprinkled throughout the API classes.
abstract class Field {
  static const active = 'active';
  static const anchor = 'anchor';
  static const backgroundColor = 'backgroundColor';
  static const character = 'character';
  static const column = 'column';
  static const end = 'end';
  static const fontSize = 'fontSize';
  static const foregroundColor = 'foregroundColor';
  static const isDarkMode = 'isDarkMode';
  static const line = 'line';
  static const selections = 'selections';
  static const start = 'start';
  static const textDocument = 'textDocument';
  static const theme = 'theme';
  static const uri = 'uri';
  static const version = 'version';
}
