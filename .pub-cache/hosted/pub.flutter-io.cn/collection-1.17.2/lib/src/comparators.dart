// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Character constants.
const int _zero = 0x30;
const int _upperCaseA = 0x41;
const int _upperCaseZ = 0x5a;
const int _lowerCaseA = 0x61;
const int _lowerCaseZ = 0x7a;
const int _asciiCaseBit = 0x20;

/// Checks if strings [a] and [b] differ only on the case of ASCII letters.
///
/// Strings are equal if they have the same length, and the characters at
/// each index are the same, or they are ASCII letters where one is upper-case
/// and the other is the lower-case version of the same letter.
///
/// The comparison does not ignore the case of non-ASCII letters, so
/// an upper-case ae-ligature (Æ) is different from
/// a lower case ae-ligature (æ).
///
/// Ignoring non-ASCII letters is not generally a good idea, but it makes sense
/// for situations where the strings are known to be ASCII. Examples could
/// be Dart identifiers, base-64 or hex encoded strings, GUIDs or similar
/// strings with a known structure.
bool equalsIgnoreAsciiCase(String a, String b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    var aChar = a.codeUnitAt(i);
    var bChar = b.codeUnitAt(i);
    if (aChar == bChar) continue;
    // Quick-check for whether this may be different cases of the same letter.
    if (aChar ^ bChar != _asciiCaseBit) return false;
    // If it's possible, then check if either character is actually an ASCII
    // letter.
    var aCharLowerCase = aChar | _asciiCaseBit;
    if (_lowerCaseA <= aCharLowerCase && aCharLowerCase <= _lowerCaseZ) {
      continue;
    }
    return false;
  }
  return true;
}

