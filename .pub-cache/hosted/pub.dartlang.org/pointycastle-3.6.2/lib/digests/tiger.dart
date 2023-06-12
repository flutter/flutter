// See file LICENSE for more information.

library impl.digest.tiger;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/base_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of Tiger digest.
class TigerDigest extends BaseDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'Tiger', () => TigerDigest());

  static const _DIGEST_LENGTH = 24;
  static final _keyMask0 = Register64(0xA5A5A5A5, 0xA5A5A5A5);
  static final _keyMask7 = Register64(0x01234567, 0x89ABCDEF);

  final _a = Register64();
  final _b = Register64();
  final _c = Register64();

  final _byteCount = Register64();

  final _wordBuffer = Uint8List(8);
  int _wordBufferOffset = 0;

  final _buffer = Register64List(8);
  int _bufferOffset = 0;

  TigerDigest() {
    reset();
  }

  @override
  final algorithmName = 'Tiger';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void reset() {
    _a.set(0x01234567, 0x89ABCDEF);
    _b.set(0xFEDCBA98, 0x76543210);
    _c.set(0xF096A5B4, 0xC3B2E187);

    _bufferOffset = 0;
    _buffer.fillRange(0, _buffer.length, 0);

    _wordBufferOffset = 0;
    _wordBuffer.fillRange(0, _wordBuffer.length, 0);

    _byteCount.set(0);
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    _finish();

    _a.pack(out, outOff, Endian.little);
    _b.pack(out, outOff + 8, Endian.little);
    _c.pack(out, outOff + 16, Endian.little);

    reset();

    return _DIGEST_LENGTH;
  }

  @override
  void updateByte(int inp) {
    _wordBuffer[_wordBufferOffset++] = inp;

    if (_wordBufferOffset == _wordBuffer.length) {
      _processWord(_wordBuffer, 0);
    }

    _byteCount.sum(1);
  }

  @override
  void update(Uint8List? inp, int inpOff, int? len) {
    // fill the current word
    while ((_wordBufferOffset != 0) && (len! > 0)) {
      updateByte(inp![inpOff]);

      inpOff++;
      len--;
    }

    // process whole words.
    while (len! > 8) {
      _processWord(inp, inpOff);

      inpOff += 8;
      len -= 8;
      _byteCount.sum(8);
    }

    // load in the remainder.
    while (len! > 0) {
      updateByte(inp![inpOff]);

      inpOff++;
      len--;
    }
  }

  void _processWord(Uint8List? b, int off) {
    _buffer[_bufferOffset++].unpack(b, off, Endian.little);

    if (_bufferOffset == _buffer.length) {
      _processBlock();
    }
    _wordBufferOffset = 0;
  }

  void _processBlock() {
    // save abc
    final aa = Register64(_a);
    final bb = Register64(_b);
    final cc = Register64(_c);

    // rounds and schedule
    _roundABC(_buffer[0], 5);
    _roundBCA(_buffer[1], 5);
    _roundCAB(_buffer[2], 5);
    _roundABC(_buffer[3], 5);
    _roundBCA(_buffer[4], 5);
    _roundCAB(_buffer[5], 5);
    _roundABC(_buffer[6], 5);
    _roundBCA(_buffer[7], 5);

    _keySchedule();

    _roundCAB(_buffer[0], 7);
    _roundABC(_buffer[1], 7);
    _roundBCA(_buffer[2], 7);
    _roundCAB(_buffer[3], 7);
    _roundABC(_buffer[4], 7);
    _roundBCA(_buffer[5], 7);
    _roundCAB(_buffer[6], 7);
    _roundABC(_buffer[7], 7);

    _keySchedule();

    _roundBCA(_buffer[0], 9);
    _roundCAB(_buffer[1], 9);
    _roundABC(_buffer[2], 9);
    _roundBCA(_buffer[3], 9);
    _roundCAB(_buffer[4], 9);
    _roundABC(_buffer[5], 9);
    _roundBCA(_buffer[6], 9);
    _roundCAB(_buffer[7], 9);

    // feed forward
    _a.xor(aa);
    _b.sub(bb);
    _c.sum(cc);

    // clear the x buffer
    _bufferOffset = 0;
    _buffer.fillRange(0, _buffer.length, 0);
  }

  void _processLength(Register64 bitLength) {
    _buffer[7].set(bitLength);
  }

  void _finish() {
    var bitLength = Register64(_byteCount)..shiftl(3);

    updateByte(0x01);

    while (_wordBufferOffset != 0) {
      updateByte(0);
    }

    _processLength(bitLength);

    _processBlock();
  }

  void _keySchedule() {
    final r = Register64();

    _buffer[0].sub(r
      ..set(_buffer[7])
      ..xor(_keyMask0));
    _buffer[1].xor(_buffer[0]);
    _buffer[2].sum(_buffer[1]);
    _buffer[3].sub(r
      ..set(_buffer[1])
      ..not()
      ..shiftl(19)
      ..xor(_buffer[2]));
    _buffer[4].xor(_buffer[3]);
    _buffer[5].sum(_buffer[4]);
    _buffer[6].sub(r
      ..set(_buffer[4])
      ..not()
      ..shiftr(23)
      ..xor(_buffer[5]));
    _buffer[7].xor(_buffer[6]);
    _buffer[0].sum(_buffer[7]);
    _buffer[1].sub(r
      ..set(_buffer[7])
      ..not()
      ..shiftl(19)
      ..xor(_buffer[0]));
    _buffer[2].xor(_buffer[1]);
    _buffer[3].sum(_buffer[2]);
    _buffer[4].sub(r
      ..set(_buffer[2])
      ..not()
      ..shiftr(23)
      ..xor(_buffer[3]));
    _buffer[5].xor(_buffer[4]);
    _buffer[6].sum(_buffer[5]);
    _buffer[7].sub(r
      ..set(_buffer[6])
      ..xor(_keyMask7));
  }

  void _roundABC(Register64 x, int mul) {
    final r = Register64();
    final c = Uint8List(8);

    _c.xor(x);
    _c.pack(c, 0, Endian.little);
    _a.sub(r
      ..set(_t1[c[0]])
      ..xor(_t2[c[2]])
      ..xor(_t3[c[4]])
      ..xor(_t4[c[6]]));
    _b.sum(r
      ..set(_t4[c[1]])
      ..xor(_t3[c[3]])
      ..xor(_t2[c[5]])
      ..xor(_t1[c[7]]));
    _b.mul(mul);
  }

  void _roundBCA(Register64 x, int mul) {
    final r = Register64();
    final a = Uint8List(8);

    _a.xor(x);
    _a.pack(a, 0, Endian.little);
    _b.sub(r
      ..set(_t1[a[0]])
      ..xor(_t2[a[2]])
      ..xor(_t3[a[4]])
      ..xor(_t4[a[6]]));
    _c.sum(r
      ..set(_t4[a[1]])
      ..xor(_t3[a[3]])
      ..xor(_t2[a[5]])
      ..xor(_t1[a[7]]));
    _c.mul(mul);
  }

  void _roundCAB(Register64 x, int mul) {
    final r = Register64();
    final b = Uint8List(8);

    _b.xor(x);
    _b.pack(b, 0, Endian.little);
    _c.sub(r
      ..set(_t1[b[0]])
      ..xor(_t2[b[2]])
      ..xor(_t3[b[4]])
      ..xor(_t4[b[6]]));
    _a.sum(r
      ..set(_t4[b[1]])
      ..xor(_t3[b[3]])
      ..xor(_t2[b[5]])
      ..xor(_t1[b[7]]));
    _a.mul(mul);
  }

  @override
  int get byteLength => 64;
}

