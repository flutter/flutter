// See file LICENSE for more information.

library src.ufixnum_test;

import 'dart:typed_data';

import 'package:pointycastle/src/ufixnum.dart';
import 'package:test/test.dart';

void main() {
  group('int8:', () {
    test('clip8()', () {
      expect(clip8(0x00), 0x00);
      expect(clip8(0xFF), 0xFF);
      expect(clip8(0x100), 0x00);
    });

    test('sum8()', () {
      expect(sum8(0x00, 0x01), 0x01);
      expect(sum8(0xFF, 0x01), 0x00);
    });

    test('sub8()', () {
      expect(sub8(0x00, 0x01), 0xFF);
      expect(sub8(0xFF, 0x01), 0xFE);
    });

    test('shiftl8()', () {
      expect(shiftl8(0xAB, 0), 0xAB);
      expect(shiftl8(0xAB, 4), 0xB0);
      expect(shiftl8(0xAB, 8), 0xAB);
    });

    test('shiftr8()', () {
      expect(shiftr8(0xAB, 0), 0xAB);
      expect(shiftr8(0xAB, 4), 0x0A);
      expect(shiftr8(0xAB, 8), 0xAB);
    });

    test('neg8()', () {
      expect(neg8(0x00), 0x00);
      expect(neg8(0xFF), 0x01);
      expect(neg8(0x01), 0xFF);
    });

    test('not8()', () {
      expect(not8(0x00), 0xFF);
      expect(not8(0xFF), 0x00);
      expect(not8(0x01), 0xFE);
    });

    test('rotl8()', () {
      expect(rotl8(0xAB, 0), 0xAB);
      expect(rotl8(0x7F, 1), 0xFE);
      expect(rotl8(0xAB, 4), 0xBA);
      expect(rotl8(0xAB, 8), 0xAB);
    });

    test('rotr8()', () {
      expect(rotr8(0xAB, 0), 0xAB);
      expect(rotr8(0xFE, 1), 0x7F);
      expect(rotr8(0xAB, 4), 0xBA);
      expect(rotr8(0xAB, 8), 0xAB);
    });
  });

  group('int16:', () {
    test('clip16()', () {
      expect(clip16(0x0000), 0x0000);
      expect(clip16(0xFFFF), 0xFFFF);
      expect(clip16(0x10000), 0x0000);
    });

    test('pack16(BIG_ENDIAN)', () {
      var out = Uint8List(2);
      pack16(0x1020, out, 0, Endian.big);
      expect(out[0], 0x10);
      expect(out[1], 0x20);
    });

    test('pack16(LITTLE_ENDIAN)', () {
      var out = Uint8List(2);
      pack16(0x1020, out, 0, Endian.little);
      expect(out[1], 0x10);
      expect(out[0], 0x20);
    });

    test('unpack16(BIG_ENDIAN)', () {
      var inp = Uint8List.fromList([0x10, 0x20]);
      expect(unpack16(inp, 0, Endian.big), 0x1020);
    });

    test('unpack16(LITTLE_ENDIAN)', () {
      var inp = Uint8List.fromList([0x20, 0x10]);
      expect(unpack16(inp, 0, Endian.little), 0x1020);
    });

    test('pack16(Uint8List.view)', () {
      var out = Uint8List(6);
      out = Uint8List.view(out.buffer, 2, 2);
      pack16(0x1020, out, 0, Endian.big);
      expect(out[0], 0x10);
      expect(out[1], 0x20);
    });

    test('unpack16(Uint8List.view)', () {
      var inp = Uint8List.fromList([0, 0, 0x20, 0x10, 0, 0]);
      inp = Uint8List.view(inp.buffer, 2, 2);
      expect(unpack16(inp, 0, Endian.little), 0x1020);
    });
  });

  group('int32:', () {
    test('clip32()', () {
      expect(clip32(0x00000000), 0x00000000);
      expect(clip32(0xFFFFFFFF), 0xFFFFFFFF);
      expect(clip32(0x100000000), 0x00000000);
    });

    test('sum32()', () {
      expect(sum32(0x00000000, 0x00000001), 0x00000001);
      expect(sum32(0xFFFFFFFF, 0x00000001), 0x00000000);
    });

    test('sub32()', () {
      expect(sub32(0x00000000, 0x00000001), 0xFFFFFFFF);
      expect(sub32(0xFFFFFFFF, 0x00000001), 0xFFFFFFFE);
    });

    test('shiftl32()', () {
      expect(shiftl32(0x10203040, 0), 0x10203040);
      expect(shiftl32(0x10203040, 16), 0x30400000);
      expect(shiftl32(0x10203040, 32), 0x10203040);
    });

    test('shiftr32()', () {
      expect(shiftr32(0x10203040, 0), 0x10203040);
      expect(shiftr32(0x10203040, 16), 0x00001020);
      expect(shiftr32(0x10203040, 32), 0x10203040);
      expect(shiftr32(0x80000000, 8), 0x00800000);
    });

    test('neg32()', () {
      expect(neg32(0x00000000), 0x00000000);
      expect(neg32(0xFFFFFFFF), 0x00000001);
      expect(neg32(0x00000001), 0xFFFFFFFF);
    });

    test('not32()', () {
      expect(not32(0x00000000), 0xFFFFFFFF);
      expect(not32(0xFFFFFFFF), 0x00000000);
      expect(not32(0x00000001), 0xFFFFFFFE);
    });

    test('rotl32()', () {
      expect(rotl32(0x10203040, 0), 0x10203040);
      expect(rotl32(0x10203040, 8), 0x20304010);
      expect(rotl32(0x10203040, 16), 0x30401020);
      expect(rotl32(0x10203040, 32), 0x10203040);
    });

    test('rotr32()', () {
      expect(rotr32(0x10203040, 0), 0x10203040);
      expect(rotr32(0x10203040, 8), 0x40102030);
      expect(rotr32(0x10203040, 16), 0x30401020);
      expect(rotr32(0x10203040, 32), 0x10203040);
    });

    test('pack32(BIG_ENDIAN)', () {
      var out = Uint8List(4);
      pack32(0x10203040, out, 0, Endian.big);
      expect(out[0], 0x10);
      expect(out[1], 0x20);
      expect(out[2], 0x30);
      expect(out[3], 0x40);
    });

    test('pack32(LITTLE_ENDIAN)', () {
      var out = Uint8List(4);
      pack32(0x10203040, out, 0, Endian.little);
      expect(out[3], 0x10);
      expect(out[2], 0x20);
      expect(out[1], 0x30);
      expect(out[0], 0x40);
    });

    test('unpack32(BIG_ENDIAN)', () {
      var inp = Uint8List.fromList([0x10, 0x20, 0x30, 0x40]);
      expect(unpack32(inp, 0, Endian.big), 0x10203040);
    });

    test('unpack32(LITTLE_ENDIAN)', () {
      var inp = Uint8List.fromList([0x40, 0x30, 0x20, 0x10]);
      expect(unpack32(inp, 0, Endian.little), 0x10203040);
    });

    test('pack32(Uint8List.view)', () {
      var out = Uint8List(8);
      out = Uint8List.view(out.buffer, 2, 4);
      pack32(0x10203040, out, 0, Endian.big);
      expect(out[0], 0x10);
      expect(out[1], 0x20);
      expect(out[2], 0x30);
      expect(out[3], 0x40);
    });

    test('unpack32(Uint8List.view)', () {
      var inp = Uint8List.fromList([0, 0, 0x40, 0x30, 0x20, 0x10, 0, 0]);
      inp = Uint8List.view(inp.buffer, 2, 4);
      expect(unpack32(inp, 0, Endian.little), 0x10203040);
    });
  });

  group('Register64:', () {
    test('Register64(hi,lo)', () {
      expect(Register64(0x00000000, 0x00000000),
          Register64(0x00000000, 0x00000000));
      expect(Register64(0x10203040, 0xFFFFFFFF),
          Register64(0x10203040, 0xFFFFFFFF));
    });

    test('Register64(lo)', () {
      expect(Register64(0x00000000), Register64(0x00000000, 0x00000000));
      expect(Register64(0x10203040), Register64(0x00000000, 0x10203040));
    });

    test('Register64(y)', () {
      expect(Register64(Register64(0x00000000, 0x00000000)),
          Register64(0x00000000, 0x00000000));
      expect(Register64(Register64(0x10203040, 0xFFFFFFFF)),
          Register64(0x10203040, 0xFFFFFFFF));
    });

    test('==', () {
      expect(
          Register64(0x00000000, 0x00000000) ==
              Register64(0x00000000, 0x00000000),
          true);
      expect(
          Register64(0x00000000, 0x00000001) ==
              Register64(0x00000000, 0x00000000),
          false);
      expect(
          Register64(0x00000001, 0x00000000) ==
              Register64(0x00000000, 0x00000000),
          false);
      expect(
          Register64(0x00000001, 0x00000001) ==
              Register64(0x00000000, 0x00000000),
          false);
    });

    test('<', () {
      expect(
          Register64(0x00000000, 0x00000000) <
              Register64(0x00000000, 0x00000000),
          false);

      expect(
          Register64(0x00000000, 0x00000001) <
              Register64(0x00000000, 0x10000000),
          true);
      expect(
          Register64(0x00000000, 0x20000000) <
              Register64(0x00000000, 0x10000000),
          false);
      expect(
          Register64(0x00000001, 0x00000000) <
              Register64(0x00000000, 0x10000000),
          false);

      expect(
          Register64(0x00000000, 0x00000001) <
              Register64(0x10000000, 0x00000000),
          true);
      expect(
          Register64(0x00000001, 0x00000001) <
              Register64(0x10000000, 0x00000000),
          true);
      expect(
          Register64(0x10000000, 0x00000000) <
              Register64(0x10000000, 0x00000000),
          false);
      expect(
          Register64(0x20000000, 0x00000001) <
              Register64(0x10000000, 0x00000000),
          false);
    });

    test('<=', () {
      expect(
          Register64(0x00000000, 0x00000000) <=
              Register64(0x00000000, 0x00000000),
          true);

      expect(
          Register64(0x00000000, 0x00000001) <=
              Register64(0x00000000, 0x10000000),
          true);
      expect(
          Register64(0x00000000, 0x20000000) <=
              Register64(0x00000000, 0x10000000),
          false);
      expect(
          Register64(0x00000001, 0x00000000) <=
              Register64(0x00000000, 0x10000000),
          false);

      expect(
          Register64(0x00000000, 0x00000001) <=
              Register64(0x10000000, 0x00000000),
          true);
      expect(
          Register64(0x00000001, 0x00000001) <=
              Register64(0x10000000, 0x00000000),
          true);
      expect(
          Register64(0x10000000, 0x00000000) <=
              Register64(0x10000000, 0x00000000),
          true);
      expect(
          Register64(0x20000000, 0x00000001) <=
              Register64(0x10000000, 0x00000000),
          false);
    });

    test('>', () {
      expect(
          Register64(0x00000000, 0x00000000) >
              Register64(0x00000000, 0x00000000),
          false);

      expect(
          Register64(0x00000000, 0x10000000) >
              Register64(0x00000000, 0x00000001),
          true);
      expect(
          Register64(0x00000000, 0x10000000) >
              Register64(0x00000000, 0x20000000),
          false);
      expect(
          Register64(0x10000000, 0x00000000) >
              Register64(0x00000001, 0x00000000),
          true);

      expect(
          Register64(0x10000000, 0x00000001) >
              Register64(0x00000000, 0x00000000),
          true);
      expect(
          Register64(0x10000000, 0x00000000) >
              Register64(0x00000001, 0x00000001),
          true);
      expect(
          Register64(0x10000000, 0x00000000) >
              Register64(0x10000000, 0x00000000),
          false);
      expect(
          Register64(0x10000000, 0x00000000) >
              Register64(0x20000000, 0x00000001),
          false);
    });

    test('>=', () {
      expect(
          Register64(0x00000000, 0x00000000) >=
              Register64(0x00000000, 0x00000000),
          true);

      expect(
          Register64(0x00000000, 0x10000000) >=
              Register64(0x00000000, 0x00000001),
          true);
      expect(
          Register64(0x00000000, 0x10000000) >=
              Register64(0x00000000, 0x20000000),
          false);
      expect(
          Register64(0x10000000, 0x00000000) >=
              Register64(0x00000001, 0x00000000),
          true);

      expect(
          Register64(0x10000000, 0x00000001) >=
              Register64(0x00000000, 0x00000000),
          true);
      expect(
          Register64(0x10000000, 0x00000000) >=
              Register64(0x00000001, 0x00000001),
          true);
      expect(
          Register64(0x10000000, 0x00000000) >=
              Register64(0x10000000, 0x00000000),
          true);
      expect(
          Register64(0x10000000, 0x00000000) >=
              Register64(0x20000000, 0x00000001),
          false);
    });

    test('set(hi,lo)', () {
      expect(Register64()..set(0x00000000, 0x00000000),
          Register64(0x00000000, 0x00000000));
      expect(Register64()..set(0x10203040, 0xFFFFFFFF),
          Register64(0x10203040, 0xFFFFFFFF));
    });

    test('set(lo)', () {
      expect(Register64()..set(0x00000000), Register64(0x00000000, 0x00000000));
      expect(Register64()..set(0x10203040), Register64(0x00000000, 0x10203040));
    });

    test('set(y)', () {
      expect(Register64()..set(Register64(0x00000000, 0x00000000)),
          Register64(0x00000000, 0x00000000));
      expect(Register64()..set(Register64(0x10203040, 0xFFFFFFFF)),
          Register64(0x10203040, 0xFFFFFFFF));
    });

    test('sum(int)', () {
      expect(Register64(0x00000000, 0x00000000)..sum(0x00000001),
          Register64(0x00000000, 0x00000001));
      expect(Register64(0x00000000, 0x80000000)..sum(0x80000001),
          Register64(0x00000001, 0x00000001));
      expect(Register64(0xFFFFFFFF, 0xFFFFFFFF)..sum(0x00000001),
          Register64(0x00000000, 0x00000000));
    });

    test('sum(y)', () {
      expect(
          Register64(0x00000000, 0x00000000)
            ..sum(Register64(0x00000000, 0x00000001)),
          Register64(0x00000000, 0x00000001));
      expect(
          Register64(0x00000000, 0x80000000)
            ..sum(Register64(0x00000000, 0x80000001)),
          Register64(0x00000001, 0x00000001));
      expect(
          Register64(0xFFFFFFFF, 0xFFFFFFFF)
            ..sum(Register64(0x00000000, 0x00000001)),
          Register64(0x00000000, 0x00000000));
    });

    test('sub(int)', () {
      expect(Register64(0x00000000, 0x00000000)..sub(0x00000001),
          Register64(0xFFFFFFFF, 0xFFFFFFFF));
      expect(Register64(0x00000001, 0x00000001)..sub(0x80000001),
          Register64(0x00000000, 0x80000000));
      expect(Register64(0xFFFFFFFF, 0xFFFFFFFF)..sub(0x00000001),
          Register64(0xFFFFFFFF, 0xFFFFFFFE));
    });

    test('sub(y)', () {
      expect(
          Register64(0x00000000, 0x00000000)
            ..sub(Register64(0x00000000, 0x00000001)),
          Register64(0xFFFFFFFF, 0xFFFFFFFF));
      expect(
          Register64(0x00000001, 0x00000001)
            ..sub(Register64(0x00000000, 0x80000001)),
          Register64(0x00000000, 0x80000000));
      expect(
          Register64(0xFFFFFFFF, 0xFFFFFFFF)
            ..sub(Register64(0x00000000, 0x00000001)),
          Register64(0xFFFFFFFF, 0xFFFFFFFE));
    });

    test('mod(int)', () {
      expect(Register64(0x80000000, 0xFFFFFFFF)..mod(0x80000001),
          Register64(0x80000000));
      expect(Register64(0x001a808c, 0xd14e661f)..mod(0x1de25c1c),
          Register64(0x19c7c283));
      expect(Register64(0x2419b4a0, 0xb107ecae)..mod(0xf9891c30),
          Register64(0xed7c34ae));
      expect(Register64(0x18bda296)..mod(0x0c8b924c), Register64(0x0c32104a));
    });

    test('mul(int)', () {
      expect(Register64(0x00000000, 0x00000000)..mul(0x00000000),
          Register64(0x00000000, 0x00000000));
      expect(Register64(0x00000000, 0x00000000)..mul(0x00000001),
          Register64(0x00000000, 0x00000000));
      expect(Register64(0x00000000, 0x00000001)..mul(0x00000001),
          Register64(0x00000000, 0x00000001));
      expect(Register64(0x00000001, 0x00000000)..mul(0x00000001),
          Register64(0x00000001, 0x00000000));
      expect(Register64(0x00000000, 0x00000001)..mul(0xFFFFFFFF),
          Register64(0x00000000, 0xFFFFFFFF));
      expect(Register64(0x00000000, 0x80000000)..mul(0x00000004),
          Register64(0x00000002, 0x00000000));
      expect(Register64(0x00000000, 0x80000001)..mul(0x00000004),
          Register64(0x00000002, 0x00000004));
      expect(Register64(0x80000001, 0x80000001)..mul(0x00000004),
          Register64(0x00000006, 0x00000004));

      expect(Register64(0x43dc7, 0xd7e76b0c)..mul(0x7ea),
          Register64(0x2190ef92, 0xad752cf8));
      expect(Register64(0x0, 0xc32451e7)..mul(0x23567c25),
          Register64(0x1aefe407, 0xe485ba63));
      expect(Register64(0x2, 0xd076305c)..mul(0x2c7b5a06),
          Register64(0x7d2f7673, 0x7bf97a28));
      expect(Register64(0x1c, 0xca56897f)..mul(0x3dd00d4),
          Register64(0x6f39c828, 0xbf4cdd2c));
      expect(Register64(0x288c, 0xebf98043)..mul(0x279fb),
          Register64(0x646c35a7, 0x4bc66cb1));
      expect(Register64(0x11a82, 0xfc7ab318)..mul(0x710a),
          Register64(0x7cbeda90, 0x5d896f0));
      expect(Register64(0x2edc, 0x994d7f30)..mul(0x1a21c),
          Register64(0x4c895271, 0x4e264940));
      expect(Register64(0xddcf, 0x53e5547b)..mul(0x3b80),
          Register64(0x338dafff, 0xcd229680));
      expect(Register64(0x2087b, 0x1f168aac)..mul(0x2067),
          Register64(0x41e0cd6c, 0x53674b34));
      expect(Register64(0x0, 0x3e0b2bad)..mul(0x8fc3718f),
          Register64(0x22d79b6d, 0x7e4bc2a3));
      expect(Register64(0x0, 0xeabdc8f2)..mul(0xf7f86812),
          Register64(0xe360e429, 0xc36a7104));
      expect(Register64(0x0, 0xfb56ee12)..mul(0x2a25f213),
          Register64(0x2961844a, 0x311aaf56));
      expect(Register64(0x0, 0x5639e48a)..mul(0xfc587481),
          Register64(0x54fec81c, 0x162ab18a));
      expect(Register64(0x0, 0xbb0fca68)..mul(0xe480f4e6),
          Register64(0xa6f84b1c, 0xf11af970));
    });

    test('mul(y)', () {
      expect(
          Register64(0x00000000, 0x00000000)
            ..mul(Register64(0x00000000, 0x00000000)),
          Register64(0x00000000, 0x00000000));
      expect(
          Register64(0x00000000, 0x00000000)
            ..mul(Register64(0x00000000, 0x00000001)),
          Register64(0x00000000, 0x00000000));
      expect(
          Register64(0x00000000, 0x00000001)
            ..mul(Register64(0x00000000, 0x00000001)),
          Register64(0x00000000, 0x00000001));
      expect(
          Register64(0x00000001, 0x00000000)
            ..mul(Register64(0x00000000, 0x00000001)),
          Register64(0x00000001, 0x00000000));
      expect(
          Register64(0x00000000, 0x00000001)
            ..mul(Register64(0x00000000, 0xFFFFFFFF)),
          Register64(0x00000000, 0xFFFFFFFF));
      expect(
          Register64(0x00000000, 0x80000000)
            ..mul(Register64(0x00000000, 0x00000004)),
          Register64(0x00000002, 0x00000000));
      expect(
          Register64(0x00000000, 0x80000001)
            ..mul(Register64(0x00000000, 0x00000004)),
          Register64(0x00000002, 0x00000004));
      expect(
          Register64(0x80000001, 0x80000001)
            ..mul(Register64(0x00000000, 0x00000004)),
          Register64(0x00000006, 0x00000004));
      expect(Register64(0x0, 0xb2ea00)..mul(Register64(0x73, 0xfecac71a)),
          Register64(0x51112fe3, 0xca11c400));
      expect(Register64(0x0, 0x7b0e)..mul(Register64(0x4ecc, 0x2675c20c)),
          Register64(0x25e065a4, 0xaeac60a8));
      expect(Register64(0x0, 0x325ecbc4)..mul(Register64(0x0, 0xd3dbfcc0)),
          Register64(0x29af6ac5, 0xf459c300));
      expect(Register64(0x0, 0xc84d)..mul(Register64(0x7a66, 0x9e3d4aa8)),
          Register64(0x5fc4fc7d, 0x7ac2b488));
      expect(Register64(0x0, 0x2ce3)..mul(Register64(0x1218, 0xe1c9dad3)),
          Register64(0x32c52de, 0xe7994d19));
      expect(Register64(0x0, 0xaa442)..mul(Register64(0x35e, 0x2537590a)),
          Register64(0x23d6a246, 0x87b35c94));
      expect(Register64(0x0, 0x83085)..mul(Register64(0x7e6, 0xceec37e4)),
          Register64(0x40b5d917, 0x8a53c974));
      expect(Register64(0x0, 0x45c1c4d)..mul(Register64(0x6, 0xdd294ade)),
          Register64(0x1dece243, 0x6963ccc6));
      expect(Register64(0x0, 0x274aef21)..mul(Register64(0x0, 0x4ff9175a)),
          Register64(0xc465b43, 0x51ed089a));
      expect(Register64(0x0, 0x13246489)..mul(Register64(0x0, 0x2c6ae04d)),
          Register64(0x3523f1e, 0xc6a41d35));
    });

    test('neg()', () {
      expect(Register64(0x00000000, 0x00000000)..neg(),
          Register64(0x00000000, 0x00000000));
      expect(Register64(0xFFFFFFFF, 0xFFFFFFFF)..neg(),
          Register64(0x00000000, 0x00000001));
      expect(Register64(0x50505050, 0x05050505)..neg(),
          Register64(0xAFAFAFAF, 0xFAFAFAFB));
    });

    test('not()', () {
      expect(Register64(0x00000000, 0x00000000)..not(),
          Register64(0xFFFFFFFF, 0xFFFFFFFF));
      expect(Register64(0xFFFFFFFF, 0xFFFFFFFF)..not(),
          Register64(0x00000000, 0x00000000));
      expect(Register64(0x50505050, 0x05050505)..not(),
          Register64(0xAFAFAFAF, 0xFAFAFAFA));
    });

    test('and()', () {
      expect(
          Register64(0x00000000, 0x00000000)
            ..and(Register64(0xFFFFFFFF, 0xFFFFFFFF)),
          Register64(0x00000000, 0x00000000));
      expect(
          Register64(0x10203040, 0x05050505)
            ..and(Register64(0xFFFFFFFF, 0xFFFFFFFF)),
          Register64(0x10203040, 0x05050505));
      expect(
          Register64(0x10203040, 0x05050505)
            ..and(Register64(0x00000000, 0xFFFFFFFF)),
          Register64(0x00000000, 0x05050505));
      expect(
          Register64(0x10203040, 0x05050505)
            ..and(Register64(0xFFFFFFFF, 0x00000000)),
          Register64(0x10203040, 0x00000000));
    });

    test('or()', () {
      expect(
          Register64(0x00000000, 0x00000000)
            ..or(Register64(0xFFFFFFFF, 0xFFFFFFFF)),
          Register64(0xFFFFFFFF, 0xFFFFFFFF));
      expect(
          Register64(0x10203040, 0x05050505)
            ..or(Register64(0xFFFFFFFF, 0xFFFFFFFF)),
          Register64(0xFFFFFFFF, 0xFFFFFFFF));
      expect(
          Register64(0x10203040, 0x05050505)
            ..or(Register64(0x00000000, 0xFFFFFFFF)),
          Register64(0x10203040, 0xFFFFFFFF));
      expect(
          Register64(0x10203040, 0x05050505)
            ..or(Register64(0xFFFFFFFF, 0x00000000)),
          Register64(0xFFFFFFFF, 0x05050505));
    });

    test('xor()', () {
      expect(
          Register64(0x00000000, 0x00000000)
            ..xor(Register64(0xFFFFFFFF, 0xFFFFFFFF)),
          Register64(0xFFFFFFFF, 0xFFFFFFFF));
      expect(
          Register64(0x10203040, 0x05050505)
            ..xor(Register64(0xFFFFFFFF, 0xFFFFFFFF)),
          Register64(0xEFDFCFBF, 0xFAFAFAFA));
      expect(
          Register64(0x10203040, 0x05050505)
            ..xor(Register64(0x00000000, 0xFFFFFFFF)),
          Register64(0x10203040, 0xFAFAFAFA));
      expect(
          Register64(0x10203040, 0x05050505)
            ..xor(Register64(0xFFFFFFFF, 0x00000000)),
          Register64(0xEFDFCFBF, 0x05050505));
    });

    test('shiftl()', () {
      expect(Register64(0x10203040, 0x05050505)..shiftl(0),
          Register64(0x10203040, 0x05050505));
      expect(Register64(0x10203040, 0x05050505)..shiftl(16),
          Register64(0x30400505, 0x05050000));
      expect(Register64(0x10203040, 0x05050505)..shiftl(32),
          Register64(0x05050505, 0x00000000));
      expect(Register64(0x10203040, 0x05050505)..shiftl(48),
          Register64(0x05050000, 0x00000000));
      expect(Register64(0x10203040, 0x05050505)..shiftl(64),
          Register64(0x10203040, 0x05050505));
    });

    test('shiftr()', () {
      expect(Register64(0x10203040, 0x05050505)..shiftr(0),
          Register64(0x10203040, 0x05050505));
      expect(Register64(0x10203040, 0x05050505)..shiftr(16),
          Register64(0x00001020, 0x30400505));
      expect(Register64(0x10203040, 0x05050505)..shiftr(32),
          Register64(0x00000000, 0x10203040));
      expect(Register64(0x10203040, 0x05050505)..shiftr(48),
          Register64(0x00000000, 0x00001020));
      expect(Register64(0x10203040, 0x05050505)..shiftr(64),
          Register64(0x10203040, 0x05050505));
    });

    test('rotl()', () {
      expect(Register64(0x10203040, 0x05050505)..rotl(0),
          Register64(0x10203040, 0x05050505));
      expect(Register64(0x10203040, 0x05050505)..rotl(16),
          Register64(0x30400505, 0x05051020));
      expect(Register64(0x10203040, 0x05050505)..rotl(32),
          Register64(0x05050505, 0x10203040));
      expect(Register64(0x10203040, 0x05050505)..rotl(48),
          Register64(0x05051020, 0x30400505));
      expect(Register64(0x10203040, 0x05050505)..rotl(64),
          Register64(0x10203040, 0x05050505));
    });

    test('rotr()', () {
      expect(Register64(0x10203040, 0x05050505)..rotr(0),
          Register64(0x10203040, 0x05050505));
      expect(Register64(0x10203040, 0x05050505)..rotr(16),
          Register64(0x05051020, 0x30400505));
      expect(Register64(0x10203040, 0x05050505)..rotr(32),
          Register64(0x05050505, 0x10203040));
      expect(Register64(0x10203040, 0x05050505)..rotr(48),
          Register64(0x30400505, 0x05051020));
      expect(Register64(0x10203040, 0x05050505)..rotr(64),
          Register64(0x10203040, 0x05050505));
    });

    test('pack(BIG_ENDIAN)', () {
      var out = Uint8List(64);
      Register64(0x10203040, 0x50607080).pack(out, 0, Endian.big);
      expect(out[0], 0x10);
      expect(out[1], 0x20);
      expect(out[2], 0x30);
      expect(out[3], 0x40);
      expect(out[4], 0x50);
      expect(out[5], 0x60);
      expect(out[6], 0x70);
      expect(out[7], 0x80);
    });

    test('pack(LITTLE_ENDIAN)', () {
      var out = Uint8List(64);
      Register64(0x10203040, 0x50607080).pack(out, 0, Endian.little);
      expect(out[7], 0x10);
      expect(out[6], 0x20);
      expect(out[5], 0x30);
      expect(out[4], 0x40);
      expect(out[3], 0x50);
      expect(out[2], 0x60);
      expect(out[1], 0x70);
      expect(out[0], 0x80);
    });

    test('unpack(BIG_ENDIAN)', () {
      var inp =
          Uint8List.fromList([0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70, 0x80]);
      expect(Register64()..unpack(inp, 0, Endian.big),
          Register64(0x10203040, 0x50607080));
    });

    test('unpack(LITTLE_ENDIAN)', () {
      var inp =
          Uint8List.fromList([0x80, 0x70, 0x60, 0x50, 0x40, 0x30, 0x20, 0x10]);
      expect(Register64()..unpack(inp, 0, Endian.little),
          Register64(0x10203040, 0x50607080));
    });

    test('pack(Uint8List.view)', () {
      var out = Uint8List(68);
      out = Uint8List.view(out.buffer, 2, 64);
      Register64(0x10203040, 0x50607080).pack(out, 0, Endian.big);
      expect(out[0], 0x10);
      expect(out[1], 0x20);
      expect(out[2], 0x30);
      expect(out[3], 0x40);
      expect(out[4], 0x50);
      expect(out[5], 0x60);
      expect(out[6], 0x70);
      expect(out[7], 0x80);
    });

    test('unpack(LITTLE_ENDIAN)', () {
      var inp = Uint8List.fromList(
          [0, 0, 0x80, 0x70, 0x60, 0x50, 0x40, 0x30, 0x20, 0x10, 0, 0]);
      inp = Uint8List.view(inp.buffer, 2, 8);
      expect(Register64()..unpack(inp, 0, Endian.little),
          Register64(0x10203040, 0x50607080));
    });

    test('toString()', () {
      expect(Register64(0x00203040, 0x00050505).toString(), '0020304000050505');
    });
  });

  group('Register64List:', () {
    test('Register64.from()', () {
      final list = Register64List.from([
        [0, 1],
        [2, 3],
        [4, 5]
      ]);

      expect(list[0], Register64(0x00000000, 0x00000001));
      expect(list[1], Register64(0x00000002, 0x00000003));
      expect(list[2], Register64(0x00000004, 0x00000005));
    });
  });
}
