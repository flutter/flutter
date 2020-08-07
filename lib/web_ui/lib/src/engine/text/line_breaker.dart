// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// Various types of line breaks as defined by the Unicode spec.
enum LineBreakType {
  /// Indicates that a line break is possible but not mandatory.
  opportunity,

  /// Indicates that this is a hard line break that can't be skipped.
  mandatory,

  /// Indicates the end of the text (which is also considered a line break in
  /// the Unicode spec). This is the same as [mandatory] but it's needed in our
  /// implementation to distinguish between the universal [endOfText] and the
  /// line break caused by "\n" at the end of the text.
  endOfText,
}

/// Acts as a tuple that encapsulates information about a line break.
///
/// It contains multiple indices that are helpful when it comes to measuring the
/// width of a line of text.
///
/// [indexWithoutTrailingSpaces] <= [indexWithoutTrailingNewlines] <= [index]
///
/// Example: for the string "foo \nbar " here are the indices:
/// ```
///   f   o   o       \n  b   a   r
/// ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
/// 0   1   2   3   4   5   6   7   8   9
/// ```
/// It contains two line breaks:
/// ```
/// // The first line break:
/// LineBreakResult(5, 4, 3, LineBreakType.mandatory)
///
/// // Second line break:
/// LineBreakResult(9, 9, 8, LineBreakType.mandatory)
/// ```
class LineBreakResult {
  const LineBreakResult(
    this.index,
    this.indexWithoutTrailingNewlines,
    this.indexWithoutTrailingSpaces,
    this.type,
  ): assert(indexWithoutTrailingSpaces <= indexWithoutTrailingNewlines),
     assert(indexWithoutTrailingNewlines <= index);

  /// Creates a [LineBreakResult] where all indices are the same (i.e. there are
  /// no trailing spaces or new lines).
  const LineBreakResult.sameIndex(this.index, this.type)
      : indexWithoutTrailingNewlines = index,
        indexWithoutTrailingSpaces = index;

  /// The true index at which the line break should occur, including all spaces
  /// and new lines.
  final int index;

  /// The index of the line break excluding any trailing new lines.
  final int indexWithoutTrailingNewlines;

  /// The index of the line break excluding any trailing spaces.
  final int indexWithoutTrailingSpaces;

  /// The type of line break is useful to determine the behavior in text
  /// measurement.
  ///
  /// For example, a mandatory line break always causes a line break regardless
  /// of width constraints. But a line break opportunity requires further checks
  /// to decide whether to take the line break or not.
  final LineBreakType type;

  @override
  int get hashCode => ui.hashValues(
        index,
        indexWithoutTrailingNewlines,
        indexWithoutTrailingSpaces,
        type,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is LineBreakResult &&
        other.index == index &&
        other.indexWithoutTrailingNewlines == indexWithoutTrailingNewlines &&
        other.indexWithoutTrailingSpaces == indexWithoutTrailingSpaces &&
        other.type == type;
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'LineBreakResult(index: $index, '
          'without new lines: $indexWithoutTrailingNewlines, '
          'without spaces: $indexWithoutTrailingSpaces, '
          'type: $type)';
    } else {
      return super.toString();
    }
  }
}

bool _isHardBreak(LineCharProperty? prop) {
  // No need to check for NL because it's already normalized to BK.
  return prop == LineCharProperty.LF || prop == LineCharProperty.BK;
}

bool _isALorHL(LineCharProperty? prop) {
  return prop == LineCharProperty.AL || prop == LineCharProperty.HL;
}

/// Whether the given property is part of a Korean Syllable block.
///
/// See:
/// - https://unicode.org/reports/tr14/tr14-45.html#LB27
bool _isKoreanSyllable(LineCharProperty? prop) {
  return prop == LineCharProperty.JL ||
      prop == LineCharProperty.JV ||
      prop == LineCharProperty.JT ||
      prop == LineCharProperty.H2 ||
      prop == LineCharProperty.H3;
}

