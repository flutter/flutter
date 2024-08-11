// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/// A `String` converter that converts characters to HTML entities.
///
/// This is intended to sanitize text before inserting the text into an HTML
/// document. Characters that are meaningful in HTML are converted to
/// HTML entities (like `&amp;` for `&`).
///
/// The general converter escapes all characters that are meaningful in HTML
/// attributes or normal element context. Elements with special content types
/// (like CSS or JavaScript) may need a more specialized escaping that
/// understands that content type.
///
/// If the context where the text will be inserted is known in more detail,
/// it's possible to omit escaping some characters (like quotes when not
/// inside an attribute value).
///
/// The escaped text should only be used inside quoted HTML attributes values
/// or as text content of a normal element. Using the escaped text inside a
/// tag, but not inside a quoted attribute value, is still dangerous.
const HtmlEscape htmlEscape = HtmlEscape();

/// HTML escape modes.
///
/// Allows specifying a mode for HTML escaping that depends on the context
/// where the escaped result is going to be used.
/// The relevant contexts are:
///
/// * as text content of an HTML element.
/// * as value of a (single- or double-) quoted attribute value.
///
/// All modes require escaping of `&` (ampersand) characters, and may
/// enable escaping of more characters.
///
/// Custom escape modes can be created using the [HtmlEscapeMode.new]
/// constructor.
///
/// Example:
/// ```dart
/// const htmlEscapeMode = HtmlEscapeMode(
///   name: 'custom',
///   escapeLtGt: true,
///   escapeQuot: false,
///   escapeApos: false,
///   escapeSlash: false,
///  );
///
/// const HtmlEscape htmlEscape = HtmlEscape(htmlEscapeMode);
/// String unescaped = 'Text & subject';
/// String escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Text &amp; subject
///
/// unescaped = '10 > 1 and 1 < 10';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // 10 &gt; 1 and 1 &lt; 10
///
/// unescaped = "Single-quoted: 'text'";
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Single-quoted: 'text'
///
/// unescaped = 'Double-quoted: "text"';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Double-quoted: "text"
///
/// unescaped = 'Path: /system/';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Path: /system/
/// ```
final class HtmlEscapeMode {
  final String _name;

  /// Whether to escape '<' and '>'.
  final bool escapeLtGt;

  /// Whether to escape '"' (quote).
  final bool escapeQuot;

  /// Whether to escape "'" (apostrophe).
  final bool escapeApos;

  /// Whether to escape "/" (forward slash, solidus).
  ///
  /// Escaping a slash is recommended to avoid cross-site scripting attacks by
  /// [the Open Web Application Security Project](https://www.owasp.org/index.php/XSS_(Cross_Site_Scripting)_Prevention_Cheat_Sheet#RULE_.231_-_HTML_Escape_Before_Inserting_Untrusted_Data_into_HTML_Element_Content)
  final bool escapeSlash;

  /// Default escaping mode, which escapes all characters.
  ///
  /// The result of such an escaping is usable both in element content and
  /// in any attribute value.
  ///
  /// The escaping only works for elements with normal HTML content,
  /// and not, for example, for script or style element content,
  /// which require escapes matching their particular content syntax.
  static const HtmlEscapeMode unknown =
      HtmlEscapeMode._('unknown', true, true, true, true);

  /// Escaping mode for text going into double-quoted HTML attribute values.
  ///
  /// The result should not be used as the content of an unquoted
  /// or single-quoted attribute value.
  ///
  /// Escapes double quotes (`"`) but not single quotes (`'`),
  /// and escapes `<` and `>` characters because they are not allowed
  /// in strict XHTML attributes
  static const HtmlEscapeMode attribute =
      HtmlEscapeMode._('attribute', true, true, false, false);

  /// Escaping mode for text going into single-quoted HTML attribute values.
  ///
  /// The result should not be used as the content of an unquoted
  /// or double-quoted attribute value.
  ///
  /// Escapes single quotes (`'`) but not double quotes (`"`),
  /// and escapes `<` and `>` characters because they are not allowed
  /// in strict XHTML attributes.
  static const HtmlEscapeMode sqAttribute =
      HtmlEscapeMode._('attribute', true, false, true, false);

  /// Escaping mode for text going into HTML element content.
  ///
  /// The escaping only works for elements with normal HTML content,
  /// and not, for example, for script or style element content,
  /// which require escapes matching their particular content syntax.
  ///
  /// Escapes `<` and `>` characters.
  static const HtmlEscapeMode element =
      HtmlEscapeMode._('element', true, false, false, false);

