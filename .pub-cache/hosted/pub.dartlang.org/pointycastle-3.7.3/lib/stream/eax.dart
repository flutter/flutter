// See file LICENSE for more information.

library impl.stream_cipher.eax;

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/macs/cmac.dart';
import 'package:pointycastle/src/impl/base_aead_cipher.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/utils.dart';
import 'package:pointycastle/stream/ctr.dart';

/// EAX mode based on CTR and CMAC/OMAC1.
///
/// Encrypts plaintext and outputs the ciphertext with the concatenated mac.
/// Decrypts and verifies ciphertext with the concatenated mac and returns the plaintext.
/// Ported from BouncyCastle's Java impl: https://github.com/bcgit/bc-java/blob/master/core/src/main/java/org/bouncycastle/crypto/modes/EAXBlockCipher.java
class EAX extends BaseAEADCipher {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      AEADCipher,
      '/EAX',
      (_, final Match match) => () {
            var digestName = match.group(1);
            return EAX(BlockCipher(digestName!));
          });

  static const _nonceTAG = 0x0;
  static const _aadTAG = 0x1;
  static const _cipherTAG = 0x2;

  final CTRStreamCipher _ctr;
  final CMac _cMac;
  late bool _forEncryption;
  late KeyParameter _keyParam;
  late CipherParameters _initParams;
  late Uint8List _nonceMac;
  late Uint8List _aadMac;
  late Uint8List _cipherMac;
  late Uint8List _bufBlock;
  late int _bufOff;
  late bool _bufFull;
  late bool _aadFinished;

  int get _blockSize => underlyingCipher.blockSize;

  /// The cipher used in CTR and CMAC
  final BlockCipher underlyingCipher;

  int _macSize;

  /// The byte size that the [mac] calculated by [doFinal] must be.
  int get macSize => _macSize;

  /// The MAC (also known as Tag), calculated and cached by [doFinal].
  ///
  /// Will not be cleared on [reset] or [init].
  @override
  late Uint8List mac;

  @override
  String get algorithmName => '${underlyingCipher.algorithmName}/EAX';

  EAX(this.underlyingCipher)
      : _ctr = CTRStreamCipher(underlyingCipher),
        _cMac = CMac(underlyingCipher, underlyingCipher.blockSize * 8),
        _macSize = underlyingCipher.blockSize ~/ 2;

  /// Initializes this for addition of AAD and en/decryption of data.
  @override
  void init(bool forEncryption, CipherParameters params) {
    _forEncryption = forEncryption;
    _initParams = params;
    Uint8List initNonce;
    Uint8List? initAAD;

    if (params is AEADParameters) {
      _macSize = params.macSize ~/ 8;
      _keyParam = params.parameters as KeyParameter;
      initNonce = params.nonce;
      initAAD = params.associatedData;
    } else if (params is ParametersWithIV) {
      _keyParam = params.parameters as KeyParameter;
      initNonce = params.iv;
    } else {
      throw ArgumentError(
          '${params.runtimeType} is not ParametersWithIV or AEADParameters',
          'params');
    }

    _nonceMac = Uint8List(_blockSize);
    _cMac
      ..init(_keyParam)
      ..update(
          Uint8List(_blockSize)..[_blockSize - 1] = _nonceTAG, 0, _blockSize)
      ..update(initNonce, 0, initNonce.length)
      ..doFinal(_nonceMac, 0);

    _aadFinished = false;
    _aadMac = Uint8List(_blockSize);
    _cMac
      ..init(_keyParam)
      ..update(
          Uint8List(_blockSize)..[_blockSize - 1] = _aadTAG, 0, _blockSize);
    if (initAAD != null) processAADBytes(initAAD, 0, initAAD.length);

    _cipherMac = Uint8List(_blockSize);
    _ctr.init(_forEncryption, ParametersWithIV(_keyParam, _nonceMac));

    _bufBlock = Uint8List(_macSize);
    _bufOff = 0;
    _bufFull = false;
  }

  /// Calculates, caches and if used as decrypter also verifies this [mac],
  /// calls [reset] and returns the number of bytes written.
  @override
  int doFinal(Uint8List out, int outOff) {
    _cMac.doFinal(_cipherMac, 0);
    _calculateMac();

    if (_forEncryption) {
      if (out.length < outOff + _macSize) {
        throw ArgumentError(
            'actual length: ${out.length}, '
                'min: ${outOff + _macSize}',
            'out');
      }
      out.setAll(outOff, mac);

      reset();
      return _macSize;
    } else {
      if (!_bufFull) {
        throw StateError('Did not process enough data '
            'for MAC to be collected from input.');
      }
      if (!_verifyMac(_inMac, 0)) {
        throw StateError('MAC does not match.');
      }

      reset();
      return 0;
    }
  }

  /// Initializes this with the parameters last given to [init].
  @override
  void reset() {
    init(_forEncryption, _initParams);
  }

  /// Processes further AAD.
  ///
  /// Must not be used when en-/decryption of data had begun.
  @override
  void processAADByte(int inp) {
    if (_aadFinished) {
      throw StateError('Must not be used when en-/decryption '
          'of data had begun.');
    }
    _cMac.updateByte(inp);
  }

  /// Processes further AAD.
  ///
  /// Must not be used after en-/decryption of data has begun.
  @override
  void processAADBytes(Uint8List inp, int inpOff, int len) {
    if (_aadFinished) {
      throw StateError('Must not be used when en-/decryption '
          'of data had begun.');
    }
    _cMac.update(inp, inpOff, len);
  }

  /// Processes the input and returns the amount of bytes written.
  @override
  int processByte(int inp, Uint8List out, int outOff) {
    _ensureAadMacFinished();

    var r = out[outOff] = _ctr.returnByte(inp);

    if (_forEncryption) {
      _cMac.updateByte(r);
      return 1;
    }
    return _bufByte(inp);
  }

  /// Processes the input and returns the amount of bytes written.
  @override
  int processBytes(
      Uint8List inp, int inOff, int len, Uint8List out, int outOff) {
    _ensureAadMacFinished();

    if (_forEncryption) {
      _ctr.processBytes(inp, inOff, len, out, outOff);
      _cMac.update(out, outOff, len);
      return len;
    } else {
      return _buf(inp, inOff, len, out, outOff);
    }
  }

  /// Returns the amount of bytes being outputted
  /// by the next [processBytes] and [doFinal] for [len] bytes input.
  @override
  int getOutputSize(int len) {
    if (_forEncryption) {
      return len + _macSize;
    } else if (_bufFull) {
      return len;
    } else {
      return max(0, len + _bufOff - _macSize);
    }
  }

  /// Returns the amount of bytes being outputted
  /// by the next [processBytes] for [len] bytes input.
  @override
  int getUpdateOutputSize(int len) {
    if (_forEncryption) {
      return len;
    } else if (_bufFull) {
      return len;
    } else {
      return max(0, len + _bufOff - _macSize);
    }
  }

  /// Returns true if provided [match] is equal to this [mac].
  bool _verifyMac(Uint8List match, int off) {
    return constantTimeAreEqualOffset(_macSize, mac, 0, match, off);
  }

  void _ensureAadMacFinished() {
    if (!_aadFinished) {
      _cMac
        ..doFinal(_aadMac, 0)
        ..init(_keyParam)
        ..update(Uint8List(_blockSize)..[_blockSize - 1] = _cipherTAG, 0,
            _blockSize);
      _aadFinished = true;
    }
  }

  Uint8List get _inMac {
    var inMac = Uint8List(_macSize);
    for (var i = 0; i < _macSize; i++) {
      inMac[i] = _bufBlock[_bufOff + i];
    }
    return inMac;
  }

  int _buf(Uint8List inp, int inOff, int len, Uint8List out, int outOff) {
    var macLen = min(_macSize, len);
    var macOff = inOff + len - macLen;
    var processed = len - macLen;

    _cMac.update(inp, inOff, processed);
    _ctr.processBytes(inp, inOff, processed, out, outOff);

    for (var i = 0; i < macLen; i++) {
      if (_bufFull) {
        _cMac.updateByte(_bufBlock[_bufOff]);
        out[outOff + processed + i] = _ctr.returnByte(_bufBlock[_bufOff]);
        processed++;
      }

      _bufBlock[_bufOff] = inp[macOff + i];

      if (_bufOff == _macSize - 1) {
        _bufOff = 0;
        _bufFull = true;
      } else {
        _bufOff++;
      }
    }
    return processed;
  }

  int _bufByte(int inp) {
    var r = 1;
    if (_bufFull) {
      _cMac.updateByte(_bufBlock[_bufOff]);
      _ctr.returnByte(_bufBlock[_bufOff]);
    } else {
      r = 0;
    }

    _bufBlock[_bufOff] = inp;

    if (_bufOff == 15) {
      _bufOff = 0;
      _bufFull = true;
    } else {
      _bufOff++;
    }
    return r;
  }

  void _calculateMac() {
    mac = Uint8List(_macSize);
    for (var i = 0; i < _macSize; i++) {
      mac[i] = _nonceMac[i] ^ _aadMac[i] ^ _cipherMac[i];
    }
  }
}
