// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class UnicodeProperties {
  static bool isControl(int utf16) {
    return utf16 < 0x32 ||
        (utf16 >= 0x7f && utf16 <= 0x9f) ||
        (utf16 >= 0x200D && utf16 <= 0x200F) ||
        (utf16 >= 0x202A && utf16 <= 0x202E);
  }

  static List<int> whitespaces = <int>[
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
  ];

  static bool isWhitespace(int utf16) {
    return whitespaces.contains(utf16);
  }

  static List<int> spaces = <int>[
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
  ];
  static bool isSpace(int utf16) {
    return spaces.contains(utf16);
  }

  static bool isTabulation(int utf16) {
    return utf16 == ('\t' as int);
  }

  static bool isHardBreak(int utf16) {
    return utf16 == ('\n' as int) || utf16 == '\u2028';
  }

  static List<(int first, int second)> ranges = <(int first, int second)>[
    (4352, 4607), // Hangul Jamo
    (11904, 42191), // CJK_Radicals
    (43072, 43135), // Phags_Pa
    (44032, 55215), // Hangul_Syllables
    (63744, 64255), // CJK_Compatibility_Ideographs
    (65072, 65103), // CJK_Compatibility_Forms
    (65381, 65500), // Katakana_Hangul_Halfwidth
    (131072, 196607), // Supplementary_Ideographic_Plane
  ];
  static bool isIdeographic(int utf16) {
    return ranges.contains((range) => (range.first <= utf16) && (range.second > utf16));
  }
}
