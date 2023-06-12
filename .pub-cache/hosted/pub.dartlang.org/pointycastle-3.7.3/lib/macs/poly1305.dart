// This file has been migrated.

library impl.mac.poly1305;

import 'dart:typed_data';

import 'package:pointycastle/src/platform_check/platform_check.dart';

import '../api.dart';
import '../src/impl/base_mac.dart';
import '../src/registry/registry.dart';
import '../src/ufixnum.dart';
import '../src/utils.dart';

class Poly1305 extends BaseMac {
  static const R_MASK_LOW_2 = 0xFC;
  static const R_MASK_HIGH_4 = 0x0F;

  Poly1305() {
    Platform.instance.assertFullWidthInteger();
    cipher = null;
  }

  Poly1305.withCipher(this.cipher) {
    Platform.instance.assertFullWidthInteger();
    if (cipher!.blockSize != BLOCK_SIZE) {
      throw ArgumentError('Poly1305 requires a 128 bit block cipher.');
    }
  }

  // ignore: non_constant_identifier_names
  static final FactoryConfig factoryConfig = DynamicFactoryConfig.suffix(
    Mac,
    '/Poly1305',
    (_, final Match match) => () {
      var cipher = BlockCipher(match.group(1)!);
      return Poly1305.withCipher(cipher);
    },
  );

  static void clamp(Uint8List key) {
    key[3] &= R_MASK_HIGH_4;
    key[7] &= R_MASK_HIGH_4;
    key[11] &= R_MASK_HIGH_4;
    key[15] &= R_MASK_HIGH_4;

    key[4] &= R_MASK_LOW_2;
    key[8] &= R_MASK_LOW_2;
    key[12] &= R_MASK_LOW_2;
  }

  static bool checkKey(Uint8List key) {
    var c1 = checkMask(key[3], R_MASK_HIGH_4);
    var c2 = checkMask(key[7], R_MASK_HIGH_4);
    var c3 = checkMask(key[11], R_MASK_HIGH_4);
    var c4 = checkMask(key[15], R_MASK_HIGH_4);

    var c5 = checkMask(key[4], R_MASK_LOW_2);
    var c6 = checkMask(key[8], R_MASK_LOW_2);
    var c7 = checkMask(key[12], R_MASK_LOW_2);

    return !(c1 || c2 || c3 || c4 || c5 || c6 || c7);
  }

  static bool checkMask(int b, int mask) {
    if (b & not32(mask) != 0) {
      return false;
    }
    return true;
  }

  @override
  String get algorithmName =>
      cipher == null ? 'Poly1305' : cipher!.algorithmName + '/Poly1305';

  @override
  int get macSize => BLOCK_SIZE;

  static const BLOCK_SIZE = 16;

  BlockCipher? cipher;

  final Uint8List singleByte = Uint8List(1);

  late int r0, r1, r2, r3, r4;

  late int s1, s2, s3, s4;

  late int k0, k1, k2, k3;

  final Uint8List currentBlock = Uint8List(BLOCK_SIZE);

  int currentBlockOffset = 0;

  late int h0, h1, h2, h3, h4;

  @override
  void init(CipherParameters params) {
    Uint8List? nonce;

    if (cipher != null) {
      if (!(params is ParametersWithIV)) {
        throw ArgumentError(
            'Poly1305 requires an IV when used with a block cipher.');
      }

      nonce = params.iv;
      params = params.parameters!;
    }

    if (!(params is KeyParameter)) {
      throw ArgumentError('Poly1305 requires a key.');
    }

    if (!checkKey(params.key)) clamp(params.key);

    setKey(params.key, nonce);

    reset();
  }

