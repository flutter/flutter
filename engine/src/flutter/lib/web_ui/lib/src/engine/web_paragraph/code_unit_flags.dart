// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import '../text_fragmenter.dart';

class HardcodedUnicodeProperties {
  static bool isControl(int utf16) {
    return utf16 < 0x32 ||
        (utf16 >= 0x7f && utf16 <= 0x9f) ||
        (utf16 >= 0x200D && utf16 <= 0x200F) ||
        (utf16 >= 0x202A && utf16 <= 0x202E);
  }

  static const Set<int> _whitespaces = <int>{
    0x0009, // character tabulation
    0x000A, // line feed
    0x000B, // line tabulation
    0x000C, // form feed
    0x000D, // carriage return
    0x0020, // space
    //0x0085, // next line
    //0x00A0, // no-break space
    0x1680, // ogham space mark
    0x2000, // en quad
    0x2001, // em quad
    0x2002, // en space
    0x2003, // em space
    0x2004, // three-per-em space
    0x2005, // four-per-em space
    0x2006, // six-per-em space
    //0x2007, // figure space
    0x2008, // punctuation space
    0x2009, // thin space
    0x200A, // hair space
    0x2028, // line separator
    0x2029, // paragraph separator
    //0x202F, // narrow no-break space
    0x205F, // medium mathematical space
    0x3000, // ideographic space
  };

  static bool isWhitespace(int utf16) {
    return _whitespaces.contains(utf16);
  }

  static const Set<int> _spaces = <int>{
    0x0009, // character tabulation
    0x000A, // line feed
    0x000B, // line tabulation
    0x000C, // form feed
    0x000D, // carriage return
    0x0020, // space
    0x0085, // next line
    0x00A0, // no-break space
    0x1680, // ogham space mark
    0x2000, // en quad
    0x2001, // em quad
    0x2002, // en space
    0x2003, // em space
    0x2004, // three-per-em space
    0x2005, // four-per-em space
    0x2006, // six-per-em space
    0x2007, // figure space
    0x2008, // punctuation space
    0x2009, // thin space
    0x200A, // hair space
    0x2028, // line separator
    0x2029, // paragraph separator
    0x202F, // narrow no-break space
    0x205F, // medium mathematical space
    0x3000, // ideographic space
  };
  static bool isSpace(int utf16) {
    return _spaces.contains(utf16);
  }

  static bool isTabulation(int utf16) {
    return utf16 == 0x0009;
  }

  static bool isHardBreak(int utf16) {
    return (utf16 == 0x000A) || (utf16 == 0x2028);
  }

  static const Set<(int first, int second)> _ranges = <(int first, int second)>{
    (4352, 4607), // Hangul Jamo
    (11904, 42191), // CJK_Radicals
    (43072, 43135), // Phags_Pa
    (44032, 55215), // Hangul_Syllables
    (63744, 64255), // CJK_Compatibility_Ideographs
    (65072, 65103), // CJK_Compatibility_Forms
    (65381, 65500), // Katakana_Hangul_Halfwidth
    (131072, 196607), // Supplementary_Ideographic_Plane
  };
  static bool isIdeographic(int utf16) {
    return _ranges.any((range) => (range.$1 <= utf16) && (range.$2 > utf16));
  }
}

class AllCodeUnitFlags {
  AllCodeUnitFlags(this._text) : _allFlags = Uint16List(_text.length + 1) {
    _extract();
  }

  final String _text;
  final Uint16List _allFlags;

  int get length => _allFlags.length;

  bool hasFlag(int index, CodeUnitFlag flag) {
    assert(index >= 0);
    assert(index < _allFlags.length);

    return (_allFlags[index] & flag._bitmask) != 0;
  }

  void _extract() {
    // Add whitespaces
    _allFlags.fillRange(0, _allFlags.length, 0);
    for (var i = 0; i < _allFlags.length - 1; i++) {
      if (HardcodedUnicodeProperties.isWhitespace(_text.codeUnitAt(i))) {
        _allFlags[i] = CodeUnitFlag.whitespace._bitmask;
      }
      // We can add more flags here, e.g. control characters, ideographic characters, etc.
    }

    // TODO(mdebbar): OPTIMIZATION:
    // We can make `segmentText` update `codeUnitFlags` in-place?
    // Get text segmentation resuls using browser APIs.
    final SegmentationResult result = segmentText(_text);

    // Fill out grapheme flags
    for (final int index in result.graphemes) {
      _allFlags[index] |= CodeUnitFlag.grapheme._bitmask;
    }
    // Fill out word flags
    for (final int index in result.words) {
      _allFlags[index] |= CodeUnitFlag.wordBreak._bitmask;
    }
    // Fill out line break flags
    for (var i = 0; i < result.breaks.length; i += 2) {
      final int index = result.breaks[i];
      final int type = result.breaks[i + 1];

      if (type == kSoftLineBreak) {
        _allFlags[index] |= CodeUnitFlag.softLineBreak._bitmask;
      } else {
        _allFlags[index] |= CodeUnitFlag.hardLineBreak._bitmask;
      }
    }
  }
}

enum CodeUnitFlag {
  whitespace(0x01), // 1 << 0
  grapheme(0x02), // 1 << 1
  softLineBreak(0x04), // 1 << 2
  hardLineBreak(0x08), // 1 << 3
  wordBreak(0x10); // 1 << 4

  const CodeUnitFlag(this._bitmask);

  final int _bitmask;
}
