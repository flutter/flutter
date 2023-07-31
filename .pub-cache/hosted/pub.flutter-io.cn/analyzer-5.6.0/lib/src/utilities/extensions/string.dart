// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension IterableOfStringExtension on Iterable<String> {
  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'and' when there are more than two elements in this
  /// iterable.
  String get commaSeparatedWithAnd => _commaSeparated('and');

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'or' when there are more than two elements in this
  /// iterable.
  String get commaSeparatedWithOr => _commaSeparated('or');

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by 'and' when there are more than two elements in this
  /// iterable, and a pair of single quotes surrounding each element.
  String get quotedAndCommaSeparatedWithAnd =>
      _commaSeparated('and', quoted: true);

  /// Produce a comma-separated representation of this iterable, with the last
  /// element preceded by the [conjunction] when there are more than two
  /// elements in this iterable.
  ///
  /// Each element is surrounded by a pair of single quotes if [quoted] is true.
  String _commaSeparated(String conjunction, {bool quoted = false}) {
    var iterator = this.iterator;

    // If has zero elements.
    if (!iterator.moveNext()) {
      return '';
    }
    var first = iterator.current;

    // If has one element.
    if (!iterator.moveNext()) {
      return quoted ? "'$first'" : first;
    }
    var second = iterator.current;

    // If has two elements.
    if (!iterator.moveNext()) {
      return quoted
          ? "'$first' $conjunction '$second'"
          : '$first $conjunction $second';
    }
    var third = iterator.current;

    var buffer = StringBuffer();
    _writeElement(buffer, first, quoted);
    buffer.write(', ');
    _writeElement(buffer, second, quoted);

    var nextToWrite = third;
    while (iterator.moveNext()) {
      buffer.write(', ');
      _writeElement(buffer, nextToWrite, quoted);
      nextToWrite = iterator.current;
    }
    buffer.write(', ');
    buffer.write(conjunction);
    buffer.write(' ');
    _writeElement(buffer, nextToWrite, quoted);
    return buffer.toString();
  }

  void _writeElement(StringBuffer buffer, String element, bool quoted) {
    if (quoted) {
      buffer.write("'");
    }
    buffer.write(element);
    if (quoted) {
      buffer.write("'");
    }
  }
}

extension StringExtension on String {
  String ifNotEmptyOrElse(String orElse) {
    return isNotEmpty ? this : orElse;
  }
}
