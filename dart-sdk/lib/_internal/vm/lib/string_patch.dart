// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

const int _maxAscii = 0x7f;
const int _maxLatin1 = 0xff;
const int _maxUtf16 = 0xffff;
const int _maxUnicode = 0x10ffff;

@patch
@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
class String {
  @patch
  factory String.fromCharCodes(Iterable<int> charCodes,
      [int start = 0, int? end]) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (charCodes == null) throw new ArgumentError.notNull("charCodes");
    if (start == null) throw new ArgumentError.notNull("start");
    return _StringBase.createFromCharCodes(charCodes, start, end, null);
  }

  @patch
  factory String.fromCharCode(int charCode) {
    if (charCode >= 0) {
      if (charCode <= 0xff) {
        return _OneByteString._allocate(1).._setAt(0, charCode);
      }
      if (charCode <= 0xffff) {
        return _StringBase._createFromCodePoints(
            new _List(1)..[0] = charCode, 0, 1);
      }
      if (charCode <= 0x10ffff) {
        var low = 0xDC00 | (charCode & 0x3ff);
        int bits = charCode - 0x10000;
        var high = 0xD800 | (bits >> 10);
        return _StringBase._createFromCodePoints(
            new _List(2)
              ..[0] = high
              ..[1] = low,
            0,
            2);
      }
    }
    throw new RangeError.range(charCode, 0, 0x10ffff);
  }

  @patch
  @pragma("vm:external-name", "String_fromEnvironment")
  external const factory String.fromEnvironment(String name,
      {String defaultValue = ""});

  bool get _isOneByte;
  String _substringUnchecked(int startIndex, int endIndex);
}

/**
 * [_StringBase] contains common methods used by concrete String
 * implementations, e.g., _OneByteString.
 */
@pragma('vm:deeply-immutable')
abstract final class _StringBase implements String {
  bool _isWhitespace(int codeUnit);

  // Constants used by replaceAll encoding of string slices between matches.
  // A string slice (start+length) is encoded in a single Smi to save memory
  // overhead in the common case.
  // We use fewer bits for length (11 bits) than for the start index (19+ bits).
  // For long strings, it's possible to have many large indices,
  // but it's unlikely to have many long lengths since slices don't overlap.
  // If there are few matches in a long string, then there are few long slices,
  // and if there are many matches, there'll likely be many short slices.
  //
  // Encoding is: 0((start << _lengthBits) | length)

  // Number of bits used by length.
  // This is the shift used to encode and decode the start index.
  static const int _lengthBits = 11;
  // The maximal allowed length value in an encoded slice.
  static const int _maxLengthValue = (1 << _lengthBits) - 1;
  // Mask of length in encoded smi value.
  static const int _lengthMask = _maxLengthValue;
  static const int _startBits = _maxUnsignedSmiBits - _lengthBits;
  // Maximal allowed start index value in an encoded slice.
  static const int _maxStartValue = (1 << _startBits) - 1;
  // We pick 30 as a safe lower bound on available bits in a negative smi.
  // TODO(lrn): Consider allowing more bits for start on 64-bit systems.
  static const int _maxUnsignedSmiBits = 30;

  // For longer strings, calling into C++ to create the result of a
  // [replaceAll] is faster than [_joinReplaceAllOneByteResult].
  // TODO(lrn): See if this limit can be tweaked.
  static const int _maxJoinReplaceOneByteStringLength = 500;

