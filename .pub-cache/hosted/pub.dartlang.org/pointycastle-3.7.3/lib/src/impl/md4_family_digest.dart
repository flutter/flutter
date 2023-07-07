// See file LICENSE for more information.

library src.impl.digests.md4_family_digest;

import 'dart:typed_data';

import 'package:pointycastle/src/ufixnum.dart';
import 'package:pointycastle/src/impl/base_digest.dart';

/// Base implementation of MD4 family style digest
abstract class MD4FamilyDigest extends BaseDigest {
  final _byteCount = Register64(0);

  final _wordBuffer = Uint8List(4);
  late int _wordBufferOffset;

  final Endian _endian;
  final int _packedStateSize;

  final List<int> state;

  final List<int> buffer;
  late int bufferOffset;

  MD4FamilyDigest(this._endian, int stateSize, int bufferSize,
      [int? packedStateSize])
      : _packedStateSize =
            (packedStateSize == null) ? stateSize : packedStateSize,
        state = List<int>.filled(stateSize, 0, growable: false),
        buffer = List<int>.filled(bufferSize, 0, growable: false) {
    reset();
  }

  /// Reset state of digest.
  void resetState();

  /// Process a whole block of data in extender digest.
  void processBlock();

  @override
  void reset() {
    _byteCount.set(0);

    _wordBufferOffset = 0;
    _wordBuffer.fillRange(0, _wordBuffer.length, 0);

    bufferOffset = 0;
    buffer.fillRange(0, buffer.length, 0);

    resetState();
  }

  @override
  void updateByte(int inp) {
    _wordBuffer[_wordBufferOffset++] = clip8(inp);
    _processWordIfBufferFull();
    _byteCount.sum(1);
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    int nbytes;

    nbytes = _processUntilNextWord(inp, inpOff, len);
    inpOff += nbytes;
    len -= nbytes;

    nbytes = _processWholeWords(inp, inpOff, len);
    inpOff += nbytes;
    len -= nbytes;

    _processBytes(inp, inpOff, len);
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    var bitLength = Register64(_byteCount)..shiftl(3);

    _processPadding();
    _processLength(bitLength);
    _doProcessBlock();

    _packState(out, outOff);

    reset();

    return digestSize;
  }

  /// Process a word (4 bytes) of data stored in [inp], starting at [inpOff].
  void _processWord(Uint8List inp, int inpOff) {
    buffer[bufferOffset++] = unpack32(inp, inpOff, _endian);

    if (bufferOffset == 16) {
      _doProcessBlock();
    }
  }

  /// Process a block of data and reset the [buffer].
  void _doProcessBlock() {
    processBlock();

    // reset the offset and clean out the word buffer.
    bufferOffset = 0;
    buffer.fillRange(0, 16, 0);
  }

  /// Process [len] bytes from [inp] starting at [inpOff]
  void _processBytes(Uint8List inp, int inpOff, int len) {
    while (len > 0) {
      updateByte(inp[inpOff]);

      inpOff++;
      len--;
    }
  }

  /// Process data word by word until no more words can be extracted from [inp] and return the number of bytes processed.
  int _processWholeWords(Uint8List inp, int inpOff, int len) {
    var processed = 0;
    while (len > _wordBuffer.length) {
      _processWord(inp, inpOff);

      inpOff += _wordBuffer.length;
      len -= _wordBuffer.length;
      _byteCount.sum(_wordBuffer.length);
      processed += 4;
    }
    return processed;
  }

  /// Process bytes from [inp] until the word buffer [_wordBuffer] is full and reset and return the number of bytes processed.
  int _processUntilNextWord(Uint8List inp, int inpOff, int len) {
    var processed = 0;

    while ((_wordBufferOffset != 0) && (len > 0)) {
      updateByte(inp[inpOff]);

      inpOff++;
      len--;
      processed++;
    }

    return processed;
  }

  // ignore: comment_references
  /// Process a word in [_xBuff] if it is already full and then reset it
  void _processWordIfBufferFull() {
    if (_wordBufferOffset == _wordBuffer.length) {
      _processWord(_wordBuffer, 0);
      _wordBufferOffset = 0;
    }
  }

  /// Add final padding to the digest
  void _processPadding() {
    updateByte(128);
    while (_wordBufferOffset != 0) {
      updateByte(0);
    }
  }

  // ignore: comment_references
  /// Called from [finish] so that extender can process the number of bits processed.
  void _processLength(Register64 bitLength) {
    if (bufferOffset > 14) {
      _doProcessBlock();
    }

    switch (_endian) {
      case Endian.little:
        buffer[14] = bitLength.lo32;
        buffer[15] = bitLength.hi32;
        break;

      case Endian.big:
        buffer[14] = bitLength.hi32;
        buffer[15] = bitLength.lo32;
        break;

      default:
        throw StateError('Invalid endianness: $_endian');
    }
  }

  void _packState(Uint8List out, int outOff) {
    for (var i = 0; i < _packedStateSize; i++) {
      pack32(state[i], out, (outOff + i * 4), _endian);
    }
  }
}
