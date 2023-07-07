// See file LICENSE for more information.

library src.utils;

import 'dart:typed_data';

import 'package:pointycastle/src/platform_check/platform_check.dart';

void arrayCopy(Uint8List? sourceArr, int sourcePos, Uint8List? outArr,
    int outPos, int len) {
  for (var i = 0; i < len; i++) {
    outArr![outPos + i] = sourceArr![sourcePos + i];
  }
}

///
///A constant time equals comparison - does not terminate early if
///test will fail. For best results always pass the expected value
///as the first parameter.
///
/// @param expected first array
/// @param supplied second array
/// @return true if arrays equal, false otherwise.
///
bool constantTimeAreEqual(Uint8List expected, Uint8List supplied) {
  if (expected == supplied) {
    return true;
  }

  var len =
      (expected.length < supplied.length) ? expected.length : supplied.length;

  var nonEqual = expected.length ^ supplied.length;

  for (var i = 0; i != len; i++) {
    nonEqual |= (expected[i] ^ supplied[i]);
  }
  for (var i = len; i < supplied.length; i++) {
    nonEqual |= (supplied[i] ^ ~supplied[i]);
  }

  return nonEqual == 0;
}

Uint8List concatUint8List(Iterable<Uint8List> list) =>
    Uint8List.fromList(list.expand((element) => element).toList());

/// Decode a BigInt from bytes in big-endian encoding.
/// Twos compliment.
BigInt decodeBigInt(List<int> bytes) {
  var negative = bytes.isNotEmpty && bytes[0] & 0x80 == 0x80;

  BigInt result;

  if (bytes.length == 1) {
    result = BigInt.from(bytes[0]);
  } else {
    result = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      var item = bytes[bytes.length - i - 1];
      result |= (BigInt.from(item) << (8 * i));
    }
  }
  return result != BigInt.zero
      ? negative
          ? result.toSigned(result.bitLength)
          : result
      : BigInt.zero;
}

/// Decode a big integer with arbitrary sign.
/// When:
/// sign == 0: Zero regardless of magnitude
/// sign < 0: Negative
/// sign > 0: Positive
BigInt decodeBigIntWithSign(int sign, List<int> magnitude) {
  if (sign == 0) {
    return BigInt.zero;
  }

  BigInt result;

  if (magnitude.length == 1) {
    result = BigInt.from(magnitude[0]);
  } else {
    result = BigInt.from(0);
    for (var i = 0; i < magnitude.length; i++) {
      var item = magnitude[magnitude.length - i - 1];
      result |= (BigInt.from(item) << (8 * i));
    }
  }

  if (result != BigInt.zero) {
    if (sign < 0) {
      result = result.toSigned(result.bitLength);
    } else {
      result = result.toUnsigned(result.bitLength);
    }
  }
  return result;
}

var _byteMask = BigInt.from(0xff);
final negativeFlag = BigInt.from(0x80);

