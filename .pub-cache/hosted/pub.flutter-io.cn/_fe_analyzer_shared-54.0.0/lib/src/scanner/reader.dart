// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An object used by the scanner to read the characters to be scanned.
 */
abstract class CharacterReader {
  /**
   * The current offset relative to the beginning of the source. Return the
   * initial offset if the scanner has not yet scanned the source code, and one
   * (1) past the end of the source code if the entire source code has been
   * scanned.
   */
  int get offset;

  /**
   * Set the current offset relative to the beginning of the source to the given
   * [offset]. The new offset must be between the initial offset and one (1)
   * past the end of the source code.
   */
  void set offset(int offset);

  /**
   * Advance the current position and return the character at the new current
   * position.
   */
  int advance();

  /**
   * Return the source to be scanned.
   */
  String getContents();

  /**
   * Return the substring of the source code between the [start] offset and the
   * modified current position. The current position is modified by adding the
   * [endDelta], which is the number of characters after the current location to
   * be included in the string, or the number of characters before the current
   * location to be excluded if the offset is negative.
   */
  String getString(int start, int endDelta);

  /**
   * Return the character at the current position without changing the current
   * position.
   */
  int peek();
}

/**
 * A [CharacterReader] that reads characters from a character sequence.
 */
class CharSequenceReader implements CharacterReader {
  /**
   * The sequence from which characters will be read.
   */
  final String _sequence;

  /**
   * The number of characters in the string.
   */
  int _stringLength;

  /**
   * The index, relative to the string, of the next character to be read.
   */
  int _charOffset;

  /**
   * Initialize a newly created reader to read the characters in the given
   * [_sequence].
   */
  CharSequenceReader(this._sequence)
      : _stringLength = _sequence.length,
        _charOffset = 0;

  @override
  int get offset => _charOffset - 1;

  @override
  void set offset(int offset) {
    _charOffset = offset + 1;
  }

  @override
  int advance() {
    if (_charOffset >= _stringLength) {
      return -1;
    }
    return _sequence.codeUnitAt(_charOffset++);
  }

  @override
  String getContents() => _sequence;

  @override
  String getString(int start, int endDelta) =>
      _sequence.substring(start, _charOffset + endDelta);

  @override
  int peek() {
    if (_charOffset >= _stringLength) {
      return -1;
    }
    return _sequence.codeUnitAt(_charOffset);
  }
}

/**
 * A [CharacterReader] that reads characters from a character sequence, but adds
 * a delta when reporting the current character offset so that the character
 * sequence can be a subsequence from a larger sequence.
 */
class SubSequenceReader extends CharSequenceReader {
  /**
   * The offset from the beginning of the file to the beginning of the source
   * being scanned.
   */
  final int _offsetDelta;

  /**
   * Initialize a newly created reader to read the characters in the given
   * [sequence]. The [_offsetDelta] is the offset from the beginning of the file
   * to the beginning of the source being scanned
   */
  SubSequenceReader(super.sequence, this._offsetDelta);

  @override
  int get offset => _offsetDelta + super.offset;

  @override
  void set offset(int offset) {
    super.offset = offset - _offsetDelta;
  }

  @override
  String getContents() => super.getContents();

  @override
  String getString(int start, int endDelta) =>
      super.getString(start - _offsetDelta, endDelta);
}
