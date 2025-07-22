// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal"
    show
        CodeUnits,
        ClassID,
        EfficientLengthIterable,
        unsafeCast,
        WasmStringBase;

import 'dart:_error_utils';
import 'dart:_js_helper' show JS, jsStringFromDartString;
import 'dart:_string';
import 'dart:_list';
import 'dart:_object_helper';
import 'dart:_string_helper';
import 'dart:_typed_data';
import 'dart:_wasm';

import "dart:typed_data" show Uint8List, Uint16List;

extension OneByteStringUncheckedOperations on OneByteString {
  @pragma('wasm:prefer-inline')
  int codeUnitAtUnchecked(int index) => _codeUnitAtUnchecked(index);

  @pragma('wasm:prefer-inline')
  String substringUnchecked(int start, int end) =>
      _substringUnchecked(start, end);

  @pragma('wasm:prefer-inline')
  void setUnchecked(int index, int codePoint) => _setAt(index, codePoint);

  @pragma('wasm:prefer-inline')
  WasmArray<WasmI8> get array => _array;
}

extension TwoByteStringUncheckedOperations on TwoByteString {
  @pragma('wasm:prefer-inline')
  int codeUnitAtUnchecked(int index) => _codeUnitAtUnchecked(index);

  @pragma('wasm:prefer-inline')
  String substringUnchecked(int start, int end) =>
      _substringUnchecked(start, end);

  @pragma('wasm:prefer-inline')
  void setUnchecked(int index, int codePoint) => _setAt(index, codePoint);

  @pragma('wasm:prefer-inline')
  WasmArray<WasmI16> get array => _array;
}

/// Static function for `OneByteString._array` to avoid making `_array` public.
@pragma('wasm:prefer-inline')
WasmArray<WasmI8> oneByteStringArray(OneByteString s) => s._array;

/// The [fromStart] and [toStart] indices together with the [length] must
/// specify ranges within the bounds of the list / string.
void copyRangeFromUint8ListToOneByteString(
  Uint8List from,
  OneByteString to,
  int fromStart,
  int toStart,
  int length,
) {
  for (int i = 0; i < length; i++) {
    to._setAt(toStart + i, from[fromStart + i]);
  }
}

@pragma("wasm:prefer-inline")
OneByteString createOneByteStringFromCharacters(
  U8List bytes,
  int start,
  int end,
) => createOneByteStringFromCharactersArray(bytes.data, start, end);

/// Create a [OneByteString] with the [array] contents in the range from
/// [start] to [end] (exclusive).
@pragma("wasm:prefer-inline")
OneByteString createOneByteStringFromCharactersArray(
  WasmArray<WasmI8> array,
  int start,
  int end,
) {
  final len = end - start;
  final s = OneByteString.withLength(len);
  s._array.copy(0, array, start, len);
  return s;
}

/// Same as [createOneByteStringFromCharactersArray], but the one-byte
/// character array is an `i16 array` instead of `i8 array`.
@pragma("wasm:prefer-inline")
OneByteString createOneByteStringFromTwoByteCharactersArray(
  WasmArray<WasmI16> array,
  int start,
  int end,
) {
  final len = end - start;
  final s = OneByteString.withLength(len);
  for (int i = 0; i < len; i += 1) {
    final i16 = array.readUnsigned(start + i);
    s._array.write(i, i16);
  }
  return s;
}

/// Create a [TwoByteString] with the [array] contents in the range from
/// [start] to [end] (exclusive).
@pragma("wasm:prefer-inline")
TwoByteString createTwoByteStringFromCharactersArray(
  WasmArray<WasmI16> array,
  int start,
  int end,
) {
  final len = end - start;
  final s = TwoByteString.withLength(len);
  s._array.copy(0, array, start, len);
  return s;
}

extension OneByteStringUnsafeExtensions on String {
  @pragma('wasm:prefer-inline')
  int oneByteStringCodeUnitAtUnchecked(int index) =>
      unsafeCast<OneByteString>(this)._codeUnitAtUnchecked(index);
}

const int _maxLatin1 = 0xff;
const int _maxUtf16 = 0xffff;

String _toUpperCase(String string) => JSStringImpl(
  JS<WasmExternRef>(
    "s => s.toUpperCase()",
    jsStringFromDartString(string).toExternRef,
  ),
);

String _toLowerCase(String string) => JSStringImpl(
  JS<WasmExternRef>(
    "s => s.toLowerCase()",
    jsStringFromDartString(string).toExternRef,
  ),
);

/**
 * [StringBase] contains common methods used by concrete String
 * implementations, e.g., OneByteString.
 */
