// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'bidi.dart';
import 'text_direction.dart';

// Suppress naming issues as changing them would be breaking.
// ignore_for_file: non_constant_identifier_names

/// Bidi stands for Bi-directional text.  According to
/// [Wikipedia](http://en.wikipedia.org/wiki/Bi-directional_text):
/// Bi-directional text is text containing text in both text directionalities,
/// both right-to-left (RTL) and left-to-right (LTR). It generally involves text
/// containing different types of alphabets, but may also refer to
/// boustrophedon, which is changing text directionality in each row.
///
/// Utility class for formatting display text in a potentially
/// opposite-directionality context without garbling layout issues.  Mostly a
/// very "slimmed-down" and dart-ified port of the Closure Birectional
/// formatting libary. If there is a utility in the Closure library (or ICU, or
/// elsewhere) that you would like this formatter to make available, please
/// contact the Dart team.
///
/// Provides the following functionality:
///
/// 1. *BiDi Wrapping*
/// When text in one language is mixed into a document in another, opposite-
/// directionality language, e.g. when an English business name is embedded in a
/// Hebrew web page, both the inserted string and the text following it may be
/// displayed incorrectly unless the inserted string is explicitly separated
/// from the surrounding text in a "wrapper" that declares its directionality at
/// the start and then resets it back at the end. This wrapping can be done in
/// HTML mark-up (e.g. a 'span dir=rtl' tag) or - only in contexts where mark-up
/// can not be used - in Unicode BiDi formatting codes (LRE|RLE and PDF).
/// Providing such wrapping services is the basic purpose of the BiDi formatter.
///
/// 2. *Directionality estimation*
/// How does one know whether a string about to be inserted into surrounding
/// text has the same directionality? Well, in many cases, one knows that this
/// must be the case when writing the code doing the insertion, e.g. when a
/// localized message is inserted into a localized page. In such cases there is
/// no need to involve the BiDi formatter at all. In the remaining cases, e.g.
/// when the string is user-entered or comes from a database, the language of
/// the string (and thus its directionality) is not known a priori, and must be
/// estimated at run-time. The BiDi formatter does this automatically.
///
/// 3. *Escaping*
/// When wrapping plain text - i.e. text that is not already HTML or HTML-
/// escaped - in HTML mark-up, the text must first be HTML-escaped to prevent
/// XSS attacks and other nasty business. This of course is always true, but the
/// escaping cannot be done after the string has already been wrapped in
/// mark-up, so the BiDi formatter also serves as a last chance and includes
/// escaping services.
///
/// Thus, in a single call, the formatter will escape the input string as
/// specified, determine its directionality, and wrap it as necessary. It is
/// then up to the caller to insert the return value in the output.

class BidiFormatter {
  /// The direction of the surrounding text (the context).
  TextDirection contextDirection;

  /// Indicates if we should always wrap the formatted text in a &lt;span&lt;,.
  final bool _alwaysSpan;

  /// Create a formatting object with a direction. If [alwaysSpan] is true we
  /// should always use a `span` tag, even when the input directionality is
  /// neutral or matches the context, so that the DOM structure of the output
  /// does not depend on the combination of directionalities.
  BidiFormatter.LTR([bool alwaysSpan = false])
      : contextDirection = TextDirection.LTR,
        _alwaysSpan = alwaysSpan;
  BidiFormatter.RTL([bool alwaysSpan = false])
      : contextDirection = TextDirection.RTL,
        _alwaysSpan = alwaysSpan;
  BidiFormatter.UNKNOWN([bool alwaysSpan = false])
      : contextDirection = TextDirection.UNKNOWN,
        _alwaysSpan = alwaysSpan;

  /// Is true if the known context direction for this formatter is RTL.
  bool get isRTL => contextDirection == TextDirection.RTL;

