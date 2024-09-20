// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

// Examples can assume:
// late StringSink sink;

abstract interface class StringSink {
  /// Writes the string representation of [object].
  ///
  /// Converts [object] to a string using `object.toString()`.
  ///
  /// Notice that calling `sink.write(null)` will will write the `"null"`
  /// string.
  void write(Object? object);

  /// Writes the elements of [objects] separated by [separator].
  ///
  /// Writes the string representation of every element of [objects],
  /// in iteration order, and writes [separator] between any two elements.
  ///
  /// ```dart
  /// sink.writeAll(["Hello", "World"], " Beautiful ");
  /// ```
  /// is equivalent to:
  /// ```dart
  /// sink
  ///   ..write("Hello");
  ///   ..write(" Beautiful ");
  ///   ..write("World");
  /// ```
  void writeAll(Iterable<dynamic> objects, [String separator = ""]);

  /// Writes the string representation of [object] followed by a newline.
  ///
  /// Equivalent to `buffer.write(object)` followed by `buffer.write("\n")`.
  ///
  /// Notice that calling `buffer.writeln(null)` will write the `"null"` string
  /// before the newline. Omitting the argument, or explicitly passing an empty
  /// string, is the recommended way to emit just the newline.
  void writeln([Object? object = ""]);

  /// Writes a string containing the character with code point [charCode].
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  void writeCharCode(int charCode);
}
