// This file has been migrated.

library impl.digest.shake;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/keccak_engine.dart';
import 'package:pointycastle/src/registry/registry.dart';

///
/// implementation of SHAKE based on following KeccakNISTInterface.c from http://keccak.noekeon.org/
///
/// Following the naming conventions used in the C source code to enable easy review of the implementation.
///
class SHAKEDigest extends KeccakEngine implements Xof {
  static final RegExp _shakeREGEX = RegExp(r'^SHAKE-([0-9]+)$');

  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig(
      Digest,
      _shakeREGEX,
      (_, final Match match) => () {
            var bitLength = int.parse(match.group(1)!);
            return SHAKEDigest(bitLength);
          });

  SHAKEDigest([int bitLength = 256]) {
    switch (bitLength) {
      case 128:
      case 256:
        init(bitLength);
        break;
      default:
        throw StateError(
            'invalid bitLength ($bitLength) for SHAKE must only be 128 or 256');
    }
  }

  @override
  String get algorithmName => 'SHAKE-$fixedOutputLength';

  @override
  int doFinal(Uint8List out, int outOff) {
    return doFinalRange(out, digestSize, digestSize);
  }

  @override
  int doFinalRange(Uint8List out, int outOff, int outLen) {
    var length = doOutput(out, outOff, outLen);
    reset();
    return length;
  }

  int doFinalPartial(
      Uint8List out, int outOff, int outLen, int partialByte, int partialBits) {
    if (partialBits < 0 || partialBits > 7) {
      throw ArgumentError('partialBits must be in the range [0,7]');
    }

    var finalInput =
        (partialByte & ((1 << partialBits) - 1)) | (0x0F << partialBits);
    var finalBits = partialBits + 4;

    if (finalBits >= 8) {
      absorb(finalInput);
      finalBits -= 8;
      finalInput >>= 8;
    }

    if (finalBits > 0) {
      absorbBits(finalInput, finalBits);
    }

    squeeze(out, outOff, (outLen) * 8);

    reset();

    return outLen;
  }

  @override
  int doOutput(Uint8List out, int outOff, int outLen) {
    if (!squeezing) {
      absorbBits(0x0F, 4);
    }

    squeeze(out, outOff, (outLen) * 8);

    return outLen;
  }
}
