library impl.block_cipher.modes.gcm;

import 'dart:math' show min;
import 'dart:typed_data';

import 'package:pointycastle/src/ct.dart';

import '../../api.dart';
import '../../src/impl/base_aead_block_cipher.dart';
import '../../src/registry/registry.dart';

class GCMBlockCipher extends BaseAEADBlockCipher {
  /// Intended for internal use.
  // ignore: non_constant_identifier_names
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
      BlockCipher,
      '/GCM',
      (_, final Match match) => () {
            var underlying = BlockCipher(match.group(1)!);
            return GCMBlockCipher(underlying);
          });

  late Uint8List _h;
  late Uint8List _counter;
  late Uint8List _e;
  late Uint8List _e0;
  late Uint8List _x;
  late int _processedBytes;
  int _blocksRemaining = 0;

  GCMBlockCipher(BlockCipher cipher) : super(cipher);

  @override
  String get algorithmName => '${underlyingCipher.algorithmName}/GCM';

  @override
  void init(bool forEncryption, CipherParameters? params) {
    var bs = underlyingCipher.blockSize;
    _blocksRemaining = (2 ^ 36 - 64) ~/ bs;
    super.init(forEncryption, params);
  }

  @override
  void reset() {
    var bs = underlyingCipher.blockSize;
    _blocksRemaining = (2 ^ 36 - 64) ~/ bs;
    super.reset();
  }

  @override
  void prepare(KeyParameter keyParam) {
    if (macSize != 16) {
      throw ArgumentError('macSize should be equal to 16 for GCM');
    }

    underlyingCipher.init(true, keyParam);

    _h = Uint8List(blockSize);
    underlyingCipher.processBlock(_h, 0, _h, 0);

    _counter = _computeInitialCounter(nonce);

    _e0 = Uint8List(16);
    _computeE(_counter, _e0);

    _e = Uint8List(16);

    _x = Uint8List(16);

    _processedBytes = 0;
  }

  Uint8List _computeInitialCounter(Uint8List iv) {
    var counter = Uint8List(16);

    if (iv.length == 12) {
      counter.setAll(0, iv);
      counter[15] = 1;
    } else {
      _gHASH(counter, iv);
      var length = Uint8List.view((Uint32List(4)..[0] = iv.length * 8).buffer);
      length = Uint8List.fromList(length.reversed.toList());

      _gHASHBlock(counter, length);
    }
    return counter;
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    var length =
        blockSize < inp.length - inpOff ? blockSize : inp.length - inpOff;

    var i = Uint8List(blockSize);
    i.setAll(0, inp.skip(inpOff).take(length));

    _processedBytes += length;

    _getNextCTRBlock(_e);

    var o = Uint8List.fromList(i);
    _xor(o, _e);
    if (length < blockSize) o.fillRange(length, blockSize, 0);

    out.setRange(outOff, outOff + length, o);

    var c = forEncryption ? o : i;

    _gHASHBlock(_x, c);

    return length;
  }

  void _gHASH(Uint8List x, Uint8List y) {
    var block = Uint8List(16);
    for (var i = 0; i < y.length; i += 16) {
      block.setAll(0, y.sublist(i, min(i + 16, y.length)));
      block.fillRange(min(i + 16, y.length) - i, 16, 0);
      _gHASHBlock(x, block);
    }
  }

  void _gHASHBlock(Uint8List x, Uint8List y) {
    _xor(x, y);
    _mult(x, _h);
  }

  void _getNextCTRBlock(Uint8List out) {
    //
    // This is tested manually by forcing _blocksRemaining to 1 and trying to run
    // the unit tests. Otherwise it takes 64GB of data to exhaust.
    //
    if (_blocksRemaining == 0) {
      throw StateError('Attempt to process too many blocks');
    }
    _blocksRemaining--;

    _counter[15]++;
    for (var i = 15; i >= 12 && _counter[i] == 0; i--) {
      _counter[i] = 0;
      if (i > 12) _counter[i - 1]++;
    }
    _computeE(_counter, out);
  }

  void _computeE(Uint8List inp, Uint8List out) {
    underlyingCipher.processBlock(inp, 0, out, 0);
  }

  final Uint8List r = Uint8List(16)..[0] = 0xe1;

  void _mult(Uint8List x, Uint8List y) {
    var v = x;
    var z = Uint8List(x.length);

    for (var i = 0; i < 128; i++) {
      CT_xor(z, v, _bit(y, i));
      CT_xor(v, r, _shiftRight(v));
    }

    x.setAll(0, z);
  }

  void _xor(Uint8List x, Uint8List? y) {
    for (var i = 0; i < x.length; i++) {
      x[i] ^= y![i];
    }
  }

  bool _bit(Uint8List x, int n) {
    var byte = n ~/ 8;
    var mask = 1 << (7 - n % 8);
    return x[byte] & mask == mask;
  }

  bool _shiftRight(Uint8List x) {
    var overflow = false;
    for (var i = 0; i < x.length; i++) {
      var nextOverflow = x[i] & 0x1 == 0x1;
      x[i] >>= 1;
      if (overflow) x[i] |= 0x80;
      overflow = nextOverflow;
    }
    return overflow;
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    var result = remainingInput.isNotEmpty
        ? processBlock(remainingInput, 0, out, outOff)
        : 0;

    var len = Uint8List.view((Uint32List(4)
          ..[2] = aad!.length * 8
          ..[0] = _processedBytes * 8)
        .buffer);
    len = Uint8List.fromList(len.reversed.toList());

    _gHASHBlock(_x, len);

    _xor(_x, _e0);

    if (forEncryption) {
      out.setAll(outOff + result, _x);
      result += _x.length;
    }

    validateMac();

    return result;
  }

  @override
  Uint8List get mac => _x;

  @override
  void processAADBytes(Uint8List inp, int inpOff, int len) {
    var block = Uint8List(16);
    for (var i = 0; i < len; i += 16) {
      block.fillRange(0, 16, 0);
      block.setAll(
          0, inp.sublist(inpOff + i, inpOff + min(i + 16, len) as int));
      _gHASHBlock(_x, block);
    }
  }
}
