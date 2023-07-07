// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'constants.dart' as constants;
import 'regexp.dart' as regexp;

/// A simple and not particularly general stream class to make parsing
/// dates from strings simpler. It is general enough to operate on either
/// lists or strings.
// TODO(alanknight): With the improvements to the collection libraries
// since this was written we might be able to get rid of it entirely
// in favor of e.g. aString.split('') giving us an iterable of one-character
// strings, or else make the implementation trivial.
class IntlStream {
  dynamic contents;
  int index = 0;

  IntlStream(this.contents);

  bool atEnd() => index >= contents.length;

  dynamic next() => contents[index++];

  /// Return the next [howMany] items, or as many as there are remaining.
  /// Advance the stream by that many positions.
  dynamic read([int howMany = 1]) {
    var result = peek(howMany);
    index += howMany;
    return result;
  }

  /// Does the input start with the given string, if we start from the
  /// current position.
  bool startsWith(String pattern) {
    if (contents is String) return contents.startsWith(pattern, index);
    return pattern == peek(pattern.length);
  }

  /// Return the next [howMany] items, or as many as there are remaining.
  /// Does not modify the stream position.
  dynamic peek([int howMany = 1]) {
    dynamic result;
    if (contents is String) {
      String stringContents = contents;
      result = stringContents.substring(
          index, min(index + howMany, stringContents.length));
    } else {
      // Assume List
      result = contents.sublist(index, index + howMany);
    }
    return result;
  }

  /// Return the remaining contents of the stream
  dynamic rest() => peek(contents.length - index);

  /// Find the index of the first element for which [f] returns true.
  /// Advances the stream to that position.
  int? findIndex(bool Function(dynamic) f) {
    while (!atEnd()) {
      if (f(next())) return index - 1;
    }
    return null;
  }

  /// Find the indexes of all the elements for which [f] returns true.
  /// Leaves the stream positioned at the end.
  List<dynamic> findIndexes(bool Function(dynamic) f) {
    var results = [];
    while (!atEnd()) {
      if (f(next())) results.add(index - 1);
    }
    return results;
  }

  /// Assuming that the contents are characters, read as many digits as we
  /// can see and then return the corresponding integer, advancing the receiver.
  ///
  /// For non-ascii digits, the optional arguments are a regular expression
  /// [digitMatcher] to find the next integer, and the codeUnit of the local
  /// zero [zeroDigit].
  int? nextInteger({RegExp? digitMatcher, int? zeroDigit}) {
    var string = (digitMatcher ?? regexp.asciiDigitMatcher).stringMatch(rest());
    if (string == null || string.isEmpty) return null;
    read(string.length);
    if (zeroDigit != null && zeroDigit != constants.asciiZeroCodeUnit) {
      // Trying to optimize this, as it might get called a lot.
      var oldDigits = string.codeUnits;
      var newDigits = List<int>.filled(string.length, 0);
      for (var i = 0; i < string.length; i++) {
        newDigits[i] = oldDigits[i] - zeroDigit + constants.asciiZeroCodeUnit;
      }
      string = String.fromCharCodes(newDigits);
    }
    return int.parse(string);
  }
}
