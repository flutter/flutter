// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class CodeUnitFlags {
  CodeUnitFlags(this._value);

  bool get isWhitespace => (_value & kPartOfWhiteSpaceBreak) != 0;

  bool get isGraphemeStart => (_value & kGraphemeStart) != 0;

  bool get isSoftLineBreak => (_value & kSoftLineBreakBefore) != 0;

  bool get isHardLineBreak => (_value & kHardLineBreakBefore) != 0;

  bool get isWordBreak => (_value & kWordBreak) != 0;

  set whitespace(bool flag) =>
      _value = flag ? (_value | kPartOfWhiteSpaceBreak) : (_value & ~kPartOfWhiteSpaceBreak);

  set graphemeStart(bool flag) =>
      _value = flag ? (_value | kGraphemeStart) : (_value & ~kGraphemeStart);

  set softLineBreak(bool flag) =>
      _value = flag ? (_value | kSoftLineBreakBefore) : (_value & ~kSoftLineBreakBefore);

  set hardLineBreak(bool flag) =>
      _value = flag ? (_value | kHardLineBreakBefore) : (_value & ~kHardLineBreakBefore);

  set wordBreak(bool flag) => _value = flag ? (_value | kWordBreak) : (_value & ~kWordBreak);

  bool hasFlag(int flag) {
    return (_value & flag) != 0;
  }

  int get value => _value;
  int _value;

  @override
  String toString() {
    final String whitespaces = isWhitespace ? 'whitespace ' : '';
    final String grapheme = isGraphemeStart ? 'grapheme ' : '';
    final String softBreak = isSoftLineBreak ? 'softBreak ' : '';
    final String hardBreak = isHardLineBreak ? 'hardBreak ' : '';
    final String word = isWordBreak ? 'word ' : '';
    return '$whitespaces$grapheme$softBreak$hardBreak$word';
  }

  static const int kNoCodeUnitFlag = 0 << 0;
  static const int kPartOfWhiteSpaceBreak = 1 << 0;
  static const int kGraphemeStart = 1 << 1;
  static const int kSoftLineBreakBefore = 1 << 2;
  static const int kHardLineBreakBefore = 1 << 3;
  static const int kPartOfIntraWordBreak = 1 << 4;
  static const int kControl = 1 << 5;
  static const int kTabulation = 1 << 6;
  static const int kGlyphClusterStart = 1 << 7;
  static const int kIdeographic = 1 << 8;
  static const int kEmoji = 1 << 9;
  static const int kWordBreak = 1 << 10;
  static const int kSentenceBreak = 1 << 11;
}
