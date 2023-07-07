// See file LICENSE for more information.

library impl.secure_random.fortuna_random;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/random/auto_seed_block_ctr_random.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// An implementation of [SecureRandom] as specified in the Fortuna algorithm.
class FortunaRandom implements SecureRandom {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(SecureRandom, 'Fortuna', () => FortunaRandom());

  final AESEngine _aes;
  late AutoSeedBlockCtrRandom _prng;

  @override
  String get algorithmName => 'Fortuna';

  FortunaRandom() : _aes = AESEngine() {
    _prng = AutoSeedBlockCtrRandom(_aes, false);
  }

  @override
  void seed(covariant KeyParameter param) {
    if (param.key.length != 32) {
      throw ArgumentError('Fortuna PRNG can only be used with 256 bits keys');
    }

    final iv = Uint8List(16);
    iv[15] = 1;
    _prng.seed(ParametersWithIV(param, iv));
  }

  @override
  int nextUint8() => _prng.nextUint8();

  @override
  int nextUint16() => _prng.nextUint16();

  @override
  int nextUint32() => _prng.nextUint32();

  @override
  BigInt nextBigInteger(int bitLength) => _prng.nextBigInteger(bitLength);

  @override
  Uint8List nextBytes(int count) {
    if (count > 1048576) {
      throw ArgumentError(
          'Fortuna PRNG cannot generate more than 1MB of random data per invocation');
    }

    return _prng.nextBytes(count);
  }
}
