// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.src.whitespace;

/// Constants for the number of spaces for various kinds of indentation.
class Indent {
  /// The number of spaces in a block or collection body.
  static const block = 2;

  /// How much wrapped cascade sections indent.
  static const cascade = 2;

  /// The number of spaces in a single level of expression nesting.
  static const expression = 4;

  /// The ":" on a wrapped constructor initialization list.
  static const constructorInitializer = 4;
}

/// The kind of pending whitespace that has been "written", but not actually
/// physically output yet.
///
/// We defer actually writing whitespace until a non-whitespace token is
/// encountered to avoid trailing whitespace.
class Whitespace {
  /// No whitespace.
  static const none = Whitespace._('none');

  /// A single non-breaking space.
  static const space = Whitespace._('space');

  /// A single newline.
  static const newline = Whitespace._('newline');

  /// A single newline that takes into account the current expression nesting
  /// for the next line.
  static const nestedNewline = Whitespace._('nestedNewline');

  /// A single newline with all indentation eliminated at the beginning of the
  /// next line.
  ///
  /// Used for subsequent lines in a multiline string.
  static const newlineFlushLeft = Whitespace._('newlineFlushLeft');

  /// Two newlines, a single blank line of separation.
  static const twoNewlines = Whitespace._('twoNewlines');

  /// A split or newline should be output based on whether the current token is
  /// on the same line as the previous one or not.
  ///
  /// In general, we like to avoid using this because it makes the formatter
  /// less prescriptive over the user's whitespace.
  static const splitOrNewline = Whitespace._('splitOrNewline');

  /// A split or blank line (two newlines) should be output based on whether
  /// the current token is on the same line as the previous one or not.
  ///
  /// This is used between enum cases, which will collapse if possible but
  /// also allow a blank line to be preserved between cases.
  ///
  /// In general, we like to avoid using this because it makes the formatter
  /// less prescriptive over the user's whitespace.
  static const splitOrTwoNewlines = Whitespace._('splitOrTwoNewlines');

  /// One or two newlines should be output based on how many newlines are
  /// present between the next token and the previous one.
  ///
  /// In general, we like to avoid using this because it makes the formatter
  /// less prescriptive over the user's whitespace.
  static const oneOrTwoNewlines = Whitespace._('oneOrTwoNewlines');

  /// A hard split was just written whose whitespace takes precedence over any
  /// previous pending whitespace.
  static const afterHardSplit = Whitespace._('afterHardSplit');

  final String name;

  /// Gets the minimum number of newlines contained in this whitespace.
  int get minimumLines {
    switch (this) {
      case Whitespace.newline:
      case Whitespace.nestedNewline:
      case Whitespace.newlineFlushLeft:
      case Whitespace.oneOrTwoNewlines:
        return 1;

      case Whitespace.twoNewlines:
        return 2;

      default:
        return 0;
    }
  }

  const Whitespace._(this.name);

  @override
  String toString() => name;
}
