// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


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
class LineBreakResult {
  LineBreakResult(this.index, this.type);

  final int index;
  final LineBreakType type;
}

/// Normalizes properties that behave the same way into one common property.
LineCharProperty? _normalizeLineProperty(LineCharProperty? prop) {
  // LF and NL behave exactly the same as BK.
  // See: https://www.unicode.org/reports/tr14/tr14-22.html#ExplicitBreaks
  if (prop == LineCharProperty.LF || prop == LineCharProperty.NL) {
    return LineCharProperty.BK;
  }
  // In the absence of extra data (ICU data and language dictionaries), the
  // following properties will be treated as AL (alphabetic): AI, SA, SG and XX.
  // See LB1: https://www.unicode.org/reports/tr14/tr14-22.html#LB1
  if (prop == LineCharProperty.AI ||
      prop == LineCharProperty.SA ||
      prop == LineCharProperty.SG ||
      prop == LineCharProperty.XX) {
    return LineCharProperty.AL;
  }

  return prop;
}

/// Finds the next line break in the given [text] starting from [index].
///
/// Useful resources:
///
/// * http://www.unicode.org/reports/tr14/#Algorithm
/// * https://www.unicode.org/Public/11.0.0/ucd/LineBreak.txt
LineBreakResult nextLineBreak(String text, int index) {
  // "raw" refers to the property before normalization.
  LineCharProperty? rawCurr = lineLookup.find(text, index);
  LineCharProperty? curr = _normalizeLineProperty(rawCurr);

  LineCharProperty? rawPrev;
  LineCharProperty? prev;

  bool hasSpaces = false;

  // When the text/line starts with SP, we should treat the begining of text/line
  // as if it were a WJ (word joiner).
  // See: https://www.unicode.org/reports/tr14/tr14-22.html#SampleCode
  if (curr == LineCharProperty.SP) {
    hasSpaces = true;
    rawCurr = LineCharProperty.WJ;
    curr = LineCharProperty.WJ;
  }

  // Always break at the end of text.
  // LB3: ! eot
  while (index < text.length) {
    index++;
    rawPrev = rawCurr;
    prev = curr;

    rawCurr = lineLookup.find(text, index);
    curr = _normalizeLineProperty(rawCurr);

    // Always break after hard line breaks.
    // LB4: BK !
    //
    // Treat CR followed by LF, as well as CR, LF, and NL as hard line breaks.
    // LB5: CR × LF
    //      CR !
    //      LF !
    //      NL !
    if (prev == LineCharProperty.BK) {
      return LineBreakResult(index, LineBreakType.mandatory);
    }

    if (prev == LineCharProperty.CR) {
      if (rawCurr == LineCharProperty.LF) {
        // LB5: CR × LF
        continue;
      } else {
        // LB5: CR !
        return LineBreakResult(index, LineBreakType.mandatory);
      }
    }

    // Do not break before hard line breaks.
    // LB6: × ( BK | CR | LF | NL )
    if (curr == LineCharProperty.BK || curr == LineCharProperty.CR) {
      continue;
    }

    // Always break at the end of text.
    // LB3: ! eot
    if (index >= text.length) {
      return LineBreakResult(text.length, LineBreakType.endOfText);
    }

    // Break before and after unresolved CB.
    // LB20: ÷ CB
    //       CB ÷
    if (prev == LineCharProperty.CB || curr == LineCharProperty.CB) {
      return LineBreakResult(index, LineBreakType.opportunity);
    }

    if (curr == LineCharProperty.SP) {
      hasSpaces = true;
      // When we encounter SP, we preserve the property of the previous character.
      rawCurr = rawPrev;
      curr = prev;
      continue;
    }

    // At this point, we've handled new lines, and consumed all spaces (if any).
    // TODO: Use the 2d table now. See https://www.unicode.org/reports/tr14/tr14-22.html#ExampleTable

    // TODO: After using the 2d table, do:
    // hasSpaces = false;

    if (hasSpaces) {
      return LineBreakResult(index, LineBreakType.opportunity);
    }
  }
  return LineBreakResult(text.length, LineBreakType.endOfText);
}
