// See file LICENSE for more information.

library impl.block_cipher.modes.gctr;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_block_cipher.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of GOST 28147 OFB counter mode (GCTR) on top of a [BlockCipher].
class GCTRBlockCipher extends BaseBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      BlockCipher,
      '/GCTR',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            return GCTRBlockCipher(underlying);
          });

  static const C1 = 16843012; //00000001000000010000000100000100
  static const C2 = 16843009; //00000001000000010000000100000001

  final BlockCipher _underlyingCipher;

  late Uint8List _iv;
  Uint8List? _ofbV;
  Uint8List? _ofbOutV;

  bool _firstStep = true;
  late int _n3;
  late int _n4;

  GCTRBlockCipher(this._underlyingCipher) {
    if (blockSize != 8) {
      throw ArgumentError('GCTR can only be used with 64 bit block ciphers');
    }

    _iv = Uint8List(_underlyingCipher.blockSize);
    _ofbV = Uint8List(_underlyingCipher.blockSize);
    _ofbOutV = Uint8List(_underlyingCipher.blockSize);
  }

  @override
  int get blockSize => _underlyingCipher.blockSize;
  @override
  String get algorithmName => '${_underlyingCipher.algorithmName}/GCTR';
  @override
  void reset() {
    _ofbV!.setRange(0, _iv.length, _iv);
    _underlyingCipher.reset();
  }

  /// Initialise the cipher and, possibly, the initialisation vector (IV).
  /// If an IV isn't passed as part of the parameter, the IV will be all zeros.
  /// An IV which is too short is handled in FIPS compliant fashion.
  ///
  /// @param encrypting if true the cipher is initialised for
  ///  encryption, if false for decryption. //ignored by this CTR mode
  /// @param params the key and other data required by the cipher.
  /// @exception IllegalArgumentException if the params argument is
  /// inappropriate.
  @override
  void init(bool encrypting, CipherParameters? params) {
    _firstStep = true;
    _n3 = 0;
    _n4 = 0;

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

      // if params is null we reuse the current working key.
      if (ivParam.parameters != null) {
        _underlyingCipher.init(true, ivParam.parameters);
      }
    } else {
      // TODO: make this behave in a standard way (as the other modes of operation)
      reset();

      // if params is null we reuse the current working key.
      if (params != null) {
        _underlyingCipher.init(true, params);
      }
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

    if (_firstStep) {
      _firstStep = false;
      _underlyingCipher.processBlock(_ofbV!, 0, _ofbOutV!, 0);
      _n3 = _bytesToint(_ofbOutV, 0);
      _n4 = _bytesToint(_ofbOutV, 4);
    }
    _n3 += C2;
    _n4 += C1;
    _intTobytes(_n3, _ofbV, 0);
    _intTobytes(_n4, _ofbV, 4);

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

  int _bytesToint(Uint8List? inp, int inpOff) {
    return unpack32(inp, inpOff, Endian.little);
  }

  void _intTobytes(int num, Uint8List? out, int outOff) {
    pack32(num, out, outOff, Endian.little);
  }
}
