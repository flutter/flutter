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
  external const factory int.fromEnvironment(
    String name, {
    int defaultValue = 0,
  });

  /// Tries parsing the [string] range from [start] to [end] as a decimal Smi.
  ///
  /// Returns `null` if it's not *definitely* a Smi value.
  /// Not optimizing the parse-error path.
  static int? _tryParseSmi(String string, int start, int end) {
    assert(start < end);
    int index = start;
    int sign = 1;
    int char = string.codeUnitAt(index);
    // Check for leading '+' or '-'.
    if (0x2b == char || 0x2d == char) {
      index++;
      sign = 0x2c - char; // -1 for '-', +1 for '+'.
      if (index == end) {
        return null; // No digits after sign.
      }
      char = string.codeUnitAt(index);
    }
    // Skip leading zeros.
    while (0x30 == char) {
      index++;
      if (index == end) return 0;
      char = string.codeUnitAt(index);
    }
    // If not too long to be a Smi, parse digits.
    int smiLimit = has63BitSmis ? 18 : 9;
    if (end - index <= smiLimit) {
      int result = 0;
      while (true) {
        int digit = 0x30 ^ char;
        if (9 >= digit) {
          result += digit;
          index++;
          if (index < end) {
            result *= 10;
            char = string.codeUnitAt(index);
          } else {
            return sign * result;
          }
        } else {
          break;
        }
      }
    }
    return null; // May not fit into a Smi, or contains non-digit.
  }

  @patch
  static int parse(String source, {int? radix, int onError(String source)?}) {
    if (source.isEmpty) {
      return _handleFormatError(onError, source, 0, radix, null) as int;
    }
    if (radix == null || radix == 10) {
      // Try parsing immediately, without trimming whitespace.
      int? result = _tryParseSmi(source, 0, source.length);
      if (result != null) return result;
    } else if (radix < 2 || radix > 36) {
      throw RangeError("Radix $radix not in range 2..36");
    }
    // Split here so improve odds of parse being inlined and the checks omitted.
    return _parse(unsafeCast<_StringBase>(source), radix, onError) as int;
  }

  static int? _parse(
    _StringBase source,
    int? radix,
    int? Function(String)? onError,
  ) {
    int end = source._lastNonWhitespace() + 1;
    if (end == 0) {
      return _handleFormatError(onError, source, source.length, radix, null);
    }
    int start = source._firstNonWhitespace();

    int first = source.codeUnitAt(start);
    int sign = 1;
    if (first == 0x2b /* + */ || first == 0x2d /* - */ ) {
      sign = 0x2c - first; // -1 if '-', +1 if '+'.
      start++;
      if (start == end) {
        return _handleFormatError(onError, source, end, radix, null);
      }
      first = source.codeUnitAt(start);
    }
    if (radix == null) {
      // check for 0x prefix.
      if (first == 0x30 /* 0 */ ) {
        start++;
        if (start == end) return 0;
        first = source.codeUnitAt(start);
        if ((first | 0x20) == 0x78 /* x */ ) {
          start++;
          if (start == end) {
            return _handleFormatError(onError, source, start, null, null);
          }
          return _parseRadix(source, 16, start, end, sign, sign > 0, onError);
        }
      }
      radix = 10;
    }
    return _parseRadix(source, radix, start, end, sign, false, onError);
  }

  @patch
  static int? tryParse(String source, {int? radix}) {
    if (source.isEmpty) return null;
    if (radix == null || radix == 10) {
      // Try parsing immediately, without trimming whitespace.
      int? result = _tryParseSmi(source, 0, source.length);
      if (result != null) return result;
    } else if (radix < 2 || radix > 36) {
      throw RangeError("Radix $radix not in range 2..36");
    }
    return _parse(unsafeCast<_StringBase>(source), radix, _kNull);
  }

  static Null _kNull(_) => null;

  static int? _handleFormatError(
    int? Function(String)? onError,
    String source,
    int? index,
    int? radix,
    String? message,
  ) {
    if (onError != null) return onError(source);
    message ??= radix == null
        ? "Invalid number"
        : "Invalid radix-$radix number";
    throw FormatException(message, source, index);
  }

  static int? _parseRadix(
    String source,
    int radix,
    int start,
    int end,
    int sign,
    bool allowU64,
    int? Function(String)? onError,
  ) {
    assert(start < end);
    // Skip leading zeros.
    while (start < end && source.codeUnitAt(start) == 0x30) {
      start++;
    }
    int length = end - start;
    if (length == 0) return 0;
    List<int> parseBlockSizeTable = has63BitSmis
        ? _parseLimits64
        : _parseLimits32;
    int tableIndex = (radix - 2) * 2;
    int blockSize = parseBlockSizeTable[tableIndex];
    if (length <= blockSize) {
      _Smi? smi = _parseBlock(source, radix, start, end);
      if (smi != null) {
        return sign * smi;
      }
      return _handleFormatError(onError, source, start, radix, null);
    }

    // Parse blocks of blockSize. If the length of input is not
    // a multiple, parse the shorter block first, so all later blocks
    // have the same length, all multiplication is with the same factor
    // and all overflow handling is in one place.

    int result = 0;
    // Repeated subtraction can be cheaper than modulo, especially
    // because digit count generally tends towards smaller rather
    // than larger.
    int smallBlockSize = length;
    while (true) {
      int smallerBlockSize = smallBlockSize - blockSize;
      if (smallerBlockSize >= 0) {
        smallBlockSize = smallerBlockSize;
      } else {
        break;
      }
    }
    while (smallBlockSize >= blockSize) smallBlockSize -= blockSize;
    if (smallBlockSize > 0) {
      int blockEnd = start + smallBlockSize;
      int? smi = _parseBlock(source, radix, start, blockEnd);
      if (smi == null) {
        return _handleFormatError(onError, source, start, radix, null);
      }
      result = sign * smi;
      start = blockEnd;
    }

    // Parse blocks of `blockSize` length into smis,
    // multiply result by radix ** blockSize and add the smi.
    // Check for overflow *before* adding.

    int multiplier = parseBlockSizeTable[tableIndex + 1];

    List<int> overflowLimits = has63BitSmis
        ? _overflowLimits64
        : _overflowLimits32;
    // Overflow table has double the row length of the parseTable.
    tableIndex <<= 1;
    int positiveOverflowLimit = overflowLimits[tableIndex + 0];
    int negativeOverflowLimit = overflowLimits[tableIndex + 1];
    int blockEnd = start + blockSize;
    do {
      int? smi = _parseBlock(source, radix, start, blockEnd);
      if (smi != null) {
        if (result >= positiveOverflowLimit) {
          // May overflow when adding a smi.
          if ((result > positiveOverflowLimit) ||
              (smi > overflowLimits[tableIndex + 2])) {
            if (allowU64) {
              assert(radix == 16 && sign > 0);
              int unsignedLimit = has63BitSmis ? 0xF : 0xFFFFFFFFF;
              if (blockEnd == end && result <= unsignedLimit) {
                return (result * multiplier) + smi;
              }
            }
            return _handleFormatError(
              onError,
              source,
              null,
              radix,
              "Positive input exceeds the limit of integer",
            );
          }
        } else if (result <= negativeOverflowLimit) {
          // Only if sign is `-1`.
          if ((result < negativeOverflowLimit) ||
              (smi > overflowLimits[tableIndex + 3])) {
            return _handleFormatError(
              onError,
              source,
              null,
              radix,
              "Negative input exceeds the limit of integer",
            );
          }
        }
        result = (result * multiplier) + (sign * smi);
        start = blockEnd;
        blockEnd = start + blockSize;
      } else {
        return _handleFormatError(onError, source, start, radix, null);
      }
    } while (blockEnd <= end);
    return result;
  }

  // Parse block of digits into a Smi.
  static _Smi? _parseBlock(String source, int radix, int start, int end) {
    _Smi result = unsafeCast<_Smi>(0);
    if (radix <= 10) {
      for (int i = start; i < end; i++) {
        int digit = source.codeUnitAt(i) ^ 0x30;
        if (digit < radix) {
          result = unsafeCast<_Smi>(radix * result + digit);
        } else {
          return null;
        }
      }
    } else {
      for (int i = start; i < end; i++) {
        int char = source.codeUnitAt(i);
        int digit = char ^ 0x30;
        if (digit > 9) {
          digit = (char | 0x20) - (0x61 - 10);
          if (digit < 10 || digit >= radix) return null;
        }
        result = unsafeCast<_Smi>(radix * result + digit);
      }
    }
    return result;
  }

  // For each radix, 2-36, how many digits are guaranteed to fit in a smi,
  // and magnitude of such a block (radix ** digit-count).

  // Table for 31-bit smis. All numbers are smis.
  static const _parseLimits32 = [
    // dart format off
    30, 1073741824, // radix: 2
    18,  387420489,
    15, 1073741824,
    12,  244140625, // radix: 5
    11,  362797056,
    10,  282475249,
    10, 1073741824,
     9,  387420489,
     9, 1000000000, // radix: 10
     8,  214358881,
     8,  429981696,
     8,  815730721,
     7,  105413504,
     7,  170859375, // radix: 15
     7,  268435456,
     7,  410338673,
     7,  612220032,
     7,  893871739,
     6 ,  64000000, // radix: 20
     6 ,  85766121,
     6,  113379904,
     6,  148035889,
     6,  191102976,
     6,  244140625, // radix: 25
     6,  308915776,
     6,  387420489,
     6,  481890304,
     6,  594823321,
     6,  729000000, // radix: 30
     6,  887503681,
     6, 1073741824,
     5,   39135393,
     5,   45435424,
     5,   52521875, // radix: 35
     5,   60466176,
    // dart format on
  ];

  // Table for 64-bit smis. All numbers are smis if smis are 63 bits.
  static const _parseLimits64 = [
    // dart format off
    62, 4611686018427387904, // radix: 2
    39, 4052555153018976267,
    30, 1152921504606846976,
    26, 1490116119384765625, // radix: 5
    23,  789730223053602816,
    22, 3909821048582988049,
    20, 1152921504606846976,
    19, 1350851717672992089,
    18, 1000000000000000000, // radix: 10
    17,  505447028499293771,
    17, 2218611106740436992,
    16,  665416609183179841,
    16, 2177953337809371136,
    15,  437893890380859375, // radix: 15
    15, 1152921504606846976,
    15, 2862423051509815793,
    14,  374813367582081024,
    14,  799006685782884121,
    14, 1638400000000000000, // radix: 20
    14, 3243919932521508681,
    13,  282810057883082752,
    13,  504036361936467383,
    13,  876488338465357824,
    13, 1490116119384765625, // radix: 25
    13, 2481152873203736576,
    13, 4052555153018976267,
    12,  232218265089212416,
    12,  353814783205469041,
    12,  531441000000000000, // radix: 30
    12,  787662783788549761,
    12, 1152921504606846976,
    12, 1667889514952984961,
    12, 2386420683693101056,
    12, 3379220508056640625, // radix: 35
    11,  131621703842267136,
    // dart format on
  ];

  /// Overflow limits for `_parseRadix` calculation.
  ///
  /// The expression
  /// ```
  ///   result = (result * multiplier) + (sign * smi)
  /// ```
  /// in `_parseRadix()` may overflow 64-bit integers. In such case,
  /// `int.parse()` should stop with an error.
  ///
  /// The table contains int64 overflow limits for `result` and `smi`.
  /// For each radix from `_parseLimits`, this table contains at
  /// index `(radix - 2) * 4`:
  ///
  /// * `[index]` = positive limit for `result`.
  /// * `[index + 1]` = negative limit for `result`.
  /// * `[index + 2]` = limit for `smi` if result is exactly at positive limit.
  /// * `[index + 3]` = limit for `smi` if result is exactly at negative limit.
  static const List<int> _overflowLimits32 = [
    // dart format off
     0x1ffffffff,  -0x200000000, 0x3fffffff,        0x0, // radix: 2
     0x58b040ea4,  -0x58b040ea4,  0x2d0ef3b,  0x2d0ef3c,
     0x1ffffffff,  -0x200000000, 0x3fffffff,        0x0,
     0x8cbccc096,  -0x8cbccc096,  0xdedb489,  0xdedb48a, // radix: 5
     0x5eb537522,  -0x5eb537522,  0xb0d4fff,  0xb0d5000,
     0x79a357391,  -0x79a357391,  0xc495a7e,  0xc495a7f,
     0x1ffffffff,  -0x200000000, 0x3fffffff,        0x0,
     0x58b040ea4,  -0x58b040ea4,  0x2d0ef3b,  0x2d0ef3c,
     0x225c17d04,  -0x225c17d04, 0x32f2d7ff, 0x32f2d800, // radix: 10
     0xa04a6c518,  -0xa04a6c518,  0x1a3c9e7,  0x1a3c9e8,
     0x4fe8e6ad5,  -0x4fe8e6ad5,  0x30affff,  0x30b0000,
     0x2a1f158bf,  -0x2a1f158bf, 0x1bb69f60, 0x1bb69f61,
    0x145f3b3bb0, -0x145f3b3bb0,  0x33497ff,  0x3349800,
     0xc9197a2b3,  -0xc9197a2b3,  0x43a9362,  0x43a9363, // radix: 15
     0x7ffffffff,  -0x800000000,  0xfffffff,        0x0,
     0x53bc2daf5,  -0x53bc2daf5, 0x100050da, 0x100050db,
     0x381f89143,  -0x381f89143, 0x1f532a7f, 0x1f532a80,
     0x267071285,  -0x267071285,  0x2561c18,  0x2561c19,
    0x218def416b, -0x218def416b,  0x343cfff,  0x343d000, // radix: 20
    0x1909f102c7, -0x1909f102c7,  0x1fa6fe0,  0x1fa6fe1,
    0x12f0cb4ca1, -0x12f0cb4ca1,  0x42c8dbf,  0x42c8dc0,
     0xe81aa6ffb,  -0xe81aa6ffb,  0x18ecdf4,  0x18ecdf5,
     0xb3cc0705f,  -0xb3cc0705f,  0x5e3ffff,  0x5e40000,
     0x8cbccc096,  -0x8cbccc096,  0xdedb489,  0xdedb48a, // radix: 25
     0x6f3a14e59,  -0x6f3a14e59,  0xfeaebbf,  0xfeaebc0,
     0x58b040ea4,  -0x58b040ea4,  0x2d0ef3b,  0x2d0ef3c,
     0x474d4f50e,  -0x474d4f50e, 0x11911fff, 0x11912000,
     0x39c3bd9d4,  -0x39c3bd9d4, 0x1ae7304b, 0x1ae7304c,
     0x2f21f8a22,  -0x2f21f8a22,  0x231277f,  0x2312780, // radix: 30
     0x26b70cb40,  -0x26b70cb40, 0x1e04a4bf, 0x1e04a4c0,
     0x1ffffffff,  -0x200000000, 0x3fffffff,        0x0,
    0x36df890826, -0x36df890826,   0xedf019,   0xedf01a,
    0x2f43b7c97a, -0x2f43b7c97a,  0x1878cbf,  0x1878cc0,
    0x28e32d909e, -0x28e32d909e,  0x305eb45,  0x305eb46, // radix: 35
    0x2383f4becf, -0x2383f4becf,   0x3d63ff,   0x3d6400,
    // dart format on
  ];

  /// Same table as [_overflowLimits32], but for 63-bit smis.
  ///
  /// The table contains int64 overflow limits for `result` and `smi`.
  /// For each radix from `_parseLimits`, this table contains at
  /// index `(radix - 2) * 4`:
  ///
  /// * `[index]` = positive limit for `result`.
  /// * `[index + 1]` = negative limit for `result`.
  /// * `[index + 2]` = limit for `smi` if result is exactly at positive limit.
  /// * `[index + 3]` = limit for `smi` if result is exactly at negative limit.
  static const List<int> _overflowLimits64 = [
    // dart format off
     0x1,  -0x2, 0x3fffffffffffffff,                0x0, // radix: 2
     0x2,  -0x2,  0xf84dd1e8f400fe9,  0xf84dd1e8f400fea,
     0x7,  -0x8,  0xfffffffffffffff,                0x0,
     0x6,  -0x6,  0x3ec43b4d3ecc3a9,  0x3ec43b4d3ecc3aa, // radix: 5
     0xb,  -0xb,  0x7717602637fffff,  0x771760263800000,
     0x2,  -0x2, 0x137b0cf15fbb3ddd, 0x137b0cf15fbb3dde,
     0x7,  -0x8,  0xfffffffffffffff,                0x0,
     0x6,  -0x6,  0xf84dd1e8f400fe9,  0xf84dd1e8f400fea,
     0x9,  -0x9,  0x31993af1d7bffff,  0x31993af1d7c0000, // radix: 10
    0x12, -0x12,  0x1bd3ee663694eb9,  0x1bd3ee663694eba,
     0x4,  -0x4,  0x4d7a3cfffffffff,  0x4d7a3d000000000,
     0xd,  -0xd,  0x7f38c8d9de428b2,  0x7f38c8d9de428b3,
     0x4,  -0x4,  0x7196bea09fbffff,  0x7196bea09fc0000,
    0x15, -0x15,   0x620e5ca93c5964,   0x620e5ca93c5965, // radix: 15
     0x7,  -0x8,  0xfffffffffffffff,                0x0,
     0x3,  -0x3,  0x8d3e433859a722c,  0x8d3e433859a722d,
    0x18, -0x18,  0x3297d7904d9ffff,  0x3297d7904da0000,
     0xb,  -0xb,  0x606f02db83d49ec,  0x606f02db83d49ed,
     0x5,  -0x5,  0xe502b672fffffff,  0xe502b6730000000, // radix: 20
     0x2,  -0x2, 0x25f690044c7e216d, 0x25f690044c7e216e,
    0x20, -0x20,  0x26838061f13ffff,  0x26838061f140000,
    0x12, -0x12,  0x21774c9a823b921,  0x21774c9a823b922,
     0xa,  -0xa,  0x65ce0ffffffffff,  0x65ce10000000000,
     0x6,  -0x6,  0x3ec43b4d3ecc3a9,  0x3ec43b4d3ecc3aa, // radix: 25
     0x3,  -0x3, 0x18b385d295c11fff, 0x18b385d295c12000,
     0x2,  -0x2,  0xf84dd1e8f400fe9,  0xf84dd1e8f400fea,
    0x27, -0x27,  0x250ce02f8ffffff,  0x250ce02f9000000,
    0x1a, -0x1a,   0x55ee8f97a91685,   0x55ee8f97a91686,
    0x11, -0x11,  0x29f04d866aaefff,  0x29f04d866aaf000, // radix: 30
     0xb,  -0xb,  0x7c24195c05eb874,  0x7c24195c05eb875,
     0x7,  -0x8,  0xfffffffffffffff,                0x0,
     0x5,  -0x5,  0xc44549d7324d07a,  0xc44549d7324d07b,
     0x3,  -0x3, 0x1ca531188f7bcfff, 0x1ca531188f7bd000,
     0x2,  -0x2, 0x223531b41f23471d, 0x223531b41f23471e, // radix: 35
    0x46, -0x46,   0x23010a4a7fffff,   0x23010a4a800000,
    // dart format on
  ];
}
