// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show has63BitSmis, patch, unsafeCast;

import "dart:typed_data" show Int64List;

/// VM implementation of int.
@patch
@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
class int {
  @patch
  @pragma("vm:external-name", "Integer_fromEnvironment")
  external const factory int.fromEnvironment(String name,
      {int defaultValue = 0});

  static int? _tryParseSmi(String str, int first, int last) {
    assert(first <= last);
    var ix = first;
    var sign = 1;
    var c = str.codeUnitAt(ix);
    // Check for leading '+' or '-'.
    if ((c == 0x2b) || (c == 0x2d)) {
      ix++;
      sign = 0x2c - c; // -1 for '-', +1 for '+'.
      if (ix > last) {
        return null; // Empty.
      }
    }
    var smiLimit = has63BitSmis ? 18 : 9;
    if ((last - ix) >= smiLimit) {
      return null; // May not fit into a Smi.
    }
    var result = 0;
    for (int i = ix; i <= last; i++) {
      var c = 0x30 ^ str.codeUnitAt(i);
      if (9 < c) {
        return null;
      }
      result = 10 * result + c;
    }
    return sign * result;
  }

  @patch
  static int parse(String source, {int? radix, int onError(String source)?}) {
    if (source == null) throw new ArgumentError("The source must not be null");
    if (source.isEmpty) {
      return _handleFormatError(onError, source, 0, radix, null) as int;
    }
    if (radix == null || radix == 10) {
      // Try parsing immediately, without trimming whitespace.
      int? result = _tryParseSmi(source, 0, source.length - 1);
      if (result != null) return result;
    } else if (radix < 2 || radix > 36) {
      throw new RangeError("Radix $radix not in range 2..36");
    }
    // Split here so improve odds of parse being inlined and the checks omitted.
    return _parse(unsafeCast<_StringBase>(source), radix, onError) as int;
  }

  static int? _parse(
      _StringBase source, int? radix, int? Function(String)? onError) {
    int end = source._lastNonWhitespace() + 1;
    if (end == 0) {
      return _handleFormatError(onError, source, source.length, radix, null);
    }
    int start = source._firstNonWhitespace();

    int first = source.codeUnitAt(start);
    int sign = 1;
    if (first == 0x2b /* + */ || first == 0x2d /* - */) {
      sign = 0x2c - first; // -1 if '-', +1 if '+'.
      start++;
      if (start == end) {
        return _handleFormatError(onError, source, end, radix, null);
      }
      first = source.codeUnitAt(start);
    }
    if (radix == null) {
      // check for 0x prefix.
      int index = start;
      if (first == 0x30 /* 0 */) {
        index++;
        if (index == end) return 0;
        first = source.codeUnitAt(index);
        if ((first | 0x20) == 0x78 /* x */) {
          index++;
          if (index == end) {
            return _handleFormatError(onError, source, index, null, null);
          }
          return _parseRadix(source, 16, index, end, sign, sign > 0, onError);
        }
      }
      radix = 10;
    }
    return _parseRadix(source, radix, start, end, sign, false, onError);
  }

  @patch
  static int? tryParse(String source, {int? radix}) {
    if (source == null) throw new ArgumentError("The source must not be null");
    if (source.isEmpty) return null;
    if (radix == null || radix == 10) {
      // Try parsing immediately, without trimming whitespace.
      int? result = _tryParseSmi(source, 0, source.length - 1);
      if (result != null) return result;
    } else if (radix < 2 || radix > 36) {
      throw new RangeError("Radix $radix not in range 2..36");
    }
    return _parse(unsafeCast<_StringBase>(source), radix, _kNull);
  }

  static Null _kNull(_) => null;

  static int? _handleFormatError(int? Function(String)? onError, String source,
      int? index, int? radix, String? message) {
    if (onError != null) return onError(source);
    if (message != null) {
      throw new FormatException(message, source, index);
    }
    if (radix == null) {
      throw new FormatException("Invalid number", source, index);
    }
    throw new FormatException("Invalid radix-$radix number", source, index);
  }