  void setKey(Uint8List key, Uint8List? nonce) {
    if (key.length != 32) throw ArgumentError('Poly1305 key must be 256 bits.');
    if (cipher != null && (nonce == null || nonce.length != BLOCK_SIZE)) {
      throw ArgumentError('Poly1305-AES requires a 128 bit IV.');
    }

    var keyByteData = ByteData.view(key.buffer, key.offsetInBytes, key.length);
    var t0 = unpack32(keyByteData, 0, Endian.little);
    var t1 = unpack32(keyByteData, 4, Endian.little);
    var t2 = unpack32(keyByteData, 8, Endian.little);
    var t3 = unpack32(keyByteData, 12, Endian.little);

    r0 = t0 & (0x03FFFFFF);
    r1 = (cshiftr32(t0, 26) | shiftl32(t1, 6)) & 0x03FFFF03;
    r2 = (cshiftr32(t1, 20) | shiftl32(t2, 12)) & 0x03FFC0FF;
    r3 = (cshiftr32(t2, 14) | shiftl32(t3, 18)) & 0x03F03FFF;
    r4 = (cshiftr32(t3, 8)) & 0x000FFFFF;

    s1 = r1 * 5;
    s2 = r2 * 5;
    s3 = r3 * 5;
    s4 = r4 * 5;

    Uint8List kBytes;
    int kOff;
    if (cipher == null) {
      kBytes = key;
      kOff = BLOCK_SIZE;
    } else {
      kBytes = Uint8List(BLOCK_SIZE);
      kOff = 0;

      cipher!.init(true, KeyParameter.offset(key, BLOCK_SIZE, BLOCK_SIZE));
      cipher!.processBlock(nonce!, 0, kBytes, 0);
    }

    var kByteData =
        ByteData.view(kBytes.buffer, kBytes.offsetInBytes, kBytes.length);
    k0 = unpack32(kByteData, kOff, Endian.little);
    k1 = unpack32(kByteData, kOff + 4, Endian.little);
    k2 = unpack32(kByteData, kOff + 8, Endian.little);
    k3 = unpack32(kByteData, kOff + 12, Endian.little);
  }

  @override
  void updateByte(final int inp) {
    singleByte[0] = inp;
    update(singleByte, 0, 1);
  }

  @override
  void update(final Uint8List inp, final int inOff, final int len) {
    var copied = 0;
    while (len > copied) {
      if (currentBlockOffset == BLOCK_SIZE) {
        processBlock();
        currentBlockOffset = 0;
      }

      var toCopy = (len - copied) > (BLOCK_SIZE - currentBlockOffset)
          ? (BLOCK_SIZE - currentBlockOffset)
          : (len - copied);
      arrayCopy(inp, copied + inOff, currentBlock, currentBlockOffset, toCopy);
      copied += toCopy;
      currentBlockOffset += toCopy;
    }
  }

  void processBlock() {
    // TODO Calculation varied between web and native.
    if (currentBlockOffset < BLOCK_SIZE) {
      currentBlock[currentBlockOffset] = 1;
      for (var i = currentBlockOffset + 1; i < BLOCK_SIZE; i++) {
        currentBlock[i] = 0;
      }
    }

    final t0 = unpack32(currentBlock, 0, Endian.little);
    final t1 = unpack32(currentBlock, 4, Endian.little);
    final t2 = unpack32(currentBlock, 8, Endian.little);
    final t3 = unpack32(currentBlock, 12, Endian.little);

    h0 += t0 & 0x3ffffff;
    h1 += uRS((t1 << 32) | t0, 26) & 0x3ffffff;
    h2 += uRS((t2 << 32) | t1, 20) & 0x3ffffff;
    h3 += uRS((t3 << 32) | t2, 14) & 0x3ffffff;
    h4 += uRS(t3, 8);

    if (currentBlockOffset == BLOCK_SIZE) {
      h4 += shiftl32(1, 24);
    }

    var tp0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
    var tp1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
    var tp2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
    var tp3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
    var tp4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;

    h0 = (tp0 & 0xffffffff) & 0x3ffffff;
    tp1 += uRS(tp0, 26);
    h1 = (tp1 & 0xffffffff) & 0x3ffffff;
    tp2 += uRS(tp1, 26);
    h2 = (tp2 & 0xffffffff) & 0x3ffffff;
    tp3 += uRS(tp2, 26);
    h3 = (tp3 & 0xffffffff) & 0x3ffffff;
    tp4 += uRS(tp3, 26);
    h4 = (tp4 & 0xffffffff) & 0x3ffffff;

    h0 += (uRS(tp4, 26) & 0xffffffff) * 5;
    h1 += cshiftr32(h0, 26);
    h0 &= 0x3ffffff;
  }

