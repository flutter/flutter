// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

/// Runs [body] and wraps any format exceptions it produces.
///
/// [name] should describe the type of thing being parsed, and [value] should be
/// its actual value.
T wrapFormatException<T>(String name, String value, T Function() body) {
  try {
    return body();
  } on SourceSpanFormatException catch (error) {
    throw SourceSpanFormatException(
        'Invalid $name: ${error.message}', error.span, error.source);
  } on FormatException catch (error) {
    throw FormatException(
        'Invalid $name "$value": ${error.message}', error.source, error.offset);
  }
}
