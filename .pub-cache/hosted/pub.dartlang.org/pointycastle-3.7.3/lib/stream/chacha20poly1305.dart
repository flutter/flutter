library impl.stream_cipher.chacha20poly1305;

import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/src/registry/registry.dart';
import '../export.dart';
import '../src/impl/base_aead_cipher.dart';
import '../src/ufixnum.dart';

import '../src/utils.dart' as utils;

// ignore_for_file: non_constant_identifier_names

class ChaCha20Poly1305 extends BaseAEADCipher {
  static final FactoryConfig factoryConfig = StaticFactoryConfig(
      AEADCipher,
      'ChaCha20-Poly1305',
      () => ChaCha20Poly1305(ChaCha7539Engine(), Poly1305()));
  static const BUF_SIZE = 64;
  static const KEY_SIZE = 32;
  static const NONCE_SIZE = 12;
  static const MAC_SIZE = 16;
  static final MAX = pow(2, 63) - 1;
  static final MIN = -pow(2, 63);
  static final Uint8List ZEROES = Uint8List(MAC_SIZE - 1);

  static final int AADLimit = (MAX - MIN).toInt();
  static const DATA_LIMIT = (1 << 32 - 1) * 64;
  final ChaCha7539Engine chacha20;
  final Poly1305 poly1305;

  final Uint8List _key = Uint8List(KEY_SIZE);
  final Uint8List _nonce = Uint8List(NONCE_SIZE);
  final Uint8List _buf = Uint8List(MAC_SIZE + BUF_SIZE);
  final Uint8List _mac = Uint8List(MAC_SIZE);

  @override
  String get algorithmName => 'ChaCha20-Poly1305';

  @override
  Uint8List get mac => _mac;

  Uint8List? _initialAAD;
  late int _aadCount;
  late int _dataCount;
  int _state = State.UNINITIALIZED;
  late int _bufPos;

  ChaCha20Poly1305(this.chacha20, this.poly1305);

  @override
  void init(bool forEncryption, CipherParameters params) {
    KeyParameter initKeyParam;
    Uint8List? initNonce;
    CipherParameters chacha20Params;

    if (params is AEADParameters) {
      var aeadParams = params;

      var macSizeBits = aeadParams.macSize;
      if ((MAC_SIZE * 8) != macSizeBits) {
        throw ArgumentError(
            'Invalid value for MAC size: ' + macSizeBits.toString());
      }

      initKeyParam = aeadParams.parameters as KeyParameter;
      initNonce = aeadParams.nonce;
      chacha20Params = ParametersWithIV(initKeyParam, initNonce);

      _initialAAD = aeadParams.associatedData;
    } else if (params is ParametersWithIV) {
      var ivParams = params;

      initKeyParam = ivParams.parameters as KeyParameter;
      initNonce = ivParams.iv;
      chacha20Params = ivParams;

      _initialAAD = null;
    } else {
      throw ArgumentError('invalid parameters passed to ChaCha20Poly1305');
    }

    // Validate key
    if (KEY_SIZE != initKeyParam.key.length) {
      throw ArgumentError('Key must be 256 bits');
    }

    // Validate nonce
    if (NONCE_SIZE != initNonce.length) {
      throw ArgumentError('Nonce must be 96 bits');
    }

    utils.arrayCopy(initKeyParam.key, 0, _key, 0, KEY_SIZE);

    utils.arrayCopy(initNonce, 0, _nonce, 0, NONCE_SIZE);

    chacha20.init(true, chacha20Params as ParametersWithIV<KeyParameter>);

    _state = forEncryption ? State.ENC_INIT : State.DEC_INIT;

    resetBool(true, false);
  }

  @override
  // ignore: missing_return
  int getOutputSize(int len) {
    var total = max(0, len) + _bufPos;

    switch (_state) {
      case State.DEC_INIT:
      case State.DEC_AAD:
      case State.DEC_DATA:
        return max(0, total - MAC_SIZE);
      case State.ENC_INIT:
      case State.ENC_AAD:
      case State.ENC_DATA:
        return total + MAC_SIZE;
      default:
        throw StateError('state = ' + _state.toString());
    }
  }

  @override
  int getUpdateOutputSize(int len) {
    var total = max(0, len) + _bufPos;

    switch (_state) {
      case State.DEC_INIT:
      case State.DEC_AAD:
      case State.DEC_DATA:
        total = max(0, total - MAC_SIZE);
        break;
      case State.ENC_INIT:
      case State.ENC_AAD:
      case State.ENC_DATA:
        break;
      default:
        throw StateError('');
    }

    return total - (total % BUF_SIZE);
  }