/// Hash code for a string which is compatible with [equalsIgnoreAsciiCase].
///
/// The hash code is unaffected by changing the case of ASCII letters, but
/// the case of non-ASCII letters do affect the result.
int hashIgnoreAsciiCase(String string) {
  // Jenkins hash code ( http://en.wikipedia.org/wiki/Jenkins_hash_function).
  // adapted to smi values.
  // Same hash used by dart2js for strings, modified to ignore ASCII letter
  // case.
  var hash = 0;
  for (var i = 0; i < string.length; i++) {
    var char = string.codeUnitAt(i);
    // Convert lower-case ASCII letters to upper case.upper
    // This ensures that strings that differ only in case will have the
    // same hash code.
    if (_lowerCaseA <= char && char <= _lowerCaseZ) char -= _asciiCaseBit;
    hash = 0x1fffffff & (hash + char);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash >>= 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash >>= 11;
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

/// Compares [a] and [b] lexically, converting ASCII letters to upper case.
///
/// Comparison treats all lower-case ASCII letters as upper-case letters,
/// but does no case conversion for non-ASCII letters.
///
/// If two strings differ only on the case of ASCII letters, the one with the
/// capital letter at the first difference will compare as less than the other
/// string. This tie-breaking ensures that the comparison is a total ordering
/// on strings and is compatible with equality.
///
/// Ignoring non-ASCII letters is not generally a good idea, but it makes sense
/// for situations where the strings are known to be ASCII. Examples could
/// be Dart identifiers, base-64 or hex encoded strings, GUIDs or similar
/// strings with a known structure.
int compareAsciiUpperCase(String a, String b) {
  var defaultResult = 0; // Returned if no difference found.
  for (var i = 0; i < a.length; i++) {
    if (i >= b.length) return 1;
    var aChar = a.codeUnitAt(i);
    var bChar = b.codeUnitAt(i);
    if (aChar == bChar) continue;
    // Upper-case if letters.
    var aUpperCase = aChar;
    var bUpperCase = bChar;
    if (_lowerCaseA <= aChar && aChar <= _lowerCaseZ) {
      aUpperCase -= _asciiCaseBit;
    }
    if (_lowerCaseA <= bChar && bChar <= _lowerCaseZ) {
      bUpperCase -= _asciiCaseBit;
    }
    if (aUpperCase != bUpperCase) return (aUpperCase - bUpperCase).sign;
    if (defaultResult == 0) defaultResult = (aChar - bChar);
  }
  if (b.length > a.length) return -1;
  return defaultResult.sign;
}

/// Compares [a] and [b] lexically, converting ASCII letters to lower case.
///
/// Comparison treats all upper-case ASCII letters as lower-case letters,
/// but does no case conversion for non-ASCII letters.
///
/// If two strings differ only on the case of ASCII letters, the one with the
/// capital letter at the first difference will compare as less than the other
/// string. This tie-breaking ensures that the comparison is a total ordering
/// on strings.
///
/// Ignoring non-ASCII letters is not generally a good idea, but it makes sense
/// for situations where the strings are known to be ASCII. Examples could
/// be Dart identifiers, base-64 or hex encoded strings, GUIDs or similar
/// strings with a known structure.
int compareAsciiLowerCase(String a, String b) {
  var defaultResult = 0;
  for (var i = 0; i < a.length; i++) {
    if (i >= b.length) return 1;
    var aChar = a.codeUnitAt(i);
    var bChar = b.codeUnitAt(i);
    if (aChar == bChar) continue;
    var aLowerCase = aChar;
    var bLowerCase = bChar;
    // Upper case if ASCII letters.
    if (_upperCaseA <= bChar && bChar <= _upperCaseZ) {
      bLowerCase += _asciiCaseBit;
    }
    if (_upperCaseA <= aChar && aChar <= _upperCaseZ) {
      aLowerCase += _asciiCaseBit;
    }
    if (aLowerCase != bLowerCase) return (aLowerCase - bLowerCase).sign;
    if (defaultResult == 0) defaultResult = aChar - bChar;
  }
  if (b.length > a.length) return -1;
  return defaultResult.sign;
}

/// Compares strings [a] and [b] according to [natural sort ordering][].
///
/// A natural sort ordering is a lexical ordering where embedded
/// numerals (digit sequences) are treated as a single unit and ordered by
/// numerical value.
/// This means that `"a10b"` will be ordered after `"a7b"` in natural
/// ordering, where lexical ordering would put the `1` before the `7`, ignoring
/// that the `1` is part of a larger number.
///
/// Example:
/// The following strings are in the order they would be sorted by using this
/// comparison function:
///
///     "a", "a0", "a0b", "a1", "a01", "a9", "a10", "a100", "a100b", "aa"
///
/// [natural sort ordering]: https://en.wikipedia.org/wiki/Natural_sort_order
int compareNatural(String a, String b) {
  for (var i = 0; i < a.length; i++) {
    if (i >= b.length) return 1;
    var aChar = a.codeUnitAt(i);
    var bChar = b.codeUnitAt(i);
    if (aChar != bChar) {
      return _compareNaturally(a, b, i, aChar, bChar);
    }
  }
  if (b.length > a.length) return -1;
  return 0;
}

/// Compares strings [a] and [b] according to lower-case
/// [natural sort ordering][].
///
/// ASCII letters are converted to lower case before being compared, like
/// for [compareAsciiLowerCase], then the result is compared like for
/// [compareNatural].
///
/// If two strings differ only on the case of ASCII letters, the one with the
/// capital letter at the first difference will compare as less than the other
/// string. This tie-breaking ensures that the comparison is a total ordering
/// on strings.
///
/// [natural sort ordering]: https://en.wikipedia.org/wiki/Natural_sort_order
int compareAsciiLowerCaseNatural(String a, String b) {
  var defaultResult = 0; // Returned if no difference found.
  for (var i = 0; i < a.length; i++) {
    if (i >= b.length) return 1;
    var aChar = a.codeUnitAt(i);
    var bChar = b.codeUnitAt(i);
    if (aChar == bChar) continue;
    var aLowerCase = aChar;
    var bLowerCase = bChar;
    if (_upperCaseA <= aChar && aChar <= _upperCaseZ) {
      aLowerCase += _asciiCaseBit;
    }
    if (_upperCaseA <= bChar && bChar <= _upperCaseZ) {
      bLowerCase += _asciiCaseBit;
    }
    if (aLowerCase != bLowerCase) {
      return _compareNaturally(a, b, i, aLowerCase, bLowerCase);
    }
    if (defaultResult == 0) defaultResult = aChar - bChar;
  }
  if (b.length > a.length) return -1;
  return defaultResult.sign;
}

/// Compares strings [a] and [b] according to upper-case
/// [natural sort ordering][].
///
/// ASCII letters are converted to upper case before being compared, like
/// for [compareAsciiUpperCase], then the result is compared like for
/// [compareNatural].
///
/// If two strings differ only on the case of ASCII letters, the one with the
/// capital letter at the first difference will compare as less than the other
/// string. This tie-breaking ensures that the comparison is a total ordering
/// on strings
///
/// [natural sort ordering]: https://en.wikipedia.org/wiki/Natural_sort_order
int compareAsciiUpperCaseNatural(String a, String b) {
  var defaultResult = 0;
  for (var i = 0; i < a.length; i++) {
    if (i >= b.length) return 1;
    var aChar = a.codeUnitAt(i);
    var bChar = b.codeUnitAt(i);
    if (aChar == bChar) continue;
    var aUpperCase = aChar;
    var bUpperCase = bChar;
    if (_lowerCaseA <= aChar && aChar <= _lowerCaseZ) {
      aUpperCase -= _asciiCaseBit;
    }
    if (_lowerCaseA <= bChar && bChar <= _lowerCaseZ) {
      bUpperCase -= _asciiCaseBit;
    }
    if (aUpperCase != bUpperCase) {
      return _compareNaturally(a, b, i, aUpperCase, bUpperCase);
    }
    if (defaultResult == 0) defaultResult = aChar - bChar;
  }
  if (b.length > a.length) return -1;
  return defaultResult.sign;
}

/// Check for numbers overlapping the current mismatched characters.
///
/// If both [aChar] and [bChar] are digits, use numerical comparison.
/// Check if the previous characters is a non-zero number, and if not,
/// skip - but count - leading zeros before comparing numbers.
///
/// If one is a digit and the other isn't, check if the previous character
/// is a digit, and if so, the the one with the digit is the greater number.
///
/// Otherwise just returns the difference between [aChar] and [bChar].
int _compareNaturally(String a, String b, int index, int aChar, int bChar) {
  assert(aChar != bChar);
  var aIsDigit = _isDigit(aChar);
  var bIsDigit = _isDigit(bChar);
  if (aIsDigit) {
    if (bIsDigit) {
      return _compareNumerically(a, b, aChar, bChar, index);
    } else if (index > 0 && _isDigit(a.codeUnitAt(index - 1))) {
      // aChar is the continuation of a longer number.
      return 1;
    }
  } else if (bIsDigit && index > 0 && _isDigit(b.codeUnitAt(index - 1))) {
    // bChar is the continuation of a longer number.
    return -1;
  }
  // Characters are both non-digits, or not continuation of earlier number.
  return (aChar - bChar).sign;
}

/// Compare numbers overlapping [aChar] and [bChar] numerically.
///
/// If the numbers have the same numerical value, but one has more leading
/// zeros, the longer number is considered greater than the shorter one.
///
/// This ensures a total ordering on strings compatible with equality.
int _compareNumerically(String a, String b, int aChar, int bChar, int index) {
  // Both are digits. Find the first significant different digit, then find
  // the length of the numbers.
  if (_isNonZeroNumberSuffix(a, index)) {
    // Part of a longer number, differs at this index, just count the length.
    var result = _compareDigitCount(a, b, index, index);
    if (result != 0) return result;
    // If same length, the current character is the most significant differing
    // digit.
    return (aChar - bChar).sign;
  }
  // Not part of larger (non-zero) number, so skip leading zeros before
  // comparing numbers.
  var aIndex = index;
  var bIndex = index;
  if (aChar == _zero) {
    do {
      aIndex++;
      if (aIndex == a.length) return -1; // number in a is zero, b is not.
      aChar = a.codeUnitAt(aIndex);
    } while (aChar == _zero);
    if (!_isDigit(aChar)) return -1;
  } else if (bChar == _zero) {
    do {
      bIndex++;
      if (bIndex == b.length) return 1; // number in b is zero, a is not.
      bChar = b.codeUnitAt(bIndex);
    } while (bChar == _zero);
    if (!_isDigit(bChar)) return 1;
  }
  if (aChar != bChar) {
    var result = _compareDigitCount(a, b, aIndex, bIndex);
    if (result != 0) return result;
    return (aChar - bChar).sign;
  }
  // Same leading digit, one had more leading zeros.
  // Compare digits until reaching a difference.
  while (true) {
    var aIsDigit = false;
    var bIsDigit = false;
    aChar = 0;
    bChar = 0;
    if (++aIndex < a.length) {
      aChar = a.codeUnitAt(aIndex);
      aIsDigit = _isDigit(aChar);
    }
    if (++bIndex < b.length) {
      bChar = b.codeUnitAt(bIndex);
      bIsDigit = _isDigit(bChar);
    }
    if (aIsDigit) {
      if (bIsDigit) {
        if (aChar == bChar) continue;
        // First different digit found.
        break;
      }
      // bChar is non-digit, so a has longer number.
      return 1;
    } else if (bIsDigit) {
      return -1; // b has longer number.
    } else {
      // Neither is digit, so numbers had same numerical value.
      // Fall back on number of leading zeros
      // (reflected by difference in indices).
      return (aIndex - bIndex).sign;
    }
  }
  // At first differing digits.
  var result = _compareDigitCount(a, b, aIndex, bIndex);
  if (result != 0) return result;
  return (aChar - bChar).sign;
}

/// Checks which of [a] and [b] has the longest sequence of digits.
///
/// Starts counting from `i + 1` and `j + 1` (assumes that `a[i]` and `b[j]` are
/// both already known to be digits).
int _compareDigitCount(String a, String b, int i, int j) {
  while (++i < a.length) {
    var aIsDigit = _isDigit(a.codeUnitAt(i));
    if (++j == b.length) return aIsDigit ? 1 : 0;
    var bIsDigit = _isDigit(b.codeUnitAt(j));
    if (aIsDigit) {
      if (bIsDigit) continue;
      return 1;
    } else if (bIsDigit) {
      return -1;
    } else {
      return 0;
    }
  }
  if (++j < b.length && _isDigit(b.codeUnitAt(j))) {
    return -1;
  }
  return 0;
}

bool _isDigit(int charCode) => (charCode ^ _zero) <= 9;

/// Check if the digit at [index] is continuing a non-zero number.
///
/// If there is no non-zero digits before, then leading zeros at [index]
/// are also ignored when comparing numerically. If there is a non-zero digit
/// before, then zeros at [index] are significant.
bool _isNonZeroNumberSuffix(String string, int index) {
  while (--index >= 0) {
    var char = string.codeUnitAt(index);
    if (char != _zero) return _isDigit(char);
  }
  return false;
}
