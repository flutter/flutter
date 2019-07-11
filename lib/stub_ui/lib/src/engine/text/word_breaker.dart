// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

enum _FindBreakDirection {
  /// Indicates to find the word break by looking forward.
  forward,

  /// Indicates to find the word break by looking backward.
  backward,
}

/// [WordBreaker] exposes static methods to identify word boundaries.
abstract class WordBreaker {
  /// It starts from [index] and tries to find the next word boundary in [text].
  static int nextBreakIndex(String text, int index) =>
      _findBreakIndex(_FindBreakDirection.forward, text, index);

  /// It starts from [index] and tries to find the previous word boundary in
  /// [text].
  static int prevBreakIndex(String text, int index) =>
      _findBreakIndex(_FindBreakDirection.backward, text, index);

  static int _findBreakIndex(
    _FindBreakDirection direction,
    String text,
    int index,
  ) {
    int step, min, max;
    if (direction == _FindBreakDirection.forward) {
      step = 1;
      min = 0;
      max = text.length - 1;
    } else {
      step = -1;
      min = 1;
      max = text.length;
    }

    int i = index;
    while (i >= min && i <= max) {
      i += step;
      if (_isBreak(text, i)) {
        break;
      }
    }
    return i;
  }

  /// Find out if there's a word break between [index - 1] and [index].
  /// http://unicode.org/reports/tr29/#Word_Boundary_Rules
  static bool _isBreak(String text, int index) {
    // Break at the start and end of text.
    // WB1: sot ÷ Any
    // WB2: Any ÷ eot
    if (index <= 0 || index >= text.length) {
      return true;
    }

    // Do not break inside surrogate pair
    if (_isUtf16Surrogate(text.codeUnitAt(index - 1))) {
      return false;
    }

    final CharProperty immediateRight = getCharProperty(text, index);
    CharProperty immediateLeft = getCharProperty(text, index - 1);

    // Do not break within CRLF.
    // WB3: CR × LF
    if (immediateLeft == CharProperty.CR && immediateRight == CharProperty.LF)
      return false;

    // Otherwise break before and after Newlines (including CR and LF)
    // WB3a: (Newline | CR | LF) ÷
    if (_oneOf(
      immediateLeft,
      CharProperty.Newline,
      CharProperty.CR,
      CharProperty.LF,
    )) {
      return true;
    }

    // WB3b: ÷ (Newline | CR | LF)
    if (_oneOf(
      immediateRight,
      CharProperty.Newline,
      CharProperty.CR,
      CharProperty.LF,
    )) {
      return true;
    }

    // WB3c: ZWJ	×	\p{Extended_Pictographic}
    // TODO(flutter_web): What's the right way to implement this?

    // Keep horizontal whitespace together.
    // WB3d: WSegSpace × WSegSpace
    if (immediateLeft == CharProperty.WSegSpace &&
        immediateRight == CharProperty.WSegSpace) {
      return false;
    }

    // Ignore Format and Extend characters, except after sot, CR, LF, and
    // Newline.
    // WB4: X (Extend | Format | ZWJ)* → X
    if (_oneOf(
      immediateRight,
      CharProperty.Extend,
      CharProperty.Format,
      CharProperty.ZWJ,
    )) {
      // The Extend|Format|ZWJ character is to the right, so it is attached
      // to a character to the left, don't split here
      return false;
    }

    // We've reached the end of an Extend|Format|ZWJ sequence, collapse it.
    int l = 0;
    while (_oneOf(
      immediateLeft,
      CharProperty.Extend,
      CharProperty.Format,
      CharProperty.ZWJ,
    )) {
      l++;
      if (index - l - 1 < 0) {
        // Reached the beginning of text.
        return true;
      }
      immediateLeft = getCharProperty(text, index - l - 1);
    }

    // Do not break between most letters.
    // WB5: (ALetter | Hebrew_Letter) × (ALetter | Hebrew_Letter)
    if (_isAHLetter(immediateLeft) && _isAHLetter(immediateRight)) {
      return false;
    }

    // Some tests beyond this point require more context. We need to get that
    // context while also respecting rule WB4. So ignore Format, Extend and ZWJ.

    // Skip all Format, Extend and ZWJ to the right.
    int r = 0;
    CharProperty nextRight;
    do {
      r++;
      nextRight = getCharProperty(text, index + r);
    } while (_oneOf(
      nextRight,
      CharProperty.Extend,
      CharProperty.Format,
      CharProperty.ZWJ,
    ));

    // Skip all Format, Extend and ZWJ to the left.
    CharProperty nextLeft;
    do {
      l++;
      nextLeft = getCharProperty(text, index - l - 1);
    } while (_oneOf(
      nextLeft,
      CharProperty.Extend,
      CharProperty.Format,
      CharProperty.ZWJ,
    ));

    // Do not break letters across certain punctuation.
    // WB6: (AHLetter) × (MidLetter | MidNumLet | Single_Quote) (AHLetter)
    if (_isAHLetter(immediateLeft) &&
        _oneOf(
          immediateRight,
          CharProperty.MidLetter,
          CharProperty.MidNumLet,
          CharProperty.SingleQuote,
        ) &&
        _isAHLetter(nextRight)) {
      return false;
    }

    // WB7: (AHLetter) (MidLetter | MidNumLet | Single_Quote) × (AHLetter)
    if (_isAHLetter(nextLeft) &&
        _oneOf(
          immediateLeft,
          CharProperty.MidLetter,
          CharProperty.MidNumLet,
          CharProperty.SingleQuote,
        ) &&
        _isAHLetter(immediateRight)) {
      return false;
    }

    // WB7a: Hebrew_Letter × Single_Quote
    if (immediateLeft == CharProperty.HebrewLetter &&
        immediateRight == CharProperty.SingleQuote) {
      return false;
    }

    // WB7b: Hebrew_Letter × Double_Quote Hebrew_Letter
    if (immediateLeft == CharProperty.HebrewLetter &&
        immediateRight == CharProperty.DoubleQuote &&
        nextRight == CharProperty.HebrewLetter) {
      return false;
    }

    // WB7c: Hebrew_Letter Double_Quote × Hebrew_Letter
    if (nextLeft == CharProperty.HebrewLetter &&
        immediateLeft == CharProperty.DoubleQuote &&
        immediateRight == CharProperty.HebrewLetter) {
      return false;
    }

    // Do not break within sequences of digits, or digits adjacent to letters
    // (“3a”, or “A3”).
    // WB8: Numeric × Numeric
    if (immediateLeft == CharProperty.Numeric &&
        immediateRight == CharProperty.Numeric) {
      return false;
    }

    // WB9: AHLetter × Numeric
    if (_isAHLetter(immediateLeft) && immediateRight == CharProperty.Numeric)
      return false;

    // WB10: Numeric × AHLetter
    if (immediateLeft == CharProperty.Numeric && _isAHLetter(immediateRight))
      return false;

    // Do not break within sequences, such as “3.2” or “3,456.789”.
    // WB11: Numeric (MidNum | MidNumLet | Single_Quote) × Numeric
    if (nextLeft == CharProperty.Numeric &&
        _oneOf(
          immediateLeft,
          CharProperty.MidNum,
          CharProperty.MidNumLet,
          CharProperty.SingleQuote,
        ) &&
        immediateRight == CharProperty.Numeric) {
      return false;
    }

    // WB12: Numeric × (MidNum | MidNumLet | Single_Quote) Numeric
    if (immediateLeft == CharProperty.Numeric &&
        _oneOf(
          immediateRight,
          CharProperty.MidNum,
          CharProperty.MidNumLet,
          CharProperty.SingleQuote,
        ) &&
        nextRight == CharProperty.Numeric) {
      return false;
    }

    // Do not break between Katakana.
    // WB13: Katakana × Katakana
    if (immediateLeft == CharProperty.Katakana &&
        immediateRight == CharProperty.Katakana) {
      return false;
    }

    // Do not break from extenders.
    // WB13a: (AHLetter | Numeric | Katakana | ExtendNumLet) × ExtendNumLet
    if (_oneOf(
          immediateLeft,
          CharProperty.ALetter,
          CharProperty.HebrewLetter,
          CharProperty.Numeric,
          CharProperty.Katakana,
          CharProperty.ExtendNumLet,
        ) &&
        immediateRight == CharProperty.ExtendNumLet) {
      return false;
    }

    // WB13b: ExtendNumLet × (AHLetter | Numeric | Katakana)
    if (immediateLeft == CharProperty.ExtendNumLet &&
        _oneOf(
          immediateRight,
          CharProperty.ALetter,
          CharProperty.HebrewLetter,
          CharProperty.Numeric,
          CharProperty.Katakana,
        )) {
      return false;
    }

    // Do not break within emoji flag sequences. That is, do not break between
    // regional indicator (RI) symbols if there is an odd number of RI
    // characters before the break point.
    // WB15: sot (RI RI)* RI × RI
    // TODO(mdebbar): implement this.

    // WB16: [^RI] (RI RI)* RI × RI
    // TODO(mdebbar): implement this.

    // Otherwise, break everywhere (including around ideographs).
    // WB999: Any ÷ Any
    return true;
  }

  static bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  static bool _oneOf(
    CharProperty value,
    CharProperty choice1,
    CharProperty choice2, [
    CharProperty choice3,
    CharProperty choice4,
    CharProperty choice5,
  ]) {
    if (value == choice1) {
      return true;
    }
    if (value == choice2) {
      return true;
    }
    if (choice3 != null && value == choice3) {
      return true;
    }
    if (choice4 != null && value == choice4) {
      return true;
    }
    if (choice5 != null && value == choice5) {
      return true;
    }
    return false;
  }

  static bool _isAHLetter(CharProperty property) {
    return _oneOf(property, CharProperty.ALetter, CharProperty.HebrewLetter);
  }
}