  @override
  void processAADByte(int inp) {
    checkAAD();

    _aadCount = incrementCount(_aadCount, 1, AADLimit);
    poly1305.updateByte(inp);
  }

  @override
  void processAADBytes(Uint8List inp, int inOff, int len) {
    if (inOff < 0) {
      throw ArgumentError('\'inOff\' cannot be negative');
    }
    if (len < 0) {
      throw ArgumentError('\'len\' cannot be negative');
    }
    if (inOff > (inp.length - len)) {
      throw ArgumentError('Input buffer too short');
    }

    checkAAD();

    if (len > 0) {
      _aadCount = incrementCount(_aadCount, len, AADLimit);
      poly1305.update(inp, inOff, len);
    }
  }

  @override
  int processByte(int inp, Uint8List out, int outOff) {
    checkData();

    switch (_state) {
      case State.DEC_DATA:
        {
          _buf[_bufPos] = inp;
          if (++_bufPos == _buf.length) {
            poly1305.update(_buf, 0, BUF_SIZE);
            processData(_buf, 0, BUF_SIZE, out, outOff);
            utils.arrayCopy(_buf, BUF_SIZE, _buf, 0, MAC_SIZE);
            _bufPos = MAC_SIZE;
            return BUF_SIZE;
          }

          return 0;
        }
      case State.ENC_DATA:
        {
          _buf[_bufPos] = inp;
          if (++_bufPos == BUF_SIZE) {
            processData(_buf, 0, BUF_SIZE, out, outOff);
            poly1305.update(out, outOff, BUF_SIZE);
            _bufPos = 0;
            return BUF_SIZE;
          }

          return 0;
        }
      default:
        throw StateError('');
    }
  }

  @override
  int processBytes(
      Uint8List inp, int inOff, int len, Uint8List out, int outOff) {
    if (inOff < 0) {
      throw ArgumentError('\'inOff\' cannot be negative');
    }
    if (len < 0) {
      throw ArgumentError('\'len\' cannot be negative');
    }
    if (inOff > (inp.length - len)) {
      throw ArgumentError('Input buffer too short');
    }
    if (outOff < 0) {
      throw ArgumentError('\'outOff\' cannot be negative');
    }

    checkData();

    var resultLen = 0;

    switch (_state) {
      case State.DEC_DATA:
        {
          for (var i = 0; i < len; ++i) {
            _buf[_bufPos] = inp[inOff + i];
            if (++_bufPos == _buf.length) {
              poly1305.update(_buf, 0, BUF_SIZE);
              processData(_buf, 0, BUF_SIZE, out, outOff + resultLen);
              utils.arrayCopy(_buf, BUF_SIZE, _buf, 0, MAC_SIZE);
              _bufPos = MAC_SIZE;
              resultLen += BUF_SIZE;
            }
          }
          break;
        }
      case State.ENC_DATA:
        {
          if (_bufPos != 0) {
            while (len > 0) {
              --len;
              _buf[_bufPos] = inp[inOff++];
              if (++_bufPos == BUF_SIZE) {
                processData(_buf, 0, BUF_SIZE, out, outOff);
                poly1305.update(out, outOff, BUF_SIZE);
                _bufPos = 0;
                resultLen = BUF_SIZE;
                break;
              }
            }
          }

          while (len >= BUF_SIZE) {
            processData(inp, inOff, BUF_SIZE, out, outOff + resultLen);
            poly1305.update(out, outOff + resultLen, BUF_SIZE);
            inOff += BUF_SIZE;
            len -= BUF_SIZE;
            resultLen += BUF_SIZE;
          }

          if (len > 0) {
            utils.arrayCopy(inp, inOff, _buf, 0, len);
            _bufPos = len;
          }
          break;
        }
      default:
        throw StateError('');
    }

    return resultLen;
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    if (outOff < 0) {
      throw ArgumentError('\'outOff\' cannot be negative');
    }

    checkData();

    for (var i = 0; i < _mac.length; i++) {
      _mac[i] = 0x00;
    }

    var resultLen = 0;

    switch (_state) {
      case State.DEC_DATA:
        {
          if (_bufPos < MAC_SIZE) {
            throw ArgumentError('data too short');
          }

          resultLen = _bufPos - MAC_SIZE;

          if (outOff > (out.length - resultLen)) {
            throw ArgumentError('Output buffer too short');
          }

          if (resultLen > 0) {
            poly1305.update(_buf, 0, resultLen);
            processData(_buf, 0, resultLen, out, outOff);
          }

          finishData(State.DEC_FINAL);

          if (!utils.constantTimeAreEqualOffset(
              MAC_SIZE, _mac, 0, _buf, resultLen)) {
            throw ArgumentError('mac check in ChaCha20Poly1305 failed');
          }

          break;
        }
      case State.ENC_DATA:
        {
          resultLen = _bufPos + MAC_SIZE;

          // ignore: invariant_booleans
          if (outOff > (out.length - resultLen)) {
            throw ArgumentError('Output buffer too short');
          }

          if (_bufPos > 0) {
            processData(_buf, 0, _bufPos, out, outOff);
            poly1305.update(out, outOff, _bufPos);
          }

          finishData(State.ENC_FINAL);

          utils.arrayCopy(_mac, 0, out, outOff + _bufPos, MAC_SIZE);
          break;
        }
      default:
        throw StateError('');
    }

    resetBool(false, true);

    return resultLen;
  }

