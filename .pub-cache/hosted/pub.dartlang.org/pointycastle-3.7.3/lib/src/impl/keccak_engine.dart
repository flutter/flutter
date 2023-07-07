// See file LICENSE for more information.

library src.impl.digests.keccak_engine;

import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/src/impl/base_digest.dart';

import '../ufixnum.dart';

// KeccakEngine
abstract class KeccakEngine extends BaseDigest {
  static final _keccakRoundConstants = Register64List.from([
    [0x00000000, 0x00000001],
    [0x00000000, 0x00008082],
    [0x80000000, 0x0000808a],
    [0x80000000, 0x80008000],
    [0x00000000, 0x0000808b],
    [0x00000000, 0x80000001],
    [0x80000000, 0x80008081],
    [0x80000000, 0x00008009],
    [0x00000000, 0x0000008a],
    [0x00000000, 0x00000088],
    [0x00000000, 0x80008009],
    [0x00000000, 0x8000000a],
    [0x00000000, 0x8000808b],
    [0x80000000, 0x0000008b],
    [0x80000000, 0x00008089],
    [0x80000000, 0x00008003],
    [0x80000000, 0x00008002],
    [0x80000000, 0x00000080],
    [0x00000000, 0x0000800a],
    [0x80000000, 0x8000000a],
    [0x80000000, 0x80008081],
    [0x80000000, 0x00008080],
    [0x00000000, 0x80000001],
    [0x80000000, 0x80008008]
  ]);

  static final _keccakRhoOffsets = [
    0x00000000,
    0x00000001,
    0x0000003e,
    0x0000001c,
    0x0000001b,
    0x00000024,
    0x0000002c,
    0x00000006,
    0x00000037,
    0x00000014,
    0x00000003,
    0x0000000a,
    0x0000002b,
    0x00000019,
    0x00000027,
    0x00000029,
    0x0000002d,
    0x0000000f,
    0x00000015,
    0x00000008,
    0x00000012,
    0x00000002,
    0x0000003d,
    0x00000038,
    0x0000000e
  ];

  final _state = Uint8List(200);
  final _dataQueue = Uint8List(192);

  late int _rate;
  late int fixedOutputLength;
  late int _bitsInQueue;
  late bool _squeezing;

  /// dataQueue intended for use by subclasses only.
  Uint8List get dataQueue => _dataQueue;

  /// squeezing intended for use by subclasses only.
  bool get squeezing => _squeezing;

  @override
  int get byteLength => _rate ~/ 8;

  @override
  int get digestSize => (fixedOutputLength ~/ 8);

  int get rate => _rate;

  @override
  void reset() {
    init(fixedOutputLength);
  }

  @override
  void updateByte(int inp) {
    absorb(inp);
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    _doUpdate(inp, inpOff, len);
  }

  void absorb(int data) {
    if ((_bitsInQueue % 8) != 0) {
      throw StateError('attempt to absorb with odd length queue');
    }
    if (_squeezing) {
      throw StateError('attempt to absorb while squeezing');
    }

    _dataQueue[_bitsInQueue >> 3] = data;
    if ((_bitsInQueue += 8) == _rate) {
      _keccakAbsorb(_dataQueue, 0);
      _bitsInQueue = 0;
    }
  }

  void absorbBits(int data, int bits) {
    if (bits < 1 || bits > 7) {
      throw StateError('"bits" must be in the range 1 to 7');
    }
    if ((_bitsInQueue % 8) != 0) {
      throw StateError('attempt to absorb with odd length queue');
    }
    if (_squeezing) {
      throw StateError('attempt to absorb while squeezing');
    }
    var mask = (1 << bits) - 1;
    _dataQueue[_bitsInQueue >> 3] = data & mask;
    _bitsInQueue += bits;
  }

