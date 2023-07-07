// See file LICENSE for more information.

library impl.key_derivator.pbkdf2;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/impl/base_key_derivator.dart';

/// Generator for PBE derived keys and ivs as defined by PKCS 5 V2.0 Scheme 2. This generator uses a SHA-1 HMac as the
/// calculation function. The document this implementation is based on can be found at:
///
/// * [http://www.rsasecurity.com/rsalabs/pkcs/pkcs-5/index.html]
///
class PBKDF2KeyDerivator extends BaseKeyDerivator {
  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      KeyDerivator,
      '/PBKDF2',
      (_, final Match match) => () {
            var mac = Mac(match.group(1)!);
            return PBKDF2KeyDerivator(mac);
          });

  late Pbkdf2Parameters _params;
  final Mac _mac;
  late Uint8List _state;

  PBKDF2KeyDerivator(this._mac) {
    _state = Uint8List(_mac.macSize);
  }

  @override
  String get algorithmName => '${_mac.algorithmName}/PBKDF2';

  @override
  int get keySize => _params.desiredKeyLength;

  void reset() {
    _mac.reset();
    _state.fillRange(0, _state.length, 0);
  }

  @override
  void init(covariant Pbkdf2Parameters params) {
    _params = params;
  }

  @override
  int deriveKey(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    var dkLen = _params.desiredKeyLength;
    var hLen = _mac.macSize;
    var l = (dkLen + hLen - 1) ~/ hLen;
    var iBuf = Uint8List(4);
    var outBytes = Uint8List(l * hLen);
    var outPos = 0;

    CipherParameters param = KeyParameter(inp.sublist(inpOff));
    _mac.init(param);

    for (var i = 1; i <= l; i++) {
      // Increment the value in 'iBuf'
      for (var pos = 3;; pos--) {
        iBuf[pos]++;
        if (iBuf[pos] != 0) break;
      }

      _f(_params.salt, _params.iterationCount, iBuf, outBytes, outPos);
      outPos += hLen;
    }

    out.setRange(outOff, outOff + dkLen, outBytes);

    return keySize;
  }

  void _f(Uint8List? S, int c, Uint8List iBuf, Uint8List out, int outOff) {
    if (c <= 0) {
      throw ArgumentError('Iteration count must be at least 1.');
    }

    if (S != null) {
      _mac.update(S, 0, S.length);
    }

    _mac.update(iBuf, 0, iBuf.length);
    _mac.doFinal(_state, 0);

    out.setRange(outOff, outOff + _state.length, _state);

    for (var count = 1; count < c; count++) {
      _mac.update(_state, 0, _state.length);
      _mac.doFinal(_state, 0);

      for (var j = 0; j != _state.length; j++) {
        out[outOff + j] ^= _state[j];
      }
    }
  }
}
