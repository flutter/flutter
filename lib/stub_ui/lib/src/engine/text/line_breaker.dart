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

final List<String> _doNotBreak = '_@,.()#/:\$'.split('');

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
  bool sawFirstWordBreak = false;
  // Always break at the end of text.
  // LB3: ÷ eot
  while (index < text.length) {
    final String curr = text[index];
    final String prev = index > 0 ? text[index - 1] : null;

    // Treat CR followed by LF, as well as CR, LF, and NL as hard line breaks.
    // LB5: CR × LF
    //      CR ÷
    //      LF ÷
    //      NL ÷
    if (curr == '\n') {
      return LineBreakResult(index + 1, LineBreakType.mandatory);
    }

    if ((_doNotBreak.contains(curr) && prev != ' ') ||
        (_doNotBreak.contains(prev))) {
      // Continue looping.
    } else if (sawFirstWordBreak) {
      return LineBreakResult(index, LineBreakType.opportunity);
    }

    index = WordBreaker.nextBreakIndex(text, index);
    sawFirstWordBreak = true;
  }
  return LineBreakResult(text.length, LineBreakType.endOfText);
}