/// Encode a BigInt into bytes using big-endian encoding.
/// It encodes the integer to a minimal twos-compliment integer as defined by
/// ASN.1
Uint8List encodeBigInt(BigInt? number) {
  if (number == BigInt.zero) {
    return Uint8List.fromList([0]);
  }

  int needsPaddingByte;
  int rawSize;

  if (number! > BigInt.zero) {
    rawSize = (number.bitLength + 7) >> 3;
    needsPaddingByte =
        ((number >> (rawSize - 1) * 8) & negativeFlag) == negativeFlag ? 1 : 0;
  } else {
    needsPaddingByte = 0;
    rawSize = (number.bitLength + 8) >> 3;
  }

  final size = rawSize + needsPaddingByte;
  var result = Uint8List(size);
  for (var i = 0; i < rawSize; i++) {
    result[size - i - 1] = (number! & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

/// Encode as Big Endian unsigned byte array.
Uint8List encodeBigIntAsUnsigned(BigInt number) {
  if (number == BigInt.zero) {
    return Uint8List.fromList([0]);
  }
  var size = number.bitLength + (number.isNegative ? 8 : 7) >> 3;
  var result = Uint8List(size);
  for (var i = 0; i < size; i++) {
    result[size - i - 1] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

bool constantTimeAreEqualOffset(
    int len, Uint8List a, int aOff, Uint8List b, int bOff) {
  if (len < 0) {
    throw ArgumentError('"len" cannot be negative');
  }
  if (aOff > (a.length - len)) {
    throw ArgumentError('"aOff" value invalid for specified length');
  }
  if (bOff > (b.length - len)) {
    throw ArgumentError('"bOff" value invalid for specified length');
  }

  var d = 0;
  for (var i = 0; i < len; ++i) {
    d |= (a[aOff + i] ^ b[bOff + i]);
  }
  return 0 == d;
}

abstract class Pack {
  static int littleEndianToLong(Uint8List bs, int off) {
    var data = ByteData.view(bs.buffer);
    return data.getInt64(off, Endian.little);
  }

  static void littleEndianToLongAtList(Uint8List bs, int off, Uint64List ns) {
    for (var i = 0; i < ns.length; ++i) {
      ns[i] = littleEndianToLong(bs, off);
      off += 8;
    }
  }

  static void littleEndianToInt32AtList(Uint8List bs, int off, Uint32List ns) {
    for (var i = 0; i < ns.length; ++i) {
      ns[i] = littleEndianToInt(bs, off);
      off += 4;
    }
  }

  static void intToLittleEndian(int n, Uint8List bs, int off) {
    var data = ByteData.view(bs.buffer);
    data.setInt32(off, n, Endian.little);
  }

  static Uint8List longToLittleEndianList(int n) {
    var bs = Uint8List(8);
    longToLittleEndianAtList(n, bs, 0);
    return bs;
  }

  static void longToLittleEndianAtList(int n, Uint8List bs, int off) {
    var data = ByteData.view(bs.buffer);
    data.setInt64(off, n, Endian.little);
  }

  static Uint8List longListToLittleEndianList(Uint64List ns) {
    var bs = Uint8List(8 * ns.length);
    longListToLittleEndianAtList(ns, bs, 0);
    return bs;
  }

  static void longListToLittleEndianAtList(
      Uint64List ns, Uint8List bs, int off) {
    for (var i = 0; i < ns.length; ++i) {
      longToLittleEndianAtList(ns[i], bs, off);
      off += 8;
    }
  }

  static int littleEndianToInt(Uint8List bs, int off) {
    var data = ByteData.view(bs.buffer);
    return data.getInt32(off, Endian.little);
  }

  static Uint8List intToLittleEndianList(int n) {
    var bs = Uint8List(4);
    intToLittleEndianAtList(n, bs, 0);
    return bs;
  }

  static void intToLittleEndianAtList(int n, Uint8List bs, int off) {
    var data = ByteData.view(bs.buffer);
    data.setInt32(off, n, Endian.little);
  }

  static Uint8List intListToLittleEndian(Uint32List ns) {
    var bs = Uint8List(4 * ns.length);
    intListToLittleEndianAtList(ns, bs, 0);
    return bs;
  }

  static void intListToLittleEndianAtList(
      Uint32List ns, Uint8List bs, int off) {
    for (var i = 0; i < ns.length; ++i) {
      intToLittleEndianAtList(ns[i], bs, off);
      off += 4;
    }
  }
}

abstract class Longs {
  static const _MASK_32 = 0xFFFFFFFF;

  static const _MASK32_HI_BITS = <int>[
    0xFFFFFFFF,
    0x7FFFFFFF,
    0x3FFFFFFF,
    0x1FFFFFFF,
    0x0FFFFFFF,
    0x07FFFFFF,
    0x03FFFFFF,
    0x01FFFFFF,
    0x00FFFFFF,
    0x007FFFFF,
    0x003FFFFF,
    0x001FFFFF,
    0x000FFFFF,
    0x0007FFFF,
    0x0003FFFF,
    0x0001FFFF,
    0x0000FFFF,
    0x00007FFF,
    0x00003FFF,
    0x00001FFF,
    0x00000FFF,
    0x000007FF,
    0x000003FF,
    0x000001FF,
    0x000000FF,
    0x0000007F,
    0x0000003F,
    0x0000001F,
    0x0000000F,
    0x00000007,
    0x00000003,
    0x00000001,
    0x00000000
  ];

  static int rotateRight(int n, int distance) {
    if (distance == 0) {
      // do nothing:
      return n;
    }

    var hi32 = (n >> 32) & 0xFFFFFFFF;
    var lo32 = (n) & 0xFFFFFFFF;

    if (distance >= 32) {
      var swap = hi32;
      hi32 = lo32;
      lo32 = swap;
      distance -= 32;

      if (distance == 0) {
        return (hi32 << 32) | lo32;
      }
    }

    final distance32 = (32 - distance);
    final m = _MASK32_HI_BITS[distance32];

    final hi32cp = hi32;

    hi32 = hi32 >> distance;
    hi32 |= (((lo32 & m) << distance32) & _MASK_32);

    lo32 = lo32 >> distance;
    lo32 |= (((hi32cp & m) << distance32) & _MASK_32);

    return (hi32 << 32) | lo32;
  }

  static int toInt32(int n) => (n & 0xFFFFFFFF);
}

const mask64 = (0xFFFFFFFF << 32) + 0xFFFFFFFF;

int unsignedShiftRight64(int n, int count) {
  if (Platform.instance.isNative) {
    return (n >> count) & ~(-1 << (64 - count));
  } else {
    count &= 0x1f;
    if (n >= 0) {
      return (n >> count);
    } else {
      return (n >> count) ^ ((mask64) ^ ((1 << (64 - count)) - 1));
    }
  }
}
