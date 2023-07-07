// See file LICENSE for more information.

library impl.digest.sha384;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/long_sha2_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';

/// Implementation of SHA-384 digest.
class SHA384Digest extends LongSHA2FamilyDigest implements Digest {
  static final FactoryConfig factoryConfig =
      StaticFactoryConfig(Digest, 'SHA-384', () => SHA384Digest());

  static const _DIGEST_LENGTH = 48;

  SHA384Digest() {
    reset();
  }

  @override
  final algorithmName = 'SHA-384';
  @override
  final digestSize = _DIGEST_LENGTH;

  @override
  void reset() {
    super.reset();

    h1.set(0xcbbb9d5d, 0xc1059ed8);
    h2.set(0x629a292a, 0x367cd507);
    h3.set(0x9159015a, 0x3070dd17);
    h4.set(0x152fecd8, 0xf70e5939);
    h5.set(0x67332667, 0xffc00b31);
    h6.set(0x8eb44a87, 0x68581511);
    h7.set(0xdb0c2e0d, 0x64f98fa7);
    h8.set(0x47b5481d, 0xbefa4fa4);
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

    reset();

    return _DIGEST_LENGTH;
  }
}
