// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

const int _kChar_0 = 48;
const int _kChar_9 = 57;
const int _kChar_A = 65;
const int _kChar_Z = 90;
const int _kChar_a = 97;
const int _kChar_z = 122;
const int _kCharBang = 33;

enum _ComparisonResult {
  inside,
  higher,
  lower,
}

/// Each instance of [UnicodeRange] represents a range of unicode characters
/// that are assigned a [CharProperty]. For example, the following snippet:
///
/// ```dart
/// UnicodeRange(0x0041, 0x005A, CharProperty.ALetter);
/// ```
///
/// is saying that all characters between 0x0041 ("A") and 0x005A ("Z") are
/// assigned the property [CharProperty.ALetter].
///
/// Note that the Unicode spec uses inclusive ranges and we are doing the
/// same here.
class UnicodeRange<P> {
  const UnicodeRange(this.start, this.end, this.property);

  final int start;

  final int end;

  final P property;

  /// Compare a [value] to this range.
  ///
  /// The return value is either:
  /// - lower: The value is lower than the range.
  /// - higher: The value is higher than the range
  /// - inside: The value is within the range.
  _ComparisonResult compare(int value) {
    if (value < start) {
      return _ComparisonResult.lower;
    }
    if (value > end) {
      return _ComparisonResult.higher;
    }
    return _ComparisonResult.inside;
  }
}

/// Given a list of [UnicodeRange]s, this class performs efficient lookup
/// to find which range a value falls into.
///
/// The lookup algorithm expects the ranges to have the following constraints:
/// - Be sorted.
/// - No overlap between the ranges.
/// - Gaps between ranges are ok.
///
/// This is used in the context of unicode to find out what property a letter
/// has. The properties are then used to decide word boundaries, line break
/// opportunities, etc.
class UnicodePropertyLookup<P> {
  const UnicodePropertyLookup(this.ranges);

  /// Creates a [UnicodePropertyLookup] from packed line break data.
  factory UnicodePropertyLookup.fromPackedData(
    String packedData,
    int singleRangesCount,
    List<P> propertyEnumValues,
  ) {
    return UnicodePropertyLookup<P>(
      _unpackProperties<P>(packedData, singleRangesCount, propertyEnumValues),
    );
  }

  final List<UnicodeRange<P>> ranges;

  /// Take a [text] and an [index], and returns the property of the character
  /// located at that [index].
  ///
  /// If the [index] is out of range, null will be returned.
  P? find(String? text, int index) {
    if (index < 0 || index >= text!.length) {
      return null;
    }
    return findForChar(text.codeUnitAt(index));
  }

  /// Takes one character as an integer code unit and returns its property.
  ///
  /// If a property can't be found for the given character, null will be
  /// returned.
  P? findForChar(int char) {
    final int rangeIndex = _binarySearch(char);
    return rangeIndex == -1 ? null : ranges[rangeIndex].property;
  }

  int _binarySearch(int value) {
    int min = 0;
    int max = ranges.length;
    while (min < max) {
      final int mid = min + ((max - min) >> 1);
      final UnicodeRange<P> range = ranges[mid];
      switch (range.compare(value)) {
        case _ComparisonResult.higher:
          min = mid + 1;
          break;
        case _ComparisonResult.lower:
          max = mid;
          break;
        case _ComparisonResult.inside:
          return mid;
      }
    }
    return -1;
  }
}

List<UnicodeRange<P>> _unpackProperties<P>(
  String packedData,
  int singleRangesCount,
  List<P> propertyEnumValues,
) {
  // Packed data is mostly structured in chunks of 9 characters each:
  //
  // * [0..3]: Range start, encoded as a base36 integer.
  // * [4..7]: Range end, encoded as a base36 integer.
  // * [8]: Index of the property enum value, encoded as a single letter.
  //
  // When the range is a single number (i.e. range start == range end), it gets
  // packed more efficiently in a chunk of 6 characters:
  //
  // * [0..3]: Range start (and range end), encoded as a base 36 integer.
  // * [4]: "!" to indicate that there's no range end.
  // * [5]: Index of the property enum value, encoded as a single letter.

  // `packedData.length + singleRangesCount * 3` would have been the size of the
  // packed data if the efficient packing of single-range items wasn't applied.
  assert((packedData.length + singleRangesCount * 3) % 9 == 0);

  final List<UnicodeRange<P>> ranges = <UnicodeRange<P>>[];
  final int dataLength = packedData.length;
  int i = 0;
  while (i < dataLength) {
    final int rangeStart = _consumeInt(packedData, i);
    i += 4;

    int rangeEnd;
    if (packedData.codeUnitAt(i) == _kCharBang) {
      rangeEnd = rangeStart;
      i++;
    } else {
      rangeEnd = _consumeInt(packedData, i);
      i += 4;
    }
    final int charCode = packedData.codeUnitAt(i);
    final P property =
        propertyEnumValues[_getEnumIndexFromPackedValue(charCode)];
    i++;

    ranges.add(UnicodeRange<P>(rangeStart, rangeEnd, property));
  }
  return ranges;
}

int _getEnumIndexFromPackedValue(int charCode) {
  // This has to stay in sync with [EnumValue.serialized] in
  // `tool/unicode_sync_script.dart`.

  assert((charCode >= _kChar_A && charCode <= _kChar_Z) ||
      (charCode >= _kChar_a && charCode <= _kChar_z));

  // Uppercase letters were assigned to the first 26 enum values.
  if (charCode <= _kChar_Z) {
    return charCode - _kChar_A;
  }
  // Lowercase letters were assigned to enum values above 26.
  return 26 + charCode - _kChar_a;
}

int _consumeInt(String packedData, int index) {
  // The implementation is equivalent to:
  //
  // ```dart
  // return int.tryParse(packedData.substring(index, index + 4), radix: 36);
  // ```
  //
  // But using substring is slow when called too many times. This custom
  // implementation makes the unpacking 25%-45% faster than using substring.
  final int digit0 = _getIntFromCharCode(packedData.codeUnitAt(index + 3));
  final int digit1 = _getIntFromCharCode(packedData.codeUnitAt(index + 2));
  final int digit2 = _getIntFromCharCode(packedData.codeUnitAt(index + 1));
  final int digit3 = _getIntFromCharCode(packedData.codeUnitAt(index));
  return digit0 + (digit1 * 36) + (digit2 * 36 * 36) + (digit3 * 36 * 36 * 36);
}

/// Does the same thing as [int.parse(str, 36)] but takes only a single
/// character as a [charCode] integer.
int _getIntFromCharCode(int charCode) {
  assert((charCode >= _kChar_0 && charCode <= _kChar_9) ||
      (charCode >= _kChar_a && charCode <= _kChar_z));

  if (charCode <= _kChar_9) {
    return charCode - _kChar_0;
  }
  // "a" starts from 10 and remaining letters go up from there.
  return charCode - _kChar_a + 10;
}
