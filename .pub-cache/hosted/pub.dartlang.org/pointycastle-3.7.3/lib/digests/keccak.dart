// See file LICENSE for more information.

library impl.digest.keccak;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/keccak_engine.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Implementation of Keccak digest.
class KeccakDigest extends KeccakEngine {
  static final RegExp _keccakREGEX = RegExp(r'^Keccak\/([0-9]+)$');

  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig(
      Digest,
      _keccakREGEX,
      (_, final Match match) => () {
            var bitLength = int.parse(match.group(1)!);
            return KeccakDigest(bitLength);
          });

  KeccakDigest([int bitLength = 288]) {
    switch (bitLength) {
      case 128:
      case 224:
      case 256:
      case 288:
      case 384:
      case 512:
        init(bitLength);
        break;
      default:
        throw StateError(
            'invalid bitLength ($bitLength) for Keccak must only be 128,224,256,288,384,512');
    }
  }

  @override
  String get algorithmName => 'Keccak/$fixedOutputLength';

  @override
  int doFinal(Uint8List out, int outOff) {
    squeeze(out, outOff, fixedOutputLength);
    reset();
    return digestSize;
  }
}
