// Copyright (c) 2013, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:source_span/source_span.dart';

/// A pair of values.
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  @override
  String toString() => '($first, $last)';
}

/// Print a warning.
///
/// If [span] is passed, associates the warning with that span.
void warn(String message, [SourceSpan? span]) =>
    yamlWarningCallback(message, span);

/// A callback for emitting a warning.
///
/// [message] is the text of the warning. If [span] is passed, it's the portion
/// of the document that the warning is associated with and should be included
/// in the printed warning.
typedef YamlWarningCallback = void Function(String message, [SourceSpan? span]);

/// A callback for emitting a warning.
///
/// In a very few cases, the YAML spec indicates that an implementation should
/// emit a warning. To do so, it calls this callback. The default implementation
/// prints a message using [print].
// ignore: prefer_function_declarations_over_variables
YamlWarningCallback yamlWarningCallback = (message, [SourceSpan? span]) {
  // TODO(nweiz): Print to stderr with color when issue 6943 is fixed and
  // dart:io is available.
  if (span != null) message = span.message(message);
  print(message);
};