  static int? _parseRadix(String source, int radix, int start, int end,
      int sign, bool allowU64, int? Function(String)? onError) {
    int tableIndex = (radix - 2) * 4 + (has63BitSmis ? 2 : 0);
    int blockSize = _PARSE_LIMITS[tableIndex];
    int length = end - start;
    if (length <= blockSize) {
      int? smi = _parseBlock(source, radix, start, end);
      if (smi == null) {
        return _handleFormatError(onError, source, start, radix, null);
      }
      return sign * smi;
    }

    // Often cheaper than: int smallBlockSize = length % blockSize;
    // because digit count generally tends towards smaller. rather
    // than larger.
    int smallBlockSize = length;
    while (smallBlockSize >= blockSize) smallBlockSize -= blockSize;
    int result = 0;
    if (smallBlockSize > 0) {
      int blockEnd = start + smallBlockSize;
      int? smi = _parseBlock(source, radix, start, blockEnd);
      if (smi == null) {
        return _handleFormatError(onError, source, start, radix, null);
      }
      result = sign * smi;
      start = blockEnd;
    }
    int multiplier = _PARSE_LIMITS[tableIndex + 1];
    int positiveOverflowLimit = 0;
    int negativeOverflowLimit = 0;
    tableIndex = tableIndex << 1; // pre-multiply by 2 for simpler indexing
    positiveOverflowLimit = _int64OverflowLimits[tableIndex];
    if (positiveOverflowLimit == 0) {
      positiveOverflowLimit = _initInt64OverflowLimits(tableIndex, multiplier);
    }
    negativeOverflowLimit = _int64OverflowLimits[tableIndex + 1];
    int blockEnd = start + blockSize;
    do {
      int? smi = _parseBlock(source, radix, start, blockEnd);
      if (smi == null) {
        return _handleFormatError(onError, source, start, radix, null);
      }
      if (result >= positiveOverflowLimit) {
        if ((result > positiveOverflowLimit) ||
            (smi > _int64OverflowLimits[tableIndex + 2])) {
          // Although the unsigned overflow limits do not depend on the
          // platform, the multiplier and block size, which are used to
          // compute it, do.
          int X = has63BitSmis ? 1 : 0;
          if (allowU64 &&
              !(result >= _int64UnsignedOverflowLimits[X] &&
                  (result > _int64UnsignedOverflowLimits[X] ||
                      smi > _int64UnsignedSmiOverflowLimits[X])) &&
              blockEnd + blockSize > end) {
            return (result * multiplier) + smi;
          }
          return _handleFormatError(onError, source, null, radix,
              "Positive input exceeds the limit of integer");
        }
      } else if (result <= negativeOverflowLimit) {
        if ((result < negativeOverflowLimit) ||
            (smi > _int64OverflowLimits[tableIndex + 3])) {
          return _handleFormatError(onError, source, null, radix,
              "Negative input exceeds the limit of integer");
        }
      }
      result = (result * multiplier) + (sign * smi);
      start = blockEnd;
      blockEnd = start + blockSize;
    } while (blockEnd <= end);
    return result;
  }

  // Parse block of digits into a Smi.
  static _Smi? _parseBlock(String source, int radix, int start, int end) {
    _Smi result = unsafeCast<_Smi>(0);
    if (radix <= 10) {
      for (int i = start; i < end; i++) {
        int digit = source.codeUnitAt(i) ^ 0x30;
        if (digit >= radix) return null;
        result = (radix * result + digit) as _Smi;
      }
    } else {
      for (int i = start; i < end; i++) {
        int char = source.codeUnitAt(i);
        int digit = char ^ 0x30;
        if (digit > 9) {
          digit = (char | 0x20) - (0x61 - 10);
          if (digit < 10 || digit >= radix) return null;
        }
        result = (radix * result + digit) as _Smi;
      }
    }
    return result;
  }

