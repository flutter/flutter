// This file has been migrated.

library impl.digest.blake2b;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

class Blake2bDigest extends BaseDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'Blake2b', () => Blake2bDigest());

  static const _rounds = 12;
  static const _blockSize = 128;

  int _digestLength = 64;
  int _keyLength = 0;
  Uint8List? _salt;
  Uint8List? _personalization;

  Uint8List? _key;

  Uint8List? _buffer;
  // Position of last inserted byte:
  int _bufferPos = 0; // a value from 0 up to 128
  final _internalState =
      Register64List(16); // In the Blake2b paper it is called: v
  Register64List?
      _chainValue; // state vector, in the Blake2b paper it is called: h

  final _t0 =
      Register64(); // holds last significant bits, counter (counts bytes)
  final _t1 = Register64(); // counter: Length up to 2^128 are supported
  final _f0 = Register64(); // finalization flag, for last block: ~0L

  Blake2bDigest(
      {int digestSize = 64,
      Uint8List? key,
      Uint8List? salt,
      Uint8List? personalization}) {
    _buffer = Uint8List(_blockSize);

    if (digestSize < 1 || digestSize > 64) {
      throw ArgumentError('Invalid digest length (required: 1 - 64)');
    }
    _digestLength = digestSize;
    if (salt != null) {
      if (salt.length != 16) {
        throw ArgumentError('salt length must be exactly 16 bytes');
      }
      _salt = Uint8List.fromList(salt);
    }
    if (personalization != null) {
      if (personalization.length != 16) {
        throw ArgumentError('personalization length must be exactly 16 bytes');
      }
      _personalization = Uint8List.fromList(personalization);
    }
    if (key != null) {
      if (key.length > 64) throw ArgumentError('Keys > 64 are not supported');
      _key = Uint8List.fromList(key);

      _keyLength = key.length;
      _buffer!.setAll(0, key);
      _bufferPos = _blockSize;
    }
    init();
  }

  @override
  String get algorithmName => 'Blake2b';
  @override
  int get digestSize => _digestLength;

  void init() {
    if (_chainValue == null) {
      _chainValue = Register64List(8);
      _chainValue![0]
        ..set(_blake2bIV[0])
        ..xor(Register64(digestSize | (_keyLength << 8) | 0x1010000));
      _chainValue![1].set(_blake2bIV[1]);
      _chainValue![2].set(_blake2bIV[2]);

      _chainValue![3].set(_blake2bIV[3]);

      _chainValue![4].set(_blake2bIV[4]);
      _chainValue![5].set(_blake2bIV[5]);
      if (_salt != null) {
        _chainValue![4].xor(Register64()..unpack(_salt, 0, Endian.little));
        _chainValue![5].xor(Register64()..unpack(_salt, 8, Endian.little));
      }

      _chainValue![6].set(_blake2bIV[6]);
      _chainValue![7].set(_blake2bIV[7]);
      if (_personalization != null) {
        _chainValue![6]
            .xor(Register64()..unpack(_personalization, 0, Endian.little));
        _chainValue![7]
            .xor(Register64()..unpack(_personalization, 8, Endian.little));
      }
    }
  }

  void _initializeInternalState() {
    _internalState.setRange(0, _chainValue!.length, _chainValue!);
    _internalState.setRange(
        _chainValue!.length, _chainValue!.length + 4, _blake2bIV);
    _internalState[12]
      ..set(_t0)
      ..xor(_blake2bIV[4]);
    _internalState[13]
      ..set(_t1)
      ..xor(_blake2bIV[5]);
    _internalState[14]
      ..set(_f0)
      ..xor(_blake2bIV[6]);
    _internalState[15].set(_blake2bIV[7]); // ^ f1 with f1 = 0
  }

  @override
  void updateByte(int inp) {
    if (_bufferPos == _blockSize) {
      // full buffer
      _t0.sum(_blockSize);
      // This requires hashing > 2^64 bytes which is impossible for the forseeable future.
      // So _t1 is untested dead code, but I've left it in because it is in the source library.
      if (_t0.lo32 == 0 && _t0.hi32 == 0) _t1.sum(1);
      _compress(_buffer, 0);
      _buffer!.fillRange(0, _buffer!.length, 0); // clear buffer
      _buffer![0] = inp;
      _bufferPos = 1;
    } else {
      _buffer![_bufferPos] = inp;
      ++_bufferPos;
    }
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    if (len == 0) return;
    var remainingLength = 0;
    if (_bufferPos != 0) {
      remainingLength = _blockSize - _bufferPos;
      if (remainingLength < len) {
        _buffer!
            .setRange(_bufferPos, _bufferPos + remainingLength, inp, inpOff);
        _t0.sum(_blockSize);
        if (_t0.lo32 == 0 && _t0.hi32 == 0) _t1.sum(1);
        _compress(_buffer, 0);
        _bufferPos = 0;
        _buffer!.fillRange(0, _buffer!.length, 0); // clear buffer
      } else {
        _buffer!.setRange(_bufferPos, _bufferPos + len, inp, inpOff);
        _bufferPos += len;
        return;
      }
    }

    int msgPos;
    var blockWiseLastPos = inpOff + len - _blockSize;
    for (msgPos = inpOff + remainingLength;
        msgPos < blockWiseLastPos;
        msgPos += _blockSize) {
      _t0.sum(_blockSize);
      if (_t0.lo32 == 0 && _t0.hi32 == 0) _t1.sum(1);
      _compress(inp, msgPos);
    }

    _buffer!.setRange(0, inpOff + len - msgPos, inp, msgPos);
    _bufferPos += inpOff + len - msgPos;
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    _f0.set(0xFFFFFFFF, 0xFFFFFFFF);
    _t0.sum(_bufferPos);
    if (_bufferPos > 0 && _t0.lo32 == 0 && _t0.hi32 == 0) _t1.sum(1);
    _compress(_buffer, 0);
    _buffer!.fillRange(0, _buffer!.length, 0); // clear buffer
    _internalState.fillRange(0, _internalState.length, 0);

    final packedValue = Uint8List(8);
    final packedValueData = packedValue.buffer.asByteData();
    for (var i = 0; i < _chainValue!.length && (i * 8 < _digestLength); ++i) {
      _chainValue![i].pack(packedValueData, 0, Endian.little);

      final start = outOff + i * 8;
      if (i * 8 < _digestLength - 8) {
        out.setRange(start, start + 8, packedValue);
      } else {
        out.setRange(start, start + _digestLength - (i * 8), packedValue);
      }
    }

    _chainValue!.fillRange(0, _chainValue!.length, 0);

    reset();

    return _digestLength;
  }

  @override
  void reset() {
    _bufferPos = 0;
    _f0.set(0);
    _t0.set(0);
    _t1.set(0);
    _chainValue = null;
    _buffer!.fillRange(0, _buffer!.length, 0);
    if (_key != null) {
      _buffer!.setAll(0, _key!);
      _bufferPos = _blockSize;
    }
    init();
  }

  // This variable is faster as a class member.
  final _m = Register64List(16);
  void _compress(Uint8List? message, int messagePos) {
    _initializeInternalState();

    for (var j = 0; j < 16; ++j) {
      _m[j].unpack(message, messagePos + j * 8, Endian.little);
    }

    for (var round = 0; round < _rounds; ++round) {
      G(_m[_blake2bSigma[round][0]], _m[_blake2bSigma[round][1]], 0, 4, 8, 12);
      G(_m[_blake2bSigma[round][2]], _m[_blake2bSigma[round][3]], 1, 5, 9, 13);
      G(_m[_blake2bSigma[round][4]], _m[_blake2bSigma[round][5]], 2, 6, 10, 14);
      G(_m[_blake2bSigma[round][6]], _m[_blake2bSigma[round][7]], 3, 7, 11, 15);
      G(_m[_blake2bSigma[round][8]], _m[_blake2bSigma[round][9]], 0, 5, 10, 15);
      G(_m[_blake2bSigma[round][10]], _m[_blake2bSigma[round][11]], 1, 6, 11,
          12);
      G(_m[_blake2bSigma[round][12]], _m[_blake2bSigma[round][13]], 2, 7, 8,
          13);
      G(_m[_blake2bSigma[round][14]], _m[_blake2bSigma[round][15]], 3, 4, 9,
          14);
    }

    for (var offset = 0; offset < _chainValue!.length; ++offset) {
      _chainValue![offset]
        ..xor(_internalState[offset])
        ..xor(_internalState[offset + 8]);
    }
  }

  void G(Register64 m1, Register64 m2, int posA, int posB, int posC, int posD) {
    // This variable is faster as a local. The allocation is probably sunk.
    final r = Register64();

    _internalState[posA].sumReg(r
      ..set(_internalState[posB])
      ..sumReg(m1));
    _internalState[posD]
      ..xor(_internalState[posA])
      ..rotr(32);
    _internalState[posC].sumReg(_internalState[posD]);
    _internalState[posB]
      ..xor(_internalState[posC])
      ..rotr(24);
    _internalState[posA].sumReg(r
      ..set(_internalState[posB])
      ..sumReg(m2));
    _internalState[posD]
      ..xor(_internalState[posA])
      ..rotr(16);
    _internalState[posC].sumReg(_internalState[posD]);
    _internalState[posB]
      ..xor(_internalState[posC])
      ..rotr(63);
  }

  @override
  int get byteLength => 128;
}

// Produced from the square root of primes 2, 3, 5, 7, 11, 13, 17, 19.
// The same as SHA-512 IV.
final _blake2bIV = Register64List.from([
  [0x6a09e667, 0xf3bcc908],
  [0xbb67ae85, 0x84caa73b],
  [0x3c6ef372, 0xfe94f82b],
  [0xa54ff53a, 0x5f1d36f1],
  [0x510e527f, 0xade682d1],
  [0x9b05688c, 0x2b3e6c1f],
  [0x1f83d9ab, 0xfb41bd6b],
  [0x5be0cd19, 0x137e2179],
]);

final _blake2bSigma = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
  [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
  [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
  [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
  [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
  [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
  [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
  [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
  [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
];
