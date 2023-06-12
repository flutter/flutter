// See file LICENSE for more information.

library impl.block_cipher.modes.ige;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';
import 'package:pointycastle/src/utils.dart';

/// Implementation of IGE mode on top of a [BlockCipher].
///
/// This mode is not commonly used aside from as a critical building block in
/// the Telegram protocol.
class IGEBlockCipher extends BaseBlockCipher {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      BlockCipher,
      '/IGE',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            return IGEBlockCipher(underlying);
          });

  final BlockCipher _underlyingCipher;

  late Uint8List _x0, _y0, _xPrev, _yPrev;

  late bool _encrypting;

  /// Instantiates an IGEBlockCipher, using [_underlyingCipher] as the basis
  /// for chaining encryption/decryption.
  IGEBlockCipher(this._underlyingCipher) {
    _x0 = Uint8List(blockSize);
    _y0 = Uint8List(blockSize);
    _xPrev = Uint8List(blockSize);
    _yPrev = Uint8List(blockSize);
  }

  @override
  String get algorithmName => '${_underlyingCipher.algorithmName}/IGE';

  @override
  int get blockSize => _underlyingCipher.blockSize;

  @override
  void reset() {
    arrayCopy(_x0, 0, _xPrev, 0, blockSize);
    arrayCopy(_y0, 0, _yPrev, 0, blockSize);

    _underlyingCipher.reset();
  }

  @override
  void init(bool forEncryption, covariant ParametersWithIV params) {
    if (params.iv.length != blockSize * 2) {
      throw ArgumentError(
          'Initialization vector must be the same length as block size');
    }

    _encrypting = forEncryption;
    arrayCopy(params.iv, 0, _x0, 0, blockSize);
    arrayCopy(params.iv, blockSize, _y0, 0, blockSize);

    reset();

    _underlyingCipher.init(forEncryption, params.parameters);
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) =>
      _encrypting
          ? _encryptBlock(inp, inpOff, out, outOff)
          : _decryptBlock(inp, inpOff, out, outOff);

  int _encryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if ((inpOff + blockSize) > inp.length) {
      throw ArgumentError('Input buffer too short');
    }

    for (var i = 0; i < blockSize; i++) {
      _xPrev[i] ^= inp[inpOff + i];
    }

    var length = _underlyingCipher.processBlock(_xPrev, 0, out, outOff);

    for (var i = 0; i < blockSize; i++) {
      out[outOff + i] ^= _yPrev[i];
    }

    arrayCopy(inp, inpOff, _yPrev, 0, blockSize);
    arrayCopy(out, outOff, _xPrev, 0, blockSize);

    return length;
  }

  int _decryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if ((inpOff + blockSize) > inp.length) {
      throw ArgumentError('Input buffer too short');
    }

    for (var i = 0; i < blockSize; i++) {
      _yPrev[i] ^= inp[inpOff + i];
    }

    var length = _underlyingCipher.processBlock(_yPrev, 0, out, outOff);

    for (var i = 0; i < blockSize; i++) {
      out[outOff + i] ^= _xPrev[i];
    }

    arrayCopy(out, outOff, _yPrev, 0, blockSize);
    arrayCopy(inp, inpOff, _xPrev, 0, blockSize);

    return length;
  }
}
