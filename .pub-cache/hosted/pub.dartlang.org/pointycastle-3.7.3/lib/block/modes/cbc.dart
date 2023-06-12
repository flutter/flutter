// See file LICENSE for more information.

library impl.block_cipher.modes.cbc;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';

/// Implementation of Cipher-Block-Chaining (CBC) mode on top of a [BlockCipher].
class CBCBlockCipher extends BaseBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      BlockCipher,
      '/CBC',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            return CBCBlockCipher(underlying);
          });

  final BlockCipher _underlyingCipher;

  late Uint8List _iv;
  Uint8List? _cbcV;
  Uint8List? _cbcNextV;

  late bool _encrypting;

  CBCBlockCipher(this._underlyingCipher) {
    _iv = Uint8List(blockSize);
    _cbcV = Uint8List(blockSize);
    _cbcNextV = Uint8List(blockSize);
  }

  @override
  String get algorithmName => '${_underlyingCipher.algorithmName}/CBC';
  @override
  int get blockSize => _underlyingCipher.blockSize;

  @override
  void reset() {
    _cbcV!.setAll(0, _iv);
    _cbcNextV!.fillRange(0, _cbcNextV!.length, 0);

    _underlyingCipher.reset();
  }

  @override
  void init(bool forEncryption, covariant ParametersWithIV params) {
    if (params.iv.length != blockSize) {
      throw ArgumentError(
          'Initialization vector must be the same length as block size');
    }

    _encrypting = forEncryption;
    _iv.setAll(0, params.iv);

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

    // XOR the cbcV and the input, then encrypt the cbcV
    for (var i = 0; i < blockSize; i++) {
      _cbcV![i] ^= inp[inpOff + i];
    }

    var length = _underlyingCipher.processBlock(_cbcV!, 0, out, outOff);

    // copy ciphertext to cbcV
    _cbcV!.setRange(0, blockSize,
        Uint8List.view(out.buffer, out.offsetInBytes + outOff, blockSize));

    return length;
  }

  int _decryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if ((inpOff + blockSize) > inp.length) {
      throw ArgumentError('Input buffer too short');
    }

    _cbcNextV!.setRange(0, blockSize,
        Uint8List.view(inp.buffer, inp.offsetInBytes + inpOff, blockSize));

    var length = _underlyingCipher.processBlock(inp, inpOff, out, outOff);

    // XOR the cbcV and the output
    for (var i = 0; i < blockSize; i++) {
      out[outOff + i] ^= _cbcV![i];
    }

    // swap the back up buffer into next position
    Uint8List? tmp;

    tmp = _cbcV;
    _cbcV = _cbcNextV;
    _cbcNextV = tmp;

    return length;
  }
}