  const HtmlEscapeMode._(this._name, this.escapeLtGt, this.escapeQuot,
      this.escapeApos, this.escapeSlash);

  /// Create a custom escaping mode.
  ///
  /// All modes escape `&`.
  /// The mode can further be set to escape `<` and `>` ([escapeLtGt]),
  /// `"` ([escapeQuot]), `'` ([escapeApos]), and/or `/` ([escapeSlash]).
  const HtmlEscapeMode(
      {String name = "custom",
      this.escapeLtGt = false,
      this.escapeQuot = false,
      this.escapeApos = false,
      this.escapeSlash = false})
      : _name = name;

  String toString() => _name;
}

/// Converter which escapes characters with special meaning in HTML.
///
/// The converter finds characters that are significant in the HTML source and
/// replaces them with corresponding HTML entities.
///
/// The characters that need escaping in HTML are:
///
/// * `&` (ampersand) always needs to be escaped.
/// * `<` (less than) and `>` (greater than) when inside an element.
/// * `"` (quote) when inside a double-quoted attribute value.
/// * `'` (apostrophe) when inside a single-quoted attribute value.
///       Apostrophe is escaped as `&#39;` instead of `&apos;` since
///       not all browsers understand `&apos;`.
/// * `/` (slash) is recommended to be escaped because it may be used
///       to terminate an element in some HTML dialects.
///
/// Escaping `>` (greater than) isn't necessary, but the result is often
/// found to be easier to read if greater-than is also escaped whenever
/// less-than is.
///
/// Example:
/// ```dart
/// const HtmlEscape htmlEscape = HtmlEscape();
/// String unescaped = 'Text & subject';
/// String escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Text &amp; subject
///
/// unescaped = '10 > 1 and 1 < 10';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // 10 &gt; 1 and 1 &lt; 10
///
/// unescaped = "Single-quoted: 'text'";
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Single-quoted: &#39;text&#39;
///
/// unescaped = 'Double-quoted: "text"';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Double-quoted: &quot;text&quot;
///
/// unescaped = 'Path: /system/';
/// escaped = htmlEscape.convert(unescaped);
/// print(escaped); // Path: &#47;system&#47;
/// ```
final class HtmlEscape extends Converter<String, String> {
  /// The [HtmlEscapeMode] used by the converter.
  final HtmlEscapeMode mode;

  /// Create converter that escapes HTML characters.
  ///
  /// If [mode] is provided as either [HtmlEscapeMode.attribute] or
  /// [HtmlEscapeMode.element], only the corresponding subset of HTML
  /// characters is escaped.
  /// The default is to escape all HTML characters.
  const HtmlEscape([this.mode = HtmlEscapeMode.unknown]);

  String convert(String text) {
    var val = _convert(text, 0, text.length);
    return val == null ? text : val;
  }

  /// Converts the substring of text from start to end.
  ///
  /// Returns `null` if no changes were necessary, otherwise returns
  /// the converted string.
  String? _convert(String text, int start, int end) {
    StringBuffer? result;
    for (var i = start; i < end; i++) {
      var ch = text[i];
      String? replacement;
      switch (ch) {
        case '&':
          replacement = '&amp;';
          break;
        case '"':
          if (mode.escapeQuot) replacement = '&quot;';
          break;
        case "'":
          if (mode.escapeApos) replacement = '&#39;';
          break;
        case '<':
          if (mode.escapeLtGt) replacement = '&lt;';
          break;
        case '>':
          if (mode.escapeLtGt) replacement = '&gt;';
          break;
        case '/':
          if (mode.escapeSlash) replacement = '&#47;';
          break;
      }
      if (replacement != null) {
        result ??= StringBuffer();
        if (i > start) result.write(text.substring(start, i));
        result.write(replacement);
        start = i + 1;
      }
    }
    if (result == null) return null;
    if (end > start) result.write(text.substring(start, end));
    return result.toString();
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    return _HtmlEscapeSink(this,
        sink is StringConversionSink ? sink : StringConversionSink.from(sink));
  }
}

class _HtmlEscapeSink extends StringConversionSink {
  final HtmlEscape _escape;
  final StringConversionSink _sink;

  _HtmlEscapeSink(this._escape, this._sink);

  void addSlice(String chunk, int start, int end, bool isLast) {
    var val = _escape._convert(chunk, start, end);
    if (val == null) {
      _sink.addSlice(chunk, start, end, isLast);
    } else {
      _sink.add(val);
      if (isLast) _sink.close();
    }
  }

  void close() {
    _sink.close();
  }
}
