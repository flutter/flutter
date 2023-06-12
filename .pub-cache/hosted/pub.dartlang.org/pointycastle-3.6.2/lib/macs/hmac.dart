// See file LICENSE for more information.

library impl.mac.hmac;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_mac.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// HMAC implementation based on RFC2104
///
/// H(K XOR opad, H(K XOR ipad, text))
class HMac extends BaseMac {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
    Mac,
    '/HMAC',
    (_, Match match) {
      final digestName = match.group(1);
      return () {
        return HMac.withDigest(Digest(digestName!));
      };
    },
  );

  //TODO reindent

  static final _ipad = 0x36;
  static final _opad = 0x5C;

  final Digest _digest;
  late int _digestSize;
  late int _blockLength;

  late Uint8List _inputPad;
  late Uint8List _outputBuf;

  HMac(this._digest, this._blockLength) {
    _digestSize = _digest.digestSize;
    _inputPad = Uint8List(_blockLength);
    _outputBuf = Uint8List(_blockLength + _digestSize);
  }

  HMac.withDigest(this._digest) {
    _blockLength = _digest.byteLength;

    _digestSize = _digest.digestSize;
    _inputPad = Uint8List(_blockLength);
    _outputBuf = Uint8List(_blockLength + _digestSize);
  }

  @override
  String get algorithmName => '${_digest.algorithmName}/HMAC';

  @override
  int get macSize => _digestSize;

  @override
  void reset() {
    // reset the underlying digest.
    _digest.reset();

    // reinitialize the digest.
    _digest.update(_inputPad, 0, _inputPad.length);
  }

  @override
  void init(covariant KeyParameter params) {
    _digest.reset();

    var key = params.key;
    var keyLength = key.length;

    if (keyLength > _blockLength) {
      _digest.update(key, 0, keyLength);
      _digest.doFinal(_inputPad, 0);

      keyLength = _digestSize;
    } else {
      _inputPad.setRange(0, keyLength, key);
    }

    _inputPad.fillRange(keyLength, _inputPad.length, 0);

    _outputBuf.setRange(0, _blockLength, _inputPad);

    _xorPad(_inputPad, _blockLength, _ipad);
    _xorPad(_outputBuf, _blockLength, _opad);

    _digest.update(_inputPad, 0, _inputPad.length);
  }

  @override
  void updateByte(int inp) {
    _digest.updateByte(inp);
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    _digest.update(inp, inpOff, len);
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    _digest.doFinal(_outputBuf, _blockLength);
    _digest.update(_outputBuf, 0, _outputBuf.length);

    var len = _digest.doFinal(out, outOff);
    _outputBuf.fillRange(_blockLength, _outputBuf.length, 0);
    _digest.update(_inputPad, 0, _inputPad.length);

    return len;
  }

  void _xorPad(Uint8List pad, int len, int n) {
    for (var i = 0; i < len; i++) {
      pad[i] ^= n;
    }
  }
}