// S-Boxes
final _t1 = [
  Register64(0x02aab17c, 0xf7e90c5e),
  Register64(0xac424b03, 0xe243a8ec),
  Register64(0x72cd5be3, 0x0dd5fcd3),
  Register64(0x6d019b93, 0xf6f97f3a),
  Register64(0xcd9978ff, 0xd21f9193),
  Register64(0x7573a1c9, 0x708029e2),
  Register64(0xb164326b, 0x922a83c3),
  Register64(0x46883eee, 0x04915870),
  Register64(0xeaace305, 0x7103ece6),
  Register64(0xc54169b8, 0x08a3535c),
  Register64(0x4ce75491, 0x8ddec47c),
  Register64(0x0aa2f4df, 0xdc0df40c),
  Register64(0x10b76f18, 0xa74dbefa),
  Register64(0xc6ccb623, 0x5ad1ab6a),
  Register64(0x13726121, 0x572fe2ff),
  Register64(0x1a488c6f, 0x199d921e),
  Register64(0x4bc9f9f4, 0xda0007ca),
  Register64(0x26f5e6f6, 0xe85241c7),
  Register64(0x859079db, 0xea5947b6),
  Register64(0x4f1885c5, 0xc99e8c92),
  Register64(0xd78e761e, 0xa96f864b),
  Register64(0x8e36428c, 0x52b5c17d),
  Register64(0x69cf6827, 0x373063c1),
  Register64(0xb607c93d, 0x9bb4c56e),
  Register64(0x7d820e76, 0x0e76b5ea),
  Register64(0x645c9cc6, 0xf07fdc42),
  Register64(0xbf38a078, 0x243342e0),
  Register64(0x5f6b343c, 0x9d2e7d04),
  Register64(0xf2c28aeb, 0x600b0ec6),
  Register64(0x6c0ed85f, 0x7254bcac),
  Register64(0x71592281, 0xa4db4fe5),
  Register64(0x1967fa69, 0xce0fed9f),
  Register64(0xfd5293f8, 0xb96545db),
  Register64(0xc879e9d7, 0xf2a7600b),
  Register64(0x86024892, 0x0193194e),
  Register64(0xa4f9533b, 0x2d9cc0b3),
  Register64(0x9053836c, 0x15957613),
  Register64(0xdb6dcf8a, 0xfc357bf1),
  Register64(0x18beea7a, 0x7a370f57),
  Register64(0x037117ca, 0x50b99066),
  Register64(0x6ab30a97, 0x74424a35),
  Register64(0xf4e92f02, 0xe325249b),
  Register64(0x7739db07, 0x061ccae1),
  Register64(0xd8f3b49c, 0xeca42a05),
  Register64(0xbd56be3f, 0x51382f73),
  Register64(0x45faed58, 0x43b0bb28),
  Register64(0x1c813d5c, 0x11bf1f83),
  Register64(0x8af0e4b6, 0xd75fa169),
  Register64(0x33ee18a4, 0x87ad9999),
  Register64(0x3c26e8ea, 0xb1c94410),
  Register64(0xb510102b, 0xc0a822f9),
  Register64(0x141eef31, 0x0ce6123b),
  Register64(0xfc65b900, 0x59ddb154),
  Register64(0xe0158640, 0xc5e0e607),
  Register64(0x884e0798, 0x26c3a3cf),
  Register64(0x930d0d95, 0x23c535fd),
  Register64(0x35638d75, 0x4e9a2b00),
  Register64(0x4085fccf, 0x40469dd5),
  Register64(0xc4b17ad2, 0x8be23a4c),
  Register64(0xcab2f0fc, 0x6a3e6a2e),
  Register64(0x2860971a, 0x6b943fcd),
  Register64(0x3dde6ee2, 0x12e30446),
  Register64(0x6222f32a, 0xe01765ae),
  Register64(0x5d550bb5, 0x478308fe),
  Register64(0xa9efa98d, 0xa0eda22a),
  Register64(0xc351a716, 0x86c40da7),
  Register64(0x1105586d, 0x9c867c84),
  Register64(0xdcffee85, 0xfda22853),
  Register64(0xccfbd026, 0x2c5eef76),
  Register64(0xbaf294cb, 0x8990d201),
  Register64(0xe69464f5, 0x2afad975),
  Register64(0x94b013af, 0xdf133e14),
  Register64(0x06a7d1a3, 0x2823c958),
  Register64(0x6f95fe51, 0x30f61119),
  Register64(0xd92ab34e, 0x462c06c0),
  Register64(0xed7bde33, 0x887c71d2),
  Register64(0x79746d6e, 0x6518393e),
  Register64(0x5ba41938, 0x5d713329),
  Register64(0x7c1ba6b9, 0x48a97564),
  Register64(0x31987c19, 0x7bfdac67),
  Register64(0xde6c23c4, 0x4b053d02),
  Register64(0x581c49fe, 0xd002d64d),
  Register64(0xdd474d63, 0x38261571),
  Register64(0xaa4546c3, 0xe473d062),
  Register64(0x928fce34, 0x9455f860),
  Register64(0x48161bba, 0xcaab94d9),
  Register64(0x63912430, 0x770e6f68),
  Register64(0x6ec8a5e6, 0x02c6641c),
  Register64(0x87282515, 0x337ddd2b),
  Register64(0x2cda6b42, 0x034b701b),
  Register64(0xb03d37c1, 0x81cb096d),
  Register64(0xe1084382, 0x66c71c6f),
  Register64(0x2b3180c7, 0xeb51b255),
  Register64(0xdf92b82f, 0x96c08bbc),
  Register64(0x5c68c8c0, 0xa632f3ba),
  Register64(0x5504cc86, 0x1c3d0556),
  Register64(0xabbfa4e5, 0x5fb26b8f),
  Register64(0x41848b0a, 0xb3baceb4),
  Register64(0xb334a273, 0xaa445d32),
  Register64(0xbca696f0, 0xa85ad881),
  Register64(0x24f6ec65, 0xb528d56c),
  Register64(0x0ce1512e, 0x90f4524a),
  Register64(0x4e9dd79d, 0x5506d35a),
  Register64(0x258905fa, 0xc6ce9779),
  Register64(0x2019295b, 0x3e109b33),
  Register64(0xf8a9478b, 0x73a054cc),
  Register64(0x2924f2f9, 0x34417eb0),
  Register64(0x3993357d, 0x536d1bc4),
  Register64(0x38a81ac2, 0x1db6ff8b),
  Register64(0x47c4fbf1, 0x7d6016bf),
  Register64(0x1e0faadd, 0x7667e3f5),
  Register64(0x7abcff62, 0x938beb96),
  Register64(0xa78dad94, 0x8fc179c9),
  Register64(0x8f1f98b7, 0x2911e50d),
  Register64(0x61e48eae, 0x27121a91),
  Register64(0x4d62f7ad, 0x31859808),
  Register64(0xeceba345, 0xef5ceaeb),
  Register64(0xf5ceb25e, 0xbc9684ce),
  Register64(0xf633e20c, 0xb7f76221),
  Register64(0xa32cdf06, 0xab8293e4),
  Register64(0x985a202c, 0xa5ee2ca4),
  Register64(0xcf0b8447, 0xcc8a8fb1),
  Register64(0x9f765244, 0x979859a3),
  Register64(0xa8d516b1, 0xa1240017),
  Register64(0x0bd7ba3e, 0xbb5dc726),
  Register64(0xe54bca55, 0xb86adb39),
  Register64(0x1d7a3afd, 0x6c478063),
  Register64(0x519ec608, 0xe7669edd),
  Register64(0x0e5715a2, 0xd149aa23),
  Register64(0x177d4571, 0x848ff194),
  Register64(0xeeb55f32, 0x41014c22),
  Register64(0x0f5e5ca1, 0x3a6e2ec2),
  Register64(0x8029927b, 0x75f5c361),
  Register64(0xad139fab, 0xc3d6e436),
  Register64(0x0d5df1a9, 0x4ccf402f),
  Register64(0x3e8bd948, 0xbea5dfc8),
  Register64(0xa5a0d357, 0xbd3ff77e),
  Register64(0xa2d12e25, 0x1f74f645),
  Register64(0x66fd9e52, 0x5e81a082),
  Register64(0x2e0c90ce, 0x7f687a49),
  Register64(0xc2e8bcbe, 0xba973bc5),
  Register64(0x000001bc, 0xe509745f),
  Register64(0x423777bb, 0xe6dab3d6),
  Register64(0xd1661c7e, 0xaef06eb5),
  Register64(0xa1781f35, 0x4daacfd8),
  Register64(0x2d11284a, 0x2b16affc),
  Register64(0xf1fc4f67, 0xfa891d1f),
  Register64(0x73ecc25d, 0xcb920ada),
  Register64(0xae610c22, 0xc2a12651),
  Register64(0x96e0a810, 0xd356b78a),
  Register64(0x5a9a381f, 0x2fe7870f),
  Register64(0xd5ad62ed, 0xe94e5530),
  Register64(0xd225e5e8, 0x368d1427),
  Register64(0x65977b70, 0xc7af4631),
  Register64(0x99f889b2, 0xde39d74f),
  Register64(0x233f30bf, 0x54e1d143),
  Register64(0x9a9675d3, 0xd9a63c97),
  Register64(0x5470554f, 0xf334f9a8),
  Register64(0x166acb74, 0x4a4f5688),
  Register64(0x70c74caa, 0xb2e4aead),
  Register64(0xf0d09164, 0x6f294d12),
  Register64(0x57b82a89, 0x684031d1),
  Register64(0xefd95a5a, 0x61be0b6b),
  Register64(0x2fbd12e9, 0x69f2f29a),
  Register64(0x9bd37013, 0xfeff9fe8),
  Register64(0x3f9b0404, 0xd6085a06),
  Register64(0x4940c1f3, 0x166cfe15),
  Register64(0x09542c4d, 0xcdf3defb),
  Register64(0xb4c52183, 0x85cd5ce3),
  Register64(0xc935b7dc, 0x4462a641),
  Register64(0x3417f8a6, 0x8ed3b63f),
  Register64(0xb8095929, 0x5b215b40),
  Register64(0xf99cdaef, 0x3b8c8572),
  Register64(0x018c0614, 0xf8fcb95d),
  Register64(0x1b14accd, 0x1a3acdf3),
  Register64(0x84d471f2, 0x00bb732d),
  Register64(0xc1a3110e, 0x95e8da16),
  Register64(0x430a7220, 0xbf1a82b8),
  Register64(0xb77e090d, 0x39df210e),
  Register64(0x5ef4bd9f, 0x3cd05e9d),
  Register64(0x9d4ff6da, 0x7e57a444),
  Register64(0xda1d60e1, 0x83d4a5f8),
  Register64(0xb287c384, 0x17998e47),
  Register64(0xfe3edc12, 0x1bb31886),
  Register64(0xc7fe3ccc, 0x980ccbef),
  Register64(0xe46fb590, 0x189bfd03),
  Register64(0x3732fd46, 0x9a4c57dc),
  Register64(0x7ef700a0, 0x7cf1ad65),
  Register64(0x59c64468, 0xa31d8859),
  Register64(0x762fb0b4, 0xd45b61f6),
  Register64(0x155baed0, 0x99047718),
  Register64(0x68755e4c, 0x3d50baa6),
  Register64(0xe9214e7f, 0x22d8b4df),
  Register64(0x2addbf53, 0x2eac95f4),
  Register64(0x32ae3909, 0xb4bd0109),
  Register64(0x834df537, 0xb08e3450),
  Register64(0xfa209da8, 0x4220728d),
  Register64(0x9e691d9b, 0x9efe23f7),
  Register64(0x0446d288, 0xc4ae8d7f),
  Register64(0x7b4cc524, 0xe169785b),
  Register64(0x21d87f01, 0x35ca1385),
  Register64(0xcebb400f, 0x137b8aa5),
  Register64(0x272e2b66, 0x580796be),
  Register64(0x36122641, 0x25c2b0de),
  Register64(0x057702bd, 0xad1efbb2),
  Register64(0xd4babb8e, 0xacf84be9),
  Register64(0x91583139, 0x641bc67b),
  Register64(0x8bdc2de0, 0x8036e024),
  Register64(0x603c8156, 0xf49f68ed),
  Register64(0xf7d236f7, 0xdbef5111),
  Register64(0x9727c459, 0x8ad21e80),
  Register64(0xa08a0896, 0x670a5fd7),
  Register64(0xcb4a8f43, 0x09eba9cb),
  Register64(0x81af564b, 0x0f7036a1),
  Register64(0xc0b99aa7, 0x78199abd),
  Register64(0x959f1ec8, 0x3fc8e952),
  Register64(0x8c505077, 0x794a81b9),
  Register64(0x3acaaf8f, 0x056338f0),
  Register64(0x07b43f50, 0x627a6778),
  Register64(0x4a44ab49, 0xf5eccc77),
  Register64(0x3bc3d6e4, 0xb679ee98),
  Register64(0x9cc0d4d1, 0xcf14108c),
  Register64(0x4406c00b, 0x206bc8a0),
  Register64(0x82a18854, 0xc8d72d89),
  Register64(0x67e366b3, 0x5c3c432c),
  Register64(0xb923dd61, 0x102b37f2),
  Register64(0x56ab2779, 0xd884271d),
  Register64(0xbe83e1b0, 0xff1525af),
  Register64(0xfb7c65d4, 0x217e49a9),
  Register64(0x6bdbe0e7, 0x6d48e7d4),
  Register64(0x08df8287, 0x45d9179e),
  Register64(0x22ea6a9a, 0xdd53bd34),
  Register64(0xe36e141c, 0x5622200a),
  Register64(0x7f805d1b, 0x8cb750ee),
  Register64(0xafe5c7a5, 0x9f58e837),
  Register64(0xe27f996a, 0x4fb1c23c),
  Register64(0xd3867dfb, 0x0775f0d0),
  Register64(0xd0e673de, 0x6e88891a),
  Register64(0x123aeb9e, 0xafb86c25),
  Register64(0x30f1d5d5, 0xc145b895),
  Register64(0xbb434a2d, 0xee7269e7),
  Register64(0x78cb67ec, 0xf931fa38),
  Register64(0xf33b0372, 0x323bbf9c),
  Register64(0x52d66336, 0xfb279c74),
  Register64(0x505f33ac, 0x0afb4eaa),
  Register64(0xe8a5cd99, 0xa2cce187),
  Register64(0x53497480, 0x1e2d30bb),
  Register64(0x8d2d5711, 0xd5876d90),
  Register64(0x1f1a4128, 0x91bc038e),
  Register64(0xd6e2e71d, 0x82e56648),
  Register64(0x74036c3a, 0x497732b7),
  Register64(0x89b67ed9, 0x6361f5ab),
  Register64(0xffed95d8, 0xf1ea02a2),
  Register64(0xe72b3bd6, 0x1464d43d),
  Register64(0xa6300f17, 0x0bdc4820),
  Register64(0xebc18760, 0xed78a77a),
];