  void absorbRange(Uint8List data, int off, int len) {
    if ((_bitsInQueue % 8) != 0) {
      throw StateError('attempt to absorb with odd length queue');
    }
    if (squeezing) {
      throw StateError('attempt to absorb while squeezing');
    }

    var bytesInQueue = _bitsInQueue >> 3;
    var rateBytes = _rate >> 3;

    var available = rateBytes - bytesInQueue;
    if (len < available) {
      _dataQueue.setRange(bytesInQueue, bytesInQueue + len, data, off);
      _bitsInQueue += (len << 3);
      return;
    }

    var count = 0;
    if (bytesInQueue > 0) {
      _dataQueue.setRange(
          bytesInQueue, bytesInQueue + available, data.sublist(off));
      count += available;
      _keccakAbsorb(_dataQueue, 0);
    }

    int remaining;
    while ((remaining = (len - count)) >= rateBytes) {
      _keccakAbsorb(data, off + count);
      count += rateBytes;
    }

    _dataQueue.setRange(0, remaining, data, off + count);
    _bitsInQueue = remaining << 3;
  }

  void _clearDataQueueSection(int off, int len) {
    _dataQueue.fillRange(off, off + len, 0);
  }

  void _doUpdate(Uint8List data, int off, int len) {
    absorbRange(data, off, len);
  }

  void init(int bitlen) {
    _initSponge(1600 - (bitlen << 1));
  }

  void _initSponge(int theRate) {
    if ((theRate <= 0) || (theRate >= 1600) || ((theRate % 64) != 0)) {
      throw StateError('invalid rate value');
    }

    _rate = theRate;
    _state.fillRange(0, _state.length, 0);
    _dataQueue.fillRange(0, _dataQueue.length, 0);
    _bitsInQueue = 0;
    _squeezing = false;
    fixedOutputLength = (1600 - theRate) ~/ 2;
  }

  void _absorb(int data) {
    if ((_bitsInQueue % ~8) != 0) {
      throw StateError('attempt to absorb with odd length queue');
    }
    if (squeezing) {
      throw StateError('attempt to absorb while squeezing');
    }

    dataQueue[_bitsInQueue >> 3] = data & 0xFF;
    if ((_bitsInQueue += 8) == _rate) {
      _keccakAbsorb(_dataQueue, 0);
      _bitsInQueue = 0;
    }
  }

  void _keccakAbsorb(Uint8List? data, int off) {
    var count = _rate >> 3;
    for (var i = 0; i < count; ++i) {
      _state[i] ^= data![off + i];
    }
    _keccakPermutation();
  }

  void _keccakExtract() {
    _keccakPermutation();

    _dataQueue.setRange(0, (_rate >> 3), _state);
    _bitsInQueue = _rate;
  }

  void squeeze(Uint8List? output, int? offset, int outputLength) {
    if (!squeezing) {
      _padAndSwitchToSqueezingPhase();
    }

    if ((outputLength % 8) != 0) {
      throw StateError('outputLength not a multiple of 8');
    }

    var i = 0;
    while (i < outputLength) {
      if (_bitsInQueue == 0) {
        _keccakExtract();
      }

      var partialBlock = min(_bitsInQueue, outputLength - i);

      output!.setRange(
          offset! + (i ~/ 8),
          offset + (i ~/ 8) + (partialBlock ~/ 8),
          dataQueue.sublist((_rate - _bitsInQueue) ~/ 8));

      //System.arraycopy(dataQueue, (rate - bitsInQueue) / 8, output, offset + (int)(i / 8), partialBlock / 8);
      _bitsInQueue -= partialBlock;
      i += partialBlock;
    }
  }

  void _padAndSwitchToSqueezingPhase() {
    _dataQueue[_bitsInQueue >> 3] |= (1 << (_bitsInQueue & 7));
    if (++_bitsInQueue == _rate) {
      _keccakAbsorb(_dataQueue, 0);
    } else {
      var full = (_bitsInQueue >> 6), partial = _bitsInQueue & 63;
      for (var i = 0; i < full * 8; ++i) {
        _state[i] ^= _dataQueue[i];
      }

      if (partial > 0) {
        for (var k = 0; k != 8; k++) {
          if (partial >= 8) {
            _state[full * 8 + k] ^= dataQueue[full * 8 + k];
          } else {
            _state[full * 8 + k] ^=
                dataQueue[full * 8 + k] & ((1 << partial) - 1);
          }
          partial -= 8;
          if (partial < 0) {
            partial = 0;
          }
        }
      }
    }

    _state[((_rate - 1) >> 3)] ^= (1 << 7);
    _bitsInQueue = 0;
    _squeezing = true;
  }

