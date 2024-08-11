// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A class for concatenating strings efficiently.
///
/// Allows for the incremental building of a string using `write*()` methods.
/// The strings are concatenated to a single string only when [toString] is
/// called.
///
/// Example:
/// ```dart
/// final buffer = StringBuffer('DART');
/// print(buffer.length); // 4
/// ```
/// To add the string representation of an object, as returned by
/// [Object.toString], to the buffer, use [write].
/// Is also used for adding a string directly.
/// ```
/// buffer.write(' is open source');
/// print(buffer.length); // 19
/// print(buffer); // DART is open source
///
/// const int dartYear = 2011;
/// buffer
///   ..write(' since ') // Writes a string.
///   ..write(dartYear); // Writes an int.
/// print(buffer); // DART is open source since 2011
/// print(buffer.length); // 30
/// ```
/// To add a newline after the object's string representation, use [writeln].
/// Calling [writeln] with no argument adds a single newline to the buffer.
/// ```
/// buffer.writeln(); // Contains "DART is open source since 2011\n".
/// buffer.writeln('-' * (buffer.length - 1)); // 30 '-'s and a newline.
/// print(buffer.length); // 62
/// ```
/// To write multiple objects to the buffer, use [writeAll].
/// ```
/// const separator = '-';
/// buffer.writeAll(['Dart', 'is', 'fun!'], separator);
/// print(buffer.length); // 74
/// print(buffer);
/// // DART is open source since 2011
/// // ------------------------------
/// // Dart-is-fun!
/// ```
/// To add the string representation of a Unicode code point, `charCode`,
/// to the buffer, use [writeCharCode].
/// ```
/// buffer.writeCharCode(0x0A); // LF (line feed)
/// buffer.writeCharCode(0x44); // 'D'
/// buffer.writeCharCode(0x61); // 'a'
/// buffer.writeCharCode(0x72); // 'r'
/// buffer.writeCharCode(0x74); // 't'
/// print(buffer.length); // 79
/// ```
/// To convert the content to a single string, use [toString].
/// ```
/// final text = buffer.toString();
/// print(text);
/// // DART is open source since 2011
/// // ------------------------------
/// // Dart-is-fun!
/// // Dart
/// ```
/// To clear the buffer, so that it can be reused, use [clear].
/// ```
/// buffer.clear();
/// print(buffer.isEmpty); // true
/// print(buffer.length); // 0
/// ```
class StringBuffer implements StringSink {
  /// Creates a string buffer containing the provided [content].
  external StringBuffer([Object content = ""]);

  /// Returns the length of the content that has been accumulated so far.
  /// This is a constant-time operation.
  external int get length;

  /// Returns whether the buffer is empty. This is a constant-time operation.
  bool get isEmpty => length == 0;

  /// Returns whether the buffer is not empty. This is a constant-time
  /// operation.
  bool get isNotEmpty => !isEmpty;

  external void write(Object? object);

  external void writeCharCode(int charCode);

  external void writeAll(Iterable<dynamic> objects, [String separator = ""]);

  /// Writes the string representation of [object] followed by a newline.
  ///
  /// Equivalent to `buffer.write(object)` followed by `buffer.write("\n")`.
  ///
  /// The newline is always represented as `"\n"`, and does not use a platform
  /// specific line ending, e.g., `"\r\n"` on Windows.
  ///
  /// Notice that calling `buffer.writeln(null)` will write the `"null"` string
  /// before the newline. Omitting the argument, or explicitly passing an empty
  /// string, is the recommended way to emit just the newline.
  external void writeln([Object? obj = ""]);

  /// Clears the string buffer.
  external void clear();

  /// Returns the contents of buffer as a single string.
  external String toString();
}