final _t2 = [
  Register64(0xe6a6be5a, 0x05a12138),
  Register64(0xb5a122a5, 0xb4f87c98),
  Register64(0x563c6089, 0x140b6990),
  Register64(0x4c46cb2e, 0x391f5dd5),
  Register64(0xd932addb, 0xc9b79434),
  Register64(0x08ea70e4, 0x2015aff5),
  Register64(0xd765a667, 0x3e478cf1),
  Register64(0xc4fb757e, 0xab278d99),
  Register64(0xdf11c686, 0x2d6e0692),
  Register64(0xddeb84f1, 0x0d7f3b16),
  Register64(0x6f2ef604, 0xa665ea04),
  Register64(0x4a8e0f0f, 0xf0e0dfb3),
  Register64(0xa5edeef8, 0x3dbcba51),
  Register64(0xfc4f0a2a, 0x0ea4371e),
  Register64(0xe83e1da8, 0x5cb38429),
  Register64(0xdc8ff882, 0xba1b1ce2),
  Register64(0xcd45505e, 0x8353e80d),
  Register64(0x18d19a00, 0xd4db0717),
  Register64(0x34a0cfed, 0xa5f38101),
  Register64(0x0be77e51, 0x8887caf2),
  Register64(0x1e341438, 0xb3c45136),
  Register64(0xe05797f4, 0x9089ccf9),
  Register64(0xffd23f9d, 0xf2591d14),
  Register64(0x543dda22, 0x8595c5cd),
  Register64(0x661f81fd, 0x99052a33),
  Register64(0x8736e641, 0xdb0f7b76),
  Register64(0x15227725, 0x418e5307),
  Register64(0xe25f7f46, 0x162eb2fa),
  Register64(0x48a8b212, 0x6c13d9fe),
  Register64(0xafdc5417, 0x92e76eea),
  Register64(0x03d912bf, 0xc6d1898f),
  Register64(0x31b1aafa, 0x1b83f51b),
  Register64(0xf1ac2796, 0xe42ab7d9),
  Register64(0x40a3a7d7, 0xfcd2ebac),
  Register64(0x1056136d, 0x0afbbcc5),
  Register64(0x7889e1dd, 0x9a6d0c85),
  Register64(0xd3352578, 0x2a7974aa),
  Register64(0xa7e25d09, 0x078ac09b),
  Register64(0xbd4138b3, 0xeac6edd0),
  Register64(0x920abfbe, 0x71eb9e70),
  Register64(0xa2a5d0f5, 0x4fc2625c),
  Register64(0xc054e36b, 0x0b1290a3),
  Register64(0xf6dd59ff, 0x62fe932b),
  Register64(0x35373545, 0x11a8ac7d),
  Register64(0xca845e91, 0x72fadcd4),
  Register64(0x84f82b60, 0x329d20dc),
  Register64(0x79c62ce1, 0xcd672f18),
  Register64(0x8b09a2ad, 0xd124642c),
  Register64(0xd0c1e96a, 0x19d9e726),
  Register64(0x5a786a9b, 0x4ba9500c),
  Register64(0x0e020336, 0x634c43f3),
  Register64(0xc17b474a, 0xeb66d822),
  Register64(0x6a731ae3, 0xec9baac2),
  Register64(0x8226667a, 0xe0840258),
  Register64(0x67d45676, 0x91caeca5),
  Register64(0x1d94155c, 0x4875adb5),
  Register64(0x6d00fd98, 0x5b813fdf),
  Register64(0x51286efc, 0xb774cd06),
  Register64(0x5e883447, 0x1fa744af),
  Register64(0xf72ca0ae, 0xe761ae2e),
  Register64(0xbe40e4cd, 0xaee8e09a),
  Register64(0xe9970bbb, 0x5118f665),
  Register64(0x726e4beb, 0x33df1964),
  Register64(0x703b0007, 0x29199762),
  Register64(0x4631d816, 0xf5ef30a7),
  Register64(0xb880b5b5, 0x1504a6be),
  Register64(0x641793c3, 0x7ed84b6c),
  Register64(0x7b21ed77, 0xf6e97d96),
  Register64(0x77630631, 0x2ef96b73),
  Register64(0xae528948, 0xe86ff3f4),
  Register64(0x53dbd7f2, 0x86a3f8f8),
  Register64(0x16cadce7, 0x4cfc1063),
  Register64(0x005c19bd, 0xfa52c6dd),
  Register64(0x68868f5d, 0x64d46ad3),
  Register64(0x3a9d512c, 0xcf1e186a),
  Register64(0x367e62c2, 0x385660ae),
  Register64(0xe359e7ea, 0x77dcb1d7),
  Register64(0x526c0773, 0x749abe6e),
  Register64(0x735ae5f9, 0xd09f734b),
  Register64(0x493fc7cc, 0x8a558ba8),
  Register64(0xb0b9c153, 0x3041ab45),
  Register64(0x321958ba, 0x470a59bd),
  Register64(0x852db00b, 0x5f46c393),
  Register64(0x91209b2b, 0xd336b0e5),
  Register64(0x6e604f7d, 0x659ef19f),
  Register64(0xb99a8ae2, 0x782ccb24),
  Register64(0xccf52ab6, 0xc814c4c7),
  Register64(0x4727d9af, 0xbe11727b),
  Register64(0x7e950d0c, 0x0121b34d),
  Register64(0x756f4356, 0x70ad471f),
  Register64(0xf5add442, 0x615a6849),
  Register64(0x4e87e099, 0x80b9957a),
  Register64(0x2acfa1df, 0x50aee355),
  Register64(0xd898263a, 0xfd2fd556),
  Register64(0xc8f4924d, 0xd80c8fd6),
  Register64(0xcf99ca3d, 0x754a173a),
  Register64(0xfe477bac, 0xaf91bf3c),
  Register64(0xed5371f6, 0xd690c12d),
  Register64(0x831a5c28, 0x5e687094),
  Register64(0xc5d3c90a, 0x3708a0a4),
  Register64(0x0f7f9037, 0x17d06580),
  Register64(0x19f9bb13, 0xb8fdf27f),
  Register64(0xb1bd6f1b, 0x4d502843),
  Register64(0x1c761ba3, 0x8fff4012),
  Register64(0x0d1530c4, 0xe2e21f3b),
  Register64(0x8943ce69, 0xa7372c8a),
  Register64(0xe5184e11, 0xfeb5ce66),
  Register64(0x618bdb80, 0xbd736621),
  Register64(0x7d29bad6, 0x8b574d0b),
  Register64(0x81bb613e, 0x25e6fe5b),
  Register64(0x071c9c10, 0xbc07913f),
  Register64(0xc7beeb79, 0x09ac2d97),
  Register64(0xc3e58d35, 0x3bc5d757),
  Register64(0xeb017892, 0xf38f61e8),
  Register64(0xd4effb9c, 0x9b1cc21a),
  Register64(0x99727d26, 0xf494f7ab),
  Register64(0xa3e063a2, 0x956b3e03),
  Register64(0x9d4a8b9a, 0x4aa09c30),
  Register64(0x3f6ab7d5, 0x00090fb4),
  Register64(0x9cc0f2a0, 0x57268ac0),
  Register64(0x3dee9d2d, 0xedbf42d1),
  Register64(0x330f49c8, 0x7960a972),
  Register64(0xc6b27202, 0x87421b41),
  Register64(0x0ac59ec0, 0x7c00369c),
  Register64(0xef4eac49, 0xcb353425),
  Register64(0xf450244e, 0xef0129d8),
  Register64(0x8acc46e5, 0xcaf4deb6),
  Register64(0x2ffeab63, 0x989263f7),
  Register64(0x8f7cb9fe, 0x5d7a4578),
  Register64(0x5bd8f764, 0x4e634635),
  Register64(0x427a7315, 0xbf2dc900),
  Register64(0x17d0c4aa, 0x2125261c),
  Register64(0x3992486c, 0x93518e50),
  Register64(0xb4cbfee0, 0xa2d7d4c3),
  Register64(0x7c75d620, 0x2c5ddd8d),
  Register64(0xdbc295d8, 0xe35b6c61),
  Register64(0x60b369d3, 0x02032b19),
  Register64(0xce42685f, 0xdce44132),
  Register64(0x06f3ddb9, 0xddf65610),
  Register64(0x8ea4d21d, 0xb5e148f0),
  Register64(0x20b0fce6, 0x2fcd496f),
  Register64(0x2c1b9123, 0x58b0ee31),
  Register64(0xb28317b8, 0x18f5a308),
  Register64(0xa89c1e18, 0x9ca6d2cf),
  Register64(0x0c6b1857, 0x6aaadbc8),
  Register64(0xb65deaa9, 0x1299fae3),
  Register64(0xfb2b794b, 0x7f1027e7),
  Register64(0x04e4317f, 0x443b5beb),
  Register64(0x4b852d32, 0x5939d0a6),
  Register64(0xd5ae6bee, 0xfb207ffc),
  Register64(0x309682b2, 0x81c7d374),
  Register64(0xbae309a1, 0x94c3b475),
  Register64(0x8cc3f97b, 0x13b49f05),
  Register64(0x98a9422f, 0xf8293967),
  Register64(0x244b16b0, 0x1076ff7c),
  Register64(0xf8bf571c, 0x663d67ee),
  Register64(0x1f0d6758, 0xeee30da1),
  Register64(0xc9b611d9, 0x7adeb9b7),
  Register64(0xb7afd588, 0x7b6c57a2),
  Register64(0x6290ae84, 0x6b984fe1),
  Register64(0x94df4cde, 0xacc1a5fd),
  Register64(0x058a5bd1, 0xc5483aff),
  Register64(0x63166cc1, 0x42ba3c37),
  Register64(0x8db8526e, 0xb2f76f40),
  Register64(0xe1088003, 0x6f0d6d4e),
  Register64(0x9e0523c9, 0x971d311d),
  Register64(0x45ec2824, 0xcc7cd691),
  Register64(0x575b8359, 0xe62382c9),
  Register64(0xfa9e400d, 0xc4889995),
  Register64(0xd1823ecb, 0x45721568),
  Register64(0xdafd983b, 0x8206082f),
  Register64(0xaa7d2908, 0x2386a8cb),
  Register64(0x269fcd44, 0x03b87588),
  Register64(0x1b91f5f7, 0x28bdd1e0),
  Register64(0xe4669f39, 0x040201f6),
  Register64(0x7a1d7c21, 0x8cf04ade),
  Register64(0x65623c29, 0xd79ce5ce),
  Register64(0x23684490, 0x96c00bb1),
  Register64(0xab9bf187, 0x9da503ba),
  Register64(0xbc23ecb1, 0xa458058e),
  Register64(0x9a58df01, 0xbb401ecc),
  Register64(0xa070e868, 0xa85f143d),
  Register64(0x4ff18830, 0x7df2239e),
  Register64(0x14d565b4, 0x1a641183),
  Register64(0xee133374, 0x52701602),
  Register64(0x950e3dcf, 0x3f285e09),
  Register64(0x59930254, 0xb9c80953),
  Register64(0x3bf29940, 0x8930da6d),
  Register64(0xa955943f, 0x53691387),
  Register64(0xa15edeca, 0xa9cb8784),
  Register64(0x29142127, 0x352be9a0),
  Register64(0x76f0371f, 0xff4e7afb),
  Register64(0x0239f450, 0x274f2228),
  Register64(0xbb073af0, 0x1d5e868b),
  Register64(0xbfc80571, 0xc10e96c1),
  Register64(0xd2670885, 0x68222e23),
  Register64(0x9671a3d4, 0x8e80b5b0),
  Register64(0x55b5d38a, 0xe193bb81),
  Register64(0x693ae2d0, 0xa18b04b8),
  Register64(0x5c48b4ec, 0xadd5335f),
  Register64(0xfd743b19, 0x4916a1ca),
  Register64(0x25770181, 0x34be98c4),
  Register64(0xe77987e8, 0x3c54a4ad),
  Register64(0x28e11014, 0xda33e1b9),
  Register64(0x270cc59e, 0x226aa213),
  Register64(0x71495f75, 0x6d1a5f60),
  Register64(0x9be853fb, 0x60afef77),
  Register64(0xadc786a7, 0xf7443dbf),
  Register64(0x09044561, 0x73b29a82),
  Register64(0x58bc7a66, 0xc232bd5e),
  Register64(0xf306558c, 0x673ac8b2),
  Register64(0x41f639c6, 0xb6c9772a),
  Register64(0x216defe9, 0x9fda35da),
  Register64(0x11640cc7, 0x1c7be615),
  Register64(0x93c43694, 0x565c5527),
  Register64(0xea038e62, 0x46777839),
  Register64(0xf9abf3ce, 0x5a3e2469),
  Register64(0x741e768d, 0x0fd312d2),
  Register64(0x0144b883, 0xced652c6),
  Register64(0xc20b5a5b, 0xa33f8552),
  Register64(0x1ae69633, 0xc3435a9d),
  Register64(0x97a28ca4, 0x088cfdec),
  Register64(0x8824a43c, 0x1e96f420),
  Register64(0x37612fa6, 0x6eeea746),
  Register64(0x6b4cb165, 0xf9cf0e5a),
  Register64(0x43aa1c06, 0xa0abfb4a),
  Register64(0x7f4dc26f, 0xf162796b),
  Register64(0x6cbacc8e, 0x54ed9b0f),
  Register64(0xa6b7ffef, 0xd2bb253e),
  Register64(0x2e25bc95, 0xb0a29d4f),
  Register64(0x86d6a58b, 0xdef1388c),
  Register64(0xded74ac5, 0x76b6f054),
  Register64(0x8030bdbc, 0x2b45805d),
  Register64(0x3c81af70, 0xe94d9289),
  Register64(0x3eff6dda, 0x9e3100db),
  Register64(0xb38dc39f, 0xdfcc8847),
  Register64(0x12388552, 0x8d17b87e),
  Register64(0xf2da0ed2, 0x40b1b642),
  Register64(0x44cefadc, 0xd54bf9a9),
  Register64(0x1312200e, 0x433c7ee6),
  Register64(0x9ffcc84f, 0x3a78c748),
  Register64(0xf0cd1f72, 0x248576bb),
  Register64(0xec697405, 0x3638cfe4),
  Register64(0x2ba7b67c, 0x0cec4e4c),
  Register64(0xac2f4df3, 0xe5ce32ed),
  Register64(0xcb33d143, 0x26ea4c11),
  Register64(0xa4e9044c, 0xc77e58bc),
  Register64(0x5f513293, 0xd934fcef),
  Register64(0x5dc96455, 0x06e55444),
  Register64(0x50de418f, 0x317de40a),
  Register64(0x388cb31a, 0x69dde259),
  Register64(0x2db4a834, 0x55820a86),
  Register64(0x9010a91e, 0x84711ae9),
  Register64(0x4df7f0b7, 0xb1498371),
  Register64(0xd62a2eab, 0xc0977179),
  Register64(0x22fac097, 0xaa8d5c0e),
];

