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
    // Only whitespace and line breaks are read during layout; word and grapheme flags stay lazy.
    _extractLineBreaksAndWhitespace();
  }

  final String _text;
  final Uint16List _allFlags;
  // Tracks whether wordBreak flags have been populated on demand.
  bool _hasWordBreaks = false;
  // Tracks whether grapheme flags have been populated on demand.
  bool _hasGraphemes = false;

  int get length => _allFlags.length;

  bool hasFlag(int index, CodeUnitFlag flag) {
    assert(index >= 0);
    assert(index < _allFlags.length);

    // Word and grapheme boundaries are not read during layout, so segment them on first query.
    if (flag == CodeUnitFlag.wordBreak && !_hasWordBreaks) {
      _extractWordBreaks();
    } else if (flag == CodeUnitFlag.grapheme && !_hasGraphemes) {
      _extractGraphemes();
    }

    return (_allFlags[index] & flag._bitmask) != 0;
  }

  void _extractLineBreaksAndWhitespace() {
    // Populate whitespace flags and V8 line-break flags needed by line wrapping.
    for (var i = 0; i < _allFlags.length - 1; i++) {
      if (HardcodedUnicodeProperties.isWhitespace(_text.codeUnitAt(i))) {
        _allFlags[i] = CodeUnitFlag.whitespace._bitmask;
      }
    }

    // Extract only V8 line breaks eagerly so layout does not pay for word or grapheme segmenters.
    final Uint32List breaks = fragmentUsingV8LineBreaker(_text);
    for (var i = 0; i < breaks.length; i += 2) {
      final int index = breaks[i];
      final int type = breaks[i + 1];

      if (type == kSoftLineBreak) {
        _allFlags[index] |= CodeUnitFlag.softLineBreak._bitmask;
      } else {
        _allFlags[index] |= CodeUnitFlag.hardLineBreak._bitmask;
      }
    }
  }

  void _extractWordBreaks() {
    // Populate word boundaries on demand for getWordBoundary queries.
    _hasWordBreaks = true;
    final Uint32List words = fragmentUsingIntlSegmenter(_text, IntlSegmenterGranularity.word);
    for (final index in words) {
      _allFlags[index] |= CodeUnitFlag.wordBreak._bitmask;
    }
  }

  void _extractGraphemes() {
    // Populate grapheme boundaries on demand when CodeUnitFlag.grapheme is queried directly.
    _hasGraphemes = true;
    final Uint32List graphemes = fragmentUsingIntlSegmenter(
      _text,
      IntlSegmenterGranularity.grapheme,
    );
    for (final index in graphemes) {
      _allFlags[index] |= CodeUnitFlag.grapheme._bitmask;
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