abstract final class StringBase extends WasmStringBase
    implements StringUncheckedOperationsBase {
  bool _isWhitespace(int codeUnit);

  // Constants used by replaceAll encoding of string slices between matches.
  // A string slice (start+length) is encoded in a single "Smi" to save memory
  // overhead in the common case.
  // Wasm does not have a Smi type, so the entire 64-bit integer value can
  // be used. Strings are limited to 2^32-1 characters, so using ~32 bits
  // for both is reasonable.
  // Encoding is: -((start << _lengthBits) | length)

  // Number of bits used by length.
  // This is the shift used to encode and decode the start index.
  static const int _lengthBits = 31;
  // The maximal allowed length value in an encoded slice.
  static const int _maxLengthValue = (1 << _lengthBits) - 1;
  // Mask of length in encoded smi value.
  static const int _lengthMask = _maxLengthValue;
  static const int _startBits = _maxUnsignedSmiBits - _lengthBits;
  // Maximal allowed start index value in an encoded slice.
  static const int _maxStartValue = (1 << _startBits) - 1;
  // Size of unsigned "Smi"s, which are all non-negative Wasm integers.
  static const int _maxUnsignedSmiBits = 63;

  int get hashCode {
    int hash = getIdentityHashField(this);
    if (hash != 0) return hash;
    hash = _computeHashCode();
    setIdentityHashField(this, hash);
    return hash;
  }

  int _computeHashCode();

  /**
   * Create the most efficient string representation for specified
   * [charCodes].
   *
   * Only uses the character codes between index [start] and index [end] of
   * `charCodes`. They must satisfy `0 <= start <= end <= charCodes.length`.
   *
   * The [limit] is an upper limit on the character codes in the iterable.
   * It's `null` if unknown.
   */
  static String createFromCharCodes(
    Iterable<int> charCodes,
    int start,
    int? end,
  ) {
    // TODO(srdjan): Also skip copying of wide typed arrays.
    final ccid = ClassID.getID(charCodes);
    if (ccid != ClassID.cidFixedLengthList &&
        ccid != ClassID.cidListBase &&
        ccid != ClassID.cidGrowableList &&
        ccid != ClassID.cidImmutableList) {
      if (charCodes is Uint8List) {
        end = _actualEnd(end, charCodes.length);
        if (start >= end) return "";
        return createOneByteString(charCodes, start, end - start);
      } else if (charCodes is Uint16List) {
        end = _actualEnd(end, charCodes.length);
        if (start >= end) return "";
        for (var i = start; i < end; i++) {
          if (charCodes[i] > _maxLatin1) {
            return TwoByteString.allocateFromTwoByteList(charCodes, start, end);
          }
        }
        return _createFromOneByteCodes(charCodes, start, end);
      } else {
        return _createStringFromIterable(charCodes, start, end);
      }
    }
    end = _actualEnd(end, charCodes.length);
    final len = end - start;
    if (len <= 0) return "";

    final typedCharCodes = unsafeCast<List<int>>(charCodes);

    // The bitwise-or of char codes below 0xFFFF in the input,
    // and of the char codes above - 0x10000.
    // If the result is negative, there was a negative input.
    // If the result is in the range 0x00..0xFF, all inputs were in that range.
    // If the result is in the range 0x100..0xFFFF, either all inputs were in
    // that range, or `multiCodeUnitChars` below is greater than zero.
    // If the result is > 0xFFFFF, the input contained a value > 0x10FFFF,
    // which is invalid.
    int bits = 0;
    // The count of char codes above 0xFFFF in the input.
    // If greater than zero, the char codes cannot directly be used
    // as the content of a one-byte or two-byte string,
    // but must be a two-byte string with this many code units *more* than
    // `end - start` to account for surrogate pairs.
    int multiCodeUnitChars = 0;
    for (var i = start; i < end; i++) {
      var code = typedCharCodes[i];
      var nonBmpCode = code - 0x10000;
      if (nonBmpCode < 0) {
        bits |= code;
        continue;
      }
      bits |= nonBmpCode | 0x10000;
      multiCodeUnitChars += 1;
    }
    // bits < 0 || bits > 0xFFFFF
    if (bits.gtU(0xFFFFF)) {
      throw ArgumentError(typedCharCodes);
    }
    if (multiCodeUnitChars == 0) {
      if (bits <= _maxLatin1) {
        return createOneByteString(typedCharCodes, start, len);
      }
      assert(bits <= _maxUtf16);
      return TwoByteString.allocateFromTwoByteList(typedCharCodes, start, end);
    }
    return _createFromAdjustedCodePoints(
      typedCharCodes,
      start,
      end,
      end - start + multiCodeUnitChars,
    );
  }

  static int _actualEnd(int? end, int length) =>
      (end == null || end > length) ? length : end;

  static String _createStringFromIterable(
    Iterable<int> charCodes,
    int start,
    int? end,
  ) {
    // Treat charCodes as Iterable.
    bool endKnown = false;
    if (charCodes is EfficientLengthIterable) {
      endKnown = true;
      int knownEnd = charCodes.length;
      if (end == null || end > knownEnd) end = knownEnd;
      if (start >= end) return "";
    }

    var it = charCodes.iterator;

    int skipCount = start;
    while (skipCount > 0) {
      if (!it.moveNext()) return "";
      skipCount--;
    }

    // Bitwise-or of all char codes in list,
    // plus code - 0x10000 for values above 0x10000.
    // If <0 or >0xFFFFF at the end, inputs were not valid.
    int bits = 0;
    int takeCount = end == null ? -1 : end - start;
    final list = GrowableList<int>(0);
    while (takeCount != 0 && it.moveNext()) {
      takeCount--;
      int code = it.current;
      int nonBmpChar = code - 0x10000;
      if (nonBmpChar < 0) {
        bits |= code;
        list.add(code);
      } else {
        bits |= nonBmpChar | 0xD800;
        list
          ..add(0xD800 | (nonBmpChar >> 10))
          ..add(0xDC00 | (nonBmpChar & 0x3FF));
      }
    }
    // bits < 0 || bits > 0xFFFFF
    if (bits.gtU(0xFFFFF)) {
      throw ArgumentError(charCodes);
    }
    final int length = list.length;
    final bool isOneByteString = (bits <= _maxLatin1);
    if (isOneByteString) {
      final charCodeList = WasmArray<WasmI8>(length);
      for (int i = 0; i < length; ++i) charCodeList.write(i, list[i]);
      return OneByteString.withData(charCodeList);
    }
    final charCodeList = WasmArray<WasmI16>(length);
    for (int i = 0; i < length; ++i) charCodeList.write(i, list[i]);
    return TwoByteString.withData(charCodeList);
  }

  static String createOneByteString(List<int> charCodes, int start, int len) {
    var s = OneByteString.withLength(len);

    // Special case for native Uint8 typed arrays.
    if (charCodes is Uint8List) {
      copyRangeFromUint8ListToOneByteString(charCodes, s, start, 0, len);
      return s;
    }

    // Fall through to normal case.
    for (int i = 0; i < len; i++) {
      s._setAt(i, charCodes[start + i]);
    }
    return s;
  }

  static String _createFromOneByteCodes(
    List<int> charCodes,
    int start,
    int end,
  ) {
    OneByteString result = OneByteString.withLength(end - start);
    for (int i = start; i < end; i++) {
      result._setAt(i - start, charCodes[i]);
    }
    return result;
  }

  /// Creates two-byte string for [codePoints] from [start] to [end].
  ///
  /// The code points contain a number of code points above 0xFFFF,
  /// `length - (end - start)` of them, which is why they require
  /// a two-byte string of length [length].
  static String _createFromAdjustedCodePoints(
    List<int> codePoints,
    int start,
    int end,
    int length,
  ) {
    assert(length > end - start);
    TwoByteString result = TwoByteString.withLength(length);
    int cursor = 0;
    for (int i = start; i < end; i++) {
      var code = codePoints[i];
      var nonBmpCode = code - 0x10000;
      if (nonBmpCode < 0) {
        result._setAt(cursor++, code);
      } else {
        result
          .._setAt(cursor++, 0xD800 | (nonBmpCode >>> 10))
          .._setAt(cursor++, 0xDC00 | (nonBmpCode & 0x3FF));
      }
    }
    if (cursor != length) {
      throw ConcurrentModificationError(codePoints);
    }
    return result;
  }

  String operator [](int index) => String.fromCharCode(codeUnitAt(index));

  @pragma('wasm:prefer-inline')
  @pragma('wasm:static-dispatch')
  bool get isEmpty {
    return this.length == 0;
  }

  @pragma('wasm:prefer-inline')
  @pragma('wasm:static-dispatch')
  bool get isNotEmpty => !isEmpty;

  String operator +(String other) {
    return _interpolate(WasmArray<Object?>.literal([this, other]));
  }

  String toString() {
    return this;
  }

  int compareTo(String other) {
    int thisLength = this.length;
    int otherLength = other.length;
    int len = (thisLength < otherLength) ? thisLength : otherLength;
    for (int i = 0; i < len; i++) {
      int thisCodeUnit = this.codeUnitAt(i);
      int otherCodeUnit = other.codeUnitAt(i);
      if (thisCodeUnit < otherCodeUnit) {
        return -1;
      }
      if (thisCodeUnit > otherCodeUnit) {
        return 1;
      }
    }
    if (thisLength < otherLength) return -1;
    if (thisLength > otherLength) return 1;
    return 0;
  }

  bool _substringMatches(int start, String other) {
    if (other.isEmpty) return true;
    final len = other.length;
    if ((start < 0) || (start + len > this.length)) {
      return false;
    }
    for (int i = 0; i < len; i++) {
      if (this.codeUnitAt(i + start) != other.codeUnitAt(i)) {
        return false;
      }
    }
    return true;
  }

  bool endsWith(String other) {
    return _substringMatches(this.length - other.length, other);
  }

  bool startsWith(Pattern pattern, [int index = 0]) {
    // index < 0 || index > length
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(index, this.length);
    if (pattern is String) {
      return _substringMatches(index, pattern);
    }
    return pattern.matchAsPrefix(this, index) != null;
  }

  int indexOf(Pattern pattern, [int start = 0]) {
    // start < 0 || start > length
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      start,
      this.length,
      "start",
    );
    if (pattern is String) {
      String other = pattern;
      int maxIndex = this.length - other.length;
      // TODO: Use an efficient string search (e.g. BMH).
      for (int index = start; index <= maxIndex; index++) {
        if (_substringMatches(index, other)) {
          return index;
        }
      }
      return -1;
    }
    for (int i = start; i <= this.length; i++) {
      // TODO(11276); This has quadratic behavior because matchAsPrefix tries
      // to find a later match too. Optimize matchAsPrefix to avoid this.
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  int lastIndexOf(Pattern pattern, [int? start]) {
    if (start == null) {
      start = this.length;
    } else {
      // start < 0 || start > length
      RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, this.length);
    }
    if (pattern is String) {
      String other = pattern;
      int maxIndex = this.length - other.length;
      if (maxIndex < start) start = maxIndex;
      for (int index = start; index >= 0; index--) {
        if (_substringMatches(index, other)) {
          return index;
        }
      }
      return -1;
    }
    for (int i = start; i >= 0; i--) {
      // TODO(11276); This has quadratic behavior because matchAsPrefix tries
      // to find a later match too. Optimize matchAsPrefix to avoid this.
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  String substring(int startIndex, [int? endIndex]) {
    endIndex = RangeErrorUtils.checkValidRange(startIndex, endIndex, length);
    return _substringUnchecked(startIndex, endIndex);
  }

  String _substringUnchecked(int startIndex, int endIndex) {
    assert((startIndex >= 0) && (startIndex <= this.length));
    assert((endIndex >= 0) && (endIndex <= this.length));
    assert(startIndex <= endIndex);

    if (startIndex == endIndex) {
      return "";
    }
    if ((startIndex == 0) && (endIndex == this.length)) {
      return this;
    }
    if ((startIndex + 1) == endIndex) {
      return this[startIndex];
    }
    return _substringUncheckedInternal(startIndex, endIndex);
  }

  String _substringUncheckedInternal(int startIndex, int endIndex);

  // Checks for one-byte whitespaces only.
  static bool _isOneByteWhitespace(int codeUnit) {
    if (codeUnit <= 32) {
      return ((codeUnit == 32) || // Space.
          ((codeUnit <= 13) && (codeUnit >= 9))); // CR, LF, TAB, etc.
    }
    return (codeUnit == 0x85) || (codeUnit == 0xA0); // NEL, NBSP.
  }

  // Characters with Whitespace property (Unicode 6.3).
  // 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
  // 0020          ; White_Space # Zs       SPACE
  // 0085          ; White_Space # Cc       <control-0085>
  // 00A0          ; White_Space # Zs       NO-BREAK SPACE
  // 1680          ; White_Space # Zs       OGHAM SPACE MARK
  // 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
  // 2028          ; White_Space # Zl       LINE SEPARATOR
  // 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
  // 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
  // 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
  // 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
  //
  // BOM: 0xFEFF
  static bool _isTwoByteWhitespace(int codeUnit) {
    if (codeUnit <= 32) {
      return (codeUnit == 32) || ((codeUnit <= 13) && (codeUnit >= 9));
    }
    if (codeUnit < 0x85) return false;
    if ((codeUnit == 0x85) || (codeUnit == 0xA0)) return true;
    return (codeUnit <= 0x200A)
        ? ((codeUnit == 0x1680) || (0x2000 <= codeUnit))
        : ((codeUnit == 0x2028) ||
            (codeUnit == 0x2029) ||
            (codeUnit == 0x202F) ||
            (codeUnit == 0x205F) ||
            (codeUnit == 0x3000) ||
            (codeUnit == 0xFEFF));
  }

  int firstNonWhitespace() {
    final len = this.length;
    int first = 0;
    for (; first < len; first++) {
      if (!_isWhitespace(codeUnitAtUnchecked(first))) {
        break;
      }
    }
    return first;
  }

  int lastNonWhitespace() {
    int last = this.length - 1;
    for (; last >= 0; last--) {
      if (!_isWhitespace(codeUnitAtUnchecked(last))) {
        break;
      }
    }
    return last;
  }

  String trim() {
    final len = this.length;
    int first = firstNonWhitespace();
    if (len == first) {
      // String contains only whitespaces.
      return "";
    }
    int last = lastNonWhitespace() + 1;
    if ((first == 0) && (last == len)) {
      // Returns this string since it does not have leading or trailing
      // whitespaces.
      return this;
    }
    return _substringUnchecked(first, last);
  }

  String trimLeft() {
    final len = this.length;
    int first = 0;
    for (; first < len; first++) {
      if (!_isWhitespace(this.codeUnitAt(first))) {
        break;
      }
    }
    if (len == first) {
      // String contains only whitespaces.
      return "";
    }
    if (first == 0) {
      // Returns this string since it does not have leading or trailing
      // whitespaces.
      return this;
    }
    return _substringUnchecked(first, len);
  }

  String trimRight() {
    final len = this.length;
    int last = len - 1;
    for (; last >= 0; last--) {
      if (!_isWhitespace(this.codeUnitAt(last))) {
        break;
      }
    }
    if (last == -1) {
      // String contains only whitespaces.
      return "";
    }
    if (last == (len - 1)) {
      // Returns this string since it does not have trailing whitespaces.
      return this;
    }
    return _substringUnchecked(0, last + 1);
  }

  String operator *(int times) {
    if (times <= 0) return "";
    if (times == 1) return this;
    StringBuffer buffer = StringBuffer(this);
    for (int i = 1; i < times; i++) {
      buffer.write(this);
    }
    return buffer.toString();
  }

  String padLeft(int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < delta; i++) {
      buffer.write(padding);
    }
    buffer.write(this);
    return buffer.toString();
  }

  String padRight(int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    StringBuffer buffer = StringBuffer(this);
    for (int i = 0; i < delta; i++) {
      buffer.write(padding);
    }
    return buffer.toString();
  }

  bool contains(Pattern pattern, [int startIndex = 0]) {
    if (pattern is String) {
      // startIndex < 0 || startIndex > length
      RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(startIndex, length);
      return indexOf(pattern, startIndex) >= 0;
    }
    return pattern.allMatches(this.substring(startIndex)).isNotEmpty;
  }

  String replaceFirst(
    Pattern pattern,
    String replacement, [
    int startIndex = 0,
  ]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      startIndex,
      length,
      "startIndex",
    );
    Iterator iterator =
        startIndex == 0
            ? pattern.allMatches(this).iterator
            : pattern.allMatches(this, startIndex).iterator;
    if (!iterator.moveNext()) return this;
    Match match = iterator.current;
    return replaceRange(match.start, match.end, replacement);
  }

  String replaceRange(int start, int? end, String replacement) {
    final length = this.length;
    end = RangeErrorUtils.checkValidRange(start, end, length);
    bool replacementIsOneByte = replacement is OneByteString;
    if (start == 0 && end == length) return replacement;
    int replacementLength = replacement.length;
    int totalLength = start + (length - end) + replacementLength;
    if (replacementIsOneByte && this is OneByteString) {
      final this_ = unsafeCast<OneByteString>(this);
      final result = OneByteString.withLength(totalLength);
      int index = 0;
      index = result._setRange(index, this_, 0, start);
      index = result._setRange(
        start,
        unsafeCast<OneByteString>(replacement),
        0,
        replacementLength,
      );
      result._setRange(index, this_, end, length);
      return result;
    }
    List slices = [];
    _addReplaceSlice(slices, 0, start);
    if (replacement.length > 0) slices.add(replacement);
    _addReplaceSlice(slices, end, length);
    return _joinReplaceAllResult(
      this,
      slices,
      totalLength,
      replacementIsOneByte,
    );
  }

  static int _addReplaceSlice(List matches, int start, int end) {
    int length = end - start;
    if (length > 0) {
      if (length <= _maxLengthValue && start <= _maxStartValue) {
        matches.add(-((start << _lengthBits) | length));
      } else {
        matches.add(start);
        matches.add(end);
      }
    }
    return length;
  }

  String replaceAll(Pattern pattern, String replacement) {
    int startIndex = 0;
    // String fragments that replace the prefix [this] up to [startIndex].
    List matches = [];
    int length = 0; // Length of all fragments.
    int replacementLength = replacement.length;

    if (replacementLength == 0) {
      for (Match match in pattern.allMatches(this)) {
        length += _addReplaceSlice(matches, startIndex, match.start);
        startIndex = match.end;
      }
    } else {
      for (Match match in pattern.allMatches(this)) {
        length += _addReplaceSlice(matches, startIndex, match.start);
        matches.add(replacement);
        length += replacementLength;
        startIndex = match.end;
      }
    }
    // No match, or a zero-length match at start with zero-length replacement.
    if (startIndex == 0 && length == 0) return this;
    length += _addReplaceSlice(matches, startIndex, this.length);
    bool replacementIsOneByte = replacement is OneByteString;
    if (replacementIsOneByte && this is OneByteString) {
      return _joinReplaceAllOneByteResult(this, matches, length);
    }
    return _joinReplaceAllResult(this, matches, length, replacementIsOneByte);
  }

  /**
   * As [_joinReplaceAllResult], but knowing that the result
   * is always a [OneByteString].
   */
  static String _joinReplaceAllOneByteResult(
    String base,
    List matches,
    int length,
  ) {
    OneByteString result = OneByteString.withLength(length);
    int writeIndex = 0;
    for (int i = 0; i < matches.length; i++) {
      var entry = matches[i];
      if (entry is int) {
        int sliceStart = entry;
        int sliceEnd;
        if (sliceStart < 0) {
          int bits = -sliceStart;
          int sliceLength = bits & _lengthMask;
          sliceStart = bits >> _lengthBits;
          sliceEnd = sliceStart + sliceLength;
        } else {
          i++;
          // This function should only be called with valid matches lists.
          // If the list is short, or sliceEnd is not an integer, one of
          // the next few lines will throw anyway.
          assert(i < matches.length);
          sliceEnd = matches[i];
        }
        for (int j = sliceStart; j < sliceEnd; j++) {
          result._setAt(writeIndex++, base.codeUnitAt(j));
        }
      } else {
        // Replacement is a one-byte string.
        String replacement = entry;
        for (int j = 0; j < replacement.length; j++) {
          result._setAt(writeIndex++, replacement.codeUnitAt(j));
        }
      }
    }
    assert(writeIndex == length);
    return result;
  }

  /**
   * Combine the results of a [replaceAll] match into a string.
   *
   * The [matches] lists contains Smi index pairs representing slices of
   * [base] and [String]s to be put in between the slices.
   *
   * The total [length] of the resulting string is known, as is
   * whether the replacement strings are one-byte strings.
   * If they are, then we have to check the base string slices to know
   * whether the result must be a one-byte string.
   */
  String _joinReplaceAllResult(
    String base,
    List matches,
    int length,
    bool replacementStringsAreOneByte,
  ) {
    if (length < 0) throw ArgumentError.value(length);
    bool isOneByte =
        replacementStringsAreOneByte &&
        _slicesAreOneByte(base, matches, length);
    if (isOneByte) {
      return _joinReplaceAllOneByteResult(base, matches, length);
    }
    TwoByteString result = TwoByteString.withLength(length);
    int writeIndex = 0;
    for (int i = 0; i < matches.length; i++) {
      var entry = matches[i];
      if (entry is int) {
        int sliceStart = entry;
        int sliceEnd;
        if (sliceStart < 0) {
          int bits = -sliceStart;
          int sliceLength = bits & _lengthMask;
          sliceStart = bits >> _lengthBits;
          sliceEnd = sliceStart + sliceLength;
        } else {
          i++;
          // This function should only be called with valid matches lists.
          // If the list is short, or sliceEnd is not an integer, one of
          // the next few lines will throw anyway.
          assert(i < matches.length);
          sliceEnd = matches[i];
        }
        for (int j = sliceStart; j < sliceEnd; j++) {
          result._setAt(writeIndex++, base.codeUnitAt(j));
        }
      } else {
        // Replacement is a one-byte string.
        String replacement = entry;
        for (int j = 0; j < replacement.length; j++) {
          result._setAt(writeIndex++, replacement.codeUnitAt(j));
        }
      }
    }
    assert(writeIndex == length);
    return result;
  }

  bool _slicesAreOneByte(String base, List matches, int length) {
    for (int i = 0; i < matches.length; i++) {
      Object? o = matches[i];
      if (o is int) {
        int sliceStart = o;
        int sliceEnd;
        if (sliceStart < 0) {
          int bits = -sliceStart;
          int sliceLength = bits & _lengthMask;
          sliceStart = bits >> _lengthBits;
          sliceEnd = sliceStart + sliceLength;
        } else {
          i++;
          if (i >= length) {
            // Invalid, handled later.
            return false;
          }
          Object? p = matches[i];
          if (p is! int) {
            // Invalid, handled later.
            return false;
          }
          sliceEnd = p;
        }
        for (int j = sliceStart; j < sliceEnd; j++) {
          if (base.codeUnitAt(j) > 0xff) {
            return false;
          }
        }
      }
    }
    return true;
  }

  String replaceAllMapped(Pattern pattern, String replace(Match match)) {
    List matches = [];
    int length = 0;
    int startIndex = 0;
    bool replacementStringsAreOneByte = true;
    for (Match match in pattern.allMatches(this)) {
      length += _addReplaceSlice(matches, startIndex, match.start);
      var replacement = "${replace(match)}";
      matches.add(replacement);
      length += replacement.length;
      replacementStringsAreOneByte =
          replacementStringsAreOneByte && replacement is OneByteString;
      startIndex = match.end;
    }
    if (matches.isEmpty) return this;
    length += _addReplaceSlice(matches, startIndex, this.length);
    if (replacementStringsAreOneByte && this is OneByteString) {
      return _joinReplaceAllOneByteResult(this, matches, length);
    }
    return _joinReplaceAllResult(
      this,
      matches,
      length,
      replacementStringsAreOneByte,
    );
  }

  String replaceFirstMapped(
    Pattern pattern,
    String replace(Match match), [
    int startIndex = 0,
  ]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      startIndex,
      length,
      "startIndex",
    );

    var matches = pattern.allMatches(this, startIndex).iterator;
    if (!matches.moveNext()) return this;
    var match = matches.current;
    var replacement = "${replace(match)}";
    return replaceRange(match.start, match.end, replacement);
  }

  static String _matchString(Match match) => match[0]!;
  static String _stringIdentity(String string) => string;

  String _splitMapJoinEmptyString(
    String onMatch(Match match),
    String onNonMatch(String nonMatch),
  ) {
    // Pattern is the empty string.
    StringBuffer buffer = StringBuffer();
    int length = this.length;
    int i = 0;
    buffer.write(onNonMatch(""));
    while (i < length) {
      buffer.write(onMatch(StringMatch(i, this, "")));
      // Special case to avoid splitting a surrogate pair.
      int code = this.codeUnitAt(i);
      if ((code & ~0x3FF) == 0xD800 && length > i + 1) {
        // Leading surrogate;
        code = this.codeUnitAt(i + 1);
        if ((code & ~0x3FF) == 0xDC00) {
          // Matching trailing surrogate.
          buffer.write(onNonMatch(this.substring(i, i + 2)));
          i += 2;
          continue;
        }
      }
      buffer.write(onNonMatch(this[i]));
      i++;
    }
    buffer.write(onMatch(StringMatch(i, this, "")));
    buffer.write(onNonMatch(""));
    return buffer.toString();
  }

  String splitMapJoin(
    Pattern pattern, {
    String onMatch(Match match)?,
    String onNonMatch(String nonMatch)?,
  }) {
    onMatch ??= _matchString;
    onNonMatch ??= _stringIdentity;
    if (pattern is String) {
      String stringPattern = pattern;
      if (stringPattern.isEmpty) {
        return _splitMapJoinEmptyString(onMatch, onNonMatch);
      }
    }
    StringBuffer buffer = StringBuffer();
    int startIndex = 0;
    for (Match match in pattern.allMatches(this)) {
      buffer.write(onNonMatch(this.substring(startIndex, match.start)));
      buffer.write(onMatch(match).toString());
      startIndex = match.end;
    }
    buffer.write(onNonMatch(this.substring(startIndex)));
    return buffer.toString();
  }

  // Used in string interpolation expressions where ownership of array is passed
  // to this function.
  //
  // It special cases all [OneByteString]s. We could also special case all
  // [TwoByteString] & all [JSStringImpl] cases.
  @pragma("wasm:entry-point", "call")
  static String _interpolate(final WasmArray<Object?> values) {
    int totalLength = 0;
    bool isOneByteString = true;
    final numValues = values.length;
    for (int i = 0; i < numValues; ++i) {
      final value = values[i];
      var stringValue = value is String ? value : value.toString();
      values[i] = stringValue;
      isOneByteString = isOneByteString && stringValue is OneByteString;
      totalLength += stringValue.length;
    }
    if (isOneByteString) {
      return OneByteString._concatAll(values, totalLength);
    }
    return StringBase._concatAllFallback(values, totalLength);
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate1(Object? value) {
    return value is String ? value : value.toString();
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate2(Object? value1, Object? value2) {
    final String string1 = value1 is String ? value1 : value1.toString();
    final String string2 = value2 is String ? value2 : value2.toString();
    if (string1 is OneByteString && string2 is OneByteString) {
      return OneByteString._concat2(string1, string2);
    }
    return StringBase._interpolate(
      WasmArray<Object?>.literal([string1, string2]),
    );
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate3(Object? value1, Object? value2, Object? value3) {
    final String string1 = value1 is String ? value1 : value1.toString();
    final String string2 = value2 is String ? value2 : value2.toString();
    final String string3 = value3 is String ? value3 : value3.toString();
    if (string1 is OneByteString &&
        string2 is OneByteString &&
        string3 is OneByteString) {
      return OneByteString._concat3(string1, string2, string3);
    }
    return StringBase._interpolate(
      WasmArray<Object?>.literal([string1, string2, string3]),
    );
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate4(
    Object? value1,
    Object? value2,
    Object? value3,
    Object? value4,
  ) {
    final String string1 = value1 is String ? value1 : value1.toString();
    final String string2 = value2 is String ? value2 : value2.toString();
    final String string3 = value3 is String ? value3 : value3.toString();
    final String string4 = value4 is String ? value4 : value4.toString();
    if (string1 is OneByteString &&
        string2 is OneByteString &&
        string3 is OneByteString &&
        string4 is OneByteString) {
      return OneByteString._concat4(string1, string2, string3, string4);
    }
    return StringBase._interpolate(
      WasmArray<Object?>.literal([string1, string2, string3, string4]),
    );
  }

  @pragma('wasm:entry-point')
  static bool _equals(String left, String? right) {
    return left == right;
  }

  static ArgumentError _interpolationError(Object? o, Object? result) {
    // Since Dart 2.0, [result] can only be null.
    return ArgumentError.value(o, "object", "toString method returned 'null'");
  }

  Iterable<Match> allMatches(String string, [int start = 0]) {
    // start < 0 || start > string.length
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      start,
      string.length,
      "start",
    );
    return StringAllMatchesIterable(string, this, start);
  }

  Match? matchAsPrefix(String string, [int start = 0]) {
    // start < 0 || start > string.length
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      start,
      string.length,
      "start",
    );
    if (start + this.length > string.length) return null;
    for (int i = 0; i < this.length; i++) {
      if (string.codeUnitAt(start + i) != this.codeUnitAt(i)) {
        return null;
      }
    }
    return StringMatch(start, string, this);
  }

  List<String> split(Pattern pattern) {
    if ((pattern is String) && pattern.isEmpty) {
      List<String> result = List<String>.generate(
        this.length,
        (int i) => this[i],
      );
      return result;
    }
    int length = this.length;
    Iterator iterator = pattern.allMatches(this).iterator;
    if (length == 0 && iterator.moveNext()) {
      // A matched empty string input returns the empty list.
      return <String>[];
    }
    List<String> result = <String>[];
    int startIndex = 0;
    int previousIndex = 0;
    // 'pattern' may not be implemented correctly and therefore we cannot
    // call _substringUnchecked unless it is a trustworthy type (e.g. String).
    while (true) {
      if (startIndex == length || !iterator.moveNext()) {
        result.add(this.substring(previousIndex, length));
        break;
      }
      Match match = iterator.current;
      if (match.start == length) {
        result.add(this.substring(previousIndex, length));
        break;
      }
      int endIndex = match.end;
      if (startIndex == endIndex && endIndex == previousIndex) {
        ++startIndex; // empty match, advance and restart
        continue;
      }
      result.add(this.substring(previousIndex, match.start));
      startIndex = previousIndex = endIndex;
    }
    return result;
  }

  List<int> get codeUnits => CodeUnits(this);

  Runes get runes => Runes(this);

  String toUpperCase() => _toUpperCase(this);

  String toLowerCase() => _toLowerCase(this);

  // To be called if not all of the given [StringBase] strings are
  // [OneByteString]s.
  static String _concatAllFallback(
    WasmArray<Object?> strings,
    int totalLength,
  ) {
    final result = TwoByteString.withLength(totalLength);
    int offset = 0;
    for (int i = 0; i < strings.length; i++) {
      final s = unsafeCast<StringBase>(strings[i]);
      offset = s._copyIntoTwoByteString(result, offset);
    }
    return result;
  }

  // Concatenate ['start', 'end'[ elements of 'strings'.
  //
  // It special cases all [OneByteString]s. We could also special case all
  // [TwoByteString] & all [JSStringImpl] cases.
  static String concatRange(WasmArray<String> strings, int start, int end) {
    if ((end - start) == 1) {
      return strings[start];
    }
    int totalLength = 0;
    bool isOneByteString = true;
    for (int i = start; i < end; i++) {
      String stringValue = strings[i];
      isOneByteString = isOneByteString && stringValue is OneByteString;
      totalLength += stringValue.length;
    }
    if (isOneByteString) {
      return OneByteString._concatRange(strings, start, end, totalLength);
    }
    return _concatRangeFallback(strings, start, end, totalLength);
  }

  // To be called if not all strings are [OneByteString]s.
  static String _concatRangeFallback(
    WasmArray<String> strings,
    int start,
    int end,
    int totalLength,
  ) {
    final result = TwoByteString.withLength(totalLength);
    int offset = 0;
    for (int i = start; i < end; i++) {
      final s = unsafeCast<StringBase>(strings[i]);
      offset = s._copyIntoTwoByteString(result, offset);
    }
    return result;
  }

  static bool _operatorEqualsFallback(String a, String b) {
    final length = a.length;
    if (length != b.length) return false;
    for (int i = 0; i < length; ++i) {
      if (a.codeUnitAt(i) != b.codeUnitAt(i)) return false;
    }
    return true;
  }

  int _copyIntoTwoByteString(TwoByteString result, int offset);
}

@pragma("wasm:entry-point")
final class OneByteString extends StringBase {
  @pragma("wasm:entry-point")
  final WasmArray<WasmI8> _array;

  @pragma("wasm:prefer-inline")
  OneByteString.withLength(int length) : _array = WasmArray<WasmI8>(length);

  @pragma("wasm:prefer-inline")
  OneByteString.withData(this._array);

  // Same hash as VM
  @override
  int _computeHashCode() {
    WasmArray<WasmI8> array = _array;
    int length = array.length;
    int hash = 0;
    for (int i = 0; i < length; i++) {
      hash = stringCombineHashes(hash, array.readUnsigned(i));
    }
    return stringFinalizeHash(hash);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! String) return false;

    if (other is OneByteString) {
      final thisBytes = _array;
      final otherBytes = other._array;
      if (thisBytes.length != otherBytes.length) return false;
      for (int i = 0; i < thisBytes.length; ++i) {
        if (thisBytes[i] != otherBytes[i]) return false;
      }
      return true;
    }

    return StringBase._operatorEqualsFallback(this, other);
  }

  @override
  @pragma('wasm:prefer-inline')
  @pragma('wasm:static-dispatch')
  int _codeUnitAtUnchecked(int index) => _array.readUnsigned(index);

  @override
  @pragma('wasm:prefer-inline')
  @pragma('wasm:static-dispatch')
  int codeUnitAt(int index) {
    IndexErrorUtils.checkIndexBCE(index, length);
    return _codeUnitAtUnchecked(index);
  }

  @override
  @pragma('wasm:prefer-inline')
  @pragma('wasm:static-dispatch')
  int get length => _array.length;

  @override
  bool _isWhitespace(int codeUnit) {
    return StringBase._isOneByteWhitespace(codeUnit);
  }

  @override
  String _substringUncheckedInternal(int startIndex, int endIndex) {
    final length = endIndex - startIndex;
    final result = OneByteString.withLength(length);
    result._array.copy(0, _array, startIndex, length);
    return result;
  }

  List<String> _splitWithCharCode(int charCode) {
    final parts = <String>[];
    int i = 0;
    int start = 0;
    for (i = 0; i < this.length; ++i) {
      if (this._codeUnitAtUnchecked(i) == charCode) {
        parts.add(this._substringUnchecked(start, i));
        start = i + 1;
      }
    }
    parts.add(this._substringUnchecked(start, i));
    return parts;
  }

  List<String> split(Pattern pattern) {
    if (pattern is OneByteString && pattern.length == 1) {
      return _splitWithCharCode(pattern.codeUnitAt(0));
    }
    return super.split(pattern);
  }

  // All element of 'strings' must be OneByteStrings.
  static OneByteString _concatAll(WasmArray<Object?> strings, int totalLength) {
    final result = OneByteString.withLength(totalLength);
    final resultBytes = result._array;
    int resultOffset = 0;
    for (int i = 0; i < strings.length; i++) {
      final bytes = unsafeCast<OneByteString>(strings[i])._array;
      resultBytes.copy(resultOffset, bytes, 0, bytes.length);
      resultOffset += bytes.length;
    }
    return result;
  }

  static OneByteString _concat2(OneByteString string1, OneByteString string2) {
    final bytes1 = string1._array;
    final bytes2 = string2._array;

    final result = OneByteString.withLength(bytes1.length + bytes2.length);
    final resultBytes = result._array;

    int resultOffset = 0;
    resultBytes.copy(resultOffset, bytes1, 0, bytes1.length);
    resultOffset += bytes1.length;
    resultBytes.copy(resultOffset, bytes2, 0, bytes2.length);

    return result;
  }

  static OneByteString _concat3(
    OneByteString string1,
    OneByteString string2,
    OneByteString string3,
  ) {
    final bytes1 = string1._array;
    final bytes2 = string2._array;
    final bytes3 = string3._array;

    final result = OneByteString.withLength(
      bytes1.length + bytes2.length + bytes3.length,
    );
    final resultBytes = result._array;

    int resultOffset = 0;
    resultBytes.copy(resultOffset, bytes1, 0, bytes1.length);
    resultOffset += bytes1.length;
    resultBytes.copy(resultOffset, bytes2, 0, bytes2.length);
    resultOffset += bytes2.length;
    resultBytes.copy(resultOffset, bytes3, 0, bytes3.length);

    return result;
  }

  static OneByteString _concat4(
    OneByteString string1,
    OneByteString string2,
    OneByteString string3,
    OneByteString string4,
  ) {
    final bytes1 = string1._array;
    final bytes2 = string2._array;
    final bytes3 = string3._array;
    final bytes4 = string4._array;

    final result = OneByteString.withLength(
      bytes1.length + bytes2.length + bytes3.length + bytes4.length,
    );
    final resultBytes = result._array;

    int resultOffset = 0;
    resultBytes.copy(resultOffset, bytes1, 0, bytes1.length);
    resultOffset += bytes1.length;
    resultBytes.copy(resultOffset, bytes2, 0, bytes2.length);
    resultOffset += bytes2.length;
    resultBytes.copy(resultOffset, bytes3, 0, bytes3.length);
    resultOffset += bytes3.length;
    resultBytes.copy(resultOffset, bytes4, 0, bytes4.length);

    return result;
  }

  // All element of 'strings' must be OneByteStrings.
  static OneByteString _concatRange(
    WasmArray<String> strings,
    int start,
    int end,
    int totalLength,
  ) {
    final result = OneByteString.withLength(totalLength);
    final resultBytes = result._array;
    int resultOffset = 0;
    for (int i = start; i < end; i++) {
      final bytes = unsafeCast<OneByteString>(strings[i])._array;
      resultBytes.copy(resultOffset, bytes, 0, bytes.length);
      resultOffset += bytes.length;
    }
    return result;
  }

  @override
  int _copyIntoTwoByteString(TwoByteString result, int offset) {
    final from = _array;
    final int length = from.length;
    final to = result._array;
    int j = offset;
    for (int i = 0; i < length; i++) {
      to.write(j++, from.readUnsigned(i));
    }
    return j;
  }

  int indexOf(Pattern pattern, [int start = 0]) {
    final len = this.length;
    // Specialize for single character pattern.
    if (pattern is String && pattern.length == 1 && start >= 0 && start < len) {
      final patternCu0 = pattern.codeUnitAt(0);
      if (patternCu0 > 0xFF) {
        return -1;
      }
      for (int i = start; i < len; i++) {
        if (this._codeUnitAtUnchecked(i) == patternCu0) {
          return i;
        }
      }
      return -1;
    }
    return super.indexOf(pattern, start);
  }

  bool contains(Pattern pattern, [int start = 0]) {
    final len = this.length;
    if (pattern is String && pattern.length == 1 && start >= 0 && start < len) {
      final patternCu0 = pattern.codeUnitAt(0);
      if (patternCu0 > 0xFF) {
        return false;
      }
      for (int i = start; i < len; i++) {
        if (this._codeUnitAtUnchecked(i) == patternCu0) {
          return true;
        }
      }
      return false;
    }
    return super.contains(pattern, start);
  }

  String operator *(int times) {
    if (times <= 0) return "";
    if (times == 1) return this;
    final int length = this.length;
    if (length == 0) return this; // Don't clone empty string.
    final OneByteString result = OneByteString.withLength(length * times);
    final WasmArray<WasmI8> array = result._array;
    for (int i = 0; i < times; i++) {
      array.copy(i * length, _array, 0, length);
    }
    return result;
  }

  String padLeft(int width, [String padding = ' ']) {
    if (padding is! OneByteString) {
      return super.padLeft(width, padding);
    }
    final length = this.length;
    int delta = width - length;
    if (delta <= 0) return this;
    int padLength = padding.length;
    int resultLength = padLength * delta + length;
    OneByteString result = OneByteString.withLength(resultLength);
    int index = 0;
    if (padLength == 1) {
      int padChar = padding.codeUnitAt(0);
      for (int i = 0; i < delta; i++) {
        result._setAt(index++, padChar);
      }
    } else {
      for (int i = 0; i < delta; i++) {
        for (int j = 0; j < padLength; j++) {
          result._setAt(index++, padding.codeUnitAt(j));
        }
      }
    }
    for (int i = 0; i < length; i++) {
      result._setAt(index++, this._codeUnitAtUnchecked(i));
    }
    return result;
  }

  String padRight(int width, [String padding = ' ']) {
    if (padding is! OneByteString) {
      return super.padRight(width, padding);
    }
    final length = this.length;
    int delta = width - length;
    if (delta <= 0) return this;
    int padLength = padding.length;
    int resultLength = length + padLength * delta;
    OneByteString result = OneByteString.withLength(resultLength);
    int index = 0;
    for (int i = 0; i < length; i++) {
      result._setAt(index++, this._codeUnitAtUnchecked(i));
    }
    if (padLength == 1) {
      int padChar = padding.codeUnitAt(0);
      for (int i = 0; i < delta; i++) {
        result._setAt(index++, padChar);
      }
    } else {
      for (int i = 0; i < delta; i++) {
        for (int j = 0; j < padLength; j++) {
          result._setAt(index++, padding.codeUnitAt(j));
        }
      }
    }
    return result;
  }

  // Lower-case conversion table for Latin-1 as string.
  // Upper-case ranges: 0x41-0x5a ('A' - 'Z'), 0xc0-0xd6, 0xd8-0xde.
  // Conversion to lower case performed by adding 0x20.
  static const _LC_TABLE = ImmutableWasmArray<WasmI8>.literal([
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, //
    0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, //
    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, //
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, //
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, //
    0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, //
    0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, //
    0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, //
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, //
    0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, //
    0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83, //
    0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, //
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, //
    0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, //
    0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, //
    0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf, //
    0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, //
    0xec, 0xed, 0xee, 0xef, 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xd7, //
    0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xdf, 0xe0, 0xe1, 0xe2, 0xe3, //
    0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef, //
    0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, //
    0xfc, 0xfd, 0xfe, 0xff,
  ]);

  // Upper-case conversion table for Latin-1 as string.
  // Lower-case ranges: 0x61-0x7a ('a' - 'z'), 0xe0-0xff.
  // The characters 0xb5 (µ) and 0xff (ÿ) have upper case variants
  // that are not Latin-1. These are both marked as 0x00 in the table.
  // The German "sharp s" \xdf (ß) should be converted into two characters (SS),
  // and is also marked with 0x00.
  // Conversion to lower case performed by subtracting 0x20.
  static const _UC_TABLE = ImmutableWasmArray<WasmI8>.literal([
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, //
    0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, //
    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, //
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, //
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, //
    0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, //
    0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, //
    0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, //
    0x60, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, //
    0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, //
    0x58, 0x59, 0x5a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83, //
    0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, //
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, //
    0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, //
    0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, //
    0xb4, 0x00, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf, //
    0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, //
    0xcc, 0xcd, 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, //
    0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0x00, 0xc0, 0xc1, 0xc2, 0xc3, //
    0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, //
    0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xf7, 0xd8, 0xd9, 0xda, 0xdb, //
    0xdc, 0xdd, 0xde, 0x00,
  ]);

  String toLowerCase() {
    final data = this._array;
    final length = data.length;

    for (int i = 0; i < length; i++) {
      final c = data.readUnsigned(i);
      if (c == _LC_TABLE.readUnsigned(c)) continue;
      // Upper-case character found.
      final WasmArray<WasmI8> result = WasmArray(length);
      result.copy(0, data, 0, i);
      for (int j = i; j < length; j++) {
        result[j] = _LC_TABLE[data.readUnsigned(j)];
      }
      return OneByteString.withData(result);
    }
    return this;
  }

  String toUpperCase() {
    final data = this._array;
    final length = data.length;

    for (int i = 0; i < length; i++) {
      final c = data.readUnsigned(i);
      // Continue loop if character is unchanged by upper-case conversion.
      if (c == _UC_TABLE.readUnsigned(c)) continue;

      // Check rest of string for characters that do not convert to
      // single-characters in the Latin-1 range.
      for (int j = i; j < length; j++) {
        final c = data.readUnsigned(j);
        if ((_UC_TABLE.readUnsigned(c) == 0x00) && (c != 0x00)) {
          // We use the 0x00 value for characters other than the null character,
          // that don't convert to a single Latin-1 character when upper-cased.
          // In that case, call the generic super-class method.
          return super.toUpperCase();
        }
      }
      // Some lower-case characters found, but all upper-case to single Latin-1
      // characters.
      final result = WasmArray<WasmI8>(length);
      result.copy(0, data, 0, i);
      for (int j = i; j < this.length; j++) {
        result[j] = _UC_TABLE[data.readUnsigned(j)];
      }
      return OneByteString.withData(result);
    }
    return this;
  }

  /// This is internal helper method. Code point value must be a valid Latin1
  /// value (0..0xFF), index must be valid.
  @pragma('wasm:prefer-inline')
  void _setAt(int index, int codePoint) {
    _array.write(index, codePoint);
  }

  /// Returns index after last character written.
  int _setRange(int index, OneByteString oneByteString, int start, int end) {
    assert(0 <= start);
    assert(start <= end);
    assert(end <= oneByteString.length);
    assert(0 <= index);
    assert(index + (end - start) <= length);
    final rangeLength = end - start;
    _array.copy(index, oneByteString._array, start, rangeLength);
    return index + rangeLength;
  }
}