  @override
  int doFinal(Uint8List out, final int outOff) {
    if (outOff + BLOCK_SIZE > out.length) {
      throw ArgumentError('Output buffer is too short.');
    }

    if (currentBlockOffset > 0) {
      processBlock();
    }

    h1 += cshiftr32(h0, 26);
    h0 &= 0x3ffffff;
    h2 += cshiftr32(h1, 26);
    h1 &= 0x3ffffff;
    h3 += cshiftr32(h2, 26);
    h2 &= 0x3ffffff;
    h4 += cshiftr32(h3, 26);
    h3 &= 0x3ffffff;
    h0 += cshiftr32(h4, 26) * 5;
    h4 &= 0x3ffffff;
    h1 += cshiftr32(h0, 26);
    h0 &= 0x3ffffff;

    int g0, g1, g2, g3, g4, b;
    g0 = sum32(h0, 5);
    b = cshiftr32(g0, 26);
    g0 &= 0x3ffffff;
    g1 = sum32(h1, b);
    b = cshiftr32(g1, 26);
    g1 &= 0x3ffffff;
    g2 = sum32(h2, b);
    b = cshiftr32(g2, 26);
    g2 &= 0x3ffffff;
    g3 = sum32(h3, b);
    b = cshiftr32(g3, 26);
    g3 &= 0x3ffffff;
    g4 = sum32(h4, b) - shiftl32(1, 26);

    b = cshiftr32(g4, 31) - 1;
    var nb = not32(b);
    h0 = (h0 & nb) | (g0 & b);
    h1 = (h1 & nb) | (g1 & b);
    h2 = (h2 & nb) | (g2 & b);
    h3 = (h3 & nb) | (g3 & b);
    h4 = (h4 & nb) | (g4 & b);

    int f0, f1, f2, f3;
    f0 = (h0 | shiftl32(h1, 26)) + (k0);
    f1 = (cshiftr32(h1, 6) | shiftl32(h2, 20)) + (k1);
    f2 = (cshiftr32(h2, 12) | shiftl32(h3, 14)) + (k2);
    f3 = (cshiftr32(h3, 18) | shiftl32(h4, 8)) + (k3);

    var outByte = ByteData.view(out.buffer, out.offsetInBytes, out.length);
    pack32(f0 & 0xffffffff, outByte, outOff, Endian.little);
    f1 += uRS(f0, 32);
    pack32(f1 & 0xffffffff, outByte, outOff + 4, Endian.little);
    f2 += uRS(f1, 32);
    pack32(f2 & 0xffffffff, outByte, outOff + 8, Endian.little);
    f3 += uRS(f2, 32);
    pack32(f3 & 0xffffffff, outByte, outOff + 12, Endian.little);
    //End come back here chunk

    out = outByte.buffer.asUint8List();

    reset();
    return BLOCK_SIZE;
  }

  @override
  void reset() {
    currentBlockOffset = 0;

    h0 = 0;
    h1 = 0;
    h2 = 0;
    h3 = 0;
    h4 = 0;
  }
}

int uRS(int x, int n) {
  return x >= 0 ? x >> n : ~(~x >> n);
}

/*
int uRS(int x, int n) {
  return (x >= 0) ? x >> (64 - n) : ~(~x >> (64 - n));
}
*/
