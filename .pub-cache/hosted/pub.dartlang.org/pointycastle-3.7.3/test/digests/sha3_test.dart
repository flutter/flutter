// See file LICENSE for more information.

library test.digests.sha3_test.dart;

import 'dart:typed_data';

import 'package:pointycastle/digests/sha3.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

class _Sha3Vector {
  _Sha3Vector(this.algo, this.bits, String msg, String digest) {
    this.msg = createUint8ListFromHexString(msg);
    this.digest = createUint8ListFromHexString(digest);
  }

  String algo;
  int bits;
  Uint8List? msg;
  Uint8List? digest;
}

void main() {
  testSHA3SizeEnforcement();
  testSHA3AgainstVectors();
}

void testSHA3AgainstVectors() {
  var algoToSize = {
    'SHA3-224': 224,
    'SHA3-256': 256,
    'SHA3-384': 384,
    'SHA3-512': 512
  };

  //
  // Test vectors for FIPS 202 - SHA-3 Standard: Permutation-Based Hash and Extendable-Output Functions
  //
  var vectors = [
    _Sha3Vector('SHA3-224', 0, '',
        '6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7'),
    _Sha3Vector('SHA3-224', 5, '13',
        'ffbad5da96bad71789330206dc6768ecaeb1b32dca6b3301489674ab'),
    _Sha3Vector('SHA3-224', 30, '53587b19',
        'd666a514cc9dba25ac1ba69ed3930460deaac9851b5f0baab007df3b'),
    _Sha3Vector(
        'SHA3-224',
        1600,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3',
        '9376816aba503f72f96ce7eb65ac095deee3be4bf9bbc2a1cb7e11e0'),
    _Sha3Vector(
        'SHA3-224',
        1605,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a303',
        '22d2f7bb0b173fd8c19686f9173166e3ee62738047d7eadd69efb228'),
    _Sha3Vector(
        'SHA3-224',
        1630,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a323',
        '4e907bb1057861f200a599e9d4f85b02d88453bf5b8ace9ac589134c'),
    _Sha3Vector('SHA3-256', 0, '',
        'a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a'),
    _Sha3Vector('SHA3-256', 5, '13',
        '7b0047cf5a456882363cbf0fb05322cf65f4b7059a46365e830132e3b5d957af'),
    _Sha3Vector('SHA3-256', 30, '53587b19',
        'c8242fef409e5ae9d1f1c857ae4dc624b92b19809f62aa8c07411c54a078b1d0'),
    _Sha3Vector(
        'SHA3-256',
        1600,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3',
        '79f38adec5c20307a98ef76e8324afbfd46cfd81b22e3973c65fa1bd9de31787'),
    _Sha3Vector(
        'SHA3-256',
        1605,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a303',
        '81ee769bed0950862b1ddded2e84aaa6ab7bfdd3ceaa471be31163d40336363c'),
    _Sha3Vector(
        'SHA3-256',
        1630,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a323',
        '52860aa301214c610d922a6b6cab981ccd06012e54ef689d744021e738b9ed20'),
    _Sha3Vector('SHA3-384', 0, '',
        '0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004'),
    _Sha3Vector('SHA3-384', 5, '13',
        '737c9b491885e9bf7428e792741a7bf8dca9653471c3e148473f2c236b6a0a6455eb1dce9f779b4b6b237fef171b1c64'),
    _Sha3Vector('SHA3-384', 30, '53587b19',
        '955b4dd1be03261bd76f807a7efd432435c417362811b8a50c564e7ee9585e1ac7626dde2fdc030f876196ea267f08c3'),
    _Sha3Vector(
        'SHA3-384',
        1600,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3',
        '1881de2ca7e41ef95dc4732b8f5f002b189cc1e42b74168ed1732649ce1dbcdd76197a31fd55ee989f2d7050dd473e8f'),
    _Sha3Vector(
        'SHA3-384',
        1605,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a303',
        'a31fdbd8d576551c21fb1191b54bda65b6c5fe97f0f4a69103424b43f7fdb835979fdbeae8b3fe16cb82e587381eb624'),
    _Sha3Vector(
        'SHA3-384',
        1630,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a323',
        '3485d3b280bd384cf4a777844e94678173055d1cbc40c7c2c3833d9ef12345172d6fcd31923bb8795ac81847d3d8855c'),
    _Sha3Vector('SHA3-512', 0, '',
        'a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26'),
    _Sha3Vector('SHA3-512', 5, '13',
        'a13e01494114c09800622a70288c432121ce70039d753cadd2e006e4d961cb27544c1481e5814bdceb53be6733d5e099795e5e81918addb058e22a9f24883f37'),
    _Sha3Vector('SHA3-512', 30, '53587b19',
        '9834c05a11e1c5d3da9c740e1c106d9e590a0e530b6f6aaa7830525d075ca5db1bd8a6aa981a28613ac334934a01823cd45f45e49b6d7e6917f2f16778067bab'),
    _Sha3Vector(
        'SHA3-512',
        1600,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3',
        'e76dfad22084a8b1467fcf2ffa58361bec7628edf5f3fdc0e4805dc48caeeca81b7c13c30adf52a3659584739a2df46be589c51ca1a4a8416df6545a1ce8ba00'),
    _Sha3Vector(
        'SHA3-512',
        1605,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a303',
        'fc4a167ccb31a937d698fde82b04348c9539b28f0c9d3b4505709c03812350e4990e9622974f6e575c47861c0d2e638ccfc2023c365bb60a93f528550698786b'),
    _Sha3Vector(
        'SHA3-512',
        1630,
        'a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a323',
        'cf9a30ac1f1f6ac0916f9fef1919c595debe2ee80c85421210fdf05f1c6af73aa9cac881d0f91db6d034a2bbadc1cf7fbcb2ecfa9d191d3a5016fb3fad8709c9')
  ];

  group('SHA-3', () {
    for (var vector in vectors) {
      test(vector.algo, () {
        var partialBits = vector.bits % 8;
        var bitLen = algoToSize[vector.algo];
        var digest = SHA3Digest(bitLen);
        Uint8List out;

        if (partialBits == 0) {
          digest.update(vector.msg!, 0, vector.msg!.length);
          out = Uint8List(digest.digestSize);
          digest.doFinal(out, 0);
          expect(vector.digest, out);

          //
          // Vandalise message, if zero len message skip.
          //
          if (vector.msg!.isNotEmpty) {
            var vandalized = Uint8List.fromList(vector.msg!);
            vandalized[0] ^= 1;

            digest.update(vandalized, 0, vector.msg!.length);
            out = Uint8List(digest.digestSize);
            digest.doFinal(out, 0);
            expect(vector.digest, isNot(out),
                reason: 'vandalized must not be equal');
          }
        } else {
          //
          // When this is added implement the test here.
          //

          Skip('No support for partials: ${vector.algo}');
        }
      });
    }
  });
}

void testSHA3SizeEnforcement() {
  group('SHA-3 Tests', () {
    test('enforcement of valid SHA-3 sizes', () {
      SHA3Digest(224);
      SHA3Digest(256);
      SHA3Digest(384);
      SHA3Digest(512);

      var bitLen = 123;
      try {
        SHA3Digest(bitLen);
        fail('Invalid sha3 bitlen accepted');
      } on StateError catch (se) {
        expect(se.message,
            'invalid bitLength ($bitLen) for SHA-3 must only be 224,256,384,512');
      }
    });
  });
}
