// See file LICENSE for more information.

library impl.secure_random.auto_seed_block_ctr_random;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/random/block_ctr_random.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// An implementation of [SecureRandom] that uses a [BlockCipher] with CTR mode to generate random
/// values and automatically self reseeds itself after each request for data, in order to achieve
/// forward security. See section 4.1 of the paper:
/// Practical Random Number Generation in Software (by John Viega).
class AutoSeedBlockCtrRandom implements SecureRandom {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      SecureRandom,
      r'^(.*)/CTR/AUTO-SEED-PRNG$',
      (_, final Match match) => () {
            var blockCipherName = match.group(1);
            var blockCipher = BlockCipher(blockCipherName!);
            return AutoSeedBlockCtrRandom(blockCipher);
          });

  late BlockCtrRandom _delegate;
  final bool _reseedIV;

  var _inAutoReseed = false;
  late int _autoReseedKeyLength;

  @override
  String get algorithmName =>
      '${_delegate.cipher.algorithmName}/CTR/AUTO-SEED-PRNG';

  AutoSeedBlockCtrRandom(BlockCipher cipher, [this._reseedIV = true]) {
    _delegate = BlockCtrRandom(cipher);
  }

  @override
  void seed(CipherParameters params) {
    if (params is ParametersWithIV<KeyParameter>) {
      _autoReseedKeyLength = params.parameters!.key.length;
      _delegate.seed(params);
    } else if (params is KeyParameter) {
      _autoReseedKeyLength = params.key.length;
      _delegate.seed(params);
    } else {
      throw ArgumentError(
          'Only types ParametersWithIV<KeyParameter> or KeyParameter allowed for seeding');
    }
  }

  @override
  int nextUint8() => _autoReseedIfNeededAfter(() {
        return _delegate.nextUint8();
      });

  @override
  int nextUint16() => _autoReseedIfNeededAfter(() {
        return _delegate.nextUint16();
      });

  @override
  int nextUint32() => _autoReseedIfNeededAfter(() {
        return _delegate.nextUint32();
      });

  @override
  BigInt nextBigInteger(int bitLength) => _autoReseedIfNeededAfter(() {
        return _delegate.nextBigInteger(bitLength);
      });

  @override
  Uint8List nextBytes(int count) => _autoReseedIfNeededAfter(() {
        return _delegate.nextBytes(count);
      });

  dynamic _autoReseedIfNeededAfter(dynamic closure) {
    if (_inAutoReseed) {
      return closure();
    } else {
      _inAutoReseed = true;
      var ret = closure();
      _doAutoReseed();
      _inAutoReseed = false;
      return ret;
    }
  }

  void _doAutoReseed() {
    var newKey = nextBytes(_autoReseedKeyLength);
    var keyParam = KeyParameter(newKey);

    CipherParameters params;
    if (_reseedIV) {
      params =
          ParametersWithIV(keyParam, nextBytes(_delegate.cipher.blockSize));
    } else {
      params = keyParam;
    }

    _delegate.seed(params);
  }
}