@pragma("wasm:entry-point")
final class TwoByteString extends StringBase {
  @pragma("wasm:entry-point")
  final WasmArray<WasmI16> _array;

  TwoByteString.withLength(int length) : _array = WasmArray<WasmI16>(length);

  @pragma("wasm:prefer-inline")
  TwoByteString.withData(this._array);

  // Same hash as VM
  @override
  int _computeHashCode() {
    WasmArray<WasmI16> array = _array;
    int length = array.length;
    int hash = 0;
    for (int i = 0; i < length; i++) {
      hash = stringCombineHashes(hash, array.readUnsigned(i));
    }
    return stringFinalizeHash(hash);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! String) return false;

    if (other is TwoByteString) {
      final thisBytes = _array;
      final otherBytes = other._array;
      if (thisBytes.length != otherBytes.length) return false;
      for (int i = 0; i < thisBytes.length; ++i) {
        if (thisBytes[i] != otherBytes[i]) return false;
      }
      return true;
    }

    return StringBase._operatorEqualsFallback(this, other);
  }

  static String allocateFromTwoByteList(List<int> list, int start, int end) {
    final int length = end - start;
    final s = TwoByteString.withLength(length);
    final array = s._array;
    for (int i = 0; i < length; i++) {
      array.write(i, list[start + i]);
    }
    return s;
  }

  /// This is internal helper method. Code point value must be a valid UTF-16
  /// value (0..0xFFFF), index must be valid.
  @pragma('wasm:prefer-inline')
  void _setAt(int index, int codePoint) {
    _array.write(index, codePoint);
  }

  @override
  bool _isWhitespace(int codeUnit) {
    return StringBase._isTwoByteWhitespace(codeUnit);
  }

  @override
  int codeUnitAt(int index) {
    IndexErrorUtils.checkIndexBCE(index, length);
    return _codeUnitAtUnchecked(index);
  }

  @override
  @pragma('wasm:prefer-inline')
  int _codeUnitAtUnchecked(int index) => _array.readUnsigned(index);

  @override
  int get length => _array.length;

  @override
  String _substringUncheckedInternal(int startIndex, int endIndex) {
    final length = endIndex - startIndex;
    final result = TwoByteString.withLength(length);
    result._array.copy(0, _array, startIndex, length);
    return result;
  }

  @override
  int _copyIntoTwoByteString(TwoByteString result, int offset) {
    result._array.copy(offset, _array, 0, length);
    return offset + length;
  }
}
