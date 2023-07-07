// See file LICENSE for more information.

library impl.digest.sha512t;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/src/impl/long_sha2_family_digest.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/src/ufixnum.dart';

/// Implementation of SHA-512/t digest (see FIPS 180-4).
class SHA512tDigest extends LongSHA2FamilyDigest implements Digest {
  static final RegExp _nameRegex = RegExp(r'^SHA-512\/([0-9]+)$');

  /// Intended for internal use.
  static final FactoryConfig factoryConfig = DynamicFactoryConfig(
      Digest,
      _nameRegex,
      (_, final Match match) => () {
            var bitLength = int.parse(match.group(1)!);
            if ((bitLength % 8) != 0) {
              throw RegistryFactoryException(
                  'Digest length for SHA-512/t is not a multiple of 8: $bitLength');
            }
            return SHA512tDigest(bitLength ~/ 8);
          });

  static final Register64 _hMask = Register64(0xa5a5a5a5, 0xa5a5a5a5);

  @override
  final int digestSize;

  final _h1t = Register64();
  final _h2t = Register64();
  final _h3t = Register64();
  final _h4t = Register64();
  final _h5t = Register64();
  final _h6t = Register64();
  final _h7t = Register64();
  final _h8t = Register64();

  SHA512tDigest(this.digestSize) {
    if (digestSize >= 64) {
      throw ArgumentError('Digest size cannot be >= 64 bytes (512 bits)');
    }
    if (digestSize == 48) {
      throw ArgumentError(
          'Digest size cannot be 48 bytes (384 bits): use SHA-384 instead');
    }

    _generateIVs(digestSize * 8);

    reset();
  }

  @override
  String get algorithmName => 'SHA-512/${digestSize * 8}';

  @override
  void reset() {
    super.reset();

    h1.set(_h1t);
    h2.set(_h2t);
    h3.set(_h3t);
    h4.set(_h4t);
    h5.set(_h5t);
    h6.set(_h6t);
    h7.set(_h7t);
    h8.set(_h8t);
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    finish();

    var tmp = Uint8List(64);

    var view = ByteData.view(tmp.buffer, tmp.offsetInBytes, tmp.length);
    h1.pack(view, 0, Endian.big);
    h2.pack(view, 8, Endian.big);
    h3.pack(view, 16, Endian.big);
    h4.pack(view, 24, Endian.big);
    h5.pack(view, 32, Endian.big);
    h6.pack(view, 40, Endian.big);
    h7.pack(view, 48, Endian.big);
    h8.pack(view, 56, Endian.big);

    out.setRange(outOff, outOff + digestSize, tmp);

    reset();

    return digestSize;
  }

  void _generateIVs(int bitLength) {
    h1
      ..set(0x6a09e667, 0xf3bcc908)
      ..xor(_hMask);
    h2
      ..set(0xbb67ae85, 0x84caa73b)
      ..xor(_hMask);
    h3
      ..set(0x3c6ef372, 0xfe94f82b)
      ..xor(_hMask);
    h4
      ..set(0xa54ff53a, 0x5f1d36f1)
      ..xor(_hMask);
    h5
      ..set(0x510e527f, 0xade682d1)
      ..xor(_hMask);
    h6
      ..set(0x9b05688c, 0x2b3e6c1f)
      ..xor(_hMask);
    h7
      ..set(0x1f83d9ab, 0xfb41bd6b)
      ..xor(_hMask);
    h8
      ..set(0x5be0cd19, 0x137e2179)
      ..xor(_hMask);

    updateByte(0x53);
    updateByte(0x48);
    updateByte(0x41);
    updateByte(0x2D);
    updateByte(0x35);
    updateByte(0x31);
    updateByte(0x32);
    updateByte(0x2F);

    if (bitLength > 100) {
      updateByte(bitLength ~/ 100 + 0x30);
      bitLength = bitLength % 100;
      updateByte(bitLength ~/ 10 + 0x30);
      bitLength = bitLength % 10;
      updateByte(bitLength + 0x30);
    } else if (bitLength > 10) {
      updateByte(bitLength ~/ 10 + 0x30);
      bitLength = bitLength % 10;
      updateByte(bitLength + 0x30);
    } else {
      updateByte(bitLength + 0x30);
    }

    finish();

    _h1t.set(h1);
    _h2t.set(h2);
    _h3t.set(h3);
    _h4t.set(h4);
    _h5t.set(h5);
    _h6t.set(h6);
    _h7t.set(h7);
    _h8t.set(h8);
  }
}
