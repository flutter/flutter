// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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

class CharCode {
  // New line characters.
  static const int lf = 0x0A;
  static const int bk1 = 0x0B;
  static const int bk2 = 0x0C;
  static const int cr = 0x0D;
  static const int nl = 0x85;

  // Space characters.
  static const int tab = 0x09;
  static const int space = 0x20;

  static const int hyphen = 0x2D;
}

/// Acts as a tuple that encapsulates information about a line break.
class LineBreakResult {
  LineBreakResult(this.index, this.type);

  final int index;
  final LineBreakType type;
}

/// Finds the next line break in the given [text] starting from [index].
///
/// Useful resources:
///
/// * http://www.unicode.org/reports/tr14/#Algorithm
/// * https://www.unicode.org/Public/11.0.0/ucd/LineBreak.txt
LineBreakResult nextLineBreak(String text, int index) {
  // TODO(flutter_web): https://github.com/flutter/flutter/issues/33523
  // This is a hacky/temporary/throw-away implementation to enable us to move fast
  // with the rest of the line-splitting project.

  // Always break at the end of text.
  // LB3: ÷ eot
  while (index++ < text.length) {
    final int curr = index < text.length ? text.codeUnitAt(index) : null;
    final int prev = index > 0 ? text.codeUnitAt(index - 1) : null;

    // Always break after hard line breaks.
    // LB4: BK !
    if (prev == CharCode.bk1 || prev == CharCode.bk2) {
      return LineBreakResult(index, LineBreakType.mandatory);
    }

    // Treat CR followed by LF, as well as CR, LF, and NL as hard line breaks.
    // LB5: CR × LF
    //      CR !
    //      LF !
    //      NL !
    if (prev == CharCode.cr && curr == CharCode.lf) {
      continue;
    }
    if (prev == CharCode.cr || prev == CharCode.lf || prev == CharCode.nl) {
      return LineBreakResult(index, LineBreakType.mandatory);
    }

    // Do not break before hard line breaks.
    // LB6: × ( BK | CR | LF | NL )
    if (curr == CharCode.bk1 ||
        curr == CharCode.bk2 ||
        curr == CharCode.cr ||
        curr == CharCode.lf ||
        curr == CharCode.nl) {
      continue;
    }

    if (index >= text.length) {
      return LineBreakResult(text.length, LineBreakType.endOfText);
    }

    if (curr == CharCode.space || curr == CharCode.tab) {
      continue;
    }

    if (prev == CharCode.space ||
        prev == CharCode.tab ||
        prev == CharCode.hyphen) {
      return LineBreakResult(index, LineBreakType.opportunity);
    }
  }
  return LineBreakResult(text.length, LineBreakType.endOfText);
}
