// This file has been migrated.

library impl.digest.sha3;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/keccak_engine.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Implementation of SHA3 digest.
/// https://csrc.nist.gov/publications/detail/fips/202/final
class SHA3Digest extends KeccakEngine {
  static final RegExp _sha3REGEX = RegExp(r'^SHA3-([0-9]+)$');

  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig(
      Digest,
      _sha3REGEX,
      (_, final Match match) => () {
            var bitLength = int.parse(match.group(1)!);
            return SHA3Digest(bitLength);
          });

  SHA3Digest([int? bitLength = 288]) {
    switch (bitLength) {
      case 224:
      case 256:
      case 384:
      case 512:
        init(bitLength!);
        break;
      default:
        throw StateError(
            'invalid bitLength ($bitLength) for SHA-3 must only be 224,256,384,512');
    }
  }

  @override
  String get algorithmName => 'SHA3-$fixedOutputLength';

  @override
  int doFinal(Uint8List out, int outOff) {
    // FIPS 202 SHA3 https://github.com/PointyCastle/pointycastle/issues/128
    absorbBits(0x02, 2);
    squeeze(out, outOff, fixedOutputLength);
    reset();
    return digestSize;
  }
}