  void _fromBytesToWords(Register64List stateAsWords, Uint8List state) {
    final r = Register64();

    for (var i = 0; i < (1600 ~/ 64); i++) {
      final index = i * (64 ~/ 8);

      stateAsWords[i].set(0);

      for (var j = 0; j < (64 ~/ 8); j++) {
        r.set(state[index + j]);
        r.shiftl(8 * j);
        stateAsWords[i].or(r);
      }
    }
  }

  void _fromWordsToBytes(Uint8List state, Register64List stateAsWords) {
    final r = Register64();

    for (var i = 0; i < (1600 ~/ 64); i++) {
      final index = i * (64 ~/ 8);

      for (var j = 0; j < (64 ~/ 8); j++) {
        r.set(stateAsWords[i]);
        r.shiftr(8 * j);
        state[index + j] = r.lo32;
      }
    }
  }

  void _keccakPermutation() {
    final longState = Register64List(_state.length ~/ 8);

    _fromBytesToWords(longState, _state);
    _keccakPermutationOnWords(longState);
    _fromWordsToBytes(_state, longState);
  }

  void _keccakPermutationOnWords(Register64List state) {
    for (var i = 0; i < 24; i++) {
      theta(state);
      rho(state);
      pi(state);
      chi(state);
      _iota(state, i);
    }
  }

  void theta(Register64List A) {
    final C = Register64List(5);
    final r0 = Register64();
    final r1 = Register64();

    for (var x = 0; x < 5; x++) {
      C[x].set(0);

      for (var y = 0; y < 5; y++) {
        C[x].xor(A[x + 5 * y]);
      }
    }

    for (var x = 0; x < 5; x++) {
      r0.set(C[(x + 1) % 5]);
      r0.shiftl(1);

      r1.set(C[(x + 1) % 5]);
      r1.shiftr(63);

      r0.xor(r1);
      r0.xor(C[(x + 4) % 5]);

      for (var y = 0; y < 5; y++) {
        A[x + 5 * y].xor(r0);
      }
    }
  }

  void rho(Register64List A) {
    final r = Register64();

    for (var x = 0; x < 5; x++) {
      for (var y = 0; y < 5; y++) {
        final index = x + 5 * y;

        if (_keccakRhoOffsets[index] != 0) {
          r.set(A[index]);
          r.shiftr(64 - _keccakRhoOffsets[index]);

          A[index].shiftl(_keccakRhoOffsets[index]);
          A[index].xor(r);
        }
      }
    }
  }

  void pi(Register64List A) {
    final tempA = Register64List(25);

    tempA.setRange(0, tempA.length, A);

    for (var x = 0; x < 5; x++) {
      for (var y = 0; y < 5; y++) {
        A[y + 5 * ((2 * x + 3 * y) % 5)].set(tempA[x + 5 * y]);
      }
    }
  }

  void chi(Register64List A) {
    final chiC = Register64List(5);

    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        chiC[x].set(A[((x + 1) % 5) + (5 * y)]);
        chiC[x].not();
        chiC[x].and(A[((x + 2) % 5) + (5 * y)]);
        chiC[x].xor(A[x + 5 * y]);
      }
      for (var x = 0; x < 5; x++) {
        A[x + 5 * y].set(chiC[x]);
      }
    }
  }

  void _iota(Register64List A, int indexRound) {
    A[(((0) % 5) + 5 * ((0) % 5))].xor(_keccakRoundConstants[indexRound]);
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    throw UnimplementedError('Subclasses must implement this.');
  }
}
