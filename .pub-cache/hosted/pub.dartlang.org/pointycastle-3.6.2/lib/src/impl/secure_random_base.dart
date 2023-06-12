// See file LICENSE for more information.

library src.impl.random.secure_random_base;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/ufixnum.dart';
import 'package:pointycastle/src/utils.dart' as utils;

/// An utility base implementation of [SecureRandom] so that only [nextUint8] method needs to be
/// implemented.
abstract class SecureRandomBase implements SecureRandom {
  @override
  int nextUint16() {
    var b0 = nextUint8();
    var b1 = nextUint8();
    return clip16((b1 << 8) | b0);
  }

  @override
  int nextUint32() {
    var b0 = nextUint8();
    var b1 = nextUint8();
    var b2 = nextUint8();
    var b3 = nextUint8();
    return clip32((b3 << 24) | (b2 << 16) | (b1 << 8) | b0);
  }

  @override
  BigInt nextBigInteger(int bitLength) {
    return utils.decodeBigIntWithSign(1, _randomBits(bitLength));
  }

  @override
  Uint8List nextBytes(int count) {
    var bytes = Uint8List(count);
    for (var i = 0; i < count; i++) {
      bytes[i] = nextUint8();
    }
    return bytes;
  }

  List<int> _randomBits(int numBits) {
    if (numBits < 0) {
      throw ArgumentError('numBits must be non-negative');
    }

    var numBytes = (numBits + 7) ~/ 8; // avoid overflow
    var randomBits = Uint8List(numBytes);

    // Generate random bytes and mask out any excess bits
    if (numBytes > 0) {
      for (var i = 0; i < numBytes; i++) {
        randomBits[i] = nextUint8();
      }
      var excessBits = 8 * numBytes - numBits;
      randomBits[0] &= (1 << (8 - excessBits)) - 1;
    }
    return randomBits;
  }
}
