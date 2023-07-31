// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'string_scanner.dart';

/// An exception thrown by a [StringScanner] that failed to parse a string.
class StringScannerException extends SourceSpanFormatException {
  @override
  String get source => super.source as String;

  /// The URL of the source file being parsed.
  ///
  /// This may be `null`, indicating that the source URL is unknown.
  Uri? get sourceUrl => span?.sourceUrl;

  StringScannerException(
      super.message, SourceSpan super.span, String super.source);
}