  factory _StringBase._uninstantiable() {
    throw new UnsupportedError("_StringBase can't be instantiated");
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:external-name", "String_getHashCode")
  external int get hashCode;

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:external-name", "String_getHashCode")
  external int get _identityHashCode;

  bool get _isOneByte {
    // Alternatively return false and override it on one-byte string classes.
    int id = ClassID.getID(this);
    return id == ClassID.cidOneByteString;
  }

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
      Iterable<int> charCodes, int start, int? end, int? limit) {
    // Validate start/end first.
    RangeError.checkNotNegative(start, "start");
    if (end != null) {
      var maxLength = end - start;
      if (maxLength < 0) {
        throw RangeError.range(end, start, null, "end");
      }
      if (maxLength == 0) {
        return "";
      }
    }
    // TODO(srdjan): Also skip copying of wide typed arrays.
    final ccid = ClassID.getID(charCodes);
    if ((ccid != ClassID.cidArray) &&
        (ccid != ClassID.cidGrowableObjectArray) &&
        (ccid != ClassID.cidImmutableArray)) {
      if (charCodes is Uint8List) {
        final int codeCount = charCodes.length;
        if (codeCount <= start) return "";
        if (end == null || end > codeCount) {
          end = codeCount;
        }
        return _createOneByteString(charCodes, start, end - start);
      } else if (charCodes is! Uint16List) {
        return _createStringFromIterable(charCodes, start, end);
      }
    }
    final int codeCount = charCodes.length;
    if (codeCount <= start) return "";
    if (end == null || end > codeCount) {
      end = codeCount;
    }
    final len = end - start;
    if (len == 0) return "";

    final typedCharCodes = unsafeCast<List<int>>(charCodes);

    final int actualLimit = limit ?? _scanCodeUnits(typedCharCodes, start, end);
    if (actualLimit < 0) {
      throw new ArgumentError(typedCharCodes);
    }
    if (actualLimit <= _maxLatin1) {
      return _createOneByteString(typedCharCodes, start, len);
    }
    if (actualLimit <= _maxUtf16) {
      return _TwoByteString._allocateFromTwoByteList(
          typedCharCodes, start, end);
    }
    // TODO(lrn): Consider passing limit to _createFromCodePoints, because
    // the function is currently fully generic and doesn't know that its
    // charCodes are not all Latin-1 or UTF-16.
    return _createFromCodePoints(typedCharCodes, start, end);
  }

  static int _scanCodeUnits(List<int> charCodes, int start, int end) {
    int bits = 0;
    for (int i = start; i < end; i++) {
      int code = charCodes[i];
      if (code is! _Smi) throw new ArgumentError(charCodes);
      bits |= code;
    }
    return bits;
  }

  static String _createStringFromIterable(
      Iterable<int> charCodes, int start, int? end) {
    assert(start >= 0);
    assert(end == null || start <= end);
    // Treat charCodes as Iterable.
    if (charCodes is EfficientLengthIterable) {
      final int codeCount = charCodes.length;
      if (start >= codeCount) return "";
      if (end == null || end > codeCount) {
        end = codeCount;
      }
    }
    var it = charCodes.iterator;
    for (int i = 0; i < start; i++) {
      if (!it.moveNext()) return "";
    }
    // Bitwise-or of all char codes in list.
    // There are two valid ranges:
    // 0x00-0xFF: Valid one-byte string.
    // 0x100-0xFFFFF: Valid two-byte string with bits-values in range
    //    0x10000-0xFFFFF already encoded as surrogate pairs.
    // Numbers above that, or negative, correspond to input "char codes"
    // outside of the range U+0000 .. U+10FFFF.
    int bits = 0;
    int takeCount = (end == null) ? -1 : (end - start); // -1 means no limit.
    var list = <int>[];
    while (takeCount != 0 && it.moveNext()) {
      takeCount -= 1;
      int code = it.current;
      if (code <= 0xFFFF) {
        bits |= code;
        list.add(code);
      } else {
        code -= 0x10000;
        // Any value in the range 0x100..0xFFFFF can be used for the second
        // number. Using 0xD800 to represent containing surrogate pairs.
        bits |= code | 0xD800;
        list
          ..add(0xD800 + (code >>> 10))
          ..add(0xDC00 + (code & 0x3FF));
      }
    }
    if (bits < 0 || bits > 0xFFFFF) {
      throw ArgumentError.value(charCodes, "charCodes",
          "Contains invalid character code, not 0 <= code <= 0x10FFFF");
    }
    List<int> codeUnitList = makeListFixedLength<int>(list);
    int length = codeUnitList.length;
    bool isOneByteString = (bits <= _maxLatin1);
    if (isOneByteString) {
      return _createOneByteString(codeUnitList, 0, length);
    }
    return _TwoByteString._allocateFromTwoByteList(codeUnitList, 0, length);
  }

  // Inlining is disabled as a workaround to http://dartbug.com/37800.
  @pragma("vm:never-inline")
  static String _createOneByteString(List<int> charCodes, int start, int len) {
    // It's always faster to do this in Dart than to call into the runtime.
    var s = _OneByteString._allocate(len);

    // Special case for native Uint8 typed arrays.
    if (charCodes is Uint8List) {
      Uint8List bytes = unsafeCast<Uint8List>(charCodes);
      copyRangeFromUint8ListToOneByteString(bytes, s, start, 0, len);
      return s;
    }

    // Fall through to normal case.
    for (int i = 0; i < len; i++) {
      s._setAt(i, charCodes[start + i]);
    }
    return s;
  }

