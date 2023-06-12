// TODO(jmesserly): reconcile this with dart:web htmlEscape.
// This one might be more useful, as it is HTML5 spec compliant.
/// Escapes [text] for use in the
/// [HTML fragment serialization algorithm][1]. In particular, as described
/// in the [specification][2]:
///
/// - Replace any occurrence of the `&` character by the string `&amp;`.
/// - Replace any occurrences of the U+00A0 NO-BREAK SPACE character by the
///   string `&nbsp;`.
/// - If the algorithm was invoked in [attributeMode], replace any occurrences
///   of the `"` character by the string `&quot;`.
/// - If the algorithm was not invoked in [attributeMode], replace any
///   occurrences of the `<` character by the string `&lt;`, and any occurrences
///   of the `>` character by the string `&gt;`.
///
/// [1]: http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#serializing-html-fragments
/// [2]: http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#escapingString
String htmlSerializeEscape(String text, {bool attributeMode = false}) {
  // TODO(jmesserly): is it faster to build up a list of codepoints?
  // StringBuffer seems cleaner assuming Dart can unbox 1-char strings.
  StringBuffer? result;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    String? replace;
    switch (ch) {
      case '&':
        replace = '&amp;';
        break;
      case '\u00A0' /*NO-BREAK SPACE*/ :
        replace = '&nbsp;';
        break;
      case '"':
        if (attributeMode) replace = '&quot;';
        break;
      case '<':
        if (!attributeMode) replace = '&lt;';
        break;
      case '>':
        if (!attributeMode) replace = '&gt;';
        break;
    }
    if (replace != null) {
      result ??= StringBuffer(text.substring(0, i));
      result.write(replace);
    } else if (result != null) {
      result.write(ch);
    }
  }

  return result != null ? result.toString() : text;
}