final _t3 = [
  Register64(0xf49fcc2f, 0xf1daf39b),
  Register64(0x487fd5c6, 0x6ff29281),
  Register64(0xe8a30667, 0xfcdca83f),
  Register64(0x2c9b4be3, 0xd2fcce63),
  Register64(0xda3ff74b, 0x93fbbbc2),
  Register64(0x2fa165d2, 0xfe70ba66),
  Register64(0xa103e279, 0x970e93d4),
  Register64(0xbecdec77, 0xb0e45e71),
  Register64(0xcfb41e72, 0x3985e497),
  Register64(0xb70aaa02, 0x5ef75017),
  Register64(0xd42309f0, 0x3840b8e0),
  Register64(0x8efc1ad0, 0x35898579),
  Register64(0x96c6920b, 0xe2b2abc5),
  Register64(0x66af4163, 0x375a9172),
  Register64(0x2174abdc, 0xca7127fb),
  Register64(0xb33ccea6, 0x4a72ff41),
  Register64(0xf04a4933, 0x083066a5),
  Register64(0x8d970acd, 0xd7289af5),
  Register64(0x8f96e8e0, 0x31c8c25e),
  Register64(0xf3fec022, 0x76875d47),
  Register64(0xec7bf310, 0x056190dd),
  Register64(0xf5adb0ae, 0xbb0f1491),
  Register64(0x9b50f885, 0x0fd58892),
  Register64(0x49754883, 0x58b74de8),
  Register64(0xa3354ff6, 0x91531c61),
  Register64(0x0702bbe4, 0x81d2c6ee),
  Register64(0x89fb2405, 0x7deded98),
  Register64(0xac307513, 0x8596e902),
  Register64(0x1d2d3580, 0x172772ed),
  Register64(0xeb738fc2, 0x8e6bc30d),
  Register64(0x5854ef8f, 0x63044326),
  Register64(0x9e5c5232, 0x5add3bbe),
  Register64(0x90aa53cf, 0x325c4623),
  Register64(0xc1d24d51, 0x349dd067),
  Register64(0x2051cfee, 0xa69ea624),
  Register64(0x13220f0a, 0x862e7e4f),
  Register64(0xce393994, 0x04e04864),
  Register64(0xd9c42ca4, 0x7086fcb7),
  Register64(0x685ad223, 0x8a03e7cc),
  Register64(0x066484b2, 0xab2ff1db),
  Register64(0xfe9d5d70, 0xefbf79ec),
  Register64(0x5b13b9dd, 0x9c481854),
  Register64(0x15f0d475, 0xed1509ad),
  Register64(0x0bebcd06, 0x0ec79851),
  Register64(0xd58c6791, 0x183ab7f8),
  Register64(0xd1187c50, 0x52f3eee4),
  Register64(0xc95d1192, 0xe54e82ff),
  Register64(0x86eea14c, 0xb9ac6ca2),
  Register64(0x3485beb1, 0x53677d5d),
  Register64(0xdd191d78, 0x1f8c492a),
  Register64(0xf60866ba, 0xa784ebf9),
  Register64(0x518f643b, 0xa2d08c74),
  Register64(0x8852e956, 0xe1087c22),
  Register64(0xa768cb8d, 0xc410ae8d),
  Register64(0x38047726, 0xbfec8e1a),
  Register64(0xa67738b4, 0xcd3b45aa),
  Register64(0xad16691c, 0xec0dde19),
  Register64(0xc6d43193, 0x80462e07),
  Register64(0xc5a5876d, 0x0ba61938),
  Register64(0x16b9fa1f, 0xa58fd840),
  Register64(0x188ab117, 0x3ca74f18),
  Register64(0xabda2f98, 0xc99c021f),
  Register64(0x3e0580ab, 0x134ae816),
  Register64(0x5f3b05b7, 0x73645abb),
  Register64(0x2501a2be, 0x5575f2f6),
  Register64(0x1b2f7400, 0x4e7e8ba9),
  Register64(0x1cd75803, 0x71e8d953),
  Register64(0x7f6ed895, 0x62764e30),
  Register64(0xb15926ff, 0x596f003d),
  Register64(0x9f65293d, 0xa8c5d6b9),
  Register64(0x6ecef04d, 0xd690f84c),
  Register64(0x4782275f, 0xff33af88),
  Register64(0xe4143308, 0x3f820801),
  Register64(0xfd0dfe40, 0x9a1af9b5),
  Register64(0x4325a334, 0x2cdb396b),
  Register64(0x8ae77e62, 0xb301b252),
  Register64(0xc36f9e9f, 0x6655615a),
  Register64(0x85455a2d, 0x92d32c09),
  Register64(0xf2c7dea9, 0x49477485),
  Register64(0x63cfb4c1, 0x33a39eba),
  Register64(0x83b040cc, 0x6ebc5462),
  Register64(0x3b9454c8, 0xfdb326b0),
  Register64(0x56f56a9e, 0x87ffd78c),
  Register64(0x2dc2940d, 0x99f42bc6),
  Register64(0x98f7df09, 0x6b096e2d),
  Register64(0x19a6e01e, 0x3ad852bf),
  Register64(0x42a99ccb, 0xdbd4b40b),
  Register64(0xa59998af, 0x45e9c559),
  Register64(0x366295e8, 0x07d93186),
  Register64(0x6b48181b, 0xfaa1f773),
  Register64(0x1fec57e2, 0x157a0a1d),
  Register64(0x4667446a, 0xf6201ad5),
  Register64(0xe615ebca, 0xcfb0f075),
  Register64(0xb8f31f4f, 0x68290778),
  Register64(0x22713ed6, 0xce22d11e),
  Register64(0x3057c1a7, 0x2ec3c93b),
  Register64(0xcb46acc3, 0x7c3f1f2f),
  Register64(0xdbb893fd, 0x02aaf50e),
  Register64(0x331fd92e, 0x600b9fcf),
  Register64(0xa498f961, 0x48ea3ad6),
  Register64(0xa8d8426e, 0x8b6a83ea),
  Register64(0xa089b274, 0xb7735cdc),
  Register64(0x87f6b373, 0x1e524a11),
  Register64(0x118808e5, 0xcbc96749),
  Register64(0x9906e4c7, 0xb19bd394),
  Register64(0xafed7f7e, 0x9b24a20c),
  Register64(0x6509eade, 0xeb3644a7),
  Register64(0x6c1ef1d3, 0xe8ef0ede),
  Register64(0xb9c97d43, 0xe9798fb4),
  Register64(0xa2f2d784, 0x740c28a3),
  Register64(0x7b849647, 0x6197566f),
  Register64(0x7a5be3e6, 0xb65f069d),
  Register64(0xf96330ed, 0x78be6f10),
  Register64(0xeee60de7, 0x7a076a15),
  Register64(0x2b4bee4a, 0xa08b9bd0),
  Register64(0x6a56a63e, 0xc7b8894e),
  Register64(0x02121359, 0xba34fef4),
  Register64(0x4cbf99f8, 0x283703fc),
  Register64(0x39807135, 0x0caf30c8),
  Register64(0xd0a77a89, 0xf017687a),
  Register64(0xf1c1a9eb, 0x9e423569),
  Register64(0x8c797628, 0x2dee8199),
  Register64(0x5d1737a5, 0xdd1f7abd),
  Register64(0x4f53433c, 0x09a9fa80),
  Register64(0xfa8b0c53, 0xdf7ca1d9),
  Register64(0x3fd9dcbc, 0x886ccb77),
  Register64(0xc040917c, 0xa91b4720),
  Register64(0x7dd00142, 0xf9d1dcdf),
  Register64(0x8476fc1d, 0x4f387b58),
  Register64(0x23f8e7c5, 0xf3316503),
  Register64(0x032a2244, 0xe7e37339),
  Register64(0x5c87a5d7, 0x50f5a74b),
  Register64(0x082b4cc4, 0x3698992e),
  Register64(0xdf917bec, 0xb858f63c),
  Register64(0x3270b8fc, 0x5bf86dda),
  Register64(0x10ae72bb, 0x29b5dd76),
  Register64(0x576ac94e, 0x7700362b),
  Register64(0x1ad112da, 0xc61efb8f),
  Register64(0x691bc30e, 0xc5faa427),
  Register64(0xff246311, 0xcc327143),
  Register64(0x3142368e, 0x30e53206),
  Register64(0x71380e31, 0xe02ca396),
  Register64(0x958d5c96, 0x0aad76f1),
  Register64(0xf8d6f430, 0xc16da536),
  Register64(0xc8ffd13f, 0x1be7e1d2),
  Register64(0x7578ae66, 0x004ddbe1),
  Register64(0x05833f01, 0x067be646),
  Register64(0xbb34b5ad, 0x3bfe586d),
  Register64(0x095f34c9, 0xa12b97f0),
  Register64(0x247ab645, 0x25d60ca8),
  Register64(0xdcdbc6f3, 0x017477d1),
  Register64(0x4a2e14d4, 0xdecad24d),
  Register64(0xbdb5e6d9, 0xbe0a1eeb),
  Register64(0x2a7e70f7, 0x794301ab),
  Register64(0xdef42d8a, 0x270540fd),
  Register64(0x01078ec0, 0xa34c22c1),
  Register64(0xe5de511a, 0xf4c16387),
  Register64(0x7ebb3a52, 0xbd9a330a),
  Register64(0x77697857, 0xaa7d6435),
  Register64(0x004e8316, 0x03ae4c32),
  Register64(0xe7a21020, 0xad78e312),
  Register64(0x9d41a70c, 0x6ab420f2),
  Register64(0x28e06c18, 0xea1141e6),
  Register64(0xd2b28cbd, 0x984f6b28),
  Register64(0x26b75f6c, 0x446e9d83),
  Register64(0xba47568c, 0x4d418d7f),
  Register64(0xd80badbf, 0xe6183d8e),
  Register64(0x0e206d7f, 0x5f166044),
  Register64(0xe258a439, 0x11cbca3e),
  Register64(0x723a1746, 0xb21dc0bc),
  Register64(0xc7caa854, 0xf5d7cdd3),
  Register64(0x7cac3288, 0x3d261d9c),
  Register64(0x7690c264, 0x23ba942c),
  Register64(0x17e55524, 0x478042b8),
  Register64(0xe0be4776, 0x56a2389f),
  Register64(0x4d289b5e, 0x67ab2da0),
  Register64(0x44862b9c, 0x8fbbfd31),
  Register64(0xb47cc804, 0x9d141365),
  Register64(0x822c1b36, 0x2b91c793),
  Register64(0x4eb14655, 0xfb13dfd8),
  Register64(0x1ecbba07, 0x14e2a97b),
  Register64(0x6143459d, 0x5cde5f14),
  Register64(0x53a8fbf1, 0xd5f0ac89),
  Register64(0x97ea04d8, 0x1c5e5b00),
  Register64(0x622181a8, 0xd4fdb3f3),
  Register64(0xe9bcd341, 0x572a1208),
  Register64(0x14112586, 0x43cce58a),
  Register64(0x9144c5fe, 0xa4c6e0a4),
  Register64(0x0d33d065, 0x65cf620f),
  Register64(0x54a48d48, 0x9f219ca1),
  Register64(0xc43e5eac, 0x6d63c821),
  Register64(0xa9728b3a, 0x72770daf),
  Register64(0xd7934e7b, 0x20df87ef),
  Register64(0xe35503b6, 0x1a3e86e5),
  Register64(0xcae321fb, 0xc819d504),
  Register64(0x129a50b3, 0xac60bfa6),
  Register64(0xcd5e68ea, 0x7e9fb6c3),
  Register64(0xb01c9019, 0x9483b1c7),
  Register64(0x3de93cd5, 0xc295376c),
  Register64(0xaed52edf, 0x2ab9ad13),
  Register64(0x2e60f512, 0xc0a07884),
  Register64(0xbc3d86a3, 0xe36210c9),
  Register64(0x35269d9b, 0x163951ce),
  Register64(0x0c7d6e2a, 0xd0cdb5fa),
  Register64(0x59e86297, 0xd87f5733),
  Register64(0x298ef221, 0x898db0e7),
  Register64(0x55000029, 0xd1a5aa7e),
  Register64(0x8bc08ae1, 0xb5061b45),
  Register64(0xc2c31c2b, 0x6c92703a),
  Register64(0x94cc596b, 0xaf25ef42),
  Register64(0x0a1d73db, 0x22540456),
  Register64(0x04b6a0f9, 0xd9c4179a),
  Register64(0xeffdafa2, 0xae3d3c60),
  Register64(0xf7c8075b, 0xb49496c4),
  Register64(0x9cc5c714, 0x1d1cd4e3),
  Register64(0x78bd1638, 0x218e5534),
  Register64(0xb2f11568, 0xf850246a),
  Register64(0xedfabcfa, 0x9502bc29),
  Register64(0x796ce5f2, 0xda23051b),
  Register64(0xaae128b0, 0xdc93537c),
  Register64(0x3a493da0, 0xee4b29ae),
  Register64(0xb5df6b2c, 0x416895d7),
  Register64(0xfcabbd25, 0x122d7f37),
  Register64(0x70810b58, 0x105dc4b1),
  Register64(0xe10fdd37, 0xf7882a90),
  Register64(0x524dcab5, 0x518a3f5c),
  Register64(0x3c9e8587, 0x8451255b),
  Register64(0x40298281, 0x19bd34e2),
  Register64(0x74a05b6f, 0x5d3ceccb),
  Register64(0xb6100215, 0x42e13eca),
  Register64(0x0ff979d1, 0x2f59e2ac),
  Register64(0x6037da27, 0xe4f9cc50),
  Register64(0x5e92975a, 0x0df1847d),
  Register64(0xd66de190, 0xd3e623fe),
  Register64(0x5032d6b8, 0x7b568048),
  Register64(0x9a36b7ce, 0x8235216e),
  Register64(0x80272a7a, 0x24f64b4a),
  Register64(0x93efed8b, 0x8c6916f7),
  Register64(0x37ddbff4, 0x4cce1555),
  Register64(0x4b95db5d, 0x4b99bd25),
  Register64(0x92d3fda1, 0x69812fc0),
  Register64(0xfb1a4a9a, 0x90660bb6),
  Register64(0x730c1969, 0x46a4b9b2),
  Register64(0x81e289aa, 0x7f49da68),
  Register64(0x64669a0f, 0x83b1a05f),
  Register64(0x27b3ff7d, 0x9644f48b),
  Register64(0xcc6b615c, 0x8db675b3),
  Register64(0x674f20b9, 0xbcebbe95),
  Register64(0x6f312382, 0x75655982),
  Register64(0x5ae48871, 0x3e45cf05),
  Register64(0xbf619f99, 0x54c21157),
  Register64(0xeabac460, 0x40a8eae9),
  Register64(0x454c6fe9, 0xf2c0c1cd),
  Register64(0x419cf649, 0x6412691c),
  Register64(0xd3dc3bef, 0x265b0f70),
  Register64(0x6d0e60f5, 0xc3578a9e),
];

