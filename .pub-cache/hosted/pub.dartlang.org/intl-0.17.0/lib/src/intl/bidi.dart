// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Bidi stands for Bi-directional text.  According to
/// http://en.wikipedia.org/wiki/Bi-directional_text: Bi-directional text is
/// text containing text in both text directionalities, both right-to-left (RTL)
/// and left-to-right (LTR). It generally involves text containing different
/// types of alphabets, but may also refer to boustrophedon, which is changing
/// text directionality in each row.

import '../global_state.dart' as global_state;
import 'text_direction.dart';

// Suppress naming issues as changing them would be breaking.
// ignore_for_file: constant_identifier_names
// ignore: avoid_classes_with_only_static_members
/// This provides utility methods for working with bidirectional text. All
/// of the methods are static, and are organized into a class primarily to
/// group them together for documentation and discoverability.
// TODO(alanknight): Consider a better way of organizing these.
class Bidi {
  /// Unicode "Left-To-Right Embedding" (LRE) character.
  static const LRE = '\u202A';

  /// Unicode "Right-To-Left Embedding" (RLE) character.
  static const RLE = '\u202B';

  /// Unicode "Pop Directional Formatting" (PDF) character.
  static const PDF = '\u202C';

  /// Unicode "Left-To-Right Mark" (LRM) character.
  static const LRM = '\u200E';

  /// Unicode "Right-To-Left Mark" (RLM) character.
  static const RLM = '\u200F';

  /// Constant to define the threshold of RTL directionality.
  static const _RTL_DETECTION_THRESHOLD = 0.40;

  /// Practical patterns to identify strong LTR and RTL characters,
  /// respectively.  These patterns are not completely correct according to the
  /// Unicode standard. They are simplified for performance and small code size.
  static const String _LTR_CHARS =
      r'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590'
      r'\u0800-\u1FFF\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF';
  static const String _RTL_CHARS = r'\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC';

