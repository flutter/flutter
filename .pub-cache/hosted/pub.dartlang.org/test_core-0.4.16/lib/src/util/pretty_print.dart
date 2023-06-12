// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A regular expression matching terminal color codes.
final _colorCode = RegExp('\u001b\\[[0-9;]+m');

/// Returns [str] without any color codes.
String withoutColors(String str) => str.replaceAll(_colorCode, '');

/// A regular expression matching a single vowel.
final _vowel = RegExp('[aeiou]');

/// Returns [noun] with an indefinite article ("a" or "an") added, based on
/// whether its first letter is a vowel.
String a(String noun) => noun.startsWith(_vowel) ? 'an $noun' : 'a $noun';

/// Indent each line in [string] by 2 spaces.
String indent(String text) {
  var lines = text.split('\n');
  if (lines.length == 1) return '  $text';

  var buffer = StringBuffer();

  for (var line in lines.take(lines.length - 1)) {
    buffer.writeln('  $line');
  }
  buffer.write('  ${lines.last}');
  return buffer.toString();
}

/// Truncates [text] to fit within [maxLength].
///
/// This will try to truncate along word boundaries and preserve words both at
/// the beginning and the end of [text].
String truncate(String text, int maxLength) {
  // Return the full message if it fits.
  if (text.length <= maxLength) return text;

  // If we can fit the first and last three words, do so.
  var words = text.split(' ');
  if (words.length > 1) {
    var i = words.length;
    var length = words.first.length + 4;
    do {
      i--;
      length += 1 + words[i].length;
    } while (length <= maxLength && i > 0);
    if (length > maxLength || i == 0) i++;
    if (i < words.length - 4) {
      // Require at least 3 words at the end.
      var buffer = StringBuffer();
      buffer.write(words.first);
      buffer.write(' ...');
      for (; i < words.length; i++) {
        buffer.write(' ');
        buffer.write(words[i]);
      }
      return buffer.toString();
    }
  }

  // Otherwise truncate to return the trailing text, but attempt to start at
  // the beginning of a word.
  var result = text.substring(text.length - maxLength + 4);
  var firstSpace = result.indexOf(' ');
  if (firstSpace > 0) {
    result = result.substring(firstSpace);
  }
  return '...$result';
}
