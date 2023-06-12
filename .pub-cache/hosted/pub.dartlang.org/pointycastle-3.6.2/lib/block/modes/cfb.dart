// See file LICENSE for more information.

library impl.block_cipher.modes.cfb;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';

/// Implementation of Cipher Feedback Mode (CFB) on top of a [BlockCipher].
class CFBBlockCipher extends BaseBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      BlockCipher,
      r'^(.+)/CFB-([0-9]+)$',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            var blockSizeInBits = int.parse(match.group(2)!);
            if ((blockSizeInBits % 8) != 0) {
              throw RegistryFactoryException.invalid(
                  'Bad CFB block size: $blockSizeInBits (must be a multiple of 8)');
            }
            return CFBBlockCipher(underlying, blockSizeInBits ~/ 8);
          });

  @override
  final int blockSize;

  final BlockCipher _underlyingCipher;

  late Uint8List _iv;
  Uint8List? _cfbV;
  Uint8List? _cfbOutV;
  late bool _encrypting;

  CFBBlockCipher(this._underlyingCipher, this.blockSize) {
    _iv = Uint8List(_underlyingCipher.blockSize);
    _cfbV = Uint8List(_underlyingCipher.blockSize);
    _cfbOutV = Uint8List(_underlyingCipher.blockSize);
  }

  @override
  String get algorithmName =>
      '${_underlyingCipher.algorithmName}/CFB-${blockSize * 8}';

  @override
  void reset() {
    _cfbV!.setRange(0, _iv.length, _iv);
    _underlyingCipher.reset();
  }

  /// Initialise the cipher and, possibly, the initialisation vector (IV).
  /// If an IV isn't passed as part of the parameter, the IV will be all zeros.
  /// An IV which is too short is handled in FIPS compliant fashion.
  ///
  /// @param encrypting if true the cipher is initialised for
  ///  encryption, if false for decryption.
  /// @param params the key and other data required by the cipher.
  /// @exception IllegalArgumentException if the params argument is
  /// inappropriate.
  @override
  void init(bool encrypting, CipherParameters? params) {
    _encrypting = encrypting;

    if (params is ParametersWithIV) {
      var ivParam = params;
      var iv = ivParam.iv;

      if (iv.length < _iv.length) {
        // prepend the supplied IV with zeros (per FIPS PUB 81)
        var offset = _iv.length - iv.length;
        _iv.fillRange(0, offset, 0);
        _iv.setRange(offset, _iv.length, iv);
      } else {
        _iv.setRange(0, _iv.length, iv);
      }

      reset();

      // if null it's an IV changed only.
      if (ivParam.parameters != null) {
        _underlyingCipher.init(true, ivParam.parameters);
      }
    } else {
      reset();
      _underlyingCipher.init(true, params);
    }
  }

  /// Process one block of input from the array in and write it to
  /// the out array.
  ///
  /// @param in the array containing the input data.
  /// @param inOff offset into the in array the data starts at.
  /// @param out the array the output data will be copied into.
  /// @param outOff the offset into the out array the output will start at.
  /// @exception DataLengthException if there isn't enough data in in, or
  /// space in out.
  /// @exception IllegalStateException if the cipher isn't initialised.
  /// @return the number of bytes processed and produced.
  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) =>
      _encrypting
          ? _encryptBlock(inp, inpOff, out, outOff)
          : _decryptBlock(inp, inpOff, out, outOff);

  /// Do the appropriate processing for CFB mode encryption.
  ///
  /// @param in the array containing the data to be encrypted.
  /// @param inOff offset into the in array the data starts at.
  /// @param out the array the encrypted data will be copied into.
  /// @param outOff the offset into the out array the output will start at.
  /// @exception DataLengthException if there isn't enough data in in, or
  /// space in out.
  /// @exception IllegalStateException if the cipher isn't initialised.
  /// @return the number of bytes processed and produced.
  int _encryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if ((inpOff + blockSize) > inp.length) {
      throw ArgumentError('Input buffer too short');
    }

    if ((outOff + blockSize) > out.length) {
      throw ArgumentError('Output buffer too short');
    }

    _underlyingCipher.processBlock(_cfbV!, 0, _cfbOutV!, 0);

    // XOR the cfbV with the plaintext producing the ciphertext
    for (var i = 0; i < blockSize; i++) {
      out[outOff + i] = _cfbOutV![i] ^ inp[inpOff + i];
    }

    // change over the input block.
    var offset = _cfbV!.length - blockSize;
    _cfbV!.setRange(0, offset, _cfbV!.sublist(blockSize));
    _cfbV!.setRange(offset, _cfbV!.length, out.sublist(outOff));

    return blockSize;
  }

  /// Do the appropriate processing for CFB mode decryption.
  ///
  /// @param in the array containing the data to be decrypted.
  /// @param inOff offset into the in array the data starts at.
  /// @param out the array the encrypted data will be copied into.
  /// @param outOff the offset into the out array the output will start at.
  /// @exception DataLengthException if there isn't enough data in in, or
  /// space in out.
  /// @exception IllegalStateException if the cipher isn't initialised.
  /// @return the number of bytes processed and produced.
  int _decryptBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if ((inpOff + blockSize) > inp.length) {
      throw ArgumentError('Input buffer too short');
    }

    if ((outOff + blockSize) > out.length) {
      throw ArgumentError('Output buffer too short');
    }

    _underlyingCipher.processBlock(_cfbV!, 0, _cfbOutV!, 0);

    // change over the input block.
    var offset = _cfbV!.length - blockSize;
    _cfbV!.setRange(0, offset, _cfbV!.sublist(blockSize));
    _cfbV!.setRange(offset, _cfbV!.length, inp.sublist(inpOff));

    // XOR the cfbV with the ciphertext producing the plaintext
    for (var i = 0; i < blockSize; i++) {
      out[outOff + i] = _cfbOutV![i] ^ inp[inpOff + i];
    }

    return blockSize;
  }
}
