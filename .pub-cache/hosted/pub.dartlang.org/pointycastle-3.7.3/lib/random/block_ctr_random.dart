// See file LICENSE for more information.

library impl.secure_random.block_ctr_random;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';
import 'package:pointycastle/src/impl/secure_random_base.dart';

/// An implementation of [SecureRandom] that uses a [BlockCipher] with CTR mode to generate random
/// values.
class BlockCtrRandom extends SecureRandomBase implements SecureRandom {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      SecureRandom,
      r'^(.*)/CTR/PRNG$',
      (_, final Match match) => () {
            var blockCipherName = match.group(1);
            var blockCipher = BlockCipher(blockCipherName!);
            return BlockCtrRandom(blockCipher);
          });

  final BlockCipher cipher;

  late Uint8List _input;
  late Uint8List _output;
  late int _used;

  BlockCtrRandom(this.cipher) {
    _input = Uint8List(cipher.blockSize);
    _output = Uint8List(cipher.blockSize);
    _used = _output.length;
  }

  @override
  String get algorithmName => '${cipher.algorithmName}/CTR/PRNG';

  @override
  void seed(CipherParameters params) {
    _used = _output.length;
    if (params is ParametersWithIV) {
      _input.setAll(0, params.iv);
      cipher.init(true, params.parameters!);
    } else {
      cipher.init(true, params);
    }
  }

  @override
  int nextUint8() {
    if (_used == _output.length) {
      cipher.processBlock(_input, 0, _output, 0);
      _used = 0;
      _incrementInput();
    }

    return clip8(_output[_used++]);
  }

  void _incrementInput() {
    var offset = _input.length;
    do {
      offset--;
      _input[offset] += 1;
    } while (_input[offset] == 0);
  }
}
