// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.src.source_code;

/// Describes a chunk of source code that is to be formatted or has been
/// formatted.
class SourceCode {
  /// The [uri] where the source code is from.
  ///
  /// Used in error messages if the code cannot be parsed.
  final String? uri;

  /// The Dart source code text.
  final String text;

  /// Whether the source is a compilation unit or a bare statement.
  final bool isCompilationUnit;

  /// The offset in [text] where the selection begins, or `null` if there is
  /// no selection.
  final int? selectionStart;

  /// The number of selected characters or `null` if there is no selection.
  final int? selectionLength;

  /// Gets the source code before the beginning of the selection.
  ///
  /// If there is no selection, returns [text].
  String get textBeforeSelection {
    if (selectionStart == null) return text;
    return text.substring(0, selectionStart);
  }

  /// Gets the selected source code, if any.
  ///
  /// If there is no selection, returns an empty string.
  String get selectedText {
    if (selectionStart == null) return '';
    return text.substring(selectionStart!, selectionStart! + selectionLength!);
  }

  /// Gets the source code following the selection.
  ///
  /// If there is no selection, returns an empty string.
  String get textAfterSelection {
    if (selectionStart == null) return '';
    return text.substring(selectionStart! + selectionLength!);
  }

  SourceCode(this.text,
      {this.uri,
      this.isCompilationUnit = true,
      this.selectionStart,
      this.selectionLength}) {
    // Must either provide both selection bounds or neither.
    if ((selectionStart == null) != (selectionLength == null)) {
      throw ArgumentError(
          'Is selectionStart is provided, selectionLength must be too.');
    }

    if (selectionStart != null) {
      if (selectionStart! < 0) {
        throw ArgumentError('selectionStart must be non-negative.');
      }

      if (selectionStart! > text.length) {
        throw ArgumentError('selectionStart must be within text.');
      }
    }

    if (selectionLength != null) {
      if (selectionLength! < 0) {
        throw ArgumentError('selectionLength must be non-negative.');
      }

      if (selectionStart! + selectionLength! > text.length) {
        throw ArgumentError('selectionLength must end within text.');
      }
    }
  }
}
