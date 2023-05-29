// Copyright (c) 2013, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:source_span/source_span.dart';

/// An error thrown by the YAML processor.
class YamlException extends SourceSpanFormatException {
  YamlException(String message, SourceSpan? span) : super(message, span);
}
