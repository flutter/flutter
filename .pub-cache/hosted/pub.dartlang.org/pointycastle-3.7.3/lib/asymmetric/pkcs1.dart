// See file LICENSE for more information.

library impl.asymmetric_block_cipher.pkcs1;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/src/impl/base_asymmetric_block_cipher.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:pointycastle/src/registry/registry.dart';

class PKCS1Encoding extends BaseAsymmetricBlockCipher {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      AsymmetricBlockCipher,
      '/PKCS1',
      (_, final Match match) => () {
            var underlyingCipher = AsymmetricBlockCipher(match.group(1)!);
            return PKCS1Encoding(underlyingCipher);
          });

  static const _HEADER_LENGTH = 10;

  final AsymmetricBlockCipher _engine;

  late SecureRandom _random;
  late bool _forEncryption;
  late bool _forPrivateKey;

  PKCS1Encoding(this._engine);

  @override
  String get algorithmName => '${_engine.algorithmName}/PKCS1';

  @override
  void reset() {}

  Uint8List _seed() {
    return Platform.instance.platformEntropySource().getBytes(32);
  }

  @override
  void init(bool forEncryption, CipherParameters params) {
    AsymmetricKeyParameter akparams;

    if (params is ParametersWithRandom) {
      var paramswr = params;

      _random = paramswr.random;
      akparams = paramswr.parameters as AsymmetricKeyParameter<AsymmetricKey>;
    } else {
      _random = FortunaRandom();
      _random.seed(KeyParameter(_seed()));
      akparams = params as AsymmetricKeyParameter<AsymmetricKey>;
    }

    _engine.init(forEncryption, akparams);

    _forPrivateKey = (akparams.key is PrivateKey);
    _forEncryption = forEncryption;
  }

  @override
  int get inputBlockSize {
    var baseBlockSize = _engine.inputBlockSize;

    if (_forEncryption) {
      return baseBlockSize - _HEADER_LENGTH;
    } else {
      return baseBlockSize;
    }
  }

  @override
  int get outputBlockSize {
    var baseBlockSize = _engine.outputBlockSize;

    if (_forEncryption) {
      return baseBlockSize;
    } else {
      return baseBlockSize - _HEADER_LENGTH;
    }
  }

  @override
  int processBlock(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    if (_forEncryption) {
      return _encodeBlock(inp, inpOff, len, out, outOff);
    } else {
      return _decodeBlock(inp, inpOff, len, out, outOff);
    }
  }

  int _encodeBlock(
      Uint8List inp, int inpOff, int inpLen, Uint8List out, int outOff) {
    if (inpLen > inputBlockSize) {
      throw ArgumentError('Input data too large');
    }

    var block = Uint8List(_engine.inputBlockSize);
    var padLength = (block.length - inpLen - 1);

    if (_forPrivateKey) {
      block[0] = 0x01; // type code 1
      block.fillRange(1, padLength, 0xFF);
    } else {
      block[0] = 0x02; // type code 2
      block.setRange(1, padLength, _random.nextBytes(padLength - 1));

      // a zero byte marks the end of the padding, so all
      // the pad bytes must be non-zero.
      for (var i = 1; i < padLength; i++) {
        while (block[i] == 0) {
          block[i] = _random.nextUint8();
        }
      }
    }

    block[padLength] = 0x00; // mark the end of the padding
    block.setRange(padLength + 1, block.length, inp.sublist(inpOff));

    return _engine.processBlock(block, 0, block.length, out, outOff);
  }

  int _decodeBlock(
      Uint8List inp, int inpOff, int inpLen, Uint8List out, int outOff) {
    var block = Uint8List(_engine.inputBlockSize);
    var len = _engine.processBlock(inp, inpOff, inpLen, block, 0);
    block = block.sublist(0, len);

    if (block.length < outputBlockSize) {
      throw ArgumentError('Block truncated');
    }

    var type = block[0];

    if (_forPrivateKey && (type != 2)) {
      throw ArgumentError('Unsupported block type for private key: $type');
    }
    if (!_forPrivateKey && (type != 1)) {
      throw ArgumentError('Unsupported block type for public key: $type');
    }
    if (block.length != _engine.outputBlockSize) {
      throw ArgumentError('Block size is incorrect: ${block.length}');
    }

    // find and extract the message block.
    int start;

    for (start = 1; start < block.length; start++) {
      var pad = block[start];

      if (pad == 0) {
        break;
      }
      if (type == 1 && (pad != 0xFF)) {
        throw ArgumentError('Incorrect block padding');
      }
    }

    start++; // data should start at the next byte

    if ((start > block.length) || (start < _HEADER_LENGTH)) {
      throw ArgumentError('No data found in block, only padding');
    }

    var rlen = (block.length - start);
    out.setRange(outOff, outOff + rlen, block.sublist(start));
    return rlen;
  }
}
