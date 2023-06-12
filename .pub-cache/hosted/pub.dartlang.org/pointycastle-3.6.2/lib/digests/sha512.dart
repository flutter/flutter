// See file LICENSE for more information.

library impl.digest.sha512;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/long_sha2_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Implementation of SHA-512 digest.
class SHA512Digest extends LongSHA2FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'SHA-512', () => SHA512Digest());

  static const _DIGEST_LENGTH = 64;

  SHA512Digest() {
    reset();
  }

  @override
  final algorithmName = 'SHA-512';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void reset() {
    super.reset();

    h1.set(0x6a09e667, 0xf3bcc908);
    h2.set(0xbb67ae85, 0x84caa73b);
    h3.set(0x3c6ef372, 0xfe94f82b);
    h4.set(0xa54ff53a, 0x5f1d36f1);
    h5.set(0x510e527f, 0xade682d1);
    h6.set(0x9b05688c, 0x2b3e6c1f);
    h7.set(0x1f83d9ab, 0xfb41bd6b);
    h8.set(0x5be0cd19, 0x137e2179);
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    finish();

    var view = ByteData.view(out.buffer, out.offsetInBytes, out.length);
    h1.pack(view, outOff, Endian.big);
    h2.pack(view, outOff + 8, Endian.big);
    h3.pack(view, outOff + 16, Endian.big);
    h4.pack(view, outOff + 24, Endian.big);
    h5.pack(view, outOff + 32, Endian.big);
    h6.pack(view, outOff + 40, Endian.big);
    h7.pack(view, outOff + 48, Endian.big);
    h8.pack(view, outOff + 56, Endian.big);

    reset();

    return _DIGEST_LENGTH;
  }
}