  @override
  void reset() {
    resetBool(true, true);
  }

  void resetBool(bool clearMac, bool resetCipher) {
    for (var i = 0; i < _buf.length; i++) {
      _buf[i] = 0;
    }

    if (clearMac) {
      for (var i = 0; i < _mac.length; i++) {
        _mac[i] = 0x00;
      }
    }

    _aadCount = 0;
    _dataCount = 0;
    _bufPos = 0;

    switch (_state) {
      case State.DEC_INIT:
      case State.ENC_INIT:
        break;
      case State.DEC_AAD:
      case State.DEC_DATA:
      case State.DEC_FINAL:
        _state = State.DEC_INIT;
        break;
      case State.ENC_AAD:
      case State.ENC_DATA:
      case State.ENC_FINAL:
        _state = State.ENC_FINAL;
        return;
      default:
        throw StateError('');
    }

    if (resetCipher) {
      chacha20.reset();
    }

    initMAC();

    if (_initialAAD != null) {
      processAADBytes(_initialAAD!, 0, _initialAAD!.length);
    }
  }

  void checkAAD() {
    switch (_state) {
      case State.DEC_INIT:
        _state = State.DEC_AAD;
        break;
      case State.ENC_INIT:
        _state = State.ENC_AAD;
        break;
      case State.DEC_AAD:
      case State.ENC_AAD:
        break;
      case State.ENC_FINAL:
        throw StateError('ChaCha20Poly1305 cannot be reused for encryption');
      default:
        throw StateError('');
    }
  }

  void checkData() {
    switch (_state) {
      case State.DEC_INIT:
      case State.DEC_AAD:
        finishAAD(State.DEC_DATA);
        break;
      case State.ENC_INIT:
      case State.ENC_AAD:
        finishAAD(State.ENC_DATA);
        break;
      case State.DEC_DATA:
      case State.ENC_DATA:
        break;
      case State.ENC_FINAL:
        throw StateError('ChaCha20Poly1305 cannot be reused for encryption');
      default:
        throw StateError('');
    }
  }

  void finishAAD(int nextState) {
    padMAC(_aadCount);

    _state = nextState;
  }

  void finishData(int nextState) {
    padMAC(_dataCount);

    var lengths = Uint8List(16);
    pack32(_aadCount, lengths, 0, Endian.little);
    pack32(_dataCount, lengths, 8, Endian.little);
    poly1305.update(lengths, 0, 16);

    poly1305.doFinal(_mac, 0);

    _state = nextState;
  }

  int incrementCount(int count, int increment, int limit) {
    if (count + MIN > (limit - increment) + MIN) {
      throw StateError('Limit exceeded');
    }

    return count + increment;
  }

  void initMAC() {
    var firstBlock = Uint8List(64);
    try {
      chacha20.processBytes(firstBlock, 0, 64, firstBlock, 0);
      poly1305.init(KeyParameter.offset(firstBlock, 0, 32));
    } finally {
      for (var i = 0; i < firstBlock.length; i++) {
        firstBlock[i] = 0;
      }
    }
  }

  void padMAC(int count) {
    var partial = (count & 4294967295) & (MAC_SIZE - 1);
    if (0 != partial) {
      poly1305.update(ZEROES, 0, MAC_SIZE - partial);
    }
  }

  void processData(
      Uint8List inp, int inOff, int inLen, Uint8List out, int outOff) {
    if (outOff > (out.length - inLen)) {
      throw ArgumentError('Output buffer too short');
    }

    chacha20.processBytes(inp, inOff, inLen, out, outOff);

    _dataCount = incrementCount(_dataCount, inLen, DATA_LIMIT);
  }
}

class State {
  static const UNINITIALIZED = 0;
  static const ENC_INIT = 1;
  static const ENC_AAD = 2;
  static const ENC_DATA = 3;
  static const ENC_FINAL = 4;
  static const DEC_INIT = 5;
  static const DEC_AAD = 6;
  static const DEC_DATA = 7;
  static const DEC_FINAL = 8;
}