  /// Returns the input [text] with spaces instead of HTML tags or HTML escapes,
  /// which is helpful for text directionality estimation.
  /// Note: This function should not be used in other contexts.
  /// It does not deal well with many things: comments, script,
  /// elements, style elements, dir attribute,`>` in quoted attribute values,
  /// etc. But it does handle well enough the most common use cases.
  /// Since the worst that can happen as a result of these shortcomings is that
  /// the wrong directionality will be estimated, we have not invested in
  /// improving this.
  static String stripHtmlIfNeeded(String text) {
    // The regular expression is simplified for an HTML tag (opening or
    // closing) or an HTML escape. We might want to skip over such expressions
    // when estimating the text directionality.
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  /// Determines if the first character in [text] with strong directionality is
  /// LTR. If [isHtml] is true, the text is HTML or HTML-escaped.
  static bool startsWithLtr(String text, [isHtml = false]) {
    return RegExp('^[^$_RTL_CHARS]*[$_LTR_CHARS]')
        .hasMatch(isHtml ? stripHtmlIfNeeded(text) : text);
  }

  /// Determines if the first character in [text] with strong directionality is
  /// RTL. If [isHtml] is true, the text is HTML or HTML-escaped.
  static bool startsWithRtl(String text, [isHtml = false]) {
    return RegExp('^[^$_LTR_CHARS]*[$_RTL_CHARS]')
        .hasMatch(isHtml ? stripHtmlIfNeeded(text) : text);
  }

  /// Determines if the exit directionality (ie, the last strongly-directional
  /// character in [text] is LTR. If [isHtml] is true, the text is HTML or
  /// HTML-escaped.
  static bool endsWithLtr(String text, [isHtml = false]) {
    return RegExp('[$_LTR_CHARS][^$_RTL_CHARS]*\$')
        .hasMatch(isHtml ? stripHtmlIfNeeded(text) : text);
  }

  /// Determines if the exit directionality (ie, the last strongly-directional
  /// character in [text] is RTL. If [isHtml] is true, the text is HTML or
  /// HTML-escaped.
  static bool endsWithRtl(String text, [isHtml = false]) {
    return RegExp('[$_RTL_CHARS][^$_LTR_CHARS]*\$')
        .hasMatch(isHtml ? stripHtmlIfNeeded(text) : text);
  }

  /// Determines if the given [text] has any LTR characters in it.
  /// If [isHtml] is true, the text is HTML or HTML-escaped.
  static bool hasAnyLtr(String text, [isHtml = false]) {
    return RegExp(r'[' '$_LTR_CHARS' r']')
        .hasMatch(isHtml ? stripHtmlIfNeeded(text) : text);
  }

  /// Determines if the given [text] has any RTL characters in it.
  /// If [isHtml] is true, the text is HTML or HTML-escaped.
  static bool hasAnyRtl(String text, [isHtml = false]) {
    return RegExp(r'[' '$_RTL_CHARS' r']')
        .hasMatch(isHtml ? stripHtmlIfNeeded(text) : text);
  }

  static final _rtlLocaleRegex = RegExp(
      r'^(ar|dv|he|iw|fa|nqo|ps|sd|ug|ur|yi|.*[-_]'
      r'(Arab|Hebr|Thaa|Nkoo|Tfng))(?!.*[-_](Latn|Cyrl)($|-|_))'
      r'($|-|_)',
      caseSensitive: false);

  static String? _lastLocaleCheckedForRtl;
  static bool? _lastRtlCheck;

  /// Check if a BCP 47 / III [languageString] indicates an RTL language.
  ///
  /// i.e. either:
  /// - a language code explicitly specifying one of the right-to-left scripts,
  ///   e.g. "az-Arab", or
  /// - a language code specifying one of the languages normally written in a
  ///   right-to-left script, e.g. "fa" (Farsi), except ones explicitly
  ///   specifying Latin or Cyrillic script (which are the usual LTR
  ///   alternatives).
  ///
  /// The list of right-to-left scripts appears in the 100-199 range in
  /// http://www.unicode.org/iso15924/iso15924-num.html, of which Arabic and
  /// Hebrew are by far the most widely used. We also recognize Thaana, N'Ko,
  /// and Tifinagh, which also have significant modern usage. The rest (Syriac,
  /// Samaritan, Mandaic, etc.) seem to have extremely limited or no modern
  /// usage and are not recognized.  The languages usually written in a
  /// right-to-left script are taken as those with Suppress-Script:
  /// Hebr|Arab|Thaa|Nkoo|Tfng in
  /// http://www.iana.org/assignments/language-subtag-registry, as well as
  /// Sindhi (sd) and Uyghur (ug).  The presence of other subtags of the
  /// language code, e.g. regions like EG (Egypt), is ignored.
  static bool isRtlLanguage([String? languageString]) {
    var language = languageString ?? global_state.getCurrentLocale();
    if (_lastLocaleCheckedForRtl != language) {
      _lastLocaleCheckedForRtl = language;
      _lastRtlCheck = _rtlLocaleRegex.hasMatch(language);
    }
    return _lastRtlCheck!;
  }

  /// Enforce the [html] snippet in RTL directionality regardless of overall
  /// context. If the html piece was enclosed by a tag, the direction will be
  /// applied to existing tag, otherwise a span tag will be added as wrapper.
  /// For this reason, if html snippet start with with tag, this tag must
  /// enclose the whole piece. If the tag already has a direction specified,
  /// this new one will override existing one in behavior (should work on
  /// Chrome, FF, and IE since this was ported directly from the Closure
  /// version).
  static String enforceRtlInHtml(String html) =>
      _enforceInHtmlHelper(html, 'rtl');

  /// Enforce RTL on both end of the given [text] using unicode BiDi formatting
  /// characters RLE and PDF.
  static String enforceRtlInText(String text) => '$RLE$text$PDF';

  /// Enforce the [html] snippet in LTR directionality regardless of overall
  /// context. If the html piece was enclosed by a tag, the direction will be
  /// applied to existing tag, otherwise a span tag will be added as wrapper.
  /// For this reason, if html snippet start with with tag, this tag must
  /// enclose the whole piece. If the tag already has a direction specified,
  /// this new one will override existing one in behavior (tested on FF and IE).
  static String enforceLtrInHtml(String html) =>
      _enforceInHtmlHelper(html, 'ltr');

  /// Enforce LTR on both end of the given [text] using unicode BiDi formatting
  /// characters LRE and PDF.
  static String enforceLtrInText(String text) => '$LRE$text$PDF';

  /// Enforce the [html] snippet in the desired [direction] regardless of
  /// overall context. If the html piece was enclosed by a tag, the direction
  /// will be applied to existing tag, otherwise a span tag will be added as
  /// wrapper.  For this reason, if html snippet start with with tag, this tag
  /// must enclose the whole piece. If the tag already has a direction
  /// specified, this new one will override existing one in behavior (tested on
  /// FF and IE).
  static String _enforceInHtmlHelper(String html, String direction) {
    if (html.startsWith('<')) {
      var buffer = StringBuffer();
      var startIndex = 0;
      var match = RegExp('<\\w+').firstMatch(html);
      if (match != null) {
        buffer
          ..write(html.substring(startIndex, match.end))
          ..write(' dir=$direction');
        startIndex = match.end;
      }
      return (buffer..write(html.substring(startIndex))).toString();
    }
    // '\n' is important for FF so that it won't incorrectly merge span groups.
    return '\n<span dir=$direction>$html</span>';
  }

  /// Apply bracket guard to [str] using html span tag. This is to address the
  /// problem of messy bracket display that frequently happens in RTL layout.
  /// If [isRtlContext] is true, then we explicitly want to wrap in a span of
  /// RTL directionality, regardless of the estimated directionality.
  static String guardBracketInHtml(String str, [bool? isRtlContext]) {
    var useRtl = isRtlContext == null ? hasAnyRtl(str) : isRtlContext;
    var matchingBrackets =
        RegExp(r'(\(.*?\)+)|(\[.*?\]+)|(\{.*?\}+)|(&lt;.*?(&gt;)+)');
    return _guardBracketHelper(str, matchingBrackets,
        '<span dir=${useRtl ? "rtl" : "ltr"}>', '</span>');
  }

  /// Apply bracket guard to [str] using LRM and RLM. This is to address the
  /// problem of messy bracket display that frequently happens in RTL layout.
  /// This version works for both plain text and html, but in some cases is not
  /// as good as guardBracketInHtml. If [isRtlContext] is true, then we
  /// explicitly want to wrap in a span of RTL directionality, regardless of the
  /// estimated directionality.
  static String guardBracketInText(String str, [bool? isRtlContext]) {
    var useRtl = isRtlContext == null ? hasAnyRtl(str) : isRtlContext;
    var mark = useRtl ? RLM : LRM;
    return _guardBracketHelper(
        str, RegExp(r'(\(.*?\)+)|(\[.*?\]+)|(\{.*?\}+)|(<.*?>+)'), mark, mark);
  }

  /// (Mostly) reimplements the $& functionality of "replace" in JavaScript.
  /// Given a [str] and the [regexp] to match with, optionally supply a string
  /// to be inserted [before] the match and/or [after]. For example,
  /// `_guardBracketHelper('firetruck', new RegExp('truck'), 'hydrant', '!')`
  /// would return 'firehydrant!'.  // TODO(efortuna): Get rid of this once this
  /// is implemented in Dart.  // See Issue 2979.
  static String _guardBracketHelper(String str, RegExp regexp,
      [String? before, String? after]) {
    var buffer = StringBuffer();
    var startIndex = 0;
    for (var match in regexp.allMatches(str)) {
      buffer
        ..write(str.substring(startIndex, match.start))
        ..write(before)
        ..write(str.substring(match.start, match.end))
        ..write(after);
      startIndex = match.end;
    }
    return (buffer..write(str.substring(startIndex))).toString();
  }

  /// Estimates the directionality of [text] using the best known
  /// general-purpose method (using relative word counts). A
  /// TextDirection.UNKNOWN return value indicates completely neutral input.
  /// [isHtml] is true if [text] HTML or HTML-escaped.
  ///
  /// If the number of RTL words is above a certain percentage of the total
  /// number of strongly directional words, returns RTL.
  /// Otherwise, if any words are strongly or weakly LTR, returns LTR.
  /// Otherwise, returns UNKNOWN, which is used to mean `neutral`.
  /// Numbers and URLs are counted as weakly LTR.
  static TextDirection estimateDirectionOfText(String text,
      {bool isHtml = false}) {
    text = isHtml ? stripHtmlIfNeeded(text) : text;
    var rtlCount = 0;
    var total = 0;
    var hasWeaklyLtr = false;
    // Split a string into 'words' for directionality estimation based on
    // relative word counts.
    for (var token in text.split(RegExp(r'\s+'))) {
      if (startsWithRtl(token)) {
        rtlCount++;
        total++;
      } else if (RegExp(r'^http://').hasMatch(token)) {
        // Checked if token looks like something that must always be LTR even in
        // RTL text, such as a URL.
        hasWeaklyLtr = true;
      } else if (hasAnyLtr(token)) {
        total++;
      } else if (RegExp(r'\d').hasMatch(token)) {
        // Checked if token contains any numerals.
        hasWeaklyLtr = true;
      }
    }

    if (total == 0) {
      return hasWeaklyLtr ? TextDirection.LTR : TextDirection.UNKNOWN;
    } else if (rtlCount > _RTL_DETECTION_THRESHOLD * total) {
      return TextDirection.RTL;
    } else {
      return TextDirection.LTR;
    }
  }

  /// Replace the double and single quote directly after a Hebrew character in
  /// [str] with GERESH and GERSHAYIM. This is most likely the user's intention.
  static String normalizeHebrewQuote(String str) {
    var buf = StringBuffer();
    if (str.isNotEmpty) {
      buf.write(str.substring(0, 1));
    }
    // Start at 1 because we're looking for the patterns [\u0591-\u05f2])" or
    // [\u0591-\u05f2]'.
    for (var i = 1; i < str.length; i++) {
      if (str.substring(i, i + 1) == '"' &&
          RegExp('[\u0591-\u05f2]').hasMatch(str.substring(i - 1, i))) {
        buf.write('\u05f4');
      } else if (str.substring(i, i + 1) == "'" &&
          RegExp('[\u0591-\u05f2]').hasMatch(str.substring(i - 1, i))) {
        buf.write('\u05f3');
      } else {
        buf.write(str.substring(i, i + 1));
      }
    }
    return buf.toString();
  }

  /// Check the estimated directionality of [str], return true if the piece of
  /// text should be laid out in RTL direction. If [isHtml] is true, the string
  /// is HTML or HTML-escaped.
  static bool detectRtlDirectionality(String str, {bool isHtml = false}) =>
      estimateDirectionOfText(str, isHtml: isHtml) == TextDirection.RTL;
}
