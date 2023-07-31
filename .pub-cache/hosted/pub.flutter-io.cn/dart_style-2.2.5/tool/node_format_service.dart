// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library node_format_service;

import 'dart:math' as math;

import 'package:dart_style/dart_style.dart';
import 'package:js/js.dart';

@JS()
@anonymous
class FormatResult {
  external factory FormatResult({String code, String error});
  external String get code;
  external String get error;
}

@JS('exports.formatCode')
external set formatCode(Function formatter);

void main() {
  formatCode = allowInterop((String source) {
    var formatter = DartFormatter();

    FormatterException exception;
    try {
      return FormatResult(code: DartFormatter().format(source));
    } on FormatterException catch (err) {
      // Couldn't parse it as a compilation unit.
      exception = err;
    }

    // Maybe it's a statement.
    try {
      return FormatResult(code: formatter.formatStatement(source));
    } on FormatterException catch (err) {
      // There is an error when parsing it both as a compilation unit and a
      // statement, so we aren't sure which one the user intended. As a
      // heuristic, we'll choose that whichever one we managed to parse more of
      // before hitting an error is probably the right one.
      if (_firstOffset(exception) < _firstOffset(err)) {
        exception = err;
      }
    }

    // If we get here, it couldn't be parsed at all.
    return FormatResult(code: source, error: '$exception');
  });
}

/// Returns the offset of the error nearest the beginning of the file out of
/// all the errors in [exception].
int _firstOffset(FormatterException exception) =>
    exception.errors.map((error) => error.offset).reduce(math.min);
