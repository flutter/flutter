library impl.stream_cipher.chacha20;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../api.dart';
import '../src/impl/base_stream_cipher.dart';
import '../src/registry/registry.dart';
import '../src/ufixnum.dart';

// ignore_for_file: omit_local_variable_types, prefer_single_quotes
// ignore_for_file: non_constant_identifier_names, directives_ordering
// ignore_for_file: prefer_typing_uninitialized_variables, camel_case_types
// ignore_for_file: annotate_overrides

/// Implementation of Daniel J. Bernstein's ChaCha20 stream cipher, Snuffle 2005.
class ChaCha20Engine extends BaseStreamCipher {
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.prefix(
      StreamCipher,
      'ChaCha20/',
      (_, final Match match) => () {
            var rounds = int.parse(match.group(1)!);
            return ChaCha20Engine.fromRounds(rounds);
          });

  static const STATE_SIZE = 16;

  int rounds = 20;

  static final _sigma = Uint8List.fromList([
    101,
    120,
    112,
    97,
    110,
    100,
    32,
    51,
    50,
    45,
    98,
    121,
    116,
    101,
    32,
    107
  ]);
  static final _tau = Uint8List.fromList([
    101,
    120,
    112,
    97,
    110,
    100,
    32,
    49,
    54,
    45,
    98,
    121,
    116,
    101,
    32,
    107
  ]);

  Uint8List? _workingKey;
  late Uint8List _workingIV;

  final _state = List<int>.filled(STATE_SIZE, 0, growable: false);
  final _buffer = List<int>.filled(STATE_SIZE, 0, growable: false);

  final _keyStream = Uint8List(STATE_SIZE * 4);
  var _keyStreamOffset = 0;

  var _initialised = false;

  @override
  String get algorithmName => 'ChaCha20/$rounds';

  ChaCha20Engine() {
    rounds = 20;
  }

