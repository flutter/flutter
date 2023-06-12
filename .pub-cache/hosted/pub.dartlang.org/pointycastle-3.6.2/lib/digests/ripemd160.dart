// See file LICENSE for more information.

library impl.digest.ripemd160;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/md4_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of RIPEMD-160 digest.
class RIPEMD160Digest extends MD4FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'RIPEMD-160', () => RIPEMD160Digest());

  static const _DIGEST_LENGTH = 20;

  RIPEMD160Digest() : super(Endian.little, 5, 16);

  @override
  final algorithmName = 'RIPEMD-160';

  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void resetState() {
    state[0] = 0x67452301;
    state[1] = 0xefcdab89;
    state[2] = 0x98badcfe;
    state[3] = 0x10325476;
    state[4] = 0xc3d2e1f0;
  }

  @override
  void processBlock() {
    int? a, aa;
    int? b, bb;
    int? c, cc;
    int? d, dd;
    int? e, ee;

    a = aa = state[0];
    b = bb = state[1];
    c = cc = state[2];
    d = dd = state[3];
    e = ee = state[4];

    // Rounds 1 - 16
    // left
    a = sum32(crotl32(a + _f1(b, c, d) + buffer[0], 11), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f1(a, b, c) + buffer[1], 14), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f1(e, a, b) + buffer[2], 15), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f1(d, e, a) + buffer[3], 12), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f1(c, d, e) + buffer[4], 5), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f1(b, c, d) + buffer[5], 8), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f1(a, b, c) + buffer[6], 7), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f1(e, a, b) + buffer[7], 9), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f1(d, e, a) + buffer[8], 11), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f1(c, d, e) + buffer[9], 13), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f1(b, c, d) + buffer[10], 14), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f1(a, b, c) + buffer[11], 15), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f1(e, a, b) + buffer[12], 6), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f1(d, e, a) + buffer[13], 7), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f1(c, d, e) + buffer[14], 9), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f1(b, c, d) + buffer[15], 8), e);
    c = rotl32(c, 10);

    // right
    aa = sum32(crotl32(aa + _f5(bb, cc, dd) + buffer[5] + 0x50a28be6, 8), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f5(aa, bb, cc) + buffer[14] + 0x50a28be6, 9), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f5(ee, aa, bb) + buffer[7] + 0x50a28be6, 9), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f5(dd, ee, aa) + buffer[0] + 0x50a28be6, 11), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f5(cc, dd, ee) + buffer[9] + 0x50a28be6, 13), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f5(bb, cc, dd) + buffer[2] + 0x50a28be6, 15), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f5(aa, bb, cc) + buffer[11] + 0x50a28be6, 15), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f5(ee, aa, bb) + buffer[4] + 0x50a28be6, 5), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f5(dd, ee, aa) + buffer[13] + 0x50a28be6, 7), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f5(cc, dd, ee) + buffer[6] + 0x50a28be6, 7), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f5(bb, cc, dd) + buffer[15] + 0x50a28be6, 8), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f5(aa, bb, cc) + buffer[8] + 0x50a28be6, 11), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f5(ee, aa, bb) + buffer[1] + 0x50a28be6, 14), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f5(dd, ee, aa) + buffer[10] + 0x50a28be6, 14), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f5(cc, dd, ee) + buffer[3] + 0x50a28be6, 12), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f5(bb, cc, dd) + buffer[12] + 0x50a28be6, 6), ee);
    cc = rotl32(cc, 10);

    // Rounds 16-31
    // left
    e = sum32(crotl32(e + _f2(a, b, c) + buffer[7] + 0x5a827999, 7), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f2(e, a, b) + buffer[4] + 0x5a827999, 6), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f2(d, e, a) + buffer[13] + 0x5a827999, 8), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f2(c, d, e) + buffer[1] + 0x5a827999, 13), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f2(b, c, d) + buffer[10] + 0x5a827999, 11), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f2(a, b, c) + buffer[6] + 0x5a827999, 9), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f2(e, a, b) + buffer[15] + 0x5a827999, 7), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f2(d, e, a) + buffer[3] + 0x5a827999, 15), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f2(c, d, e) + buffer[12] + 0x5a827999, 7), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f2(b, c, d) + buffer[0] + 0x5a827999, 12), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f2(a, b, c) + buffer[9] + 0x5a827999, 15), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f2(e, a, b) + buffer[5] + 0x5a827999, 9), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f2(d, e, a) + buffer[2] + 0x5a827999, 11), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f2(c, d, e) + buffer[14] + 0x5a827999, 7), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f2(b, c, d) + buffer[11] + 0x5a827999, 13), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f2(a, b, c) + buffer[8] + 0x5a827999, 12), d);
    b = rotl32(b, 10);

    // right
    ee = sum32(crotl32(ee + _f4(aa, bb, cc) + buffer[6] + 0x5c4dd124, 9), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f4(ee, aa, bb) + buffer[11] + 0x5c4dd124, 13), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f4(dd, ee, aa) + buffer[3] + 0x5c4dd124, 15), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f4(cc, dd, ee) + buffer[7] + 0x5c4dd124, 7), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f4(bb, cc, dd) + buffer[0] + 0x5c4dd124, 12), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f4(aa, bb, cc) + buffer[13] + 0x5c4dd124, 8), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f4(ee, aa, bb) + buffer[5] + 0x5c4dd124, 9), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f4(dd, ee, aa) + buffer[10] + 0x5c4dd124, 11), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f4(cc, dd, ee) + buffer[14] + 0x5c4dd124, 7), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f4(bb, cc, dd) + buffer[15] + 0x5c4dd124, 7), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f4(aa, bb, cc) + buffer[8] + 0x5c4dd124, 12), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f4(ee, aa, bb) + buffer[12] + 0x5c4dd124, 7), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f4(dd, ee, aa) + buffer[4] + 0x5c4dd124, 6), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f4(cc, dd, ee) + buffer[9] + 0x5c4dd124, 15), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f4(bb, cc, dd) + buffer[1] + 0x5c4dd124, 13), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f4(aa, bb, cc) + buffer[2] + 0x5c4dd124, 11), dd);
    bb = rotl32(bb, 10);

    // Rounds 32-47
    // left
    d = sum32(crotl32(d + _f3(e, a, b) + buffer[3] + 0x6ed9eba1, 11), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f3(d, e, a) + buffer[10] + 0x6ed9eba1, 13), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f3(c, d, e) + buffer[14] + 0x6ed9eba1, 6), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f3(b, c, d) + buffer[4] + 0x6ed9eba1, 7), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f3(a, b, c) + buffer[9] + 0x6ed9eba1, 14), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f3(e, a, b) + buffer[15] + 0x6ed9eba1, 9), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f3(d, e, a) + buffer[8] + 0x6ed9eba1, 13), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f3(c, d, e) + buffer[1] + 0x6ed9eba1, 15), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f3(b, c, d) + buffer[2] + 0x6ed9eba1, 14), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f3(a, b, c) + buffer[7] + 0x6ed9eba1, 8), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f3(e, a, b) + buffer[0] + 0x6ed9eba1, 13), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f3(d, e, a) + buffer[6] + 0x6ed9eba1, 6), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f3(c, d, e) + buffer[13] + 0x6ed9eba1, 5), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f3(b, c, d) + buffer[11] + 0x6ed9eba1, 12), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f3(a, b, c) + buffer[5] + 0x6ed9eba1, 7), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f3(e, a, b) + buffer[12] + 0x6ed9eba1, 5), c);
    a = rotl32(a, 10);

    // right
    dd = sum32(crotl32(dd + _f3(ee, aa, bb) + buffer[15] + 0x6d703ef3, 9), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f3(dd, ee, aa) + buffer[5] + 0x6d703ef3, 7), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f3(cc, dd, ee) + buffer[1] + 0x6d703ef3, 15), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f3(bb, cc, dd) + buffer[3] + 0x6d703ef3, 11), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f3(aa, bb, cc) + buffer[7] + 0x6d703ef3, 8), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f3(ee, aa, bb) + buffer[14] + 0x6d703ef3, 6), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f3(dd, ee, aa) + buffer[6] + 0x6d703ef3, 6), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f3(cc, dd, ee) + buffer[9] + 0x6d703ef3, 14), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f3(bb, cc, dd) + buffer[11] + 0x6d703ef3, 12), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f3(aa, bb, cc) + buffer[8] + 0x6d703ef3, 13), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f3(ee, aa, bb) + buffer[12] + 0x6d703ef3, 5), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f3(dd, ee, aa) + buffer[2] + 0x6d703ef3, 14), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f3(cc, dd, ee) + buffer[10] + 0x6d703ef3, 13), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f3(bb, cc, dd) + buffer[0] + 0x6d703ef3, 13), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f3(aa, bb, cc) + buffer[4] + 0x6d703ef3, 7), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f3(ee, aa, bb) + buffer[13] + 0x6d703ef3, 5), cc);
    aa = rotl32(aa, 10);

    // Rounds 48-63
    // left
    c = sum32(crotl32(c + _f4(d, e, a) + buffer[1] + 0x8f1bbcdc, 11), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f4(c, d, e) + buffer[9] + 0x8f1bbcdc, 12), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f4(b, c, d) + buffer[11] + 0x8f1bbcdc, 14), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f4(a, b, c) + buffer[10] + 0x8f1bbcdc, 15), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f4(e, a, b) + buffer[0] + 0x8f1bbcdc, 14), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f4(d, e, a) + buffer[8] + 0x8f1bbcdc, 15), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f4(c, d, e) + buffer[12] + 0x8f1bbcdc, 9), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f4(b, c, d) + buffer[4] + 0x8f1bbcdc, 8), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f4(a, b, c) + buffer[13] + 0x8f1bbcdc, 9), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f4(e, a, b) + buffer[3] + 0x8f1bbcdc, 14), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f4(d, e, a) + buffer[7] + 0x8f1bbcdc, 5), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f4(c, d, e) + buffer[15] + 0x8f1bbcdc, 6), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f4(b, c, d) + buffer[14] + 0x8f1bbcdc, 8), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f4(a, b, c) + buffer[5] + 0x8f1bbcdc, 6), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f4(e, a, b) + buffer[6] + 0x8f1bbcdc, 5), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f4(d, e, a) + buffer[2] + 0x8f1bbcdc, 12), b);
    e = rotl32(e, 10);

    // right
    cc = sum32(crotl32(cc + _f2(dd, ee, aa) + buffer[8] + 0x7a6d76e9, 15), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f2(cc, dd, ee) + buffer[6] + 0x7a6d76e9, 5), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f2(bb, cc, dd) + buffer[4] + 0x7a6d76e9, 8), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f2(aa, bb, cc) + buffer[1] + 0x7a6d76e9, 11), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f2(ee, aa, bb) + buffer[3] + 0x7a6d76e9, 14), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f2(dd, ee, aa) + buffer[11] + 0x7a6d76e9, 14), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f2(cc, dd, ee) + buffer[15] + 0x7a6d76e9, 6), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f2(bb, cc, dd) + buffer[0] + 0x7a6d76e9, 14), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f2(aa, bb, cc) + buffer[5] + 0x7a6d76e9, 6), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f2(ee, aa, bb) + buffer[12] + 0x7a6d76e9, 9), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f2(dd, ee, aa) + buffer[2] + 0x7a6d76e9, 12), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f2(cc, dd, ee) + buffer[13] + 0x7a6d76e9, 9), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f2(bb, cc, dd) + buffer[9] + 0x7a6d76e9, 12), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f2(aa, bb, cc) + buffer[7] + 0x7a6d76e9, 5), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f2(ee, aa, bb) + buffer[10] + 0x7a6d76e9, 15), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f2(dd, ee, aa) + buffer[14] + 0x7a6d76e9, 8), bb);
    ee = rotl32(ee, 10);

    // Rounds 64-79
    // left
    b = sum32(crotl32(b + _f5(c, d, e) + buffer[4] + 0xa953fd4e, 9), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f5(b, c, d) + buffer[0] + 0xa953fd4e, 15), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f5(a, b, c) + buffer[5] + 0xa953fd4e, 5), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f5(e, a, b) + buffer[9] + 0xa953fd4e, 11), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f5(d, e, a) + buffer[7] + 0xa953fd4e, 6), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f5(c, d, e) + buffer[12] + 0xa953fd4e, 8), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f5(b, c, d) + buffer[2] + 0xa953fd4e, 13), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f5(a, b, c) + buffer[10] + 0xa953fd4e, 12), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f5(e, a, b) + buffer[14] + 0xa953fd4e, 5), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f5(d, e, a) + buffer[1] + 0xa953fd4e, 12), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f5(c, d, e) + buffer[3] + 0xa953fd4e, 13), a);
    d = rotl32(d, 10);
    a = sum32(crotl32(a + _f5(b, c, d) + buffer[8] + 0xa953fd4e, 14), e);
    c = rotl32(c, 10);
    e = sum32(crotl32(e + _f5(a, b, c) + buffer[11] + 0xa953fd4e, 11), d);
    b = rotl32(b, 10);
    d = sum32(crotl32(d + _f5(e, a, b) + buffer[6] + 0xa953fd4e, 8), c);
    a = rotl32(a, 10);
    c = sum32(crotl32(c + _f5(d, e, a) + buffer[15] + 0xa953fd4e, 5), b);
    e = rotl32(e, 10);
    b = sum32(crotl32(b + _f5(c, d, e) + buffer[13] + 0xa953fd4e, 6), a);
    d = rotl32(d, 10);

    // right
    bb = sum32(crotl32(bb + _f1(cc, dd, ee) + buffer[12], 8), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f1(bb, cc, dd) + buffer[15], 5), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f1(aa, bb, cc) + buffer[10], 12), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f1(ee, aa, bb) + buffer[4], 9), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f1(dd, ee, aa) + buffer[1], 12), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f1(cc, dd, ee) + buffer[5], 5), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f1(bb, cc, dd) + buffer[8], 14), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f1(aa, bb, cc) + buffer[7], 6), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f1(ee, aa, bb) + buffer[6], 8), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f1(dd, ee, aa) + buffer[2], 13), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f1(cc, dd, ee) + buffer[13], 6), aa);
    dd = rotl32(dd, 10);
    aa = sum32(crotl32(aa + _f1(bb, cc, dd) + buffer[14], 5), ee);
    cc = rotl32(cc, 10);
    ee = sum32(crotl32(ee + _f1(aa, bb, cc) + buffer[0], 15), dd);
    bb = rotl32(bb, 10);
    dd = sum32(crotl32(dd + _f1(ee, aa, bb) + buffer[3], 13), cc);
    aa = rotl32(aa, 10);
    cc = sum32(crotl32(cc + _f1(dd, ee, aa) + buffer[9], 11), bb);
    ee = rotl32(ee, 10);
    bb = sum32(crotl32(bb + _f1(cc, dd, ee) + buffer[11], 11), aa);
    dd = rotl32(dd, 10);

    dd = clip32(dd + c + state[1]);
    state[1] = clip32(state[2] + d + ee);
    state[2] = clip32(state[3] + e + aa);
    state[3] = clip32(state[4] + a + bb);
    state[4] = clip32(state[0] + b + cc);
    state[0] = dd;
  }

  int _f1(int x, int y, int z) => x ^ y ^ z;

  int _f2(int x, int y, int z) => (x & y) | (~x & z);

  int _f3(int x, int y, int z) => (x | ~y) ^ z;

  int _f4(int x, int y, int z) => (x & z) | (y & ~z);

  int _f5(int x, int y, int z) => x ^ (y | ~z);

  @override
  int get byteLength => 64;
}
