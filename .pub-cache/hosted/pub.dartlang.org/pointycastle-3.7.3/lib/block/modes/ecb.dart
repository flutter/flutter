// See file LICENSE for more information.

library impl.block_cipher.modes.ecb;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';

/// Implementation of Electronic Code Book (ECB) mode on top of a [BlockCipher].
class ECBBlockCipher extends BaseBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      BlockCipher,
      '/ECB',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            return ECBBlockCipher(underlying);
          });

  final BlockCipher _underlyingCipher;

  ECBBlockCipher(this._underlyingCipher);

  @override
  String get algorithmName => '${_underlyingCipher.algorithmName}/ECB';
  @override
  int get blockSize => _underlyingCipher.blockSize;
  @override
  void reset() {
    _underlyingCipher.reset();
  }

  @override
  void init(bool forEncryption, CipherParameters? params) {
    _underlyingCipher.init(forEncryption, params);
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) =>
      _underlyingCipher.processBlock(inp, inpOff, out, outOff);
}