  /// Formats a string of a given (or estimated, if not provided) [direction]
  /// for use in HTML output of the context directionality, so an
  /// opposite-directionality string is neither garbled nor garbles what follows
  /// it.
  ///
  ///If the input string's directionality doesn't match the context
  /// directionality, we wrap it with a `span` tag and add a `dir` attribute
  /// (either "dir=rtl" or "dir=ltr").  If alwaysSpan was true when constructing
  /// the formatter, the input is always wrapped with `span` tag, skipping the
  /// dir attribute when it's not needed.
  ///
  /// If [resetDir] is true and the overall directionality or the exit
  /// directionality of [text] is opposite to the context directionality,
  /// a trailing unicode BiDi mark matching the context directionality is
  /// appended (LRM or RLM). If [isHtml] is false, we HTML-escape the [text].
  String wrapWithSpan(String text,
      {bool isHtml = false, bool resetDir = true, TextDirection? direction}) {
    direction ??= estimateDirection(text, isHtml: isHtml);
    String result;
    if (!isHtml) text = const HtmlEscape().convert(text);
    var directionChange = contextDirection.isDirectionChange(direction);
    if (_alwaysSpan || directionChange) {
      var spanDirection = '';
      if (directionChange) {
        spanDirection = ' dir=${direction.spanText}';
      }
      result = '<span$spanDirection>$text</span>';
    } else {
      result = text;
    }
    return result + (resetDir ? _resetDir(text, direction, isHtml) : '');
  }

  /// Format [text] of a known (if specified) or estimated [direction] for use
  /// in *plain-text* output of the context directionality, so an
  /// opposite-directionality text is neither garbled nor garbles what follows
  /// it. Unlike wrapWithSpan, this makes use of unicode BiDi formatting
  /// characters instead of spans for wrapping. The returned string would be
  /// RLE+text+PDF for RTL text, or LRE+text+PDF for LTR text.
  ///
  /// If [resetDir] is true, and if the overall directionality or the exit
  /// directionality of text are opposite to the context directionality,
  /// a trailing unicode BiDi mark matching the context directionality is
  /// appended (LRM or RLM).
  ///
  /// In HTML, the *only* valid use of this function is inside of elements that
  /// do not allow markup, e.g. an 'option' tag.
  /// This function does *not* do HTML-escaping regardless of the value of
  /// [isHtml]. [isHtml] is used to designate if the text contains HTML (escaped
  /// or unescaped).
  String wrapWithUnicode(String text,
      {bool isHtml = false, bool resetDir = true, TextDirection? direction}) {
    direction ??= estimateDirection(text, isHtml: isHtml);
    var result = text;
    if (contextDirection.isDirectionChange(direction)) {
      var marker = direction == TextDirection.RTL ? Bidi.RLE : Bidi.LRE;
      result = '$marker$text${Bidi.PDF}';
    }
    return result + (resetDir ? _resetDir(text, direction, isHtml) : '');
  }

  /// Estimates the directionality of [text] using the best known
  /// general-purpose method (using relative word counts). A
  /// TextDirection.UNKNOWN return value indicates completely neutral input.
  /// [isHtml] is true if [text] HTML or HTML-escaped.
  TextDirection estimateDirection(String text, {bool isHtml = false}) {
    return Bidi.estimateDirectionOfText(text, isHtml: isHtml); //TODO~!!!
  }

  /// Returns a unicode BiDi mark matching the surrounding context's [direction]
  /// (not necessarily the direction of [text]). The function returns an LRM or
  /// RLM if the overall directionality or the exit directionality of [text] is
  /// opposite the context directionality. Otherwise
  /// return the empty string. [isHtml] is true if [text] is HTML or
  /// HTML-escaped.
  String _resetDir(String text, TextDirection direction, bool isHtml) {
    // endsWithRtl and endsWithLtr are called only if needed (short-circuit).
    if ((contextDirection == TextDirection.LTR &&
            (direction == TextDirection.RTL ||
                Bidi.endsWithRtl(text, isHtml))) ||
        (contextDirection == TextDirection.RTL &&
            (direction == TextDirection.LTR ||
                Bidi.endsWithLtr(text, isHtml)))) {
      return contextDirection == TextDirection.LTR ? Bidi.LRM : Bidi.RLM;
    } else {
      return '';
    }
  }
}
