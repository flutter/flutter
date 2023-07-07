// See file LICENSE for more information.

library impl.stream_cipher.salsa20;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_stream_cipher.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of Daniel J. Bernstein's Salsa20 stream cipher, Snuffle 2005.
class Salsa20Engine extends BaseStreamCipher {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(StreamCipher, 'Salsa20', () => Salsa20Engine());

  static const _STATE_SIZE = 16;

  static final _sigma = Uint8List.fromList('expand 32-byte k'.codeUnits);
  static final _tau = Uint8List.fromList('expand 16-byte k'.codeUnits);

  Uint8List? _workingKey;
  late Uint8List _workingIV;

  final _state = List<int>.filled(_STATE_SIZE, 0, growable: false);
  final _buffer = List<int>.filled(_STATE_SIZE, 0, growable: false);

  final _keyStream = Uint8List(_STATE_SIZE * 4);
  var _keyStreamOffset = 0;

  var _initialised = false;

  @override
  final String algorithmName = 'Salsa20';

  @override
  void reset() {
    if (_workingKey != null) {
      _setKey(_workingKey!, _workingIV);
    }
  }

  @override
  void init(
      bool forEncryption, covariant ParametersWithIV<KeyParameter> params) {
    var uparams = params.parameters;
    var iv = params.iv;
    if (iv.length != 8) {
      throw ArgumentError('Salsa20 requires exactly 8 bytes of IV');
    }

    _workingIV = iv;
    _workingKey = uparams!.key;

    _setKey(_workingKey!, _workingIV);
  }

  @override
  int returnByte(int inp) {
    if (_keyStreamOffset == 0) {
      _generateKeyStream(_keyStream);

      if (++_state[8] == 0) {
        ++_state[9];
      }
    }

    var out = clip8(_keyStream[_keyStreamOffset] ^ inp);
    _keyStreamOffset = (_keyStreamOffset + 1) & 63;

    return out;
  }

  @override
  void processBytes(
      Uint8List? inp, int inpOff, int len, Uint8List? out, int outOff) {
    if (!_initialised) {
      throw StateError('Salsa20 not initialized: please call init() first');
    }

    if ((inpOff + len) > inp!.length) {
      throw ArgumentError(
          'Input buffer too short or requested length too long');
    }

    if ((outOff + len) > out!.length) {
      throw ArgumentError(
          'Output buffer too short or requested length too long');
    }

    for (var i = 0; i < len; i++) {
      if (_keyStreamOffset == 0) {
        _generateKeyStream(_keyStream);

        if (++_state[8] == 0) {
          ++_state[9];
        }
      }

      out[i + outOff] = clip8(_keyStream[_keyStreamOffset] ^ inp[i + inpOff]);
      _keyStreamOffset = (_keyStreamOffset + 1) & 63;
    }
  }

  void _setKey(Uint8List keyBytes, Uint8List ivBytes) {
    _workingKey = keyBytes;
    _workingIV = ivBytes;

    _keyStreamOffset = 0;
    var offset = 0;
    Uint8List constants;

    // Key
    _state[1] = unpack32(_workingKey, 0, Endian.little);
    _state[2] = unpack32(_workingKey, 4, Endian.little);
    _state[3] = unpack32(_workingKey, 8, Endian.little);
    _state[4] = unpack32(_workingKey, 12, Endian.little);

    if (_workingKey!.length == 32) {
      constants = _sigma;
      offset = 16;
    } else {
      constants = _tau;
    }

    _state[11] = unpack32(_workingKey, offset, Endian.little);
    _state[12] = unpack32(_workingKey, offset + 4, Endian.little);
    _state[13] = unpack32(_workingKey, offset + 8, Endian.little);
    _state[14] = unpack32(_workingKey, offset + 12, Endian.little);
    _state[0] = unpack32(constants, 0, Endian.little);
    _state[5] = unpack32(constants, 4, Endian.little);
    _state[10] = unpack32(constants, 8, Endian.little);
    _state[15] = unpack32(constants, 12, Endian.little);

    // IV
    _state[6] = unpack32(_workingIV, 0, Endian.little);
    _state[7] = unpack32(_workingIV, 4, Endian.little);
    _state[8] = _state[9] = 0;

    _initialised = true;
  }

  void _generateKeyStream(Uint8List output) {
    _salsa20Core(20, _state, _buffer);
    var outOff = 0;
    for (var x in _buffer) {
      pack32(x, output, outOff, Endian.little);
      outOff += 4;
    }
  }

  /// The Salsa20 core function
  void _salsa20Core(int rounds, List<int> input, List<int> x) {
    x.setAll(0, input);

    for (var i = rounds; i > 0; i -= 2) {
      x[4] ^= crotl32((x[0] + x[12]), 7);
      x[8] ^= crotl32((x[4] + x[0]), 9);
      x[12] ^= crotl32((x[8] + x[4]), 13);
      x[0] ^= crotl32((x[12] + x[8]), 18);
      x[9] ^= crotl32((x[5] + x[1]), 7);
      x[13] ^= crotl32((x[9] + x[5]), 9);
      x[1] ^= crotl32((x[13] + x[9]), 13);
      x[5] ^= crotl32((x[1] + x[13]), 18);
      x[14] ^= crotl32((x[10] + x[6]), 7);
      x[2] ^= crotl32((x[14] + x[10]), 9);
      x[6] ^= crotl32((x[2] + x[14]), 13);
      x[10] ^= crotl32((x[6] + x[2]), 18);
      x[3] ^= crotl32((x[15] + x[11]), 7);
      x[7] ^= crotl32((x[3] + x[15]), 9);
      x[11] ^= crotl32((x[7] + x[3]), 13);
      x[15] ^= crotl32((x[11] + x[7]), 18);
      x[1] ^= crotl32((x[0] + x[3]), 7);
      x[2] ^= crotl32((x[1] + x[0]), 9);
      x[3] ^= crotl32((x[2] + x[1]), 13);
      x[0] ^= crotl32((x[3] + x[2]), 18);
      x[6] ^= crotl32((x[5] + x[4]), 7);
      x[7] ^= crotl32((x[6] + x[5]), 9);
      x[4] ^= crotl32((x[7] + x[6]), 13);
      x[5] ^= crotl32((x[4] + x[7]), 18);
      x[11] ^= crotl32((x[10] + x[9]), 7);
      x[8] ^= crotl32((x[11] + x[10]), 9);
      x[9] ^= crotl32((x[8] + x[11]), 13);
      x[10] ^= crotl32((x[9] + x[8]), 18);
      x[12] ^= crotl32((x[15] + x[14]), 7);
      x[13] ^= crotl32((x[12] + x[15]), 9);
      x[14] ^= crotl32((x[13] + x[12]), 13);
      x[15] ^= crotl32((x[14] + x[13]), 18);
    }

    for (var i = 0; i < _STATE_SIZE; ++i) {
      x[i] = sum32(x[i], input[i]);
    }
  }
}