  // For each radix, 2-36, how many digits are guaranteed to fit in a smi,
  // and magnitude of such a block (radix ** digit-count).
  // 32-bit limit/multiplier at (radix - 2)*4, 64-bit limit at (radix-2)*4+2
  static const _PARSE_LIMITS = const [
    30, 1073741824, 62, 4611686018427387904, // radix: 2
    18, 387420489, 39, 4052555153018976267,
    15, 1073741824, 30, 1152921504606846976,
    12, 244140625, 26, 1490116119384765625, //  radix: 5
    11, 362797056, 23, 789730223053602816,
    10, 282475249, 22, 3909821048582988049,
    10, 1073741824, 20, 1152921504606846976,
    9, 387420489, 19, 1350851717672992089,
    9, 1000000000, 18, 1000000000000000000, //  radix: 10
    8, 214358881, 17, 505447028499293771,
    8, 429981696, 17, 2218611106740436992,
    8, 815730721, 16, 665416609183179841,
    7, 105413504, 16, 2177953337809371136,
    7, 170859375, 15, 437893890380859375, //    radix: 15
    7, 268435456, 15, 1152921504606846976,
    7, 410338673, 15, 2862423051509815793,
    7, 612220032, 14, 374813367582081024,
    7, 893871739, 14, 799006685782884121,
    6, 64000000, 14, 1638400000000000000, //    radix: 20
    6, 85766121, 14, 3243919932521508681,
    6, 113379904, 13, 282810057883082752,
    6, 148035889, 13, 504036361936467383,
    6, 191102976, 13, 876488338465357824,
    6, 244140625, 13, 1490116119384765625, //   radix: 25
    6, 308915776, 13, 2481152873203736576,
    6, 387420489, 13, 4052555153018976267,
    6, 481890304, 12, 232218265089212416,
    6, 594823321, 12, 353814783205469041,
    6, 729000000, 12, 531441000000000000, //    radix: 30
    6, 887503681, 12, 787662783788549761,
    6, 1073741824, 12, 1152921504606846976,
    5, 39135393, 12, 1667889514952984961,
    5, 45435424, 12, 2386420683693101056,
    5, 52521875, 12, 3379220508056640625, //    radix: 35
    5, 60466176, 11, 131621703842267136,
  ];

  static const _maxInt64 = 0x7fffffffffffffff;
  static const _minInt64 = -0x8000000000000000;

  static const _int64UnsignedOverflowLimits = const [0xfffffffff, 0xf];
  static const _int64UnsignedSmiOverflowLimits = const [
    0xfffffff,
    0xfffffffffffffff
  ];

  /// Calculation of the expression
  ///
  ///   result = (result * multiplier) + (sign * smi)
  ///
  /// in `_parseRadix()` may overflow 64-bit integers. In such case,
  /// `int.parse()` should stop with an error.
  ///
  /// This table is lazily filled with int64 overflow limits for result and smi.
  /// For each multiplier from `_PARSE_LIMITS[tableIndex + 1]` this table
  /// contains
  ///
  /// * `[tableIndex*2]` = positive limit for result
  /// * `[tableIndex*2 + 1]` = negative limit for result
  /// * `[tableIndex*2 + 2]` = limit for smi if result is exactly at positive limit
  /// * `[tableIndex*2 + 3]` = limit for smi if result is exactly at negative limit
  static final Int64List _int64OverflowLimits =
      new Int64List(_PARSE_LIMITS.length * 2);

  static int _initInt64OverflowLimits(int tableIndex, int multiplier) {
    _int64OverflowLimits[tableIndex] = _maxInt64 ~/ multiplier;
    _int64OverflowLimits[tableIndex + 1] = _minInt64 ~/ multiplier;
    _int64OverflowLimits[tableIndex + 2] =
        unsafeCast<int>(_maxInt64.remainder(multiplier));
    _int64OverflowLimits[tableIndex + 3] =
        -unsafeCast<int>(_minInt64.remainder(multiplier));
    return _int64OverflowLimits[tableIndex];
  }
}