/// Whether the given char code has an Eastern Asian width property of F, W or H.
///
/// See:
/// - https://www.unicode.org/reports/tr14/tr14-45.html#LB30
/// - https://www.unicode.org/Public/13.0.0/ucd/EastAsianWidth.txt
bool _hasEastAsianWidthFWH(int charCode) {
  return charCode == 0x2329 ||
      (charCode >= 0x3008 && charCode <= 0x301D) ||
      (charCode >= 0xFE17 && charCode <= 0xFF62);
}

/// Finds the next line break in the given [text] starting from [index].
///
/// Wethink about indices as pointing between characters, and they go all the
/// way from 0 to the string length. For example, here are the indices for the
/// string "foo bar":
///
/// ```
///   f   o   o       b   a   r
/// ^   ^   ^   ^   ^   ^   ^   ^
/// 0   1   2   3   4   5   6   7
/// ```
///
/// This way the indices work well with [String.substring()].
///
/// Useful resources:
///
/// * https://www.unicode.org/reports/tr14/tr14-45.html#Algorithm
/// * https://www.unicode.org/Public/11.0.0/ucd/LineBreak.txt
LineBreakResult nextLineBreak(String text, int index) {
  int? codePoint = getCodePoint(text, index);
  LineCharProperty curr = lineLookup.findForChar(codePoint);

  LineCharProperty? prev1;

  // Keeps track of the character two positions behind.
  LineCharProperty? prev2;

  // When there's a sequence of spaces or combining marks, this variable
  // contains the base property i.e. the property of the character before the
  // sequence.
  LineCharProperty? baseOfSpaceSequence;

  /// The index of the last character that wasn't a space.
  int lastNonSpaceIndex = index;

  /// The index of the last character that wasn't a new line.
  int lastNonNewlineIndex = index;

  // When the text/line starts with SP, we should treat the begining of text/line
  // as if it were a WJ (word joiner).
  if (curr == LineCharProperty.SP) {
    baseOfSpaceSequence = LineCharProperty.WJ;
  }

  bool isCurrZWJ = curr == LineCharProperty.ZWJ;

  // LB10: Treat any remaining combining mark or ZWJ as AL.
  // This catches the case where a CM is the first character on the line.
  if (curr == LineCharProperty.CM || curr == LineCharProperty.ZWJ) {
    curr = LineCharProperty.AL;
  }

  int regionalIndicatorCount = 0;

  // Always break at the end of text.
  // LB3: ! eot
  while (index < text.length) {
    // Keep count of the RI (regional indicator) sequence.
    if (curr == LineCharProperty.RI) {
      regionalIndicatorCount++;
    } else {
      regionalIndicatorCount = 0;
    }

    if (codePoint != null && codePoint > 0xFFFF) {
      // Advance `index` one extra step when handling a surrogate pair in the
      // string.
      index++;
    }
    index++;
    prev2 = prev1;
    prev1 = curr;

    final bool isPrevZWJ = isCurrZWJ;

    // Reset the base when we are past the space sequence.
    if (prev1 != LineCharProperty.SP) {
      baseOfSpaceSequence = null;
    }

    codePoint = getCodePoint(text, index);
    curr = lineLookup.findForChar(codePoint);

    isCurrZWJ = curr == LineCharProperty.ZWJ;

    // Always break after hard line breaks.
    // LB4: BK !
    //
    // Treat CR followed by LF, as well as CR, LF, and NL as hard line breaks.
    // LB5: LF !
    //      NL !
    if (_isHardBreak(prev1)) {
      return LineBreakResult(
        index,
        lastNonNewlineIndex,
        lastNonSpaceIndex,
        LineBreakType.mandatory,
      );
    }

    if (prev1 == LineCharProperty.CR) {
      if (curr == LineCharProperty.LF) {
        // LB5: CR × LF
        continue;
      } else {
        // LB5: CR !
        return LineBreakResult(
          index,
          lastNonNewlineIndex,
          lastNonSpaceIndex,
          LineBreakType.mandatory,
        );
      }
    }

    // At this point, we know for sure the prev character wasn't a new line.
    lastNonNewlineIndex = index;
    if (prev1 != LineCharProperty.SP) {
      lastNonSpaceIndex = index;
    }

    // Do not break before hard line breaks.
    // LB6: × ( BK | CR | LF | NL )
    if (_isHardBreak(curr) || curr == LineCharProperty.CR) {
      continue;
    }

    // Always break at the end of text.
    // LB3: ! eot
    if (index >= text.length) {
      return LineBreakResult(
        text.length,
        lastNonNewlineIndex,
        lastNonSpaceIndex,
        LineBreakType.endOfText,
      );
    }

    // Do not break before spaces or zero width space.
    // LB7: × SP
    if (curr == LineCharProperty.SP) {
      // When we encounter SP, we preserve the property of the previous
      // character so we can later apply the indirect breaking rules.
      if (prev1 == LineCharProperty.SP) {
        // If we are in the middle of a space sequence, a base should've
        // already been set.
        assert(baseOfSpaceSequence != null);
      } else {
        // We are at the beginning of a space sequence, establish the base.
        baseOfSpaceSequence = prev1;
      }
      continue;
    }
    // LB7: × ZW
    if (curr == LineCharProperty.ZW) {
      continue;
    }

    // Break before any character following a zero-width space, even if one or
    // more spaces intervene.
    // LB8: ZW SP* ÷
    if (prev1 == LineCharProperty.ZW ||
        baseOfSpaceSequence == LineCharProperty.ZW) {
      return LineBreakResult(
        index,
        lastNonNewlineIndex,
        lastNonSpaceIndex,
        LineBreakType.opportunity,
      );
    }

    // Do not break a combining character sequence; treat it as if it has the
    // line breaking class of the base character in all of the following rules.
    // Treat ZWJ as if it were CM.
    // LB9: Treat X (CM | ZWJ)* as if it were X
    //      where X is any line break class except BK, NL, LF, CR, SP, or ZW.
    if (curr == LineCharProperty.CM || curr == LineCharProperty.ZWJ) {
      // Other properties: BK, NL, LF, CR, ZW would've already generated a line
      // break, so we won't find them in `prev`.
      if (prev1 == LineCharProperty.SP) {
        // LB10: Treat any remaining combining mark or ZWJ as AL.
        curr = LineCharProperty.AL;
      } else {
        if (prev1 == LineCharProperty.RI) {
          // Prevent the previous RI from being double-counted.
          regionalIndicatorCount--;
        }
        // Preserve the property of the previous character to treat the sequence
        // as if it were X.
        curr = prev1;
        continue;
      }
    }

    // Do not break after a zero width joiner.
    // LB8a: ZWJ ×
    if (isPrevZWJ) {
      continue;
    }

    // Do not break before or after Word joiner and related characters.
    // LB11: × WJ
    //       WJ ×
    if (curr == LineCharProperty.WJ || prev1 == LineCharProperty.WJ) {
      continue;
    }

    // Do not break after NBSP and related characters.
    // LB12: GL ×
    if (prev1 == LineCharProperty.GL) {
      continue;
    }

    // Do not break before NBSP and related characters, except after spaces and
    // hyphens.
    // LB12a: [^SP BA HY] × GL
    if (!(prev1 == LineCharProperty.SP ||
            prev1 == LineCharProperty.BA ||
            prev1 == LineCharProperty.HY) &&
        curr == LineCharProperty.GL) {
      continue;
    }

    // Do not break before ‘]’ or ‘!’ or ‘;’ or ‘/’, even after spaces.
    // LB13: × CL
    //       × CP
    //       × EX
    //       × IS
    //       × SY
    if (curr == LineCharProperty.CL ||
        curr == LineCharProperty.CP ||
        curr == LineCharProperty.EX ||
        curr == LineCharProperty.IS ||
        curr == LineCharProperty.SY) {
      continue;
    }

    // Do not break after ‘[’, even after spaces.
    // LB14: OP SP* ×
    if (prev1 == LineCharProperty.OP ||
        baseOfSpaceSequence == LineCharProperty.OP) {
      continue;
    }

    // Do not break within ‘”[’, even with intervening spaces.
    // LB15: QU SP* × OP
    if ((prev1 == LineCharProperty.QU ||
            baseOfSpaceSequence == LineCharProperty.QU) &&
        curr == LineCharProperty.OP) {
      continue;
    }

    // Do not break between closing punctuation and a nonstarter, even with
    // intervening spaces.
    // LB16: (CL | CP) SP* × NS
    if ((prev1 == LineCharProperty.CL ||
            baseOfSpaceSequence == LineCharProperty.CL ||
            prev1 == LineCharProperty.CP ||
            baseOfSpaceSequence == LineCharProperty.CP) &&
        curr == LineCharProperty.NS) {
      continue;
    }

    // Do not break within ‘——’, even with intervening spaces.
    // LB17: B2 SP* × B2
    if ((prev1 == LineCharProperty.B2 ||
            baseOfSpaceSequence == LineCharProperty.B2) &&
        curr == LineCharProperty.B2) {
      continue;
    }

    // Break after spaces.
    // LB18: SP ÷
    if (prev1 == LineCharProperty.SP) {
      return LineBreakResult(
        index,
        lastNonNewlineIndex,
        lastNonSpaceIndex,
        LineBreakType.opportunity,
      );
    }

    // Do not break before or after quotation marks, such as ‘”’.
    // LB19: × QU
    //       QU ×
    if (prev1 == LineCharProperty.QU || curr == LineCharProperty.QU) {
      continue;
    }

    // Break before and after unresolved CB.
    // LB20: ÷ CB
    //       CB ÷
    if (prev1 == LineCharProperty.CB || curr == LineCharProperty.CB) {
      return LineBreakResult(
        index,
        lastNonNewlineIndex,
        lastNonSpaceIndex,
        LineBreakType.opportunity,
      );
    }

    // Do not break before hyphen-minus, other hyphens, fixed-width spaces,
    // small kana, and other non-starters, or after acute accents.
    // LB21: × BA
    //       × HY
    //       × NS
    //       BB ×
    if (curr == LineCharProperty.BA ||
        curr == LineCharProperty.HY ||
        curr == LineCharProperty.NS ||
        prev1 == LineCharProperty.BB) {
      continue;
    }

    // Don't break after Hebrew + Hyphen.
    // LB21a: HL (HY | BA) ×
    if (prev2 == LineCharProperty.HL &&
        (prev1 == LineCharProperty.HY || prev1 == LineCharProperty.BA)) {
      continue;
    }

    // Don’t break between Solidus and Hebrew letters.
    // LB21b: SY × HL
    if (prev1 == LineCharProperty.SY && curr == LineCharProperty.HL) {
      continue;
    }

    // Do not break before ellipses.
    // LB22: × IN
    if (curr == LineCharProperty.IN) {
      continue;
    }

    // Do not break between digits and letters.
    // LB23: (AL | HL) × NU
    //       NU × (AL | HL)
    if ((_isALorHL(prev1) && curr == LineCharProperty.NU) ||
        (prev1 == LineCharProperty.NU && _isALorHL(curr))) {
      continue;
    }

    // Do not break between numeric prefixes and ideographs, or between
    // ideographs and numeric postfixes.
    // LB23a: PR × (ID | EB | EM)
    if (prev1 == LineCharProperty.PR &&
        (curr == LineCharProperty.ID ||
            curr == LineCharProperty.EB ||
            curr == LineCharProperty.EM)) {
      continue;
    }
    // LB23a: (ID | EB | EM) × PO
    if ((prev1 == LineCharProperty.ID ||
            prev1 == LineCharProperty.EB ||
            prev1 == LineCharProperty.EM) &&
        curr == LineCharProperty.PO) {
      continue;
    }

    // Do not break between numeric prefix/postfix and letters, or between
    // letters and prefix/postfix.
    // LB24: (PR | PO) × (AL | HL)
    if ((prev1 == LineCharProperty.PR || prev1 == LineCharProperty.PO) &&
        _isALorHL(curr)) {
      continue;
    }
    // LB24: (AL | HL) × (PR | PO)
    if (_isALorHL(prev1) &&
        (curr == LineCharProperty.PR || curr == LineCharProperty.PO)) {
      continue;
    }

    // Do not break between the following pairs of classes relevant to numbers.
    // LB25: (CL | CP | NU) × (PO | PR)
    if ((prev1 == LineCharProperty.CL ||
            prev1 == LineCharProperty.CP ||
            prev1 == LineCharProperty.NU) &&
        (curr == LineCharProperty.PO || curr == LineCharProperty.PR)) {
      continue;
    }
    // LB25: (PO | PR) × OP
    if ((prev1 == LineCharProperty.PO || prev1 == LineCharProperty.PR) &&
        curr == LineCharProperty.OP) {
      continue;
    }
    // LB25: (PO | PR | HY | IS | NU | SY) × NU
    if ((prev1 == LineCharProperty.PO ||
            prev1 == LineCharProperty.PR ||
            prev1 == LineCharProperty.HY ||
            prev1 == LineCharProperty.IS ||
            prev1 == LineCharProperty.NU ||
            prev1 == LineCharProperty.SY) &&
        curr == LineCharProperty.NU) {
      continue;
    }

    // Do not break a Korean syllable.
    // LB26: JL × (JL | JV | H2 | H3)
    if (prev1 == LineCharProperty.JL &&
        (curr == LineCharProperty.JL ||
            curr == LineCharProperty.JV ||
            curr == LineCharProperty.H2 ||
            curr == LineCharProperty.H3)) {
      continue;
    }
    // LB26: (JV | H2) × (JV | JT)
    if ((prev1 == LineCharProperty.JV || prev1 == LineCharProperty.H2) &&
        (curr == LineCharProperty.JV || curr == LineCharProperty.JT)) {
      continue;
    }
    // LB26: (JT | H3) × JT
    if ((prev1 == LineCharProperty.JT || prev1 == LineCharProperty.H3) &&
        curr == LineCharProperty.JT) {
      continue;
    }

    // Treat a Korean Syllable Block the same as ID.
    // LB27: (JL | JV | JT | H2 | H3) × PO
    if (_isKoreanSyllable(prev1) && curr == LineCharProperty.PO) {
      continue;
    }
    // LB27: PR × (JL | JV | JT | H2 | H3)
    if (prev1 == LineCharProperty.PR && _isKoreanSyllable(curr)) {
      continue;
    }

    // Do not break between alphabetics.
    // LB28: (AL | HL) × (AL | HL)
    if (_isALorHL(prev1) && _isALorHL(curr)) {
      continue;
    }

    // Do not break between numeric punctuation and alphabetics (“e.g.”).
    // LB29: IS × (AL | HL)
    if (prev1 == LineCharProperty.IS && _isALorHL(curr)) {
      continue;
    }

    // Do not break between letters, numbers, or ordinary symbols and opening or
    // closing parentheses.
    // LB30: (AL | HL | NU) × OP
    //
    // LB30 requires that we exclude characters that have an Eastern Asian width
    // property of value F, W or H classes.
    if ((_isALorHL(prev1) || prev1 == LineCharProperty.NU) &&
        curr == LineCharProperty.OP &&
        !_hasEastAsianWidthFWH(text.codeUnitAt(index))) {
      continue;
    }
    // LB30: CP × (AL | HL | NU)
    if (prev1 == LineCharProperty.CP &&
        !_hasEastAsianWidthFWH(text.codeUnitAt(index - 1)) &&
        (_isALorHL(curr) || curr == LineCharProperty.NU)) {
      continue;
    }

    // Break between two regional indicator symbols if and only if there are an
    // even number of regional indicators preceding the position of the break.
    // LB30a: sot (RI RI)* RI × RI
    //        [^RI] (RI RI)* RI × RI
    if (curr == LineCharProperty.RI) {
      if (regionalIndicatorCount.isOdd) {
        continue;
      } else {
        return LineBreakResult(
          index,
          lastNonNewlineIndex,
          lastNonSpaceIndex,
          LineBreakType.opportunity,
        );
      }
    }

    // Do not break between an emoji base and an emoji modifier.
    // LB30b: EB × EM
    if (prev1 == LineCharProperty.EB && curr == LineCharProperty.EM) {
      continue;
    }

    // Break everywhere else.
    // LB31: ALL ÷
    //       ÷ ALL
    return LineBreakResult(
      index,
      lastNonNewlineIndex,
      lastNonSpaceIndex,
      LineBreakType.opportunity,
    );
  }
  return LineBreakResult(
    text.length,
    lastNonNewlineIndex,
    lastNonSpaceIndex,
    LineBreakType.endOfText,
  );
}
