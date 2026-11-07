// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../build.dart';
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const _listEquality = ListEquality<String>();
final _lineContinuationRegex = RegExp(r'\\\r?\n');

/// Representation of a `.d` dependency file containing [inputs] and [outputs]
/// file paths for an [ExtensionAssembleTarget].
///
/// Extensions that declare [ExtensionAssembleTarget.depfiles] can use
/// [ExtensionDepfile.format] to write `.d` files into their build directory
/// and [ExtensionDepfile.parse] to read them back.
///
/// Relative paths written to a declared depfile are resolved relative to the
/// project root directory and rewritten in place with normalized paths by the
/// host after a successful build. Each declared depfile must be written on
/// every successful build.
@immutable
class ExtensionDepfile {
  const ExtensionDepfile({this.inputs = const <String>[], this.outputs = const <String>[]});

  /// Parses `.d` depfile [contents] (`<outputs>: <inputs>`) into an [ExtensionDepfile].
  ///
  /// Supports single-rule `<outputs>: <inputs>` files, including backslash-newline
  /// (`\`) line continuations.
  ///
  /// Throws a [FormatException] if [contents] does not contain a single `": "`
  /// separator between outputs and inputs.
  factory ExtensionDepfile.parse(String contents) {
    final String normalized = contents.replaceAll(_lineContinuationRegex, ' ');
    final List<String> colonSeparated = normalized.split(': ');
    if (colonSeparated.length != 2) {
      throw const FormatException('Invalid depfile syntax: expected "<outputs>: <inputs>".');
    }
    final List<String> outputs = _processList(colonSeparated[0].trim());
    final List<String> inputs = _processList(colonSeparated[1].trim());
    return ExtensionDepfile(inputs: inputs, outputs: outputs);
  }

  static final RegExp _separatorExpr = RegExp(r'([^\\]) ');
  static final RegExp _escapeExpr = RegExp(r'\\(.)');

  /// The input file paths recorded in this depfile.
  final List<String> inputs;

  /// The output file paths recorded in this depfile.
  final List<String> outputs;

  /// Formats this depfile into standard `.d` depfile text (`<outputs>: <inputs>`).
  ///
  /// Spaces in file paths are escaped as `\ `. When [windows] is `true`,
  /// backslashes are escaped as `\\`; otherwise backslashes are normalized to `/`.
  String format({bool windows = false}) {
    final buffer = StringBuffer();
    _writePathsToBuffer(outputs, buffer, windows: windows);
    buffer.write(': ');
    _writePathsToBuffer(inputs, buffer, windows: windows);
    return buffer.toString();
  }

  static void _writePathsToBuffer(
    List<String> paths,
    StringBuffer buffer, {
    required bool windows,
  }) {
    for (var path in paths) {
      if (windows) {
        path = path.replaceAll(r'\', r'\\');
      } else {
        path = path.replaceAll(r'\', r'/');
      }
      path = path.replaceAll(r' ', r'\ ');
      buffer.write(' $path');
    }
  }

  static List<String> _processList(String rawText) {
    return rawText
        .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
        .split('\n')
        .map<String>(
          (String path) =>
              path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)!).trim(),
        )
        .where((String path) => path.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  String toString() => 'ExtensionDepfile(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionDepfile &&
            _listEquality.equals(other.inputs, inputs) &&
            _listEquality.equals(other.outputs, outputs));
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(inputs), Object.hashAll(outputs));
}
