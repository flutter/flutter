// See file LICENSE for more information.

library impl.block_cipher.modes.ofb;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';

/// Implementation of Output FeedBack mode (OFB) on top of a [BlockCipher].
class OFBBlockCipher extends BaseBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.regex(
      BlockCipher,
      r'^(.+)/OFB-([0-9]+)$',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            var blockSizeInBits = int.parse(match.group(2)!);
            if ((blockSizeInBits % 8) != 0) {
              throw RegistryFactoryException.invalid(
                  'Bad OFB block size: $blockSizeInBits (must be a multiple of 8)');
            }
            return OFBBlockCipher(underlying, blockSizeInBits ~/ 8);
          });

  @override
  final int blockSize;

  final BlockCipher _underlyingCipher;

  late Uint8List _iv;
  Uint8List? _ofbV;
  Uint8List? _ofbOutV;

  OFBBlockCipher(this._underlyingCipher, this.blockSize) {
    _iv = Uint8List(_underlyingCipher.blockSize);
    _ofbV = Uint8List(_underlyingCipher.blockSize);
    _ofbOutV = Uint8List(_underlyingCipher.blockSize);
  }

  @override
  String get algorithmName =>
      '${_underlyingCipher.algorithmName}/OFB-${blockSize * 8}';

  @override
  void reset() {
    _ofbV!.setRange(0, _iv.length, _iv);
    _underlyingCipher.reset();
  }

  /// Initialise the cipher and, possibly, the initialisation vector (IV). If an IV isn't passed as part of the parameter, the
  /// IV will be all zeros. An IV which is too short is handled in FIPS compliant fashion.
  @override
  void init(bool forEncryption, CipherParameters? params) {
    if (params is ParametersWithIV) {
      var ivParam = params;
      var iv = ivParam.iv;

      if (iv.length < _iv.length) {
        // prepend the supplied IV with zeros (per FIPS PUB 81)
        var offset = _iv.length - iv.length;
        _iv.fillRange(0, offset, 0);
        _iv.setAll(offset, iv);
      } else {
        _iv.setRange(0, _iv.length, iv);
      }

      reset();

      // if null it's an IV changed only.
      if (ivParam.parameters != null) {
        _underlyingCipher.init(true, ivParam.parameters);
      }
    } else {
      _underlyingCipher.init(true, params);
    }
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if ((inpOff + blockSize) > inp.length) {
      throw ArgumentError('Input buffer too short');
    }

    if ((outOff + blockSize) > out.length) {
      throw ArgumentError('Output buffer too short');
    }

    _underlyingCipher.processBlock(_ofbV!, 0, _ofbOutV!, 0);

    // XOR the ofbV with the plaintext producing the cipher text (and the next input block).
    for (var i = 0; i < blockSize; i++) {
      out[outOff + i] = _ofbOutV![i] ^ inp[inpOff + i];
    }

    // change over the input block.
    var offset = _ofbV!.length - blockSize;
    _ofbV!.setRange(0, offset, _ofbV!.sublist(blockSize));
    _ofbV!.setRange(offset, _ofbV!.length, _ofbOutV!);

    return blockSize;
  }
}
