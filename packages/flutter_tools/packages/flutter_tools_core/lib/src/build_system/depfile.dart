// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const _listEquality = ListEquality<String>();

/// Unresolved [inputs] and [outputs] file paths parsed from or formatted to a
/// `.d` dependency file.
@immutable
final class Depfile {
  const Depfile({this.inputs = const <String>[], this.outputs = const <String>[]});

  /// Parses `.d` depfile [contents] (`<outputs>: <inputs>`) into a [Depfile].
  ///
  /// Throws a [FormatException] if [contents] does not contain a single `": "`
  /// separator between outputs and inputs.
  factory Depfile.parse(String contents) {
    final List<String> colonSeparated = contents.split(': ');
    if (colonSeparated.length != 2) {
      throw const FormatException('Invalid depfile syntax: expected "<outputs>: <inputs>".');
    }
    final List<String> outputs = _processList(colonSeparated[0].trim());
    final List<String> inputs = _processList(colonSeparated[1].trim());
    return Depfile(inputs: inputs, outputs: outputs);
  }

  // Matches unescaped spaces separating file paths in a depfile rule.
  static final _separatorExpr = RegExp(r'([^\\]) ');

  // Matches backslash-escaped characters (such as `\ ` or `\\`) in a file path.
  static final _escapeExpr = RegExp(r'\\(.)');

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
  String toString() => 'Depfile(inputs: $inputs, outputs: $outputs)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Depfile &&
            _listEquality.equals(other.inputs, inputs) &&
            _listEquality.equals(other.outputs, outputs));
  }

  @override
  int get hashCode => Object.hash(_listEquality.hash(inputs), _listEquality.hash(outputs));
}
