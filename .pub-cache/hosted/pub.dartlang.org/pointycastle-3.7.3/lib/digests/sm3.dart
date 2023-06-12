// See file LICENSE for more information.

library impl.digest.sm3;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/md4_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of Chinese SM3 Hash Function (GM/T 0004-2012) as
/// described at [Reference 1][REF1] and at [Reference 2][REF2].
///
/// 这是一个依据 [参考文献1][REF1] 和 [参考文献2][REF2] 的 SM3 哈希函数的实现.
///
/// [REF1]: http://www.sca.gov.cn/sca/xwdt/2010-12/17/content_1002389.shtml
/// [REF2]: https://tools.ietf.org/html/draft-shen-sm3-hash
class SM3Digest extends MD4FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'SM3', () => SM3Digest());

  static const _DIGEST_LENGTH = 32;

  final List<int> _W;

  SM3Digest()
      : _W = List<int>.filled(68, 0, growable: false),
        super(Endian.big, 8, 16);

  @override
  final algorithmName = 'SM3';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void resetState() {
    state[0] = 0x7380166f;
    state[1] = 0x4914b2b9;
    state[2] = 0x172442d7;
    state[3] = 0xda8a0600;
    state[4] = 0xa96f30bc;
    state[5] = 0x163138aa;
    state[6] = 0xe38dee4d;
    state[7] = 0xb0fb0e4e;
  }

  @override
  void processBlock() {
    int i;
    // [REF1] 5.3.2 消息扩展
    // [REF2] 3.3.2 Message Extension
    _W.setAll(0, buffer);
    for (i = 16; i < 68; ++i) {
      _W[i] = _P1(_W[i - 16] ^ _W[i - 9] ^ rotl32(_W[i - 3], 15)) ^
          rotl32(_W[i - 13], 7) ^
          _W[i - 6];
    }
    // [REF1] 5.3.3 压缩函数
    // [REF2] 3.3.3 Compression Function
    var A = state[0];
    var B = state[1];
    var C = state[2];
    var D = state[3];
    var E = state[4];
    var F = state[5];
    var G = state[6];
    var H = state[7];
    int SS1, SS2, TT1, TT2, Tj;
    for (i = 0; i < 16; ++i) {
      Tj = 0x79cc4519;
      SS1 = rotl32(clip32(rotl32(A, 12) + E + rotl32(Tj, i)), 7);
      SS2 = SS1 ^ rotl32(A, 12);
      TT1 = clip32(_FF1(A, B, C) + D + SS2 + (_W[i] ^ _W[i + 4]));
      TT2 = clip32(_GG1(E, F, G) + H + SS1 + _W[i]);
      D = C;
      C = rotl32(B, 9);
      B = A;
      A = TT1;
      H = G;
      G = rotl32(F, 19);
      F = E;
      E = _P0(TT2);
    }
    for (i = 16; i < 64; ++i) {
      Tj = 0x7a879d8a;
      SS1 = rotl32(clip32(rotl32(A, 12) + E + rotl32(Tj, i)), 7);
      SS2 = SS1 ^ rotl32(A, 12);
      TT1 = clip32(_FF2(A, B, C) + D + SS2 + (_W[i] ^ _W[i + 4]));
      TT2 = clip32(_GG2(E, F, G) + H + SS1 + _W[i]);
      D = C;
      C = rotl32(B, 9);
      B = A;
      A = TT1;
      H = G;
      G = rotl32(F, 19);
      F = E;
      E = _P0(TT2);
    }
    state[0] ^= A;
    state[1] ^= B;
    state[2] ^= C;
    state[3] ^= D;
    state[4] ^= E;
    state[5] ^= F;
    state[6] ^= G;
    state[7] ^= H;
  }

  /// FF1 Function
  static final _FF1 = (X, Y, Z) => ((X) ^ (Y) ^ (Z));

  /// FF2 Function
  static final _FF2 = (X, Y, Z) => (((X) & (Y)) | ((X) & (Z)) | ((Y) & (Z)));

  /// GG1 Function
  static final _GG1 = _FF1;

  /// GG2 Function
  static final _GG2 = (X, Y, Z) => (((X) & (Y)) | ((~X) & (Z)));

  /// P0 Function
  static final _P0 = (X) => ((X) ^ rotl32((X), 9) ^ rotl32((X), 17));

  /// P1 Function
  static final _P1 = (X) => ((X) ^ rotl32((X), 15) ^ rotl32((X), 23));

  @override
  int get byteLength => 64;
}