  ChaCha20Engine.fromRounds(this.rounds);

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
      throw ArgumentError('ChaCha20 requires exactly 8 bytes of IV');
    }

    _workingIV = iv;
    _workingKey = uparams!.key;

    _setKey(_workingKey!, _workingIV);
  }

  @override
  int returnByte(int inp) {
    if (_keyStreamOffset == 0) {
      generateKeyStream(_keyStream);

      if (++_state[12] == 0) {
        ++_state[13];
      }
    }

    var out = clip8(_keyStream[_keyStreamOffset] ^ inp);
    _keyStreamOffset = (_keyStreamOffset + 1) & 63;

    return out;
  }

  @override
  void processBytes(
      Uint8List inp, int inpOff, int len, Uint8List out, int outOff) {
    if (!_initialised) {
      throw StateError('ChaCha20 not initialized: please call init() first');
    }

    if ((inpOff + len) > inp.length) {
      throw ArgumentError(
          'Input buffer too short or requested length too long');
    }

    if ((outOff + len) > out.length) {
      throw ArgumentError(
          'Output buffer too short or requested length too long');
    }

    for (var i = 0; i < len; i++) {
      if (_keyStreamOffset == 0) {
        generateKeyStream(_keyStream);

        if (++_state[12] == 0) {
          ++_state[13];
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
    _state[4] = unpack32(_workingKey, 0, Endian.little);
    _state[5] = unpack32(_workingKey, 4, Endian.little);
    _state[6] = unpack32(_workingKey, 8, Endian.little);
    _state[7] = unpack32(_workingKey, 12, Endian.little);

    if (_workingKey!.length == 32) {
      constants = _sigma;
      offset = 16;
    } else {
      constants = _tau;
    }

    _state[8] = unpack32(_workingKey, offset, Endian.little);
    _state[9] = unpack32(_workingKey, offset + 4, Endian.little);
    _state[10] = unpack32(_workingKey, offset + 8, Endian.little);
    _state[11] = unpack32(_workingKey, offset + 12, Endian.little);
    _state[0] = unpack32(constants, 0, Endian.little);
    _state[1] = unpack32(constants, 4, Endian.little);
    _state[2] = unpack32(constants, 8, Endian.little);
    _state[3] = unpack32(constants, 12, Endian.little);

    // IV
    _state[14] = unpack32(_workingIV, 0, Endian.little);
    _state[15] = unpack32(_workingIV, 4, Endian.little);
    _state[12] = _state[13] = 0;

    _initialised = true;
  }

  void generateKeyStream(Uint8List output) {
    _core(rounds, _state, _buffer);
    var outOff = 0;
    for (var x in _buffer) {
      pack32(x, output, outOff, Endian.little);
      outOff += 4;
    }
  }

  /// The ChaCha20 core function
  void _core(int rounds, List<int> input, List<int> x) {
    var x00 = input[0];
    var x01 = input[1];
    var x02 = input[2];
    var x03 = input[3];
    var x04 = input[4];
    var x05 = input[5];
    var x06 = input[6];
    var x07 = input[7];
    var x08 = input[8];
    var x09 = input[9];
    var x10 = input[10];
    var x11 = input[11];
    var x12 = input[12];
    var x13 = input[13];
    var x14 = input[14];
    var x15 = input[15];

    for (var i = rounds; i > 0; i -= 2) {
      x00 += x04;
      x12 = crotl32(x12 ^ x00, 16);
      x08 += x12;
      x04 = crotl32(x04 ^ x08, 12);
      x00 += x04;
      x12 = crotl32(x12 ^ x00, 8);
      x08 += x12;
      x04 = crotl32(x04 ^ x08, 7);
      x01 += x05;
      x13 = crotl32(x13 ^ x01, 16);
      x09 += x13;
      x05 = crotl32(x05 ^ x09, 12);
      x01 += x05;
      x13 = crotl32(x13 ^ x01, 8);
      x09 += x13;
      x05 = crotl32(x05 ^ x09, 7);
      x02 += x06;
      x14 = crotl32(x14 ^ x02, 16);
      x10 += x14;
      x06 = crotl32(x06 ^ x10, 12);
      x02 += x06;
      x14 = crotl32(x14 ^ x02, 8);
      x10 += x14;
      x06 = crotl32(x06 ^ x10, 7);
      x03 += x07;
      x15 = crotl32(x15 ^ x03, 16);
      x11 += x15;
      x07 = crotl32(x07 ^ x11, 12);
      x03 += x07;
      x15 = crotl32(x15 ^ x03, 8);
      x11 += x15;
      x07 = crotl32(x07 ^ x11, 7);
      x00 += x05;
      x15 = crotl32(x15 ^ x00, 16);
      x10 += x15;
      x05 = crotl32(x05 ^ x10, 12);
      x00 += x05;
      x15 = crotl32(x15 ^ x00, 8);
      x10 += x15;
      x05 = crotl32(x05 ^ x10, 7);
      x01 += x06;
      x12 = crotl32(x12 ^ x01, 16);
      x11 += x12;
      x06 = crotl32(x06 ^ x11, 12);
      x01 += x06;
      x12 = crotl32(x12 ^ x01, 8);
      x11 += x12;
      x06 = crotl32(x06 ^ x11, 7);
      x02 += x07;
      x13 = crotl32(x13 ^ x02, 16);
      x08 += x13;
      x07 = crotl32(x07 ^ x08, 12);
      x02 += x07;
      x13 = crotl32(x13 ^ x02, 8);
      x08 += x13;
      x07 = crotl32(x07 ^ x08, 7);
      x03 += x04;
      x14 = crotl32(x14 ^ x03, 16);
      x09 += x14;
      x04 = crotl32(x04 ^ x09, 12);
      x03 += x04;
      x14 = crotl32(x14 ^ x03, 8);
      x09 += x14;
      x04 = crotl32(x04 ^ x09, 7);
    }
    var xup = [
      x00,
      x01,
      x02,
      x03,
      x04,
      x05,
      x06,
      x07,
      x08,
      x09,
      x10,
      x11,
      x12,
      x13,
      x14,
      x15
    ];
    for (var i = 0; i < STATE_SIZE; ++i) {
      x[i] = csum32(xup[i], input[i]);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation);
}
