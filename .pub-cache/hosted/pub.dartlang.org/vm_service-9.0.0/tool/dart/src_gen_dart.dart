// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library to generate Dart source code.
library src_gen_dart;

import '../common/src_gen_common.dart';

/// A class used to generate Dart source code. This class facilitates writing out
/// dartdoc comments, automatically manages indent by counting curly braces, and
/// automatically wraps doc comments on 80 char column boundaries.
class DartGenerator {
  static const DEFAULT_COLUMN_BOUNDARY = 80;

  final int colBoundary;

  String _indent = "";
  final StringBuffer _buf = StringBuffer();

  bool _previousWasEol = false;

  DartGenerator({this.colBoundary = DEFAULT_COLUMN_BOUNDARY});

  /// Write out the given dartdoc text, wrapping lines as necessary to flow
  /// along the column boundary. If [preferSingle] is true, and the docs would
  /// fit on a single line, use `///` dartdoc style.
  void writeDocs(String? docs) {
    if (docs == null) return;

    docs = wrap(docs.trim(), colBoundary - _indent.length - 4);
    // docs = docs.replaceAll('*/', '/');
    // docs = docs.replaceAll('/*', r'/\*');

    docs.split('\n').forEach((line) => _writeln('/// ${line}'.trimRight()));

    // if (!docs.contains('\n') && preferSingle) {
    //   _writeln("/// ${docs}", true);
    // } else {
    //   _writeln("/**", true);
    //   _writeln(" * ${docs.replaceAll("\n", "\n * ")}", true);
    //   _writeln(" */", true);
    // }
  }

  /// Write out the given Dart statement and terminate it with an eol. If the
  /// statement will overflow the column boundary, attempt to wrap it at
  /// reasonable places.
  void writeStatement(String str) {
    if (_indent.length + str.length > colBoundary) {
      // Split the line on the first '('. Currently, we don't do anything
      // fancier then that. This takes the edge off the long lines.
      int index = str.indexOf('(');

      if (index == -1) {
        writeln(str);
      } else {
        writeln(str.substring(0, index + 1));
        writeln("    ${str.substring(index + 1)}");
      }
    } else {
      writeln(str);
    }
  }

  void writeln([String str = ""]) => _write("${str}\n");

  void write(String str) => _write(str);

  void out(String str) => _buf.write(str);

  void _writeln([String str = "", bool ignoreCurlies = false]) =>
      _write("${str}\n", ignoreCurlies);

  void _write(String str, [bool ignoreCurlies = false]) {
    for (final int rune in str.runes) {
      if (!ignoreCurlies) {
        if (rune == RUNE_LEFT_CURLY) {
          _indent = "${_indent}  ";
        } else if (rune == RUNE_RIGHT_CURLY && _indent.length >= 2) {
          _indent = _indent.substring(2);
        }
      }

      if (_previousWasEol && rune != RUNE_EOL) {
        _buf.write(_indent);
      }

      _buf.write(String.fromCharCode(rune));

      _previousWasEol = rune == RUNE_EOL;
    }
  }

  String toString() => _buf.toString();
}
