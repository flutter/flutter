// See file LICENSE for more information.

library impl.asymmetric_block_cipher.rsa;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/src/impl/base_asymmetric_block_cipher.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/utils.dart' as utils;

class RSAEngine extends BaseAsymmetricBlockCipher {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(AsymmetricBlockCipher, 'RSA', () => RSAEngine());

  late bool _forEncryption;
  RSAAsymmetricKey? _key;
  late BigInt _dP;
  late BigInt _dQ;
  late BigInt _qInv;

  @override
  String get algorithmName => 'RSA';

  @override
  int get inputBlockSize {
    if (_key == null) {
      throw StateError(
          'Input block size cannot be calculated until init() called');
    }

    var bitSize = _key!.modulus!.bitLength;
    if (_forEncryption) {
      return ((bitSize + 7) ~/ 8) - 1;
    } else {
      return (bitSize + 7) ~/ 8;
    }
  }

  @override
  int get outputBlockSize {
    if (_key == null) {
      throw StateError(
          'Output block size cannot be calculated until init() called');
    }

    var bitSize = _key!.modulus!.bitLength;
    if (_forEncryption) {
      return (bitSize + 7) ~/ 8;
    } else {
      return ((bitSize + 7) ~/ 8) - 1;
    }
  }

  @override
  void reset() {}

  @override
  void init(bool forEncryption,
      covariant AsymmetricKeyParameter<RSAAsymmetricKey> params) {
    _forEncryption = forEncryption;
    _key = params.key;

    if (_key is RSAPrivateKey) {
      var privKey = (_key as RSAPrivateKey);
      var pSub1 = (privKey.p! - BigInt.one);
      var qSub1 = (privKey.q! - BigInt.one);
      _dP = privKey.privateExponent!.remainder(pSub1);
      _dQ = privKey.privateExponent!.remainder(qSub1);
      _qInv = privKey.q!.modInverse(privKey.p!);
    }
  }

  @override
  Uint8List process(Uint8List data) {
    // Expand the output block size by an extra byte to handle cases where
    // the output is larger than expected.
    var out = Uint8List(outputBlockSize + 1);
    var len = processBlock(data, 0, data.length, out, 0);
    return out.sublist(0, len);
  }

  @override
  int processBlock(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    var input = _convertInput(inp, inpOff, len);
    var output = _processBigInteger(input);
    return _convertOutput(output, out, outOff);
  }

  BigInt _convertInput(Uint8List inp, int inpOff, int len) {
    var inpLen = inp.length;

    if (inpLen < inpOff + len) {
      throw ArgumentError.value(inpOff, 'inpOff',
          'Not enough data for RSA cipher (length=$len, available=$inpLen)');
    }

    if (inputBlockSize + 1 < len) {
      throw ArgumentError.value(len, 'len',
          'Too large for maximum RSA cipher input block size ($inputBlockSize)');
    }

    var res = utils.decodeBigIntWithSign(1, inp.sublist(inpOff, inpOff + len));
    if (res >= _key!.modulus!) {
      throw ArgumentError('Input block too large for RSA key size');
    }

    return res;
  }

  int _convertOutput(BigInt result, Uint8List out, int outOff) {
    final output = utils.encodeBigInt(result);

    if (_forEncryption) {
      if ((output[0] == 0) && (output.length > outputBlockSize)) {
        // have ended up with an extra zero byte, copy down.
        var len = (output.length - 1);
        out.setRange(outOff, outOff + len, output.sublist(1));
        return len;
      }
      if (output.length < outputBlockSize) {
        // have ended up with less bytes than normal, lengthen
        var len = outputBlockSize;
        out.setRange((outOff + len - output.length), (outOff + len), output);
        return len;
      }
    } else {
      if (output[0] == 0) {
        // have ended up with an extra zero byte, copy down.
        var len = (output.length - 1);
        out.setRange(outOff, outOff + len, output.sublist(1));
        return len;
      }
    }

    out.setAll(outOff, output);
    return output.length;
  }

  BigInt _processBigInteger(BigInt input) {
    if (_key is RSAPrivateKey) {
      var privKey = (_key as RSAPrivateKey);
      BigInt mP, mQ, h, m;

      mP = (input.remainder(privKey.p!)).modPow(_dP, privKey.p!);

      mQ = (input.remainder(privKey.q!)).modPow(_dQ, privKey.q!);

      h = mP - mQ;
      h = h * _qInv;
      h = h % privKey.p!;

      m = h * privKey.q!;
      m = m + mQ;

      return m;
    } else {
      return input.modPow(_key!.exponent!, _key!.modulus!);
    }
  }
}