final _t4 = [
  Register64(0x5b0e6085, 0x26323c55),
  Register64(0x1a46c1a9, 0xfa1b59f5),
  Register64(0xa9e245a1, 0x7c4c8ffa),
  Register64(0x65ca5159, 0xdb2955d7),
  Register64(0x05db0a76, 0xce35afc2),
  Register64(0x81eac77e, 0xa9113d45),
  Register64(0x528ef88a, 0xb6ac0a0d),
  Register64(0xa09ea253, 0x597be3ff),
  Register64(0x430ddfb3, 0xac48cd56),
  Register64(0xc4b3a67a, 0xf45ce46f),
  Register64(0x4ececfd8, 0xfbe2d05e),
  Register64(0x3ef56f10, 0xb39935f0),
  Register64(0x0b22d682, 0x9cd619c6),
  Register64(0x17fd460a, 0x74df2069),
  Register64(0x6cf8cc8e, 0x8510ed40),
  Register64(0xd6c824bf, 0x3a6ecaa7),
  Register64(0x61243d58, 0x1a817049),
  Register64(0x048bacb6, 0xbbc163a2),
  Register64(0xd9a38ac2, 0x7d44cc32),
  Register64(0x7fddff5b, 0xaaf410ab),
  Register64(0xad6d495a, 0xa804824b),
  Register64(0xe1a6a74f, 0x2d8c9f94),
  Register64(0xd4f78512, 0x35dee8e3),
  Register64(0xfd4b7f88, 0x6540d893),
  Register64(0x247c2004, 0x2aa4bfda),
  Register64(0x096ea1c5, 0x17d1327c),
  Register64(0xd56966b4, 0x361a6685),
  Register64(0x277da5c3, 0x1221057d),
  Register64(0x94d59893, 0xa43acff7),
  Register64(0x64f0c51c, 0xcdc02281),
  Register64(0x3d33bcc4, 0xff6189db),
  Register64(0xe005cb18, 0x4ce66af1),
  Register64(0xff5ccd1d, 0x1db99bea),
  Register64(0xb0b854a7, 0xfe42980f),
  Register64(0x7bd46a6a, 0x718d4b9f),
  Register64(0xd10fa8cc, 0x22a5fd8c),
  Register64(0xd3148495, 0x2be4bd31),
  Register64(0xc7fa975f, 0xcb243847),
  Register64(0x4886ed1e, 0x5846c407),
  Register64(0x28cddb79, 0x1eb70b04),
  Register64(0xc2b00be2, 0xf573417f),
  Register64(0x5c959045, 0x2180f877),
  Register64(0x7a6bddff, 0xf370eb00),
  Register64(0xce509e38, 0xd6d9d6a4),
  Register64(0xebeb0f00, 0x647fa702),
  Register64(0x1dcc06cf, 0x76606f06),
  Register64(0xe4d9f28b, 0xa286ff0a),
  Register64(0xd85a305d, 0xc918c262),
  Register64(0x475b1d87, 0x32225f54),
  Register64(0x2d4fb516, 0x68ccb5fe),
  Register64(0xa679b9d9, 0xd72bba20),
  Register64(0x53841c0d, 0x912d43a5),
  Register64(0x3b7eaa48, 0xbf12a4e8),
  Register64(0x781e0e47, 0xf22f1ddf),
  Register64(0xeff20ce6, 0x0ab50973),
  Register64(0x20d261d1, 0x9dffb742),
  Register64(0x16a12b03, 0x062a2e39),
  Register64(0x1960eb22, 0x39650495),
  Register64(0x251c16fe, 0xd50eb8b8),
  Register64(0x9ac0c330, 0xf826016e),
  Register64(0xed152665, 0x953e7671),
  Register64(0x02d63194, 0xa6369570),
  Register64(0x5074f083, 0x94b1c987),
  Register64(0x70ba598c, 0x90b25ce1),
  Register64(0x794a1581, 0x0b9742f6),
  Register64(0x0d5925e9, 0xfcaf8c6c),
  Register64(0x3067716c, 0xd868744e),
  Register64(0x910ab077, 0xe8d7731b),
  Register64(0x6a61bbdb, 0x5ac42f61),
  Register64(0x93513efb, 0xf0851567),
  Register64(0xf494724b, 0x9e83e9d5),
  Register64(0xe887e198, 0x5c09648d),
  Register64(0x34b1d3c6, 0x75370cfd),
  Register64(0xdc35e433, 0xbc0d255d),
  Register64(0xd0aab842, 0x34131be0),
  Register64(0x08042a50, 0xb48b7eaf),
  Register64(0x9997c4ee, 0x44a3ab35),
  Register64(0x829a7b49, 0x201799d0),
  Register64(0x263b8307, 0xb7c54441),
  Register64(0x752f95f4, 0xfd6a6ca6),
  Register64(0x92721740, 0x2c08c6e5),
  Register64(0x2a8ab754, 0xa795d9ee),
  Register64(0xa442f755, 0x2f72943d),
  Register64(0x2c31334e, 0x19781208),
  Register64(0x4fa98d7c, 0xeaee6291),
  Register64(0x55c3862f, 0x665db309),
  Register64(0xbd061017, 0x5d53b1f3),
  Register64(0x46fe6cb8, 0x40413f27),
  Register64(0x3fe03792, 0xdf0cfa59),
  Register64(0xcfe70037, 0x2eb85e8f),
  Register64(0xa7be29e7, 0xadbce118),
  Register64(0xe544ee5c, 0xde8431dd),
  Register64(0x8a781b1b, 0x41f1873e),
  Register64(0xa5c94c78, 0xa0d2f0e7),
  Register64(0x39412e28, 0x77b60728),
  Register64(0xa1265ef3, 0xafc9a62c),
  Register64(0xbcc2770c, 0x6a2506c5),
  Register64(0x3ab66dd5, 0xdce1ce12),
  Register64(0xe65499d0, 0x4a675b37),
  Register64(0x7d8f5234, 0x81bfd216),
  Register64(0x0f6f64fc, 0xec15f389),
  Register64(0x74efbe61, 0x8b5b13c8),
  Register64(0xacdc82b7, 0x14273e1d),
  Register64(0xdd40bfe0, 0x03199d17),
  Register64(0x37e99257, 0xe7e061f8),
  Register64(0xfa526269, 0x04775aaa),
  Register64(0x8bbbf63a, 0x463d56f9),
  Register64(0xf0013f15, 0x43a26e64),
  Register64(0xa8307e9f, 0x879ec898),
  Register64(0xcc4c27a4, 0x150177cc),
  Register64(0x1b432f2c, 0xca1d3348),
  Register64(0xde1d1f8f, 0x9f6fa013),
  Register64(0x606602a0, 0x47a7ddd6),
  Register64(0xd237ab64, 0xcc1cb2c7),
  Register64(0x9b938e72, 0x25fcd1d3),
  Register64(0xec4e0370, 0x8e0ff476),
  Register64(0xfeb2fbda, 0x3d03c12d),
  Register64(0xae0bced2, 0xee43889a),
  Register64(0x22cb8923, 0xebfb4f43),
  Register64(0x69360d01, 0x3cf7396d),
  Register64(0x855e3602, 0xd2d4e022),
  Register64(0x073805ba, 0xd01f784c),
  Register64(0x33e17a13, 0x3852f546),
  Register64(0xdf487405, 0x8ac7b638),
  Register64(0xba92b29c, 0x678aa14a),
  Register64(0x0ce89fc7, 0x6cfaadcd),
  Register64(0x5f9d4e09, 0x08339e34),
  Register64(0xf1afe929, 0x1f5923b9),
  Register64(0x6e3480f6, 0x0f4a265f),
  Register64(0xeebf3a2a, 0xb29b841c),
  Register64(0xe21938a8, 0x8f91b4ad),
  Register64(0x57dfeff8, 0x45c6d3c3),
  Register64(0x2f006b0b, 0xf62caaf2),
  Register64(0x62f479ef, 0x6f75ee78),
  Register64(0x11a55ad4, 0x1c8916a9),
  Register64(0xf229d290, 0x84fed453),
  Register64(0x42f1c27b, 0x16b000e6),
  Register64(0x2b1f7674, 0x9823c074),
  Register64(0x4b76eca3, 0xc2745360),
  Register64(0x8c98f463, 0xb91691bd),
  Register64(0x14bcc93c, 0xf1ade66a),
  Register64(0x8885213e, 0x6d458397),
  Register64(0x8e177df0, 0x274d4711),
  Register64(0xb49b73b5, 0x503f2951),
  Register64(0x10168168, 0xc3f96b6b),
  Register64(0x0e3d963b, 0x63cab0ae),
  Register64(0x8dfc4b56, 0x55a1db14),
  Register64(0xf789f135, 0x6e14de5c),
  Register64(0x683e68af, 0x4e51dac1),
  Register64(0xc9a84f9d, 0x8d4b0fd9),
  Register64(0x3691e03f, 0x52a0f9d1),
  Register64(0x5ed86e46, 0xe1878e80),
  Register64(0x3c711a0e, 0x99d07150),
  Register64(0x5a0865b2, 0x0c4e9310),
  Register64(0x56fbfc1f, 0xe4f0682e),
  Register64(0xea8d5de3, 0x105edf9b),
  Register64(0x71abfdb1, 0x2379187a),
  Register64(0x2eb99de1, 0xbee77b9c),
  Register64(0x21ecc0ea, 0x33cf4523),
  Register64(0x59a4d752, 0x1805c7a1),
  Register64(0x3896f5eb, 0x56ae7c72),
  Register64(0xaa638f3d, 0xb18f75dc),
  Register64(0x9f39358d, 0xabe9808e),
  Register64(0xb7defa91, 0xc00b72ac),
  Register64(0x6b5541fd, 0x62492d92),
  Register64(0x6dc6dee8, 0xf92e4d5b),
  Register64(0x353f57ab, 0xc4beea7e),
  Register64(0x735769d6, 0xda5690ce),
  Register64(0x0a234aa6, 0x42391484),
  Register64(0xf6f95080, 0x28f80d9d),
  Register64(0xb8e319a2, 0x7ab3f215),
  Register64(0x31ad9c11, 0x51341a4d),
  Register64(0x773c22a5, 0x7bef5805),
  Register64(0x45c7561a, 0x07968633),
  Register64(0xf913da9e, 0x249dbe36),
  Register64(0xda652d9b, 0x78a64c68),
  Register64(0x4c27a97f, 0x3bc334ef),
  Register64(0x76621220, 0xe66b17f4),
  Register64(0x96774389, 0x9acd7d0b),
  Register64(0xf3ee5bca, 0xe0ed6782),
  Register64(0x409f7536, 0x00c879fc),
  Register64(0x06d09a39, 0xb5926db6),
  Register64(0x6f83aeb0, 0x317ac588),
  Register64(0x01e6ca4a, 0x86381f21),
  Register64(0x66ff3462, 0xd19f3025),
  Register64(0x72207c24, 0xddfd3bfb),
  Register64(0x4af6b6d3, 0xe2ece2eb),
  Register64(0x9c994dbe, 0xc7ea08de),
  Register64(0x49ace597, 0xb09a8bc4),
  Register64(0xb38c4766, 0xcf0797ba),
  Register64(0x131b9373, 0xc57c2a75),
  Register64(0xb1822cce, 0x61931e58),
  Register64(0x9d7555b9, 0x09ba1c0c),
  Register64(0x127fafdd, 0x937d11d2),
  Register64(0x29da3bad, 0xc66d92e4),
  Register64(0xa2c1d571, 0x54c2ecbc),
  Register64(0x58c5134d, 0x82f6fe24),
  Register64(0x1c3ae351, 0x5b62274f),
  Register64(0xe907c82e, 0x01cb8126),
  Register64(0xf8ed0919, 0x13e37fcb),
  Register64(0x3249d8f9, 0xc80046c9),
  Register64(0x80cf9bed, 0xe388fb63),
  Register64(0x1881539a, 0x116cf19e),
  Register64(0x5103f3f7, 0x6bd52457),
  Register64(0x15b7e6f5, 0xae47f7a8),
  Register64(0xdbd7c6de, 0xd47e9ccf),
  Register64(0x44e55c41, 0x0228bb1a),
  Register64(0xb647d425, 0x5edb4e99),
  Register64(0x5d11882b, 0xb8aafc30),
  Register64(0xf5098bbb, 0x29d3212a),
  Register64(0x8fb5ea14, 0xe90296b3),
  Register64(0x677b9421, 0x57dd025a),
  Register64(0xfb58e7c0, 0xa390acb5),
  Register64(0x89d3674c, 0x83bd4a01),
  Register64(0x9e2da4df, 0x4bf3b93b),
  Register64(0xfcc41e32, 0x8cab4829),
  Register64(0x03f38c96, 0xba582c52),
  Register64(0xcad1bdbd, 0x7fd85db2),
  Register64(0xbbb442c1, 0x6082ae83),
  Register64(0xb95fe86b, 0xa5da9ab0),
  Register64(0xb22e0467, 0x3771a93f),
  Register64(0x845358c9, 0x493152d8),
  Register64(0xbe2a4886, 0x97b4541e),
  Register64(0x95a2dc2d, 0xd38e6966),
  Register64(0xc02c11ac, 0x923c852b),
  Register64(0x2388b199, 0x0df2a87b),
  Register64(0x7c8008fa, 0x1b4f37be),
  Register64(0x1f70d0c8, 0x4d54e503),
  Register64(0x5490adec, 0x7ece57d4),
  Register64(0x002b3c27, 0xd9063a3a),
  Register64(0x7eaea384, 0x8030a2bf),
  Register64(0xc602326d, 0xed2003c0),
  Register64(0x83a7287d, 0x69a94086),
  Register64(0xc57a5fcb, 0x30f57a8a),
  Register64(0xb56844e4, 0x79ebe779),
  Register64(0xa373b40f, 0x05dcbce9),
  Register64(0xd71a786e, 0x88570ee2),
  Register64(0x879cbacd, 0xbde8f6a0),
  Register64(0x976ad1bc, 0xc164a32f),
  Register64(0xab21e25e, 0x9666d78b),
  Register64(0x901063aa, 0xe5e5c33c),
  Register64(0x9818b344, 0x48698d90),
  Register64(0xe36487ae, 0x3e1e8abb),
  Register64(0xafbdf931, 0x893bdcb4),
  Register64(0x6345a0dc, 0x5fbbd519),
  Register64(0x8628fe26, 0x9b9465ca),
  Register64(0x1e5d0160, 0x3f9c51ec),
  Register64(0x4de44006, 0xa15049b7),
  Register64(0xbf6c70e5, 0xf776cbb1),
  Register64(0x411218f2, 0xef552bed),
  Register64(0xcb0c0708, 0x705a36a3),
  Register64(0xe74d1475, 0x4f986044),
  Register64(0xcd56d943, 0x0ea8280e),
  Register64(0xc12591d7, 0x535f5065),
  Register64(0xc83223f1, 0x720aef96),
  Register64(0xc3a0396f, 0x7363a51f),
];
