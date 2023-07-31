// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/reader.dart';

export 'package:_fe_analyzer_shared/src/scanner/reader.dart'
    show CharacterReader, CharSequenceReader, SubSequenceReader;

/// A [CharacterReader] that reads a range of characters from another character
/// reader.
class CharacterRangeReader extends CharacterReader {
  /// The reader from which the characters are actually being read.
  final CharacterReader baseReader;

  /// The first character to be read.
  final int startIndex;

  /// The last character to be read.
  final int endIndex;

  /// Initialize a newly created reader to read the characters from the given
  /// [baseReader] between the [startIndex] inclusive to [endIndex] exclusive.
  CharacterRangeReader(this.baseReader, this.startIndex, this.endIndex) {
    baseReader.offset = startIndex - 1;
  }

  @override
  int get offset => baseReader.offset;

  @override
  set offset(int offset) {
    baseReader.offset = offset;
  }

  @override
  int advance() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.advance();
  }

  @override
  String getContents() =>
      baseReader.getContents().substring(startIndex, endIndex);

  @override
  String getString(int start, int endDelta) =>
      baseReader.getString(start, endDelta);

  @override
  int peek() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.peek();
  }
}