  @pragma("vm:external-name", "StringBase_createFromCodePoints")
  external static String _createFromCodePoints(
      List<int> codePoints, int start, int end);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:external-name", "String_charAt")
  external String operator [](int index);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int codeUnitAt(int index);

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "String_getLength")
  external int get length;

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  @pragma("vm:external-name", "String_concat")
  external String operator +(String other);

  String toString() {
    return this;
  }

  @pragma("vm:exact-result-type", bool)
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is String && this.length == other.length) {
      final len = this.length;
      for (int i = 0; i < len; i++) {
        if (this.codeUnitAt(i) != other.codeUnitAt(i)) {
          return false;
        }
      }
      return true;
    }
    return false;
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

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
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
    if ((index < 0) || (index > this.length)) {
      throw new RangeError.range(index, 0, this.length);
    }
    if (pattern is String) {
      return _substringMatches(index, pattern);
    }
    return pattern.matchAsPrefix(this, index) != null;
  }

  int indexOf(Pattern pattern, [int start = 0]) {
    if ((start < 0) || (start > this.length)) {
      throw new RangeError.range(start, 0, this.length, "start");
    }
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
    } else if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
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
    endIndex = RangeError.checkValidRange(startIndex, endIndex, this.length);
    return _substringUnchecked(startIndex, endIndex);
  }

  String _substringUnchecked(int startIndex, int endIndex) {
    assert(endIndex != null);
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
    return _substringUncheckedNative(startIndex, endIndex);
  }

  @pragma("vm:external-name", "StringBase_substringUnchecked")
  external String _substringUncheckedNative(int startIndex, int endIndex);

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

  int _firstNonWhitespace() {
    final len = this.length;
    int first = 0;
    for (; first < len; first++) {
      if (!_isWhitespace(this.codeUnitAt(first))) {
        break;
      }
    }
    return first;
  }

  int _lastNonWhitespace() {
    int last = this.length - 1;
    for (; last >= 0; last--) {
      if (!_isWhitespace(this.codeUnitAt(last))) {
        break;
      }
    }
    return last;
  }

  String trim() {
    final len = this.length;
    int first = _firstNonWhitespace();
    if (len == first) {
      // String contains only whitespaces.
      return "";
    }
    int last = _lastNonWhitespace() + 1;
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
    StringBuffer buffer = new StringBuffer(this);
    for (int i = 1; i < times; i++) {
      buffer.write(this);
    }
    return buffer.toString();
  }

  String padLeft(int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    StringBuffer buffer = new StringBuffer();
    for (int i = 0; i < delta; i++) {
      buffer.write(padding);
    }
    buffer.write(this);
    return buffer.toString();
  }

  String padRight(int width, [String padding = ' ']) {
    int delta = width - this.length;
    if (delta <= 0) return this;
    StringBuffer buffer = new StringBuffer(this);
    for (int i = 0; i < delta; i++) {
      buffer.write(padding);
    }
    return buffer.toString();
  }

  bool contains(Pattern pattern, [int startIndex = 0]) {
    if (pattern is String) {
      if (startIndex < 0 || startIndex > this.length) {
        throw new RangeError.range(startIndex, 0, this.length);
      }
      return indexOf(pattern, startIndex) >= 0;
    }
    return pattern.allMatches(this.substring(startIndex)).isNotEmpty;
  }

  String replaceFirst(Pattern pattern, String replacement,
      [int startIndex = 0]) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (pattern == null) {
      throw new ArgumentError.notNull("pattern");
    }
    if (replacement == null) {
      throw new ArgumentError.notNull("replacement");
    }
    if (startIndex == null) {
      throw new ArgumentError.notNull("startIndex");
    }
    RangeError.checkValueInInterval(startIndex, 0, this.length, "startIndex");
    Iterator iterator = startIndex == 0
        ? pattern.allMatches(this).iterator
        : pattern.allMatches(this, startIndex).iterator;
    if (!iterator.moveNext()) return this;
    Match match = iterator.current;
    return replaceRange(match.start, match.end, replacement);
  }

  String replaceRange(int start, int? end, String replacement) {
    final length = this.length;
    final localEnd = RangeError.checkValidRange(start, end, length);
    bool replacementIsOneByte = replacement._isOneByte;
    if (start == 0 && localEnd == length) return replacement;
    int replacementLength = replacement.length;
    int totalLength = start + (length - localEnd) + replacementLength;
    if (replacementIsOneByte && this._isOneByte) {
      var result = _OneByteString._allocate(totalLength);
      int index = 0;
      index = result._setRange(index, this, 0, start);
      index = result._setRange(start, replacement, 0, replacementLength);
      result._setRange(index, this, localEnd, length);
      return result;
    }
    List slices = [];
    _addReplaceSlice(slices, 0, start);
    if (replacement.length > 0) slices.add(replacement);
    _addReplaceSlice(slices, localEnd, length);
    return _joinReplaceAllResult(
        this, slices, totalLength, replacementIsOneByte);
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
    if (pattern == null) throw new ArgumentError.notNull("pattern");
    if (replacement == null) throw new ArgumentError.notNull("replacement");

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
    bool replacementIsOneByte = replacement._isOneByte;
    if (replacementIsOneByte &&
        length < _maxJoinReplaceOneByteStringLength &&
        this._isOneByte) {
      // TODO(lrn): Is there a cut-off point, or is runtime always faster?
      return _joinReplaceAllOneByteResult(this, matches, length);
    }
    return _joinReplaceAllResult(this, matches, length, replacementIsOneByte);
  }

  /**
   * As [_joinReplaceAllResult], but knowing that the result
   * is always a [_OneByteString].
   */
  static String _joinReplaceAllOneByteResult(
      String base, List matches, int length) {
    _OneByteString result = _OneByteString._allocate(length);
    int writeIndex = 0;
    for (int i = 0; i < matches.length; i++) {
      var entry = matches[i];
      if (entry is _Smi) {
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
   * Combine the results of a [replaceAll] match into a new string.
   *
   * The [matches] lists contains Smi index pairs representing slices of
   * [base] and [String]s to be put in between the slices.
   *
   * The total [length] of the resulting string is known, as is
   * whether the replacement strings are one-byte strings.
   * If they are, then we have to check the base string slices to know
   * whether the result must be a one-byte string.
   */
  @pragma("vm:external-name", "StringBase_joinReplaceAllResult")
  external static String _joinReplaceAllResult(
      String base, List matches, int length, bool replacementStringsAreOneByte);

  String replaceAllMapped(Pattern pattern, String replace(Match match)) {
    if (pattern == null) throw new ArgumentError.notNull("pattern");
    if (replace == null) throw new ArgumentError.notNull("replace");
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
          replacementStringsAreOneByte && replacement._isOneByte;
      startIndex = match.end;
    }
    if (matches.isEmpty) return this;
    length += _addReplaceSlice(matches, startIndex, this.length);
    if (replacementStringsAreOneByte &&
        length < _maxJoinReplaceOneByteStringLength &&
        this._isOneByte) {
      return _joinReplaceAllOneByteResult(this, matches, length);
    }
    return _joinReplaceAllResult(
        this, matches, length, replacementStringsAreOneByte);
  }

  String replaceFirstMapped(Pattern pattern, String replace(Match match),
      [int startIndex = 0]) {
    if (pattern == null) throw new ArgumentError.notNull("pattern");
    if (replace == null) throw new ArgumentError.notNull("replace");
    if (startIndex == null) throw new ArgumentError.notNull("startIndex");
    RangeError.checkValueInInterval(startIndex, 0, this.length, "startIndex");

    var matches = pattern.allMatches(this, startIndex).iterator;
    if (!matches.moveNext()) return this;
    var match = matches.current;
    var replacement = "${replace(match)}";
    return replaceRange(match.start, match.end, replacement);
  }

  static String _matchString(Match match) => match[0]!;
  static String _stringIdentity(String string) => string;

  String _splitMapJoinEmptyString(
      String onMatch(Match match), String onNonMatch(String nonMatch)) {
    // Pattern is the empty string.
    StringBuffer buffer = new StringBuffer();
    int length = this.length;
    int i = 0;
    buffer.write(onNonMatch(""));
    while (i < length) {
      buffer.write(onMatch(new _StringMatch(i, this, "")));
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
    buffer.write(onMatch(new _StringMatch(i, this, "")));
    buffer.write(onNonMatch(""));
    return buffer.toString();
  }

  String splitMapJoin(Pattern pattern,
      {String onMatch(Match match)?, String onNonMatch(String nonMatch)?}) {
    if (pattern == null) {
      throw new ArgumentError.notNull("pattern");
    }
    onMatch ??= _matchString;
    onNonMatch ??= _stringIdentity;
    if (pattern is String) {
      String stringPattern = pattern;
      if (stringPattern.isEmpty) {
        return _splitMapJoinEmptyString(onMatch, onNonMatch);
      }
    }
    StringBuffer buffer = new StringBuffer();
    int startIndex = 0;
    for (Match match in pattern.allMatches(this)) {
      buffer.write(onNonMatch(this.substring(startIndex, match.start)));
      buffer.write(onMatch(match).toString());
      startIndex = match.end;
    }
    buffer.write(onNonMatch(this.substring(startIndex)));
    return buffer.toString();
  }

  // Convert single object to string.
  @pragma("vm:entry-point", "call")
  static String _interpolateSingle(Object? o) {
    if (o is String) return o;
    final s = o.toString();
    // TODO(40614): Remove once non-nullability is sound.
    if (s is! String) {
      throw _interpolationError(o, s);
    }
    return s;
  }

  /**
   * Convert all objects in [values] to strings and concat them
   * into a result string.
   * Modifies the input list if it contains non-`String` values.
   */
  @pragma("vm:recognized", "other")
  @pragma("vm:entry-point", "call")
  @pragma("vm:never-inline")
  static String _interpolate(final List values) {
    final numValues = values.length;
    int totalLength = 0;
    int i = 0;
    while (i < numValues) {
      final e = values[i];
      final s = e.toString();
      values[i] = s;
      if (ClassID.getID(s) == ClassID.cidOneByteString) {
        totalLength += s.length;
        i++;
      } else if (s is! String) {
        // TODO(40614): Remove once non-nullability is sound.
        throw _interpolationError(e, s);
      } else {
        // Handle remaining elements without checking for one-byte-ness.
        while (++i < numValues) {
          final e = values[i];
          final s = e.toString();
          values[i] = s;
          // TODO(40614): Remove once non-nullability is sound.
          if (s is! String) {
            throw _interpolationError(e, s);
          }
        }
        return _concatRangeNative(values, 0, numValues);
      }
    }
    // All strings were one-byte strings.
    return _OneByteString._concatAll(values, totalLength);
  }

  static ArgumentError _interpolationError(Object? o, Object? result) {
    // Since Dart 2.0, [result] can only be null.
    return new ArgumentError.value(
        o, "object", "toString method returned 'null'");
  }

  Iterable<Match> allMatches(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length, "start");
    }
    return new _StringAllMatchesIterable(string, this, start);
  }

  Match? matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    if (start + this.length > string.length) return null;
    for (int i = 0; i < this.length; i++) {
      if (string.codeUnitAt(start + i) != this.codeUnitAt(i)) {
        return null;
      }
    }
    return new _StringMatch(start, string, this);
  }

  List<String> split(Pattern pattern) {
    if ((pattern is String) && pattern.isEmpty) {
      List<String> result =
          new List<String>.generate(this.length, (int i) => this[i]);
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

  List<int> get codeUnits => new CodeUnits(this);

  Runes get runes => new Runes(this);

  @pragma("vm:external-name", "String_toUpperCase")
  external String toUpperCase();

  @pragma("vm:external-name", "String_toLowerCase")
  external String toLowerCase();

  // Concatenate ['start', 'end'[ elements of 'strings'.
  static String _concatRange(List<String> strings, int start, int end) {
    if ((end - start) == 1) {
      return strings[start];
    }
    return _concatRangeNative(strings, start, end);
  }

  // Call this method if all elements of [strings] are known to be strings
  // but not all are known to be OneByteString(s).
  @pragma("vm:external-name", "String_concatRange")
  external static String _concatRangeNative(List strings, int start, int end);
}

/// Product of two positive integers, clamped to the maximum int value on
/// overflow or non-positive inputs.
int _clampedPositiveProduct(int a, int b) {
  const MAX_INT64 = (-1) >>> 1;

  int product = a * b;

  // `(a | b)` is negative if either is negative.
  // `product <= 0` if `a` or `b` is zero, and in some cases of overflow.
  if ((a | b) < 0 || product <= 0) return MAX_INT64;

  // Both values are small enough that the product has no overflow.
  if ((a | b) < (1 << 30)) return product;

  // Check the product.
  if (product ~/ a != b) return MAX_INT64;

  return product;
}

@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class _OneByteString extends _StringBase {
  factory _OneByteString._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:external-name", "String_getHashCode")
  external int get hashCode;

  bool _isWhitespace(int codeUnit) {
    return _StringBase._isOneByteWhitespace(codeUnit);
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  // Intrinsic is more efficient than an inlined body even for the small
  // strings.
  @pragma('vm:never-inline')
  bool operator ==(Object other) {
    return super == other;
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _OneByteString)
  @pragma("vm:external-name", "OneByteString_substringUnchecked")
  external String _substringUncheckedNative(int startIndex, int endIndex);

  List<String> _splitWithCharCode(int charCode) {
    final parts = <String>[];
    int i = 0;
    int start = 0;
    for (i = 0; i < this.length; ++i) {
      if (this.codeUnitAt(i) == charCode) {
        parts.add(this._substringUnchecked(start, i));
        start = i + 1;
      }
    }
    parts.add(this._substringUnchecked(start, i));
    return parts;
  }

  List<String> split(Pattern pattern) {
    // TODO(vegorov) investigate if this can be rewritten as `is _OneByteString`
    // check without performance penalty. Front-end would then promote
    // pattern variable to _OneByteString.
    if (ClassID.getID(pattern) == ClassID.cidOneByteString) {
      final String patternAsString = unsafeCast<String>(pattern);
      if (patternAsString.length == 1) {
        return _splitWithCharCode(patternAsString.codeUnitAt(0));
      }
    }
    return super.split(pattern);
  }

  // All element of 'strings' must be OneByteStrings.
  static _concatAll(List strings, int totalLength) {
    if (totalLength > 128) {
      // Native is quicker.
      return _StringBase._concatRangeNative(strings, 0, strings.length);
    }
    final res = _OneByteString._allocate(totalLength);
    final stringsLength = strings.length;
    int rIx = 0;
    for (int i = 0; i < stringsLength; i++) {
      final _OneByteString e = strings[i];
      final eLength = e.length;
      for (int s = 0; s < eLength; s++) {
        res._setAt(rIx++, e.codeUnitAt(s));
      }
    }
    return res;
  }

  int indexOf(Pattern pattern, [int start = 0]) {
    // Specialize for single character pattern.
    final pCid = ClassID.getID(pattern);
    if ((pCid == ClassID.cidOneByteString) ||
        (pCid == ClassID.cidTwoByteString)) {
      final String patternAsString = unsafeCast<String>(pattern);
      final len = this.length;
      if ((patternAsString.length == 1) && (start >= 0) && (start < len)) {
        final patternCu0 = patternAsString.codeUnitAt(0);
        if (patternCu0 > 0xFF) {
          return -1;
        }
        for (int i = start; i < len; i++) {
          if (this.codeUnitAt(i) == patternCu0) {
            return i;
          }
        }
        return -1;
      }
    }
    return super.indexOf(pattern, start);
  }

  bool contains(Pattern pattern, [int start = 0]) {
    final pCid = ClassID.getID(pattern);
    if ((pCid == ClassID.cidOneByteString) ||
        (pCid == ClassID.cidTwoByteString)) {
      final String patternAsString = unsafeCast<String>(pattern);
      final len = this.length;
      if ((patternAsString.length == 1) && (start >= 0) && (start < len)) {
        final patternCu0 = patternAsString.codeUnitAt(0);
        if (patternCu0 > 0xFF) {
          return false;
        }
        for (int i = start; i < len; i++) {
          if (this.codeUnitAt(i) == patternCu0) {
            return true;
          }
        }
        return false;
      }
    }
    return super.contains(pattern, start);
  }

  String operator *(int times) {
    if (times <= 0) return "";
    if (times == 1) return this;
    if (this.isEmpty) return this; // Don't clone empty string.
    int length = this.length;
    int resultLength = _clampedPositiveProduct(length, times);
    _OneByteString result = _OneByteString._allocate(resultLength);
    // Copy `this` into `result`.
    for (int i = 0; i < length; i++) {
      result._setAt(i, this.codeUnitAt(i));
    }
    // Make more copies by copying within `result`.
    for (int i = length; i < resultLength; i++) {
      result._setAt(i, result.codeUnitAt(i - length));
    }
    return result;
  }

  String padLeft(int width, [String padding = ' ']) {
    int padCid = ClassID.getID(padding);
    if (padCid != ClassID.cidOneByteString) {
      return super.padLeft(width, padding);
    }
    int length = this.length;
    int delta = width - length;
    if (delta <= 0) return this;
    int padLength = padding.length;
    int resultLength = padLength * delta + length;
    _OneByteString result = _OneByteString._allocate(resultLength);
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
      result._setAt(index++, this.codeUnitAt(i));
    }
    return result;
  }

  String padRight(int width, [String padding = ' ']) {
    int padCid = ClassID.getID(padding);
    if (padCid != ClassID.cidOneByteString) {
      return super.padRight(width, padding);
    }
    int length = this.length;
    int delta = width - length;
    if (delta <= 0) return this;
    int padLength = padding.length;
    int resultLength = length + padLength * delta;
    _OneByteString result = _OneByteString._allocate(resultLength);
    int index = 0;
    for (int i = 0; i < length; i++) {
      result._setAt(index++, this.codeUnitAt(i));
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
  static const _LC_TABLE =
      "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
      "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
      "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
      "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
      "\x40\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
      "\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x5b\x5c\x5d\x5e\x5f"
      "\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f"
      "\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
      "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f"
      "\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
      "\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf"
      "\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
      "\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef"
      "\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xd7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xdf"
      "\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef"
      "\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff";

  // Upper-case conversion table for Latin-1 as string.
  // Lower-case ranges: 0x61-0x7a ('a' - 'z'), 0xe0-0xff.
  // The characters 0xb5 (µ) and 0xff (ÿ) have upper case variants
  // that are not Latin-1. These are both marked as 0x00 in the table.
  // The German "sharp s" \xdf (ß) should be converted into two characters (SS),
  // and is also marked with 0x00.
  // Conversion to lower case performed by subtracting 0x20.
  static const _UC_TABLE =
      "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
      "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
      "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f"
      "\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
      "\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f"
      "\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
      "\x60\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f"
      "\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x7b\x7c\x7d\x7e\x7f"
      "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f"
      "\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
      "\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf"
      "\xb0\xb1\xb2\xb3\xb4\x00\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
      "\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf"
      "\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\x00"
      "\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf"
      "\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xf7\xd8\xd9\xda\xdb\xdc\xdd\xde\x00";

  String toLowerCase() {
    for (int i = 0; i < this.length; i++) {
      final c = this.codeUnitAt(i);
      if (c == _LC_TABLE.codeUnitAt(c)) continue;
      // Upper-case character found.
      final result = _allocate(this.length);
      for (int j = 0; j < i; j++) {
        result._setAt(j, this.codeUnitAt(j));
      }
      for (int j = i; j < this.length; j++) {
        result._setAt(j, _LC_TABLE.codeUnitAt(this.codeUnitAt(j)));
      }
      return result;
    }
    return this;
  }

  String toUpperCase() {
    for (int i = 0; i < this.length; i++) {
      final c = this.codeUnitAt(i);
      // Continue loop if character is unchanged by upper-case conversion.
      if (c == _UC_TABLE.codeUnitAt(c)) continue;

      // Check rest of string for characters that do not convert to
      // single-characters in the Latin-1 range.
      for (int j = i; j < this.length; j++) {
        final c = this.codeUnitAt(j);
        if ((_UC_TABLE.codeUnitAt(c) == 0x00) && (c != 0x00)) {
          // We use the 0x00 value for characters other than the null character,
          // that don't convert to a single Latin-1 character when upper-cased.
          // In that case, call the generic super-class method.
          return super.toUpperCase();
        }
      }
      // Some lower-case characters found, but all upper-case to single Latin-1
      // characters.
      final result = _allocate(this.length);
      for (int j = 0; j < i; j++) {
        result._setAt(j, this.codeUnitAt(j));
      }
      for (int j = i; j < this.length; j++) {
        result._setAt(j, _UC_TABLE.codeUnitAt(this.codeUnitAt(j)));
      }
      return result;
    }
    return this;
  }

  // Allocates a string of given length, expecting its content to be
  // set using _setAt.
  @pragma("vm:exact-result-type", _OneByteString)
  @pragma("vm:prefer-inline")
  static _OneByteString _allocate(int length) {
    return unsafeCast<_OneByteString>(allocateOneByteString(length));
  }

  @pragma("vm:external-name", "OneByteString_allocateFromOneByteList")
  external static _OneByteString _allocateFromOneByteList(
      List<int> list, int start, int end);

  // This is internal helper method. Code point value must be a valid
  // Latin1 value (0..0xFF), index must be valid.
  @pragma("vm:prefer-inline")
  void _setAt(int index, int codePoint) {
    writeIntoOneByteString(this, index, codePoint);
  }

  // Should be optimizable to a memory move.
  // Accepts _OneByteString as argument.
  // Returns index after last character written.
  int _setRange(int index, String oneByteString, int start, int end) {
    assert(oneByteString._isOneByte);
    assert(0 <= start);
    assert(start <= end);
    assert(end <= oneByteString.length);
    assert(0 <= index);
    assert(index + (end - start) <= length);
    for (int i = start; i < end; i++) {
      _setAt(index, oneByteString.codeUnitAt(i));
      index += 1;
    }
    return index;
  }
}

@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class _TwoByteString extends _StringBase {
  factory _TwoByteString._uninstantiable() {
    throw "Unreachable";
  }

  // Allocates a string of given length, expecting its content to be
  // set using _setAt.
  @pragma("vm:exact-result-type", _TwoByteString)
  @pragma("vm:prefer-inline")
  static _TwoByteString _allocate(int length) {
    return unsafeCast<_TwoByteString>(allocateTwoByteString(length));
  }

  @pragma("vm:external-name", "TwoByteString_allocateFromTwoByteList")
  external static String _allocateFromTwoByteList(
      List<int> list, int start, int end);

  // This is internal helper method. Code point value must be a valid
  // UTF-16 value (0..0xFFFF), index must be valid.
  @pragma("vm:prefer-inline")
  void _setAt(int index, int codePoint) {
    writeIntoTwoByteString(this, index, codePoint);
  }

  bool _isWhitespace(int codeUnit) {
    return _StringBase._isTwoByteWhitespace(codeUnit);
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  // Intrinsic is more efficient than an inlined body even for the small
  // strings.
  @pragma('vm:never-inline')
  bool operator ==(Object other) {
    return super == other;
  }

  String operator *(int times) {
    if (times <= 0) return "";
    if (times == 1) return this;
    if (this.isEmpty) return this; // Don't clone empty string.
    int length = this.length;
    int resultLength = _clampedPositiveProduct(length, times);
    _TwoByteString result = _TwoByteString._allocate(resultLength);
    // Copy `this` into `result`.
    for (int i = 0; i < length; i++) {
      result._setAt(i, this.codeUnitAt(i));
    }
    // Make more copies by copying within `result`.
    for (int i = length; i < resultLength; i++) {
      result._setAt(i, result.codeUnitAt(i - length));
    }
    return result;
  }
}

final class _StringMatch implements Match {
  const _StringMatch(this.start, this.input, this.pattern);

  int get end => start + pattern.length;
  String operator [](int g) => group(g);
  int get groupCount => 0;

  String group(int group) {
    if (group != 0) {
      throw new RangeError.value(group);
    }
    return pattern;
  }

  List<String> groups(List<int> groups) {
    List<String> result = <String>[];
    for (int g in groups) {
      result.add(group(g));
    }
    return result;
  }

  final int start;
  final String input;
  final String pattern;
}

final class _StringAllMatchesIterable extends Iterable<Match> {
  final String _input;
  final String _pattern;
  final int _index;

  _StringAllMatchesIterable(this._input, this._pattern, this._index);

  Iterator<Match> get iterator =>
      new _StringAllMatchesIterator(_input, _pattern, _index);

  Match get first {
    int index = _input.indexOf(_pattern, _index);
    if (index >= 0) {
      return new _StringMatch(index, _input, _pattern);
    }
    throw IterableElementError.noElement();
  }
}

final class _StringAllMatchesIterator implements Iterator<Match> {
  final String _input;
  final String _pattern;
  int _index;
  Match? _current;

  _StringAllMatchesIterator(this._input, this._pattern, this._index);

  bool moveNext() {
    if (_index + _pattern.length > _input.length) {
      _current = null;
      return false;
    }
    var index = _input.indexOf(_pattern, _index);
    if (index < 0) {
      _index = _input.length + 1;
      _current = null;
      return false;
    }
    int end = index + _pattern.length;
    _current = new _StringMatch(index, _input, _pattern);
    // Empty match, don't start at same location again.
    if (end == _index) end++;
    _index = end;
    return true;
  }

  Match get current => _current as Match;
}
